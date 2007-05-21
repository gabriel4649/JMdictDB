all: mkindex.sql drpindex.sql

mkindex.sql: mktables.sql
	perl ../tools/mkindex.pl c <mktables.sql >mkindex.sql

drpindex.sql: mktables.sql
	perl ../tools/mkindex.pl d <mktables.sql >drpindex.sql

.DELETE_ON_ERROR:
