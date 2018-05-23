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

import sys, cgi, re, datetime, copy
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import logger; from logger import L; logger.enable()
import jdb, jmcgi, jelparse, jellex, serialize, fmt

def main (args, opts):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        errs = []; chklist = {}
        try: form, svc, dbg, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])

        fv = form.getfirst; fl = form.getlist
        KW = jdb.KW

          # 'eid' will be an integer if we are editing an existing
          # entry, or undefined if this is a new entry.
        pentr = None
        eid = url_int ('id', form, errs)
        if eid:
             # Get the parent entry of the edited entry.  This is what the
             # edited entry will be diff'd against for the history record. 
             # It is also the entry that will be pointed to by the edited
             # entry's 'dfrm' field.
            pentr = jdb.entrList (cur, None, [eid])
              #FIXME: Need a better message with more explanation.
            if not pentr: errs.append ("The entry you are editing has been deleted.")
            else: pentr = pentr[0]

          # Desired disposition: 'a':approve, 'r':reject, undef:submit.
        disp = url_str ('disp', form)
        if disp!='a' and disp!='r' and disp !='' and disp is not None:
            errs.append ("Invalid 'disp' parameter: '%s'" % disp)

          # New status is A for edit of existing or new entry, D for
          # deletion of existing entry.
        delete = fv ('delete');  makecopy = fv ('makecopy')
        if delete and makecopy: errs.append ("The 'delete' and 'treat as new'"
           " checkboxes are mutually exclusive; please select only one.")
        if makecopy: eid = None
          # FIXME: we need to disallow new entries with corp.seq
          # that matches an existing A, A*, R*, D*, D? entry.
          # Do same check in submit.py.

        seq = url_int ('seq', form, errs)
        src = url_int ('src', form, errs)
        notes = url_str ('notes', form)
        srcnote = url_str ('srcnote', form)

          # These are the JEL (JMdict Edit Language) texts which
          # we will concatenate into a string that is fed to the
          # JEL parser which will create an Entr object.
        kanj = (stripws (url_str ('kanj', form))).strip()
        rdng = (stripws (url_str ('rdng', form))).strip()
        sens = (url_str ('sens', form)).strip()
        intxt = "\f".join ((kanj, rdng, sens))
        grpstxt = url_str ('grp', form)

          # Get the meta-edit info which will go into the history
          # record for this change.
        comment = url_str ('comment', form)
        refs    = url_str ('reference', form)
        name    = url_str ('name', form)
        email   = url_str ('email', form)

        if errs: jmcgi.err_page (errs)

          # Parse the entry data.  Problems will be reported
          # by messages in 'perrs'.  We do the parse even if
          # the request is to delete the entry (is this right
          # thing to do???) since on the edconf page we want
          # to display what the entry was.  The edsubmit page
          # will do the actual deletion.

        entr, errs = parse (intxt)
          # 'errs' is a list which if not empty has a single item
          # which is a 2-seq of str's: (error-type, error-message).
        if errs or not entr:
            if not entr and not errs:
                errs = ([], "Unable to create an entry from your input.")
            jmcgi.err_page ([errs[0][1]], prolog=errs[0][0])

        entr.dfrm = eid;
        entr.unap = not disp

          # To display the xrefs and reverse xrefs in html, they
          # need to be augmented with additional info about their
          # targets.  collect_refs() simply returns a list Xref
          # objects that are on the entr argument's .xref list
          # (forward xrefs) if rev not true, or the Xref objects
          # on the entr argument's ._xrer list (reverse xrefs) if
          # rev is true).  This does not remove them from the entry
          # and is done simply for convenience so we can have 
          # augment_xrefs() process them all in one shot. 
          # augment_xrefs add an attribute, .TARG, to each Xref
          # object whose value is an Entr object for the entry the
          # xref points to if rev is not true, or the entry the xref
          # is from, if rev is true.  These Entr objects can be used
          # to display info about the xref target or source such as
          # seq#, reading or kanji.  See jdb.augment_xrefs() for details.
          # Note that <xrefs> and <xrers> below contain references 
          # to the xrefs on the entries; thus the augmentation done
          # by jdb.augment_xrefs() alters the xref objects on those 
          # entries. 
        if pentr:
            x = jdb.collect_xrefs ([pentr])
            if x: jdb.augment_xrefs (cur, x)
              # Although we don't allow editing of an entry's reverse
              # xref, we still augment them (on the parent entry)
              # because we will display them.
            x = jdb.collect_xrefs ([pentr], rev=True)
            if x: jdb.augment_xrefs (cur, x, rev=True)
        x = jdb.collect_xrefs ([entr])
        if x: jdb.augment_xrefs (cur, x)

        if delete:
              # Ignore any content changes made by the submitter by
              # restoring original values to the new entry.
            entr.seq = pentr.seq;  entr.src = pentr.src;
            entr.stat = KW.STAT['D'].id
            entr.notes = pentr.notes;  entr.srcnote = pentr.srcnote;
            entr._kanj = getattr (pentr, '_kanj', [])
            entr._rdng = getattr (pentr, '_rdng', [])
            entr._sens = getattr (pentr, '_sens', [])
            entr._snd  = getattr (pentr, '_snd',  [])
            entr._grp  = getattr (pentr, '_grp',  [])
            entr._cinf = getattr (pentr, '_cinf', [])

        else:
              # Migrate the entr details to the new entr object
              # which to this point has only the kanj/rdng/sens
              # info provided by jbparser.
            entr.seq = seq;   entr.src = src;
            entr.stat = KW.STAT['A'].id
            entr.notes = notes;  entr.srcnote = srcnote;
            entr._grp = jelparse.parse_grp (grpstxt)

              # This form and the JEL parser provide no way to change
              # some entry attributes such _cinf, _snd, reverse xrefs
              # and for non-editors, _freq.  We need to copy these items
              # from the original entry to the new, edited entry to avoid
              # loosing them.  The copy can be shallow since we won't be
              # changing the copied content.
            if pentr:
                if not jmcgi.is_editor (sess):
                    jdb.copy_freqs (pentr, entr)
                if hasattr (pentr, '_cinf'): entr._cinf = pentr._cinf
                copy_snd (pentr, entr)

                  # Copy the reverse xrefs that are on pentr to entr,
                  # removing any that are no longer valid because they
                  # refer to senses , readings or kanji no longer present
                  # on the edited entry.  Note that these have already
                  # been augmented above.
                nuked_xrers = realign_xrers (entr, pentr)
                if nuked_xrers:
                    chklist['xrers'] = format_for_warnings (nuked_xrers, pentr)

              # Add sound details so confirm page will look the same as the
              # original entry page.  Otherwise, the confirm page will display
              # only the sound clip id(s).
              #FIXME? Should the following snd augmentation stuff be outdented
              # one level so that it is done in both the delete and non-delete
              # paths?
            snds = []
            for s in getattr (entr, '_snd', []): snds.append (s)
            for r in getattr (entr, '_rdng', []):
                for s in getattr (r, '_snd', []): snds.append (s)
            if snds: jdb.augment_snds (cur, snds)

              # If any xrefs were given, resolve them to actual entries
              # here since that is the form used to store them in the
              # database.  If any are unresolvable, an approriate error
              # is saved and will reported later.

            rslv_errs = jelparse.resolv_xrefs (cur, entr)
            if rslv_errs: chklist['xrslv'] = rslv_errs

        if errs: jmcgi.err_page (errs)

          # Append a new hist record details this edit.
        if not hasattr (entr, '_hist'): entr._hist = []
        entr = jdb.add_hist (entr, pentr, sess.userid if sess else None,
                             name, email, comment, refs,
                             entr.stat==KW.STAT['D'].id)
        if not delete:
            check_for_errors (entr, errs)
            if errs: jmcgi.err_page (errs)
            pseq = pentr.seq if pentr else None
            check_for_warnings (cur, entr, pseq, chklist)

          # The following all expect a list of entries.
        jmcgi.add_filtered_xrefs ([entr], rem_unap=False)
        serialized = serialize.serialize ([entr])
        jmcgi.htmlprep ([entr])

        entrs = [[entr, None]]  # Package 'entr' as expected by entr.jinja.
        jmcgi.jinja_page ("edconf.jinja",
                        entries=entrs, serialized=serialized,
                        chklist=chklist, disp=disp, parms=parms,
                        svc=svc, dbg=dbg, sid=sid, session=sess, cfg=cfg,
                        this_page='edconf.py')

