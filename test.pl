#!/usr/bin/perl -w

use strict;
use vars qw($loaded);

#-------------------------------------------------------------------------------

BEGIN {
	$| = 1;
	print "1..3\n";
}

END {
    print "not ok 1\n" unless $loaded;
}

#-------------------------------------------------------------------------------

{
    my $ntest=1;
    sub ok     { return "ok ".$ntest++."\n"; }
    sub not_ok { return "not ok ".$ntest++."\n"; }
}

#-------------------------------------------------------------------------------

# test 1
use SVG::Parser;
$loaded = 1;
print ok;

# tests 2..N
foreach my $test (<test/*.pl>) {
  my $result=do $test;
  print $result?ok:not_ok;
}

