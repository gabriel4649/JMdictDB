# How to import a JMdict XML file into Postgresql...
#
# It is assumed that when you execute these commands,
# you start cd'd to the parent directory of the perl
# and pg subdirectories, and that is the location of
# in input file, jmdict.xml.
#
# Depending of configuration and defaults you may
# need to modify some arguments such as "-U postgres"
# on the psql commands, or the input and output file
# names in the load_jmdict.pl command.

cd perl
perl load_jmdict.pl -o ../jmdict.dmp ../jmdict.xml

cd ../pg
psql -U postgres -f reload.sql
psql -U postgres -d jmdict <../jmdict.dmp
psql -U postgres -d jmdict -f postload.sql

#rm ../jmdict.dmp	# Optional
