#######################################################################
#  This file is part of JMdictDB.
#  Copyright (c) 2008 Stuart McGraw
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
               '$Date$'[7:-11]);

import zlib, base64, urllib.request, urllib.parse, urllib.error, datetime, time
try: import json
except ImportError: import simplejson as json
import jdb

def serialize (obj):
        s = jencode (obj)
        s = zlib.compress (s)
        s = base64.b64encode (s)
        s = urllib.parse.quote_plus (s)
        return s

def unserialize (str):
        s = urllib.parse.unquote_plus (str)
        s = base64.b64decode (s)
        s = zlib.decompress (s)
        obj = jdecode (s)
        return obj

def jencode (obj):
        r = obj2struc (obj)
        jstr = json.dumps (r)
        return jstr

def jdecode (jstr):
        r = json.loads (jstr)
        o = struc2obj (r)
        return o

# The following two functions convert certain Python objects
# to and from a description format that consists solely of
# data types supported by JSON.  This allows those certain
# objects to be converted to this description format, JSON
# encoded, transmitted to a receiving process, JSON deccoded,
# and finally deconverted to get a reconstructed object that
# matches the original.
#
# The description format can represent and correctly restore
# objects that have shared or cyclical references.
#
# It supports the following object types:
#  scalar: int, float, boolean, None, str[1], unicode
#  container: list
#  object: jdb.DbRow, jdb.Obj
#
# Representation format
# A python object is represented by itself, if it is of one
# of the scalar types mention above.  If not, it is represented
# by a 1-, 2-, or 3-item list.
#
#  1. [idn]
#  2. [typ, val]
#  3. [idn, typ, val]
#
# where 'idn' is an integer "object number", 'typ' is a string
# giving the object's type (e.g. "list", or "DbRow") and 'val'
# is a representation of the object's value.  For a list, it is
# a list of the obj2struc representations on each list item.
# For other supported objects, it is a dict where each key is
# a string naming one of the object's attributes, and each value
# is the obj2struc representation of the attribute's value.
#
# For the 1-item list case, 'isn' is the object number of an
# object represented earlier in the representation with a 3-item
# form having the same 'idn' number.  This is how cyclic and
# shared referenced are represented.
#
# Example:
#
# >>> a = [4, 5, [None, 6]]
# >>> a[2][0] = a
# >>> a
# [4, 5, [[...], 6]]
# >>> x = obj2struc (a)
# >>> print x
# [1, 'list', [4, 5, ['list', [[1], 6]]]]
# >>> print struc2obj (x)
# [4, 5, [[...], 6]]
#

Serializable_classes = (
  'Obj', 'DbRow',
  'Chr', 'Cinf', 'Dial', 'Entr', 'Entrsnd', 'Fld', 'Freq', 'Gloss', 'Hist',
  'Kanj', 'Kinf', 'Kreslv', 'Lsrc', 'Misc', 'Pos', 'Rdng', 'Restr', 'Rinf',
  'Rdngsnd', 'Sens', 'Stagk', 'Stagr', 'Xref', 'Xrslv', 'Grp')

def obj2struc (o, seen=None):

        if seen is None:

              # If seen is None, this is a top-level (i.e. not
              # a recursive) call.
              #
              # 'seen' is used to record the id() of every
              # object precessed so that we can tell when we
              # see the same object a second of more times.
              # The dict key is the id() number and the value
              # a list of references to the desc's the represent
              # the object.  The first desc in the list will
              # be of the form [typ, val], and following ones
              # of the form [None].  Before returning (at the
              # top-level) the desc's will have 'idn's inserted.

            seen = dict()
            toplevel = True

        else: toplevel = False

          # Get the object's id() value and string naming its type.

        idn = id(o); typ = type(o).__name__
        if typ == 'instance': typ = o.__class__.__name__

        if typ in (('list', 'tuple', 'datetime') + Serializable_classes):

              # These are complex types not directly representable
              # in JSON, or which may have references to them.
              # We convert each into a 1- or 2-item list called a
              # descriptor.

            if idn in seen:

                  # If 'idn' is a key in seen we've seen this object
                  # before and henceforth will be represented with a
                  # descriptor of the form ['idn'], where 'idn' is the
                  # object number used for the object in it's first
                  # occuring representation.  We will supply the actual
                  # 'idn' value later so for now use a placeholder [None].
                  # (The id() value is too long to use and would bloat
                  # the representation when it's serialized.)

                desc = [None]

                  # Append this descriptor to the seen object list
                  # so we can find it later, in order to replace the
                  # None.

                seen[idn].append (desc)

            else:

                  # This object has not been seen before...
                  # Create an empty descriptor (list) for it, and use it
                  # to start a list in 'seen', keyed by this object's id()
                  # number.  Note that we have to create the descriptor
                  # before processing the object value because the latter
                  # could contain references to this object which will
                  # require the descriptor to be registered in 'seen'.

                desc = []
                seen[idn] = [desc]
                if typ in ('list', 'tuple'):

                      # If object is a seq, the representation of its
                      # value is a list of the representation of each
                      # of it items.

                    val = [obj2struc(v,seen) for v in o]

                elif typ == 'datetime':
                    val = o.isoformat (' ')

                else:
                      # If object is one of the supported objects
                      # its representation in a dictionary with the
                      # keys naming the object's attributes, and its
                      # values the representation of the object's
                      # attribute values.  We have to process the
                      # attributes in a deterministic order because
                      # if the objects they reference are referenced
                      # elsewhere, we have to assure that the same
                      # reference will be seen first during restore
                      # in struc2obj as was seen first here, since
                      # the first reference carries the idn tag.

                    val = dict([(a,obj2struc(v,seen))
                                for a,v in sorted (o.__dict__.items())])

                  # Now we can fill out the empty desc list created above
                  # with the actual type and value.

                desc.extend ([typ, val])

        elif typ in ('str', 'unicode', 'int', 'long', 'float', 'bool', 'NoneType'):

              # Basic scalar types that are directly representable in JSON
              # and to which we don't expect (or don't support) mutiple or
              # cyclic references.

            desc = o

        else:
              # Any other types are not supported.

            raise ValueError ("Unsupported type: %s" % str(type(o)))

          # Go through the representation and add 'idn' values where needed.

        if toplevel:
            xid = 0
            for idn,refs in list(seen.items()):

                  # 'idn' here is the id() number of an object.
                  # 'refs' is a list, with the first item being the
                  # descriptor of the form [typ, val] for the first
                  # occurance of the object, and subsequence items
                  # (if any) are references to the object of the form
                  # [None].  We need to change the first item to the
                  # form [idn, typ, val] and following items to form
                  # [idn].  ('idn' here is just a small unique number
                  # not a id() number.)

                  # If the list len is 1, there are no refernces to
                  # this object so we need not do anything, the descriptor
                  # is fine as it stands.

                if len(refs) <= 1: continue

                  # Separate the first descriptor and remaining reference
                  # descriptors.

                first = refs.pop(0)

                  # Generate a new 'idn' number.

                xid += 1

                  # Change the first descriptor from [typ, val] to
                  # [idn, typ, val].

                first.insert (0, xid)
                for descx in refs:

                      # For each of the reference descriptors, change
                      # from [None] to [idn].

                    descx[0] = xid

        return desc


