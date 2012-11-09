
import sys

Logfile = sys.stderr

def warn (msg, *args):
        m = msg % args
        print (m, file=Logfile)


