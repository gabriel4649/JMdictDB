# -*- coding: utf-8 -*-

import sys, re, copy, collections, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb, jmxml, xmlkw
from objects import *

# Module under test...
if '../../web/cgi' not in sys.path: sys.path.append ('../../web/cgi')
from edconf import realign_xrers

class Test_MockDb (unittest.TestCase):
    @classmethod
    def setUpClass (cls):
        #pdb.set_trace()
        cls.db = db = MockDb (rklookup)
        jdb.KW = db.kw
        db.addentrs ('data/edconf/realign.xml')
        db.xresolv()
    def test_00010(_):
        e = _.db.get(3000010)
        _.assertEqual (e._rdng, [Rdng(rdng=1,txt=u'さんびゃくまんじゅう'),
                                 Rdng(rdng=2,txt=u'さんびゃくまんじゅうって')])
        _.assertEqual (e._kanj, [])
        _.assertEqual (len(e._sens), 1)
        _.assertEqual (e._sens[0]._gloss, [Gloss(lang=1,ginf=1,txt='3000010')])
        _.assertEqual (e._sens[0]._xrer, [Xref(3000020,1,1,3,3000010,1,1,None,None)])
        _.assertEqual (e._sens[0]._xref, [])
    def test_00020(_):
        e = _.db.get(3000020)
        _.assertEqual (e._rdng, [Rdng(rdng=1,txt=u'さんびゃくまんにじゅう')])
        _.assertEqual (e._kanj, [])
        _.assertEqual (len(e._sens), 1)
        _.assertEqual (e._sens[0]._gloss, [Gloss(lang=1,ginf=1,txt='3000020')])
        _.assertEqual (e._sens[0]._xrer, [])
        _.assertEqual (e._sens[0]._xref, [Xref(3000020,1,1,3,3000010,1,1,None,None)])

