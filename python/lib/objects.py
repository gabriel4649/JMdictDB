#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2006-2012 Stuart McGraw
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
from __future__ import print_function, absolute_import, division
from future_builtins import ascii, filter, hex, map, oct, zip

__version__ = ('$Revision$'[11:-2],
               '$Date$'[7:-11]);

import sys, datetime, pdb

#######################################################################
#
#  WARNING
#
#  The objects below (or any subclass of Obj) may by created in
#  web/cgi/edconf.py and other programs by de-serializing input
#  received from the internet or other untrusted user input.
#
#  It is critical that no methods be added to these objects that
#  could result in destructive or undesired behavior since such
#  behavior could be initiated by an arbitrary user supplying
#  a hand-crafted serialized object to edconf.py or other such
#  program.
#
#  These objects should be limited to acting like data structures.
#
#######################################################################
#
#  NOTE
#  When adding/deleting/modifying the classes below, be sure to
#  check in python/lib/serialize.py for any corresponding changes
#  that need to be made there.
#
#######################################################################

class Obj(object):
    # This creates "bucket of attributes" objects.  That is,
    # it creates a generic object with no special behavior
    # that we can set and get attribute values from.  One
    # could use a keys in a dict the same way, but sometimes
    # the attribute syntax results in more readable code.
    def __init__ (self, **kwds):
        for k,v in kwds.items(): setattr (self, k, v)
    def __repr__ (self):
        return self.__class__.__name__ + '(' \
                 + ', '.join([k + '=' + _p(v)
                              for k,v in self.__dict__.items() if k != '__cols__']) + ')'

class DbRow (Obj):
    def __init__(self, values=None, cols=None):
        if values is not None:
            if cols is not None:
                self.__cols__ = cols
                for n,v in zip (cols, values): setattr (self, n, v)
            else:
                self.__cols__ = values.keys()
                for n,v in values.items(): setattr (self, n, v)
    def __getitem__ (self, idx):
        return getattr (self, self.__cols__[idx])
    def __setitem__ (self, idx, value):
        name = self.__cols__[idx]
        setattr (self, name, value)
    def __len__(self):
        return len(self.__cols__)
    def __iter__(self):
        for n in self.__cols__: yield getattr (self, n)
    def __eq__(self, other): return _compare (self, other)
    def __ne__(self, other): return not _compare (self, other)
    def __hash__(self): return id(self) 
    def copy (self):
        c = self.__class__()
        c.__dict__.update (self.__dict__)
        return c
    def new (self):
        c = self.__class__()
        c.__init__ ([None]*len(self.__cols__), self.__cols__)
        return c

def _p (o):
        if isinstance (o, (int,long,str,unicode,bool,type(None))):
            return repr(o)
        if isinstance (o, (datetime.datetime, datetime.date, datetime.time)):
            return str(o)
        if isinstance (o, list):
            if len(o) == 0: return "[]"
            else: return "[...]"
        if isinstance (o, dict):
            if len(o) == 0: return "{}"
            else: return "{...}"
        else: return repr (o)

class _Nothing: pass
def _compare (self, other):
        try: attrs = set (list(self.__dict__.keys()) + list(other.__dict__.keys()))
        except AttributeError: return False
        for a in attrs:
            s = getattr (self, a, _Nothing)
            o = getattr (other, a, _Nothing)
            if s is _Nothing: return False
            if o is _Nothing: return False
            if s != o: return False
        return True


class Entr (DbRow):
    def __init__ (s, id=None, src=None, stat=None, seq=None, dfrm=None,
                     unap=None, srcnote=None, notes=None,
                     _kanj=None, _rdng=None, _sens=None, _hist=None,
                     _snd=None, _grp=None, _cinf=None):
        DbRow.__init__(s, ( id,  src,  stat,  seq,  dfrm,  unap,  srcnote,  notes),
                          ('id','src','stat','seq','dfrm','unap','srcnote','notes'))
        s._kanj = _kanj or []
        s._rdng = _rdng or []
        s._sens = _sens or []
        s._hist = _hist or []
        s._snd  = _snd  or []
        s._grp  = _grp  or []
        s._cinf = _cinf or []

