package SVG::Parser;
use strict;

require 5.004;

use SVG 2.0;
use XML::Parser;

use vars qw(@ISA $VERSION);
@ISA=qw(XML::Parser);

$VERSION="0.85";

#---------------------------------------------------------------------------------------

=head1 NAME

SVG::Parser - XML Parser for SVG documents

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use SVG::Parser;

  die "Usage: $0 <file>\n" unless @ARGV;

  my $xml;
  {
      local $/=undef;
      $xml=<>;
  }

  my $parser=new SVG::Parser;

  my $svg=$parser->parse($xml);

  print $svg->xmlify;

=head1 DESCRIPTION

SVG::Parser is an XML parser for SVG Documents. It takes XML as input, and produces an
SVG object as its output. XML::Parser is used to perform the basic parsing; a subclass
of XML::Parser that permits I<Stream mode> may also be used (see below).

=head2 METHODS

SVG::Parser provides all methods supported by XML::Parser. In particular:

=over 4

=item * new([%attrs])

Create a new SVG::Parser object. Optional attributes may be passed as arguments; all
attributes without a leading '-' prefix are passed to the parent constructor (by default
XML::Parser). For example:

   my $parser=new SVG::Parser(
	ErrorContext => 2,
        NoExpand => 1,
   );

(NB: SVG::Parser expects the parser style to be 'Stream'. Changing this is probably
unhelpful.)

Attributes with a leading '-' are processed by SVG::Parser. Currently the only 
recognised attribute is '-debug' which generates a simple but possibly useful debug
trace of the parsing process to standard error. For example:

   my $parser=new SVG::Parser(debug => 1);

or:

   my $parser=SVG::Parser->new(debug => 1);

=item * parse($xml)

Parse an XML document and return an SVG object which may then be used to manipulate the
SVG content before regenerating the output XML. For example:

    my $svg=$parser->parse($svgxml);

See L<XML::Parser> for other ways to parse input XML.

=back

=head2 EXPORTS

None. However, an alternative parent class (other than XML::Parser) can be specified by
passing the package name to SVG::Parser in the import list. For example:

    use SVG::Parser qw(My::XML::Parser::Subclass);

Where My::XML::Parser::Subclass is a subclass like:

    package My::XML::Parser::Subclass;
    use strict;
    use vars qw(@ISA);
    use XML::Parser;
    @ISA=qw(XML::Parser);

    ...custom methods...

    1;

=head2 EXAMPLES

See C<svgparse> in the examples directory of the distribution.

=head1 AUTHOR

Peter Wainwright, peter.wainwright@cybrid.net

=head1 SEE ALSO

L<SVG>, L<XML::Parser>, perl(1).

=cut

#---------------------------------------------------------------------------------------
# SVG::Parser constructor - implement a streaming parser. Attributes with no minus
# prefix are passed to the parent class. Attributes with a minus are set locally.

sub new {
    my $proto=shift;
    my $class=ref($proto) || $proto;
    my %attrs=@_;

    # pass on non-minus-prefixed attributes to XML::Parser
    my %parser_attrs;
    foreach (keys %attrs) {
        $parser_attrs{$_}=delete $attrs{$_} unless /^-/;
    }

    my $self=$class->SUPER::new(
        Style    => "Stream",    # This is a streaming XML parser
        Handlers => {
            XMLDecl => \&XMLDecl,
            Doctype => \&Doctype,
            Comment => \&Comment,
            Final   => \&Final,
        },
    %parser_attrs);

    # minus-prefixed attributes stay here
    foreach (keys %attrs) {
        $self->{$_}=$attrs{$_};
    }

    return $self;
}

# debug: simple debug method
sub debug ($$;@) {
    my ($self,$what,@msgs)=@_;
    return unless $self->{-debug};

    my $first=1;
    my $name||=ref($self);
    my $length||=length($name);
    if (@msgs) {
        foreach (@msgs) {
            printf STDERR "+++%s %-8s: %s\n",
                ($first?$name:" "x$length),
                ($first?$what:"       "),$_;
            $first&&=0;
        }
    } else {
        printf STDERR "+++%s %s\n",$name,$what;
    }
}

