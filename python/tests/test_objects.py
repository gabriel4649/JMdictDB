# -*- coding: utf-8 -*-

import sys, re, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb
from objects import *

def globalSetup (): pass

class Test_DbRow (unittest.TestCase):
    def test000010(_): _.assertIs (type (DbRow()), DbRow)
    def test000020(_): _.assertEqual (len (DbRow([],[])), 0)
    def test000030(_): _.assertEqual (len (DbRow([0],['a'])), 1)
    def test000040(_): _.assertEqual (len (DbRow([10,11,12],['a','b','c'])), 3)
    def test000050(_): _.assertEqual (len (DbRow({})), 0)
    def test000060(_): _.assertEqual (len (DbRow({'a':0})), 1)
    def test000070(_): _.assertEqual (len (DbRow({'a':0,'b':1,'c':2})), 3)
    def test000080(_): _.assertEqual ([x for x in DbRow([20,21,22],['a','b','c'])], [20,21,22])
      # Following test is bogus because it depends on the iteration order
      # of the dict argument when it is evaluated by DbRow.__init__().
    #def test000090(_): _.assertEqual ([x for x in DbRow({'a':20,'c':21,'b':22})], [20,21,22])
    def test000210(_): _.assertEqual (DbRow([20,21,22],['a','b','c']).a, 20)
    def test000220(_): _.assertEqual (DbRow([20,21,22],['a','b','c']).b, 21)
    def test000230(_): _.assertEqual (DbRow([20,21,22],['a','b','c']).c, 22)
    def test000240(_): _.assertEqual (DbRow([20,21,22],['a','b','c'])[0], 20)
    def test000250(_): _.assertEqual (DbRow([20,21,22],['a','b','c'])[1], 21)
    def test000260(_): _.assertEqual (DbRow([20,21,22],['a','b','c'])[2], 22)

class Test_DbRow_compare (unittest.TestCase):
    def test000010(_):
        e1 = DbRow(); e2 = DbRow()
        _.assertEqual (e1, e2)
    def test000020(_):
        e1 = DbRow ([33],['id']); e2 = DbRow ([33],['id'])
        _.assertEqual (e1, e2)
    def test000030(_):
        e1 = DbRow ([33],['id']); e2 = DbRow ()
        _.assertNotEqual (e1, e2)
    def test000040(_):
        e1 = DbRow (); e2 = DbRow ([33],['id'])
        _.assertNotEqual (e1, e2)
    def test000050(_):
        e1 = DbRow ([33],['id']); e2 = DbRow ([32],['id'])
        _.assertNotEqual (e1, e2)
    def test000060(_):
        e1 = DbRow ([33],['id']); e2 = DbRow ([33],['ie'])
        _.assertNotEqual (e1, e2)
    def test000070(_):
        e1 = DbRow ([''],['id']); e2 = DbRow ([''],['id'])
        _.assertEqual (e1, e2)
    def test000080(_):
        e1 = DbRow ([''],['id']); e2 = DbRow ([0],['id'])
        _.assertNotEqual (e1, e2)
    def test000090(_):
        e1 = DbRow ([33,''],['id','val']); e2 = DbRow ([33,''],['id','val'])
        _.assertEqual (e1, e2)
    def test000100(_):
        e1 = DbRow ([33,''],['id','val']); e2 = DbRow ([34,''],['id','val'])
        _.assertNotEqual (e1, e2)
    def test000110(_):
        e1 = DbRow ([33,''],['id','val']); e2 = DbRow ([33,'a'],['id','val'])
        _.assertNotEqual (e1, e2)
    def test000120(_):
        e1 = DbRow ([33,''],['id','val']); e2 = DbRow ([33,''],['idx','val'])
        _.assertNotEqual (e1, e2)
    def test000130(_):
        e1 = DbRow ([33,''],['id','val']); e2 = DbRow ([33,''],['id','valx'])
        _.assertNotEqual (e1, e2)
    def test000140(_):
        e1 = DbRow ([33,''],['id','val']); e2 = DbRow ([34],['id'])
        _.assertNotEqual (e1, e2)
    def test000150(_):
        e1 = DbRow ([33,''],['id','val']); e2 = DbRow ([''],['val'])
        _.assertNotEqual (e1, e2)

    def test000410(_):
        e1 = DbRow ([[1,2,3,4]],['list']); e2 = DbRow ([[1,2,3,4]],['list'])
        _.assertEqual (e1, e2)
    def test000420(_):
        e1 = DbRow ([[1,2],{'a':4,'b':set((4.7,'u\3000\u3042'))}],['list','dict'])
        e2 = DbRow ([[1,2],{'a':4,'b':set(('u\3000\u3042',4.7))}],['list','dict'])
        _.assertEqual (e1, e2)
    def test000430(_):
        e1 = DbRow ([[1,2],{'a':4,'b':set((4.7,'u\3000\u3042'))}],['list','dict'])
        e2 = DbRow ([[1,2],{'a':4,'b':set(('u\3000\u3042',4.8))}],['list','dict'])
        _.assertNotEqual (e1, e2)