class Rdng (DbRow):
    def __init__ (s, entr=None, rdng=None, txt=None,
                     _inf=None, _freq=None, _restr=None, _stagr=None, _snd=None):
        DbRow.__init__(s, ( entr,  rdng,  txt),
                          ('entr','rdng','txt'))
        s._inf   = _inf   or []
        s._freq  = _freq  or []
        s._restr = _restr or []
        s._stagr = _stagr or []
        s._snd   = _snd   or []

class Kanj (DbRow):
    def __init__ (s, entr=None, kanj=None, txt=None,
                     _inf=None, _freq=None, _restr=None, _stagk=None):
        DbRow.__init__(s, ( entr,  kanj,  txt),
                          ('entr','kanj','txt'))
        s._inf   = _inf   or []
        s._freq  = _freq  or []
        s._restr = _restr or []
        s._stagk = _stagk or []

class Sens (DbRow):
    def __init__ (s, entr=None, sens=None, notes=None,
                     _gloss=None, _pos=None, _misc=None, _fld=None,
                     _dial=None, _lsrc=None, _stagr=None, _stagk=None,
                     _xref=None, _xrer=None, _xrslv=None):
        DbRow.__init__(s,  (entr,  sens,  notes),
                          ('entr','sens','notes'))
        s._gloss = _gloss or []
        s._pos   = _pos   or []
        s._misc  = _misc  or []
        s._fld   = _fld   or []
        s._dial  = _dial  or []
        s._lsrc  = _lsrc  or []
        s._stagr = _stagr or []
        s._stagk = _stagk or []
        s._xref  = _xref  or []
        s._xrer  = _xrer  or []
        s._xrslv = _xrslv or []

class Gloss (DbRow):
    def __init__ (s, entr=None, sens=None, gloss=None, lang=None, ginf=None, txt=None):
        DbRow.__init__(s, ( entr,  sens,  gloss,  lang,  ginf,  txt),
                          ('entr','sens','gloss','lang','ginf','txt'))

class Rinf (DbRow):
    def __init__ (s, entr=None, rdng=None, ord=None, kw=None):
        DbRow.__init__(s, ( entr,  rdng,  ord,  kw),
                          ('entr','rdng','ord','kw'))

class Kinf (DbRow):
    def __init__ (s, entr=None, kanj=None, ord=None, kw=None):
        DbRow.__init__(s, ( entr,  kanj,  ord,  kw),
                          ('entr','kanj','ord','kw'))

class Freq (DbRow):
    def __init__ (s, entr=None, rdng=None, kanj=None, kw=None, value=None):
        DbRow.__init__(s, ( entr,  rdng,  kanj,  kw,  value),
                          ('entr','rdng','kanj','kw','value'))

class Restr (DbRow):
    def __init__ (s, entr=None, rdng=None, kanj=None, sens=None):
        DbRow.__init__(s, ( entr,  rdng,  kanj),
                          ('entr','rdng','kanj'))

class Stagr (DbRow):
    def __init__ (s, entr=None, sens=None, rdng=None):
        DbRow.__init__(s, ( entr,  sens,  rdng),
                          ('entr','sens','rdng'))

class Stagk (DbRow):
    def __init__ (s, entr=None, sens=None, kanj=None):
        DbRow.__init__(s, ( entr,  sens,  kanj),
                          ('entr','sens','kanj'))

class Pos (DbRow):
    def __init__ (s, entr=None, sens=None, ord=None, kw=None):
        DbRow.__init__(s, ( entr,  sens,  ord,  kw),
                          ('entr','sens','ord','kw'))

class Misc (DbRow):
    def __init__ (s, entr=None, sens=None, ord=None, kw=None):
        DbRow.__init__(s, ( entr,  sens,  ord,  kw),
                          ('entr','sens','ord','kw'))

class Fld (DbRow):
    def __init__ (s, entr=None, sens=None, ord=None, kw=None):
        DbRow.__init__(s, ( entr,  sens,  ord,  kw),
                          ('entr','sens','ord','kw'))

