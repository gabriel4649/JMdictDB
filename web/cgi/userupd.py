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

import sys, cgi, copy, time, os, re
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import logger; from logger import L; logger.enable()
import jdb, jmcgi

def main( args, opts ):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        errs = []; so = None; stats = {}
        try: form, svc, dbg, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])
        fv = form.getfirst; fl = form.getlist

          # The form values "userid", "fullname", "email", "priv",
          #  "disabled", come from editable fields in the user.py
          #  page.
          # The values "new" (i.e. create) and "delete" are also user
          #  boolean input from user.py indicating what the user wants
          #  to do.  Neither of them set indicates an update action on
          #  an existing account.  Both of them set is an error.
          # The form value "subjid" identifies the user whose data was 
          #  originally loaded into the user.py form and is the user any
          #  update or delete will be performed on.  If it differs from
          #  sess.userid it indcates the action is to e done on the 
          #  account of someone other than the logged user themself 
          #  and is prohibited unless the logged in user has "admin"
          #  privilege.  For a new (create) action, "subjid" is ignored
          #  and the new user is created with the id given in "userid".

          # Set 'action' to "n" (new), "u" (update), "d" (delete) or
          #  "x" (invalid) according to the values of fv('new') and 
          #  fv('delete') that were received from as url parameters
          #  from the User form. 
        action = {(0,0):'u', (0,1):'d', (1,0):'n', (1,1):'x'}\
                   [(bool(fv('new')),bool(fv('delete')))]
        L('cgi.userupd').debug(
            "new=%r, delete=%r, action=%r, subjid=%r, userid=%r"
            % (fv('new'), fv('delete'), action, fv('subjid'), fv('userid')))
 
          # NOTE: The jmcgi.err_page() calls below do not return,
          #  jmcgi.err_page() calls sys.exit().

        if not sess:
            jmcgi.err_page ([], 
                prolog="<p>You must login before you can change your "
                           "user settings.</p>")
        if fv('subjid') != sess.userid and sess.priv != 'A':
            jmcgi.err_page ([],
                prolog="<p>You do not have sufficient privilege to alter "
                         "settings for anyone other than yourself.</p>")
        if action in ('nd') and sess.priv != 'A':
            jmcgi.err_page ([],
                prolog="<p>You do not have sufficient privilege to create "
                          "or delete users.</p>")
        if action == 'x':
            jmcgi.err_page ([],
                prolog="<p>\"New user\" and \"Delete\" are incompatible.</p>")

        errors = []
         # Get the id of the user we will be updating.  If creating a
         # new user, 'subjid' should not exist and thus 'subj' will be
         # None which has the beneficial effect of causing gen_sql_-
         # params() to generate change parameters for every form value
         # which is what we want when creating a user.
        subj = jmcgi.get_user (fv('subjid'), svc, cfg)
        if action in 'nu':   # "new" or "update" action...
            if action == 'u':
               L('cgi.userupd').debug("update user %r" % sanitize_o(subj))
            else:
                L('cgi.userupd').debug("create user %r" % fv('userid'))
            if action == 'n' and \
                    (subj or fv('userid')==sess.userid
                     or jmcgi.get_user(fv('userid'), svc, cfg)):
                  # This is the creation of a new user (fv('userid')). 
                  # The userid must not already exist.  The tests for
                  # subj and sess.userid are simply to avoid an expensive
                  # get_user() call when we already know the user exists.
                errors.append ("Account name %s is already in use."
                               % fv('userid'))
            if action == 'u' and fv('userid')!=subj.userid \
                    and (fv('userid')==sess.userid \
                         or jmcgi.get_user(fv('userid'), svc, cfg)):
                  # This is an update of an existing user. 
                  # If the new userid (fv('userid')) is the same as the
                  # subj.userid it's not being changed and is ok.  If
                  # different then it must not be the same as an exiting
                  # userid.  The test for sess.userid is simply to avoid
                  # an expensive get_user() call when we already know 
                  # that user exists.
                errors.append ("Account name %s is already in use."
                               % fv('userid'))

              # Get the parameters we'll need for the sql statement used
              # to update the user/sessions database.
            collist, values, err \
                = gen_sql_params (sess.priv=='A', subj, fv('pw1'), fv('pw2'),
                                  fv('userid'), fv('fullname'), fv('email'),
                                  fv('priv'), fv('disabled'))
            errors.extend (err)
            L('cgi.userupd').debug("collist: %r" % collist)
            L('cgi.userupd').debug("values: %r" % sanitize_v (values, collist))
 
        else:  # "delete" action...
              # We ignore changes made to the form fields since we
              # are going to delete the user, they are irrelevant. 
              # Except for one: the "userid" field.  If that was
              # changed we treat it as an error due to the risk that
              # the user thought the changed userid will be deleted
              # which is not what will happen (we delete the "subjid"
              # user.)
            values = []
            if fv('userid') != fv('subjid'):
                errors.append (
                    "Can't delete user when userid has been changed.")
            if not subj:
                errors.append ("User '%s' doesn't exist." % fv('subjid'))

        if errors:
            jmcgi.err_page (errs=errors, 
                prolog="The following errors were found in the changes "
                "you requested.  Please use your browser's Back button "
                "to return to the user page, correct them, and resubmit "
                "your changes.")

        update_session = None;  result = None
        if action == 'n':                         # Create new user...
            cols = ','.join (c for c,p in collist)
            pmarks = ','.join (p for c,p in collist)
            sql = "INSERT INTO users(%s) VALUES (%s)" % (cols, pmarks)
            values_sani = sanitize_v (values, collist)
        elif action == 'd':                       # Delete existing user...
            sql = "DELETE FROM users WHERE userid=%s"
            values.append (fv('subjid'))
            values_sani = values
        else:                                     # Update existing user...
            if not collist: result = 'nochange'
            else:
                if subj and subj.userid == sess.userid \
                        and fv('userid') and fv('userid'): 
                    update_session = fv('userid')
                updclause = ','.join (("%s=%s" % (c,p)) for c,p in collist)
                sql = "UPDATE users SET %s WHERE userid=%%s" % updclause
                values.append (fv('subjid'))
                values_sani = sanitize_v (values, collist)

        if result != 'nochange':
            sesscur = jdb.dbOpenSvc (cfg, svc, session=True, nokw=True)
            L('cgi.userupd').debug("sql:  %r" % sql)
              # 'values_sani' should be the same as values but with any
              # password text masked out.
            L('cgi.userupd').debug("args: %r" % values_sani)
            sesscur.execute (sql, values)
            sesscur.connection.commit()
              #FIXME: trap db errors and try to figure out what went
              # wrong in terms that a user can remediate.
            if update_session:
                L('cgi.userupd').debug("update sess.userid: %r->%r" 
                                       % (sess.userid, update_session))
                sess.userid = update_session
            result = 'success'
          # If the user is not an admin we send them back to their
          # settings page (using 'userid' since it they may have changed
          # it.)  For admin users it's more complcatd because they might
          # have deleted the user.  Easiest for us to send him/her back
          # to the user list page which we know always exists.
        if sess.priv=='A': return_to = 'users.py?'
        else:
            return_to = 'user.py?u=%s' % fv('userid')
        jmcgi.redirect (urlbase()
                + "%s&svc=%s&sid=%s&dbg=%s&result=%s"
                  % (return_to, svc, sid, dbg, result))

