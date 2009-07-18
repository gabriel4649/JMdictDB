#!/usr/env python
#
# This program allows direct editing of the database tables
# that constitute an entry.

__version__ = ("$Revision$"[11:-2], 
	       "$Date$"[7:-11])
# To do:
# In MyGrid, allow clicking (or right click context menu) on 
#   column headers to sort on that column. 
# A TableFrame re-query option just for that table?
# Improve load/reload options.
# How to edit groups, snds, kw* tables, the t* tables?
# Make jmedit callable from the src.py gui tool?

import sys, copy, pdb
import wx, wx.grid, wx.xrc as xrc
from wx.lib.pubsub import Publisher as publisher
import  jdb, fmt, fmtjel, fmtxml, objects

Subscribe = publisher().subscribe
def Notify (topic, msg=None):
	  # During some frame close scenarios, notifies are
	  # issued that result in calls to methods of objects
	  # that have been partially deconstucted.
	try: publisher().sendMessage (topic, msg)
	except wx.PyDeadObjectError: pass

class Unset: pass

def main (args, opts):
	global Prefs
	Prefs = read_prefs (opts.config, opts)
        cursor = jdb.dbOpen (opts.database, **jdb.dbopts(opts))
	tables_descr = setup_tables_descr()
	model = Model (cursor, tables_descr)
	app = wx.App (redirect=0)
	xrcfile = jdb.find_in_syspath ("jmedit.xrc") + "/" + "jmedit.xrc"
	xrcres = wx.xrc.XmlResource (xrcfile)
	title = "Jmedit (%s)" % opts.database
	if opts.sql: sql, sql_args = opts.sql, []
	else:        sql, sql_args = None, parse_args (args)
	frame = MainFrame (None, title, xrcres, model, sql, sql_args)
	frame.Show (True)
	app.MainLoop()

class MainFrame (wx.Frame):
    def __init__(self, parent, title, xrcres, model, sql, sql_args):
        wx.Frame.__init__ (self, parent, -1, title, size=(640,540))
	global Model;  Model = self.model = model
	panel = xrcres.LoadPanel (self, "PANEL1")
	self.SetMenuBar (xrcres.LoadMenuBar ("MENU1"))
	self.display = "norm"
	self.closing = False

	mitem = lambda name: self.MenuBar.FindItemById(wx.xrc.XRCID(name))
	self.Bind (wx.EVT_MENU, self.Close, mitem('m_close'))
	self.Bind (wx.EVT_MENU, self.save_all, mitem('m_commit'))
	self.Bind (wx.EVT_MENU, self.cancel, mitem('m_rollback'))

	for tblname in self.model.tables.keys():
	    self.bind_table_button (xrcres, model, tblname)
	XRC (self, "b_load").Bind (wx.EVT_BUTTON, self.read_entries)
	XRC (self, "d_norm").Bind (wx.EVT_RADIOBUTTON, lambda e:self.set_display('norm'))
	XRC (self, "d_jel" ).Bind (wx.EVT_RADIOBUTTON, lambda e:self.set_display('jel'))
	XRC (self, "d_xml" ).Bind (wx.EVT_RADIOBUTTON, lambda e:self.set_display('xml'))
	XRC (self, "d_diff").Bind (wx.EVT_RADIOBUTTON, lambda e:self.set_display('diff'))
	XRC (self, "e_save"  ).Bind (wx.EVT_BUTTON, self.save_all)
	XRC (self, "e_cancel").Bind (wx.EVT_BUTTON, self.cancel)

	self.Bind (wx.EVT_CLOSE, self.on_close)
	Subscribe (self.upd_view, 'data')
	Subscribe (self.upd_view, 'reload')
	Subscribe (self.mark_dirty, 'dbdirty')
	Notify ('dbdirty', False)
	if sql or sql_args: self.model.load_entries (sql, sql_args)

    def bind_table_button (self, xrcres, model, table_name):
	  # Each of the "table" buttons in the XRC layout has a name of
	  # the form "e_" + 'tablename'.  Each button when clicked will
	  # open a new Frame that displays the table contents in a grid.
	  # Might be better here to interate through the buttons rather
	  # than the table names but this is ok for demo...

	XRC (self, "e_" + table_name).Bind (wx.EVT_BUTTON, 
	    lambda evt: self.disp_table_frame (self, xrcres, table_name))

    def on_close (self, evt=None):
	# We want to close all TableFrame windows before closing the
	# main windows since some of them may have unwritten changes
	# the require user interaction to write or not.  Further, a
	# write may fail necessitating a cancel of the main window
	# close.
	  # Get a list of open TableFrame windows.
	opentbls = [child for child in self.GetChildren() if isinstance (child, TableFrame)]
	print >>sys.stderr, 'open tables: %r' % [x.Name for x in opentbls]
	if opentbls:
	    if not self.closing: 
		  # This is the first attempt to close the main window so
		  # try to close all the open TableFrames.  It seems that 
		  # the .Close() calls may return before the window in actually
		  # closed, so cancel this close event, and schedule a new
		  # one to occur shortly.
		for tbl in opentbls: tbl.Close()
		wx.CallAfter (self.Close)
		self.closing = True
	    else:
		  # This is the second attempt to close and there are still 
		  # TableFrame windows open so cancel the close.
		self.closing = False
	    evt.Veto()
	    return

	# Check if there are any uncommited changes.
	if self.unsaved_continue ("exiting"):
	    evt.Skip()	# Continue the normal close process.
	else: 
	    evt.Veto()	# Cancel the normal close process.

    def read_entries (self, evt=None, idargs=[]):
	if idargs: idlist = [int(x) for x in idargs]
	else:
	    idstr = XRC (self, "idnum").GetValue()
	    idstr = idstr.replace(',', ' ')
	    idlist = [int (x) for x in idstr.split()]
	if not idlist: return
	if not self.unsaved_continue ("loading new entries"): return
	self.model.load_entries (None, idlist)

    def disp_table_frame (self, parent, xrcres, table_name):
	if not self.model.recordsets:
	    dialog (self, "No entries loaded yet.", "No Entries", wx.ICON_EXCLAMATION)
	    return
	recordset = self.model.recordsets[table_name]
	TableFrame (self, xrcres, table_name, recordset)

    def set_display (self, typ):
	# 'typ' is one of: "norm", "jel", "xml", "diff".
	self.display = typ
	self.upd_view()

    def upd_view (self, msg=None):
	  # Update the textual view of the entries that is provided 
	  # in the text window.
	print >>sys.stderr, "MainFrame.upd_view"
	textwin = XRC (self, "entrtxt")
	data = dict ((k,v.data) for k,v in self.model.recordsets.items())
	entrs = jdb.entr_bld (data)
	  # Since the primary keys of some records may have changed, call reorder_entr()
	  # to make sure all the sublists of the entry are ordered as expected by primary
	  # key.  
	  # FIXME: Should there be a notify message for this case so we can 
	  #  do it only when actually needed?
	for entr in entrs: reorder_entr (entr, self.model.tables)
	if   self.display == 'norm': txt = fmt_norm (entrs)
	elif self.display == 'jel':  txt = fmt_jel  (entrs) 
	elif self.display == 'xml':  txt = fmt_xml  (entrs)
	elif self.display == 'diff': txt = fmt_diff (entrs, self.model.origentrs)
	else: raise ValueError ("Unexpected self.display value: %r" % self.display)
	textwin.ChangeValue (txt)
	textwin.Refresh()
	textwin.Update()

    def save_all (self, evt=None): self.model.save_all()

    def cancel (self, evt=None): self.model.cancel()

    def mark_dirty (self, msg):
	self.uncommited_changes = msg.data
	print >>sys.stderr, "Notify: changed = %r" % msg.data
	XRC (self, "e_save"  ).Enable (msg.data)
	XRC (self, "e_cancel").Enable (msg.data)

    def unsaved_continue (self, verb):
	# If there are uncommited database changes, prompt the user to save
	# them, save or not as requested, and return True.  If the user clicked
	# Cancel, return False.
	if not self.uncommited_changes: return True
	msg = "There are uncommited database changes.  Click Cancel if you want " \
	    "the opportunity to save them.\nDo you want to continue %s without saving?" % verb
	rv = dialog (self, msg, "Uncommited Changes", wx.OK|wx.CANCEL|wx.ICON_EXCLAMATION)
	if rv == wx.ID_CANCEL: return False
	if rv == wx.ID_OK:
	    self.cancel();  return True