def realign_xrers (entr, pentr):
        # This function mutates 'entr' to remove invalid reverse
        # xrefs from entr's ._xrer list and fix those that point
        # to moved readings or kanji.
        # There may be other entries in the database that have xrefs
        # pointing to (senses of) the entry we are editing.  These
        # reverse xrefs also have rdng and kanj numbers that index
        # a specific reading and/or kanji our entry.  While the sense
        # rdng and kanj numbers were correct for our parent (pre-edit)
        # entry, the edits made may have changed, reordered or deleted
        # the senses, readings and kanji of our entry.  This function
        # tries to adjust the reverse xrefs so that any that refer to
        # a sense, reading or kanji that no longer exists is deleted,
        # and any that now point to the wrong reading or kanji because
        # they were reordered are corrected.  We fix them by getting
        # the rdng or kanj text from the parent entry, find the index
        # same text in the edited entry, and update the rev xref with
        # the new index.
        # Since senses have no real id (yet, see IS-197), we can't
        # really do much to correct them other than to delete any
        # that reference a sense beyond the end of the senses list.

        # First, copy rev xrefs from parent to new entry except
        # for those there is no sense for on new entry.
        nosens = []     # List for discarded for no sense xrers.
        for n, sp in enumerate (pentr._sens):
            if not sp._xrer: continue
            if n < len (entr._sens):
                entr._sens[n]._xrer = copy.copy (sp._xrer)
            else: nosens.extend (sp._xrer)

        # Now fix up missing and out of order readings and kanji.
        nordng = []  # Lists to accumulate xrefs that refer to
        nokanj = []  #  readings and kanji no longer in new entry.
          # Index the readings and kanji of our edited entry.
          # The resulting dicts are keyed by rdng/kanj text and values
          #  are the indices (0-based) in ._rdng/._kanj of those texts.
        ridx = dict (((r.txt,n) for n,r in enumerate (entr._rdng)))
        kidx = dict (((k.txt,n) for n,k in enumerate (entr._kanj)))
        for i, s in enumerate (entr._sens):
            new = []    # We will build a new _xrer list in here.
            if i >= len (pentr._sens): break
            for x in s._xrer:   # For each rev xref in edited entry sense...
                if x.rdng:
                      # Even though x is an xrer on the new entry, x.rdng is
                      # still the number of the reading on the parent so we
                      # can use it to get the rdng text from the parent.
                      # Note that x.rdng is 1-based.
                    rtxt = pentr._rdng[x.rdng - 1].txt
                      # Look up the text in the rdng index for the new entry
                      # which gives us the index number on the new entry.
                      # Set the new index into the xref.
                    try: x.rdng = ridx[rtxt] + 1
                    except KeyError:
                          # A KeyError means the reading on the parent
                          # is not on our new entry any more.  Add the
                          # rev xref to a list of same which we'll use
                          # to tell user about later.
                        nordng.append (x); continue
                if x.kanj:
                      # Follow the same process as above for kanji.
                    ktxt = pentr._kanj[x.kanj - 1].txt
                    try: x.kanj = kidx[ktxt] + 1
                    except KeyError:
                        nokanj.append (x); continue
                  # Add the updated rev xref to the 'new' list.
                new.append (x)
              # When all rev xrefs have been updated, replace the old
              # rev xref list with the new one.
            s._xrer = new
        return nosens + nordng + nokanj

