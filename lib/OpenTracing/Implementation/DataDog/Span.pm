package OpenTracing::Implementation::DataDog::Span;

our $VERSION = 'v0.30.1';

use syntax 'maybe';

use Moo;

with 'OpenTracing::Role::Span';

use OpenTracing::Implementation::DataDog::Utils qw(
    random_64bit_int
    nano_seconds
);

use Types::Standard qw/CodeRef Object/;



has '+span_id' => (
    default => sub{ random_64bit_int() }
);



has on_DEMOLISH => (
    is              => 'ro',
    isa             => CodeRef,
    default         => sub { sub { } }
);



sub nano_seconds_start_time { nano_seconds( $_[0]->start_time ) }

sub nano_seconds_duration   { nano_seconds( $_[0]->duration ) }



sub DEMOLISH {
    my $self = shift;
    my $in_global_destruction = shift;
    
    $self->on_DEMOLISH->( $self )
        unless $in_global_destruction;
    
    return
}



1;
