#!/usr/bin/env python

_VERSION_=("$Revision$"[11:-2],"$Date$"[7:-11])

import sys, re, operator, os, tempfile, time, cgi, pdb
import wx, wx.xrc, wx.grid, wx.html, wx.lib.pubsub, wx.lib.delayedresult
import wx.lib.inspection
import jdb, fmt, fmtjel, tal, jmcgi, pylib.config
import ply, jelparse, jellex
from jelparse import ParseError
from jdb import AuthError
from functools import partial
from wxstuff import CheckListBoxCombo

global KW

def GET (*args):
 r = wx.xrc.XRCCTRL (*args)
 if not r:
  raise RuntimeError ("Unable to find item '%s' in '%s'" % (args[1], args[0].Name))
 return r
#GET = wx.xrc.XRCCTRL

def main():
	args, opts = parse_cmdline ()
	dbopts = dict()
	if opts.host: dbopts['host'] = opts.host
	cursor = jdb.dbOpen (opts.dbname, **dbopts)
	global KW; KW = jdb.KW
	model = Model (cursor)

        gui = wx.App (redirect=0)
	gui.userid = opts.authorized
	xrcres = wx.xrc.XmlResource ("srch.xrc")

	if opts.edit is not None:
	    entrs = model.get_entrs (args=[opts.edit])
	    entr = entrs[0] if entrs else None
	    frame = Frame3 (None, -1, "Edit", xrcres, model, entr)
	elif opts.srch:
	    return # For now
	else:
            frame = Frame (None, -1, "Search", xrcres, model)
	frame.Fit()
        frame.Show()
	#wx.lib.inspection.InspectionTool().Show()
        gui.MainLoop ()

# This class handles all the user-interface and GUI work.
# Window physical layout is defined in the .xrc file.

