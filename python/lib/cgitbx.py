# An alternative html traceback displayer.
#
# This is a replacement for Python's cgitb module which,
# in this developer's opinion, produces very ugly and overly
# complex output.  What I want is just a simple traceback,
# as one would see in a command line program, to appear in
# the browser when a cgi script fails.
# The code here is from cgitb.py with all the junk stripped
# out.
#
# Use this module in a cgi script as follows:
#   import cgitbx; cgitbx.enable()


import sys

def reset():
    """Return a string that resets the CGI and browser to a known state."""
    return '''Content-Type: text/html

<body bgcolor="#ffffff"><font color="#000000" size="-5"> -->
<body bgcolor="#ffffff"><font color="#000000" size="-5"> --> -->
</font> </font> </font> </script> </object> </blockquote> </pre>
</table> </table> </table> </table> </table> </font> </font> </font>'''

class Hook:
    """A hook to replace sys.excepthook that shows tracebacks in HTML."""

    def __init__(self, file=None):
        self.file = file or sys.stdout  # place to send the output

    def __call__(self, etype, evalue, etb):
        self.handle((etype, evalue, etb))

    def handle(self, info=None):
        info = info or sys.exc_info()
        self.file.write(reset())
        import traceback
        doc = ''.join(traceback.format_exception(*info))
        doc = doc.replace('&', '&amp;').replace('<', '&lt;')
        self.file.write("<br/>"
            "We're sorry, but an error occured while processing your request. "
            "It has resulted in an alarm condition in the EDRDG Worldwide "
            "Network Operations Center, and a large number of people are "
            "now scurrying around trying to fix the problem you caused. "
            "We hope you're happy. " +
            '<pre>' + doc + '</pre>\n')

handler = Hook().handle
def enable(): sys.excepthook = Hook()
