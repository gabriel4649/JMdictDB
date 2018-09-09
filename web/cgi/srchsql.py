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
        try: form, svc, dbg, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])

        adv_srch_allowed = jmcgi.adv_srch_allowed (cfg, sess)
        jmcgi.jinja_page ("srchsql.jinja",
                        svc=svc, dbg=dbg, sid=sid, session=sess, cfg=cfg,
                        adv_srch_allowed = adv_srch_allowed, parms=parms,
                        this_page='srchsql.py')

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
