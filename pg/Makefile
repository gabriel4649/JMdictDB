all: mkindex.sql drpindex.sql

mkindex.sql: mktables.sql
	perl edit.pl c <mktables.sql >mkindex.sql

drpindex.sql: mktables.sql
	perl edit.pl d <mktables.sql >drpindex.sql



