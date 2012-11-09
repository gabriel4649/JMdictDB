#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys, unittest, pdb
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb, jellex, ply, unittest_extensions

__unittest = 1

def main():
        globalSetup()
        unittest.main()

def setup (_):
        global Lexer, Tokens
        _.lexer, _.tokens = jellex.create_lexer ()
        return True

class Test_create (unittest.TestCase):
    def setUp   (_): setup (_)
    def test001 (_): _.assertIsInstance (_.lexer, ply.lex.Lexer) 
    def test002 (_): 
        _.assertEqual (set(_.tokens), 
                       set(('SNUM', 'SEMI', 'BRKTL', 'TEXT', 'QTEXT', 'COLON',
                            'COMMA', 'DOT', 'EQL', 'SLASH', 'BRKTR', 'NL',
                            'GTEXT', 'KTEXT', 'RTEXT', 'NUMBER', 'HASH')))

class Test_single1 (unittest.TestCase):
      #FIXME: need tests for token NL added in here.
    def setUp     (_): setup (_)
    def test000010(_): check(_,'',[])
    def test000020(_): check(_,' ',[])          # ascii space
    def test000030(_): check(_,'　',[])         # wide space \u3000
    def test000040(_): check(_,'        ',[])   # tab
    def test000050(_): check(_,';',['SEMI'])
    def test000060(_): check(_,'；',['SEMI'])    # wide semi \uFF1B
    def test000070(_): check(_,'[',['BRKTL'], expect_end='TAGLIST')
    def test000080(_): check(_,']',['TEXT'])
    def test000090(_): check(_,'a',['TEXT'])
    def test000100(_): check(_,'0',['TEXT'])
    def test000110(_): check(_,'あ',['RTEXT'])
    def test000120(_): check(_,'ア',['RTEXT'])
    def test000130(_): check(_,'男',['KTEXT'])
    def test000140(_): check(_,'a a',['TEXT','TEXT'])
    def test000150(_): check(_,'a\ta',['TEXT','TEXT'])
    def test000160(_): check(_,'a　a',['TEXT','TEXT'])
    def test000170(_): check(_,'あ a',['RTEXT','TEXT'])
    def test000180(_): check(_,'a　女',['TEXT','KTEXT'])
    def test000190(_): check(_,'abcFG',['TEXT'])
    def test000200(_): check(_,'ab男の人　おんなのこ',['KTEXT','RTEXT'])
    def test000210(_): check(_,'a       a',['TEXT','TEXT'])  # Ascii spaces
    def test000220(_): check(_,'a　　　　a',['TEXT','TEXT'])  # \u3000 spaces
    def test000230(_): check(_,'a　  　　a',['TEXT','TEXT'])  # Mixed spaces
    def test000240(_): check(_,'あああ　\t アア',['RTEXT','RTEXT'])
    def test000250(_): check(_,'　ああ　abc a   大阪\tb　 ',['RTEXT','TEXT','TEXT','KTEXT','TEXT'])
    def test000260(_): check(_,'a;b',['TEXT','SEMI','TEXT'])
    def test000270(_): check(_,'a；b',['TEXT','SEMI','TEXT'])
    def test000280(_): check(_,'けしゴム;男の子',['RTEXT','SEMI','KTEXT'])
    def test000290(_): check(_,'a　 ;b',['TEXT','SEMI','TEXT'])
    def test000300(_): check(_,'　a ;  ；; b',['TEXT','SEMI','SEMI','SEMI','TEXT'])
    def test000310(_): check(_,'a[',['TEXT','BRKTL'])
    def test000320(_): check(_,'[0]',['SNUM'],expect_end='GLOSS')
    def test000330(_): check(_,'a[9999999999]',['TEXT','SNUM'])
      # Note the following are not an SNUM due to the space inside brackets.
    #def test000340(_): check(_,'[0 ]',['TEXT','SNUM'])
    #def test000350(_): check(_,'[ 0]',['SNUM'])
    def test000400(_): check(_,'a;b\uFF1Bc\u3000d e\tf\rg\nh',
        ['TEXT','SEMI','TEXT','SEMI','TEXT','TEXT','TEXT','TEXT','TEXT','NL','TEXT'],
        ['a',';','b','\uFF1B','c','d','e','f','g','\n','h'])

    # Taglist sequences

    def test001010(_): check(_,'[ 0]',['BRKTL','NUMBER','BRKTR'])
    def test001020(_): check(_,'[0 ]',['BRKTL','NUMBER','BRKTR'])
    def test001030(_): check(_,'[:',['BRKTL','COLON'])
    def test001040(_): check(_,'[;',['BRKTL','SEMI'])
    def test001050(_): check(_,'[\uff1b',['BRKTL','SEMI'])
    def test001060(_): check(_,'[,',['BRKTL','COMMA'])
    def test001070(_): check(_,'[\u3001',['BRKTL','COMMA'])
    def test001080(_): check(_,'[=',['BRKTL','EQL'])
    def test001090(_): check(_,'[/',['BRKTL','SLASH'])
    def test001100(_): check(_,'[\uFF0F',['BRKTL','SLASH'])
    def test001110(_): check(_,'[.',['BRKTL','DOT'])
    def test001120(_): check(_,'[\u30FB',['BRKTL','DOT'])
    def test001130(_): check(_,'[#',['BRKTL','HASH'])
    def test001140(_): check(_,'[[',['BRKTL','BRKTL'],expect_end='SNUMLIST')
    def test001150(_): check(_,'[]',['BRKTL','BRKTR'],expect_end='INITIAL')
    def test001160(_): check(_,'[0',['BRKTL','NUMBER'])
    def test001170(_): check(_,'[0123',['BRKTL','NUMBER'])
    def test001180(_): check(_,'[０１２３',['BRKTL','NUMBER'])
    def test001190(_): check(_,'[０1３2',['BRKTL','NUMBER'])
    def test001200(_): check(_,'[""',['BRKTL','TEXT'])
    def test001210(_): check(_,'["abc"',['BRKTL','QTEXT'],['[','"abc"'])
    def test001220(_): check(_,'["ab  cde"',['BRKTL','QTEXT'],['[','"ab  cde"'])
    def test001230(_): check(_,r'["ab\"cde"',['BRKTL','QTEXT'],['[',r'"ab\"cde"'])
    def test001240(_): check(_,r'["ab \" \" bcde"',['BRKTL','QTEXT'],['[',r'"ab \" \" bcde"'])
    def test001250(_): check(_,'[ :',['BRKTL','COLON'])
    def test001260(_): check(_,'[: ',['BRKTL','COLON'])
    def test001270(_): check(_,'[  :  ',['BRKTL','COLON'])
    def test001280(_): check(_,'[ \u3000:\t\u3000 ',['BRKTL','COLON'])
    def test001290(_): check(_,'[abc',['BRKTL','TEXT'])
    def test001300(_): check(_,'[ああ',['BRKTL','RTEXT'])
    def test001310(_): check(_,'[会議',['BRKTL','KTEXT'])
    def test001320(_): check(_,'[abc 会議 アア def',['BRKTL','TEXT', 'KTEXT', 'RTEXT', 'TEXT'])
    def test001330(_): check(_,'[abc\u3000会議',['BRKTL','KTEXT'])  # \u3000 is not space in taglist.
    def test001340(_): check(_,'[kw=xxx]',['BRKTL','TEXT','EQL','TEXT','BRKTR'],['[','kw','=','xxx',']'])
    def test001350(_): check(_,'[kw="xxx"]',['BRKTL','TEXT','EQL','QTEXT','BRKTR'],['[','kw','=','"xxx"',']'])
    def test001360(_): check(_,'[kw="  xx  xx  " ]',['BRKTL','TEXT','EQL','QTEXT','BRKTR'],
                                                    ['[','kw','=','"  xx  xx  "',']'])
    # Gloss sequences

    def test001510(_): check(_,'[0]text',['SNUM','GTEXT'],['[0]','text'],expect_end='GLOSS')  #see also test000320.
    def test001520(_): check(_,'te\;xt',['GTEXT'],['te;xt'],begin='GLOSS')
    def test001530(_): check(_,'te\[xt',['GTEXT'],['te[xt'],begin='GLOSS')
    def test001540(_): check(_,'\;text',['GTEXT'],[';text'],begin='GLOSS')
    def test001550(_): check(_,'\[text',['GTEXT'],['[text'],begin='GLOSS')
    def test001560(_): check(_,'text\;',['GTEXT'],['text;'],begin='GLOSS')
    def test001570(_): check(_,'text\[',['GTEXT'],['text['],begin='GLOSS')
    def test001580(_): check(_,'text1;text2',['GTEXT','SEMI','GTEXT'],begin='GLOSS')
    def test001590(_): check(_,'text1;\;text2',['GTEXT','SEMI','GTEXT'],begin='GLOSS')
      # check cleanup functions...
    def test001610(_): check(_,'[0]  text',['SNUM','GTEXT'],['[0]  ','text'])  #FIXME
    def test001620(_): check(_,'[0]text  ',['SNUM','GTEXT'],['[0]','text'])
    def test001630(_): check(_,'[0]  text  ',['SNUM','GTEXT'],['[0]  ','text'])  #FIXME
    def test001640(_): check(_,'[0]  words twice  ',['SNUM','GTEXT'],['[0]  ','words twice'])  #FIXME
    def test001650(_): check(_,'[0]  words   twice  ',['SNUM','GTEXT'],['[0]  ','words   twice'])  #FIXME
    def test001660(_): check(_,'[0]\u3000\u3000text',['SNUM','GTEXT'],['[0]\u3000\u3000','text'])  #FIXME
    def test001670(_): check(_,'[0]text\u3000\u3000',['SNUM','GTEXT'],['[0]','text'])
    def test001680(_): check(_,'[0]\t\ttext',['SNUM','GTEXT'],['[0]\t\t','text'])  #FIXME
    def test001690(_): check(_,'[0]text\t\t',['SNUM','GTEXT'],['[0]','text'])
    def test001700(_): check(_,'[0]\n\ntext',['SNUM','GTEXT'],['[0]\n\n','text'])  #FIXME
    def test001710(_): check(_,'[0]text\n\n',['SNUM','GTEXT'],['[0]','text'])
    def test001720(_): check(_,'[0] \u3000\t \u3000text',['SNUM','GTEXT'],['[0] \u3000\t \u3000','text'])  #FIXME
    def test001730(_): check(_,'[0]text \u3000\t \u3000',['SNUM','GTEXT'],['[0]','text'])
    def test001740(_): check(_,'[0] \u3000\t \u3000text \u3000\t \u3000',['SNUM','GTEXT'],['[0] \u3000\t \u3000','text'])  #FIXME
    def test001750(_): check(_,'[',['BRKTL'],begin='GLOSS',expect_end='TAGLIST')
    def test001760(_): check(_,'[]',['BRKTL','BRKTR'],begin='GLOSS',expect_end='GLOSS')

    # Snumlist

    def test001910(_): check(_,'[',['BRKTL'],begin='TAGLIST',expect_end='SNUMLIST')
    def test001920(_): check(_,'[]',['BRKTL','BRKTR'],begin='TAGLIST',expect_end='TAGLIST')
    def test001930(_): check(_,'[1',['BRKTL','NUMBER'],['[','1'],begin='TAGLIST',expect_end='SNUMLIST')
    def test001940(_): check(_,'[,',['BRKTL','COMMA'],begin='TAGLIST',expect_end='SNUMLIST')
    def test001950(_): check(_,'[a',['BRKTL','TEXT'],begin='TAGLIST',expect_end='SNUMLIST')
    def test001960(_): check(_,'[2aa33bb',['BRKTL','NUMBER','TEXT','TEXT','NUMBER','TEXT','TEXT'],  #FIXME?
                                          ['[','2','a','a','33','b','b'],begin='TAGLIST',expect_end='SNUMLIST')
    def test001970(_): check(_,'[ 1',['BRKTL','NUMBER'],['[','1'],begin='TAGLIST',expect_end='SNUMLIST')
    def test001980(_): check(_,'[２',['BRKTL','NUMBER'],['[','２'],begin='TAGLIST',expect_end='SNUMLIST')
    def test001990(_): check(_,'[　２　',['BRKTL','NUMBER'],['[','２'],begin='TAGLIST',expect_end='SNUMLIST')
    def test002000(_): check(_,'[2,33,5]',['BRKTL','NUMBER','COMMA','NUMBER','COMMA','NUMBER','BRKTR'],
                                          ['[','2',',','33',',','5',']'],begin='TAGLIST',expect_end='TAGLIST')

def check (_, in_str,            # String containing text to feed to lexer. 
              expect_toks,       # List of tokens expected from lexer (or None to not check).
              expect_vals=None,  # List of token values expected from lexer (or None...) 
              expect_end=None,   # Lexer state expected after lexer has processed string.
              begin='INITIAL'):  # Lexer state to set before processing string. 
        tokens, values = _check (_, in_str, begin)
        if expect_toks is not None: 
            _.assertEqual (tokens, expect_toks)
        if expect_vals is not None:
            _.assertEqual (values, expect_vals)
        if expect_end is not None:
            _.assertEqual (_.lexer.lexstate, expect_end)

def _check (_, in_str, begin='INITIAL'):
        jellex.lexreset (_.lexer, in_str, begin)
        tokens = [];  values = []
        while 1:
            tok = _.lexer.token()
            if not tok: break
            tokens.append (tok.type)
            values.append (tok.value)
        return tokens, values

if __name__ == '__main__': main()
