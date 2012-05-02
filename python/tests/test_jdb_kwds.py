#!/usr/bin/env python

# Tests the jdb.Kwds class.

import sys, pdb, unittest
if '../lib' not in sys.path: sys.path.append ('../lib')
import jdb
__unittest = 1

KwdsAttrs = set (('DIAL','FLD','FREQ','GINF','KINF','LANG','MISC',
		  'POS','RINF','SRC','STAT','XREF','CINF','GRP'))

# The following should be updated when changes are made to the 
# base data in the ../../pg/data/*.csv files.
Current_kwds = [
	('001', 'CINF', 1, 'nelson_c'),
	('002', 'CINF', 2, 'nelson_n'),
	('003', 'CINF', 3, 'halpern_njecd'),
	('004', 'CINF', 4, 'halpern_kkld'),
	('005', 'CINF', 5, 'heisig'),
	('006', 'CINF', 6, 'gakken'),
	('007', 'CINF', 7, 'oneill_names'),
	('008', 'CINF', 8, 'oneill_kk'),
	('009', 'CINF', 9, 'moro'),
	('010', 'CINF', 10, 'henshall'),
	('011', 'CINF', 11, 'sh_kk'),
	('012', 'CINF', 12, 'sakade'),
	('013', 'CINF', 13, 'tutt_cards'),
	('014', 'CINF', 14, 'crowley'),
	('015', 'CINF', 15, 'kanji_in_ctx'),
	('016', 'CINF', 16, 'busy_people'),
	('017', 'CINF', 17, 'kodansha_comp'),
	('018', 'CINF', 18, 'skip'),
	('019', 'CINF', 19, 'sh_desc'),
	('020', 'CINF', 20, 'four_corner'),
	('021', 'CINF', 21, 'deroo'),
	('022', 'CINF', 22, 'misclass'),
	('023', 'CINF', 23, 'pinyin'),
	('024', 'CINF', 24, 'strokes'),
	('025', 'CINF', 25, 'jis208'),
	('026', 'CINF', 26, 'jis212'),
	('027', 'CINF', 27, 'jis213'),
	('028', 'CINF', 28, 'henshall3'),
	('029', 'CINF', 29, 'korean_h'),
	('030', 'CINF', 30, 'korean_r'),
	('031', 'CINF', 31, 'jf_cards'),
	('032', 'CINF', 32, 'nelson_rad'),
	('033', 'CINF', 33, 'skip_mis'),
	('034', 'CINF', 34, 's_h'),
	('035', 'DIAL', 1, 'std'),
	('036', 'DIAL', 2, 'ksb'),
	('037', 'DIAL', 3, 'ktb'),
	('038', 'DIAL', 4, 'kyb'),
	('039', 'DIAL', 5, 'osb'),
	('040', 'DIAL', 6, 'tsb'),
	('041', 'DIAL', 7, 'thb'),
	('042', 'DIAL', 8, 'tsug'),
	('043', 'DIAL', 9, 'kyu'),
	('044', 'DIAL', 10, 'rkb'),
	('045', 'FLD', 1, 'Buddh'),
	('046', 'FLD', 2, 'comp'),
	('047', 'FLD', 3, 'food'),
	('048', 'FLD', 4, 'geom'),
	('049', 'FLD', 5, 'ling'),
	('050', 'FLD', 6, 'MA'),
	('051', 'FLD', 7, 'math'),
	('052', 'FLD', 8, 'mil'),
	('053', 'FLD', 9, 'physics'),
	('054', 'FLD', 10, 'chem'),
	('055', 'FREQ', 1, 'ichi'),
	('056', 'FREQ', 2, 'gai'),
	('057', 'FREQ', 4, 'spec'),
	('058', 'FREQ', 5, 'nf'),
	('059', 'FREQ', 6, 'gA'),
	('060', 'FREQ', 7, 'news'),
	('061', 'GINF', 1, 'equ'),
	('062', 'GINF', 2, 'lit'),
	('063', 'GINF', 3, 'fig'),
	('064', 'GINF', 4, 'expl'),
	('065', 'KINF', 1, 'iK'),
	('066', 'KINF', 2, 'io'),
	('067', 'KINF', 3, 'oK'),
	('068', 'KINF', 4, 'ik'),
	('069', 'KINF', 5, 'ateji'),
	('070', 'MISC', 1, 'X'),
	('071', 'MISC', 2, 'abbr'),
	('072', 'MISC', 3, 'arch'),
	('073', 'MISC', 4, 'chn'),
	('074', 'MISC', 5, 'col'),
	('075', 'MISC', 6, 'derog'),
	('076', 'MISC', 7, 'eK'),
	('077', 'MISC', 8, 'fam'),
	('078', 'MISC', 9, 'fem'),
	('079', 'MISC', 11, 'hon'),
	('080', 'MISC', 12, 'hum'),
	('081', 'MISC', 13, 'id'),
	('082', 'MISC', 14, 'm-sl'),
	('083', 'MISC', 15, 'male'),
	('084', 'MISC', 17, 'obs'),
	('085', 'MISC', 18, 'obsc'),
	('086', 'MISC', 19, 'pol'),
	('087', 'MISC', 20, 'rare'),
	('088', 'MISC', 21, 'sl'),
	('089', 'MISC', 22, 'uk'),
	('090', 'MISC', 24, 'vulg'),
	('091', 'MISC', 25, 'sens'),
	('092', 'MISC', 26, 'poet'),
	('093', 'MISC', 27, 'on-mim'),
	('094', 'MISC', 81, 'proverb'),
	('095', 'MISC', 82, 'aphorism'),
	('096', 'MISC', 83, 'quote'),
	('097', 'MISC', 181, 'surname'),
	('098', 'MISC', 182, 'place'),
	('099', 'MISC', 183, 'unclass'),
	('100', 'MISC', 184, 'company'),
	('101', 'MISC', 185, 'product'),
	('102', 'MISC', 188, 'person'),
	('103', 'MISC', 189, 'given'),
	('104', 'MISC', 190, 'station'),
	('105', 'MISC', 191, 'organization'),
	('106', 'POS', 1, 'adj-i'),
	('107', 'POS', 2, 'adj-na'),
	('108', 'POS', 3, 'adj-no'),
	('109', 'POS', 4, 'adj-pn'),
	('110', 'POS', 5, 'adj-t'),
	('111', 'POS', 6, 'adv'),
	('112', 'POS', 8, 'adv-to'),
	('113', 'POS', 9, 'aux'),
	('114', 'POS', 10, 'aux-adj'),
	('115', 'POS', 11, 'aux-v'),
	('116', 'POS', 12, 'conj'),
	('117', 'POS', 13, 'exp'),
	('118', 'POS', 14, 'int'),
	('119', 'POS', 17, 'n'),
	('120', 'POS', 18, 'n-adv'),
	('121', 'POS', 19, 'n-suf'),
	('122', 'POS', 20, 'n-pref'),
	('123', 'POS', 21, 'n-t'),
	('124', 'POS', 24, 'num'),
	('125', 'POS', 25, 'pref'),
	('126', 'POS', 26, 'prt'),
	('127', 'POS', 27, 'suf'),
	('128', 'POS', 28, 'v1'),
	('130', 'POS', 30, 'v5aru'),
	('131', 'POS', 31, 'v5b'),
	('132', 'POS', 32, 'v5g'),
	('133', 'POS', 33, 'v5k'),
	('134', 'POS', 34, 'v5k-s'),
	('135', 'POS', 35, 'v5m'),
	('136', 'POS', 36, 'v5n'),
	('137', 'POS', 37, 'v5r'),
	('138', 'POS', 38, 'v5r-i'),
	('139', 'POS', 39, 'v5s'),
	('140', 'POS', 40, 'v5t'),
	('141', 'POS', 41, 'v5u'),
	('142', 'POS', 42, 'v5u-s'),
	('143', 'POS', 43, 'v5uru'),
	('144', 'POS', 44, 'vi'),
	('145', 'POS', 45, 'vk'),
	('146', 'POS', 46, 'vs'),
	('147', 'POS', 47, 'vs-s'),
	('148', 'POS', 48, 'vs-i'),
	('149', 'POS', 49, 'vz'),
	('150', 'POS', 50, 'vt'),
	('151', 'POS', 51, 'ctr'),
	('152', 'POS', 52, 'vn'),
	('153', 'POS', 53, 'v4r'),
	('155', 'POS', 56, 'adj-f'),
	('157', 'POS', 58, 'vr'),
	('158', 'RINF', 1, 'gikun'),
	('159', 'RINF', 2, 'ok'),
	('160', 'RINF', 3, 'ik'),
	('161', 'RINF', 4, 'uK'),
	('162', 'RINF', 21, 'oik'),
	('163', 'RINF', 103, 'name'),
	('164', 'RINF', 104, 'rad'),
	('165', 'RINF', 105, 'jouyou'),
	('166', 'RINF', 106, 'kun'),
	('167', 'RINF', 128, 'on'),
	('168', 'RINF', 129, 'kan'),
	('169', 'RINF', 130, 'go'),
	('170', 'RINF', 131, 'tou'),
	('171', 'RINF', 132, 'kanyou'),
	('173', 'STAT', 2, 'A'),
	('174', 'STAT', 4, 'D'),
	('175', 'STAT', 6, 'R'),
	('176', 'XREF', 1, 'syn'),
	('177', 'XREF', 2, 'ant'),
	('178', 'XREF', 3, 'see'),
	('179', 'XREF', 4, 'cf'),
	('180', 'XREF', 5, 'ex'),
	('181', 'XREF', 6, 'uses'),
	('182', 'XREF', 7, 'pref'),
	('183', 'XREF', 8, 'kvar'),
	('183', 'LANG', 1, 'eng'),
	('184', 'LANG', 10, 'ain'),
	('185', 'LANG', 79, 'chi'),
	('186', 'LANG', 137, 'fre'),
	('187', 'LANG', 150, 'ger'),
	('188', 'LANG', 460, 'vie'),
	('189', 'POS', 59, 'v2a-s'),
	('190', 'POS', 60, 'v4h'),
	('191', 'POS', 61, 'pn'),
	('192', 'DIAL', 11, 'nab'),
	('193', 'POS', 62, 'vs-c'),
	('194', 'DIAL', 12, 'hob'),
	('194', 'FLD', 11, 'archit'),
	('195', 'FLD', 12, 'astron'),
	('196', 'FLD', 13, 'baseb'),
	('197', 'FLD', 14, 'biol'),
	('198', 'FLD', 15, 'bot'),
	('199', 'FLD', 16, 'bus'),
	('200', 'FLD', 17, 'econ'),
	('201', 'FLD', 18, 'engr'),
	('202', 'FLD', 19, 'finc'),
	('203', 'FLD', 20, 'geol'),
	('204', 'FLD', 21, 'law'),
	('205', 'FLD', 22, 'med'),
	('206', 'FLD', 23, 'music'),
	('207', 'FLD', 24, 'Shinto'),
	('208', 'FLD', 25, 'sports'),
	('209', 'FLD', 26, 'sumo'),
	('210', 'FLD', 27, 'zool'),
	('211', 'POS', 63, 'adj-kari'),
	('212', 'POS', 64, 'adj-ku'),
	('213', 'POS', 65, 'adj-shiku'),
	('214', 'POS', 66, 'adj-nari'),
	('215', 'POS', 67, 'n-pr'),
	('216', 'POS', 68, 'v-unspec'),
	('217', 'POS', 69, 'v4k'),
	('218', 'POS', 70, 'v4g'),
	('219', 'POS', 71, 'v4s'),
	('220', 'POS', 72, 'v4t'),
	('221', 'POS', 73, 'v4n'),
	('222', 'POS', 74, 'v4b'),
	('223', 'POS', 75, 'v4m'),
	('224', 'POS', 76, 'v2k-k'),
	('225', 'POS', 77, 'v2g-k'),
	('226', 'POS', 78, 'v2t-k'),
	('227', 'POS', 79, 'v2d-k'),
	('228', 'POS', 80, 'v2h-k'),
	('229', 'POS', 81, 'v2b-k'),
	('230', 'POS', 82, 'v2m-k'),
	('231', 'POS', 83, 'v2y-k'),
	('232', 'POS', 84, 'v2r-k'),
	('233', 'POS', 85, 'v2k-s'),
	('234', 'POS', 86, 'v2g-s'),
	('235', 'POS', 87, 'v2s-s'),
	('236', 'POS', 88, 'v2z-s'),
	('237', 'POS', 89, 'v2t-s'),
	('238', 'POS', 90, 'v2d-s'),
	('239', 'POS', 91, 'v2n-s'),
	('240', 'POS', 92, 'v2h-s'),
	('241', 'POS', 93, 'v2b-s'),
	('242', 'POS', 94, 'v2m-s'),
	('243', 'POS', 95, 'v2y-s'),
	('244', 'POS', 96, 'v2r-s'),
	('245', 'POS', 97, 'v2w-s'),
	('246', 'MISC', 28, 'joc'),
	('247', 'FLD', 28, 'anat'),
	]