def format_for_warnings (xrers, pentr):
        msgs = []
        for x in xrers:
            rtxt = pentr._rdng[x.rdng-1].txt if x.rdng else ''
            ktxt = pentr._kanj[x.kanj-1].txt if x.kanj else ''
            krtxt = kr (ktxt, rtxt)
            msgs.append ((x.entr, x.TARG.seq, x.sens, krtxt, x.xsens))
        msgs.sort (key=lambda x: (x[0],x[2],x[3],x[4]))
        return msgs

def kr (ktxt, rtxt):
        if ktxt and rtxt: txt = u'%s\u30FB%s' % (ktxt, rtxt)
        elif ktxt: txt = ktxt
        elif rtxt: txt = rtxt
        else: txt = ''
        return txt

def check_for_errors (e, errs):
        # Do some validation of the entry.  This is nowhere near complete
        # Yhe database integrity rules will in principle catch all serious
        # problems but catching db errors and back translating them to a
        # user-actionable message is difficult so we try to catch the obvious
        # stuff here.
        # Note that every check done here should also be done in edsubmit.py
        # because an entry can be submitted to edsubmit.py without using this
        # form.

        if not getattr (e,'src',None):
            errs.append ("No Corpus specified.  Please select the corpus "
                         "that this entry will be added to.")

        ## FIXME: IS-190.
        #if not getattr (entr, '_rdng', None) \
        #        and entr.src==jdb.KW.SRC['jmdict'].id:
        #    errs.append ("No readings were entered for this entry.  "\
        #                 "All JMdict entries require a reading.")

        if not getattr (e,'_rdng',None) and not getattr (e,'_kanj'):
            errs.append ("Both the Kanji and Reading boxes are empty.  "
                         "You must provide at least one of them.")
        if not getattr (e,'_sens',None):
            errs.append ("No senses given.  You must provide at least one sense.")
        for n, s in enumerate (e._sens):
            if not getattr (s, '_gloss'):
                errs.append ("Sense %d has no glosses.  Every sense must have at least "\
                             "one regular gloss, or a [lit=...] or [expl=...] tag." % (n+1))
            ## FIXME: Can't be sure that jmdict is "jmdict". IS-190 is the real fix.
            #if not getattr (s, '_pos') and e.src==jdb.KW.SRC['jmdict'].id:
            #   errs.append ("Sense %d has no PoS (part-of-speech) tag.  "\
            #                "Every sense must have at least one." % (n+1))

          # Check for duplicate reading, kanji or gloss text (IS-205).
        nodups, dups = jdb.rmdups (e._rdng, lambda x: x.txt)
        if dups: errs.append ("Duplicate readings were given."
                              "  Please remove the extra readings: %s"
                              % ", ".join (x.txt for x in dups))
        nodups, dups = jdb.rmdups (e._kanj, lambda x: x.txt)
        if dups: errs.append ("Duplicate kanji were given."
                              "  Please remove the extra kanji: %s"
                              % ", ".join (x.txt for x in dups))
        for n, s in enumerate (e._sens):
              # Note that duplicate glosses are per sense and per langauge;
              # duplicates with different languages are ok.
            nodups, dups = jdb.rmdups (s._gloss, lambda x: (x.lang,x.txt))
            if dups: errs.append ("Duplicate gloss were given in sense %d."
                              "  Please remove the extra gloss: %s"
                              % (n+1, ", ".join (x.txt for x in dups)))

