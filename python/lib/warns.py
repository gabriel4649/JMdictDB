from __future__ import print_function, absolute_import, division
from future_builtins import ascii, filter, hex, map, oct, zip 
import sys

Logfile = sys.stderr
Encoding = sys.getdefaultencoding()

def warn (msg, *args):
	m = msg % args
	if Encoding: m = m.encode (Encoding, 'backslashreplace')
	print (m, file=Logfile)


