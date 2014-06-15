#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2008-2014 Stuart McGraw
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

__version__ = ('$Revision: $'[11:-2],
               '$Date: $'[7:-11]);

import sys, re, cgi, urllib.request, urllib.parse, urllib.error, os, os.path, random, time, http.cookies, datetime, time
import jdb, tal, fmt

def parseform (readonly=False):
        """\
    Do some routine tasksthat are needed for (most) every page, specifically:
    * Call cgi.FieldStorage to parse parameters.
    * Extract the svc parameter, validate it, and open the requested database.
    * Get session id and handle log or logout requests.
    Return an 8-tuple of:
        form (cgi.FieldStorage obj)
        svc (string) -- Checked svc value.
        host (string) -- Name of host where database server is running.
        cur (dbapi cursor) -- Open cursor for database defined by 'svc'.
        sid (string) -- session.id in hexidecimal form or "".
        sess (Session inst.) -- Session for sid or None.
        params (dict) -- Received and decoded form parameters.
        cfg (Config inst.) -- Config object from reading config.ini.
        """

        #logw ("parseform called in %s" % sys.modules['__main__'].__file__)
        errs=[]; sess=None; sid=''; cur=None; svc=None
        cfg = jdb.cfgOpen ('config.ini')
        def_svc = cfg['web'].get ('DEFAULT_SVC', 'jmdict')
        if def_svc.startswith ('db_'): def_svc = def_svc[3:]

        form = cgi.FieldStorage()
        svc = form.getfirst ('svc') or def_svc
        usid = form.getfirst ('sid') or ''    # No SID is "", not None.
        try: svc = safe (svc)
        except ValueError: errs.append ('svc=' + svc)
        if not errs: cur = jdb.dbOpenSvc (cfg, svc)
        if errs: raise ValueError (';'.join (errs))
        host = jdb._extract_hostname (cur.connection)

          # Login, logout, and session identification...
        scur = jdb.dbOpenSvc (cfg, svc, session=True, nokw=True)
        action = form.getfirst ('loginout') # Will be None, "login" or "logout"
        sid = get_sid_from_cookie() or ''
        sid_from_cookie = False
        if sid: sid_from_cookie = True
        if usid: sid = usid     # Use sid from url if available.
        #logw ("parseform(): sid=%s, from_cookie=%s, action=%s" % (sid, sid_from_cookie, action))
        uname = form.getfirst('username') or ''
        pw = form.getfirst('password') or ''
        sid, sess = get_session (scur, action, sid, uname, pw)
        #logw ("parseform(): %s session, sid=%s" % ("got" if sess else "no", sid))
        if sid: set_sid_cookie (sid, delete=(action=="logout"))
        if sid_from_cookie: sid=''
        scur.connection.close()

          # Collect the form parameters.  Caller is expected to pass
          # them to the page template which will use them in the login
          # section as hidden parms so the page can be recreated after
          # a login.
        parms = [(k,v)
                 for k in list(form.keys())
                 if k not in ('loginout','username','password')
                     for v in form.getlist(k) ]

        return form, svc, host, cur, sid, sess, parms, cfg

COOKIE_NAME = 'jmdictdb_sid'
SESSION_TIMEOUT = '2 hour'

def get_session (cur, action=None, sid=None, uname=None, pw=None):
        # Do the authentication action specified by 'action':
        #  None -- Lookup 'sid' and return a session if there is one.
        #  "login" -- Create a new session authenicating with 'uname'
        #       and 'pw'.  Return the session and its sid.
        #  "logout" -- Lookup session 'sid' and delete it.
        #
        # cur (dbapi cursor object) -- Cursor to open jmsess database.
        # action (string) -- None, "login", or "logout".
        # sid (string) -- Session identifier if logged in or None is not.
        # uname (string)-- Username (only required if action is "login".)
        # pw (string)-- Password (only required if action is "login".)
        #
        # Returns: sid, sess

        sess = None
        if not action and not sid: # Not logged in
            return '', None
        if not action:             # Use sid to retrieve session.
            sess = dbsession (cur, sid)
        elif action == 'logout':
            if sid: dblogout (cur, sid)
              # Don't clear 'sid' because its value will be needed
              # by caller to delete cookie.
        elif action == 'login':
            if not re.match (r'^[a-zA-Z0-9_]+$', uname): return '', None
            if not re.match (r'^[a-zA-Z0-9_]+$', pw): return '', None
            sid, sess = dblogin (cur, uname, pw)
        else: pass    # Ignore invalid 'action' parameter.
        return sid, sess

def dbsession (cur, sid):
        # Return the session identified by 'sid' or None.
        # As a side effect, if we have a sucessful login we
        # delete all expired session records in the session
        # table.  This will hopefully avoid the need for a
        # cron job to prune expired entries.

        sid = str (sid)
          # FIXME: we should log non-digit strings so we find
          #  out where they come from and fix at the source.
        if not sid.isdigit(): return ''
        sess = db_validate_sid (cur, sid)
        if not sess: return None
        db_del_old_sessions (cur)
        db_update_sid_ts (cur, sid)
        return sess

