#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2006,2008 Stuart McGraw
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

# This file contains functions for using SimpleTAL templates.
# The SimpleTAL software is available at
#   http://www.owlfish.com/software/simpleTAL/.
# The SimpleTAL templates used by the JMdictDB project are
#  located in python/lib/tmpl/*.tal.

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11])

import sys, logging, io, copy, re
from simpletal import simpleTAL, simpleTALES
import jdb, fmtjel

logging.basicConfig (level=logging.WARNING, stream=sys.stderr)

#FIXME: Should following function be moved into SimpleTalHelper.py?

def fmt_simpletal (tmplfn, xml=False, **kwds):
        # tmplfn -- Filename of the template file to use.
        # xml -- false: generate HTML template.
        #        true: generate XML template.
        # kwds -- Rest of keyword args will be passed to serialize().

          # When the SimpleTal evaluator processes a template it
          # appears to use the parameter KW when evaluating TALES
          # expressions (caller is responsible for passing it in
          # **kwds if needed), and the global KW  when evaluating
          # Python path expressions.

        global KW;

          # Sometimes we will want to format a template that does
          # not use KW and we may not have KW available, so ignore
          # errors when setting it up here.
        try: KW = jdb.KW
        except AttributeError: KW = None

        tmpl = mktemplate (tmplfn, xml=xml)
        txt = serialize (tmpl, **kwds)
        if txt.startswith ('\ufeff') or txt.startswith ('\ufffe'):
            txt = txt[1:]
        return txt

def mktemplate (tmplFilename, xml=False):
        tmplFile = open (tmplFilename, encoding='utf-8')
        if xml:
            tmpl = simpleTAL.compileXMLTemplate (tmplFile)
        else:
            tmpl = simpleTAL.compileHTMLTemplate (tmplFile)
        tmplFile.close()
        return tmpl

def serialize (tmpl, outfile=None, encoding='utf-8', **kwds):
        ctx = simpleTALES.Context (allowPythonPath=1)
        for k,v in list(kwds.items()): ctx.addGlobal (k, v)
          # Use StringIO module because cStringIO does not do unicode.
        if outfile is None: ofl = io.StringIO()
        else: ofl = outfile
        tmpl.expand (ctx, ofl, outputEncoding=encoding)
        if outfile: return
        txt = ofl.getvalue()
        txt = re.sub (r'\n\s*\n', r'\n', txt)
        return txt

def add2builtins (f):
        # Decorator to add function 'f' to the __builtin__ module
        # so that it will be available to the simpleTAL processor.
        import builtins
        builtins.__dict__[f.__name__] = f

# Functions added the the __builtin__ namespace below should be
# named with a prefix of 'TAL" to avoid conflicts with preexisting
# functions.

@add2builtins
def TALhas (parent, attr):
        return hasattr (parent, attr) and getattr (parent, attr)

@add2builtins
def TALattrand (parent, *attrs):
        for a in attrs:
            if not getattr (parent, a, None): return False
        return True

@add2builtins
def TALattror (parent, *attrs):
        for a in attrs:
            if getattr (parent, a, None): return True
        return False

@add2builtins
def TALabbr (kwtyp,id):
        kws = getattr(KW,kwtyp)
        return kws[id].kw

@add2builtins
def TALabbrs (kwtyp,parent,attr,sep=','):
        kws = getattr(KW,kwtyp)
        return sep.join([kws[x.kw].kw for x in getattr(parent,attr)])

@add2builtins
def TALdescr (kwtyp,id):
        kws = getattr(KW,kwtyp)
        return kws[id].descr

@add2builtins
def TALdescrs (kwtyp,parent,attr,sep=','):
        kws = getattr(KW,kwtyp)
        return sep.join([kws[x.kw].descr for x in getattr(parent,attr)])

@add2builtins
def TALfreqs (parent,sep=','):
        f = jdb.freq2txts(getattr(parent,'_freq'))
        return sep.join (f)

@add2builtins
def TALtxts (parent,attr,sep=';'):
          # Return a string consisting of 'sep' '.txt' values
          # from each object in the list at 'parent'.'attr'.
        return sep.join([x.txt for x in getattr(parent,attr,[])])

@add2builtins
def TALkrtxt (parent,attr,idx):
          # Used for getting xref kanj/rdng, e.g:
          #    <span tal:condition="xref/TARG/_kanj"
          #          tal:replace="python:TALkrtxt(xref.TARG,'_kanj',xref.kanj)">
          #       xref-kanj</span>
        x = getattr(parent,attr,None)
        if not x or idx is None: return ''
        return x[idx-1].txt

@add2builtins
def TALgrps (parent, sep='; '):
          # Return a string representing a list of groups.
        grps = getattr(parent,'_grp',None)
        if not grps: return ''
        return sep.join ([fmtjel.grp (x) for x in grps])

@add2builtins
def TALfmtjel (entr,what):
          # Item is _kanj, _rdng, or _sens list.  Return a jel formatted
          # string for the item.
        if   what=='s': return fmtjel.senss (getattr(entr,'_sens',[]), getattr(entr,'_kanj',[]), getattr(entr,'_rdng',[]))
        elif what=='r': return fmtjel.rdngs (getattr(entr,'_rdng',[]), getattr(entr,'_kanj',[]))
        elif what=='k': return fmtjel.kanjs (getattr(entr,'_kanj',[]))
        else: raise ValueError ("Invalid 'what' value: %s" % what)

@add2builtins
def TALdecode (arg, *args):
          # Takings the arguments in *args pairwise, find the first
          # 2*n'th argument in *args that is "==" to 'arg', and return
          # the 2*n+1'th argument from *args.
        #import pdb; pdb.set_trace()
        for i in range (0, len(args)-1, 2):
            if arg == args[i]: return args[i+1]
        if len(args) % 2: return args[-1]
        return None