def parse_args (args):
	idlist = [int(x) for x in args]
	return idlist

def fmt_norm (entrs):
	txts = []
	for e in entrs:
	    txts.append (fmt.entr (e))
	    if e is not entrs[-1]:
		txts.extend (['', '============================='])
	txt = '\n'.join (txts)
	return txt

def fmt_xml (entrs):
	txts = []
	for e in entrs:
	    txts.extend (['', fmt.entrhdr(e)])
	    txts.append (fmtxml.entr (e))
	    if e is not entrs[-1]:
		txts.extend (['', '============================='])
	txt = '\n'.join (txts)
	return txt

def fmt_jel (entrs):
	txts = []
	for e in entrs:
	    txts.append (fmtjel.entr (e))
	    if e is not entrs[-1]:
		txts.extend (['', '============================='])
	txt = '\n'.join (txts)
	return txt

def fmt_diff (entrs, origs):
	txts = []
	for enew, eold in zip (entrs, origs):
	    hdr = fmt.entrhdr (eold)
	    diff = fmtxml.entr_diff (eold, enew)
	    if not diff: hdr += " <no changes>"
	    txts.append (hdr)
	    if diff: txts.append (diff)
	txt = '\n'.join (txts)
	return txt

def XRC (wxobj, name):
	# This is a simple helper function used to lookup XRC
	# objects by name.  It was formerly equivalent to
	# wx.xrc.XRCCTRL() but that function returns None if
	# 'name' is not found which inevitably led to obscure
	# errors later in the code when the results were used.  
	# So this function raises an error immediately.

	if not isinstance (wxobj, wx.Object): 
	    raise ValueError ("Argument 1 not a wx.Object, is a %s" % type(wxobj))
	result = wx.xrc.XRCCTRL (wxobj, name)
	if not result: 
	    raise ValueError ("wx object '%s' not found in '%s'" % (name, wxobj))
	return result

def dialog (parent, msg, title, style):
	rv = wx.ID_OK  
	dlg = wx.MessageDialog (parent, msg, title, style=style)
	rv = dlg.ShowModal()
	dlg.Destroy()
	return rv

#=========================================================================

class TableFrame (wx.Frame):
    def __init__ (self, parent, xrcres, table_name, recordset):
        wx.Frame.__init__ (self, parent, -1, table_name, size=(640,480))
	  # Pass the 'table_name' and 'recordset' values to the MyGrid
	  # constructor by using globals.  Unpleasant but wxPython offers
	  # no other better options. 
	global _Table_name, _Record_set
	_Table_name, _Record_set = table_name, recordset
	  # The following creates the objects in the PANEL2 part of
	  # the XRC file, which includes creating the custom MyGrid
	  # subclass of wx.grid.Grid below.
	self.recordset = recordset
	self.tablename = table_name
	xrcres.LoadPanel (self, "PANEL2")
	self.SetMenuBar (xrcres.LoadMenuBar ("MENU2"))
	self.grid = XRC (self, 'grid') 
	self.Bind (wx.EVT_CLOSE, self.on_close)

	mitem = lambda name: self.MenuBar.FindItemById(wx.xrc.XRCID(name))
	self.Bind (wx.EVT_MENU, self.Close, mitem('m_close'))
	self.Bind (wx.EVT_MENU, self.grid.writeall, mitem('m_writetall'))
	self.Bind (wx.EVT_MENU, self.grid.revertall, mitem('m_revertall'))
	self.Bind (wx.EVT_MENU, self.grid.do_write, mitem('m_write'))
	self.Bind (wx.EVT_MENU, self.grid.do_rvrt, mitem('m_revert'))
	self.Bind (wx.EVT_MENU, self.grid.do_delete, mitem('m_delete'))

	Subscribe (self.upd_view, 'reload')
	self.Show (True)

    def on_close (self, evt):
	rv = None
	self.grid.SaveEditControlValue()  # Make sure any incomplete edit is processed.
	if self.recordset.has_changes():
	    rv = wx.ID_OK  
	    msg = "There are unwritten changes pending for table %s.  " \
		"Do you want to write them to the database them before closing?" % self.tablename
	    rv = dialog (self, msg, "Unwritten Changes", wx.YES_NO|wx.YES_DEFAULT|wx.CANCEL|wx.ICON_EXCLAMATION)
	if rv == wx.ID_YES: 
	      #FIXME: Some of the writes below may fail.  We need to catch that
	      # event, and then veto the close.
	    try: self.recordset.write_all()
	    except jdb.dbapi.Error, excep: 
	        msg = "Unable to write to database. \n" \
		    "SQL was: %s\n" \
		    "SQL args were: %r\n" \
		    "Error was: %s" % (excep.sql, excep.sqlargs, unicode (excep))
	        dialog (self, msg, "Database Error", wx.ICON_ERROR) 
		rv = wx.ID_CANCEL
	elif rv == wx.ID_NO: 
	    self.recordset.revert_all()
	if rv != wx.ID_CANCEL:	# Continue the normal close.
	    evt.Skip() 
	else: evt.Veto()		  # Don't close.

    def upd_view (self, msg=None):
	# Refresh the grid.
	print >>sys.stderr, "TableFrame(%s).upd_view" % self.tablename
	self.grid.reload (msg.data[self.tablename])

