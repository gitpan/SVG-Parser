package SVG::Parser::Base;
use strict;

#-------------------------------------------------------------------------------

# XML declaration defaults
use constant SVG_DEFAULT_DECL_VERSION     => "1.0";
use constant SVG_DEFAULT_DECL_ENCODING    => "UTF-8";
use constant SVG_DEFAULT_DECL_STANDALONE  => "yes";

# Document type definition defaults
use constant SVG_DEFAULT_DOCTYPE_NAME     => "svg";
use constant SVG_DEFAULT_DOCTYPE_SYSID    => "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd";
use constant SVG_DEFAULT_DOCTYPE_PUBID    => "-//W3C//DTD SVG 1.0//EN";

#-------------------------------------------------------------------------------

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
            $first=0;
        }
    } else {
        printf STDERR "+++%s %s\n",$name,$what;
    }
}

#-------------------------------------------------------------------------------

use constant ARG_IS_STRING                => "string";
use constant ARG_IS_HANDLE                => "handle";
use constant ARG_IS_HASHRF                => "hash"; 
use constant ARG_IS_INVALID               => "nonsuch"; 

#-------------------------------------------------------------------------------

# is it a bird...is it a plane?
sub identify ($$) {
    my ($self,$source)=@_;

    return ARG_IS_INVALID unless $source; 

    # assume a string unless we determine differently
    my $type=ARG_IS_STRING;

    # check for various filehandle cases
    if (ref $source) {
        my $class = ref($source);

        if (UNIVERSAL::isa($source,'IO::Handle')) {
            # it's a new-style filehandle
            $type=ARG_IS_HANDLE;
        } elsif (tied($source)) {
            # it's a tied filehandle?
            no strict 'refs'; 
            $type=ARG_IS_HANDLE if defined &{"${class}::TIEHANDLE"};
        }
    } else {
        # it's an old-style filehandle?
        no strict 'refs'; 
        $type=ARG_IS_HANDLE if eval { *{$source}{IO} };
    }

    # possibly a hash argument is called via parse_file (SAX)
    $type=ARG_IS_HASHRF if ref($source) and $type eq ARG_IS_STRING;

    return $type;
}

#-------------------------------------------------------------------------------

1;
