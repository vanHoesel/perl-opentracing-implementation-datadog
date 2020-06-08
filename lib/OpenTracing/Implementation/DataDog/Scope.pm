package OpenTracing::Implementation::DataDog::Scope;

=head1 NAME

OpenTracing::Implementation::DataDog::Scope - A DataDog specific Scope

=head SYNOPSIS

    duno

=cut



our $VERSION = '0.04_003';

use Moo;

BEGIN {
    with 'OpenTracing::Role::Scope';
}

1;