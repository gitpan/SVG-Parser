#!/usr/bin/perl -w

use strict;
use vars qw($loaded);

#-------------------------------------------------------------------------------

$| = 1;

#-------------------------------------------------------------------------------

{
    my $ntest=1;
    sub ok      { return "ok ".$ntest++."\n"; }
    sub not_ok  { return "not ok ".$ntest++."\n"; }
    sub skipped { return "skipped ".$ntest++."\n"; }
}

#-------------------------------------------------------------------------------

my @tests=<test/*.pl>;

print "1..",scalar(@tests),"\n";

foreach my $test (@tests) {
  my $result=do $test;
  print $result?($result==2?skipped:ok):not_ok;
}