def dblogin (cur, userid, password):
        # Login by authenticating the userid/password pair.
        # and getting a session record which is returned with
        # the session id.  If 'userid' has an active session
        # already, it (the most recent one if more than one)
        # is returned.  If not, a new session is created.
        # Reusing existing sessions help prevent the proliferation
        # of sessions that was occuring previously.

          # Check userid, password validity.
        sql = "SELECT userid FROM users WHERE userid=%s AND pw=%s "\
                "AND pw IS NOT NULL AND NOT disabled "
        rs = jdb.dbread (cur, sql, (userid, password))
        if not rs:
            time.sleep (1);  return '', None

          # Look for an existing session (the most recent if more than one).
        sql = "SELECT s.id,s.userid,s.ts,u.fullname,u.email" \
              " FROM sessions s JOIN users u ON u.userid=s.userid" \
              " WHERE u.userid=%%s AND (NOW()-ts)<'%s'::INTERVAL" \
              " ORDER BY ts DESC LIMIT 1" % SESSION_TIMEOUT
        rs = jdb.dbread (cur, sql, (userid,))
        if len (rs) == 1:
            sid = rs[0][0]
              # Update the session timestamp to 'now'.
            db_update_sid_ts (cur, sid)
            return sid, rs[0]

          # No existing session found, create a new session.
        sid = random.randint (0, 2**63-1)
        sql = "INSERT INTO sessions(id,userid,ts) VALUES(%s,%s,DEFAULT)"
        cur.execute (sql, (sid, userid))
        cur.connection.commit()
        sess = db_validate_sid (cur, sid)
        return sid, sess

def dblogout (cur, sid):
        if not sid: return
          # Make logout delete all users sessions so that
          #  a logout will remedy a disclosed sid.  Of course
          #  this means a logout in one winow of one machine
          #  will affect every other login session.
        sql = "DELETE FROM sessions WHERE id IN"\
              "(SELECT s2.id FROM sessions s1"\
              " JOIN sessions s2 ON s1.userid=s2.userid"\
              " WHERE s1.id=%s)"
        cur.execute (sql, (sid,))
        cur.connection.commit()

def db_validate_sid (cur, sid):
        # Check that 'sid' is an existing session and if so
        # return a session record.  Otherwise return None.
        sql = "SELECT s.id,s.userid,s.ts,u.fullname,u.email" \
              " FROM sessions s JOIN users u ON u.userid=s.userid" \
              " WHERE id=%%s AND (NOW()-ts)<'%s'::INTERVAL" \
               % SESSION_TIMEOUT
        rs = jdb.dbread (cur, sql, (sid,))
        if len (rs) == 0: return None
        return rs[0]

def db_update_sid_ts (cur, sid):
        # Update the last-used timestamp for 'sid'.
        sql = "UPDATE sessions SET ts=DEFAULT WHERE id=%s"
        cur.execute (sql, (sid,))
        cur.connection.commit()

def db_del_old_sessions (cur):
        # Delete all sessions that are expired, for all users.
        sql = "DELETE FROM sessions WHERE (NOW()-ts)>'%s'::INTERVAL" \
               % SESSION_TIMEOUT
        cur.execute (sql)

def get_sid_from_cookie ():
        sid = ''
        if 'HTTP_COOKIE' in os.environ:
            c = http.cookies.SimpleCookie()
            c.load (os.environ['HTTP_COOKIE'])
            try: sid = c[COOKIE_NAME].value
            except KeyError: pass
        return sid

def set_sid_cookie (sid, delete=False):
        # Set a cookie on the client machine by writing an http
        # Set-Cookie line to stdout.  Caller is responsible for
        # calling this while http headers are being output.

        c = http.cookies.SimpleCookie()
        c[COOKIE_NAME] = sid
        c[COOKIE_NAME]['max-age'] = 0 if delete else 1*60*60
        print (c.output())

def is_editor (sess):
        """Return a true value if the 'sess' object (which may be None)
        is for a logged-in editor.  Note that currently, any non-None
        session is treated as a logged-in editor."""

        if sess: return getattr (sess, 'userid', None)
        return None

def adv_srch_allowed (cfg, sess):
        try: v = (cfg['search']['ENABLE_SQL_SEARCH']).lower()
        except (TypeError, ValueError, KeyError): return False
        if v == 'all': return True
        if v == 'editors' and is_editor (sess): return True
        return False

def form2qs (form):
        """
    Convert a cgi.FieldStorage object back into a query string.
        """
        d = []
        for k in list(form.keys()):
            for v in form.getlist (k):
                d.append ((k, v))
        qs = urllib.parse.urlencode (d)
        return qs

