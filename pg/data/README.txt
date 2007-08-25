pg/data/

The files in this directory hold data for the jmdict 
keywords.  This data is both loaded into the database
kw* tables, and used to generate perl contstants that
are included by various perl scripts.  After any changes 
are made to the .csv files here, "make" should be run
in perl/lib/ to update those constants (in perl/lib/-
kwstatic.com).

There is a similar but not identical set of keywords
that are maintained in the file 

  perl/lib/jmdictxml.pm

Those are used when parsing the jmdict xml files.
When a kw id number is changed/added/deleted here.
a corresponding change should be made in perl/lib/-
jmdictxml.pm, if the line represents an entity or
text string that is used in the jmdict or jmnedict
xml files.

The keywords and description text in these file do 
not need to match what is used in the jmdict xml file, 
although by convention, they do.  However the id number 
in this file must be the same as the id number used in 
the corresponding line in jmdictxml.pm.
