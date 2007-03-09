# $Revision$
# $Date$
#-----------------------------------------------------------------------
# This script is a brief tutorial intended to introduce some
# of the jmdict library functions and data structures.
#
# It is intended tp be run interactively using the perl debugger,
# which will allow one to execute the code step-by-step, and
# examine the jmdict data data structures in more detail along
# the way.
#
# To run under the debugger:
#
#   perl -d tut.pl
#
# For details on using the debugger see "man perldbg".
# 
# The most useful commands (in the context of this tutorial) are:
#
#   n -- execute the next statement, skipping over subroutine calls.
#   s -- execute the next statement, stepping into any subroutine calls.
#   x expression -- Print information about and the value of the 
#	given expression.  Expression me be a simple variable or
#	something more complex.
#
#-----------------------------------------------------------------------

# There are seveval perl modules we will need.  Encode provides
# functions for dealing with charset/encoding issues.  DBI is
# Perl's standard database interface.  DBI in turn will use 
# module DBD:Pg to talk to Postgresql but we don't need to 
# load that one explicitly.

use Encode;  use DBI;

# Assuming you are running this stript from the source code
# distribution's doc/ directory, we need to tell Perl where 
# to find the jmdict library modules, by adding that directory
# to the module search path, @INC.

BEGIN {push (@INC, "../perl/lib");}

# Now we and tell Perl to use the jmdict.pm module.

use jmdict;  

# First thing to do is to set the encoding to use when writing
# to stdout or stderr.  This is important since we will be printing
# Japanese text strings.  "sjis" is appropriate for Microsoft
# Windows systems with a Japanese locale.  Linux/Unix users with
# a ja_JP.UTF-8 environment will want "utf8".  Others may want
# "euc-jp".  Edit this file and change the '$enc = "sjis"' line
# below as appropriate.
# 
# $DB::OUT is the file handle used by the Perl debugger.  If it is
# referenced without the debugger active, a fatal error is generated.
# So we execute uin an eval to ignore the error and allow execution
# to continue when the debugger is not active.

	$enc = "sjis";
	binmode(STDOUT, ":encoding($enc)");
	binmode(STDERR, ":encoding($enc)");
	eval { binmode($DB::OUT, ":encoding($enc)"); }; $dbh=$DB::OUT;

# Next, open a connection to the database.  "jmdict"
# is the database name.  You can append ",host=<server_running postgresql>"
# to that string if the database is running of a different machine.
# "postgres" is the postgresql username to use, the argument after that
# is the password for that user.  Adjust as neccessary.
# We get back a handle ($dbh) that will be used whenever we access the 
# database.

	$dbh = DBI->connect("dbi:Pg:dbname=jmdict", "postgres", "", 
			{ PrintWarn=>0, RaiseError=>1, AutoCommit=>0 } );

# Following is needed in order to get unicode back from the server
# rather than bytes.

	$dbh->{pg_enable_utf8} = 1;

# Kwds() is a function in module jmdict.  It is used in allmost 
# every jmdictdb script.  It reads all the kw* tables, and returns
# a data structure containing their information.  By convention
# I typically asssign that datastructure to a global variable
# $::KW to make it easily available throughout the programs.

	$::KW = Kwds ($dbh);

# At this point, were ready do do whatever we need to do with the
# database.

	print "Database connection ready...\n";