class Frame (wx.Frame):		# Main frame
    def __init__ (self, parent, id, title, xrcres, model):
	self.xrcres = xrcres
	self.model = model
	self.viewtype = 'txt'
	wx.Frame.__init__ (self, parent, id, name='srch_frame', title=title)

	self.SetMenuBar (xrcres.LoadMenuBar ("M_MAIN"))

	sizer = wx.BoxSizer (wx.VERTICAL)
	self.SetSizer (sizer)

	nb = wx.Notebook (self, -1)
	sizer.Add (nb, 1, wx.EXPAND)
	self.p1 = xrcres.LoadPanel (nb, "P_MAIN")
	self.p2 = xrcres.LoadPanel (nb, "P_ADVSRCH")

	nb.AddPage (self.p1, "Search", True)
	nb.AddPage (self.p2, "Advanced", True)
	nb.ChangeSelection(0)
	self.init();  self.p1_init();  self.p2_init (xrcres)
	self.Layout()

    def init (self):
	self.Bind (wx.EVT_MENU, self.editnew, 
		   self.MenuBar.FindItemById(wx.xrc.XRCID('editnew')))
	self.Bind (wx.EVT_MENU, self.close, 
		   self.MenuBar.FindItemById(wx.xrc.XRCID('close')))
	self.Bind (wx.EVT_MENU, lambda x: chgfontsz (self, 2), 
		   self.MenuBar.FindItemById(wx.xrc.XRCID('fontszincr')))
	self.Bind (wx.EVT_MENU, lambda x: chgfontsz (self, -2),
		   self.MenuBar.FindItemById(wx.xrc.XRCID('fontszdecr')))

    def editnew (self, evt=None):
	self.editframe = Frame3 (self, -1, "Edit New", self.xrcres, self.model, None)

    def close (self, evt=None):
	self.Close()

    def p1_init (self):
	for name,vals in gen_chkgrp_data (self.model).items():
	    d = CheckListBoxCombo (self.p1, values=vals)
	    self.xrcres.AttachUnknownControl (name, d, self.p1)

	GET (self, "srch").Bind(wx.EVT_BUTTON, self.p1_srch)
	GET (self, "reset").Bind(wx.EVT_BUTTON, self.p1_resetall)

    def p1_resetall (self, evt=None):
	for n in 1,2,3:
	    GET (self.p1, 'srchin'+str(n)).SetSelection (0)
	    GET (self.p1, 'srchtype'+str(n)).SetSelection (0)
	    GET (self.p1, 'srchtext'+str(n)).SetValue ('')
	GET (self.p1, 'idnum').SetValue ('')
	GET (self.p1, 'idtype').SetSelection (0)

    def p1_srch (self, evt=None):
	  # Extract values from controls into a generic object.
	so = cntls2so (self.p1)
	  # Generate a search condition list from the search object fields.
	conds = jmcgi.so2conds (so)
	  # Generate an executable sql statement from the condition list.
	sql, args = jdb.build_search_sql (conds)
	  # Create a Results frame.  As part of its initialization, it 
	  # will execute the sql in order to get the resultset.
	frame2 = Frame2 (self, -1, "Results", self.xrcres, self.model, sql, args, size=(800,350))

    def p2_init (self, xrcres):
	self.advdirty = False
	nb = GET (self.p2, 'nb')
	p3 = xrcres.LoadPanel (nb, "P_ADVHELP")
	p4 = xrcres.LoadPanel (nb, "P_ADVSQL")
	nb.AddPage (p3, "Help")
	nb.AddPage (p4, "SQL")

	self.ssinitfn = "jmdbss.txt"
	self.ss = pylib.config.Config()
	self.ss.read (open(self.ssinitfn)) 
	for x in self.ss.keys(): GET (self.p2, "srchs").Append (x)
	self.ss_new_sql = GET (self.p2, "sql").GetValue()
	self.ss_new_help = GET (self.p2, "help").GetValue()
	self.sscurrent = 0
	self.ssdirty = set()

	GET (self.p2, "srch").Bind(wx.EVT_BUTTON, self.p2_srch)
	GET (self.p2, "save").Bind(wx.EVT_BUTTON, self.p2_save)
	GET (self.p2, "delete").Bind(wx.EVT_BUTTON, self.p2_delete)
	GET (self.p2, "clear").Bind(wx.EVT_BUTTON, self.p2_resetall)
	GET (self.p2, "srchs").Bind(wx.EVT_CHOICE, self.p2_choice)
	GET (self.p2, "srchs").Bind(wx.EVT_COMBOBOX, self.p2_choice)
	GET (self.p2, "sql").Bind(wx.EVT_TEXT, self.p2_dirty)
	GET (self.p2, "help").Bind(wx.EVT_TEXT, self.p2_dirty)
	GET (self.p2, "sql").Bind(wx.EVT_KILL_FOCUS, self.p2_wrtbk)
	GET (self.p2, "help").Bind(wx.EVT_KILL_FOCUS, self.p2_wrtbk)

    def p2_dirty (self, evt=None):
	cntl = evt.EventObject
	sb = GET (self.p2, "save")
	if not sb.IsEnabled(): sb.Enable()

    def p2_wrtbk (self, evt=None):
	cntl = evt.EventObject
	if cntl.IsModified():
	      # Get name from .Value() because user
	      # may have have changed it. 
	    name = GET (self.p2, "srchs").GetValue()
	    # FIXME: check name in [a-zA-Z0-9_ whatever...].  Use validator?
	    if name != GET (self.p2, "srchs").GetValue():
		# FIXME: need popup dialog here.
		print "Warning: Overwriting a different saved search."
	    self.ss[name][cntl.GetName()] = cntl.GetValue()
	    self.ssdirty.add (self.sscurrent)
	    cntl.SetModified (False)

    def p2_save (self, evt=None): 
	print"save: sscurrent=%d, dirty=%r" % (self.sscurrent, self.ssdirty)
	if self.sscurrent not in self.ssdirty: return
	cur_name = GET (self.p2, "srchs").GetValue()
	if self.sscurrent == 0:
	      # This is a new search.
	    if not cur_name: pass
		# Warning, you must give a name to this new saved search.
	    # Check for duplicate of existing?
	    cfg_update (self.ssinitfn, name, self.ss[name])
	else:
	      # This is an update to an existing saved search.
	    prev_name, x = self.ss.atpos (self.sscurrent)
	    # FIXME: check name: warn if is same as another one?
	    ###if cur_name != prev_name: self.ss.changekey (self.sscurrent, cur_name)
	    cfg_update (self.ssinitfn, name, self.ss[name], self.sscurrent)
	self.ssdirty.remove (self.sscurrent)
	GET (self.p2, "save").Enable (False)	

    def p2_saveall (self, evt=None):
	cfg_writeall (self.ssinitfn, self.ss)
	seldf.ssdirty = Set()

    def p2_choice (self, evt=None): 
	print"choice: sscurrent=%d, dirty=%r" % (self.sscurrent, self.ssdirty)
	if self.sscurrent in self.ssdirty: pass  # warning dialog
	    # if wx.CANCEL: return
	    # if wx.OK: save_previous, idx in self.sscurrent
	idxnum = GET (self.p2, "srchs").GetSelection()
	self.p2_updview (idxnum)

    def p2_updview (self, idxnum=None):
	print"updview: idxnum=%r, sscurrent=%d, dirty=%r" % (idxnum, self.sscurrent, self.ssdirty)
	srchs = GET (self.p2, "srchs")
	if not idxnum: idxnum = srchs.GetSelection()
	else:
	    if srchs.GetSelection() != idxnum: srchs.SetSelection (idxnum)
	self.sscurrent = idxnum
	print "updview: new sscurrent = %r" % idxnum
	if idxnum == 0:
	    GET (self.p2, 'sql').ChangeValue (self.ss_new_sql)
	    GET (self.p2, 'help').ChangeValue (self.ss_new_help)
	else:
	    x = self.ss[srchs.GetValue()]
	    GET (self.p2, 'sql').ChangeValue (x['sql'])
	    GET (self.p2, 'help').ChangeValue (x['help'])
	GET (self.p2, 'save').Enable (idxnum in self.ssdirty)

    def p2_srch (self, evt=None): 
	sql = GET (self.p2, "sql").GetValue()
	args = []
	for p in "p1 p2 p3 p4".split():
	    pval = GET (self.p2, p).GetValue()
	    if pval: args.append (pval)
	frame2 = Frame2 (self, -1, "Results", self.xrcres, self.model, sql, args, size=(800,350))

    def p2_delete (self, evt=None): 
	if self.sscurrent <= 1: 
	    # FIXME: warning dialog
	    print "can't delete new entry."
	    return
	name = GET (self.p2, "srchs").GetValue()
	GET (self.p2, "srchs").Delete (self.sscurrent)
	del self.ss[name]
	cfg_update (self.ssinitfn, name, None)
	self.updview (0)

    def p2_resetall (self, evt=None): pass 
	# If "new srch" page, restore default messages
	# otherwise restore sql,help from last saved (config file )

