#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2018 Stuart McGraw
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

import sys, cgi, re, datetime, copy
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import logger; from logger import L; logger.enable()
import jdb, jmcgi

def main (args, opts):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        errs = []; chklist = {}
        try: form, svc, dbg, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])
        fv = form.getfirst; fl = form.getlist

        if not sess or sess.priv != 'A': users = []
        else:
            sql = "SELECT * FROM users ORDER BY userid"
            sesscur = jdb.dbOpenSvc (cfg, svc, session=True, nokw=True)
            users = jdb.dbread (sesscur, sql)
            L('cgi.users').debug('read %d rows from table "user"' % (len(users),))
        jmcgi.jinja_page ("users.jinja", users=users, session=sess,
                          cfg=cfg, parms=parms, svc=svc, dbg=dbg,
                          sid=sid, this_page='user.py', result=fv('result'))

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
