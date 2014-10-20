PYTHON = python3

all: fkcreate.sql mkperms.sql

fkcreate.sql: mktables.sql ../tools/mkcreatefks.sql ../tools/mkdropfks.sql
	  # Create a temporary JMdictDB database named "jmtmp" that we
	  #  will use to extract information about the JMdictDB foreign
	  #  keys and indexes from.
	-dropdb jmtmp
	cd .. && make DB=jmtmp jmnew >/dev/null
	  # Generate scripts that we can use later on a different database
	  #  to drop and recreate the indexes and foreign keys.
	psql $(PG_HOST) -U $(USER) -d jmtmp -f ../tools/mkcreatefks.sql >fkcreate.sql
	psql $(PG_HOST) -U $(USER) -d jmtmp -f ../tools/mkdropfks.sql   >fkdrop.sql
	-dropdb jmtmp

mkperms.sql: mktables.sql
	$(PYTHON) ../tools/mkperms.py mktables.sql mkviews.sql >mkperms.sql

.DELETE_ON_ERROR:
