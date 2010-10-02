psql -U jmdictdb -d jmdict -f 003_01.sql
psql -U jmdictdb -d jmdict -f ../pg/mkviews.sql
psql -U jmdictdb -d jmdict -f ../pg/mkviews2.sql