#---------------------------------------------------------------------------------------
# Parser method to pass an attribute to XML::Parser::Expat so we can find ourselves from
# the Expat object in the handlers below.
sub parse {
    my $self=shift;
    $self->SUPER::parse(@_,__parser=>$self);
}

#---------------------------------------------------------------------------------------
# Import method to change default inheritance, if required

sub import {
    my $package=shift;

    # permit an alternative XML::Parser subclass to be our parent class
    @ISA=@_ if @_;
}

#---------------------------------------------------------------------------------------
# Stream mode handlers

# create and set SVG document object as root element
sub StartDocument {
    my $expat=shift;

    my $parser=$expat->{__parser};
    # instantiate SVG document object
    $parser->{__svg}=new SVG(-nostub=>1);
    # empty element list
    $parser->{__elements}=[]; 

    $expat->{__parser}->debug("Start","$parser/$expat");
}

# handle start of element - extend chain by one
sub StartTag ($$) {
    my ($expat,$type)=@_;
    my $elements=$expat->{__parser}{__elements};
    my $svg=$expat->{__parser}{__svg};

    if (@$elements) {
        my $parent=$elements->[-1];
        push @$elements, $parent->element($type,%_);
    } else {
        $svg->{-inline}=1 if $type ne "svg"; #inlined
        my $el=$svg->element($type,%_);
        $svg->{-document} = $el;
        push @$elements, $el;
    }

    $expat->{__parser}->debug("Element",$type);
}

# handle end of element - shorten chain by one
sub EndTag ($$) {
    my ($expat,$type)=@_;
    my $elements=$expat->{__parser}{__elements};
    pop @$elements;
}

# handle cannonical data (text)
sub Text ($) {
    my $expat=shift;
    my $elements=$expat->{__parser}{__elements};

    return if /^\s*$/s; #ignore redundant whitespace
    my $parent=$elements->[-1];
    $parent->cdata($_);

    $expat->{__parser}->debug("CDATA","\"$_\"");
}

# handle processing instructions
sub PI ($$$) {
    my ($expat,$target,$data)=@_;
    my $elements=$expat->{__parser}{__elements};

    my $parent=$elements->[-1];
    /^<\?(.*)\?>/;
    $parent->pi($1);

    $expat->{__parser}->debug("PI",$_);
}

#---------------------------------------------------------------------------------------
# Base handlers

# handle XML declaration, if present
sub XMLDecl {
    my ($expat,$version,$encoding,$standalone)=@_;
    my $svg=$expat->{__parser}{__svg};

    $svg->{-version}=$version;
    $svg->{-encoding}=$encoding;
    $svg->{-standalone}=$standalone?"yes":"no";

    $expat->{__parser}->debug("XMLDecl","-version=\"$version\"",
		"-encoding=\"$encoding\"","-standalone=\"$standalone\"");
}

# handle XML Doctype Declaration, if present
sub Doctype {
    my ($expat,$name,$sysid,$pubid,$internal)=@_;
    my $svg=$expat->{__parser}{__svg};

    $svg->{-docroot}=$name;
    $svg->{-sysid}=$sysid;
    $svg->{-pubid}=$pubid;
    $svg->{-internal}=$internal;

    $expat->{__parser}->debug("Doctype","-docroot=\"$name\"","-sysid=\"$sysid\"",
		"-pubid=\"$pubid\"","-internal=\"$internal\"");
}

# handle XML Comments
sub Comment {
    my ($expat,$data)=@_;
    my $elements=$expat->{__parser}{__elements};
    my $parent=$elements->[-1];
    $parent->comment($data);

    $expat->{__parser}->debug("Comment: $data");
}

# return root SVG document object as result of parse()
sub Final {
    my $expat=shift;
    my $parser=$expat->{__parser};

    $parser->debug("Done");
    return $parser->{__svg};
}

#---------------------------------------------------------------------------------------

1;
