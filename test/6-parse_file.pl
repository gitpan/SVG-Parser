#!/usr/bin/perl -w
use strict;
use SVG::Parser;

my $parser=new SVG::Parser;
my $svg=$parser->parse_file("test/in/svg.xml");