class Test_realign (unittest.TestCase):
    @classmethod
    def setUpClass (cls):
        global SavedEntrListFunction
        cls.db = db = MockDb (rklookup)
        jdb.KW = db.kw
        db.addentrs ('data/edconf/realign.xml')
        db.xresolv()
          # Monkey patch the jdb module...
        SavedEntrListFunction = jdb.entrList
        jdb.entrList = db.entrList 
    @classmethod
    def tearDownClass (cls):
        global SavedEntrListFunction
        jdb.entrList = SavedEntrListFunction
    def getpair (_, id):
        parent = _.db.get (id)
        entr = copy.deepcopy (parent)
        for s in entr._sens: s._xrer = []
        return parent, entr

    # Xref (entr, sens, xref, typ, xentr, xsens, rdng, kanj, notes)

    def test_000010(_):
        # No change to entr
        pentr, entr = _.getpair (3000010)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [])
        _.assertEqual (entr._sens[0]._xrer, [Xref(3000020,1,1,3,3000010,1,1,None,None)])

    def test_000020(_): 
        # Swap rdng 1 and rdng 2
        pentr, entr = _.getpair (3000010)
        entr._rdng = entr._rdng[::-1]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [])
        _.assertEqual (entr._sens[0]._xrer, [Xref(3000020,1,1,3,3000010,1,2,None,None)])

    def test_000030(_): 
        # Delete rdng 1.
        pentr, entr = _.getpair (3000010)
        del entr._rdng[0]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [Xref(3000020,1,1,3,3000010,1,1,None,None)])
        _.assertEqual (entr._sens[0]._xrer, [])

    def test_000040(_):
        # No change to entr
        pentr, entr = _.getpair (3000030)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [])
        _.assertEqual (entr._sens[0]._xrer, [Xref(3000040,1,1,3,3000030,1,None,1,None)])

    def test_000050(_): 
        # Swap kanj 1 and kanj 2
        pentr, entr = _.getpair (3000030)
        entr._kanj = entr._kanj[::-1]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [])
        _.assertEqual (entr._sens[0]._xrer, [Xref(3000040,1,1,3,3000030,1,None,2,None)])

    def test_000060(_): 
        # Delete kanj 1.
        pentr, entr = _.getpair (3000030)
        del entr._kanj[0]; entr._kanj[0].kanj=1
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [Xref(3000040,1,1,3,3000030,1,None,1,None)])
        _.assertEqual (entr._sens[0]._xrer, [])

    def test_000070(_):
        # No change to entr
        pentr, entr = _.getpair (3000050)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [])
        _.assertEqual (entr._sens[0]._xrer, [Xref(3000060,1,1,3,3000050,1,1,1,None)])

    def test_000080(_):
        # Swap rdng's.
        pentr, entr = _.getpair (3000050)
        entr._rdng = entr._rdng[::-1]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [])
        _.assertEqual (entr._sens[0]._xrer, [Xref(3000060,1,1,3,3000050,1,2,1,None)])

    def test_000090(_):
        # Swap kanj's.
        pentr, entr = _.getpair (3000050)
        entr._kanj = entr._kanj[::-1]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [])
        _.assertEqual (entr._sens[0]._xrer, [Xref(3000060,1,1,3,3000050,1,1,2,None)])

    def test_000100(_):
        # Swap rdng's and kanj's.
        pentr, entr = _.getpair (3000050)
        entr._rdng = entr._rdng[::-1]
        entr._kanj = entr._kanj[::-1]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [])
        _.assertEqual (entr._sens[0]._xrer, [Xref(3000060,1,1,3,3000050,1,2,2,None)])

    def test_000110(_): 
        # Delete rdng 1.
        pentr, entr = _.getpair (3000050)
        del entr._rdng[0]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [Xref(3000060,1,1,3,3000050,1,1,1,None)])
        _.assertEqual (entr._sens[0]._xrer, [])

    def test_000120(_): 
        # Delete kanj 1.
        pentr, entr = _.getpair (3000050)
        del entr._kanj[0]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [Xref(3000060,1,1,3,3000050,1,1,1,None)])
        _.assertEqual (entr._sens[0]._xrer, [])

    def test_000130(_): 
        # Swap rdng, delete kanj 1.
        pentr, entr = _.getpair (3000050)
        entr._rdng = entr._rdng[::-1]
        del entr._kanj[0]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
          # Note that the rdng number was changed from 1 to 2 
          # because realign() processes rdng before kanj. (c.f.
          # test_000140.)
        _.assertEqual (res, [Xref(3000060,1,1,3,3000050,1,2,1,None)])
        _.assertEqual (entr._sens[0]._xrer, [])

    def test_000140(_): 
        # Swap kanj, delete rdng 1.
        pentr, entr = _.getpair (3000050)
        entr._kanj = entr._kanj[::-1]
        del entr._rdng[0]
        jdb.setkeys (entr)
        res = realign_xrers (entr, pentr)
          # Note that the kanj number was not changed from
          # 1 to 2 because realign() processes rdng before
          # kanj. (c.f. test_000130.)
        _.assertEqual (res, [Xref(3000060,1,1,3,3000050,1,1,1,None)])
        _.assertEqual (entr._sens[0]._xrer, [])

    def test_IS216(_):
        pentr, entr = _.getpair (2177620)
        res = realign_xrers (entr, pentr)
        _.assertEqual (res, [])
        _.assertEqual (entr._sens[0]._xrer, [Xref(2177650,1,1,3,2177620,1,None,2,None)])


class DuplIdError (KeyError): pass
class MultTargError (KeyError): pass
class NoTargetError (KeyError): pass
class NoSenseError (KeyError): pass

