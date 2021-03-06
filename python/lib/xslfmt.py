#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2009 Stuart McGraw
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
#######################################################################

"""
Apply an xslt transform to an entry formatted as xml.  Typically
this is used with the "to_edit2.xsl" stylesheet to get a Edict2
formmated version of an entry.

"""
import sys, re, lxml
from io import StringIO
from lxml import etree
import jdb, fmtxml

def entr (entr, xslfile=None, xslt=[], want_utf8=False):
        # A slow but simple way to get an Edict2 formatted text for an entry.
        # entr -- A jmdictdb Entr object, or a string containing the xml
        #   of an Entr object, or None.
        # xslfile -- Name of an xslt file.  If the name contains any path
        #   separator characters, it will be used as is.  Otherwise is it
        #   will be taken as a plain filename and searched for on the Python
        #   search path (sys.path).  Either way, the resulting file is
        #   will be converted to a lxml .etree.XSLT transform object and
        #   applied the the xml from 'entr' (if 'entr' was not None.)
        # xslt -- May be None, an empty list, or a list of one item which
        #   is a lxml.etree.XSLT transform object that will be applied to
        #   in 'entr' xml.  If an empty list, the xslt file given 'xslfile'
        #   will be converted to a transform and saved in it (for use in
        #   subsequent calls).  If None, 'xslfile' will be converted to a
        #   transform and not saved.
        # want_utf8 -- If false, a unicode text string is returned.  If
        #   true, a utf-8 encoded text string is returned.

        if not xslt:
            if not xslfile: xslfile = 'edict2.xsl'
              # Read the xsl file.
            if '/' not in xslfile and '\\' not in xslfile:
                dir = jdb.find_in_syspath (xslfile)
                xslfile = dir + '/' + xslfile
            xsldoc = lxml.etree.parse (xslfile)
              # Generate a transform, and use the default value
              # of the 'xslt' parameter to cache it.
            xslt[:] = [lxml.etree.XSLT (xsldoc)]
        edicttxt = None
        if entr:
            if not isinstance (entr, str):
                xml = fmtxml.entr (entr, compat='jmdict')
            else: xml = entr
              # Replace entities.
            xml = re.sub (r'&([a-zA-Z0-9-]+);', r'\1', xml)
            xml = "<JMdict>%s</JMdict>" % xml
              # Apply the xsl to the xml, result is utf-8 encoded.
            edicttxt = str (xslt[0](etree.parse (StringIO (xml)))).rstrip('\n\r')
            if want_utf8:  # Convert to utf-8 to unicode.
                edicttxt = edicttxt.encode('utf-8')
        return edicttxt
