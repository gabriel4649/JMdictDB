This directory contains update files that are used for migrating an 
existing JMdictDB database to a state matching that which would be 
created by a new install.  It is only necessary to apply those updates
that are more recent than the JMdictDB software used to create the
database initially.  That is, when a new database is created it 
already incorporates all updates to that point in time.

Generally the updates are applied using Postgresql's 'psql' tool.
It should be run as the database user (using the -U option) that 
owns the objects in the database (typically "jmdictdb") and specify
the database to update (typically "jmdict"):

  $ psql -d jmdict -U jmdictdb -f patches/024-20c2fe.sql

However, there may be exceptions which will be documented in the
comments in the file so you should look at the contents of the 
update file before applying it.
 
Updates will generally be applied in numerical order although
some may be optional.

Updates with a "s" after the leading three digits are updates 
to the session database (which is independent of the main jmdict 
database.)


Old format:
-----------
Up through 2017 (001.sql through 023.sql) updates were applied using 
the program tools/patchdb.py.  This tool is no longer used but may 
still be recovered from the source code repository revision:
  hg-20180408-d8e3d85d26d2