class MyGrid (wx.grid.Grid):
    def __init__ (self):
	self.esccnt = 0
	  # wxPython seems to offer no way to pass parameters to the
	  # constructor of a class that is instanstiated by xrcres()
	  # (i.e. us!) so we use globals (yuck) to pass them and 
	  # retreive them now.
	self.tablename, self.recordset = _Table_name, _Record_set
        g = wx.grid.PreGrid()
        self.PostCreate (g)
	  # Using OnCreate below as documented on the wxPython wiki
	  # "two-phase creation" docs just results in a divide-by-zero
	  # exception for me.
	wx.CallAfter (self.PostInit)

    def PostInit (self):
	self.CreateGrid (0, len (self.recordset.cols))
	gridbase = MyGridTable (self.recordset)
	self.SetTable (gridbase, True)
	self.SetRowLabelSize (15)
	for n, col in enumerate (self.recordset.cols):
	    if len(col) != 5: pdb.set_trace()
	    self.SetColSize (n, col[4])
	self.Bind (wx.EVT_CLOSE, self.on_close)
	self.Bind (wx.EVT_KEY_DOWN, self.keyevt)			# Revert changes if ESC key.
	self.Bind (wx.grid.EVT_GRID_LABEL_LEFT_DCLICK, self.labelclick)	# Write if click in row label.
	#self.ctxmenu = ContextMenu ((('Write', self.do_write),	# Right click context menu.
	#			     ('Revert', self.do_rvrt)))
        #self.Bind (wx.EVT_CONTEXT_MENU, self.show_ctxmenu)		# Right click context menu.
        #self.Bind (wx.EVT_RIGHT_DOWN, self.show_ctxmenu)		# Right click context menu.
	Subscribe (self.rowstat, 'rowstat')
	self.reload ()

    def on_close (self, evt=None):
	self.SaveEditControlValue()  # Make sure any incomplete edit is processed.

    def labelclick (self, evt):
	if evt.GetRow() >= 0:
	    self.do_write()

    def reload (self, recordset=None): 
	self.GetTable().reload (recordset or self.recordset)
	self.ForceRefresh()

    def rowstat (self, msg=None): 
	print >>sys.stderr, "GridTable.rowstat()"
	self.ForceRefresh()

    def do_rvrt (self, evt=None):
	self.SaveEditControlValue()  # Make sure any incomplete edit is processed.
	if evt and hasattr (evt, 'GetRow'): rownum = evt.GetRow()
	else: rownum = self.GetGridCursorRow()
	row = self.recordset.row (rownum)
	print >>sys.stderr, "MyGrid.do_rvrt(%d):" % rownum
	self.recordset.revert (row)
	wx.CallAfter (self.ForceRefresh)

    def do_write (self, evt=None):
	# Write all changes (if any) made to the current grid row, to
	# that database.
	#pdb.set_trace()
	self.SaveEditControlValue()  # Make sure any incomplete edit is processed.
	if evt and hasattr (evt, 'GetRow'): rownum = evt.GetRow()
	else: rownum = self.GetGridCursorRow()
	row = self.recordset.row (rownum)
	print >>sys.stderr, "MyGrid.do_write(%d):" % rownum
	try: 
	    self.recordset.write (row)
	except jdb.dbapi.Error, excep: 
	    msg = "Unable to write to database. \n" \
		"SQL was: %s\n" \
		"SQL args were: %r\n" \
		"Error was: %s" % (excep.sql, excep.sqlargs, unicode (excep))
	    dialog (self, msg, "Database Error", wx.ICON_ERROR) 
	wx.CallAfter (self.ForceRefresh)

    def do_delete (self, evt=None):
	if evt and hasattr (evt, 'GetRow'): rownum = evt.GetRow()
	else: rownum = self.GetGridCursorRow()
	row = self.recordset.row (rownum)
	self.recordset.delete (row)
	wx.CallAfter (self.ForceRefresh)

    def keyevt (self, evt=None):
	print >>sys.stderr, "key evt=%s" % (evt.GetKeyCode()) 
	#pdb.set_trace()
	rownum = self.GetGridCursorRow()
	try: row = self.recordset.row (rownum)
	except IndexError: 
	    evt.Skip();  return
	key = evt.GetKeyCode()
	if key == wx.WXK_ESCAPE:	# WXK_ESCAPE: 
	    self.do_rvrt(); evt.Skip()
	elif key == wx.WXK_DELETE:
	    print >>sys.stderr, "MyGrid.keyevt(): deleteing row %d" % rownum
	    self.do_delete()
	    # Don't do a .Skip() -- otherwise, the del will start an
	    #   edit and delete a character.
	else: evt.Skip()

    def writeall (self, evt=None):
	for row in self.recordset.changed_rows():
	    self.recordset.write (row) 
	wx.CallAfter (self.ForceRefresh)

    def revertall (self, evt=None):
	for row in self.recordset.changed_rows():
	    self.recordset.revert (row) 
	wx.CallAfter (self.ForceRefresh)

    def show_ctxmenu (self, evt):
	print >>sys.stderr, "ctx menu"
	self.ctxmenu.show (evt, self)
	evt.Skip()

