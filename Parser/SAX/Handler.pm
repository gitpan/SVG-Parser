package SVG::Parser::SAX::Handler;
use strict;
use vars qw(@ISA $VERSION);

require 5.004;

use base qw(XML::SAX::Base SVG::Parser::Base);
use SVG::Parser::Base;
use SVG 2.0;

$VERSION="0.97";

#-------------------------------------------------------------------------------

sub new {
    my $proto=shift;
    my $class=ref($proto) || $proto;
    my %attrs=@_;

    # pass on non-minus-prefixed attributes to handler
    my %handler_attrs;
    foreach (keys %attrs) {
        $handler_attrs{$_}=delete $attrs{$_} unless /^-/;
    }

    my $self=$class->SUPER::new(%handler_attrs);

    # minus-prefixed attributes stay here, double-minus to SVG object
    foreach (keys %attrs) {
        if (/^-(-.+)$/) {
            $self->{__svg_attr}{$1}=$attrs{$_};
        } else {
            $self->{$_}=$attrs{$_};
        }
    } 

    return $self;
}

#-------------------------------------------------------------------------------

sub start_document {
    my ($self,$document)=@_;

    # gather SVG constuctor attributes
    my %svg_attr;
    %svg_attr=%{delete $self->{__svg_attr}} if exists $self->{__svg_attr};
    $svg_attr{-nostub}=1;
    # instantiate SVG document object
    $self->{__svg}=new SVG(%svg_attr);
    # empty element list
    $self->{__elements}=[];

    $self->debug("Start",$self."/".$self->{__svg});
}

sub start_element {
    my ($self,$element)=@_;

    my $elements=$self->{__elements};
    my $svg=$self->{__svg};
  
    my $name=$element->{Name};
    my %attrs=map {
	$element->{Attributes}{$_}{Name} => $element->{Attributes}{$_}{Value}
    } keys %{$element->{Attributes}};

    if (@$elements) {
        my $parent=$elements->[-1];
        push @$elements, $parent->element($name,%attrs);
    } else {
        $svg->{-inline}=1 if $name ne "svg"; #inlined
        my $el=$svg->element($name,%attrs);
        $svg->{-document} = $el;
        push @$elements, $el;
    }

    $self->debug("Element",$name);
}

sub end_element {
    my ($self,$element)=@_;
    my $elements=$self->{__elements};
    pop @$elements;
}

sub characters {
    my ($self,$text)=@_;
    my $elements=$self->{__elements};

    return if $text->{Data}=~/^\s*$/s; #ignore redundant whitespace
    my $parent=$elements->[-1];
    $parent->cdata($text->{Data});

    $self->debug("CDATA",qq/"$text->{Data}"/);
}

sub processing_instruction {
    my ($self,$pi)=@_;
    my $elements=$self->{__elements};

    my $parent=$elements->[-1];
    $parent->pi("$pi->{Target} $pi->{Data}");

    $self->debug("PI","$pi->{Target} $pi->{Data}");
}

# handle XML Comments
sub comment {
    my ($self,$comment)=@_;

    my $elements=$self->{__elements};
    my $parent=$elements->[-1];

    $parent->comment($comment->{Data});
    $self->debug("Comment",$comment->{Data});
}

sub end_document {
    my ($self,$document)=@_;

    $self->debug("Done");

    return $self->{__svg};
}

#-------------------------------------------------------------------------------

# handle XML declaration, if present
sub xml_decl {
    my ($self,$decl)=@_;
    my $svg=$self->{__svg};

    $svg->{-version}=$decl->{Version} || $self->SVG_DEFAULT_DECL_VERSION;
    $svg->{-encoding}=$decl->{Encoding} || $self->SVG_DEFAULT_DECL_ENCODING;
    $svg->{-standalone}=$decl->{Standalone} || $self->SVG_DEFAULT_DECL_STANDALONE;
   
    $self->debug("XMLDecl","-version=\"$svg->{-version}\"",
        "-encoding=\"$svg->{-encoding}\"","-standalone=\"$svg->{-standalone}\"");
}

# handle Doctype declaration, if present (and if parser handles it)
sub doctype_decl {
    my ($self,$dtd)=@_;
    my $svg=$self->{__svg};

    $svg->{-docroot}=$dtd->{Name} || $self->SVG_DEFAULT_DOCTYPE_NAME;
    $svg->{-sysid}=$dtd->{SystemId} || $self->SVG_DEFAULT_DOCTYPE_SYSID;
    $svg->{-pubid}=$dtd->{PublicId} || $self->SVG_DEFAULT_DOCTYPE_PUBID;
    $svg->{-internal}=$dtd->{Internal};

    $self->debug("Doctype",
        "-docroot=\"$svg->{-docroot}\"",
        "-sysid=\"$svg->{-sysid}\"",
        "-pubid=\"$svg->{-pubid}\"",
        "-internal=\"$svg->{-internal}\""
    );
}

#-------------------------------------------------------------------------------

=head1 NAME

SVG::Parser::SAX::Handler - SAX handler class for SVG documents

=head1 DESCRIPTION

This module provides the handlers for constructing an SVG document object when
using SVG::Parser::SAX. See L<SVG::Parser::SAX> for more information.

=head1 AUTHOR

Peter Wainwright, peter.wainwright@cybrid.net

=head1 SEE ALSO

L<SVG::Parser>, L<SVG::Parser::SAX>

=cut

1;
