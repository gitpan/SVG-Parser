#!/usr/bin/perl -w
use strict;
use SVG::Parser;

my $xml;
{
    push @ARGV,"test/in/svg.xml";
    local $/=undef;
    $xml=<>;
}

my $parser=new SVG::Parser;
my $svg=$parser->parse($xml);

1;
