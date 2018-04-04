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
#  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#######################################################################

import cgi, os.path, pdb
import jinja2
import jdb

def add_filters (env):
          # Load the database keyword tables object which we use to
          # convert id's to keyword and descriptions.  However we may
          # need to render pages before the KW table is available (to
          # render an error page when the database is not available,
          # for example) so we continue on without it if necessary
          # though this will cause any subsequent filter invocations
          # that require it to fail.
        try: KW = jdb.KW
        except AttributeError: KW = None

          # The add_filter decoractors are right justified to make it
          # easier to visually locate filter functions by name.
        @                                                      add_filter (env)
        def TALhas (parent, attr):
            return hasattr (parent, attr) and getattr (parent, attr)
        @                                                      add_filter (env)
        def TALattrand (parent, *attrs):
            for a in attrs:
                if not getattr (parent, a, None): return False
            return True
        @                                                      add_filter (env)
        def TALattror (parent, *attrs):
            for a in attrs:
                if getattr (parent, a, None): return True
            return False
        @                                                      add_filter (env)
        def TALabbrtxt (id, kwtyp):
            return _abbr (kwtyp, id, True)
        @                                                      add_filter (env)
        def TALabbr (id, kwtyp):
            return _abbr (kwtyp, id)
        @                                                      add_filter (env)
        def TALabbrs (parent, kwtyp, attr, sep=','):
            kws = getattr(jdb.KW,kwtyp)
            return sep.join([_abbr (kwtyp, x.kw) for x in getattr (parent,attr)])
        @                                                      add_filter (env)
        def TALdescr (id, kwtyp):
            kws = getattr(jdb.KW,kwtyp)
            return kws[id].descr
        @                                                      add_filter (env)
        def TALdescrs (parent, kwtyp, attr, sep=','):
            kws = getattr(jdb.KW,kwtyp)
            return sep.join([kws[x.kw].descr for x in getattr(parent,attr)])
        @                                                      add_filter (env)
        def TALfreqs (parent, sep=','):
            f = jdb.freq2txts(getattr(parent,'_freq'), tt=True)
            return sep.join (f)
        @                                                      add_filter (env)
        def TALtxts (parent, attr, sep=';'):
              # Return a string consisting of 'sep' '.txt' values
              # from each object in the list at 'parent'.'attr'.
            return sep.join([x.txt for x in getattr(parent,attr,[])])
        @                                                      add_filter (env)
        def TALkrtxt (parent, attr, idx):
              # Used for getting xref kanj/rdng, e.g:
              #    <span tal:condition="xref/TARG/_kanj"
              #          tal:replace="python:TALkrtxt(xref.TARG,'_kanj',xref.kanj)">
              #       xref-kanj</span>
            x = getattr(parent,attr,None)
            if not x or idx is None: return ''
            return x[idx-1].txt
        @                                                      add_filter (env)
        def TALgrps (parent, sep='; '):
              # Return a string representing a list of groups.
            grps = getattr(parent,'_grp',None)
            if not grps: return ''
            return sep.join ([fmtjel.grp (x) for x in grps])
        @                                                      add_filter (env)
        def TALfmtjel (entr, what):
              # Item is _kanj, _rdng, or _sens list.  Return a jel formatted
              # string for the item.
            if   what=='s': return fmtjel.senss (getattr(entr,'_sens',[]),
                                                 getattr(entr,'_kanj',[]),
                                                 getattr(entr,'_rdng',[]))
            elif what=='r': return fmtjel.rdngs (getattr(entr,'_rdng',[]),
                                                 getattr(entr,'_kanj',[]))
            elif what=='k': return fmtjel.kanjs (getattr(entr,'_kanj',[]))
            else: raise ValueError ("Invalid 'what' value: %s" % what)
        @                                                      add_filter (env)
        def TALdecode (arg, *args):
              # Taking the arguments in *args pairwise, find the first
              # 2*n'th argument in *args that is "==" to 'arg', and return
              # the 2*n+1'th argument from *args.
            #import pdb; pdb.set_trace()
            for i in range (0, len(args)-1, 2):
                if arg == args[i]: return args[i+1]
            if len(args) % 2: return args[-1]
            return None
        @                                                      add_filter (env)
        def TALm2mn (monthnum, short=False):
              # Convert a month number (1-12) to the name of the month.
            if not monthnum: return ''
            mn = ['January','February','March','April','May','June','July',
                  'August','September','October','November','December']\
                 [int(monthnum)-1]
            if short: return mn[:3]
            return mn
        @                                                      add_filter (env)
        def N (arg):
            return '' if arg is None else arg
        @                                                      add_filter (env)
          # Wrap a non-vacuous argument with prefix and suffix.
        def w (arg, prefix=None, suffix=None):
              # Undefined check must be done first below since "is" or
              # "==" ops on undefined value will raise error.
            if isinstance(arg,jinja2.Undefined) or arg is None or arg=='':
                return ''
            arg = str (arg)
            if prefix: arg = prefix + arg
            if suffix: arg = arg + suffix
            return arg
        @                                                      add_filter (env)
          # Similar to Jinja2's default(boolean=True) but shorter.
        def a (arg, attrib=""):
            return attrib if bool(arg) else ""
          # Examples:
          #  <option>{{color}} {{(color=='red')|a('selected')}}</option>
          #  <checkbox ... {{default_on|a('checked')}}
          #  {{(description|a)+(suffix|a)}} {# filter changes None to "" #}
        @                                                      add_filter (env)
          # Convert  newline's to "<br>".
          # See also: 
          #   http://flask.pocoo.org/snippets/28/
          #   http://jinja.pocoo.org/docs/dev/api/#custom-filters
        def lf (s):
            return escape(s).replace('\n', jinja2.Markup('<br>\n'))
        @                                                      add_filter (env)
        def resub (s, pattern, replace=''):
            return None if s is None else re.sub (pattern, replace, s)
        @                                                      add_filter (env)
        def today (arg):
            return datetime.date.today().isoformat()
        @                                                      add_filter (env)
          # Return a datetime as string truncated to minute resolution.
        def min (dt):
            return None if dt is None else str(dt)[:16] 
        #@                                                      add_filter (env)
        #WARNING: following for development only!!
        #def py (s, expression):
        #    return eval (expression, globals(), locals())