def cfg_update (filename, section_name, section, index=None):
	"""Update one section of a config file.  
	If index is None or not given:
	If a section with name 'section_name' exists in the file, it will be
	replaced by 'section'.  Otherwise a new section named 'section_name'
	is added at the end of the file.
	If index is given it is an integer and the section at that position
	will be replaced by a section 'section' with name 'section_name'.
	In either of the above cases, if 'section' is None, the section 
	will be deleted from the file."""

	f = open (filename, 'r+')
	cfg = pylib.config.Config()
	cfg.read (f)
	if index is not None:
	    oldname, oldsection = cfg.atpos (index)
	    if oldname != section_name:
		cfg.changepos (index, section_name)
	if section:
	    cfg[section_name] = section
	else:
	    del cfg[section_name]
	f.seek (0)
	f.writelines (list(cfg.write()))
	f.close()

def cfg_writeall (filename, cfg):
	f = open (filename, 'w')
	f.write (cfg.write())
	f.close()

# Map the gui text box strings to the values expected
# by jdb.autocond()...
Map_srchin = {'Auto':1, 'Kanji':2, 'Readings':3, 'Gloss':4}
Map_srchtyp = {'Is':1, 'Starts':2, 'Contains':3, 'Ends':4}

def cntls2so (p1):
	"""Extract search critera from a set of controls on a panel
	and bundle into a generic object.  All controls are assumed 
	to be located on a single panel ('p1')and are referenced by
	their names.  Control names are hardwired in the code."""

	 # Note: _sa() calls below are like setattr(obj,attr,val) except
	 # they don't do anything if 'val' does not have a true value.

	o = jmcgi.SearchItems()
	idnum = GET (p1, 'idnum').GetValue()
	if idnum:
	    o.idnum = int (idnum)
	    idtyp = GET (p1, 'idtype').GetSelection()
	    if idtyp == 1:    # Id Number
		o.idtyp = 'id'
	    elif idtyp == 0:  # Seq Number
		o.idtyp ='seq'
		_sa (o, 'src', GET (p1, 'src').GetSelectedStrings())
	    else: raise ValueError ("Bad 'idtyp' value")
	    return o

	tlist = []
	for n in 1,2,3:
	    txt = GET (p1, 'srchtxt' + str(n)).GetValue()
	    if txt:
		o2 = jmcgi.SearchItemsTexts (srchtxt=txt)
		_sa (o2, 'srchin',
		    Map_srchin[GET (p1, 'srchin'+str(n)).GetStringSelection()])
		_sa (o2, 'srchtyp', 
		    Map_srchtyp[GET (p1, 'srchtyp'+str(n)).GetStringSelection()])
		tlist.append (o2)
	_sa (o, 'txts',   tlist)
	for name in "pos misc fld kinf rinf src stat unap freq".split():
	    _sa (o, name, GET (p1, name).GetSelectedStrings())
	for name in 'nfval', 'gaval':
	    _sa (o, name, GET (p1, name).GetValue())
	for name in 'nfcmp', 'gacmp':
	    _sa (o, name, GET (p1, name).GetStringSelection())
	return o

def _sa (obj, attr, val):
	"""Set attribute 'attr' on object 'obj' to 'val' only
	if 'val' has a true value."""

	if val: setattr (obj, attr, val)

def chgfontsz (window, factor):
	_fontsz (window, factor)
	window.Layout()

def _fontsz (window, factor):
	if isinstance (window, wx.grid.Grid): 
	    _gridfontsz (window, factor)
	if isinstance (window, wx.html.HtmlWindow): 
	    _htmlfontsz (window, factor)
	else:
	    font = window.GetFont()
	    _fontadjsz (font, factor)
	    window.SetFont (font)
	    for c in window.GetChildren(): _fontsz (c, factor)

def _fontadjsz (font, factor):
	sz = font.GetPointSize()
	newsz = sz + factor
	font.SetPointSize (newsz)

def _gridfontsz (window, factor):
	font = window.GetLabelFont()
	_fontadjsz (font, factor)
	window.SetLabelFont (font)

	font = window.GetDefaultCellFont()
	_fontadjsz (font, factor)
	window.SetDefaultCellFont (font)
	window.ForceRefresh()

def _htmlfontsz (window, factor):
	pdb.set_trace()
	fszs = [
	    wx.html.wxHTML_FONT_SIZE_1,
	    wx.html.wxHTML_FONT_SIZE_2,
	    wx.html.wxHTML_FONT_SIZE_3,
	    wx.html.wxHTML_FONT_SIZE_4,
	    wx.html.wxHTML_FONT_SIZE_5,
	    wx.html.wxHTML_FONT_SIZE_6,
	    wx.html.wxHTML_FONT_SIZE_7, ]
	fszs = [x+factor for x in fszs]
	print repr(fszs)
	window.SetFonts ("", "", fszs)

