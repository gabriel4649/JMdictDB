"""
This module defines a set of classes corresponding 
to the tables in the JB database.  These classes 
are instanciated for each row of the corresponding 
table.  Properties of the tables (e.g. the names 
of the table's columns) are defined by setting
class variables.  See the docstring in tables.DbRow.
"""
# Copyright (c) 2006, Stuart McGraw 
_VERSION_ = ("$Revision$"[11:-2], "$Date$"[7:-11])

from jbdb import DbRow

class KwAudit (DbRow):
    _table = "kwAudit"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwDial (DbRow):
    _table = "kwDial"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwFreq (DbRow):
    _table = "kwFreq"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwFld (DbRow):
    _table = "kwFld"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwKinf (DbRow):
    _table = "kwKinf"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwLang (DbRow):
    _table = "kwLang"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwMisc (DbRow):
    _table = "kwMisc"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwPos (DbRow):
    _table = "kwPos"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwRinf (DbRow):
    _table = "kwRinf"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwSrc (DbRow):
    _table = "kwSrc"
    _cols = ["id","kw","descr"]
    _pk = ["id"]
class KwXref (DbRow):
    _table = "kwXref"
    _cols = ["id","kw","descr"]
    _pk = ["id"]


class Kfreq (DbRow):
    _table = "kfreq"
    _cols = ["kanj","kw","value"]
    _pk = ["kanj","kw"]
    _parent = "kanj"
class Rfreq (DbRow):
    _table = "rfreq"
    _cols = ["kana","kw","value"]
    _pk = ["kana","kw"]
    _parent = "kana"
class Kinf (DbRow):
    _table = "kinf"
    _cols = ["kanj","kw"]
    _pk = ["kanj","kw"]
    _parent = "kanj"
class Rinf (DbRow):
    _table = "rinf"
    _cols = ["kana","kw"]
    _pk = ["kana","kw"]
    _parent = "kana"
class Pos (DbRow):
    _table = "pos"
    _cols = ["sens","kw"]
    _pk = ["sens","kw"]
    _parent = "sens"
class Misc (DbRow):
    _table = "misc"
    _cols = ["sens", "kw"]
    _pk = ["sens","kw"]
    _parent = "sens"
class Dial (DbRow):
    _table = "dial"
    _cols = ["entr", "kw"]
    _pk = ["entr","kw"]
    _parent = "entr"
class Fld (DbRow):
    _table = "fld"
    _cols = ["sens", "kw"]
    _pk = ["sens","kw"]
    _parent = "sens"
class Lang (DbRow):
    _table = "lang"
    _cols = ["entr", "kw"]
    _pk = ["entr","kw"]
    _parent = "entr"


class Restr (DbRow):
    _table = "restr"
    _cols = ["kana","kanj"]
    _pk = ["kana","kanj"]
    _parent = "kana"
class Stagr (DbRow):
    _table = "stagr"
    _cols = ["sens","kana"]
    _pk = ["sens","kana"]
    _parent = "sens"
class Stagk (DbRow):
    _table = "stagk"
    _cols = ["sens","kanj"]
    _pk = ["sens","kanj"]
    _parent = "sens"


class Xref (DbRow):
    _table = "xref"
    _cols = ["sens","xref","typ","note"]
    _pk = ["sens","xref","typ"]
    _parent = "sens"

class Audit (DbRow):
    _table = "audit"
    _cols = ["id","entr","typ","dt","who","note"]
    _pk = ["id"]
    _auto = "id"
    _parent = "entr"

class Gloss (DbRow):
    _table = "gloss"
    _cols = ["id","sens","ord","lang","txt","note"]
    _pk = ["id"]
    _auto = "id"
    _parent = "sens"
    _ord = "ord"

class Sens (DbRow):
    _table = "sens"
    _cols = ["id","entr","ord","note"]
    _pk = ["id"]
    _related = [Gloss,Xref,Pos,Misc,Fld,Stagr,Stagk]
    _auto = "id"
    _parent = "entr"
    _ord = "ord"

class Kanj (DbRow):
    _table = "kanj"
    _cols = ["id","entr","ord","txt"]
    _pk = ["id"]
    _related = [Kinf,Kfreq]
    _auto = "id"
    _parent = "entr"
    _ord = "ord"

class Kana (DbRow):
    _table = "kana"
    _cols = ["id","entr","ord","txt"]
    _pk = ["id"]
    _related = [Rinf,Rfreq,Restr]
    _auto = "id"
    _parent = "entr"
    _ord = "ord"

class Entr (DbRow):
    _table = "entr"
    _cols = ["id","src","seq","note"]
    _pk = ["id"]
    _related = [Kanj,Kana,Sens,Lang,Dial,Audit]
    _auto = "id"