def gen_sql_params (is_admin, subj, pw1, pw2, userid, fullname, email,
                    priv, disabled):
        """
        Compares the form values received from the User form
        with the values in 'subj' to determine which have been
        changed.  For user creation ("new" action) there is no
        'subj' so any non-null form values will be seen as changes.
        If the action is delete, this function need not even be 
        called since the only info needed for deletion is the
        user id.

        Return values: 
        collist -- A list of 2-tuples each consisting of
           column name -- Name of the changed field/
           parameter -- This is either a psycopg2 paramater marker
             ("%s") or a Postgresql expression containing the same.
        values -- A list of the same length as 'collist' containing
           the values the will be substituted for the parameter markers
           in collist be Postgresql.
        errors -- A list of errors discovered when generating 'collist'
           and 'values'.  If this list in non-empty, 'collist' and
           'values' should be ignored and the errors should be displayed
           to the user. 
        """

        new = not subj
        collist = [];  values = [];  errors = [];

        if pw1 or pw2:
            if pw1 != pw2:
                errors.append ("Password mismatch.  Please reenter "
                               "your passwords.")
            else:
                collist.append (('pw', "crypt(%s, gen_salt('bf'))"))
                values.append (pw1)
        else:
            errors.append ("Password is required for new users.")

        if new or userid != subj.userid:
            L('cgi.userupd').debug("userid change: %r" % userid)
              # Max length of 16 is enforced in database DDL.
            if not re.match (r'[a-zA-Z][a-zA-Z0-9]{2,15}$', userid or ''):
                errors.append ('Invalid "userid" value')
            else:
                collist.append (('userid', "%s"))
                values.append (userid)

        if new or fullname != subj.fullname:
            L('cgi.userupd').debug("fullname change: %r" % fullname)
            if fullname and len (fullname) > 120:
                  # This limit is not enforced in database DDL but is
                  # applied here as a sanity/maleficence check.
                errors.append ("Full name is too long, max of 120 "
                               "characters please.")
            collist.append (('fullname', "%s"))
            values.append (fullname)

        if new or email != subj.email:
            L('cgi.userupd').debug("email change: %r" % email)
            if email and '@' not in (email):
                errors.append ('Email addresses must include an "@" '
                               'character.')
            elif email and len (email) > 120:
                  # This limit is not enforced in database DDL but is
                  # applied here as a sanity/maleficence check.
                errors.append ("Email address too long, max of 120 "
                               "characters please.")
            else:
                collist.append (('email', "%s"))
                values.append (email)

        if is_admin:
              # Only if the script executor is an admin user do we
              # allow changing the account's priv or disabled status.

            if new or priv != subj.priv:
                L('cgi.userupd').debug("priv change: %r" % priv)
                collist.append (('priv', "%s"))
                values.append ({'admin':'A', 'editor':'E'}.get (priv, None))

            if new or bool(disabled) != subj.disabled:
                L('cgi.userupd').debug("disabled change: %r" % bool(disabled))
                collist.append (('disabled', "%s"))
                values.append (bool(disabled))

        return collist, values, errors

def urlbase():
        pathinfo = os.environ.get('PATH_INFO', '')
        return pathinfo

def sanitize_o (obj):
        if not hasattr (obj, 'pw'): return obj
        o = obj.copy()
        if o.pw: o.pw = sanitize_s (o.pw)
        return o

def sanitize_v (values, collist):
        try: i = [c for c,p in collist].index ('pw')
        except ValueError: return values
        v = copy.copy (values)
        v[i] = sanitize_s (v[i])
        return v

def sanitize_s (s):
        if not s: return s
        return '***'

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