class Frame2 (wx.Frame):		# Results frame
    Inst_cnt = 0
    def __init__ (self, parent, id, title, xrcres, model, sql, sql_args, size=(-1,-1)):
	wx.Frame.__init__ (self, parent, id, name='results_frame', title=title, size=size)
	sizer = wx.BoxSizer (wx.VERTICAL)
	self.SetSizer (sizer)

	self.model = model
	self.xrcres = xrcres # Need for instantiating Edit frame in self.edit()
	self.entrs = []
	self.htmlview = 0
	self.rowpos = 0
	self.Inst_cnt += 1

	self.SetMenuBar (xrcres.LoadMenuBar ("M_RESL"))

	panel3 = self.panel3 = xrcres.LoadPanel (self, "P_WAIT")
	sizer.Add (panel3, 1, wx.EXPAND)

	self.panel2 = xrcres.LoadPanel (self, "P_RESL")
	sizer.Add (self.panel2, 1, wx.EXPAND)

	self.nb = GET (self, "notebook")

	grid_panel = xrcres.LoadPanel (self.nb, "P_GRID")
	self.nb.AddPage (grid_panel, "Srch Results", True)
	self.grid = GET (grid_panel, "grid")

	html_panel = xrcres.LoadPanel (self.nb, "P_HTML")
	self.nb.AddPage (html_panel, "Entry Details", True)
	self.html = GET (html_panel, "html")
	self.html.SetFonts ("Arial Unicode MS", "MS Gothic")

	self.colinfo = \
	   [('entrID',60),('Corp',60),('Seq',60),('St',20),('P',20),
	    ('Kanji',170),('Read',170),('Gloss',250),]

	self.b_next  = GET (self, "b_next")
	self.Bind(wx.EVT_BUTTON, lambda x: self.move (self.rowpos+1, x), self.b_next )
	self.b_prev  = GET (self, "b_prev")
	self.Bind(wx.EVT_BUTTON, lambda x: self.move (self.rowpos-1, x), self.b_prev )
	self.b_last  = GET (self, "b_last")
	self.Bind(wx.EVT_BUTTON, lambda x: self.move (999999999,     x), self.b_last )
	self.b_first = GET (self, "b_first")
	self.Bind(wx.EVT_BUTTON, lambda x: self.move (-999999999,    x), self.b_first )
	self.b_edit  = GET (self, "edit")
	self.Bind(wx.EVT_BUTTON, self.edit, self.b_edit )
	self.b_editnew  = GET (self, "new")
	self.Bind(wx.EVT_BUTTON, self.editnew, self.b_editnew )

	self.abortEvent = wx.lib.delayedresult.AbortEvent()
	self.Bind(wx.EVT_BUTTON, self.abort_evt, GET (panel3, 'b_abort'))

	self.Bind(wx.EVT_END_PROCESS, self.OnProcessEnded)

	self.htmlview = menugrp (self, ('view_html','view_text','view_jel'),
			                self.chng_view)
	self.Bind (wx.EVT_MENU, self.showsrc, 
		   self.MenuBar.FindItemById(wx.xrc.XRCID('show_src')))

	self.Bind (wx.EVT_MENU, lambda x: self.move(0, x), 
		   self.MenuBar.FindItemById(wx.xrc.XRCID('refresh')))

	self.Bind (wx.EVT_MENU, lambda x: chgfontsz (self, 2), 
		   self.MenuBar.FindItemById(wx.xrc.XRCID('fontszincr')))
	self.Bind (wx.EVT_MENU, lambda x: chgfontsz (self, -2),
		   self.MenuBar.FindItemById(wx.xrc.XRCID('fontszdecr')))

	self.Bind (wx.EVT_NOTEBOOK_PAGE_CHANGED, self.page_changed)
	self.Bind (wx.grid.EVT_GRID_SELECT_CELL, self.grid_select)
	self.Bind (wx.html.EVT_HTML_LINK_CLICKED, self.OnLinkClicked)

	self.panel3.Show(); self.panel2.Hide()
	self.Layout()
	self.abortEvent.clear()

	if 0:
 	    wx.lib.delayedresult.startWorker (
		self.data_ready,  self.find_data, 
        	wargs=(sql, sql_args), jobID=self.Inst_cnt)
	else:
	    entrs = self.find_data (sql, sql_args)
	    self.present_data (entrs)

	self.Show()	# Shows the "waiting..." panel.

    def page_changed (self, evt=None):
	#print "pagechg"
	page = evt.GetSelection()
	if page == 0: # Grid
	    self.grid.SetGridCursor (self.rowpos, 0)
	self.moved ()

    def grid_select (self, evt):
	#print "grid_sel(evt.Row=%r), rowpos=%r" % (evt.Row, self.rowpos)
	row = evt.Row
	self.moved (row)
	if evt: evt.Skip()

    def move (self, pos, evt=None):
	# Called when row position is to be moved, typically by the
	# record nav buttons or the keyboard arrow keys.
	#print "move(pos=%r), rowpos=%r" % (pos, self.rowpos)
	if pos is None: pos = self.rowpos
	last = len (self.entrs) - 1
	if pos > last: pos = last
	if pos < 0:  pos = 0
	if self.nb.GetSelection() == 0: 
	    self.grid.SetGridCursor (pos, 0)
	    # No need to call .moved() here since the the SetGridCursor()
	    # call will generate a GRID_SELECT_CELL event which will call
	    # .grid_select() which will call .moved()
	else: 
	    self.moved (pos, evt)

    def moved (self, pos=None, evt=None):
	# Called after the row position has been moved, typically by
	# call to .move() or by a grid cursor movement event.
	#print "moved(pos=%r), rowpos=%r" % (pos, self.rowpos)
	if pos is None: pos = self.rowpos
	last = len (self.entrs) - 1
	if pos > last: pos = last
	if pos < 0:  pos = 0
	self.b_prev.Enable  (pos > 0)
	self.b_first.Enable (pos > 0)
	self.b_next.Enable (pos < last)
	self.b_last.Enable (pos < last)
	self.rowpos = pos
	if last < 0: GET (self, 'recnum').SetValue ('')
	else: GET (self, 'recnum').SetValue (str(pos + 1))
	GET (self, 'reccnt').SetValue (str(len(self.entrs)))
	if self.nb.GetSelection() == 1:
	    e = [self.entrs[self.rowpos]] if self.entrs else None
	    html_update (self.html, e, self.htmlview)
	elif self.nb.GetSelection() == 0:
	    self.nb.Layout()
	    if not self.grid.IsVisible (self.rowpos, 0, 1):
		self.grid.MakeCellVisible (self.rowpos, 0)

    def OnLinkClicked (self, evt=None):
	href = evt.GetLinkInfo().GetHref()
	#print "OnLinkClicked, href=%r" %href		#####
	url, qs = href.split('?')
	#print "url=%s, qs=%s" % (url,qs)		#####
	if url != 'entr': return
	#evt.Skip()
	d = cgi.parse_qs (qs)
	#print "d=%r" % d				#####
	vals = [int(x) for x in d['e']]
	#print "vals=%r" % vals				#####
	self.getxref (vals)

    def getxref (self, eids):
	eid = eids[0]	# Only works for one target currently:
	have = -1	# If there are multiple targets and some we
			# already have and others are added to the
			# the end of the entr list, which one do we 
			# move to?
	  # Look to see if we already have the desired entry.
	for n,e in enumerate (self.entrs):
	    if eid == e.id:
		have = n;  break
	if have < 0:
	      # If not, we need to read it from the database.
	    elist = self.model.get_entrs (args=eids)
	    if not elist: raise RuntimeError ("'dis shoulda neva happa.")
	    self.entrs.extend (elist)
	    self.grid.GetTable().DataUpdated()
	    have = len(self.entrs) - 1
	self.move (have)

    def showsrc (self, evt=None):
        fd,fn = tempfile.mkstemp ('.txt', text=True)
	os.write (fd, self.html.src.encode('utf-8'))
	os.close (fd)
        self.process = wx.Process(self)
        pid = wx.Execute('notepad "%s"' % fn, wx.EXEC_ASYNC, self.process)
	time.sleep (1)  # Allow time for process to start and open file before deletion.
	os.unlink (fn)

    def edit (self, evt=None):
	if not self.entrs: return
	self.editframe = Frame3 (self, -1, "Edit", self.xrcres, self.model,
			 	 self.entrs[self.rowpos])

    def editnew (self, evt=None):
	self.editframe = Frame3 (self, -1, "Edit New", self.xrcres, self.model, None)

    def chng_view (self, idx, evt=None):
	if self.htmlview != idx:
	    self.htmlview = idx
	    self.moved()

    def find_data (self, sql, sql_args):
	# This function is run in a separate thread.
	print sql, sql_args
	tmptbl = self.model.find_entrs (sql, sql_args)
	#except StandardError, e:  return e
	#if self.abortEvent(): return None
	data = self.model.get_entrs (tmptbl)
	#except StandardError, e: return e
	return data

    def data_ready (self, delayedResult):
	rv = delayedResult.get()
	if rv is None: self.Close() 
	if isinstance (rv, StandardError): raise rv
	self.present_data (rv)

    def present_data (self, entrs):
	self.entrs = entrs
	GET (self, 'reccnt').SetValue (str(len(self.entrs)))
	clabels = [x[0] for x in self.colinfo]
	csizes  = [x[1] for x in self.colinfo]
	gridtab = EntrGridtab (clabels, self.entrs)
	self.grid.SetTable (gridtab, takeOwnership=True)
	grid_init (self.grid, csizes)
	if len(self.entrs) == 1: page = 1
	else: page = 0
	self.nb.ChangeSelection (page)
	self.moved (0)
	self.panel3.Hide(); self.panel2.Show()
	self.Layout()
	#self.RequestUserAttention()

    def abort_evt (self, evt=None): 
	print "Aborting..." 
        self.abortEvent.set()
	self.Close()

    def OnProcessEnded (self, evt):
        self.process.Destroy()
        self.process = None