def args():
        """
    Command-line argument processing for cgi scripts.

    Python's cgi module will process a commandline argument as though
    it had been received through the environment as it is when a script
    is run by a web server, which is very useful for debugging.
    However, it expects only the url parameters (the part of the url
    that follows the "?", not the full url (starting with "http://...").
    Accepting the full url is convenient since it allows one to copy/-
    paste urls from a browser to a commendline invocation for debugging.
    This function will remove anything preceeding the url parameters so
    that the cgi module will be happy.
        """
        args = [];  opts = object()
        if len(sys.argv) > 1:
            #args, opts = parse_cmdline()
            args = sys.argv[1:]

            if args:
                a1, x, a2 = args[0].partition ('?')
                if a2: sys.argv[1] = a2
        return args, opts

def clean (s):
        if not s: return ''
        if not re.search ('^[0-9A-Za-z_]+$', s):
            raise ValueError ("clean(): Bad string received")
        return s

def esc(s): #FIXME
        if not s: return ""
        else: return str(s)

def str2seq (q):
        # Convert 'q', a string of the form of either 'seq" or
        # "seq.corp", where "seq" is a string of digits representing
        # a seq number, and "corp" is either a string of digits
        # representing a corpus id number or the name of a corpus.
        # The existence of the  corpus, if given, is validated in
        # the KW.SRC dict.  The seq number is only validated as
        # being greater than 0.
        # If sucessful, a 2-tuple of (seq-number, corpus-id) is
        # retuened, where 'corpus-id will be None if the first
        # input string format was given.  Otherwise a ValueError
        # exception is raised.

        KW = jdb.KW
        seq_part, x, corp_part = q.partition ('.')
        try: seq = int (seq_part)
        except (ValueError, TypeError):
            raise ValueError("Invalid seq number '%s'." % (q,))
        if seq <= 0: raise ValueError("Invalid seq number '%s'." % (q,))
        corp = None
        if corp_part:
            corp = corp2id (corp_part)
            if not corp: raise ValueError("Invalid corpus in '%s'." % (q,))
        return seq, corp

def corp2id (c):
        # Convert 'c' which identifies a corpus and is either
        # the corpus id number in integer or string form or
        # the name of a corpus, to the id number of the corpus.
        # The existence id th corpus is validadedin the KW.SRC
        # dict.

        try: c = int (c)
        except (ValueError, TypeError): pass
        try: corpid = jdb.KW.SRC[c].id
        except KeyError: return None
        return corpid

def str2eid (e):
        n = int (e)
        if n <= 0: raise ValueError()
        return n

def safe (s):
        if not s: return ''
        if re.search (r'^[a-zA-Z_][a-zA-Z_0-9]*$', s): return s
        raise ValueError ()

def txt2html (s, ):
        s = cgi.escape (s)
        s = s.replace ('\n', '<br/>\n')
        return s

def get_entrs (dbh, elist, qlist, errs, active=None, corpus=None):
        # Retrieve a set of Entr objects from the database, specified
        # by their entry id and/or seq numbers.
        #
        # dbh -- Open dbapi cursor to the current database.
        # elist -- List of id numbers of entries to get.  Each number
        #       may by either a integer or a string.
        # qlist -- List of seq numbers of entries to get.  Each seq
        #       number may be an integer or a string.  If the latter
        #       it may be followed by a period, and a corpus identifier
        #       which is either the corpus id number or the corpus name.
        # errs -- Must be a list (or other append()able object) to
        #       which any error messages will be appended.
        # active -- If 1, only active/approved or new/(unapproved)
        #       entries will be retrieved.
        #       If 2, at most one entry will be returned for each seq number
        #       in the results and that entry will be the most recently edited
        #       (chronologically based on history records) entry if one exists
        #       of the approved active entry.
        #       If active is any other value or not present, all entries
        #       meeting the entry-id, seq, or seq-corpus criteria will be
        #       retrieved.
        # corpus -- If not none, this is a corpus id number or name
        #       and will apply to any seq numbers without an explicit
        #       corpus given with the number.
        #
        # If the same entry is specified more than once in 'elist' and/or
        # 'qlist' ir will only occur once in the returned object list.
        # Objects in the returned list are in no particular order.

        eargs = []; qargs = []; xargs = []; whr = [];  corpid = None
        if corpus is not None:
            corpid = corp2id (corpus)
            if corpid is None:
                errs.append ("Bad corpus parameter: %s" % corpus)
                return []
        for x in (elist or []):
            try: eargs.append (str2eid (str(x)))
            except ValueError:
                errs.append ("Bad url parameter received: " + esc(x))
        if eargs: whr.append ("id IN (" + ','.join(['%s']*len(eargs)) + ")")

        for x in (qlist or []):
            try: args = list (str2seq (str(x)))
            except ValueError:
                errs.append ("Bad parameter received: " + esc(x))
            else:
                if corpus and not args[1]: args[1] = corpid
                if args[1]:
                    whr.append ("(seq=%s AND src=%s)"); qargs.extend (args)
                else:
                    whr.append ("seq=%s"); qargs.append (args[0])
        if not whr: errs.append ("No valid entry or seq numbers given.")
        if errs: return None
        whr2 = ''; distinct = ''; hjoin = ''; order = ''
        try: active = int (active)
        except (ValueError, TypeError): pass
        if active == 1:
              # Following will restrict returned rows to active/approved
              # (stat=A and not unap) or new (dfrm is NULL), that is, the
              # result set will not include any stat=D or stat=R results.
            whr2 = " AND stat=%s AND (NOT unap OR dfrm IS NULL)"
            xargs.append (jdb.KW.STAT['A'].id)
        elif active == 2:
              # Restrict returned rows to active (no stat=D or stat=R results)
              # and most recent edit as determined by the history records (if any).
              # In no event will more than one entry per seq number be returned.
              # Note that this will necessarily return the edit from only one
              # branch when multiple branches exist which may result in surprise
              # for a user when the returned entry shows no signs of a recent
              # edit known to have been made.
              # Example of generated sql:
              # SELECT DISTINCT ON (e.seq) e.id FROM entr e LEFT JOIN hist h ON h.entr=e.id
              #  WHERE e.seq=2626330 and e.stat=2 ORDER BY e.seq,h.dt DESC NULLS LAST;
            whr2 = " AND e.stat=%s"
            xargs.append (jdb.KW.STAT['A'].id)
            distinct = " DISTINCT ON (e.seq)"
            hjoin = " LEFT JOIN hist h ON h.entr=e.id"
              # "NULLS LAST" is needed below because some entries (e.g., entries
              # imported when JMdictDB is first initialized and never edited)
              # may not have history records which will result in 'dt' values of
              # NULL; we want those entries last.
            order = " ORDER BY e.seq,h.dt DESC NULLS LAST"
        sql = "SELECT" + distinct + " e.id FROM entr e " \
                 + hjoin + " WHERE (" + " OR ".join (whr) + ")" + whr2 + order
        entries, raw = jdb.entrList (dbh, sql, eargs+qargs+xargs, ret_tuple=True)
        if entries:
            jdb.augment_xrefs (dbh, raw['xref'])
            jdb.augment_xrefs (dbh, raw['xrer'], rev=1)
            jdb.add_xsens_lists (raw['xref'])
            jdb.mark_seq_xrefs (dbh, raw['xref'])
        return entries

def gen_page (tmpl, output=None, macros=None, xml=False, **kwds):
        httphdrs = kwds.get ('HTTP', None)
        if not httphdrs:
            if not kwds.get ('NoHTTP', None):
                httphdrs = "Content-type: text/html\n"
        if not httphdrs: html = ''
        else: html = httphdrs + "\n"
          # FIXME: 'tmpl' might contain a directory component containing
          #  a dot which breaks the following.
        if tmpl.find ('.') < 0: tmpl = tmpl + '.tal'
        tmpldir = jdb.find_in_syspath (tmpl)
        if tmpldir == '': tmpldir = "."
        if not tmpldir:
            raise IOError ("File or directory '%s' not found in sys.path" % tmpl)
        if macros:
            macros = tal.mktemplate (tmpldir + '/' + macros, xml=xml)
            kwds['macros'] = macros
        html += tal.fmt_simpletal (tmpldir + '/' + tmpl, xml=xml, **kwds)
        if output: print (html, file=output)
        return html

def err_page (errs):
        if isinstance (errs, str): errs = [errs]
        gen_page ('tmpl/url_errors.tal', output=sys.stdout, errs=errs)
        sys.exit()

def logw (msg, pre=''):
        #return   # Uncomment me to disable logging.
        if isinstance (msg, str): msg = msg.encode ('utf-8')
        try: pid = os.getpid()
        except OSError: pid = ''
        ts = datetime.datetime.now().isoformat(' ')
        try:
            logf = open ("./jmdictdb.log", "a")
            print ("%s%s [%s]: %s" % (pre, ts, pid, msg), file=logf)
            logf.close()
        except Exception: pass

def htmlprep (entries):
        """\
        Prepare a list of entries for display with an html template
        by adding some additional information that is inconvenient to
        generate from within a template."""

        add_p_flag (entries)
        add_restr_summary (entries)
        add_stag_summary (entries)
        add_audio_flag (entries)
        add_editable_flag (entries)
        add_unreslvd_flag (entries)
        add_pos_flag (entries)

def add_p_flag (entrs):
        # Add a supplemantary attribute to each entr object in
        # list 'entrs', that has a boolean value indicating if
        # any of its readings or kabji meet wwwjdic's criteria
        # for "P" status (have a freq tag of "ichi1", "gai1",
        # "spec1", or "news1").

        for e in entrs:
            if jdb.is_p (e): e.IS_P = True
            else: e.IS_P = False

