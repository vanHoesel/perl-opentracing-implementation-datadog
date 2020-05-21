package OpenTracing::Implementation::DataDog::Scope;

=head1 NAME

OpenTracing::Implementation::DataDog::Scope - Formailzing active spans

=head SYNOPSIS

    duno

=cut

our $VERSION = 'v0.30.1';

use Moo;

BEGIN {
    with 'OpenTracing::Role::Scope';
}

1;