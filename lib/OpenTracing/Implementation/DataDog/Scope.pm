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



has after_close => (
    is              => 'ro',
    isa             => CodeRef,
    default         => sub { sub { } },
);



sub close {
    my $self = shift;
    
    return $self->after_close->( $self, @_ )
    
}



sub DEMOLISH {
    my $self = shift;
    my $in_global_destruction = shift;
    
    return if $self->closed;
    
    croak "Scope not programmatically closed before being demolished";
    #
    # below might be appreciated behaviour, but you should close yourself
    #
    $self->close( )
        unless $in_global_destruction;
    
    return
}



1;