def add_restr_summary (entries):

        # This adds an _RESTR attribute to each reading of each entry
        # that has a restr list.  The ._RESTR attribute value is a list
        # of text strings giving the kanji that *are* allowed with the
        # reading.  Recall that the database (and entry object created
        # therefrom) stores the *disallowed* reading/kanji combinations
        # but one generally wants to display the *allowed* combinations.
        #
        # Also add a HAS_RESTR boolean flag to the entry if there are
        # _restr items on any reading.

        for e in entries:
            if not hasattr (e, '_rdng') or not hasattr (e, '_kanj'): continue
            for r in e._rdng:
                if not hasattr (r, '_restr'): continue
                rt = fmt.restrtxts (r._restr, e._kanj, '_restr')
                if rt: r._RESTR = rt
                e.HAS_RESTR = 1

def add_stag_summary (entries):

        # This adds a STAG attribute to each sense that has any
        # stagr or stagk restrictions.  .STAG is set to a single
        # list that contains the kana or kanji texts strings that
        # are allowed for the sense under the restrictions.

        for e in entries:
            for s in getattr (e, '_sens', []):
                rt = []
                if getattr (s, '_stagr', None):
                    rt.extend (fmt.restrtxts (s._stagr, e._rdng, '_stagr'))
                if getattr (s, '_stagk', None):
                    rt.extend (fmt.restrtxts (s._stagk, e._kanj, '_stagk'))
                if rt:
                    s._STAG = rt

def add_audio_flag (entries):

        # The display template shows audio records at the entry level
        # rather than the reading level, so we set a HAS_AUDIO flag on
        # entries that have audio records so that the template need not
        # sear4ch all readings when deciding if it should show the audio
        # block.
        # [Since the display template processes readings prior to displaying
        # audio records, perhaps the template should set its own global
        # variable when interating the readings, and use that when showing
        # an audio block.  That would eliminate the need for this function.]

        for e in entries:
            if getattr (e, '_snd', None):
                e.HAS_AUDIO = 1;  continue
            for r in getattr (e, '_rdng', []):
                if getattr (r, '_snd', None):
                    e.HAS_AUDIO = 1
                    break

def add_editable_flag (entries):

        # This is a convenience function to avoid embedding this logic
        # in the TAL templates.  This sets a boolean EDITABLE flag on
        # each entry that says whether or not an "Edit" button should
        # be shown for the entry.  All unapproved entries, and approved
        # active or deleted entries are editable.  Rejected entries aren't.

        KW = jdb.KW
        for e in entries:
            e.EDITABLE = e.unap or (e.stat == KW.STAT['A'].id)\
                                or (e.stat == KW.STAT['D'].id)

def add_unreslvd_flag (entries):

        # This is a convenience function to avoid embedding this logic
        # in the TAL templates.  This sets a boolean UNRESLVD flag on
        # each entry that says whether or not it has any senses that
        # have unresolved xrefs in its '_xunr' list.

        KW = jdb.KW
        for e in entries:
            e.UNRESLVD = False
            for s in e._sens:
                if len (getattr (s, '_xunr', [])) > 0:
                    e.UNRESLVD = True

def add_pos_flag (entries):

        # This is a convenience function to avoid embedding this logic
        # in the TAL templates.  This sets a boolean POS flag on
        # each entry if any senses in the entry have a part-of-speech
        # (pos) tag that is conjugatable.  A POS tag is conjugatable
        # if its id number is an id number in jdb.KW.COPOS.  jdb.KW.COPOS
        # in turn is populated from database view 'vcopos' which are those
        # rows in kwpos which are also referenced in table 'copos' (that
        # identifies them as conjugatable.)  See also the comments for
        # view 'vcopos' in pg/conj.sql.
        # The .POS attribute set by this function is used to determine
        # if a "Conjugations" link should be shown for the entry.

        KW = jdb.KW
        conjugatable_poslist = [x.id for x in jdb.KW.recs('COPOS')]
        for e in entries:
            e.POS = False
            for s in e._sens:
                for p in s._pos:
                    if p.kw in conjugatable_poslist:
                        e.POS = True;  break

def add_filtered_xrefs (entries, rem_unap=False):

        # Generate substitute _xref and _xrer lists and put them in
        # sense attribute .XREF and .XRER.  These lists are copies of
        # ._xref and ._xrer but references to deleted or rejected
        # entries are removed.  Additionally, if 'rem_unap' is true,
        # references to unapproved entries are also removed *if*
        # the current entry is approved.
        # The xrefs in ._xref and ._xrer must be augmented xrefs (i.e.
        # have had jdb.augment_xrefs() called on the them.)
        #
        # FIXME: have considered not displaying reverse xref if an
        #  identical forward xref (to same entr/sens) exists.  If
        #  we want to do that, this is the place.

        cond = lambda e,x: (e.unap or not x.TARG.unap or not rem_unap) \
                            and x.TARG.stat==jdb.KW.STAT['A'].id
        for e in entries:
            for s in e._sens:
                s.XREF = [x for x in s._xref if cond (e, x)]
                s.XRER = [x for x in s._xrer if cond (e, x)]

