all: mkindex.sql drpindex.sql

mkindex.sql: mktables.sql
	perl mkindex.pl c <mktables.sql >mkindex.sql

drpindex.sql: mktables.sql
	perl mkindex.pl d <mktables.sql >drpindex.sql

.DELETE_ON_ERROR:
