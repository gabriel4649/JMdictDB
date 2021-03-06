#!/usr/bin/env python3
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
#  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
#######################################################################

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import logger; from logger import L; logger.enable()
import jdb, jmcgi

def main( args, opts ):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        errs = []
        try: form, svc, dbg, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str(e)])

        fv = form.getfirst; fl = form.getlist
        orderby = "k.id,s.kw,e.src"
        sql = "SELECT k.id, k.kw, k.descr, s.kw AS corpus, count(*) AS cnt " \
                "FROM kwgrp k " \
                "LEFT JOIN grp g ON g.kw=k.id " \
                "LEFT JOIN entr e ON e.id=g.entr " \
                "LEFT JOIN kwsrc s ON s.id=e.src " \
                "GROUP BY k.id, k.kw, k.descr, e.src, s.kw " \
                "ORDER BY %s" % orderby

        rs = jdb.dbread (cur, sql)
        jmcgi.jinja_page ("groups.jinja",
                         results=rs, parms=parms,
                         svc=svc, dbg=dbg, sid=sid, session=sess, cfg=cfg,
                         this_page='goups.py')

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
