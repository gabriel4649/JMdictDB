#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Tests the jdb.jstr_classify() function.


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
    ('013', '\x01\x00',         jdb.LATIN,                 False, False, True,  ),
    ('014', '　',               jdb.KSYM,                  False, True,  False, ),
    ('015', '、',               jdb.KSYM,                  False, True,  False, ),
    ('016', '。',               jdb.KSYM,                  False, True,  False, ),
    ('019', '【',               jdb.KSYM,                  False, True,  False, ),
    ('020', 'ぁ',               jdb.KANA,                  True,  False, False, ),
    ('021', 'あ',               jdb.KANA,                  True,  False, False, ),
    ('022', 'ん',               jdb.KANA,                  True,  False, False, ),
    ('023', 'ァ',               jdb.KANA,                  True,  False, False, ),
    ('024', 'ア',               jdb.KANA,                  True,  False, False, ),
    ('025', 'ン',               jdb.KANA,                  True,  False, False, ),
    ('026', 'ー',               jdb.KANA,                  True,  False, False, ),  # U+30FB
    ('027', '一',               jdb.KANJI,                 False, True,  False, ),  # U+4E00
    ('028', 'Α',                jdb.OTHER,                 False, True,  False, ),
    ('029', 'Ａ',               jdb.KANJI,                 False, True,  False, ),
    ('030', '〇',               jdb.KSYM,                  False, True,  False, ),
    ('031', '○',                jdb.OTHER,                 False, True,  False, ),
    ('032', 'α',                jdb.OTHER,                 False, True,  False, ),
    ('033', '→',                jdb.OTHER,                 False, True,  False, ),
    ('034', '〒',               jdb.KSYM,                  False, True,  False, ),
    ('035', '店',               jdb.KANJI,                 False, True,  False, ),
    ('036', 'ヽ',               jdb.KANA,                  True,  False, False, ),
    ('037', 'ヾ',               jdb.KANA,                  True,  False, False, ),
    ('038', 'ゝ',               jdb.KANA,                  True,  False, False, ),
    ('039', 'ゞ',               jdb.KANA,                  True,  False, False, ),
    ('040', '〃',               jdb.KSYM,                  False, True,  False, ),
    ('041', '々',               jdb.KSYM,                  False, True,  False, ),
    ('042', '〆',               jdb.KANJI,                 False, True,  False, ),  # IS-222
    ('043', '３',               jdb.KANJI,                 False, True,  False, ),
    ('044', '・',               jdb.KSYM,                  False, True,  False, ),
    ('045', '\u301C',           jdb.KANA,                  True,  False, False, ),  # WAVE DASH
    ('046', '\uFF5E',           jdb.KANJI,                 False, True,  False, ),  # FULLWIDTH TILDE

    ('101', 'ーパ',             jdb.KANA,                  True,  False, False, ),
    ('102', 'スーパー',         jdb.KANA,                  True,  False, False, ),
    ('103', '会う',             jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('104', 'ＰＣエンジン',     jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('105', '１０しん',         jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('106', 'スコップ！',       jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('107', '２ちゃんねる',     jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('108', 'ＫＤＤＩ',         jdb.KANJI,                 False, True,  False, ),
    ('109', 'ＰＣエンジン',     jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('110', 'ｍｉｘｉ',         jdb.KANJI,                 False, True,  False, ),
    ('111', 'しろＭＩＤタワ',   jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('112', 'ＦＣ東京',         jdb.KANJI,                 False, True,  False, ),
    ('113', 'ＳＭＢＣフレンド証券', jdb.KANJI|jdb.KANA,    False, True,  False, ),
    ('114', 'あか組４',         jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('115', 'βカロチン',        jdb.KANA|jdb.OTHER,        False, True,  False, ),
    ('116', '〆る',             jdb.KANJI|jdb.KANA,        False,  True, False, ),  # IS-222
    ('117', 'おげんき',         jdb.KANA,                  True,  False, False, ),
    ('118', 'お元気',           jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('119', '会う',             jdb.KANJI|jdb.KANA,        False, True,  False, ),
    ('120', 'アンパックしんひょうきほう', jdb.KANA,        True,  False, False, ),
    ('121', 'アンパック１０しんひょうきほう', jdb.KANJI|jdb.KANA,
                                                                False, True,  False, ),
    ('122', 'インターナショナライゼーション／インターナショナリゼーション',
                                 jdb.KANJI|jdb.KANA,            False, True,  False  ),
    ('123', 'バタード・チャイルド', jdb.KANA|jdb.KSYM,         True,  False, False, ),
    ('124', '黄葉・こうよう',   jdb.KANJI|jdb.KANA|jdb.KSYM,   False, True,  False, ),
    ('125', 'タバコ・モザイク病', jdb.KANJI|jdb.KANA|jdb.KSYM, False, True,  False, ),
    ('126', '原子力安全・保安院', jdb.KANJI|jdb.KSYM,          False, True,  False, ),
    ('127', '【あるく】',       jdb.KANA|jdb.KSYM,                True,  False, False  ),
    ('128', '【歩く】',         jdb.KANJI|jdb.KANA|jdb.KSYM,   False, True,  False, ),
    ('129', '[あるく]',         jdb.KANA|jdb.LATIN,         False, True,  False  ), # ascii turns it into keb.
    ('130', '[歩く]',           jdb.KANJI|jdb.KANA|jdb.LATIN,        False, True,  False, ),
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