def check_for_warnings (cur, entr, parent_seq, chklist):
          # Look for other entries that have the same kanji or reading.
          # These will be shown as cautions at the top of the confirmation
          # form in hopes of reducing submissions of words already in
          # the database.
          # 'parent_seq' is used by find_similar() to exclude other entries
          # with the same seq# from being flagged as having duplicate kanji
          # or readings.
        dups = find_similar (cur, getattr (entr,'_kanj',[]),
                                  getattr (entr,'_rdng',[]), entr.src, parent_seq)
        if dups: chklist['dups'] = dups

          # FIXME: IS-190.
        if not getattr (entr, '_rdng', None) \
                and entr.src==jdb.KW.SRC['jmdict'].id:
            chklist['norebs'] = True

          # FIXME: Should pass list of the kanj/rdng text rather than
          #   a pre-joined string so that page can present the list as
          #   it wishes.
        chklist['invkebs'] = ", ".join (k.txt for k in getattr (entr,'_kanj',[])
                                                if not jdb.jstr_keb (k.txt))
        chklist['invrebs'] = ", ".join (r.txt for r in getattr (entr,'_rdng',[])
                                                if not jdb.jstr_reb (r.txt))
          # FIXME: IS-190.
        if entr.src==jdb.KW.SRC['jmdict'].id:
            chklist['nopos']   = ", ".join (str(n+1) for n,x in enumerate (getattr (entr,'_sens',[]))
                                                       if not x._pos)
        chklist['jpgloss'] = ", ".join ("%d.%d: %s"%(n+1,m+1,'"'+'", "'.join(re.findall('[\uFF01-\uFF5D]', g.txt))+'"')
                                                for n,s in enumerate (getattr (entr,'_sens',[]))
                                                  for m,g in enumerate (getattr (s, '_gloss',[]))
                                                        # Change text in edconf.tal if charset changed.
                                                    if re.findall('[\uFF01-\uFF5D]', g.txt))

          # Remove any empty warnings so that if there are no warnings,
          # 'chklist' itself will be empty and no warning span element
          # will be produced by the template (which otherwise will
          # contain a <hr/> even if there are no other warnings.)
        for k in list(chklist.keys()):
            if not chklist[k]: del chklist[k]