class MyGridTable (wx.grid.PyGridTableBase):
    def __init__ (self, recordset):
	wx.grid.PyGridTableBase.__init__ (self)
	self.reload (recordset)
	Subscribe (self.delete_listener, 'delete')

    def delete_listener (self, msg):
	print >>sys.stderr, "delete listener called, rn=%d" % msg.data
	self.delete_row (msg.data)

    def reload (self, recordset):
	# Display a new recordset in this grid.
	if hasattr (self, 'rowcnt'):
	      # This is a reload as opposed to a new (first-time) load.
	      # The grid already has been created with some number of rows and
	      # columns.  We assume the number of columns doesn't change but
	      # we need to add or remove grid rows to accommadate any change  
	      # in the number of data rows.self.oldrowcnt
	    rowdelta = len (recordset.data) - self.rowcnt
	    change_number_of_rows (self, rowdelta)
	self.rs = recordset
	self.rowcnt = len (recordset.data)

    def GetNumberRows (self):  return len (self.rs.data) + 1
    def GetNumberCols (self):  return len (self.rs.cols)
    def GetColLabelValue (self, colnum): return self.rs.cols[colnum][0]

    def GetRowLabelValue (self, rownum): 
	try: stat = self.rs.edit_status (self.rs.row (rownum))
	except IndexError: stat = None
	return {None:'', 'u':u'*', 'n':u'\u2299', 'd':u'\u2715'}[stat]

    def IsEmptyCell (self, rownum, colnum):
        try: return not self.rs.data[rownum][colnum]
        except IndexError: return True

    def GetValue (self, rownum, colnum):
	try: row = self.rs.data[rownum]
        except IndexError: return ''
	v = self.rs.getcurval (row, self.rs.cols[colnum][0])
	if v is None or v is Unset: vstr = ''
	else: 
	    kwtbl = self.rs.cols[colnum][3]
	    if not kwtbl:         vstr = unicode(v)
	      # Map kw id values to keyword text.
	    elif kwtbl == 'STAT': vstr = (getattr (jdb.KW, kwtbl))[v].descr
	    else:                 vstr = (getattr (jdb.KW, kwtbl))[v].kw
	return vstr

    def SetValue (self, rownum, colnum, value):
	try:
            self._setvalue (rownum, colnum, value)
	except jdb.dbapi.Error, e:
	    msg = "Unable to make change. Database error was:\n%s" % str(e)
	    rv = dialog (None, msg, "Database Error", style=wx.OK|wx.ICON_ERROR)
	Notify ('rowstat')

    def _setvalue (self, rownum, colnum, value):
	v = self.cast (colnum, value)
	colname = self.rs.cols[colnum][0]
	if rownum == len (self.rs.data):
	    self.rs.add()
            change_number_of_rows (self, 1)
	#pdb.set_trace()
	self.rs.update (self.rs.data[rownum], colname, v)

    def GetTypeName (self, rownum, colnum):
        return self.rs.cols[colnum][2]

    def delete_row (self, rownum):
	print >>sys.stderr, "deleting grid table row %d" % rownum
	change_number_of_rows (self, -1, rownum)

    def cast (self, col, value):
	# Convert string data, 'value', (which is received by the
	# SetValue call) to the appropriate datatype for column number
	# 'col'.
	if value == '': return None
	  # The datatype mat be followed with additional information
	  # after a colon (e.g. list of choices for datatypr "choice") 
	  # which we get rid of with the split() call below.
	datatype = self.rs.cols[col][2].split (':')[0]
	if datatype == wx.grid.GRID_VALUE_CHOICE:
	    kwtbl = getattr (jdb.KW, self.rs.cols[col][3])
	    value = kwtbl[value].id
	elif datatype == wx.grid.GRID_VALUE_NUMBER: value = int (value)
	elif datatype == wx.grid.GRID_VALUE_BOOL: value = bool (value)
	elif datatype == wx.grid.GRID_VALUE_DATETIME: value = None      #FIXME
	elif datatype == wx.grid.GRID_VALUE_STRING: pass
	elif datatype == wx.grid.GRID_VALUE_TEXT: pass
	else: raise ValueError ('Unexpected column datatype: "%r"' % datatype)
	return value

def change_number_of_rows (gridtable, rowdelta, at=None):
	# Change the number of rows in a grid table.  This is  
	# a convenience function that unifies the interface for 
	# inserting, appending, or deleting grid table rows.
	# 
	# 'rowdelta' -- Number of rows to add (if positive) or delete
	#     if negative.
	# 'at' -- The row number (first row is 1) before which to add
	#     rows or row number of the first row to be deleted.  If not
	#     given or None, rows will be added ot deleted from the end of 
	#     the grid table.
	#
	# Note that how to do this is not documented the wxPython/wxWigets
	# docs.  See GridCustTable.py in the wxPython demo code.  

	if rowdelta == 0: return
	if at is None: at = gridtable.GetNumberRows()
	if rowdelta < 0: 
            msg = wx.grid.GridTableMessage (gridtable,         # The table.
                        wx.grid.GRIDTABLE_NOTIFY_ROWS_DELETED, # What we did to it.
		        at + rowdelta + 1,  # Index (base 1) of first row to del.
                        -rowdelta)          # How rows many to delete.
	else:
            msg = wx.grid.GridTableMessage (gridtable,         # The table.
                       wx.grid.GRIDTABLE_NOTIFY_ROWS_INSERTED, # What we did to it.
                       at,		    # Insert after this row (first row is 1).
                       rowdelta)            # How many rows to insert.
	gridtable.GetView().ProcessTableMessage (msg)

#=========================================================================

class ContextMenu (wx.Menu):
        # Create a context menu.
        # To use this class, in a frame, panel, or other widget, create the 
        # context menu object:
        #       ...
        #       self.popupmenu = MyContextMenu (('one','two','three'))
        #       p.Bind (wx.EVT_CONTEXT_MENU, self.OnShowPopup)
        #       ...
        # Create an event handler to catch the EVT_CONTEXT_MENU event,
        # and call the context menu object's show() method to display
        # the menu.  Pass the show() method the event, and the widget
        # in which the context menu will be shown:
        #    def OnShowPopup (self, event):
        #       self.popupmenu.show (event, self.panel)
        # As instantiated above, the selected item can be retrieved from 
        # the ".selected" attribute of the context menu object,after :
        #       print "you selected %s" % self.popupmenu.selected
        #
        # Alternatively, you can provide a menu selection handler for
        # each menu item:
        #       ...
        #       self.popupmenu = MyContextMenu ((('one',self.m1),
        #   			('two',self.m2),('three',self.m3)))
        #       p.Bind (wx.EVT_CONTEXT_MENU, self.OnShowPopup)
        #       ...
        #    def OnShowPopup (self, event):
        #       self.popupmenu.show (event, self.panel)
        #    def m1 (self, event): print "you select one"
        #    def m2 (self, event): print "you select two"
        #    def m3 (self, event): print "you select three"

    def __init__ (self, items, func=None):
	  # items may be a list of text items, each of which will create
	  # a menu item, or a list of 2-tuples consisting of the menu text
	  # and a selection handler function for that menu item.  Any of 
	  # functions may be None.  When item is processed, any function
          # values that are None will be replaced with  the optional second
	  # argumuent, 'func', and if that is None, by an internal handler.
	  # The internal handler will set an attribute, "selection" on the
	  # context menu object to the text value of the selection.

	wx.Menu.__init__(self)
	self.selected = None
        for text in items:
	    if isinstance (text, (str, unicode)): _func = None
	    else: text, _func = text
            item = self.Append (-1, text)
	    #print >>sys.stderr, "ctx menu setup, item=%s, funcs=%r" % (text, (_func,func,self.intern_handler))
            #self.Bind (wx.EVT_MENU, _func or func or self.intern_handler, item)
            self.Bind (wx.EVT_RIGHT_DOWN,  _func or func or self.intern_handler, item)

    def intern_handler (self, event):
        item = self.FindItemById (event.GetId())
	#print >>sys.stderr, "selected %s" % item.GetText()
        self.selected = item.GetText()

    def show (self, event, panel):
        pos = event.GetPosition()
        pos = panel.ScreenToClient (pos)
        panel.PopupMenu (self)

