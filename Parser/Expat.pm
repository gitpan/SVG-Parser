package SVG::Parser::Expat;
use strict;

require 5.004;

use base qw(XML::Parser SVG::Parser::Base);
use SVG 2.0;

use vars qw($VERSION @ISA);

$VERSION="0.97";

#---------------------------------------------------------------------------------------

=head1 NAME

SVG::Parser::Expat - XML Expat Parser for SVG documents

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use SVG::Parser::Expat;

  die "Usage: $0 <file>\n" unless @ARGV;

  my $xml;
  {
      local $/=undef;
      $xml=<>;
  }

  my $parser=new SVG::Parser::Expat;

  my $svg=$parser->parse($xml);

  print $svg->xmlify;

=head1 DESCRIPTION

SVG::Parser::Expat is the Expat-specific parser module used by SVG::Parser when an
underlying XML::Parser-based parser is selected. It may also be used directly, as shown
in the synopsis above.

Use SVG::Parser to retain maximum flexibility as to which underlying parser is chosen.
Use SVG::Parser::Expat to supply Expat-specific parser options or where the presence
of XML::Parser is known and/or preferred.

=head2 EXPORTS

None. However, an alternative parent class (other than XML::Parser) can be specified by
passing the package name to SVG::Parser::Expat in the import list. For example:

    use SVG::Parser::Expat qw(My::XML::Parser::Subclass);

Where My::XML::Parser::Subclass is a subclass like:

    package My::XML::Parser::Subclass;
    use strict;
    use vars qw(@ISA);
    use XML::Parser;
    @ISA=qw(XML::Parser);

    ...custom methods...

    1;

When loaded via SVG::Parser, this parent class may be specified by placing it after
the '=' in a parser specification:

    use SVG::Parser qw(Expat=My::XML::Parser::Subclass);

See L<SVG::Parser> for more details.

=head2 EXAMPLES

See C<svgexpatparse> in the examples directory of the distribution.

=head1 AUTHOR

Peter Wainwright, peter.wainwright@cybrid.net

=head1 SEE ALSO

L<SVG>, L<SVG::Parser>, L<SVG::Parser::SAX>, L<XML::Parser>

=cut

#---------------------------------------------------------------------------------------
# SVG::Parser::Expat constructor. Attributes with no minus prefix are passed to
# the parent parser class. Attributes with a minus are set locally.

sub new {
    my $proto=shift;
    my $class=ref($proto) || $proto;
    my %attrs=@_;

    # pass on non-minus-prefixed attributes to XML::Parser
    my %parser_attrs;
    foreach (keys %attrs) {
        $parser_attrs{$_}=delete $attrs{$_} unless /^-/;
    }

    my $parser=$class->SUPER::new(%parser_attrs);
    $parser->setHandlers(
        XMLDecl => sub { XMLDecl($parser, @_) },
        Doctype => sub { Doctype($parser, @_) },
        Init    => sub { StartDocument($parser, @_) },
        Final   => sub { FinishDocument($parser, @_) },

        Start   => sub { StartTag($parser, @_) },
        End     => sub { EndTag($parser, @_) },
        Char    => sub { Text($parser, @_) },
        Proc    => sub { PI($parser, @_) },
        Comment => sub { Comment($parser, @_) },
    );

    # minus-prefixed attributes stay here, double-minus to SVG object
    foreach (keys %attrs) {
        if (/^-(-.+)$/) {
            $parser->{__svg_attr}{$1}=$attrs{$_};
        } else {
            $parser->{$_}=$attrs{$_};
        }
    }

    return $parser;
}

#---------------------------------------------------------------------------------------
# Import method to change default inheritance, if required

sub import {
    my $package=shift;

    # permit an alternative XML::Parser subclass to be our parent class
    if (@_) {
        my $superclass=shift;
 
        $ISA[0]=$superclass,return if eval qq[
            require $superclass;
            import $superclass qw(@_);
        ];        

        die "Parent parser class $superclass not found\n";
    }
}

