# Enable to support locale aware default string encodings.
# This code copied from Python's site.py.

print "executing syscustomize"
import sys,locale
loc = locale.getdefaultlocale()
if loc[1]: 
    encoding = loc[1]
    print "setting default encoding to",encoding
    sys.setdefaultencoding(encoding)