def html_update (self, entrs, view):
	if entrs:
	    if view == 0:	# html
		txt = tal.fmt_simpletal ('srch.tal', entrs=entrs)
	    elif view == 1:	# text
		entrstxt = [fmt.entr (e) for e in entrs]
		txt = tal.fmt_simpletal ('srcht.tal', entrs=entrstxt)
	    elif view == 2:	# jel
		entrstxt = [fmtjel.entr (e) for e in entrs]
		txt = tal.fmt_simpletal ('srcht.tal', entrs=entrstxt)
	    else:
		raise ValueError ('Bogus view argument')
	else: txt = ''
	html_setsrc (self, txt)

def html_setsrc (self, src=None):
	if not hasattr (self, 'src'): self.src = ''
	if src is not None: self.src = src
	self.SetPage (self.src)

def grid_init (self, colsizes):
	self.SetRowLabelSize (15)
	self.SetColLabelSize (25)
	for n,sz in enumerate (colsizes):
	    self.SetColSize (n, sz)

def menugrp (frame, menuitem_names, handler):
	group = [];  default = None
	for n,name in enumerate (menuitem_names):
	    menuitem = frame.MenuBar.FindItemById (wx.xrc.XRCID(name))
	    group.append (menuitem)
	    if menuitem.IsChecked():
		if default is not None: 
		    raise RuntimeError ("Multiple menuitems checked by default in group")
		else: default = n
	for menuitem in group:
	    frame.Bind (wx.EVT_MENU, partial (check1_evt, frame, group, handler), menuitem)
	if default is None: raise RuntimeError ("No menu item checked by default in group")
	return default

