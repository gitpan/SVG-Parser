#!/usr/bin/perl -w
use strict;
use SVG::Parser qw(My::XML::Parser::Subclass);

{
    package My::XML::Parser::Subclass;
    use strict;
    use vars qw(@ISA);
    use XML::Parser;
    @ISA=qw(XML::Parser);
}

my $parser=new SVG::Parser;

$parser->parsefile("test/in/svg.xml");
