####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package jbparser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package Parse::Yapp::Driver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.05';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------


#line 1 "jbparser.yp"

#######################################################################
#   This file is part of JMdictDB. 
#   Copyright (c) 2006,2007 Stuart McGraw 
# 
#   JMdictDB is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published 
#   by the Free Software Foundation; either version 2 of the License, 
#   or (at your option) any later version.
# 
#   JMdictDB is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with JMdictDB; if not, write to the Free Software Foundation,
#   51 Franklin Street, Fifth Floor, Boston, MA  02110#1301, USA
#######################################################################

#@VERSION = (substr('$Revision$',11,-2), \
#	    substr('$Date$',7,-11));

# To-do:
#   lsrc syntax needed for wasei, part flags.
#   Need to be able to specify language of a plain gloss.
#   Need to be able to specify an xref by seq number.
#     (but what about multiple src's, or same seq with
#     different stat's?  Could we use id number?)
#   semicolon (we use as item separator in kanji and
#     reading sections) is used in kanj text in 4 example 
#     sentences.
#   use of WS to sepatate kanji and reading sections
#     is a problem because space occurs in example
#     sentences' kanji (although most occurances seem
#     to be clearly erroneous, or occur after a sentence
#     terminator (periiod, question mark, etc).  

use strict; #use warnings; 
BEGIN {push (@INC, "../perl/lib");}
use utf8; use jmdict; 

use kwstatic;
# Make "nokanji" a psuedo-keyword...
$::KW = $kwstatic::Kwds;
$::KW->{RESTR} = {'nokanji'=>{id=>'nokanji', kw=>'nokanji'}};

use Dumpvalue;		# For debugging.
$::D = new Dumpvalue;



sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'RTEXT' => 5,
			'KTEXT' => 8
		},
		GOTOS => {
			'entr' => 4,
			'preentr' => 2,
			'rdngitem' => 1,
			'kanjsect' => 6,
			'rdngsect' => 3,
			'kanjitem' => 7
		}
	},
	{#State 1
		DEFAULT => -8
	},
	{#State 2
		DEFAULT => -1
	},
	{#State 3
		ACTIONS => {
			'SNUM' => 9,
			'SEMI' => 10
		},
		GOTOS => {
			'senses' => 12,
			'sense' => 11
		}
	},
	{#State 4
		ACTIONS => {
			'' => 13
		}
	},
	{#State 5
		ACTIONS => {
			'BRKTL' => 16
		},
		DEFAULT => -10,
		GOTOS => {
			'taglist' => 14,
			'taglists' => 15
		}
	},
	{#State 6
		ACTIONS => {
			'RTEXT' => 5,
			'SEMI' => 17
		},
		GOTOS => {
			'rdngitem' => 1,
			'rdngsect' => 18
		}
	},
	{#State 7
		DEFAULT => -4
	},
	{#State 8
		ACTIONS => {
			'BRKTL' => 16
		},
		DEFAULT => -6,
		GOTOS => {
			'taglist' => 14,
			'taglists' => 19
		}
	},
	{#State 9
		DEFAULT => -14,
		GOTOS => {
			'@1-1' => 20
		}
	},
	{#State 10
		ACTIONS => {
			'RTEXT' => 5
		},
		GOTOS => {
			'rdngitem' => 21
		}
	},
	{#State 11
		DEFAULT => -12
	},
	{#State 12
		ACTIONS => {
			'SNUM' => 9
		},
		DEFAULT => -2,
		GOTOS => {
			'sense' => 22
		}
	},
	{#State 13
		DEFAULT => 0
	},
	{#State 14
		DEFAULT => -22
	},
	{#State 15
		ACTIONS => {
			'BRKTL' => 16
		},
		DEFAULT => -11,
		GOTOS => {
			'taglist' => 23
		}
	},
	{#State 16
		DEFAULT => -24,
		GOTOS => {
			'@2-1' => 24
		}
	},
	{#State 17
		ACTIONS => {
			'KTEXT' => 8
		},
		GOTOS => {
			'kanjitem' => 25
		}
	},
	{#State 18
		ACTIONS => {
			'SNUM' => 9,
			'SEMI' => 10
		},
		GOTOS => {
			'senses' => 26,
			'sense' => 11
		}
	},
	{#State 19
		ACTIONS => {
			'BRKTL' => 16
		},
		DEFAULT => -7,
		GOTOS => {
			'taglist' => 23
		}
	},
	{#State 20
		ACTIONS => {
			'GTEXT' => 29,
			'BRKTL' => 16
		},
		GOTOS => {
			'sensitems' => 28,
			'taglist' => 27,
			'sensitem' => 31,
			'glossset' => 30
		}
	},
	{#State 21
		DEFAULT => -9
	},
	{#State 22
		DEFAULT => -13
	},
	{#State 23
		DEFAULT => -23
	},
	{#State 24
		ACTIONS => {
			'TEXT' => 33
		},
		GOTOS => {
			'tagitem' => 34,
			'tags' => 32
		}
	},
	{#State 25
		DEFAULT => -5
	},
	{#State 26
		ACTIONS => {
			'SNUM' => 9
		},
		DEFAULT => -3,
		GOTOS => {
			'sense' => 22
		}
	},
	{#State 27
		DEFAULT => -19
	},
	{#State 28
		ACTIONS => {
			'GTEXT' => 29,
			'BRKTL' => 16
		},
		DEFAULT => -15,
		GOTOS => {
			'taglist' => 27,
			'sensitem' => 35,
			'glossset' => 30
		}
	},
	{#State 29
		DEFAULT => -20
	},
	{#State 30
		ACTIONS => {
			'SEMI' => 36
		},
		DEFAULT => -18
	},
	{#State 31
		DEFAULT => -16
	},
	{#State 32
		ACTIONS => {
			'COMMA' => 37
		},
		DEFAULT => -25,
		GOTOS => {
			'@3-3' => 38
		}
	},
	{#State 33
		ACTIONS => {
			'EQL' => 39
		},
		DEFAULT => -29
	},
	{#State 34
		DEFAULT => -27
	},
	{#State 35
		DEFAULT => -17
	},
	{#State 36
		ACTIONS => {
			'GTEXT' => 40
		}
	},
	{#State 37
		ACTIONS => {
			'TEXT' => 33
		},
		GOTOS => {
			'tagitem' => 41
		}
	},
	{#State 38
		ACTIONS => {
			'BRKTR' => 42
		}
	},
	{#State 39
		ACTIONS => {
			'TEXT' => 44,
			'RTEXT' => 45,
			'KTEXT' => 48
		},
		GOTOS => {
			'jtext' => 46,
			'jitems' => 47,
			'jitem' => 43
		}
	},
	{#State 40
		DEFAULT => -21
	},
	{#State 41
		DEFAULT => -28
	},
	{#State 42
		DEFAULT => -26
	},
	{#State 43
		DEFAULT => -34
	},
	{#State 44
		ACTIONS => {
			'COLON' => 49
		},
		DEFAULT => -30
	},
	{#State 45
		DEFAULT => -39
	},
	{#State 46
		ACTIONS => {
			'BRKTL' => 51
		},
		DEFAULT => -36,
		GOTOS => {
			'slist' => 50
		}
	},
	{#State 47
		ACTIONS => {
			'SEMI' => 52
		},
		DEFAULT => -33
	},
	{#State 48
		ACTIONS => {
			'SLASH' => 53
		},
		DEFAULT => -38
	},
	{#State 49
		ACTIONS => {
			'TEXT' => 54
		},
		DEFAULT => -31
	},
	{#State 50
		DEFAULT => -37
	},
	{#State 51
		ACTIONS => {
			'TEXT' => 56
		},
		GOTOS => {
			'snums' => 55
		}
	},
	{#State 52
		ACTIONS => {
			'RTEXT' => 45,
			'KTEXT' => 48
		},
		GOTOS => {
			'jtext' => 46,
			'jitem' => 57
		}
	},
	{#State 53
		ACTIONS => {
			'RTEXT' => 58
		}
	},
	{#State 54
		DEFAULT => -32
	},
	{#State 55
		ACTIONS => {
			'BRKTR' => 60,
			'COMMA' => 59
		}
	},
	{#State 56
		DEFAULT => -42
	},
	{#State 57
		DEFAULT => -35
	},
	{#State 58
		DEFAULT => -40
	},
	{#State 59
		ACTIONS => {
			'TEXT' => 61
		}
	},
	{#State 60
		DEFAULT => -41
	},
	{#State 61
		DEFAULT => -43
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'entr', 1,
sub
#line 56 "jbparser.yp"
{ dbgprt (1, "preentr -> entr");
				  my ($e) = $_[1];
				    # Set record numbers in child lists because we will
				    # will use those numbers in mk_restrs().
				  setkeys ($e, 1); 
				    # The reading and sense restrictions here are simple
				    # lists of text strings that give the allowed readings
				    # or kanji.  mk_restrs() converts those to the canonical
				    # format which uses the index number of the disallowed 
				    # readings or kanji. 
				  if (!mk_restrs ("_RESTR", $e->{_rdng}, "rdng", $e->{_kanj}, "kanj")) {
				    $_[0]->YYError(); }
				  if (!mk_restrs ("_STAGK", $e->{_sens}, "sens", $e->{_kanj}, "kanj")) {
				    $_[0]->YYError(); }
				  if (!mk_restrs ("_STAGR", $e->{_sens}, "sens", $e->{_rdng}, "rdng")) {
				    $_[0]->YYError(); }
				    # Confirm the validity of all the xrefs.
				  #rslv_xrefs (); 
				  $e; }
	],
	[#Rule 2
		 'preentr', 2,
sub
#line 78 "jbparser.yp"
{ dbgprt (1, "rdngsect senses -> preentr");
				  {_rdng=>$_[1], _sens=>$_[2]}; }
	],
	[#Rule 3
		 'preentr', 3,
sub
#line 81 "jbparser.yp"
{ dbgprt (1, "kanjsect rdngsect senses -> preentr");
				  {_kanj=>$_[1], _rdng=>$_[2], _sens=>$_[3]}; }
	],
	[#Rule 4
		 'kanjsect', 1,
sub
#line 86 "jbparser.yp"
{ dbgprt (1, "kanjitem -> kanjsect"); 
				  [$_[1]]; }
	],
	[#Rule 5
		 'kanjsect', 3,
sub
#line 89 "jbparser.yp"
{ dbgprt (1, "kanjsect SEMI kanjitem -> kanjsect");
				  push (@{$_[1]}, $_[3]);
				  $_[1]; }
	],
	[#Rule 6
		 'kanjitem', 1,
sub
#line 95 "jbparser.yp"
{ dbgprt (1, "KTEXT -> kanjitem"); 
				  {txt=>$_[1]}; }
	],
	[#Rule 7
		 'kanjitem', 2,
sub
#line 98 "jbparser.yp"
{ dbgprt (1, "KTEXT taglists -> kanjitem"); 
				  my ($kanj) = {txt=>$_[1]};
				  if (!bld_kanj ($kanj, $_[2])) { $_[0]->YYError(); }
				  $kanj; }
	],
	[#Rule 8
		 'rdngsect', 1,
sub
#line 105 "jbparser.yp"
{ dbgprt (1, "rdngitem -> rdngsect"); 
				  [$_[1]]; }
	],
	[#Rule 9
		 'rdngsect', 3,
sub
#line 108 "jbparser.yp"
{ dbgprt (1, "rdngsect SEMI rdngitem -> rdngsect"); 
				  push (@{$_[1]}, $_[3]);
				  $_[1]; }
	],
	[#Rule 10
		 'rdngitem', 1,
sub
#line 114 "jbparser.yp"
{ dbgprt (1, "RTEXT -> rdngitem"); 
				  {txt=>$_[1]}; }
	],
	[#Rule 11
		 'rdngitem', 2,
sub
#line 117 "jbparser.yp"
{ dbgprt (1, "RTEXT taglists -> rdngitem");
				  my ($rdng) = {txt=>$_[1]};
				  if (!bld_rdng ($rdng, $_[2])) { $_[0]->YYError(); }
				  $rdng; }
	],
	[#Rule 12
		 'senses', 1,
sub
#line 124 "jbparser.yp"
{ dbgprt (1, "sense -> senses"); 
				  [$_[1]]; }
	],
	[#Rule 13
		 'senses', 2,
sub
#line 127 "jbparser.yp"
{ dbgprt (1, "senses sense -> senses"); 
				  push (@{$_[1]}, $_[2]);
				  $_[1]; }
	],
	[#Rule 14
		 '@1-1', 0,
sub
#line 132 "jbparser.yp"
{_setlexstate(2)}
	],
	[#Rule 15
		 'sense', 3,
sub
#line 133 "jbparser.yp"
{ dbgprt (1, "SNUM sensitems -> sense");
				  my ($sens) = {};
				  if (!bld_sens ($sens, $_[3])) { $_[0]->YYError(); }
				  $sens; }
	],
	[#Rule 16
		 'sensitems', 1,
sub
#line 140 "jbparser.yp"
{ dbgprt (1, "sensitem -> sensitems"); 
				  $_[1]; }
	],
	[#Rule 17
		 'sensitems', 2,
sub
#line 143 "jbparser.yp"
{ dbgprt (1, "sensitems sensitem -> sensitems"); 
				  push (@{$_[1]}, @{$_[2]});
				  $_[1]; }
	],
	[#Rule 18
		 'sensitem', 1,
sub
#line 149 "jbparser.yp"
{ dbgprt (1, "glossset -> sensitem");
				  $_[1]; }
	],
	[#Rule 19
		 'sensitem', 1,
sub
#line 152 "jbparser.yp"
{ dbgprt (1, "taglist -> sensitem");
				  $_[1]; }
	],
	[#Rule 20
		 'glossset', 1,
sub
#line 157 "jbparser.yp"
{ dbgprt (1, "GTEXT -> glossset"); 
				  [["gloss", gcleanup ($_[1])]]; }
	],
	[#Rule 21
		 'glossset', 3,
sub
#line 160 "jbparser.yp"
{ dbgprt (1, "glossset SEMI GTEXT -> glossset");
				  push (@{$_[1]}, ["gloss", gcleanup ($_[3])]);
				  $_[1]; }
	],
	[#Rule 22
		 'taglists', 1,
sub
#line 166 "jbparser.yp"
{ dbgprt (1, "taglist -> taglists");
				  $_[1]; }
	],
	[#Rule 23
		 'taglists', 2,
sub
#line 169 "jbparser.yp"
{ dbgprt (1, "taglists taglist -> taglists");
				  push (@{$_[1]}, @{$_[2]}); 
				  $_[1]; }
	],
	[#Rule 24
		 '@2-1', 0,
sub
#line 174 "jbparser.yp"
{_pushlexstate(1)}
	],
	[#Rule 25
		 '@3-3', 0,
sub
#line 174 "jbparser.yp"
{_poplexstate()}
	],
	[#Rule 26
		 'taglist', 5,
sub
#line 175 "jbparser.yp"
{ dbgprt (1, "BRKTL tags BRKTR -> taglist");
				  $_[3]; }
	],
	[#Rule 27
		 'tags', 1,
sub
#line 180 "jbparser.yp"
{ dbgprt (1, "tagitem -> tags"); 
				  [$_[1]]; }
	],
	[#Rule 28
		 'tags', 3,
sub
#line 183 "jbparser.yp"
{ dbgprt (1, "tags COMMA tagitem -> tags");
				  push (@{$_[1]}, $_[3]);
				  $_[1]; }
	],
	[#Rule 29
		 'tagitem', 1,
sub
#line 189 "jbparser.yp"
{ dbgprt (1, "TEXT -> tagitem");
				  my ($x) = lookup_tag ($_[1]);
				  if ($x == -1) { 
				    error ("Unknown keyword: '$_[1]'");
				    $_[0]->YYError(); } 
				  if ($x == -2) { 
				    error ("Ambiguous keyword: '$_[1]'");
				    $_[0]->YYError(); }
				  $x; }
	],
	[#Rule 30
		 'tagitem', 3,
sub
#line 200 "jbparser.yp"
{ dbgprt (1, "TEXT EQL TEXT -> tagitem"); 
				  return [$_[1],$_[3],1] if ($_[1] eq "note" or $_[1] eq "lit" or $_[1] eq "expl");
				  return [$_[1],$_[3],1] if ($_[1] eq "lsrc");
				  my ($x) = lookup_tag ($_[3], $_[1]);
				  if ($x == -1) {
				    error ("Unknown $_[1] keyword: '$_[3]'");
				    $_[0]->YYError(); }
				  if ($x == -3) { 
				    error ("Unknown keyword type: '$_[1]'");
				    $_[0]->YYError(); }
				  $x; }
	],
	[#Rule 31
		 'tagitem', 4,
sub
#line 213 "jbparser.yp"
{ dbgprt (1, "TEXT EQL TEXT COLON -> tagitem"); 
				  if ($_[1] ne "lsrc") {
				    error ("Keyword must be \"lsrc\"");
				    $_[0]->YYError (); }
				  my ($la) = $::KW->{LANG}{$_[3]}{id};
				  if (!$la) {
				    error ("Unrecognised language '$_[3]'");
				    $_[0]->YYError (); }
				  ["lsrc", undef, $la]; }
	],
	[#Rule 32
		 'tagitem', 5,
sub
#line 224 "jbparser.yp"
{ dbgprt (1, "TEXT EQL TEXT COLON TEXT -> tagitem"); 
				  
				  if ($_[1] ne "lsrc" and $_[1] ne "lit" and $_[1] ne "expl") {
				    error ("Keyword not \"lsrc\", \"lit\", or \"expl\"");
				    $_[0]->YYError (); }
				  my ($la) = $::KW->{LANG}{$_[3]}{id};
				  if (!$la) {
				    error ("Unrecognised language '$_[3]'");
				    $_[0]->YYError (); }
				  ["lsrc", $_[5], $la]; }
	],
	[#Rule 33
		 'tagitem', 3,
sub
#line 236 "jbparser.yp"
{ dbgprt (1, "TEXT EQL jitems -> tagitem"); 
				  if ($_[1] ne "restr" and $_[1] ne "see" and $_[1] ne "ant") {
				    error ("Keyword not \"restr\", \"see\", or \"ant\"");
				    $_[0]->YYError (); }
				    ;
				  if ($_[1] eq "restr") { $_[1] = "RESTR"; }
				  [$_[1], $_[3]]; }
	],
	[#Rule 34
		 'jitems', 1,
sub
#line 246 "jbparser.yp"
{ dbgprt (1, "jitem -> jitems"); 
				  [$_[1]]; }
	],
	[#Rule 35
		 'jitems', 3,
sub
#line 249 "jbparser.yp"
{ dbgprt (1, "jitems jitem -> jitems");
				  push (@{$_[1]}, $_[3]);
				  $_[1]; }
	],
	[#Rule 36
		 'jitem', 1,
sub
#line 255 "jbparser.yp"
{ dbgprt (1, "jtext -> jitem");
				   $_[1]; }
	],
	[#Rule 37
		 'jitem', 2,
sub
#line 258 "jbparser.yp"
{ dbgprt (1, "jtexts -> jitem");
				  $_[1]->[2] = $_[2];  
				  $_[1]; }
	],
	[#Rule 38
		 'jtext', 1,
sub
#line 264 "jbparser.yp"
{ dbgprt (1, "KTEXT -> jtext"); 
				  [$_[1],undef,undef]; }
	],
	[#Rule 39
		 'jtext', 1,
sub
#line 267 "jbparser.yp"
{ dbgprt (1, "RTEXT -> jtext"); 
				  [undef,$_[1],undef]; }
	],
	[#Rule 40
		 'jtext', 3,
sub
#line 270 "jbparser.yp"
{ dbgprt (1, "KTEXT SEMI RTEXT-> jtext"); 
				  [$_[1],$_[3],undef]; }
	],
	[#Rule 41
		 'slist', 3,
sub
#line 275 "jbparser.yp"
{ dbgprt (1, "BRKTL snums BRKTR -> slist"); 
				  $_[2]; }
	],
	[#Rule 42
		 'snums', 1,
sub
#line 280 "jbparser.yp"
{ dbgprt (1, "TEXT -> snums"); 
				  my $x = int ($_[1]);
				  if ($x<=0 or $x>99) {
				    error ("Invalid sense number '$x', must be between 1 and 99");
				    $_[0]->YYError(); }
				  [$x]; }
	],
	[#Rule 43
		 'snums', 3,
sub
#line 287 "jbparser.yp"
{ dbgprt (1, "snums COMMA TEXT -> snums"); 
				  my $x = int ($_[3]);
				  if ($x<=0 or $x>99) {
				    error ("Invalid sense number '$x', must be between 1 and 99");
				    $_[0]->YYError(); }
				  push (@{$_[1]}, $x);
				  $_[1]; }
	]
],
                                  @_);
    bless($self,$class);
}