#=========================================================================

class RecordSet:
    def __init__ (self, cursor, tablename, data, cols): 
	self.cursor = cursor
	self.table = tablename
	self.cols = cols
	self.data = data

	# self.data is a sequence of DbRow objects as retrieved 
	# from the database  
	# Each row object represents the the value of the row as we 
	# believe it to currently exists in the database, with changes
	# to be made to it stored in an attribute, "_changed".  
	#
	# Rows may be in one of four states as determined by the two
	# attributes, "_changed" and "EDITSTAT".  If attribute,"_changed"
	# exists, its value is a dict of colname, value items.  If attribute
	# "EDITSTAT" exists, its value is either "n" or "d".
	# 
	#  Original -- Row has neither a "_changed" or "EDTSTAT" attribute.
	#    Is an unchanged copy of the row as it exists in the database
	#    and no changes are pending.
	#  Changed -- Has a "_changed" attribute but no "EDITSTAT attribute. 
	#    Row is a copy of a original database row but attribute ._changed
	#    contains a changes to be applied to row when the row is updated 
	#    in the database.
	#  New -- Has a "_changed" attribute, and an "EDITSTAT" attribute with
	#    a value of "n".  The row itself has attributes having Unset values
	#    but attribute "_changed" contains a dict of new values to be used
	#    when the new row is writtn to the database.
	#  Deleted -- A copy of a database row but attribute "EDITSTAT" is "d".
	#    Attribute "_changed" may or may not exist depending on whether or
	#    not the row was edited before being marked for delete.
	#
	# Any of four actions may be applied to a row: 
	# The following table gives the activity performed for each of these 
	# actions applied to rows having each of the four states:
	#
	#   Row state	Action		Result
	#   Original	Update		The change is recorded in row attribute ._changed
	#				  and status becomes changed.
	# 		Delete		The row status changed to deleted.
	#		Revert		No action
	#		Write		No action
	#
	#   Changed	Update		The change is recorded in row attribute ._changed.
	#		Delete		Confirm, then change status to deleted, (remove _changed?).	
	#		Revert		Remove the .changed info.
	#		Write		Write the row w/changes back to database, replace
	#				  with freshly read copy of the row, change status to original. 
	#
	#   Deleted	Update		Error, require revert first.
	#   		Delete		No action
	#		Revert		Change status from deleted to original.
	#		Write		Delete the row in database [requires rebuild of entry object]
	#
	#   New		Update		The change is recorded in row attribute ._changed.
	#		Delete		Remove the row from recordset.
	#		Revert		Remove the row from recordset. 
	#		Write		Write the row w/changes back to database, replace
	#				  with freshly read copy of the row.
	# Notifications:
	# data -- (no arg) Sent when a data change occurs that requires a
	#   rebuild of the Entr object displayed in the main window.
	# rowstat -- (No arg) When a insert, update or delete operation is
	#   successfully performed on the database.  This event indicates a
	#   commit is needed to permanently save the changes.
	# dbdirty -- Arg=true when an uncommitted insert, update, or delete
	#   is made to the database.  Arg=false when a commit is done. 
	# 
	# Because changes made during editing may be inconsistent (refer to
	# and entry id that doesn't exist, etc, we do not notify any listeners
	# of such changes since they may not be prtepared to handle such
	# invalid state.  Notification is only done when changes are made
	# to the data in the database. 

    def row (self, rownum):
	# Return the row indexed by 'rownum'.
	#if not isinstance (rownum, int): return rownum
	return self.data[rownum]

    def rownum (self, row):
	# Return the index of 'row'. 
	for n,r in enumerate (self.data):
	    if r is row: return n
	else: raise RuntimeError ("Recordset.revert: row not found")

    def edit_status (self, row):
	# Return None, 'u', 'n', or 'd' if the row status is respectively
	# original, updated, new, or deleted.
	if hasattr (row, 'EDITSTAT'): return row.EDITSTAT # 'n' or 'd'.
	return 'u' if hasattr (row, '_changed') else None

    def update (self, row, attr, newval):
	# Change an attribute value in an existing row.
	print >>sys.stderr, "Recordset.update: attr=%s, val=%s, row=%r" % (attr, newval, row)
	stat = self.edit_status (row)
	if stat == 'd': raise ValueError ("Can't update a deleted row, revert first")
	if newval == self.getcurval (row, attr): return
	if not hasattr (row, '_changed'): row._changed = {}
	row._changed[attr] = newval

    def delete (self, row):
	# Mark a row for deletion.
	stat = self.edit_status (row)
	print >>sys.stderr, "Recordset.delete: stat=%s, row=%r" % (stat, row)
	if stat == 'd': return
	elif stat == 'n': self.revert (row)
	else: row.EDITSTAT = 'd'
	Notify ('rowstat')

    def revert (self, row):
	# Revert all unwritten changes made to a row.
	stat = self.edit_status (row)
	if stat: print >>sys.stderr, "reverting stat=%s, row=%r" % (stat, row)
	if not stat: return
	elif stat == 'u': 
	    del row._changed;  Notify ('rowstat')
	elif stat == 'd': 
	    del row.EDITSTAT;  Notify ('rowstat')
	elif stat == 'n': 
	    rownum = self.rownum (row)
	    del self.data[rownum]
	    self._remove (rownum)
	    
    def add (self):
	# Add a new empty row at the end of the recordset.	
	row = jdb.DbRow ([None] * len (self.cols), self.colnames ())
	row._changed = dict ([(c,None) for c in self.colnames()])
	row.EDITSTAT = 'n'
	self.data.append (row)
	return row

    def _remove (self, row):
	# Remove the row from the recordset and notify the display
	# that the row is gone.  This function should be called after
	# _dbdel has sucessfully deleted the row, or when reverting 
	# a newly added but not yet written row.
	rownum = self.rownum (row)
	del self.data[rownum]
	print >>sys.stderr, "sending delete messge for row %d" % rownum
	Notify ('delete', rownum)

    def colnames (self):       return [x[0] for x in self.cols]
    def pks (self):            return [x[0] for x in self.cols if x[1]]
    def oldpkvals (self, row): return [getattr (row, pk) for pk in self.pks()]
    def newpkvals (self, row): return [self.getcurval (row, pk) for pk in self.pks()]

    def getcurval (self, row, attr):
	# Return the "current" value of an attribute 'attr' in 'row' which
	# is a changed value if any, otherwise the value in 'row' which is
	# what is the value most recently written to the database (though
	# not necessarily commited.)
	stat = self.edit_status (row)
	if stat == None:
	    return getattr (row, attr)
	elif stat == 'u':
	    try: return row._changed[attr]
	    except (AttributeError,KeyError): return getattr (row, attr)
	elif stat == 'n':
	    # All changes are in ._changed.
	    return row._changed[attr]
	elif stat == 'd':
	    #return '*deleted*'
	    try: return row._changed[attr]
	    except (AttributeError,KeyError): return getattr (row, attr)
	else: raise RuntimeError ("Recordset.getcurval: Bad 'stat' value")

    def has_changes (self):
	for row in self.data:
	    if self.edit_status (row): return True
	return False

    def changed_rows (self):
	# Return a list of rows that have pending changes.
	return [row for row in self.data if self.edit_status(row)]

    def revert_all (self):
	# Undo all unwritten changes made to this recordset. 
	# row is 'rownum' not given or None.
	for row in self.changed_rows(): self.revert (row)

    # The following methods may write changes to the database an thus
    # need to notify listeners of that fact.  write() wand write_all()
    # are the only public interfaces.

    def write_all (self):
	# Write all unwritten changes to the database.
	chgd_rows = self.changed_rows()
	if chgd_rows:
	    for row in self.changed_rows(): 
		self.write (row, nonotify=True)
	    Notify ('data')

    def write (self, row, nonotify=False):
	stat = self.edit_status (row)
	print >>sys.stderr, "Recordset.write: stat=%s, row=%r" % (stat, row)
	if not stat: return
	elif stat == 'd': 
	    pkvals = self.oldpkvals (row)
	    self._dbdel (pkvals)
	    self._remove (row)
	elif stat == 'n': 
	    self._dbins (row._changed)
	elif stat == 'u': 
	    pkvals = self.oldpkvals (row)
	    self._dbupd (pkvals, row._changed)
	if stat == 'u' or stat == 'n':
	    self._dbreread (self.newpkvals (row), row, nonotify)


    def _dbreread (self, pkvals, row, nonotify=False):
	# Update the values in 'row' from the database row with the 
	# primary key values 'pkvals'.  We need to update the row because 
	# default values or triggers may have changed what is in the database 
	# compared to what the row thinks is in the database.  Of course
	# triggers may have changed other rows but not much we can do about
	# that without reloading the entire recordset.
	#
	# CAUTION: Some rows may have additional information (e.g. augmented
	# Xref rows) that may no longer be consistent with the updated field
	# values. 

	colnames = self.colnames()
	cols = ','.join (colnames)
	whr = " AND ".join ('%s=%%s' % k for k in self.pks())
	sql = "SELECT %s FROM %s WHERE %s" % (cols, self.table, whr)
	print >>sys.stderr, "Recordset.dbreread: %s / %r" % (sql, pkvals)
	try: self.cursor.execute (sql, pkvals)
	except jdb.dbapi.Error, excep: 
	    excep.sql = sql;  excep.sqlargs = args
	    raise excep 
	rs = self.cursor.fetchall ()
	if len (rs) != 1: raise RuntimeError ("Oh shit")
	for c,v in zip (colnames, rs[0]):  setattr (row, c, v)
	if hasattr (row, 'EDITSTAT'): del row.EDITSTAT
	if hasattr (row, '_changed'): del row._changed
	if not nonotify: Notify ('data')

    def _dbupd (self, pkvals, changes):
	whr = " AND ".join ('%s=%%s' % k for k in self.pks())
	upd = ",".join ("%s=%%s" % k for k in changes.keys())
	uargs = changes.values()
	sql = "UPDATE %s SET %s WHERE %s" % (self.table, upd, whr)
	args = uargs + pkvals
	print >>sys.stderr, "Recordset._dbupd: %s / %r" % (sql, args)
	try: jdb.dbexecsp (self.cursor, sql, args)
	except jdb.dbapi.Error, excep: 
	    excep.sql = sql;  excep.sqlargs = args
	    raise excep 
	Notify ('dbdirty', True)

    def _dbins (self, changes):
	cols=[]; pmarks=[]; args=[] 
	for k, v in changes.items():
	    cols.append (k)
	    pmarks.append ('%s')
	    args.append (v)
	sql = "INSERT INTO %s (%s) VALUES(%s)" % (self.table, ','.join(cols), ','.join(pmarks))
	print >>sys.stderr, "Recordset.dbins: %s / %r" % (sql, args)
	try: jdb.dbexecsp (self.cursor, sql, args)
	except jdb.dbapi.Error, excep: 
	    excep.sql = sql;  excep.sqlargs = args
	    raise excep 
	Notify ('dbdirty', True)

    def _dbdel (self, pkvals):
	whr = " AND ".join ('%s=%%s' % k for k in self.pks())
	sql = "DELETE FROM %s WHERE %s" % (self.table, whr)
	print >>sys.stderr, "Recordset.dbdel: %s / %r" % (sql, pkvals)
	try: jdb.dbexecsp (self.cursor, sql, pkvals)	
	except jdb.dbapi.Error, excep: 
	    excep.sql = sql;  excep.sqlargs = pkvals
	    raise excep 
	Notify ('dbdirty', True)

