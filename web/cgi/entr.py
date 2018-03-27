#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2006-2012,2018 Stuart McGraw
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

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11])

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi
import fmtxml, fmtjel, xslfmt

def main (args, opts):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        #print "Content-type: text/html\n"
        errs = []
        try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])

        entries = jmcgi.get_entrs (cur, form.getlist ('e'),
                                        form.getlist ('q'), errs)
        if errs: jmcgi.err_page (errs)

        entries.sort (key=lex_sort)
        for e in entries:
            for s in e._sens:
                if hasattr (s, '_xref'): jdb.augment_xrefs (cur, s._xref)
                if hasattr (s, '_xrer'): jdb.augment_xrefs (cur, s._xrer, 1)
            if hasattr (e, '_snd'): jdb.augment_snds (cur, e._snd)
        cur.close()
        disp = form.getfirst ('disp')
        if disp == 'xml':
            etxts = [fmtxml.entr (e) for e in entries]
        elif disp == 'jm':
            etxts = [fmtxml.entr (e, compat='jmdict') for e in entries]
        elif disp == 'jmne':
            etxts = [fmtxml.entr (e, compat='jmnedict') for e in entries]
        elif disp == 'jel':
            etxts = [fmtjel.entr (e) for e in entries]
        elif disp == 'ed':
            etxts = [xslfmt.entr (e) for e in entries]
        else:
            etxts = ['' for e in entries]
        jmcgi.htmlprep (entries)
        jmcgi.add_encodings (entries)    # For kanjidic entries.
        if disp == 'ed': etxts = [jmcgi.txt2html (x) for x in etxts]
        jmcgi.add_filtered_xrefs (entries, rem_unap=True)

        if errs: jmcgi.err_page (errs)

        jmcgi.jinja_page ('entr.jinja', macros='tmpl/macros.tal',
                        entries=list(zip(entries, etxts)), disp=disp,
                        svc=svc, host=host, sid=sid, session=sess, cfg=cfg,
                        parms=parms, output=sys.stdout, this_page='entr.py')

def lex_sort (e):
        # Sort key function for ordering lists of entries lexically,
        # by its first kanji, then first reading, then seq number,
        # then id number.  This is the same as the sort used in
        # the search results page.  We won't include gloss because
        # there are only a couple entries in JMdict where that might
        # make a difference.
        #
        # FIXME: The Sort in srchres.py is done in database using the
        #  database locale (typically ja_JP.utf8 if JMdictDB installed
        #  according to instructins).  I do not know if Python string
        #  sorts are locale-aware or not.

        return (e._kanj[0].txt if e._kanj else ''), \
               (e._rdng[0].txt if e._rdng else ''), \
               e.seq, e.id

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