class Dial (DbRow):
    def __init__ (s, entr=None, sens=None, ord=None, kw=None):
        DbRow.__init__(s, ( entr,  sens,  ord,  kw),
                          ('entr','sens','ord','kw'))

class Lsrc (DbRow):
    def __init__ (s, entr=None, sens=None, ord=None, lang=1, txt=None, part=False, wasei=False):
        DbRow.__init__(s, ( entr,  sens,  ord,  lang,  txt,  part,  wasei),
                          ('entr','sens','ord','lang','txt','part','wasei'))

class Xref (DbRow):
    def __init__ (s, entr=None, sens=None, xref=None, typ=None, xentr=None, xsens=None,
                  rdng=None, kanj=None, notes=None):
        DbRow.__init__(s, ( entr,  sens,  xref,  typ,  xentr,  xsens,  rdng,  kanj,  notes),
                          ('entr','sens','xref','typ','xentr','xsens','rdng','kanj','notes'))

class Hist (DbRow):
    def __init__ (s, entr=None, hist=None, stat=None, userid=None, dt=None, name=None,
                  email=None, diff=None, refs=None, notes=None):
        DbRow.__init__(s, ( entr,  hist,  stat,  userid,  dt,  name,  email,  diff,  refs,  notes),
                          ('entr','hist','stat','userid','dt','name','email','diff','refs','notes'))

class Grp (DbRow):
    def __init__ (s, entr=None, kw=None, ord=None, notes=None):
        DbRow.__init__(s, ( entr,  kw,  ord,  notes),
                          ('entr','kw','ord','notes'))

class Cinf (DbRow):
    def __init__ (s, entr=None, kw=None, value=None, mctype=None):
        DbRow.__init__(s, ( entr,  kw,  value,  mctype),
                          ('entr','kw','value','mctype'))

class Chr (DbRow):
    def __init__ (s, entr=None, uni=None, bushu=None, strokes=None,
                  freq=None, grade=None, jlpt=None):
        DbRow.__init__(s, ( entr,  uni,  bushu,  strokes,  freq,  grade,  jlpt),
                          ('entr','uni','bushu','strokes','freq','grade','jlpt'))

class Xrslv (DbRow):
    def __init__ (s, entr=None, sens=None, ord=None, typ=None,
                  rtxt=None, ktxt=None, tsens=None, notes=None, prio=None):
        DbRow.__init__(s, ( entr,  sens,  ord,  typ,  rtxt,  ktxt,  tsens,  notes,  prio),
                          ('entr','sens','ord','typ','rtxt','ktxt','tsens','notes','prio'))

class Kreslv (DbRow):
    def __init__ (s, entr=None, kw=None, value=None):
        DbRow.__init__(s, ( entr,  kw,  value),
                          ('entr','kw','value'))

class Entrsnd (DbRow):
    def __init__ (s, entr=None, ord=None, snd=None):
        DbRow.__init__(s, ( entr,  ord,  snd),
                          ('entr','ord','snd'))

class Rdngsnd (DbRow):
    def __init__ (s, entr=None, rdng=None, ord=None, snd=None):
        DbRow.__init__(s, ( entr,  rdng,  ord,  snd),
                          ('entr','rdng','ord','snd'))

class Snd (DbRow):
    def __init__ (s, id=None, file=None, strt=None, leng=None, trns=None, notes=None):
        DbRow.__init__(s, ( id,  file,  strt,  leng,  trns,  notes),
                          ('id','file','strt','leng','trns','notes'))

class Sndfile (DbRow):
    def __init__ (s, id=None, vol=None, title=None, loc=None, type=None, notes=None):
        DbRow.__init__(s, ( id,  vol,  title,  loc,  type,  notes),
                          ('id','vol','title','loc','type','notes'))

class Sndvol (DbRow):
    def __init__ (s, id=None, title=None, loc=None, type=None, idstr=None, corp=None, notes=None):
        DbRow.__init__(s, ( id,  title,  loc,  type,  idstr,  corp,  notes),
                          ('id','title','loc','type','idstr','corp','notes'))
