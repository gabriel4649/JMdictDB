"""
This module defines a set of classes corresponding 
to the tables in the JB database.  These classes are
instanciated for each row of the corresponding 
table.  Properties of the tables (e.g. the names 
of the table's columns) are defined by setting
class variables.  See the docstring in tables.DbRow.
"""

from jbdb import DbRow

class Entr (DbRow):
    _table = "entr"
    _cols = ["id","src","seq","note"]
    _related = ["kanj","read","sens","lang","dial","audit"]
    _auto = "id"

class Kanj (DbRow):
    _table = "kanj"
    _cols = ["id","entr","ord","txt"]
    _related = ["inf","freq"]
    _auto = "id"
    _parent = "entr"
    _ord = "ord"

class Read (DbRow):
    _table = "kana"
    _cols = ["id","entr","ord","txt"]
    _related = ["inf","freq"]
    _auto = "id"
    _parent = "entr"
    _ord = "ord"

class Sens (DbRow):
    _table = "sens"
    _cols = ["id","entr","ord","note"]
    _related = ["gloss","xref","pos","misc","fld"]
    _auto = "id"
    _parent = "entr"
    _ord = "ord"

class Gloss (DbRow):
    _table = "gloss"
    _cols = ["id","sens","ord","lang","txt","note"]
    _auto = "id"
    _parent = "sens"
    _ord = "ord"

class Xref (DbRow):
    _table = "xref"
    _cols = ["sens","xref","typ","note"]
    _parent = "sens"

class Audit (DbRow):
    _table = "audit"
    _cols = ["id","entr","typ","dt","who","note"]
    _auto = "id"
    _parent = "entr"

class Kfreq (DbRow):
    _table = "kfreq"
    _cols = ["kanj","kw","value"]
    _parent = "kanj"
class Rfreq (DbRow):
    _table = "rfreq"
    _cols = ["kana","kw","value"]
    _parent = "kana"
class Kinf (DbRow):
    _table = "kinf"
    _cols = ["kanj","kw"]
    _parent = "kanj"
class Rinf (DbRow):
    _table = "rinf"
    _cols = ["kana","kw"]
    _parent = "kana"
class Pos (DbRow):
    _table = "pos"
    _cols = ["sens","kw"]
    _parent = "sens"
class Misc (DbRow):
    _table = "misc"
    _cols = ["sens", "kw"]
    _parent = "sens"
class Dial (DbRow):
    _table = "dial"
    _cols = ["entr", "kw"]
    _parent = "entr"
class Fld (DbRow):
    _table = "fld"
    _cols = ["sens", "kw"]
    _parent = "sens"
class Lang (DbRow):
    _table = "lang"
    _cols = ["entr", "kw"]
    _parent = "entr"

class KwAudit (DbRow):
    _table = "kwAudit"
    _cols = ["id","kw","descr"]
class KwDial (DbRow):
    _table = "kwDial"
    _cols = ["id","kw","descr"]
class KwFreq (DbRow):
    _table = "kwFreq"
    _cols = ["id","kw","descr"]
class KwFld (DbRow):
    _table = "kwFld"
    _cols = ["id","kw","descr"]
class KwKinf (DbRow):
    _table = "kwKinf"
    _cols = ["id","kw","descr"]
class KwLang (DbRow):
    _table = "kwLang"
    _cols = ["id","kw","descr"]
class KwMisc (DbRow):
    _table = "kwMisc"
    _cols = ["id","kw","descr"]
class KwPos (DbRow):
    _table = "kwPos"
    _cols = ["id","kw","descr"]
class KwRinf (DbRow):
    _table = "kwRinf"
    _cols = ["id","kw","descr"]
class KwSrc (DbRow):
    _table = "kwSrc"
    _cols = ["id","kw","descr"]
class KwXref (DbRow):
    _table = "kwXref"
    _cols = ["id","kw","descr"]

class Restr (DbRow):
    _table = "restr"
    _cols = ["kana","kanj"]
    _useid = ["kana","kanj"]
class Stagr (DbRow):
    _table = "stagr"
    _cols = ["sens","kana"]
    _useid = ["sens","kana"]
class Stagk (DbRow):
    _table = "stagk"
    _cols = ["sens","kanj"]
    _useid = ["sens","kanj"]