def add_encodings (entries, gahoh_url=None):

        # Add encoding info which is displayed when presenting kanjidic
        # (or similar single-character) entries.

        for e in entries:
            if not hasattr (e, 'chr') or not e.chr: continue
            c = e.chr; c.enc = {}
            c.enc['uni'] = hex (ord (c.chr)).upper()[2:]
            c.enc['unid'] = ord (c.chr)
            c.enc['uurl'] = 'http://www.unicode.org/cgi-bin/GetUnihanData.pl?codepoint=' + c.enc['uni']
            c.enc['utf8'] = ' '.join(["%0.2X"%x for x in c.chr.encode('utf-8')])
            try:
                iso2022jp = c.chr.encode ('iso2022-jp')
                c.enc['iso2022jp'] = ' '.join(["%0.2X"%x for x in iso2022jp])
                c.enc['jis'] = ''.join(["%0.2X"%x for x in iso2022jp[3:5]])
            except UnicodeEncodeError: c.enc['iso2022jp'] = c.enc['jis'] = '\u3000'
            try: c.enc['sjis'] = ''.join(["%0.2X"%x for x in c.chr.encode('sjis')])
            except UnicodeEncodeError: c.enc['sjis'] = '\u3000'
            try: c.enc['eucjp'] = ''.join(["%0.2X"%x for x in c.chr.encode('euc-jp')])
            except UnicodeEncodeError: c.enc['eucjp'] = '\u3000 '

class SearchItems (jdb.Obj):
    """Convenience class for creating objects for use as an argument
    to function so2conds() that prevents using invalid attribute
    names."""

    def __setattr__ (self, name, val):
        if name not in ('idtyp','idnum','src','txts','pos','misc',
                        'fld','dial','freq','kinf','rinf','grp','stat','unap',
                        'nfval','nfcmp','gaval','gacmp','ts','smtr', 'mt'):
            raise AttributeError ("'%s' object has no attribute '%s'"
                                   % (self.__class__.__name__, name))
        self.__dict__[name] = val

class SearchItemsTexts (jdb.Obj):
    """Convenience class for creating objects for use in the 'txts'
    attribute of SearchItems objects that prevents using invalid
    attribute names."""

    def __setattr__ (self, name, val):
        if name not in ('srchtxt','srchin','srchtyp','inv'):
            raise AttributeError ("'%s' object has no attribute %s"
                                   % (self.__class__.__name__, name))
        self.__dict__[name] = val