def check1_evt (frame, group, handler, evt):
	c = evt.IsChecked()
	for x in group:
	    if c:
		if x.Id != evt.Id: x.Check(False)
		else: handler (group.index(x))
	    if not c and x.Id == evt.Id: x.Check(True)

class EntrGridtab (wx.grid.PyGridTableBase):
    def __init__(self, clabels, entrs): 
        wx.grid.PyGridTableBase.__init__(self) 
	self.clabels = clabels
	self.kw = KW
	self.entrs = entrs
	self.nentrs = len(entrs)
    def GetNumberRows (self): return len(self.entrs)
    def GetNumberCols (self): return len(self.clabels)
    def IsEmptyCell (self, rownum, colnum): return False
    def GetValue (self, rownum, colnum):
	row = self.entrs[rownum]
	if   colnum == 0: return row.id
	elif colnum == 1: return self.kw.SRC[row.src].kw
	elif colnum == 2: return row.seq
	elif colnum == 3: return stat_abbr (row)
	elif colnum == 4: return 'P' if jdb.is_p (row) else ' '
	  # u'\uFF1B' is a wide semicolon.
	elif colnum == 5: return u"\uFF1B".join ([k.txt for k in row._kanj])
	elif colnum == 6: return u"\uFF1B".join ([r.txt for r in row._rdng])
	elif colnum == 7: return u"/".join ([u"; ".join ([g.txt for g in s._gloss]) 
							       for s in row._sens])
    def SetValue (self, rownum, colnum, value): return
      # We must provide the above five method overrides...
    def GetRowLabelValue (self, rownum): return " "
    def GetColLabelValue (self, colnum): return self.clabels[colnum]
      # Approve changes to the number of rows...
    def DeleteRows(self, pos, numRows): return True
    def InsertRows(self, pos, numRows): return True
    def AppendRows(self, numRows): 
	print "table base: APPENDING %d ROWS" % numRows
	return True
    def DataUpdated(self):
	  # Call this method to inform the grid after a change has been made
	  # (rows added or deleted) from the data source table referenced
	  # by self.entrs.  Ref: http://wiki.wxpython.org/UpdatingGridData
 	msg = None; curNumRows = self.nentrs; newNumRows = len(self.entrs)
        if newNumRows < curNumRows:
            msg = wx.grid.GridTableMessage(self,
                        wx.grid.GRIDTABLE_NOTIFY_ROWS_DELETED,
                        curNumRows - newNumRows,    # position
                        curNumRows - newNumRows)    # how many
        if newNumRows > curNumRows:
            msg = wx.grid.GridTableMessage(self,
                        wx.grid.GRIDTABLE_NOTIFY_ROWS_APPENDED,
                        newNumRows - curNumRows)    # how many
        if msg: self.GetView().ProcessTableMessage(msg)
        msg = wx.grid.GridTableMessage(self, wx.grid.GRIDTABLE_REQUEST_VIEW_GET_VALUES)
        self.GetView().ProcessTableMessage(msg)
	self.nentrs = len (self.entrs)


