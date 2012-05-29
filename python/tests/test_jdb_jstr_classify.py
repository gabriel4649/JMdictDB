#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Tests the jdb.jstr_classify() function.

from __future__ import print_function, absolute_import, division, unicode_literals
from future_builtins import ascii, filter, hex, map, oct, zip
import sys, pdb, unittest
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb

__unittest = 1

Data = [
    # Name  Test string          Test_chars                 reb    keb    gloss
    #                            expect                     expect expect expect
    ('001', '',                  0,                         True,  True,  True,  ),
    ('002', ' ',                 jdb.LATIN,                 False, False, True,  ),
    ('003', '\n',                jdb.LATIN,                 False, False, True,  ),
    ('007', 'a',                 jdb.LATIN,                 False, False, True,  ),
    ('008', 'Z',                 jdb.LATIN,                 False, False, True,  ),
    ('009', '\x7f',              jdb.LATIN,                 False, False, True,  ),
    ('010', '\x80',              jdb.LATIN,                 False, False, True,  ),
    ('011', '\xa0',              jdb.LATIN,                 False, False, True,  ),
    ('012', '\xff',              jdb.LATIN,                 False, False, True,  ),
    ('013', u'\x01\x00',         jdb.LATIN,                 False, False, True,  ),
    ('014', u'　',               jdb.KSYM,                  False, True,  False, ),
    ('015', u'、',               jdb.KSYM,                  False, True,  False, ),
    ('016', u'。',               jdb.KSYM,                  False, True,  False, ),
    ('019', u'【',               jdb.KSYM,                  False, True,  False, ),
    ('020', u'ぁ',               jdb.KANA,                  True,  False, False, ),
    ('021', u'あ',               jdb.KANA,                  True,  False, False, ),
    ('022', u'ん',               jdb.KANA,                  True,  False, False, ),
    ('023', u'ァ',               jdb.KANA,                  True,  False, False, ),
    ('024', u'ア',               jdb.KANA,                  True,  False, False, ),
    ('025', u'ン',               jdb.KANA,                  True,  False, False, ),
    ('026', u'ー',               jdb.KANA,                  True,  False, False, ),  # U+30FB
    ('027', u'一',               jdb.KANJI,                 False, True,  False, ),  # U+4E00
    ('028', u'Α',                jdb.OTHER,                 False, True,  False, ),
    ('029', u'Ａ',               jdb.KANJI,                 False, True,  False, ),
    ('030', u'〇',               jdb.KSYM,                  False, True,  False, ),
    ('031', u'○',                jdb.OTHER,                 False, True,  False, ),
    ('032', u'α',                jdb.OTHER,                 False, True,  False, ),
    ('033', u'→',                jdb.OTHER,                 False, True,  False, ),
    ('034', u'〒',               jdb.KSYM,                  False, True,  False, ),
    ('035', u'店',               jdb.KANJI,                 False, True,  False, ),
    ('036', u'ヽ',               jdb.KANA,                  True,  False, False, ),
    ('037', u'ヾ',               jdb.KANA,                  True,  False, False, ),
    ('038', u'ゝ',               jdb.KANA,                  True,  False, False, ),
    ('039', u'ゞ',               jdb.KANA,                  True,  False, False, ),
    ('040', u'〃',               jdb.KSYM,                  False, True,  False, ),
    ('041', u'々',               jdb.KSYM,                  False, True,  False, ),
    ('042', u'〆',               jdb.KSYM,                  False, True,  False, ),
    ('043', u'３',               jdb.KANJI,                 False, True,  False, ),
    ('044', u'・',               jdb.KSYM,                  False, True,  False, ),
    ('045', u'\u301C',           jdb.KANA,                  True,  False, False, ),  # WAVE DASH
    ('046', u'\uFF5E',           jdb.KANJI,                 False, True,  False, ),  # FULLWIDTH TILDE

    ('101', u'ーパ',             jdb.KANA,                  True,  False, False, ),
    ('102', u'スーパー',         jdb.KANA,                  True,  False, False, ),
    ('103', u'会う',             jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('104', u'ＰＣエンジン',     jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('105', u'１０しん',         jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('106', u'スコップ！',       jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('107', u'２ちゃんねる',     jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('108', u'ＫＤＤＩ',         jdb.KANJI,                 False, True,  False, ),
    ('109', u'ＰＣエンジン',     jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('110', u'ｍｉｘｉ',         jdb.KANJI,                 False, True,  False, ),
    ('111', u'しろＭＩＤタワ',   jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('112', u'ＦＣ東京',         jdb.KANJI,                 False, True,  False, ),
    ('113', u'ＳＭＢＣフレンド証券', jdb.KANJI|jdb.KANA,    False, True,  False, ),
    ('114', u'あか組４',         jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('115', u'βカロチン',        jdb.KANA|jdb.OTHER,        False, True,  False, ),
    ('116', u'〆る',             jdb.KSYM|jdb.KANA,         True,  False, False, ),
    ('117', u'おげんき',         jdb.KANA,                  True,  False, False, ),
    ('118', u'お元気',           jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('119', u'会う',             jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('120', u'アンパックしんひょうきほう', jdb.KANA,        True,  False, False, ),
    ('121', u'アンパック１０しんひょうきほう', jdb.KANJI|jdb.KANA,
                                                                False, True,  False, ),
    ('122', u'インターナショナライゼーション／インターナショナリゼーション',
                                 jdb.KANJI|jdb.KANA,            False, True,  False  ),
    ('123', u'バタード・チャイルド', jdb.KANA|jdb.KSYM,         True,  False, False, ),
    ('124', u'黄葉・こうよう',   jdb.KANJI|jdb.KANA|jdb.KSYM,   False, True,  False, ),
    ('125', u'タバコ・モザイク病', jdb.KANJI|jdb.KANA|jdb.KSYM, False, True,  False, ),
    ('126', u'原子力安全・保安院', jdb.KANJI|jdb.KSYM,          False, True,  False, ),
    ('127', u'【あるく】',       jdb.KANA|jdb.KSYM,                True,  False, False  ),
    ('128', u'【歩く】',         jdb.KANJI|jdb.KANA|jdb.KSYM,   False, True,  False, ),
    ('129', u'[あるく]',         jdb.KANA|jdb.LATIN,         False, True,  False  ), # ascii turns it into keb.
    ('130', u'[歩く]',           jdb.KANJI|jdb.KANA|jdb.LATIN,        False, True,  False, ),
    ]

def add_tests (cls, col):
        # This function will dynamically add test methods to
        # class, 'cls'.  For each row in Data, a method will
        # be added to the class with name "test%s" where %s is
        # from column 0, and the method will call the (preseumed
        # to exist) instance method "check() with two arguments,
        # the first being from column 'col', and the second from
        # column 1.

        for row in Data:
            testid = row[0]; teststr = row[1]; expected = row[col]
              # We use default argument values in the lambda expression
              # they are bound when the "setattr(...lambda...) line
              # is executed.  Otherwise, the lambda arguments will be
              # evaluated when the lambda is, and will contain the
              # valuesthat the variable had when the loop was exited.
            setattr (cls, 'test_%s' % testid,
                     lambda self,e=expected, t=teststr: self.check(e, t))

class Test_Chars (unittest.TestCase):
    def check (_, expected, testtext):
        result = jdb.jstr_classify (testtext)
        _.assertEqual (result, expected)
add_tests (Test_Chars, 2)

class Test_jstr_reb (unittest.TestCase):
    def check (_, expected, testtext):
        result = jdb.jstr_reb (testtext)
        _.assertEqual (result, expected)
add_tests (Test_jstr_reb, 3)

class Test_jstr_gloss (unittest.TestCase):
    def check (_, expected, testtext):
        result = jdb.jstr_gloss (testtext)
        _.assertEqual (result, expected)
add_tests (Test_jstr_gloss, 5)

class Test_jstr_keb (unittest.TestCase):
    def check (_, expected, testtext):
        result = jdb.jstr_keb (testtext)
        _.assertEqual (result, expected)
add_tests (Test_jstr_keb, 4)

if __name__ == '__main__':
        unittest.main()
