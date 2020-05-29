package OpenTracing::Implementation::DataDog::ScopeManager;

=head1 NAME

OpenTracing::Implementation::DataDog::ScopeManager - Keep track of active scopes

=head1 SYNOPSIS

    duno

=cut

our $VERSION = 'v0.30.1';

use Moo;

use OpenTracing::Implementation::DataDog::Scope;



sub build_scope {
    my $self = shift;
    my $options = { @_ };
    
    my $current_scope = $self->get_active_scope;
    
    my $scope = OpenTracing::Implementation::DataDog::Scope->new(
        span                 => $options->{ span },
        finish_span_on_close => $options->{ finish_span_on_close },
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
