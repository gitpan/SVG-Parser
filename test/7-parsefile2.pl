#!/usr/bin/perl -w
use strict;
use SVG::Parser::SAX;

my $parser=new SVG::Parser::SAX;

open (FH,"test/in/svg.xml") or die $!;
my $svg=$parser->parsefile(*FH);