def find_similar (dbh, kanj, rdng, src, excl_seq=None):
        # Find all entries that have a kanj in the list of text
        # strings, 'kanj', or a reading in the list of text strings,
        # 'rdng', and return a list of esum view records of such
        # entries.  Either 'kanj' or 'rdng', but not both, may empty.
        # If 'src' is given, search will be limited to entries with
        # that entr.src id number.  Entries with a seq number of
        # 'excl_seq' (which may be None) will be excluded.

        rwhr = " OR ".join (["txt=%s"] * len(rdng))
        kwhr = " OR ".join (["txt=%s"] * len(kanj))
        args = [src]
        if excl_seq is not None: args.append (excl_seq)
        args.extend ([x.txt for x in rdng+kanj])

        sql = "SELECT DISTINCT e.* " \
                + "FROM esum e " \
                + "WHERE e.src=%s AND e.stat<4 " \
                + ("" if excl_seq is None else "AND seq!=%s ") \
                + "AND e.id IN (" \
                + (("SELECT entr FROM rdng WHERE %s " % rwhr)    if rwhr          else "") \
                + ("UNION "                                      if rwhr and kwhr else "") \
                + (("SELECT entr FROM kanj WHERE %s " % kwhr)    if kwhr          else "") \
                + ")"
        rs = jdb.dbread (dbh, sql, args)
        return rs

def copy_snd (fromentr, toentr, replace=False):
        # Copy the snd items (both Entrsnd and Rdngsnd objects) from
        # 'fromentr' to 'toentr'.
        # If 'replace' is false, the copied freqs will be appended
        # to any freqs already on 'toentr'.  If true, all existing
        # freqs on 'toentr' will be deleted before copying the freqs.
        # CAUTION: The Entrsnd and Rdngsnd objects themselves are not
        #  duplicated, the same objects are referred to from both the
        #  'fromentr' and the 'toentr'.

        if replace:
            if hasattr (toentr, '_snd'): toentr._snd = []
            for r in getattr (toentr, '_rdng', []):
                if hasattr (r, '_snd'): r._snd = []
        if hasattr (fromentr, '_snd'): toentr._snd.extend (fromentr._snd)
          # FIXME: How to migrate if new readings are different
          # than old readings (in attr '.txt', in order, or in number)?
        if hasattr (fromentr, '_rdng') and hasattr (toentr, '_rdng'):
            for rto, rfrom in zip (getattr (toentr,'_rdng',[]),
                                   getattr (fromentr,'_rdng',[])):
                 if hasattr (rfrom, '_snd'): rto._snd.extend (rfrom._snd)

def parse (krstext):
        entr = None; errs = []
        lexer, tokens = jellex.create_lexer ()
        parser = jelparse.create_parser (lexer, tokens)
        jellex.lexreset (lexer, krstext)
        try:
            entr = parser.parse (krstext, lexer=lexer, tracking=True)
        except jelparse.ParseError as e:
            errs.append ((e.args[0], e.loc))
        return entr, errs

def url_int (name, form, errs):
        v = form.getfirst (name)
        if not v: return v
        try: n = int (v)
        except ValueError:
              # FIXME: escape v
            errs.append ("name=" + v)
        return n

def url_str (name, form):
        v = form.getfirst (name)
        if v: v = v.strip('\n\r \t\u3000')
        return v or ''

Transtbl = {ord(' '):None, ord('\t'):None, ord('\r'):None, ord('\n'):None, }
def stripws (s):
        if s is None: return ''
          # Make sure 's' is a uncode string; .translate() will
          # bomb if is is a str string.
        return (str(s)).translate (Transtbl)

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