#---------------------------------------------------------------------------------------
# Handlers

# create and set SVG document object as root element
sub StartDocument {
    my $parser=shift;

    # gather SVG constuctor attributes
    my %svg_attr;
    %svg_attr=%{delete $parser->{__svg_attr}} if exists $parser->{__svg_attr};
    $svg_attr{-nostub}=1;
    # instantiate SVG document object
    $parser->{__svg}=new SVG(%svg_attr);
    # empty element list
    $parser->{__elements}=[]; 

    $parser->debug("Start",$parser."/".$parser->{__svg});
}

# handle start of element - extend chain by one
sub StartTag {
    my ($parser,$expat,$type,%attrs)=@_;
    my $elements=$parser->{__elements};
    my $svg=$parser->{__svg};

    if (@$elements) {
        my $parent=$elements->[-1];
        push @$elements, $parent->element($type,%attrs);
    } else {
        $svg->{-inline}=1 if $type ne "svg"; #inlined
        my $el=$svg->element($type,%attrs);
        $svg->{-document} = $el;
        push @$elements, $el;
    }

    $parser->debug("Element",$type);
}

# handle end of element - shorten chain by one
sub EndTag {
    my ($parser,$expat,$type)=@_;
    my $elements=$parser->{__elements};
    pop @$elements;
}

# handle cannonical data (text)
sub Text {
    my ($parser,$expat,$text)=@_;
    my $elements=$parser->{__elements};

    return if $text=~/^\s*$/s; #ignore redundant whitespace
    my $parent=$elements->[-1];
    $parent->cdata($text);

    $parser->debug("CDATA","\"$text\"");
}

# handle processing instructions
sub PI {
    my ($parser,$expat,$target,$data)=@_;
    my $elements=$parser->{__elements};

    my $parent=$elements->[-1];
    /^<\?(.*)\?>/;
    $parent->pi($1);

    $parser->debug("PI",$_);
}

# handle XML Comments
sub Comment {
    my ($parser,$expat,$data)=@_;

    my $elements=$parser->{__elements};
    my $parent=$elements->[-1];
    $parent->comment($data);

    $parser->debug("Comment",$data);
}

# return root SVG document object as result of parse()
sub FinishDocument {
    my $parser=shift;

    $parser->debug("Done");

    return $parser->{__svg};
}

#---------------------------------------------------------------------------------------

# handle XML declaration, if present
sub XMLDecl {
    my ($parser,$expat,$version,$encoding,$standalone)=@_;
    my $svg=$parser->{__svg};

    $svg->{-version}=$version || $parser->SVG_DEFAULT_DECL_VERSION;
    $svg->{-encoding}=$encoding || $parser->SVG_DEFAULT_DECL_ENCODING;
    $svg->{-standalone}=$standalone?"yes":"no";

    $parser->debug("XMLDecl","-version=\"$svg->{-version}\"",
	"-encoding=\"$svg->{-encoding}\"","-standalone=\"$svg->{-standalone}\"");
}

# handle Doctype declaration, if present
sub Doctype {
    my ($parser,$expat,$name,$sysid,$pubid,$internal)=@_;
    my $svg=$parser->{__svg};

    $svg->{-docroot}=$name || $parser->SVG_DEFAULT_DOCTYPE_NAME;
    $svg->{-sysid}=$sysid || $parser->SVG_DEFAULT_DOCTYPE_SYSID;
    $svg->{-pubid}=$pubid || $parser->SVG_DEFAULT_DOCTYPE_PUBID;
    $svg->{-internal}=$internal?"yes":"no"; # this needs further work...

    $parser->debug("Doctype",
        "-docroot=\"$svg->{-docroot}\"",
        "-sysid=\"$svg->{-sysid}\"",
	"-pubid=\"$svg->{-pubid}\"",
        "-internal=\"$svg->{-internal}\""
    );
}

#---------------------------------------------------------------------------------------
# SAX -> Expat compatability

sub parse_file {
    shift->parsefile(@_);
}

#---------------------------------------------------------------------------------------


1;
