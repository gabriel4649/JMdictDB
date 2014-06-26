This directory contains patch files that are used for 
migrating an existing JMdictDB database to a state
matching that which would be created by a new install.

These scripts should be applied using the program

  tools/patchdb.py

Patchdb.should be run from the parent of the tools 
directory in order to automatically find this patches
subdirectory; else provide the --dir option).

Run "tools/patchdb.py --help" for more details.

When creating a new patch file, the patch level in 
pg/mktables.sql should be simultaneously updated to
match.