def struc2obj (desc, seen=None):
          # Convert a JSON'able structure into an object.

          # 'Seen' is used to restore cyclic and shared references.
        if seen is None: seen = dict()

          # Simple scalars are represented by themselves in the descriptor
          # structure.
        if type(desc) is not list: o = desc

          # Otherwise, a list is a descriptor.
        else:
              # This is an object descriptor.
              # It is either [id, typ, val], [typ, val], or [id].
            idn = typ = None
            if   len (desc) == 1: (idn,) = desc
            elif len (desc) == 2: (typ, val) = desc
            elif len (desc) == 3: (idn, typ, val) = desc
            else: raise ValueError ("Expected length 1, 2, or 3 list")

            if idn and type(idn) is not int:
                raise ValueError ("Id value '%s' is not an int" % idn)

            if not typ:
                  # If no 'typ' value, this descriptor is of the form
                  # [idn] and is a reference to a previously seen object.
                  # We expect the find the object in the 'seen' registry.
                try: o = seen[idn]
                except KeyError: raise ValueError ("Id value '%s' not found" % idn)
            else:
                  # Process a descriptor based on its 'typ'...
                  # In each case below, before we reconstruct the object's
                  # value, we need (is there is an 'idn' value) make and
                  # empty intance of the object and register it in 'seen'
                  # so than any values that refer to it can do so.
                  # FIXME: Need to do this in better more general way.

                if typ == 'list':
                    o = list()
                    if idn: seen[idn] = o
                    o.extend ([struc2obj(v,seen) for v in val])
                elif typ == 'tuple':
                      # FIXME: tuple immutable so we can't create empty
                      # instance first to register with 'seen' and add
                      # values after.
                    o = tuple([struc2obj(v,seen) for v in val])
                    if idn: seen[idn] = o
                elif typ in Serializable_classes:
                    cls = getattr (jdb, typ)
                    o = cls()
                    if idn: seen[idn] = o
                    for a,v in sorted(val.items()):
                        setattr (o, a, struc2obj(v,seen))
                elif typ == 'datetime':
                    o = isoformat2datetime (val)
                else:
                    raise ValueError ("Unknown type: %s" % typ)
        return o

def isoformat2datetime (isoformat):
          # FIXME: handle microsecs and timezone
        s = isoformat.replace ('T', ' ')
        ts = time.strptime (s, "%Y-%m-%d %H:%M:%S")
        v = datetime.datetime(*ts[:6])
        return v

# The following two functions serialize and de-serialize
# jmcgi.SearchItems objects.

def so2js (obj):
        # Convert a SearchItems object to a structure serializable
        # by json.  This is a temporary hack and should be generalized
        # later, possibly by generalizing serialize.obj2struct().

        js = obj.__dict__.copy()
        if  hasattr (obj, 'txts'):
            txts = [x.__dict__.copy() for x in obj.txts]
            if txts: js['txts'] = txts
        soj = json.dumps (js)
        return soj

def js2so (soj):
        # Convert a json-serialized SearchItems object back to an
        # object.  For convenience, we don't restore it to a SearchItem
        # but to an Obj.  SearchItem's purpose is to prevent adding
        # unexpected attributes, something we don't have to worry about
        # here since we're receiving one that was already checked.
        # 'soj' is a serialized SearchItems object to be restored.

        js = json.loads (soj)
        obj = jdb.Obj()
        obj.__dict__ = js
        sis = []
        for si in js.get ('txts', []):
            o = jdb.Obj()
            o.__dict__ = si
            sis.append (o)
        if sis: obj.txts = sis
        return obj