class Frame3 (wx.Frame):  # from srch.py
    def __init__ (self, parent, id, title, xrcres, model, entr):
	self.model = model
	self.xrcres = xrcres
	userid = wx.GetApp().userid
	self.authed = self.model.get_ed (userid) if userid else None 
	self.entr = entr
	wx.Frame.__init__ (self, parent, id, title)
	self.SetMenuBar (xrcres.LoadMenuBar ("M_EDIT"))
        self.panel = xrcres.LoadPanel (self, "P_EDIT")
	self.Fit()
	self.initcntls()
	self.initbehav()

	if self.entr: self.setdisp (self.entr)
	else: self.cleardisp()
	self.Show (True)

    def initcntls (self):
	self.loadchoice (GET(self, 'corp'), 'SRC')
	self.loadchoice (GET(self, 'stat'), 'STAT', 'descr')

    def initbehav (self):
	GET(self, "save").Bind(wx.EVT_BUTTON, self.save)
	self.Bind (wx.EVT_MENU, lambda x: chgfontsz (self, 2), 
		   self.MenuBar.FindItemById(wx.xrc.XRCID('fontszincr')))
	self.Bind (wx.EVT_MENU, lambda x: chgfontsz (self, -2),
		   self.MenuBar.FindItemById(wx.xrc.XRCID('fontszdecr')))


    def setdisp (self, entr):
	self.setchoice (GET(self, 'corp'), entr.src)
	self.setchoice (GET(self, 'stat'), entr.stat)
	GET(self, 'id').SetValue (str(entr.id or ''))
	GET(self, 'seq').SetValue (str(entr.seq or ''))
	GET(self, 'unap').SetValue (not entr.unap or False) # Caution: sense reversed from DB.
	GET(self, 'dfrm').SetValue (str(entr.dfrm or ''))
	GET(self, 'srcnote').SetValue (str(entr.srcnote or ''))
	GET(self, 'notes').SetValue (str(entr.notes or ''))
	GET(self, 'kanj').SetValue (fmtjel.kanjs (getattr(entr,'_kanj',[])))
	GET(self, 'rdng').SetValue (fmtjel.rdngs (getattr(entr,'_rdng',[]), entr._kanj))
	GET(self, 'sens').SetValue (fmtjel.senss (getattr(entr,'_sens',[]), entr._rdng, entr._kanj))
	hist = fmt.hist (getattr(entr,'_hist',[]))
	if hist: 
	    # Strip off useless (to us) header. 
	    if not hist.startswith ("\nHistory:\n"):
		raise RuntimeError ("Unexpected format in History text")
	    hist = hist[10:]
	GET(self, 'hist').SetValue (hist)

    def cleardisp (self):
	GET(self, 'corp').SetSelection (-1)
	GET(self, 'stat').SetSelection (-1)
	GET(self, 'id').SetValue ('')
	GET(self, 'seq').SetValue ('')
	GET(self, 'unap').SetValue (False)
	GET(self, 'dfrm').SetValue ('')
	GET(self, 'srcnote').SetValue ('')
	GET(self, 'notes').SetValue ('')
	GET(self, 'kanj').SetValue ('')
	GET(self, 'rdng').SetValue ('')
	GET(self, 'sens').SetValue ('')

    def save (self, evt, saved=[None]):
	if not self.entr: dfrm = None
	else: dfrm = self.entr.id
	userid = self.authed.id if self.authed else None 
	st, v = self.get_comment (saved[0])
	saved[0] = v
	if st == wx.ID_OK: user, email, comment, refs = v
	else: return 
	krstext = "%s\n%s\n%s" % (
	    GET(self, 'kanj').GetValue (),
	    GET(self, 'rdng').GetValue (),
	    GET(self, 'sens').GetValue ())
	try: 
	    newentr = self.model.build_entr ( dfrm, krstext,
		self.getselection (GET(self, 'corp')),
		self.getvalue (GET(self, 'seq'),int),
		self.getselection (GET(self, 'stat')),
		not self.getvalue (GET(self, 'unap'),bool),
		self.getvalue (GET(self, 'srcnote'),unicode),
		self.getvalue (GET(self, 'notes'),unicode))
	    self.model.add_entr ( newentr, userid, user, email, comment, refs)
	except (ParseError,AuthError), excep:
	    msg (self, str(excep), wx.OK|wx.ICON_ERROR)
	    return
	msgtxt = "Entry added to database, id=%s" % newentr.id
	msg (self, msgtxt, wx.OK|wx.ICON_INFORMATION)
	self.Close()

    def get_comment (self, prev=None):
	dlg = self.xrcres.LoadDialog (self, "D_COMMENT")
	cntls = [dlg.FindWindowByName(x) 
		 for x in ('username','email','hnotes','refs')]
	if prev:
	    for cntl,prevval in zip (cntls, prev): cntl.SetValue (prevval)
	dlg.FindWindowByName('ok').SetId (wx.ID_OK)
	dlg.FindWindowByName('cancel').SetId (wx.ID_CANCEL)

	if not cntls[0].GetValue() and self.authed:
	    cntls[0].SetValue(self.authed.name)
	if not cntls[1].GetValue() and self.authed:
	    cntls[1].SetValue(self.authed.email)

	if self.authed:
	    dlg.FindWindowByName('userid').SetValue (str(self.authed.id))
	    dlg.FindWindowByName('edname').SetValue (self.authed.name)
	    dlg.FindWindowByName('edemail').SetValue (self.authed.email)

	st = dlg.ShowModal()
	rv = [cntl.GetValue() for cntl in cntls]
        dlg.Destroy()
	return st, rv

    def loadchoice (self, cntl, table, col='kw'):
	for kwrec in self.model.choice_values (table, col, ord=col): 
	    cntl.Append (getattr (kwrec, col), kwrec.id)

    def setchoice (self, cntl, id):
	for n in range (cntl.GetCount()):
	    cid = cntl.GetClientData(n)
	    if cid == id: break
	if cid != id: raise KeyError ("Id %s not found in control %s" % (id, cntl.GetName()))
	cntl.SetSelection (n)

    def getvalue (self, cntl, typ):
	v = cntl.GetValue()
	if not v: v = None
	else: v = typ(v)
	return v

    def getselection (self, cntl):
	i = cntl.GetSelection()
	v = cntl.GetClientData (i)
	return v

def msg (frame, txt, flags=wx.OK|wx.ICON_ERROR, title=None):
	if title is None:
	    if   flags & wx.ICON_INFORMATION: title = 'Info'
	    elif flags & wx.ICON_QUESTION:    title = 'Question'
	    elif flags & wx.ICON_WARNING:     title = 'Warning'
	    elif flags & wx.ICON_ERROR:       title = 'Error'
	    else:                             title = 'Message'
        dlg = wx.MessageDialog (frame, txt, title, flags)
        v = dlg.ShowModal()
        dlg.Destroy()
	return v

