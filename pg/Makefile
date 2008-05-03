all: mkindex.sql drpindex.sql

mkindex.sql: mktables.sql
	python ../tools/mkindex.py c <mktables.sql >mkindex.sql

drpindex.sql: mktables.sql
	python ../tools/mkindex.py d <mktables.sql >drpindex.sql

.DELETE_ON_ERROR:
