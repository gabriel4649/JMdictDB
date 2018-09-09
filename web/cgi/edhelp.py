#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2008-2010 Stuart McGraw
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

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import logger; from logger import L; logger.enable()
import jdb, jmcgi

def main (args, opts):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        try: form, svc, dbg, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])
        kwhash = {}
        for t in 'RINF KINF FREQ MISC POS FLD DIAL GINF SRC STAT XREF'.split():
            kw = jdb.KW.recs (t)
            kwset = [t.capitalize(), sorted (kw, key=lambda x:x.kw.lower())]
            kwhash[t] = kwset[1]
        kwhash['LANG'] = get_langs (cur)
        jmcgi.jinja_page ("edhelp.jinja", svc=svc, dbg=dbg, cfg=cfg, 
                          kwhash=kwhash)

def get_langs (cur):
        """Get set of kwlang rows for languages currently used in the
        the database (for gloss and lsrc.)"""

        sql = \
          "SELECT k.id,k.kw,k.descr FROM "\
              "(SELECT lang FROM gloss "\
              "UNION DISTINCT "\
              "SELECT lang FROM lsrc) AS l "\
          "JOIN kwlang k ON k.id=l.lang "\
          "ORDER BY k.kw!='eng', k.kw "
          # The first "order by" term will sort english to the top
          # of the list.
        rows = jdb.dbread (cur, sql)
        return rows

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