class Model:
    def __init__(self, cursor):
	self.cursor = cursor
	self.lexer, tokens = jellex.create_lexer ()
        self.parser = jelparse.create_parser (tokens, debug=0)

    def find_entrs (self, critera=None, args= None):
	tmptbl = jdb.entrFind (self.cursor, critera, args)
	return tmptbl

    def get_entrs (self, criteria=None, args=None, ord=None):
	data, raw = jdb.entrList (self.cursor, criteria, args, ord, ret_tuple=True)
	jdb.augment_xrefs (self.cursor, raw['xref'])
	jdb.augment_xrefs (self.cursor, raw['xrer'], rev=1)
	#if topic: self.notify (topic, data)
	return data

    def build_entr (self, dfrm, krstext, corp, seq, stat,
		     unap, srcnote, notes):
        jellex.lexreset (self.lexer, krstext)
        e = self.parser.parse (krstext, lexer=self.lexer)
	(e.src, e.seq, e.stat, e.dfrm, e.unap, e.srcnote, e.notes) \
	  = corp, seq, stat, dfrm, unap, srcnote, notes
	return e

    def add_entr (self, e, userid, name, email, comment, refs):
	jdb.add_hist (self.cursor, e, userid, name, email, comment, refs)
	self.cursor.execute ('BEGIN')
	id,x = jdb.addentr (self.cursor, e)
	self.cursor.execute ('COMMIT')
	return e

    def choice_values (self, table, col='kw', ord='kw'):
	rs = KW.recs (table.upper())
	rs.sort (key=operator.attrgetter (ord))
	return rs

    def get_ed (self, userid):
	#FIXME: don't hardwire "jmsess".
	userdb = jdb.dbOpen ("jmsess")
	sql = "SELECT id,name,email,notes FROM users WHERE id=%s"
	rs = jdb.dbread (userdb, sql, (userid,), ('id','name','email','notes'))
	userdb.close()
	return rs[0] if rs else None

    def notify (self, topic, data=None):
	pubsub.Publisher().sendMessage (topic, data)

    def subscribe (self, listener, topics):
	  # 'listener' is a callable that should expect to be called with
	  # a single pubsub.Message instance which hasd two attributes: 
	  #   topic -- The full topic.
	  #   data -- Client data.
	pubsub.Publisher().subscribe (callable, topics)

# Remainder of code has no wx dependencies.

class SavedSrchs:
    def __init__ (self, fname=None):
	self.ss = ConfigParser.RawConfigParser()
	self.file = None
	try: 
	    if fname: self.read (fname)
	except IOError: pass
    def read (self, fname):
	if self.file:  self.file.close()
	self.file = open (fname)
	self.ss.read (self.file)
    def keys (self): 
	return self.ss.sections()
    def save (self, name, sql, help, ovrwt=False): 
	if has_section (name) and not ovrwt:
	    DuplicateSectionError (name)
	self.ss.set (name, 'sql', sql)
	self.ss.set (name, 'help', help)
    def get (self, name):
	return Obj (self.ss.items(name))
    def write (self):
	if self.file:  self.file.close()
	f = open ("w")
	self.ss.write (f)

def stat_abbr (entr):
	return KW.STAT[entr.stat].kw + ('*' if entr.unap else ' ') 



def gen_chkgrp_data (model):
	" Generate data for the checkbox combo dropdown lists."
	grpdata = dict()
        for grpname in 'src','stat','kinf','rinf','freq','fld','pos','misc','unap':
	    if grpname == 'unap':
		data = [('appr','appr -- approved'),('unappr','unappr -- unapproved')]
	    elif grpname == 'stat':
		data = [x.descr for x in model.choice_values (grpname)]
	    elif grpname == 'freq':
		tmp = model.choice_values (grpname)
		data = [('NOT','NOT'),('P','P -- Popular (eqv to ichi1,gai1,news1,spec1)')]
		for x in tmp:
		    if x.kw != 'nf' and x.kw != 'gA':
		        data.append (x.kw+"1")
		        data.append (x.kw+"2")
	    else:
		choices = model.choice_values (grpname)
		data = [('NOT','NOT')] if len(choices)>5 else []
		for x in choices:
		    if x.descr: s,d = ' -- ', x.descr
		    else: s,d = '', ''
	            data.append ((x.kw,x.kw + s + d))
	    grpdata[grpname] = data
	return grpdata


from optparse import OptionParser

def parse_cmdline ():
	u = \
"""\n\t%prog [options...]

  This is the search control center, the power nexus of the jmdictdb world.

Arguments:  none"""

	v = sys.argv[0][max (0,sys.argv[0].rfind('\\')+1):] \
	        + " Rev %s (%s)" % _VERSION_
	p = OptionParser (usage=u, version=v, add_help_option=False)
	p.add_option ("-a", "--authorized",
            type="int", dest="authorized", 
	    help="Act as authorized editor with the given id.")
	p.add_option ("--edit", metavar="INT",
            type="int", dest="edit", 
	    help="Open the edit window directly on entry with id INT.  ")
	p.add_option ("--search", metavar="URL",
            type="str", dest="srch",
	    help="Execute a search with the parameters given in URL and "
		"open the Results window directly.  ")
	p.add_option ("-d", "--database", metavar="DBNAME",
            type="str", dest="dbname", default="jmdict",
	    help="Name of the jmdict database.  ")
	p.add_option ("-s", "--server", metavar="SRVR",
            type="str", dest="host", 
	    help="Name or IP address of the server hosting the"
		" the Postgresql jmdict database.  No default," 
		" which will generally result in an attempt to"
		" connect to a database on the local machine. ")
	p.add_option ("--help",
            action="help", help="Print this help message.")
	opts, args = p.parse_args ()
	if len(args) != 0: p.error("Error, no arguments expected.  " 
				"Use --help for more info")
	return args, opts

if __name__ == '__main__':  main()
