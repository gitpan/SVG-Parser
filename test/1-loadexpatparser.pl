#!/usr/bin/perl -w
use strict;

if (eval qq[require SVG::Parser::Expat, 1]) {
    1; # ok
} else {
    2; # skipped
}
