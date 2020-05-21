package OpenTracing::Implementation::DataDog::ScopeManager;

=head1 NAME

OpenTracing::Implementation::DataDog::ScopeManager - Keep track of active scopes

=head1 SYNOPSIS

    duno

=cut

our $VERSION = 'v0.30.1';

use Moo;

use OpenTracing::Implementation::DataDog::Scope;

use OpenTracing::Types qw/Scope/;
use Types::Standard qw/Maybe/;



has _active_scope => (
    is => 'rwp',
    isa => Maybe[Scope],
    reader => 'get_active_scope',
);



has '+scope_builder' => (
    lazy => 1,
    builder => sub { shift->datadog_scope_builder->(@_) },
);



sub datadog_scope_builder {
    my $self = shift;
    my $span = shift;
    my $options = { @_ };
    
    # remove the `finish_span_on_close` option, which is for this method only! 
    my $finish_span_on_close = 
        exists( $options->{ finish_span_on_close } ) ?
            !! delete $options->{ finish_span_on_close }
            : !undef
    ; # use 'truthness' of param if provided, or set to 'true' otherwise
    
    my $current_scope = $self->get_active_scope;
    
    my $scope = OpenTracing::Implementation::DataDog::Scope->new(
        span                 => $span,
        finish_span_on_close => $finish_span_on_close,
        on_close             => sub {
            $self->set_active_scope( $current_scope );
        }
    );
    
    return $scope
}



BEGIN {
    with 'OpenTracing::Role::ScopeManager';
}



1;
