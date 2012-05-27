#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2008 Stuart McGraw 
# 
#  JMdictDB is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published 
#  by the Free Software Foundation; either version 2 of the License, 
#  or (at your option) any later version.
# 
#  JMdictDB is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with JMdictDB; if not, write to the Free Software Foundation,
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#######################################################################
from __future__ import print_function

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

import wx, wx.combo, string

# Adapted from the CheckListBoxComboPopup class in XRCed-2.8.7.1 (see params.py)
# and the wxPython ComboCtrl demo in the "More Windows/Controls section of the
# wxPython demo's.  We use a CheckedListCtrl for the popup rather than a ListCtrl
# as the demo does.

class CheckListBoxCombo (wx.combo.ComboCtrl):

    def __init__ (self, parent=None, id=-1, values=[], style=0, size=(120,-1)):
	wx.combo.ComboCtrl.__init__ (self, parent, id, style=style, size=size)
	self.values = [];  displays = []
	for x in values:
	    if isinstance (x, (str, unicode)): v = d = x
	    else: v, d = x
	    self.values.append (v)
	    displays.append (d)
        self.popup = CheckListBoxComboPopup (self.values, displays)
	self.SetPopupControl (self.popup)

    def GetSelectedIndexes (self):
	values = map(string.strip, self.GetValue().split(','))
	if values == ['']: values = []
	parsed = []; self.ignored = []
	for i in values:
	    try: 
		parsed.append (self.values.index(i))
	    except ValueError:
		print ('unknown flag: %s: ignored.' % i)
		self.ignored.append(i)
	return parsed

    def GetSelectedStrings (self):
	indexes = self.GetSelectedIndexes()
	return [self.values[x] for x in indexes]

class CheckListBoxComboPopup(wx.CheckListBox, wx.combo.ComboPopup):
        
    def __init__(self, values, displays):
	self.ignored = []
	self.values = values
	self.displays = displays
	self.PostCreate(wx.PreCheckListBox())
	wx.combo.ComboPopup.__init__(self)
	    
    def Create(self, parent):
	wx.CheckListBox.Create(self, parent)
	self.InsertItems (self.displays, 0)
	return True

    def OnPopup(self):
	combo = self.GetCombo()
	parsed = combo.GetSelectedIndexes()
	for i in parsed: self.Check(i)
	wx.combo.ComboPopup.OnPopup(self)

    def OnDismiss(self):
	combo = self.GetCombo()
	values = []
	for i in range(self.GetCount()):
	    if self.IsChecked(i):
		values.append(self.values[i])
	  # Add ignored flags
	  # values.extend(self.ignored)
	strValue = ', '.join(values)
	if combo.GetValue() != strValue:
	    combo.SetValue(strValue)
	    #Presenter.setApplied(False)
	wx.combo.ComboPopup.OnDismiss(self)

    def GetControl(self): return self

    def GetAdjustedSize (self, minwidth, prefheight, maxheight):
	#print "minwidth=%s, prefheight=%s, maxheight=%s" \
	#      % (str(minwidth), str(prefheight), str(maxheight))
	sz = minwidth, self.GetBestSize().y - 15
	#print "returning %s, %s" % sz
	return sz

def clipsize (targsz, maxsz=(None,None), minsz=(None,None)):
        x = targ[0], y = targ[1] 
        if maxsz[0] is not None and targ[0] > maxsz[0]: x = maxsz[0]
        if maxsz[1] is not None and targ[1] > maxsz[1]: y = maxsz[1]
        if minsz[0] is not None and targ[0] < minsz[0]: x = minsz[0]
        if minsz[1] is not None and targ[1] < minsz[1]: y = minsz[1]
	return x,y

if __name__ == '__main__':
	gui = wx.App (redirect=0)
	frame = wx.Frame (None, -1, size=(250,150))
	panel = wx.Panel (frame, -1)
	CheckListBoxCombo (panel, values=['aaa','bbb','cc','dddd','ee'])
	frame.Show()
	gui.SetTopWindow (frame)
	gui.MainLoop ()


