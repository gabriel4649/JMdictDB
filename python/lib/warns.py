
import sys

Logfile = sys.stderr
Encoding = sys.getdefaultencoding()

def warn (msg, *args):
        m = msg % args
        if Encoding: m = m.encode (Encoding, 'backslashreplace')
        print (m, file=Logfile)