Cursor = None
def globalSetup ():
	global Cursor
	try:	# Get login credentials from dbauth.py if possible.
	    import dbauth; kwargs = dbauth.auth
	except ImportError: kwargs = {}
	Cursor = jdb.dbOpen ('jmdict', **kwargs)

class Test_Empty (unittest.TestCase):
    def setUp (_):
	_.o = jdb.Kwds()

    def test001 (_):
	  # Check that .Tables has the expected set of attribute 
	  # names since we will use them in later tests, and doesn't
	  # have any unexpected ones.
	_.assert_ (hasattr (_.o, 'Tables'))
	_.assertEquals (set (_.o.Tables.keys()), KwdsAttrs)

    def test002 (_):
	  # .attrs() method should return empty list for empty instance.
	_.assertEquals (_.o.attrs(), [])

    def test003 (_): 
	  # .recs() method should return an empty list for every attribute.
	for a in KwdsAttrs:
	    _.assertEquals (_.o.recs(a), [])

    def test004 (_):
	  # .recs() method should fail with an unknown attribute.
	_.assertRaises (AttributeError, _.o.recs, 'XXX')

    def test005 (_):
	values = (22,'abc','a description')
	rec = jdb.DbRow (values,('id','kw','descr'))
	_.o.add ('DIAL', rec)
	validate_rec (_, _.o, 'DIAL', *values)

    def test006 (_):
	values = (22,'abc','a description')
	_.o.add ('DIAL', values)
	validate_rec (_, _.o, 'DIAL', *values)