#=========================================================================

class Model:
    def __init__ (self, cursor, tables):
	self.cursor = cursor
	self.tables = tables
	self.recordsets = {}
	self.origentrs = None
	self.sql = None
	self.sql_args = []
	self.auto_renumber = True

    def load_entries (self, sql=None, sql_args=None):
	self.cursor.execute ('ROLLBACK')
	if sql is None and sql_args is None:
	    sql = self.sql;  sql_args = self.sql_args
	else:
	    self.sql = sql;  self.sql_args = sql_args
	self.reload()
	self.cursor.execute ('BEGIN')
	Notify ('dbdirty', False)

    def reload (self):
	  # Reload the database tables from the database.
	self.entrs, data = jdb.entrList (self.cursor, self.sql, self.sql_args, ret_tuple=1)
	  # The following three lines notate the xrefs for the  
	  # benefit of the textual display.
	jdb.augment_xrefs  (self.cursor, data['xref'])
	jdb.add_xsens_lists (data['xref'])
	jdb.mark_seq_xrefs (self.cursor, data['xref'])
	self.origentrs = copy.deepcopy (self.entrs)
	for t in self.tables: 
	    self.recordsets[t] = RecordSet (self.cursor, t, data[t], self.tables[t].cols)
	Notify ('reload', self.recordsets)

    def tables_pending (self):
	# Returns a list of recordset that have pending (not
	# yet written) database writes.
	if not self.recordsets: return []
	return [tname for tname, rset in self.recordsets.items()
		 if rset.has_changes()]

    def cancel (self):
	self.cursor.connection.rollback()
	if self.sql: self.reload()
	Notify ('dbdirty', False)

    def save_all (self):
	for rs in self.recordsets.values(): rs.write_all()
	self.cursor.connection.commit()
	Notify ('dbdirty', False)

