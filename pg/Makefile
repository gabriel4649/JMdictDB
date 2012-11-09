all: mkindex.sql drpindex.sql mkperms.sql

PYTHON = python3

mkindex.sql: mktables.sql
	 ../tools/mkindex.py c <mktables.sql >mkindex.sql

drpindex.sql: mktables.sql
	(PYTHON) ../tools/mkindex.py d <mktables.sql >drpindex.sql

mkperms.sql: mktables.sql
	(PYTHON) ../tools/mkperms.py mktables.sql mkviews.sql >mkperms.sql

.DELETE_ON_ERROR:
