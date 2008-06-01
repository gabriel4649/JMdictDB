#######################################################################
#  This file is part of JMdictDB. 
#  Copyright (c) 2006,2008 Stuart McGraw 
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
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
########################################################################

from __future__ import with_statement

__version__ = ('$Revision$'[11:-2],
	       '$Date$'[7:-11]);

from lrucache import LRUCache
# We import mciError to make it available from this module to
# users of Audio, CD since any of those can raise it.
import mci; from mci.constants import *; from mci import mciError 

class Cd:
    def __init__ (self, devid):
	self.devid = devid

    def getCdTrackLen (self, devid, track=0): 
	  # Return position of end of given track (or current
	  # track id not specified).  
	if track == 0: track = mci.Status (devid, item=MCI_STATUS_CURRENT_TRACK)
	  # Note: even though the device is using tmsf time format,
	  # the status value returned is in msf format (way to go, Microsoft!!!) 
	leng = mci.msf2s (mci.Status (devid, item=MCI_STATUS_LENGTH, track=track))
	return leng

    def getToc (self):
	toc = []
	ntrks = mci.Status (self.devid, item=MCI_STATUS_NUMBER_OF_TRACKS)
	for i in xrange (1, ntrks + 1):
	   toc.append (self.getCdTrackLen (self.devid, i))
	return toc

    def getCdIdStr (self):
	return mci.Info (self.devid, MCI_INFO_MEDIA_IDENTITY)

class Audio:
    def __init__ (self, cacheSize=200):
	self.devCache = LRUCache (size=cacheSize)
	self.cd = Cd (self.getCdDevId ())

    def playSnd (self, iscd, dir_or_cd, file_or_track, start=0, leng=0):
	if iscd: self.playcd (dir_or_cd, file_or_track, start/100., leng/100.)
	else: self.playfile (dir_or_cd, file_or_track, start/100., leng/100.)

    def playcd (self, cd, track, start=0, leng=0, wait=1):
	  # 'start' and 'leng' are in seconds (float ok)
	track = int (track)
	flags = wait * MCI_WAIT
	end = 0
	if leng != 0: end = mci.s2tmsf (start + leng, track) 
	mci.Play (self.cd.devid, flags, start=mci.s2tmsf (start, track), end=end)

    def playfile (self, dir, fname, start=0, leng=0, wait=1):
	  # 'start' and 'leng' are in seconds (float ok)
	devid = self.getFlDevId (dir, fname)
	flags = wait * MCI_WAIT
	end = 0
	if leng != 0: end = (start + leng) * 1000
	mci.Play (devid, flags, int(start * 1000), int(end))

    def getCdDevId (self):
	if ("cdaudio",) in self.devCache: devid = self.devCache[cd]
	else:
	    devid = mci.Open (MCI_OPEN_TYPE, "cdaudio")
	    mci.Set (devid, MCI_SET_TIME_FORMAT, MCI_FORMAT_TMSF)
	    self.devCache[("cdaudio",)] = devid
	return devid

    def getFlDevId (self, dir, file):
	if len(dir) > 0 and not dir.endswith ("\\"): dir += "\\"
	fname = dir + file
	if fname.lower().endswith(".mp3"): devtyp = "mpegvideo"
	elif fname.lower().endswith(".wav"): devtyp = "waveaudio"
	else: raise ValueError, "Invalid file type: %s" % fname
	if fname in self.devCache: devid = self.devCache[fname]
	else:
	    devid = mci.Open (MCI_OPEN_TYPE|MCI_OPEN_ELEMENT, devtyp, fname)
	    mci.Set (devid, MCI_SET_TIME_FORMAT, MCI_FORMAT_MILLISECONDS)
	    self.devCache[fname] = devid
	return devid

    def getCdIdStr (self):
	return self.cd.getCdIdStr ()