def getcols (obj, cols):
	# Return a tuple of attribute values of 'obj' where the
	# attribute names are given in list 'cols')
	return tuple ([getattr (obj, col) for col in cols])

def sortobjs (objlist, attrs):
	# Sort a list of entry objects in-place using the 
	# object's attribute names 'attrs' to determine order.
	objlist.sort (key=lambda x: getcols(x, attrs))

def rows_eq (r1, r2):
	v1 = [v for k,v in r1.__dict__.items() if not k.startswith ('_') and k[0].islower()]
	v2 = [v for k,v in r2.__dict__.items() if not k.startswith ('_') and k[0].islower()]
	return v1 == v2

def reorder_entr (obj, tables):
	# Sort all the list items (reciursively) in an Entr object
	# so that the list's order correspond to the position numbers
	# given in the list object's keys.

	for attr in obj.__dict__:
	    if not attr.startswith ('_'): continue
	      # Get the sublist.
	    oblist = getattr (obj, attr)
	      # If empty or None, ignore it.
	    if not oblist: continue
	      # The table from which this list data came from can be found from
	      # the class name of the objects in the list; the list's name is not
	      # sufficient.  (For example, both lists ._xref and ._xrer contain
	      # objects from the table 'xref' and contain Xref objects.)  Also, 
	      # some lists may not be a list at all, but rather a dict (e.g., 
	      #  ._changed) so ignore KeyErrors. 
	    try: table_name = oblist[0].__class__.__name__.lower()
	    except KeyError: continue
	      # Now, with the table name, get the table decription.
	    try: table = tables[table_name]
	    except KeyError: 
		#print >>sys.stderr, "reorder: skipping attr %s" % attr
		continue
	    sortobjs (oblist, table.pks)
	    for o in oblist: 
		reorder_entr (o, tables)

#=========================================================================

class Table (object):
    def __init__ (self, name, ordered, cols):
	self.name = name
	self.ordered = ordered
	self.cols = cols
	for n,c in enumerate (cols):
	      # If 'c' is a wx.Choice box (which we can tell by c[3] being
	      # non-None), append to c[2] (the GRID_VALUE_xxx item) a list
	      # of values that will be used as the choice selections.
	    if c[3]: 
		added_choices = c[2] + ':' + ','.join([x.kw for x in jdb.KW.recs (c[3])])
		self.cols[n] = (c[0:2] + (added_choices,) + c[3:])
	  # Pull out the names of the primary key fields and put them
	  # in a separate attribute for convenience.
	self.pks =  [z[1] for z in sorted ([(x[1],x[0]) for x in cols if x[1]>0])]
	self.data = [];