class Test_loadcsv (unittest.TestCase):

    def setUp (_):
	_.o = jdb.Kwds ('data/kwds')

    def test001 (_): 
	_.assert_ (hasattr (_.o, 'KINF'))
	_.assert_ (hasattr (_.o, 'GINF'))
	validate_rec (_, _.o, 'KINF', 13, 'xxx', 'line 1')
	validate_rec (_, _.o, 'KINF', 27, 'yy')
	validate_rec (_, _.o, 'KINF', 8, 'qq-r')
	validate_rec (_, _.o, 'GINF', 1, 'equ',  'equivalent')
	validate_rec (_, _.o, 'GINF', 2, 'lit',  'literaly')
	validate_rec (_, _.o, 'GINF', 3, 'fig',  'figuratively')
	validate_rec (_, _.o, 'GINF', 4, 'expl', 'explanatory')

    def test002 (_):
	_.assertEqual (_.o.attrs(), ['GINF', 'KINF'])

    def test003 (_):
	  # Check KINF records.
	expect = set (((13, 'xxx', 'line 1'),(27, 'yy', None),(8, 'qq-r', None)))
	recs = _.o.recs('KINF')
	_.assertEqual (len(recs), 3)
	comparable_recs = set ((tuple(x) for x in recs))
	_.assertEqual (comparable_recs, expect)

    def test004 (_): 
	  # Check GINF records.
	expect = set (((1,'equ','equivalent'),(2,'lit','literaly'),
		       (3,'fig','figuratively'),(4,'expl','explanatory')))
	recs = _.o.recs('GINF')
	_.assertEqual (len(recs), 4)
	comparable_recs = set ((tuple(x) for x in recs))
	_.assertEqual (comparable_recs, expect)

    def test005 (_):
	  # Check short-form kw->id attribute names.
	expected = set (
		'GINF_equ GINF_lit GINF_fig GINF_expl '
		'KINF_xxx KINF_yy KINF_qq_r'.split())
	actual = set ([x for x in _.o.__dict__.keys() if "_" in x])
	_.assertEqual (expected, actual)

    def test006 (_):
	  # Check values of short-form kw->id attributes.
	attrs = 'GINF_equ GINF_lit GINF_fig GINF_expl ' \
		'KINF_xxx KINF_yy KINF_qq_r'.split()
	expected = [1, 2, 3, 4, 13, 27, 8]
	actual = [getattr (_.o, x) for x in attrs if "_" in x]
	_.assertEqual (expected, actual)