def so2conds (o):
        """
        Convert an object containing search criteria (typically
        obtained from a web search page or gui search form) into
        a list of search "conditions" suitable for handing to the
        jdb.build_search_sql() function.

        Attributes of 'o':
          idtyp -- Either "id" or "seq".  Indicates if 'idnum'
                should be interpreted as an entry id number, or
                an entry sequence number.  If the former, all
                other attributes other than 'idnum' are ignored.
                If the latter, all other attributes other than
                'idnum' and 'src' are ignored.
          idnum -- An integer that is either the entry id number
                or sequence number of the target entry.  Which it
                will be interpreted is determined by the 'idtyp'
                attribute, which but also be present, if 'idnum'
                is present.
          src -- List of Corpus keywords.
          txts -- A list of objects, each with the following
                   attributes:
              srchtxt -- Text string to be searched for.
              srchin --Integer indicating table to be searched:
                1 -- Determine table by examining 'srchtxt':
                2 -- Kanj table.
                3 -- rdng table
                4 -- Gloss table.
              srchtyp -- Integer indicating hot to search for
                   'srchtxt':
                1 -- 'srchtxt' must match entire text string in table
                        (i.e. and "exact" match.)
                2 -- 'srchtxt' matches the leading text in table (i.e.
                        anchorded at start).
                3 -- 'srchtxt' matches a substring of text in table
                        (i.e. is contained anywhere in the table's text).
                4 -- 'srchtxt' matches the trailing text in table
                        (i.e. anchored at end).
              inv -- If true, invert the search sense: find entries
                    where the text doesn't match according the the
                    given criteria.
          pos -- List of Part of Speech keywords.
          misc -- List of Misc (sense) keywords.
          fld -- List of Field keywords.
          dial -- List of Dialect keywords.
          kinf -- List of Kanj Info keywords.
          rinf -- List of Reading Info of Speech keywords.
          grp -- List of entry group keywords.
          stat -- List of Status keywords.
          unap -- List of Unapproved keywords.  #FIXME
          freq -- List of Frequency keywords.  #FIXME
                Note that an entry matches if there is either a
                matching kanj freq or a matching rdng freq.  There
                is no provision to specify just one or the other.
          ts -- History min and max time limits as a 2-tuple.  Each
                time value is either None or number of seconds from
                the epoch as returned by time.localtime() et.al.
          smtr -- 2-tuple of name to match with hist.name, and bool
                indicating a wildcard match is desired.
          mt -- History record match type as an int:
                  0: match any hist record
                  1: match only first hist record
                 -1: match only last hist record

        Since it is easy to mistype attribute names, the classes
        jdb.SearchItems can be used to create an object to pass
        to so2conds.  It checks attribute names and will raise an
        AttributeError in an unrecognised one is used.
        SearchItemsTexts is similar for the objects in the '.txts'
        list.

        Example:
            # Create a criteria object that will look for in jmdict
            # and the tanaka (examples) corpus for entries with
            # a gloss (srchin=4) containing (srchtyp=2) the text
            # "helper".

          srch_criteria = jdb.SearchItems (
                                 src=['jmdict','examples'],
                                 txts=[jdb.SearchItemsTexts (
                                     srchtxt="helper",
                                     srchin=4,
                                     srchtyp=2)])

            # Convert the criteria object into a "condition list".

          condlist = so2conds (srch_criteria)

            # Convert the condition list into the sql and sql arguments
            # need to perform the search.

          sql, sql_args = build_srch_sql (condlist)

            # Give the sql to the entrList() function to retrieve
            # entry objects that match the search criteria.

          entry_list = entrList (dbcursor, sql, sql_args)

            # Now one can display or otherwise do something with
            # the found entries.

        """
        conds = []
        n = int(getattr (o, 'idnum', None) or 0)
        if n:
            idtyp = getattr (o, 'idtyp')
            if idtyp == 'id':    # Id Number
                conds.append (('entr','id=%s',[n]))
            elif idtyp == 'seq':  # Seq Number
                conds.append (('entr','seq=%s',[n]))
                conds.extend (_kwcond (o, 'src',  "entr e", "e.src"))
            else: raise ValueError ("Bad 'idtyp' value: %r" % idtyp)
            return conds

        for n,t in enumerate (getattr (o, 'txts', [])):
            conds.extend (_txcond (t, n))
        conds.extend (_kwcond (o, 'pos',  "pos",    "pos.kw"))
        conds.extend (_kwcond (o, 'misc', "misc",   "misc.kw"))
        conds.extend (_kwcond (o, 'fld',  "fld",    "fld.kw"))
        conds.extend (_kwcond (o, 'dial', "dial",   "dial.kw"))
        conds.extend (_kwcond (o, 'kinf', "kinf",   "kinf.kw"))
        conds.extend (_kwcond (o, 'rinf', "rinf",   "rinf.kw"))
        conds.extend (_kwcond (o, 'grp',  "grp",    "grp.kw"))
        conds.extend (_kwcond (o, 'src',  "entr e", "e.src"))
        conds.extend (_kwcond (o, 'stat', "entr e", "e.stat"))
        conds.extend (_boolcond (o, 'unap',"entr e","e.unap", 'unappr'))
        conds.extend (_freqcond (getattr (o, 'freq', []),
                                 getattr (o, 'nfval', None),
                                 getattr (o, 'nfcmp', None),
                                 getattr (o, 'gaval', None),
                                 getattr (o, 'gacmp', None)))
        conds.extend (_histcond (getattr (o, 'ts',    None),
                                 getattr (o, 'smtr',  None),
                                 getattr (o, 'mt',    None)))
        return conds

def _txcond (t, n):
        txt = t.srchtxt
        intbl  = getattr (t, 'srchin', 1)
        typ    = getattr (t, 'srchtyp', 1)
        inv    = getattr (t, 'srchnot', '')
        cond = jdb.autocond (txt, typ, intbl, inv, alias_suffix=n)
        return [cond]

def _kwcond (o, attr, tbl, col):
        vals = getattr (o, attr, None)
        if not vals: return []
          # FIXME: following hack breaks if first letter of status descr
          #  is not same as kw string.
        if attr == 'stat': vals = [x[0] for x in vals]
        kwids, inv = jdb.kwnorm (attr.upper(), vals)
        if not kwids: return []
        cond = tbl, ("%s %sIN (%s)" % (col, inv, ','.join(str(x) for x in kwids))), []
        return [cond]

def _boolcond (o, attr, tbl, col, true_state):
        vals = getattr (o, attr, None)
        if not vals or len(vals) == 2: return []
        inv = ''
        if vals[0] != true_state: inv = 'NOT '
        cond = tbl, (inv + col), []
        return [cond]

def _histcond (ts, smtr, mt):
        conds = []
        if ts and (ts[0] or ts[1]):
              # ts[0] and[1] are 9-tuples of ints that correspond
              # to time.struct_time objects.  We convert them to
              # datetime.datetime objects.
            if ts[0]: conds.append (('hist', "dt>=%s", [datetime.datetime.fromtimestamp(int(ts[0]))]))
            if ts[1]: conds.append (('hist', "dt<=%s", [datetime.datetime.fromtimestamp(int(ts[1]))]))
        if smtr and smtr[0]:
            name, wc = smtr
            if not wc: conds.append (('hist', "lower(name)=lower(%s)", [name]))
            else: conds.append (('hist', "name ILIKE %s", [wc2like (name)]))
        if mt:
            if int(mt) ==  1: conds.append (('hist', "hist=1", []))
            if int(mt) == -1: conds.append (('hist', "hist=(SELECT COUNT(*) FROM hist WHERE hist.entr=e.id)", []))
        return conds

