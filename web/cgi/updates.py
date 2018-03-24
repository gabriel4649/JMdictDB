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

# Display entries that were added or updated on a given date (that
# is, have a history entry with that date) or alternately, an index
# page that shows date links to pages for the entries updated on that
# date.
#
# URL parameters:
#   i -- Display an index page listing dates for which there
#        are undates.  Each date is a link which when clicked
#        will display the actual updates made on that date.
#        Only one year of dates is shown; the year is specified
#        with the 'y' parameter.  If 'i' is not present, a page
#        showing the actual entries updated on the date given 
#        by 'y', 'm', 'd' will be shown with the entr.tal template.  
#   y, m, d -- The year, month (1-12) and day (1-31) giving a 
#        date.  If 'i' was not given, the updates made on this
#        date will be shown.  If 'i' was given, 'm' and 'd' are
#        ignored and an index page for the year 'y' is shown.
#        If any of 'y', 'm' or 'd' are missing, its value will
#        be taken from the current date.
#   n -- A integer greater than 0 that is a number of days that
#        will be subtracted from the date given with the other
#        parameters.  This is primarily used with the value 1
#        to get "yesterday's" updates but will work consistently
#        with other values.
#   [other] -- The standard jmdictdb cgi parameters like 'svc',
#        'sid', etc.  See python/lib/jmcgi.py.

import sys, cgi, datetime
sys.path.extend (['../lib','../../python/lib','../python/lib'])
import logger; from logger import L; logger.enable()
import jdb, jmcgi

def main (args, opts):
        jdb.reset_encoding (sys.stdout, 'utf-8')
        try: form, svc, host, cur, sid, sess, parms, cfg = jmcgi.parseform()
        except Exception as e: jmcgi.err_page ([str (e)])
        formvalues = form, svc, host, cur, sid, sess, parms, cfg
        fv = form.getfirst; fl = form.getlist
        t = datetime.date.today()  # Will supply default value of y, m, d.
          # y, m, and d below are used to construct sql string and *must*
          # be forced to int()'s to eliminate possibiliy of sql injection. 
        try: y = int (fv ('y') or t.year)
        except Exception as e: 
            jmcgi.err_page ("Bad 'y' url parameter."); return

        show_index = bool (fv ('i'))
        if show_index:
            render_year_index (y, formvalues)
        else:
            try:
                m = int (fv ('m') or t.month)
                d = int (fv ('d') or t.day)
                n = int (fv ('n') or 0)
            except Exception as e:
                jmcgi.err_page ("Bad 'm', 'd' or 'n' url parameter."); return
            render_day_updates (y, m, d, n, formvalues)

def render_day_updates (y, m, d, n, formvalues):
        # If we have a specific date, we will show the actual entries that
        # were modified on that date.  We do this by retrieving Entr's for
        # any entries that have a 'hist' row with a 'dt' date on that day.
        # The Entr's are displayed using the standard entr.tal template 
        # that is also used for displaying other "list of entries" results
        # (such as from the Search Results page).

        cur = formvalues[3]
        sql = '''SELECT DISTINCT e.id
                 FROM entr e
                 JOIN hist h on h.entr=e.id
                 WHERE h.dt BETWEEN %s::timestamp
                            AND %s::timestamp + interval '1 day' '''

        day = datetime.date (y, m, d)
        if n: 
              # 'n' is used to adjust the given date backwards by 'n' days.
              # Most frequently it is used with a value of 1 in conjuction
              # with "today's" date to get entries updated "yesterday" but
              # for consistency we make it work for any date and any value
              # of 'n'.
            day = day - datetime.timedelta (n)
            y, m, d = day.year, day.month, day.day

        entries = jdb.entrList (cur, sql, (day,day,), 'x.src,x.seq,x.id')

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

        form, svc, host, cur, sid, sess, parms, cfg = formvalues
        jmcgi.gen_page ('tmpl/entr.tal', macros='tmpl/macros.tal',
                        entries=zip(entries, [None]*len(entries)), disp=None,
                        svc=svc, host=host, sid=sid, session=sess, cfg=cfg,
                        parms=parms, output=sys.stdout, this_page='entr.py')

def render_year_index (y, formvalues):
        # If 'i' was given in the URL params we will generate an index
        # page showing dates, with each date being a link back to this
        # script with the result that clicking it will show the updates
        # (viw render_day_update() above) for that date.  The range of
        # the dates are limited to one year.
        # Also on the page we generate links for each year for which
        # there are updates in the database.  Those links also points 
        # back to this script but with 'i' and a year, so that when
        # clicked, they will generate a daily index for that year.
        
        cur = formvalues[3]

          # Get a list of dates (in the form: year, month, day, count)
          # for year = 'y' for with there are hist records.  'count' is
          # the number of number of hist records with the coresponding
          # date.
            # Following can by simplified when using postgresql-9.4: 
            # see changeset jm:b930b6fd1e3b (2015-08-19)
        start_of_year = '%d-01-01' % y  
        end_of_year = '%d-12-31' % y
        sql = '''SELECT EXTRACT(YEAR FROM dt)::INT AS y, 
                     EXTRACT(MONTH FROM dt)::INT AS m, 
                     EXTRACT(DAY FROM dt)::INT AS d,
                     COUNT(*)
                 FROM hist h
                 WHERE dt BETWEEN '%s'::DATE AND '%s'::DATE 
                 GROUP BY EXTRACT(YEAR FROM dt)::INT,EXTRACT(MONTH FROM dt)::INT,EXTRACT(DAY FROM dt)::INT
                 ORDER BY EXTRACT(YEAR FROM dt)::INT,EXTRACT(MONTH FROM dt)::INT,EXTRACT(DAY FROM dt)::INT
                 ''' % (start_of_year, end_of_year)
        cur.execute (sql, (y,y))
        days = cur.fetchall()

          # Get a list of years (in the form: year, count) for which there
          # are history records.  'count' is the total number in the year.

        sql = '''SELECT EXTRACT(YEAR FROM dt)::INT AS y, COUNT(*)
                 FROM hist h 
                 GROUP BY EXTRACT(YEAR FROM dt)::INT 
                 ORDER BY EXTRACT(YEAR FROM dt)::INT DESC;'''
        cur.execute (sql, ())
        years = cur.fetchall()

        form, svc, host, cur, sid, sess, parms, cfg = formvalues
        jmcgi.gen_page ('tmpl/updates.tal', macros='tmpl/macros.tal',
                        years=years, year=y, days=days, disp=None,
                        svc=svc, host=host, sid=sid, session=sess, cfg=cfg,
                        parms=parms, output=sys.stdout, this_page='entr.py')

if __name__ == '__main__':
        args, opts = jmcgi.args()
        main (args, opts)
