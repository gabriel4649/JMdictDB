#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2013 Stuart McGraw
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

import sys, cgi, re
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import logger; from logger import L; logger.enable()
import jdb, jmcgi
import fmtxml, fmtjel, xslfmt

def main (args, opts):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        errs = []
        try: form, svc, dbg, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])

        entries = jmcgi.get_entrs (cur, form.getlist ('e'),
                                        form.getlist ('q'), errs)
        if not entries:
            jmcgi.err_page ("No entries found");  return

        ids = [e.id for e in entries]
        sql, args = "SELECT * FROM vinflxt WHERE id IN %s", (tuple(ids),)
        results = jdb.dbread (cur, sql, args)
        poses = set ([p.kw for e in entries for s in e._sens for p in s._pos])
        poskws = sorted ([jdb.KW.POS[p].kw for p in poses])
        if not results:
            if poskws: msg = "Unable to conjugate any of the following parts-of-speech: %s." % (', '.join(poskws))
            else: msg = "Word does not have a part-of-speech tag."
            jmcgi.err_page (msg)
            return

        sql, args = "SELECT DISTINCT id,txt FROM vconotes WHERE pos IN %s ORDER BY id", (tuple(poses),)
        notes = jdb.dbread (cur, sql, args)

        cur.close()
          # Make notes links, replace '\n's with <br/>s.
        htmlify_conjs (results)
          # Divide the conjugations table up into sections, one for each word (by id).
        sections = partition_conjs (results)
          # Make each note a link target.
        htmlify_notes (notes)

        if errs: jmcgi.err_page (errs)

        jmcgi.jinja_page ('conj.jinja',
                        sections=sections, notes=notes,
                        svc=svc, dbg=dbg, sid=sid, session=sess, cfg=cfg,
                        parms=parms, this_page='conj.py')

def htmlify_conjs (rows):
        for row in rows:
            for attr in 'w0','w1','w2','w3':
                t = getattr (row, attr, None)
                if t is None: continue
                t = t.replace ('\n', '<br/>')
                  #FIXME: following only ok if no ascii digits occur in t other
                  # than in footnote references.
                t = re.sub (r'(\d+)', r'<a href="#note\1">\1</a>', t)
                setattr (row, attr, t)
        return

def htmlify_notes (rows):
        for row in rows:
            row.id = '<a name="note%s">%s</a>' % (row.id, row.id)
        return

def partition_conjs (results):
        if not results: return []
        sections = []
        lastid = results[0].id;  start = 0
        for n, row in enumerate (results):
              # Separate 'results' into blocks of contiguous rows with same id.
            if row.id != lastid:
                sections.append (results[start:n])
                start = n;  lastid = row.id
        sections.append (results[start:n+1])
        for s in sections:
            lastkey = None
            for row in s:
                key = (row.knum, row.rnum, row.pos)
                if key != lastkey: row.sbreak = True
                else: row.sbreak = False
                lastkey = key
        return sections

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
