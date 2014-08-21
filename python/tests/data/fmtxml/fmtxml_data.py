# Test data for test_fmtxml.py

t_in = {}  # Global for test input strings, keyed by test id.
t_exp = {} # Global for test expected strings, keyed by test id.

####################################################
# Test_entr

tid = '0200010' ####################################
t_in [tid] = \
        'e = Entr()'
t_exp[tid] = '''\
<entry>
</entry>'''

tid = '0201020' ####################################
t_in[tid] = \
        'e = Entr(_grp=[Grp(kw=2,ord=1)])'
t_exp[tid] = '''\
<entry>
<group ord="1">xx</group>
</entry>'''

tid = '0201030' ####################################
t_in[tid] = \
        'e = Entr(_grp=[Grp(kw=11,ord=5),Grp(kw=10,ord=2)])'
t_exp[tid] = '''\
<entry>
<group ord="5">mxtpp55-2</group>
<group ord="2">zz</group>
</entry>'''

tid = '0201040' ####################################
t_in[tid] = \
        'e = Entr(_grp=[Grp(kw=5,ord=1)])'
t_exp[tid] = '''\
<entry>
</entry>'''

tid = '0201050' ####################################
t_in[tid] = \
        "e = Entr(_grp=[Grp(kw=1)])"
t_exp[tid] = '''\
<entry>
<group>grp1</group>
</entry>'''

####################################################
# Test_xrslv

tid = '0202010' ####################################
t_in[tid] = \
        "e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=3, ktxt='\u540c\u3058')])])"
t_exp[tid] = '''\
<entry>
<sense>
<xref>同じ</xref>
</sense>
</entry>'''

tid = '0202020' ####################################
t_in[tid] = \
        "e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=2, ktxt='\u540c\u3058')])])"
t_exp[tid] = '''\
<entry>
<sense>
<ant>同じ</ant>
</sense>
</entry>'''

tid = '0202030' ####################################
t_in[tid] = \
        "e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=3, rtxt='\u304a\u306a\u3058')])])"
t_exp[tid] = '''\
<entry>
<sense>
<xref>おなじ</xref>
</sense>
</entry>'''

tid = '0202040' ####################################
t_in[tid] = \
        "e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=3, ktxt='\u540c\u3058',\
                                                             rtxt='\u304a\u306a\u3058')])])"
t_exp[tid] = '''\
<entry>
<sense>
<xref>同じ・おなじ</xref>
</sense>
</entry>'''

tid = '0202050' ####################################
t_in[tid] = \
        "e = Entr (src=99, _sens=[Sens (_xrslv=[Xrslv(typ=3, ktxt='\u540c\u3058',\
                                                             rtxt='\u304a\u306a\u3058', tsens=3)])])"
t_exp[tid] = '''\
<entry>
<sense>
<xref>同じ・おなじ・3</xref>
</sense>
</entry>'''

####################################################
# Test_jmnedict

tid = '0300010' ####################################
t_in[tid] = \
        "e = Entr (src=99, seq=300010)"
t_exp[tid] = '''\
<entry>
</entry>'''

tid = '0300020' ####################################
t_in[tid] = \
        "e = Entr (src=99, _rdng=[Rdng (txt='たかはし')])"
t_exp[tid] = '''\
<entry>
<r_ele>
<reb>たかはし</reb>
</r_ele>
</entry>'''

tid = '0300030' ####################################
t_in[tid] = \
        "e = Entr (src=99, _rdng=[Rdng (txt='キャッツ')])"
t_exp[tid] = '''\
<entry>
<r_ele>
<reb>キャッツ</reb>
</r_ele>
</entry>'''

tid = '0300040' ####################################
t_in[tid] = \
        "e = Entr (src=99, _kanj=[Kanj (txt='高橋')])"
t_exp[tid] = '''\
<entry>
<k_ele>
<keb>高橋</keb>
</k_ele>
</entry>'''

tid = '0300050' ####################################
t_in[tid] = \
        "e = Entr (src=99, _sens=[Sens (_gloss=[Gloss(txt='Takahashi')])])"
t_exp[tid] = '''\
<entry>
<trans>
<trans_det>Takahashi</trans_det>
</trans>
</entry>'''

tid = '0305001' ####################################
t_in[tid] = \
        "e = Entr (src=99, _rdng=[Rdng (txt='キャッツ＆ドッグス')],\
                           _sens=[Sens (_gloss=[Gloss (txt='Cats & Dogs (film)')],\
                                        _misc=[Misc (kw=jdb.KW.MISC['unclass'].id)])])"
t_exp[tid] = '''\
<entry>
<r_ele>
<reb>キャッツ＆ドッグス</reb>
</r_ele>
<trans>
<name_type>&unclass;</name_type>
<trans_det>Cats &amp; Dogs (film)</trans_det>
</trans>
</entry>'''

# Following data for class Test_entr_diff

tid = '0400010' ####################################
t_in[tid] = \
        "e1 = Entr (id=1, src=99, _rdng=[Rdng (txt='たかはし')])\n"\
        "e2 = Entr (id=2, src=99, _rdng=[Rdng (txt='たかはし')])"
t_exp[tid] = ''

tid = '0400020' ####################################
t_in[tid] = \
        "e1 = Entr (id=1, src=99, _rdng=[Rdng (txt='たかはし')])\n"\
        "e2 = Entr (id=2, src=99, _rdng=[Rdng (txt='たかばし')])"
t_exp[tid] = '''\
@@ -4 +4 @@
-<reb>たかはし</reb>
+<reb>たかばし</reb>'''