#line 297 "jbparser.yp"

    sub resolv_xrefs { my ($dbh, $e) = @_;
	# An xref given by the user is parsed into a 4-item
	# list:
	#    0 -- Xref type per $::KW->{XREF}.
	#    1 -- Kanji text
	#    2 -- Reading text
	#    3 -- Ref to list of integers, each is a sense
	#           number.
	# Any of the last three elements may be undefined
	# although at least one of the kanji and reading
	# elements will be non-undefined.

	my ($s, $x, $xrefs);
	foreach $s (@{$e->{_sens}}) {
	    foreach $x (@{$s->{_XREF}}) {
		$xrefs = resolv_xref ($dbh, $x->[1], $x->[2],
				      $x->[3], $x->[0], 1, 1);
		if (!$s->{_erefs}) { $s->{_erefs} = []; }
		push (@{$s->{_erefs}}, @$xrefs); }
	    delete ($s->{_XREF}); } }

    sub lookup_tag { my ($tag, $typ) = @_;
	# Lookup $tag (given as a string) if the keyword tables
	# and return the kw id number.  If $typ is given (also 
	# a string and usually capitalized), it gives the kw 
	# domain (e.g. FREQ, KINF, etc) and $tag is looked up
	# in that domain.  If not given, $tag is looked for in
	# every domain.
	# For other than FREQ tags the return value is a 2-tuple:
	# the domain and the kw id number.  For FREQ tags, it is
	# a 3-tuple: the domain, the kw id number and the freq
	# value.
	# If the tag is not found, a scalar -1 is returned.

	my ($t, $x, $fval, $tx);
	if ($typ) {
	    $t = uc ($typ);
	    return -3 if (!$::KW->{$t});
	    if ($t eq "FREQ" and ($tag =~ m/^([^0-9]+)(\d+)$/)) {
		$tag = $1; $fval = $2; }
	    $x = $::KW->{$t}{$tag}{id}; }
	else {
	    foreach $tx (keys (%{$::KW})) {
		$t = $tx;
	        $x = $::KW->{$t}{$tag}{id};
	        last if ($x); }
	    #return -2 if # ambiguous.
	    if (!$x and ($tag =~ m/^([^0-9]+)(\d+)$/)) {  
		$x = $::KW->{FREQ}{$1}{id};  $fval = $2; $t = "FREQ"} }
	return -1 if (!$x);
	return [$t, $x, $fval] if ($t eq "FREQ");
	return [$t, $x]; }

    sub bld_sens { my ($sens, $taglist) = @_;
	# Build a sense record.  We are given a list of sense items
	# in @$taglist.  These are not just tags (keyword records) but
	# anything that goes into a sense: glosses, lsource records,
	# stagr/k restrictions, etc.  Each of these items is an n-tuple
	# with the first element being a string that indicates the type
	# of item, and the remaining elements providing the items' data.
	# Our job is to iterate though this list, and put each item 
	# on the appropriate sense list: e.g. all the "gloss" items go 
	# into the list @{$sens->{_gloss}}, all the "POS" keyword items 
	# go on @{$sens->{_pos}}, etc.
 
	my ($s, $t, $typ, $errs, $jitem, $kw);
	foreach $t (@$taglist) {
	    $typ = shift (@$t);		# Get the item type.
	    if ($typ eq "POS" or $typ eq "MISC" or $typ eq "FLD" or $typ eq "DIAL") {
	        append ($sens, "_".lc($typ), {kw=>$t->[0]}); }
	    elsif ($typ eq "RESTR") { 
		# We can't create real @{_stagk} or @{_stagr} lists here because
		# the readings and kanji we are given by the user are allowed ones,
		# but we need to store disallowed ones.  To get the disallowed ones,
		# we need access to all the readings/kanji for this entry and we 
		# don't have that here.  So we do what checking we can. and save 
		# the texts as given, and will fix later after the full entry is 
		# built and we have access to the entry's readings and kanji.
		foreach $jitem (@{$t->[0]}) {
		    if (($jitem->[0] and $jitem->[1]) or 
			     (!$jitem->[0] and !$jitem->[1]) or $jitem->[3]) { 
			error ("Sense restrictions must have a reading or kanji (but not both): "
			       . fmt_jitem (@$jitem));
			$errs++; }
		    if ($jitem->[0]) { append ($sens, "_STAGK", $jitem->[0]); }
		    if ($jitem->[1]) { append ($sens, "_STAGR", $jitem->[1]); } } }
	    elsif ($typ eq "lsrc")  { append ($sens, "_lsrc",  {txt=>$t->[0], lang=>($t->[1] || 1), part=>0, wasei=>0}); }
	    elsif ($typ eq "gloss") { append ($sens, "_gloss", {txt=>$t->[0], lang=>1, ginf=>1}); }
	    elsif ($typ eq "lit")   { append ($sens, "_gloss", {txt=>$t->[0], lang=>($t->[1] || 1), ginf=>$KWGINF_lit}); }
	    elsif ($typ eq "expl")  { append ($sens, "_gloss", {txt=>$t->[0], lang=>($t->[1] || 1), ginf=>$KWGINF_expl}); }
	    elsif ($typ eq "id")    { append ($sens, "_gloss", {txt=>$t->[0], lang=>($t->[1] || 1), ginf=>$KWGINF_id}); }
	    elsif ($typ eq "note")  { 
		if ($sens->{notes}) { error ("Only one sense note allowed"); $errs++ }
		$sens->{notes} = $t->[0]; }
	    elsif ($typ eq "see" or $typ eq "ant") { 
		foreach $jitem (@{$t->[0]}) {
		    $kw = $::KW->{XREF}{$typ}{id};
		    die "Unable to find xref type '$typ' in KW table!" if (!$kw);
		    append ($sens, "_XREF", [$kw, @$jitem]); } }
	    else { error ("Cannot use '$typ' tag in a sense"); $errs++; } }
	return $errs ? undef : $sens; }

    sub bld_rdng { my ($r, $taglist) = @_;
	my ($typ, $t, $jitem, $errs, $nokanj);
	foreach $t (@$taglist) {
	    $typ = shift (@$t);
	    if ($typ eq "RINF") { append ($r, "_rinf", {kw=>$t->[0]}); }
	    elsif ($typ eq "FREQ") { append ($r, "_rfreq", {kw=>$t->[0], value=>$t->[1]}); }
	    elsif ($typ eq "RESTR") {
		# We can't generate real restr records here because the real
		# records are the disallowed kanji.  We have the allowed
		# kanji here and need the set of all kanji in order to get
		# the disallowed set, and we don't have that now.  So we 
		# just save the allowed kanji as given, and will convert it
		# after the full entry is build and we have all the info we
		# need.
		if ($t->[0] eq "nokanji") { 
		    $nokanj = 1; 
		    $r->{_NOKANJI} = 1;
		    next; }
		foreach $jitem (@{$t->[0]}) {
		    if (!$jitem->[0] or $jitem->[1] or $jitem->[3]) { 
			error ("Reading restrictions must be kanji only: " . fmt_jitem (@$jitem));
			$errs++; }
		    append ($r, "_RESTR", $jitem->[0]); }
		if ($r->{_RESTR} and $nokanj) { 
		    error ("Can't use both kanji and 'nokanji' in 'restr' tags");
		    $errs++; } }
	    else { error ("Cannot use '$typ' tag in a reading"); $errs++; } }
	return $errs ? undef : $r; }

    sub bld_kanj { my ($k, $taglist) = @_;
	my ($typ, $x, $t);
	foreach $t (@$taglist) {
	    $typ = shift (@$t);
	    if ($typ eq "KINF") { append ($k, "_kinf", {kw=>$t->[0]}); }
	    elsif ($typ eq "FREQ") { append ($k, "_kfreq", {kw=>$t->[0], value=>$t->[1]}); }
	    else { error ("Cannot use $typ tag with a kanji"); return undef; } }
	return $k; }

    sub mk_restrs { my ($listkey, $rdngs, $rdngkey, $kanj, $kanjkey, $kmap) = @_;
	# Note: mk_restrs() are used for all three
	# types of restriction info: restr, stagr, stagk.  However to
	# simplify things, the comments and variable names assume use
	# with reading restrictions (restr).  
	#
	# What we do is take a list of restr text items received from
	# a user which list the kanji (a subset of all the kanji for
	# the entry) that are valid with this reading, and turn it 
	# into a list of restr records that identify the kanji that
	# are *invalid* with this reading.  The restr records identify
	# kanji by id number rather than text.
	#
	# $listkey -- Name of the key used to get the list of text
	#    restr items from $rdngs.  These are the text strings
	#    provided by the user.  Should be "_RESTR", "_STAGR", 
	#    or "_STAGK".
	# @$rdngs -- Lists of rdng or sens records depending on whether
	#    we're doing restr or stagr/stagk restrictions.
	# $rdngkey -- Either "rdng" or "sens" depending on whether we're
	#    doing restr or  stagr/stagk restrictions.
	# @$kanj -- List of the entry's kanji or reading records 
	#    depending on whether we are doing restr/stagk or stagr
	#    restrictions.
	# $kanjkey -- Either "kanj" or "rdng" depending on whether we're
	#    doing restr/stagk or stagr restrictions.
	# %$kmap -- (Optional)  A hash of @$kanj keyed by the text strings.
	#    If not given it will be automatically generated, but caller
	#    can supply it to prevent it from being recalculated multiple
	#    times.  [NB: we should cache after generation so caller need
	#    not worry about it at all.]

	my ($r, @nomatch, $restrtxt, %xmap, @disallowed, $nokanj, $errs);
	for $r (@$rdngs) {

	      # Get the list of restr text strings and nokanji flag and
	      # delete them from the rdng object since they aren't part
	      # of the standard api.
	    $restrtxt = $r->{$listkey};
	    delete $r->{$listkey}; 
	    $nokanj = $r->{_NOKANJI};
	    delete $r->{_NOKANJI};

	      # Continue with next reading if nothing to be done 
	      # with this one.
	    next if (!$nokanj and !$restrtxt);

	      # bld_rdngs() guarantees that {_NOKANJI} and {_RESTR} won't
	      # both be present on the same rdng.

	    if (!$nokanj) { 
		  # Put the restr strings into a hash for easy
		  # lookup.  We only care about existence so value
		  # of each item set to 1.
		%xmap = map (($_, 1), @$restrtxt);

		  # Do the same with the text from the @$kanj records
		  # if the caller hasn't already done it.
		if (!$kmap) { $kmap = {map (($_->{txt}, $_), @$kanj)}; }

		  # Look for any restr kanji text that is not in the
		  # entry's kanji text.
		@nomatch = grep (!$kmap->{$_}, @$restrtxt);
		if (@nomatch) { 
		    error ("restr value(s) '" . 
			    join ("','", @nomatch) . 
			    "' not in the entry's readings or kanji");
		    $errs++; }

		  # Get a list of the disallowd kanji by finding all the
		  # items in @$kanj that are not in @$restrtxt (which was
		  # hashed into %xmap above).
		@disallowed = grep (!$xmap{$_->{txt}}, @$kanj); }

	    else {
		@disallowed = ();
		if (!$kanj || !@$kanj) {
		    error ("Entry has no kanji but reading has 'nokanji' tag");
		    $errs++; }

		  # If this reading was marked "nokanji", then all 
		  # the entries kanji are disallowed.
		else { @disallowed = @$kanj; } }

	      # Use the list of disallowed kanji to create the restr 
	      # list that is attached to the reading.
	    if (@disallowed) { 
		$r->{lc($listkey)} = [map (+
		  {entr=>$r->{entr}, $rdngkey=>$r->{$rdngkey}, $kanjkey=>$_->{$kanjkey}},
		  @disallowed)]; } }
	return $errs ? undef : 1; }

    sub append { my ($sens, $key, $item) = @_; 

	# Append $item to the list, @{$sens->{$key}}, creating 
	# the latter if needed.

	if (!($sens->{$key})) { $sens->{$key} = []; }
	push (@{$sens->{$key}}, $item); }

    sub gcleanup { my ($txt) = @_;

	# Remove leading and trailing whitespace from string.
	# Replace multiple whitespace characters with one.
	# Unescape escaped ';'s and '['s.

	$txt =~ s/^[\s\x{3000}\n\r]+//s;
	$txt =~ s/[\s\x{3000}\n\r]+$//s;
	$txt =~ s/[\s\x{3000}\n\r]+$/ /sg;
	$txt =~ s/\\([;\[])/$1/g;
	return $txt; }

    sub qcleanup { my ($txt) = @_;

	# Remove leading and trailing whitespace from string.
	# Replace multiple whitespace characters with one.
	# Unescape escaped '"'s.

	$txt =~ s/^[\s\x{3000}\n\r]+//s;
	$txt =~ s/[\s\x{3000}\n\r]+$//s;
	$txt =~ s/[\s\x{3000}\n\r]+$/ /sg;
	$txt =~ s/\\(["])/$1/g;
	return $txt; }

    sub error { 
	push (@::TmpError, @_); } 

    sub dummy {

	# For debugging.  Delete me soon please. 

	print "dummy: $_[0]\n"; 
	return; }

    sub dbgprt { my ($typ, $msg) = @_;

	# Called at various places in the parser and lexer to
	# show what itis doing.  YAPP also has debugging output
	# but I like mine better.
 
	my ($pre);
	return if (!($typ & $::dbg));
	if ($typ == 1) { $pre = "Applying rule:"; }
	if ($typ == 2) { $pre = "Lexer returning:"; }
	if ($typ == 4) { $pre = "Lexer state:"; }
	# print STDERR "$pre $msg\n";
	$::dbgtxt .= "$pre $msg\n"; } 

    sub _pushlexstate { my ($state) = @_;
	push (@::Lexstate, $state); 
	if ($::dbg & 4) { dbgprt (4, join(",",@::Lexstate)); } }

    sub _poplexstate { 
	if (scalar(@::Lexstate) > 1) { pop (@::Lexstate); }	
	if ($::dbg & 4) { dbgprt (4, join(",",@::Lexstate)); } }

    sub _setlexstate { my ($state) = @_;
	@::Lexstate = ($state); 
	if ($::dbg & 4) { dbgprt (4, join(",",@::Lexstate)); } }

    sub _mklexer { my ($txt) = @_;
	# Create lexer sub as a closure so that it has a copy
	# of the text string ($txt) it is analyzing.
	my $subr = sub { my ($parser) = @_;
	    my ($t, $s);

	    # The lexer has three states, and recognises a different set
	    # of tokens in each state.  The states are:
	    #   0 -- Recognise tokens relevant in the reading and
	    #        kanji sections.
	    #   1 -- Recognise tokens within a taglist enclosed in square
	    #        brackets "[...]".
            #   2 -- Recognise tokens when parsing glosses.
	    # A stack of states in maintained in @::Lexstate and the 
	    # topmost element ($Lexstate[-1]) is the current state.
	    # The parser controls the state stack via the functions
	    # _pushlexstate(), _poplexstate(), and _setlexstate().
	    
	    $s = $::Lexstate[-1]; # dbgprt (4, "=" . $s);

	      # Skip over any whitespace.  \x{3000} is a ja space.

	    $txt =~ m/\G[\s\x{3000}]+/smcg;

	      # YAPP requires (undef,"") to be returned at the end of
	      # the text.  Perl function pos() gives the current position
	      # within the text.

	    return (undef, "") if (pos($txt) >= length ($txt));

	      # All the regex's below start with \G and use the flags
	      # /cg which tell the regex engine to start the match at
	      # the point where the last successful match (which was
	      # probably during the previous call to this function)
	      # left off.

	    if ($s == 0) {	# Inside reading or kanji sections.
		# We only care about characters that delimit 
		# individual kanji or reading items (semicolon)
		# or that signal a change in state (left bracket,
		# or sense number.
		  
		  # Match the sense number pattern explicitly since it
		  # too much lookahead to have the parser detect it
		  # as BRKTL NUMBER BRKTR.
		if ($txt =~ m/\G(\[\d+\])/cg)  { return ("SNUM", $1); }
		if ($txt =~ m/\G[;\x{FF1B}]/cg)  { return ("SEMI", ";"); }
		if ($txt =~ m/\G\[/cg) { return ("BRKTL", "["); }
		  # Match any text up to whitespace or any of the special
		  # character recognised above. 
		if ($txt =~ m/\G([^;\x{FF1B}:=,\[\]\x{3000} \t\r\n]+)/smcg) { 
		      # Classify it as kanji, reading (kana), or ordinary
		      # text and return token accordingly.
		    $t = jmdict::jstr_classify ($1);
		    if ($t & $jmdict::KANJI) { return ("KTEXT", $1); }
		    if ($t & $jmdict::KANA)  { return ("RTEXT", $1); }
		    return ("TEXT", $1); } }

	    elsif ($s == 1) {	# Inside taglist.
		  # Match quoted string allowing for included \", but
		  # not currently \\. 
		if ($txt =~ m/\G"((([^"\\])|(\\"))+)"/cg)  { return ("TEXT", "$1"); }
		  # Match special characters in taglists...
		if ($txt =~ m/\G[:]/cg)  { return ("COLON", ":"); }
		if ($txt =~ m/\G([;\x{FF1B}])/cg)  { return ("SEMI", "$1"); }
		if ($txt =~ m/\G[,]/cg)  { return ("COMMA", ","); }
		if ($txt =~ m/\G[=]/cg)  { return ("EQL", "="); }
		if ($txt =~ m/\G([\/\x{FF0F}])/cg) { return ("SLASH", "$1"); }
		if ($txt =~ m/\G[\[]/cg) { return ("BRKTL", "["); }
		if ($txt =~ m/\G[\]]/cg) { return ("BRKTR", "]"); }
		  # If none of the above, match any sequence of characters
		  # up to the next whitespace of special character.
		if ($txt =~ m/\G([^;\x{FF1B}:=,\/\x{FF0F}\[\] \t\r\n]+)/smcg) { 
		      # Classify it as kanji, reading (kana), or ordinary
		      # text and return token accordingly.
		    $t = jmdict::jstr_classify ($1);
		    if ($t & $jmdict::KANJI) { return ("KTEXT", qcleanup($1)); }
		    if ($t & $jmdict::KANA)  { return ("RTEXT", qcleanup($1)); }
		    return ("TEXT", qcleanup($1)); } }

	    elsif ($s == 2) {	# Inside glosses section.
		  # When parsing glosses the only spacial characters
		  # we care about are ";" which seperates glosses,
		  # "[" which starts a taglist, and "[\d+]" which denotes
		  # a new sense.  We don't treat whitespace specially
		  # (it is preserved and included in the token's value.)
		if ($txt =~ m/\G(\[\d+\])/cg)   { return ("SNUM", $1); }
		  # Following regex allows "[" and ";" in the gloss text 
		  # if escaped with a "\" character. 
		if ($txt =~ m/\G((([^;\\\[])|(\\\[)|(\\;))+)/cg) { return ("GTEXT", gcleanup($1)); }
		if ($txt =~ m/\G;/cg) { return ("SEMI", ";"); } 
		if ($txt =~ m/\G\[/cg) { return ("BRKTL", "["); } }

	    else { die "Invalid lexer state '$s' encountered\n"; }

	      # A catch all.  The parser does not use OTHER token in any
	      # productions so it will cause the parser to generate a 
	      # a parse error.
	    ($txt =~ m/\G(.)/smcg) && return ("OTHER", $1); 
	    die "How the heck did this happen?\n"; }; 
	return $subr; }

    sub _error { my ($parser) = @_;
	# This function is called by the YAPP parser when it 
	# detects parse error.  We create and save an error
	# message describing the error.
	# 
	# Parse errors may be generated by a YAPP detected
	# syntax error in the input, or syntheised by our 
	# when semantic value code when some non-purely
	# syntactic error is found.  In that latter case
	# the error detecting code will put error message
	# in global variable @::tmpError, and we retrieve 
	# it from there and use it as the error message.
	#
	# When a syntax error is detected by the YAPP parse
	# engine, we synthesise an error message from the
	# info the YAPP makes available.
	
	my ($msg, $wanted, @expected);
	  # Get the error message saved by our seantic code
	  # (if any).
	$msg = join ("\n", @::TmpError);

	if ($msg) {
	      # Clear the transfer variable for the next time.
	    @::TmpError = (); }
	else { 
	      # If there was no message then this is a syntax
	      # error that YAPP detected.  We will synthesise
	      # a message.
	    @expected = $parser->YYExpect();
	    if (0 == scalar (@expected)) { $wanted = "<EOF>"; }
	    elsif (1 == scalar (@expected)) { $wanted = "'$expected[0]'"}
	    else { $wanted = "one of '" . join ("', '", @expected) . "'" }
	    $msg = "parse error: read a ". $parser->YYCurtok() ." token, expected $wanted"; }
	# $msg .= " at line $.";

	  # Save the message is a message stack that will be
	  # printed by the main program after the parser is 
	  # finished.
	push (@::Errors, $msg); }
	
    sub parse_text { my ($self, $txt, $dbg) = @_;
	my ($parser, $lexer, $result, $dbglexer);
	$parser = new ("jbparser");
	$::dbg = $dbg;
	@::Errors = ();
	$lexer = _mklexer ($txt); 
	$dbglexer = 
	    sub { my ($p) = @_; 
		my ($t, $v) = &$lexer ($p);
		if ($::dbg & 2) { dbgprt (2, "token='$t', val='$v'"); }
		return ($t, $v); };
	@::Lexstate = (0);
	$result = $parser->YYParse (yylex=>$dbglexer, yyerror=>\&_error);
	($result, \@::Errors); }

    1;

1;
