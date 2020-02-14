package OpenTracing::Implementation::DataDog::Scope;

=head1 NAME

OpenTracing::Implementation::DataDog::Scope - Formailzing active spans

=head SYNOPSIS

    duno

=cut

our $VERSION = 'v0.30.1';

use Moo;

with 'OpenTracing::Role::Scope';

use OpenTracing::Implementation::DataDog::Utils qw/epoch_floatingpoint/;

use Carp;
use Types::Interface qw/ObjectDoesInterface/;
use Types::Standard qw/CodeRef Num/;



has on_close => (
    is              => 'ro',
    isa             => CodeRef,
    default         => sub { sub { } },
);



sub close {
    my $self = shift;
    
    return $self->on_close->( $self, @_ )
    
}



1;