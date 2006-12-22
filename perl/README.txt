# How to import a JMdict XML file into Postgresql...
#
# Execute the commans in this script while cd'd into 
# the pg/ subdirectory.
#
# Depending of configuration and defaults you may
# need to use additional arguments such as "-U postgres"
# on the psql commands.

psql -d postgres -f reload.sql		#Create db, make tables.
cd ../perl
perl ../perl/load_jmdict.pl -o jmdict.dmp ../jmdict.xml	#Create jmdict pg load file.
psql -d jmdict <jmdict.dmp		#Load into database.
rm jmdict.dmp				#Delete uneeded big file.
cd ../pg
psql -d jmdict -f postload.sql		#Make indexes, fks, etc.