class MockDb (dict):
    # A trivial database for testing just sufficient to
    # store entries input as XML and allow lookup by id
    # number.
    def __init__ (self, lookupfunc):
        dict.__init__ (self)
        self.kw = jdb.Kwds (jdb.std_csv_dir())
        jmxml.XKW = xmlkw.make (self.kw)    # Uhgg!
        self.ridx = collections.defaultdict (set)
        self.kidx = collections.defaultdict (set)
        self.lookupfunc = lookupfunc
    def get (self, key):
        return copy.deepcopy (self[key])
    def addentr (self, xml, id=None):
          #FIXME: (or more accurately, fix jmxml) jmxml.parse_entry()
          #  returns entries with all the ordering/linking fields (e.g.,
          #  rdng.rdng, sens.sens, gloss.sens, gloss.gloss, etc) set.
          #  Convention in most jmdictdb code is to leave these set to
          #  None since they are implicitly defined by the object's
          #  position in the list that contains it.  Having them None
          #  would let us rearrange list objects for testing without 
          #  having to also reset these fields correspondingly.  
        entr = jmxml.parse_entry (xml)[0]
        entr.id = id if id else entr.seq
        if id in self: 
            raise DuplIdError ("id %d already exists in database" % id)
        self[entr.id] = entr
        for r in entr._rdng: self.ridx[r.txt].add (entr.id)
        for k in entr._kanj: self.kidx[k.txt].add (entr.id)
        return entr
    def addentrs (self, xmlfile, init_id=None, id_incr=1):
        with open (xmlfile) as f: xmltxt = f.read()
        xmlentries = (x.lstrip()+"</entry>" for x in xmltxt.split ("</entry>"))
        entr = None
        for n, xml in enumerate (xmlentries):
            if xml.startswith ("</entry>"): continue
            id = (init_id + n * id_incr) if init_id else None
            if xml: entr = self.addentr (xml, id)
        return entr.id if entr else None 
    def entrList (self, dbh, crit=None, args=None, ord='', tables=None, ret_tuple=False):
        if sql and args: raise ValueError 
        idlist = sql or args
        retlist = [self[id] for id in idlist]
        return retlist
    def xresolv (self):
        for id,e in self.items():
            for s in e._sens:
                for v in s._xrslv: self.xresolv1 (e, s, v)
    def xresolv1 (self, e, s, v):
        #FIXME: there are three xresolv functions, one here, one
        # in xresolv.py, and one in jdb.py.  Would be nice to 
        # combine them somehow.
          # 'lookupfunc' is a function that find a set of Entr's
          # that match the criteria given by the args which define
          # the targets of an xref.
        targs = self.lookupfunc (self, e.id, v.rtxt, v.ktxt)
        xrefcnt = 0
        if len (targs) == 1:
            t = self[targs.pop()]
              # If a target sense number is given in the Xrslv object,
              # verify that the sense exists in the target entry.
            if v.sens and v.tsens >= len (t._sens): raise NoSenseError (
                "id %d, xref(rdng=%r, kanj=%r): no sense #%d in target entry id=%d"
                % (e.id, v.rtxt, v.ktxt, v.tsens, t.id)) 
              # Find the indices of the reading and kanji text.
            rdng = (1 + [r.txt for r in t._rdng].index (v.rtxt)) if v.rtxt else None
            kanj = (1 + [k.txt for k in t._kanj].index (v.ktxt)) if v.ktxt else None
              # If no target sense is given in the Xrslv object, we will
              # create xrefs to every sense in the target entry.
            for n, ts in enumerate (t._sens):
                if v.tsens == n+1 or not v.tsens:
                    xrefcnt += 1
                    x = Xref (e.id, n+1, v.ord, v.typ, t.id, n+1, rdng, kanj, v.notes)
                    s._xref.append (x)
                    t._sens[n]._xrer.append (x)
        elif len (targs) < 1:
            raise NoTargetError (
                "id %d, xref(rdng=%r, kanj=%r): no target entries found"
                % (e.id, v.rtxt, v.ktxt))
        else: # len(targs) > 0:
            raise MultTargError (
                "id %d: xref(rdng=%r, kanj=%r): multiple (%d) entries found" 
                % (e.id, len (targs), v.rtxt, v.ktxt))
        return xrefcnt

def rklookup (ctx, ourid, rtxt=None, ktxt=None, seq=None, corpid=None, eid=None):
        # This function meets the interface requirements of 
        #  of (a future) general xresolve function.
        # ctx -- a MockDb instance.
        # ourid -- Entry id number to be excluded from results.
        # rtxt -- Reading text to search for
        # ktxt -- Kanji text to search for.
        # seq, corpid, eid -- Currently unimplemented and ignored.

          # ctx.ridx is a dict keyed by reading texts whose values
          # are sets of entry id numbers of entries in which that
          # reading text occurs.  ctx.kidx is analogous for kanji.
        if rtxt: rcandidates = ctx.ridx[rtxt]
        if ktxt: kcandidates = ctx.kidx[ktxt]
        if rtxt and ktxt: targs = rcandidates & kcandidates
        elif rtxt: targs = rcandidates
        elif ktxt: targs = kcandidates
        else: raise ValueError
        if ourid: targs.discard (ourid) 
          # 'targs' is a set of entry id numbers of entries that
          # have 'rtxt' readings and 'ktxt' kanji and does not 
          # include 'ourid'.
        return targs 

if __name__ == '__main__': unittest.main()