class Test_Attrs (unittest.TestCase):
    # Check the jmdictdb objects for the expected attribute sets.
    def test000010(_): attrchk (_, Entr(),    ['id','src','stat','seq','dfrm','unap','srcnote','notes',
                                               '_kanj','_rdng','_sens','_hist','_snd','_grp','chr','_krslv'])
    def test000020(_): attrchk (_, Rdng(),    ['entr','rdng','txt',
                                               '_inf','_freq','_restr','_stagr','_snd'])
    def test000030(_): attrchk (_, Kanj(),    ['entr','kanj','txt',
                                               '_inf','_freq','_restr','_stagk'])
    def test000040(_): attrchk (_, Sens(),    ['entr','sens','notes','_gloss','_pos','_misc','_fld','_dial',
                                               '_lsrc','_stagr','_stagk','_xref','_xrer','_xrslv'])
    def test000050(_): attrchk (_, Gloss(),   ['entr','sens','gloss','lang','ginf','txt'])
    def test000060(_): attrchk (_, Rinf(),    ['entr','rdng','ord','kw'])
    def test000070(_): attrchk (_, Kinf(),    ['entr','kanj','ord','kw'])
    def test000080(_): attrchk (_, Freq(),    ['entr','rdng','kanj','kw','value'])
    def test000090(_): attrchk (_, Restr(),   ['entr','rdng','kanj'])
    def test000100(_): attrchk (_, Stagr(),   ['entr','sens','rdng'])
    def test000110(_): attrchk (_, Stagk(),   ['entr','sens','kanj'])
    def test000120(_): attrchk (_, Pos(),     ['entr','sens','ord','kw'])
    def test000130(_): attrchk (_, Misc(),    ['entr','sens','ord','kw'])
    def test000140(_): attrchk (_, Fld(),     ['entr','sens','ord','kw'])
    def test000150(_): attrchk (_, Dial(),    ['entr','sens','ord','kw'])
    def test000160(_): attrchk (_, Lsrc(),    ['entr','sens','ord','lang','txt','part','wasei'])
    def test000170(_): attrchk (_, Xref(),    ['entr','sens','xref','typ','xentr','xsens','rdng','kanj','notes'])
    def test000180(_): attrchk (_, Hist(),    ['entr','hist','stat','unap','dt','userid','name','email','diff','refs','notes'])
    def test000190(_): attrchk (_, Grp(),     ['entr','kw','ord','notes'])
    def test000200(_): attrchk (_, Cinf(),    ['entr','kw','value','mctype'])
    def test000210(_): attrchk (_, Chr(),     ['entr','chr','bushu','strokes','freq','grade','jlpt','_cinf'])
    def test000220(_): attrchk (_, Xrslv(),   ['entr','sens','ord','typ','rtxt','ktxt','tsens','notes','prio'])
    def test000230(_): attrchk (_, Kreslv(),  ['entr','kw','value'])
    def test000240(_): attrchk (_, Entrsnd(), ['entr','ord','snd'])
    def test000250(_): attrchk (_, Rdngsnd(), ['entr','rdng','ord','snd'])
    def test000260(_): attrchk (_, Snd(),     ['id','file','strt','leng','trns','notes'])
    def test000270(_): attrchk (_, Sndfile(), ['id','vol','title','loc','type','notes'])
    def test000280(_): attrchk (_, Sndvol(),  ['id','title','loc','type','idstr','corp','notes'])

def attrchk (_, o, exp_attrs):
          # Check that all the attribute names in list 'exp_attrs' exist
          # in object 'o', and that 'o' has no other attributes exist (except
          # that attributes starting with "__" are ignored).  Also check that
          # any attributes starting with "_" (but not "__") are lists.

        o_attrs = set ((a for a in dir (o) if not a.startswith('__')))
        o_attrs -= set (('new','copy'))         # Attributes from DbRow base class.
        _.assertEqual (o_attrs, set (exp_attrs))
        for attr in [a for a in dir (o) if a.startswith ('_')
                                           and not a.startswith ('__')]:
            _.assertIsInstance (getattr (o, attr), list)

if __name__ == '__main__': unittest.main()





