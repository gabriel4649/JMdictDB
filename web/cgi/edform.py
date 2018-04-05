#!/usr/bin/env python3
#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2008-2012 Stuart McGraw
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

# This page will present a form for entering new entries to
# and for modifying existing entries.  Multiple entries can
# be specified which will generate a page with multiple edit
# forms.  The form for an entry may be preinitialized with
# data.
#
# To edit an existing entry, provide either
#  * the 'e', 'q' url parameters (which will lookup the entry
#    in the database and initialize the form from the entry
#    (possibly more than one in the case of 'q') found.
#  * the 'entr' parameter where the supplied serialized Entr
#    object has a 'dfrm' attribute with the id number of the
#    entry being edited.  The form will be initialized with
#    data from the the serialized Entr object.
#
# To edit a new object, provide:
#  * No 'e', 'q', 'entr' or 'j' parameters.  A blank edit form
#    will be presented.
#  FIXME: should we have an explict parameter for a blank new
#   new entry form to allow a page with multiple new entry forms?
#  * An 'entr' parameter with a serialized Entr object with a
#    'dfrm' value of None.  The form will be initialized from the
#    Entr object.
#  * A 'j' parameter that will be parsed and used to initialize
#    the form.
#
# Multiple 'e', 'q', 'entr' and 'j' parameters may be given and will
# result in a page with multiple edit forms.  No attempt is made to
# "de-duplicate" entries... if the same entry is specified more than
# once, it will appear in multiple forms.  If any entries given by
# the 'e' or 'q' parameters are not found they will be ignored but
# any other errors in loading any of the entries will result in an
# error page and none of the entries will be available for edit.
#
# Url parameters:
#   e=<n> -- Id number of entry to edit.  May be given multiple times.
#   q=<n> -- Seq number of entry to edit.  May be given multiple times.
#       Each 'q' parameter may result in multiple edit forms if there
#       are multiple entries of that seq number.  Multiple entries
#       with the same seq number may occur in different corpora
#       (use the 'q.c' form or 'c' parameter to limit to one corpus)
#       or because there mutiple entries in different edit states
#       (use the 'a' parameter to limit to the single active or new
#       entry.)
#   q=<n.c> -- Seq number and corpus of entry to edit.  May be given
#       multiple times.
#   c=<c> -- Default corpus for new entries or when searching for
#       q entries that don't specify a corpus.  Value may be the
#       corpus id number, or corpus name.
#   f=1 -- Do not give non-editor users a choice of corpus for
#       new entries.  This parameter will be ignored if 'c' not
#       also given.  Existing entries are always treated as though
#       f=1 is in effect for non-editors.
#   a -- If given the value 1 or 2, will limit entries displayed
#       in the edit form as described below.  If 'a' not given
#       all entries that match the other criteria will be displayed
#       including possibly deleted, rejected, and unapproved entries.
#   a=1 -- Restrict entries to active/approved, or new entries.
#       If not given all entries with a matching seq number will
#       be displayed regardless of status or approval state.
#   a=2 -- Restrict all entries to one per each seq number that
#       occurs in the results.  that entry will be the most recently
#       edited (chronologically, based on history records) entry
#       if one exists, or the active/approved entry fr the seq
#       number.  Note that this option may result in user suprise
#       in that the latest entry may be on a different branch than
#       an earlier entry and will show no sign of the earlier entry.
#   j=<str> -- A string describing an entry in Edict2 format.
#       If this parameter is given, the "e", "q", and "a"
#       parameters are ignored.
#   entr=<...> -- A serialized Entr object that will be used to
#       initialize the form edit fields.  If it's 'id' attribute
#       is None, it will be treated as a new entry, otherwise as
#       as an edit of existing entry 'id'.  If it's 'stat'
#       attribute is 4 (D), the "delete" box will be checked.
#       If this parameter is given, the "e", "q", and "a"
#       parameters are ignored.
#
#   Standard parameters parsed by jmcgi.parseform():
#       svc -- Postgres service name that identifies database to use.
#       username -- Username to log in as.  Will do a login and page
#          redisplay.
#       password -- Password to use with above username.
#       logout -- If given, this parameter will force a logout and
#          page redisplay.
#       sid -- Session id number if already logged in.

import sys, cgi
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import logger; from logger import L; logger.enable()
import jdb, jmcgi, fmtjel, serialize, edparse

def main (args, opts):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        errs = []; entrs =[]
        try: form, svc, dbg, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])

        fv = form.getfirst; fl = form.getlist
        is_editor = jmcgi.is_editor (sess)
        dbg = fv ('dbg'); meth = fv ('meth')
        def_corp = fv ('c')             # Default corpus for new entries.
        defcorpid = None
        if def_corp:
            try: def_corp = int (def_corp)
            except ValueError: pass
            try: defcorpid = jdb.KW.SRC[def_corp].id
            except KeyError: errs.append ("Bad url parameter: c=%s" % def_corp)
        force_corp = fv ('f')   # Force default corpus for new entries.

        sentrs = fl ("entr")
        for sentr in sentrs:
            try: entrs = serialize.unserialize (sentr)
            except Exception as e:
                errs.append ("Bad 'entr' value, unable to unserialize: %s" % str(e))
            else:
                entrs.append (entr)

        jentrs = fl ('j')
        for jentr in jentrs:
            try: entr = edparse.entr (jentr)
            except Exception as e:
                errs.append ("Bad 'j' value, unable to parse: %s" % str(e))
            else:
                entr.src = None
                entrs.append (entr)

        elist, qlist, active = fl('e'), fl('q'), fv('a')
        if elist or qlist:
            entrs.extend (jmcgi.get_entrs (cur, elist or [], qlist or [], errs,
                                           active=active, corpus=def_corp) or [])
        cur.close()

        if (elist or qlist or jentrs or sentrs) and not entrs:
              # The caller explictly specified and entry to edit but we
              # didn't find it (or them).  Rather than treating this as
              # though no entries were given and displaying a blank edit
              # form, show an error message.
            errs.append ("No matching entries were found")
        if errs: jmcgi.err_page (errs)

        srcs = sorted (jdb.KW.recs('SRC'), key=lambda x: x.kw.lower())
        #srcs.insert (0, jdb.Obj (id=0, kw='', descr=''))
        if not entrs:
              # This is a blank new entry.
              # The following dummy entry will produce the default
              # text for new entries: no kanji, no reading, and sense
              # text "[1][n]".
            entr = jdb.Entr(_sens=[jdb.Sens(_pos=[jdb.Pos(kw=jdb.KW.POS['n'].id)])], src=None)
            entrs = [entr]
        for e in entrs:
            if not is_editor: remove_freqs (e)
            e.ISDELETE = (e.stat == jdb.KW.STAT['D'].id) or None
              # Provide a default corpus.
            if not e.src: e.src = defcorpid
            e.NOCORPOPT = force_corp

        if errs: jmcgi.err_page (errs)

        for e in entrs:
            e.ktxt = fmtjel.kanjs (e._kanj)
            e.rtxt = fmtjel.rdngs (e._rdng, e._kanj)
            e.stxt = fmtjel.senss (e._sens, e._kanj, e._rdng)

        if errs: jmcgi.err_page (errs)

        jmcgi.jinja_page ('edform.jinja', parms=parms, extra={},
                         entrs=entrs, srcs=srcs, is_editor=is_editor,
                         svc=svc, dbg=dbg, sid=sid, session=sess, cfg=cfg,
                         this_page='edform.py')

def remove_freqs (entr):
        for r in getattr (entr, '_rdng', []): r._freq = []
        for k in getattr (entr, '_kanj', []): k._freq = []

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