def setup_tables_descr ():
        # We initialize the tables structure below in this function rather
	# than outside because the Table.__init__() method requires access
	# to jdb.KW which is not initialized until jdb.dbOpen() is called
	# in main().  Doing the tables setup in a function allows it to 
	# be called after the jdb.dbOpen() call.

	SZ_ID  = 80;	SZ_KW  = 80;	SZ_FK  = 25;	SZ_TXT = 150
	SZ_STR = 80;	SZ_BOOL = 25;	SZ_DT = 100;

	tables = {
	    'entr':    Table ('entr', False,
			      # column   pk     wx.grid data type       dropdown  grid col
			      #  name    ord                             source    width

			      [('id',     1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('src',    0, wx.grid.GRID_VALUE_CHOICE,   'SRC',  SZ_KW),
			       ('stat',   0, wx.grid.GRID_VALUE_CHOICE,   'STAT', SZ_KW),
			       ('seq',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('dfrm',   0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('unap',   0, wx.grid.GRID_VALUE_BOOL,     None,   SZ_BOOL),
			       ('srcnote',0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT),
			       ('notes',  0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT)]),

	    'kanj':    Table ('kanj', True,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('kanj',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('txt',    0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT)]),

	    'rdng':    Table ('rdng', True,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('rdng',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('txt',    0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT)]),

	    'kinf':    Table ('kinf', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('kanj',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kw',     0, wx.grid.GRID_VALUE_CHOICE,   'KINF', SZ_KW)]),

	    'rinf':    Table ('rinf', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('rdng',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kw',     0, wx.grid.GRID_VALUE_CHOICE,   'RINF', SZ_KW)]),

	    'freq':    Table ('freq', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('rdng',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kanj',   3, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kw',     4, wx.grid.GRID_VALUE_CHOICE,   'FREQ', SZ_KW),
			       ('value',  0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK)]),

	    'grp':     Table ('grp', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('kw',     2, wx.grid.GRID_VALUE_CHOICE,   'GRP',  SZ_KW+30),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('notes',  0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT)]),

	    'hist':    Table ('hist', True,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('hist',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('stat',   0, wx.grid.GRID_VALUE_CHOICE,   'STAT', SZ_KW),
			       ('unap',   0, wx.grid.GRID_VALUE_BOOL,     None,   SZ_BOOL),
			       ('dt',     0, wx.grid.GRID_VALUE_DATETIME, None,   SZ_DT),
			       ('userid', 0, wx.grid.GRID_VALUE_STRING,   None,   SZ_STR),
			       ('name',   0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_STR),
			       ('email',  0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_STR),
			       ('diff',   0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT),
			       ('refs',   0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT),
			       ('notes',  0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT)]),

	    'sens':    Table ('sens', True,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('notes',  0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT)]),

	    'pos':     Table ('pos', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kw',     3, wx.grid.GRID_VALUE_CHOICE,   'POS',  SZ_KW)]),

	    'misc':    Table ('misc', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kw',     3, wx.grid.GRID_VALUE_CHOICE,   'MISC', SZ_KW)]),

	    'fld':     Table ('fld', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kw',     3, wx.grid.GRID_VALUE_CHOICE,   'FLD',  SZ_KW)]),

	    'dial':    Table ('dial', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kw',     3, wx.grid.GRID_VALUE_CHOICE,   'DIAL', SZ_KW)]),

	    'lsrc':    Table ('lsrc', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('lang',   3, wx.grid.GRID_VALUE_CHOICE,   'LANG', SZ_KW),
			       ('txt',    4, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT),
			       ('part',   0, wx.grid.GRID_VALUE_BOOL,     None,   SZ_BOOL),
			       ('wasei',  0, wx.grid.GRID_VALUE_BOOL,     None,   SZ_BOOL)]),

	    'xref':    Table ('xref', True,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('xref',   3, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('typ',    0, wx.grid.GRID_VALUE_CHOICE,   'XREF', SZ_KW),
			       ('xentr',  0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('xsens',  0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('rdng',   0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kanj',   0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('notes',  0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT)]),

	    'xresolv': Table ('xresolv', True,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('typ',    3, wx.grid.GRID_VALUE_CHOICE,   'XREF', SZ_KW),
			       ('ord',    4, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('rtxt',   0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_STR),
			       ('ktxt',   0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_STR),
			       ('tsens',  0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('notes',  0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT)]),

	    'gloss':   Table ('gloss', True,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('gloss',  3, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('lang',   0, wx.grid.GRID_VALUE_CHOICE,   'LANG', SZ_KW),
			       ('ginf',   0, wx.grid.GRID_VALUE_CHOICE,   'GINF', SZ_KW),
			       ('txt',    0, wx.grid.GRID_VALUE_TEXT,     None,   SZ_TXT)]),

	    'restr':   Table ('restr', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('rdng',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kanj',   3, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK)]),

	    'stagr':   Table ('stagr', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('rdng',   3, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK)]),

	    'stagk':   Table ('stagk', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('sens',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('kanj',   3, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK)]),

	    'entrsnd': Table ('entrsnd', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('snd',    2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID)]),

	    'rdngsnd': Table ('rdngsnd', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('rdng',   2, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('ord',    0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('snd',    3, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID)]),

	    'chr':     Table ('chr', False,
			      [('entr',   1, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('chr',    0, wx.grid.GRID_VALUE_STRING,   None,   SZ_FK),
			       ('bushu',  0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('strokes',0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('freq',   0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_ID),
			       ('grade',  0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('jlpt',   0, wx.grid.GRID_VALUE_NUMBER,   None,   SZ_FK),
			       ('radname',0, wx.grid.GRID_VALUE_STRING,   None,   SZ_KW)]),
	    }
	return tables

#---------------------------------------------------------------------------

def read_prefs (inifile, opts):
	pass

#---------------------------------------------------------------------------
from optparse import OptionParser

def parse_cmdline ():
	u = \
"""\n\t%prog id-num [,id-num, ...]

  %prog will display entries identified by id number of the command
  line as a tree.

arguments:  One or more entry id numbers"""

	p = OptionParser (usage=u, add_help_option=False)
	p.add_option ("--help",
            action="help", help="Print this help message.")
	opts, args = p.parse_args ()
	return args, opts

#---------------------------------------------------------------------

from optparse import OptionParser, Option

class MyOption (Option):
    ACTIONS = Option.ACTIONS + ('extend',)
    STORE_ACTIONS = Option.STORE_ACTIONS + ('extend',)
    TYPED_ACTIONS = Option.TYPED_ACTIONS + ('extend',)
    ALWAYS_TYPED_ACTIONS = Option.ALWAYS_TYPED_ACTIONS + ('extend',)

    def take_action(self, action, dest, opt, value, values, parser):
        if action == 'extend':
            lvalues = value.split( ',' )
            values.ensure_value( dest, [] ).extend( x.strip() for x in lvalues )
        else:
            Option.take_action( self, action, dest, opt, value, values, parser )

def parse_cmdline ():
	u = \
"""\n\t%prog id-num [,id-num, ...]

  %prog will display and allow direct editing of the table data that 
  consitutes the entries identified by the 'id-num's.

Arguments:  Zero or more entry id numbers.  (But see the --sql option.)"""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % __version__
	p = OptionParser (usage=u, version=v, add_help_option=False,
			  option_class=MyOption)

	p.add_option ("-s", "--sql", default=None,
            help="SQL statement returning entry id numbers in the first "
		"column that will be used to load the initial set of entries."
		"If given, any arguments are ignored.")
	p.add_option ("-c", "--config", default=".jmdbedit",
            help="Name of configuration file from which preferences are read "
		"at program startup.  If not an absolute path, the file will "
		"be searched for in a standard set of directories.")
	p.add_option ("-d", "--database", default="jmnew",
            help="Name of the database to load.  Default is \"jmnew\".")
	p.add_option ("-h", "--host",
            help="Name host machine database resides on.")
	p.add_option ("-u", "--user",
            help="Connect to database with this username.")
	p.add_option ("-e", "--encoding", default=None, 
            help="Encoding for output (typically \"sjis\", \"utf8\", "
	      "or \"euc-jp\"")
	p.add_option ("-p", "--password",
            help="Connect to database with this password.")
	p.add_option ("--help",
            action="help", help="Print this help message.")

	p.add_option ("-D", "--debug", type="int", default=0,
	    help="""If non-zero, print debugging info.""")

	opts, args = p.parse_args ()
	return args, opts

if __name__ == '__main__': 
	args, opts = parse_cmdline ()
	main (args, opts)