class Test_missing_csv (unittest.TestCase):
    def test001 (_):
	_.assertRaises (IOError, jdb.Kwds, 'data/kwds/empty')
    def test002 (_):
	o = jdb.Kwds()
	expected = set (o.Tables.values()) - set (['kwginf', 'kwkinf'])
	missing = o.loadcsv ('data/kwds')
	_.assertEquals (expected, set (missing))
    def test003 (_):
	o = jdb.Kwds()
	missing = o.loadcsv ('data/kwds/full')
	_.assertEquals ([], missing)

#FIXME: need Test_missing_db.

class Test_loaddb (unittest.TestCase):

    def setUp (_):
	  #FIXME: use dedicated test database, or mock database
	if not Cursor: globalSetup()
	_.o = jdb.Kwds (Cursor)

    def test001 (_):
	expect = set (((1,'equ','equivalent'),(2,'lit','literaly'),
		       (3,'fig','figuratively'),(4,'expl','explanatory')))
	recs = _.o.recs('GINF')
	_.assertEqual (len(recs), 4)
	comparable_recs = set ((tuple(x) for x in recs))
	_.assertEqual (comparable_recs, expect)


def add_tests (cls):
	# This function will dynamically add test methods to 
	# class, 'cls'.  For each row in Data, a method will
	# be added to the class with name "test%s" where %s is
	# from column 0, and the method will call the function
	# "validate() with the remaining columns.

	for row in Current_kwds:
	    testid, domain, id, kw = row
	      # We use default argument values in the lambda expression
	      # they are bound when the "setattr(...lambda...) line
	      # is executed.  Otherwise, the lambda arguments will be
	      # evaluated when the lambda is, and will contain the 
	      # valuesthat the variable had when the loop was exited.
	    setattr (cls, 'test_%s' % testid, 
		     lambda self,d=domain,i=id,k=kw: validate_rec(self,self.o,d,i,k))

