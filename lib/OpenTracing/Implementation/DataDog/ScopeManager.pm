package OpenTracing::Implementation::DataDog::ScopeManager;

=head1 NAME

OpenTracing::Implementation::DataDog::ScopeManager - Keep track of active scopes

=head1 SYNOPSIS

    duno

=cut

use Moo;

# with 'OpenTracing::Role::ScopeManager';
#
# moved to the bottom, so Moo can install methods that are required

use OpenTracing::Implementation::DataDog::Scope;

use Carp;
use Types::Interface qw/ObjectDoesInterface/;
use Types::Standard qw/Maybe/;



has _active_scope => (
    is => 'rwp',
    isa => Maybe[ObjectDoesInterface['OpenTracing::Role::Scope']],
    reader => 'get_active_scope',
);



sub activate_span {
    my $self = shift;
    my $span = shift or croak "Missing OpenTracing Span";
    
    my $finish_span_on_close = scalar( @_ ) ? !! shift : !undef;
    #
    # missing this (last) positional argument, means it defaults to 'true'
    
    my $scope = $self->_build_scope( $span, $finish_span_on_close );
    
    $self->_set__active_scope( $scope );
    
    return $scope
}



sub _build_scope {
    my $self = shift;
    my $span = shift;
    my $finish_span_on_close = shift;
    
    my $current_scope = $self->get_active_scope;
    
    my $scope = OpenTracing::Implementation::DataDog::Scope->new(
        span                 => $span,
        finish_span_on_close => $finish_span_on_close,
        after_close          => sub {
            $self->_set__active_scope( $current_scope );
        }
    );
    
    return $scope
}


with 'OpenTracing::Role::ScopeManager';

1;
