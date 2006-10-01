# Enable to support locale aware default string encodings.
# This code copied from Python's site.py.

import locale
loc = locale.getdefaultlocale()
if loc[1]: encoding = loc[1]
print "syscustomize executed"