Test_actual_csv_test_object = None
class Test_actual_csv (unittest.TestCase):
    def setUp (_):
	global Test_actual_csv_test_object
	if Test_actual_csv_test_object is None:
	    Test_actual_csv_test_object = jdb.Kwds(jdb.std_csv_dir())
	_.o = Test_actual_csv_test_object
add_tests (Test_actual_csv)

Test_actual_db_test_object = None
class Test_actual_db (unittest.TestCase):
    def setUp (_):
	global Test_actual_db_test_object
	if Test_actual_db_test_object is None:
	    if not Cursor: globalSetup()
	    Test_actual_db_test_object = jdb.Kwds(Cursor)
	_.o = Test_actual_db_test_object
add_tests (Test_actual_db)

class Missing: pass
def validate_rec (_, o, domain, idx, kw, descr=Missing):
	  # Lookup a Kwds record and confirm that it matches
	  # expectations: that the same record is found by
	  # id number or kw string lookup, and the that id
	  # number, kw string, and (optionally) descr in the
	  # found record match what is expected (as given in
	  # the arguments).

	r1 = getattr (o, domain)[idx]
	r2 = getattr (o, domain)[kw]
	_.assertEqual (id(r1), id(r2))
	_.assertEqual (r1.id, idx)
	_.assertEqual (r1.kw, kw)
	if descr is not Missing: 
	    _.assertEqual (r1.descr, descr)
	   
if __name__ == '__main__': unittest.main()
