#!/usr/bin/perl -w
use strict;
use SVG::Parser;

my $parser=new SVG::Parser;
my $svg=$parser->parsefile("test/in/svg.xml");
