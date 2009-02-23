all: mkindex.sql drpindex.sql mkperms.sql

mkindex.sql: mktables.sql
	python ../tools/mkindex.py c <mktables.sql >mkindex.sql

drpindex.sql: mktables.sql
	python ../tools/mkindex.py d <mktables.sql >drpindex.sql

mkperms.sql: mktables.sql
	python ../tools/mkperms.py mktables.sql mkviews.sql >mkperms.sql

.DELETE_ON_ERROR:
