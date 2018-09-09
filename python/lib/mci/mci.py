#==============================================================
#
#   MCI.py
#
#   Ctypes interface to Microsoft's MCI multimedia library.
#
#   Currently this is very incomplete, containing only those
#   interfaces I need for audio work.
#
#   $Id$
#==============================================================

from ctypes import *
try: from ctypes.wintypes import *
except ValueError: raise ImportError ('mci module not available')
import exceptions
from .constants import *

#-------------------------------------------------------------------------------
def Break (devid, flags=0, key=0, hwnd=0):
        if key != 0 and flags == 0: flags |= MCI_BREAK_KEY
        if flags == 0: flags |= MCI_BREAK_OFF
        if hwnd != 0: flags |= MCI_BREAK_HWND
        params = MCI_BREAK_PARMS (0, key, hwnd)
        SendCommand (devid, MCI_BREAK, flags, byref (params))

#-------------------------------------------------------------------------------
def Close (devid, flags=0):
        params = MCI_GENERIC_PARMS (0)
        SendCommand (devid, MCI_CLOSE, flags, byref (params))

#------------------------------------------------------------------------------
def GetDevCaps (devid, flags=0, item=0):
        params = MCI_GETDEVCAPS_PARAMS (0, 0, item)
        SendCommand (devid, MCI_GETDEVCAPS, flags, byref (params))
        return params.dwReturn

#------------------------------------------------------------------------------
def Info (devid, flags=0):
        p = c_char_p (' ' * 250)
        params = MCI_INFO_PARAMS (0, p, 250)
        SendCommand (devid, MCI_INFO, flags, byref (params))
        return p.value

#------------------------------------------------------------------------------
def Open (flags=0, devtype=None, elemname=None, alias=None):
        if devtype != None: flags |= MCI_OPEN_TYPE
        if elemname != None: flags |= MCI_OPEN_ELEMENT
        if alias != None: flags |= MCI_OPEN_ALIAS
        params = MCI_OPEN_PARAMS (0, 99, devtype, elemname, alias)
        SendCommand (0, MCI_OPEN, flags, byref(params))
        # SendCommand will raise an error if it fails, so
        # we can assume at this point that there is no problem.
        # SendCommand wrote the assigned device ID back into the
        # MCI_OPEN_PARAMS structure.
        return params.wDeviceID

#------------------------------------------------------------------------------
def Pause (devid, flags=0):
        params = MCI_GENERIC_PARMS (0)
        SendCommand (devid, MCI_PAUSE, flags, byref (params))

#------------------------------------------------------------------------------
def Play (devid, flags=0, start=0, end=0):
        if start != 0: flags |= MCI_FROM
        if end != 0: flags |= MCI_TO
        params = MCI_PLAY_PARAMS (0, start, end)
        SendCommand (devid, MCI_PLAY, flags, byref (params))

#------------------------------------------------------------------------------
def Record (devid, flags=0, start=0, end=0):
        if start != 0: flags |= MCI_FROM
        if end != 0: flags |= MCI_TO
        params = MCI_RECORD_PARAMS (0, start, end)
        SendCommand (devid, MCI_RECORD, flags, byref (params))

#------------------------------------------------------------------------------
def Set (devid, flags=0, timeFormat=0, audio=0):
        if timeFormat != 0: flags |= MCI_SET_TIME_FORMAT
        if audio != 0: flags |= MCI_SET_AUDIO
        params = MCI_SET_PARAMS (0, timeFormat, audio)
        SendCommand (devid, MCI_SET, flags, byref (params))

#------------------------------------------------------------------------------
def Status (devid, flags=0, item=0, track=0):
        params = MCI_STATUS_PARMS (0, 0, item, track)
        if item != 0: flags |= MCI_STATUS_ITEM
        if track != 0: flags |= MCI_TRACK
        SendCommand (devid, MCI_STATUS, flags, byref (params))
        return params.dwReturn

#------------------------------------------------------------------------------
def Stop (devid, flags=0):
        params = MCI_GENERIC_PARMS (0)
        SendCommand (devid, MCI_STOP, flags, byref (params))

#------------------------------------------------------------------------------
def Sysinfo (devid, flags=0, devNumber=0, devType=0):
        p = c_char_p (' ' * 250)
        params = MCI_SYSINFO_PARAMS (0, p, 250, devNumber, devType)
        SendCommand (devid, MCI_SYSINFO, flags, params)
        if (flags & MCI_SYSINFO_QUANTITY) == 0: return p
        else: return struct.unpack ("l", p)

#===============================================================================

def SendCommand (devid, msg, flags, params):
        global dllWinmm
        if not dllWinmm: dllWinmm = windll.winmm
        rc = dllWinmm.mciSendCommandA (devid, msg, flags, params)
        if rc != 0: raise mciError(rc, GetErrorString (rc))

def SendString (cmdstr):
        global  dllWinmm
        if not dllWinmm: dllWinmm = windll.winmm
        p = create_string_buffer(250)
        rc = dllWinmm.mciSendStringA (byref (cmdstr), p, 250, None)
        if rc != 0: raise mciError(rc, GetErrorString (rc))
        return p.value

def GetErrorString (errno):
        global dllWinmm
        if not dllWinmm: dllWinmm = windll.winmm
        p = create_string_buffer(250)
        rc = dllWinmm.mciGetErrorStringA (errno, p, 250)
        if rc == 0: raise mciError(0, "GetErrorString: unknown error code %s" % errno)
        return p.value

def GetDeviceID (devname):
        global dllWinmm
        if not dllWinmm: dllWinmm = windll.winmm
        devid = dllWinmm.mciGetDeviceIDA (byref (devname))
        if devid == 0: raise mciError(0, "GetDeviceID: unable to get device ID")
        return devid

#==============================================================================
def s2tmsf (secs, track=0):
        # Microsoft's tmsf format is 4 bytes packed
        # into an int:
        # +---------+---------+---------+---------+
        # | frame   | second  | minute  |  track  |
        # | (0-74)  | (0-59)  | (0-255) | (0-255) |
        # +---------+---------+---------+---------+
        #    MSB                            LSB
        #
        # For CD Audio, there are 75 frames per second,
        # or 13.33333... mS/frame.

        (s, fs) = divmod (secs, 1.0)
        s = int (s)
        m = s // 60
        s = s % 60
        f = int (fs * 75)
        return int ((f<<24) + (s<<16) + (m<<8) + track)

def unpack_tmsf (tmsf):
        t = int (tmsf & 0xFF)
        m = int ((tmsf>>8) & 0xFF)
        s = int ((tmsf>>16) & 0xFF)
        f = int ((tmsf>>24) & 0xFF)
        return (t, m, s, f)

def tmsf2s (tmsf):
        (t, m, s, f) = unpack_tmsf (tmsf)
        secs = m * 60 + s + f * (1.0 / 75.0)
        return (secs, t)

def unpack_msf (msf):
        m = int ((msf) & 0xFF)
        s = int ((msf>>8) & 0xFF)
        f = int ((msf>>16) & 0xFF)
        return (m, s, f)

def msf2s (msf):
        (m, s, f) = unpack_msf (msf)
        secs = m * 60 + s + f * (1.0 / 75.0)
        return secs

#==============================================================================

dllWinmm = None

DWORD_PTR = c_void_p
UINT = c_uint

class mciError (exceptions.Exception):
    def __init__ (self, errno, msg):
        self.args = (errno, msg)
        self.errno = errno
        self.msg = msg

class MCI_GENERIC_PARMS(Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR)]
class MCI_BREAK_PARMS(Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR),
            ("nVirtKey", c_int),
            ("hwndBreak", HWND)]
class MCI_GETDEVCAPS_PARMS(Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR),
            ("dwReturn", DWORD),
            ("dwItem", DWORD)]
class MCI_INFO_PARAMS(Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR),
            ("lpstrReturn", LPSTR),
            ("dwRetSize", DWORD)]
class MCI_OPEN_PARAMS(Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR),
            ("wDeviceID", DWORD),
            ("lpstrDeviceType", LPSTR),
            ("lpstrElementName", LPSTR),
            ("lpstrAlias", LPSTR)]
class MCI_PLAY_PARAMS(Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR),
            ("dwFrom", DWORD),
            ("dwTo", DWORD)]
class MCI_RECORD_PARAMS (Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR),
            ("dwFrom", DWORD),
            ("dwTo", DWORD)]
class MCI_SET_PARAMS (Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR),
            ("dwTimeFormat", DWORD),
            ("dwAudio", DWORD)]
class MCI_STATUS_PARMS (Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR),
            ("dwReturn", DWORD),
            ("dwItem", DWORD),
            ("dwTrack", DWORD)]

class MCI_SYSINFO_PARMS (Structure):
        _fields_ = [
            ("dwCallback", DWORD_PTR),
            ("lpstrReturn", LPSTR),
            ("dwRetSize", DWORD),
            ("dwNumber", DWORD),
            ("wDeviceType", c_uint)]


