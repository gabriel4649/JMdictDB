# -*- coding: utf-8 -*-
import sys, unittest, itertools, pdb
from copy import deepcopy
if '../lib' not in sys.path: sys.path.append ('../lib')
from objects import *
import jdb

class Test_jdb_copy_freqs (unittest.TestCase):
    def setUp(_):
          # Create some freq objects for use in tests.
        _.ichi1  = Freq (kw=1, value=1)
        _.ichi2  = Freq (kw=1, value=2)
        _.gai1   = Freq (kw=2, value=1)
        _.nf17   = Freq (kw=5, value=17)
        _.nf16   = Freq (kw=5, value=16)
        _.ichi2a = Freq (kw=1, value=2)

    def test_0010(_):
          # No rdng or kanj.
        p, e = Entr(), Entr()
        jdb.copy_freqs (p, e)
        _.assertEqual ([], e._rdng)	
        _.assertEqual ([], e._kanj)	
    def test_0020(_):
          # No kanj.
        p = Entr(_rdng=[Rdng(u'よい')])
        e = deepcopy (p)
        jdb.copy_freqs (p, e)
        _.assertEqual ([], e._rdng[0]._freq)	
    def test_0030(_):
          # No rdng.
        p = Entr (_kanj=[Kanj(u'良い')])
        e = deepcopy (p)
        jdb.copy_freqs (p, e)
        _.assertEqual ([], e._kanj[0]._freq)
    def test_0040(_):
          # Test existing freq removal
        p = Entr(_rdng=[Rdng(txt=u'よ')], _kanj=[Kanj(txt=u'良')])
        e = deepcopy (p)
        e._rdng[0]._freq = [_.ichi2]
        e._kanj[0]._freq = [_.gai1]
        jdb.copy_freqs (p, e)
        _.assertEqual ([], e._rdng[0]._freq)
        _.assertEqual ([], e._kanj[0]._freq)

    def test_0110(_):
          # Single shared freq on 1 kanj and 1 rdng.
        p = Entr(_rdng=[Rdng(txt=u'よ')], _kanj=[Kanj(txt=u'良')])
        e = deepcopy (p)
          # Note that we must use the same (as in 'is', not as in '==')
          # Freq object in the two freq lists, the lists themselves must
          # be distinct objects to accurately represent how things work
          # in the jmdictdb software.  
        p._rdng[0]._freq = [_.ichi2]
        p._kanj[0]._freq = [_.ichi2]
        jdb.copy_freqs (p, e)
        _.assertFreqOnLists (_.ichi2,  e._rdng[0], e._kanj[0])
        _.assertEqual (1, len(e._rdng[0]._freq))
        _.assertEqual (1, len(e._kanj[0]._freq))

    def test_0120(_):
          # Rdng only freq
        p = Entr(_rdng=[Rdng(txt=u'よ')], _kanj=[Kanj(txt=u'良')])
        e = deepcopy (p)
        p._rdng[0]._freq = [_.ichi2]
        jdb.copy_freqs (p, e)
        _.assertFreqOnLists (_.ichi2,  e._rdng[0])
        _.assertEqual (1, len(e._rdng[0]._freq))
        _.assertEqual (0, len(e._kanj[0]._freq))
 
    def test_0130(_):
          # Kanj only freq
        p = Entr(_rdng=[Rdng(txt=u'よ')], _kanj=[Kanj(txt=u'良')])
        e = deepcopy (p)
        p._kanj[0]._freq = [_.ichi2]
        jdb.copy_freqs (p, e)
        _.assertFreqOnLists (_.ichi2,  e._kanj[0])
        _.assertEqual (0, len(e._rdng[0]._freq))
        _.assertEqual (1, len(e._kanj[0]._freq))
 
    def test_0140(_):
          # A more complex set.
        p = Entr(_rdng=[Rdng(txt=u'の'), Rdng(txt=u'や'), Rdng(txt=u'ぬ')],
                 _kanj=[Kanj(txt=u'野'), Kanj(txt=u'埜'), Kanj(txt=u'金')])
        e = deepcopy (p)
        p._rdng[1]._freq.append (_.ichi1); p._kanj[0]._freq.append (_.ichi1)
        p._rdng[1]._freq.append (_.gai1);  p._kanj[2]._freq.append (_.gai1)
        p._rdng[2]._freq.append (_.nf16);  p._kanj[0]._freq.append (_.nf16)
        p._rdng[2]._freq.append (_.nf17);  p._kanj[2]._freq.append (_.nf17)
        p._rdng[2]._freq.append (_.ichi2)
        p._kanj[2]._freq.append (_.ichi2a)
        jdb.copy_freqs (p, e)
        _.assertFreqOnLists (_.ichi1,  e._rdng[1], e._kanj[0])
        _.assertFreqOnLists (_.gai1,   e._rdng[1], e._kanj[2])
        _.assertFreqOnLists (_.nf16,   e._rdng[2], e._kanj[0])
        _.assertFreqOnLists (_.nf17,   e._rdng[2], e._kanj[2])
        _.assertFreqOnLists (_.ichi2,  e._rdng[2], None)
        _.assertFreqOnLists (_.ichi2a, e._kanj[2], None)
        _.assertEqual (0, len (e._rdng[0]._freq))
        _.assertEqual (2, len (e._rdng[1]._freq))
        _.assertEqual (3, len (e._rdng[2]._freq))
        _.assertEqual (2, len (e._kanj[0]._freq))
        _.assertEqual (0, len (e._kanj[1]._freq))
        _.assertEqual (3, len (e._kanj[2]._freq))

    # To do: implent tests that check the duplicate elimination 
    # functionality in jdb.copy_freqs().

    # To do: implement tests that permute the reading and kanji
    # lists.

    def test_0410(_):   # IS-209
          # Setup the "from" entry like seq# 1589900.
        p = Entr(_rdng=[Rdng(txt=u'かき'),Rdng(txt=u'なつき')],
                 _kanj=[Kanj(txt=u'夏期'),Kanj(txt=u'夏季')])
        e = deepcopy (p)
        ichi1a = Freq (kw=1, value=1); ichi1b = Freq (kw=1, value=1)
        news1 = Freq (kw=7, value=1); nf13 = Freq (kw=5, value=13)
        p._rdng[0]._freq = [ichi1a, ichi1b, news1, nf13]
        p._kanj[0]._freq = [ichi1a]
        p._kanj[1]._freq = [ichi1b, news1, nf13]
          # Remove k0 from the "to" entry, which moves k1 to k0.
        del e._kanj[0]
        jdb.copy_freqs (p, e)
          # The r0/k1 freq (ichi1b) should have been moved to r0/k0.
          # The r0/k0 freq (ichi1a) should be gone with the old k0.
        _.assertFreqOnLists (ichi1b, e._rdng[0], e._kanj[0])
        _.assertFreqOnLists (news1,  e._rdng[0], e._kanj[0])
        _.assertFreqOnLists (nf13,   e._rdng[0], e._kanj[0])
        _.assertEqual (3, len (e._rdng[0]._freq))
        _.assertEqual (3, len (e._kanj[0]._freq))
        _.assertEqual (0, len (e._rdng[1]._freq))

    #================================================================
    # Support functions...

    def assertFreqOnLists (_, eqfreq, rk1, rk2=None):
        # Check that a Freq object equal to 'exfreq' is present
        # on the ._freq lists of Rdng or Kanj objects 'rk1' and 
        # 'rk2' (or just 'rk1' if 'rk2' is None).  Also check
        # that the Freq object on 'rk1' is the same object (not
        # just equal) as the object on 'rk2'
        #
        # Note that there may be more than one Freq item in a list
        # that is equal to 'eqfreq', only one of which is identical
        # to an item in the other list; consequently we have to
        # examine all pairs of items from the lists to find the 
        # right pair.  It is also possible that the Freq object 
        # may be on one of the lists more that once in which case
        # a ValueError exception is raised.
        # 
        # This function is used check that expected Freq objects
        # are present in the given Rdng/Kanj objects.  Caller should
        # also check the lengths of the ._freq lists to ensure that
        # only the checked Freq objects are present.
 
        flist1 = rk1._freq
        flist2 = rk2._freq if rk2 else None
        if flist2 is None: flist2 = [None]
        found = None
        for f1, f2 in itertools.product (flist1, flist2):
                      # Two Freq items are equal for our purpose
                      # if their .kw and .value attributes match.
                      # The other attributes don't matter. 
            if (f2 is None or f2 is f1) \
                    and (f1.kw==eqfreq.kw and f1.value==eqfreq.value):
                if found: raise ValueError ("Multiple pairs found")
                found = f1, f2
        _.assertIsNotNone (found)
            

if __name__ == '__main__': unittest.main()