def _abbr (kwtyp, id, textonly=False):
    # Should this be in fmt.py with freq2txt()?
        kws = getattr (jdb.KW, kwtyp)
        kw, descr =  kws[id].kw, kws[id].descr
        if descr and not textonly:
           kw = '<span class="abbr" title="%s">%s</span>' % (cgi.escape(descr,1), kw)
        return kw

def add_filter (env, name=None):
        def wrapper (f):
            env.filters[name or f.__name__] = f
            return f
        return wrapper

def render( filename, vars, env):
        t = env.get_template( filename )
        text = t.render( vars )
        return text

def init (tmpl_dir=None, trim=False, lstrip=True):
        if tmpl_dir is None:
            tmpl_dir = os.path.join (os.path.dirname (__file__), 'tmpl')
        env = jinja2.Environment( loader 
            = jinja2.FileSystemLoader (tmpl_dir) )
          # By default Jinja2 strips tailing newline from the rendered
          # template but we want result file to match temple exactly except
          # for replacement values, so following changes Jinja2's behavior.
        env.keep_trailing_newline = True
          # the following causes None to be rendered in templates as ""
          # rather than "None".
        env.trim_blocks = trim
        env.lstrip_blocks = lstrip
        env.finalize = lambda x: '' if x is None else x
          # Optionally raise an error if an undefined variable is
          # encountered when rendering a template.
        env.autoescape = True
        env.undefined=jinja2.StrictUndefined
        add_filters (env)
        return env