def _freqcond (freq, nfval, nfcmp, gaval, gacmp):
        # Create a pair of 3-tuples (build_search_sql() "conditions")
        # that build_search_sql() will use to create a sql statement
        # that will incorporate the freq-of-use criteria defined by
        # our parameters:
        #
        # $freq -- List of indexes from a freq option checkboxe, e.g. "ichi2".
        # $nfval -- String containing an "nf" number ("1" - "48").
        # $nfcmp -- String containing one of ">=", "=", "<=".
        # gaval -- String containing a gA number.
        # gacmp -- Same as nfcmp.

        # Freq items consist of a domain (such as "ichi" or "nf")
        # and a value (such as "1" or "35").
        # Process the checkboxes by creating a hash indexed by
        # by domain and with each value a list of freq values.

        KW = jdb.KW
        x = {};  inv = ''
        if 'NOT' in freq:
            freq.remove ('NOT')
            inv = 'NOT '
        # FIXME: we really shouldn't hardwire this...
        if 'P' in freq:
            freq.remove ('P')
            freq = list (set (freq + ['ichi1','gai1','news1','spec1']))
        for f in freq:
              # Split into text (domain) and numeric (value) parts.
            match = re.search (r'^([A-Za-z_-]+)(\d*)$', f)
            domain, value = match.group(1,2)
            if domain == 'nf': have_nf = True
            elif domain == 'gA': have_gA = True
            else:
                  # Append this value to the domain list.
                x.setdefault (domain, []).append (value)

        # Now process each domain and it's list of values...

        whr = []
        for k,v in list(x.items()):
              # Convert the domain string to a kwfreq table id number.
            kwid = KW.FREQ[k].id

              # The following assumes that the range of values are
              # limited to 1 and 2.

              # As an optimization, if there are 2 values, they must be 1 and 2,
              # so no need to check value in query, just see if the domain exists.
              # FIXME: The above is false, e.g., there could be two "1" values.
              # FIXME: The above assumes only 1 and 2 are allowed.  Currently
              #   true but may change in future.
            if len(v) == 2: whr.append ("(freq.kw=%s)" % kwid)
              # If there is only one value we need to look for kw with
              # that value.
            elif len(v) == 1: whr.append ("(freq.kw=%s AND freq.value=%s)" % (kwid, v[0]))
              # If there are more than 2 values then we look for them explicitly
              # using an IN() construct.
            elif len(v) > 2: whr.append (
                "(freq.kw=%s AND freq.value IN (%s))" % (k, ",".join(v)))
              # A 0 length list should never occur.
            else: raise ValueError ("No numeric value in freq item")

          # Handle any "nfxx" item specially here.

        if nfval:
            kwid = KW.FREQ['nf'].id
            # Build list of "where" clause parts using the requested comparison and value.
            whr.append (
                "(freq.kw=%s AND freq.value%s%s)" % (kwid, nfcmp, nfval))

          # Handle any "gAxx" item specially here.

        if gaval:
            kwid = KW.FREQ['gA'].id
              # Build list of "where" clause parts using the requested comparison and value.
            whr.append (
                "(freq.kw=%s AND freq.value%s%s)" % (kwid, gacmp, gaval))

          # If there were no freq related conditions...
        if not whr: return []

        # Now, @whr is a list of all the various freq related conditions that
        # were  selected.  We change it into a clause by connecting them all
        # with " OR".
        whr = ("%s(" + " OR ".join(whr) + ")") % inv

        # Return a triple suitable for use by build-search_sql().  That function
        # will build sql that effectivly "AND"s all the conditions (each specified
        # in a triple) given to it.  Our freq conditions applies to two tables
        # (rfreq and kfreq) and we want them OR'd not AND'd.  So we cheat and use a
        # strisk in front of table name to tell build_search_sql() to use left joins
        # rather than inner joins when refering to that condition's table.  This will
        # result in the inclusion in the result set of rfreq rows that match the
        # criteria, even if there are no matching kfreq rows (and visa versa).
        # The where clause refers to both the rfreq and kfreq tables, so need only
        # be given in one constion triple rather than in each.

        return [("freq",whr,[])]

def utt (d):
        # Convert a simple string-to-string mapping into
        # the form required by <unicode>.translate().
        return dict ((ord(k), str(v)) for k,v in list(d.items()))

Wc_trans = utt({'*':'%', '?':'_', '%':'\\%', '_':'\\_'})
def wc2like (s):
        # Convert a string with wildcard characters '*' and '?' to SQL
        # "like" operator characters, "%" and "_", being careful of
        # escape "\" characters.
        s1 = str (s)
        s1 = s1.replace ('\\*', '\x01')
        s1 = s1.replace ('\\?', '\x02')
        s1 = s1.translate (Wc_trans)
        s1 = s1.replace ('\x01', '*')
        s1 = s1.replace ('\x02', '?')
        return s1

