#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2010 Stuart McGraw
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

# Display (using the standard entr.tal template) a page of
# entries that have a comment with a timestamp in the day
# given in the URL y (year), m (month), and d (day) parameters.

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11])

import sys, cgi, datetime
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import cgitbx; cgitbx.enable()
import jdb, jmcgi

def main (args, opts):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])
        fv = form.getfirst; fl = form.getlist

        t = datetime.date.today()  # Will supply default values of y, m, d.
        try:
            y = int (fv ('y') or t.year)
            m = int (fv ('m') or t.month)
            d = int (fv ('d') or t.day)
        except Exception as e: jmcgi.err_page ("Bad 'y', 'm' or 'd' url parameter.")
        day = datetime.date (y, m, d)

        sql = '''SELECT DISTINCT e.id
                 FROM entr e
                 JOIN hist h on h.entr=e.id
                 WHERE h.dt::DATE=%s'''

        entries = jdb.entrList (cur, sql, (day,), 'x.src,x.seq,x.id')

          # Prepare the entries for display... Augment the xrefs (so that
          # the xref seq# and kanji/reading texts can be shown rather than
          # just an entry id number.  Do same for sounds.
        for e in entries:
            for s in e._sens:
                if hasattr (s, '_xref'): jdb.augment_xrefs (cur, s._xref)
                if hasattr (s, '_xrer'): jdb.augment_xrefs (cur, s._xrer, 1)
            if hasattr (e, '_snd'): jdb.augment_snds (cur, e._snd)
        cur.close()
        jmcgi.htmlprep (entries)
        jmcgi.add_filtered_xrefs (entries, rem_unap=True)

        jmcgi.gen_page ('tmpl/entr.tal', macros='tmpl/macros.tal',
                        entries=zip(entries, [None]*len(entries)), disp=None,
                        svc=svc, host=host, sid=sid, session=sess, cfg=cfg,
                        parms=parms, output=sys.stdout, this_page='entr.py')

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
