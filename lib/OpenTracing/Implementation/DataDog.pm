package OpenTracing::Implementation::DataDog;

use strict;
use warnings;

our $VERSION = '0.03';

use aliased 'OpenTracing::Implementation::DataDog::Tracer';



sub bootstrap_tracer {
    my $implementation_class = shift;
    
    my @implementation_args  = @_;
    
    return Tracer->new( @implementation_args );
}



BEGIN {
    use Role::Tiny::With;
    with 'OpenTracing::Implementation::Interface::Bootstrap'
        if $ENV{OPENTRACING_INTERFACE}
} # check at compile time, perl -c will work



1;
