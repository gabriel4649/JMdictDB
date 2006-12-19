# How to import a JMdict XML file into Postgresql...
#
# Depending of configuration and defaultsm you may
# need to use additional arguments such as "-U postgres"
# on the psql commands.

psql -d postgres -f ../pg/reload.sql		#Create db, make tables.
perl load_jmdict.pl -o jmdict.dmp jmdict.xml	#Create jmdict pg load file.
psql -d jmdict <jmdict.dmp			#Load into database.
psql -d jmdict -f ../pg/postload.sql		#Make indexes, fks, etc.
psql -d jmdict -f ../pg/reslvxref.sql		#Resolve xrefs.
rm jmdict.dmp					#Delete uneeded big file.

