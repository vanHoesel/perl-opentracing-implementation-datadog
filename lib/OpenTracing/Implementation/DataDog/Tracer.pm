package OpenTracing::Implementation::DataDog::Tracer;

use strict;
use warnings;


our $VERSION = 'v0.40.0.7-TRIAL';

=head1 NAME

OpenTracing::Implementation::DataDog::Tracer - Keep track of traces

=head1 SYNOPSIS

    use aliased 'OpenTracing::Implementation::DataDog::Tracer';
    use aliased 'OpenTracing::Implementation::DataDog::Agent';
    use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';
    
    my $TRACER = Tracer->new(
        agent                 => Agent->new(),
    );

and later

    sub foo {
        
        my $scope = $TRACER->start_active_span( 'Operation Name' => %options );
        
        ...
        
        $scope->close;
        
        return $foo
    }

=cut

use syntax 'maybe';

use Moo;

with 'OpenTracing::Role::Tracer';

use aliased 'OpenTracing::Implementation::DataDog::Agent';
use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';
use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use Ref::Util qw/is_plain_hashref/;
use Types::Standard qw/Object/;



=head1 DESCRIPTION

This is a L<OpenTracing SpanContext|OpenTracing::Interface::SpanContext>
compliant implementation with DataDog specific extentions

=cut



=head1 EXTENDED ATTRIBUTES

=cut



=head2 C<scope_manager>

A L<OpenTracing::Types::ScopeManger> that now defaults to a
L<DataDog::ScopeManger|OpenTracing::Implementation::DataDog::ScopeManager>

=cut

has '+scope_manager' => (
    default => sub { ScopeManager->new },
);



=head1 DATADOG SPECIFIC ATTRIBUTES

=cut



=head2 C<agent>

An agent that has a C<send_span> method that will get called on a `on_finish`.

See L<DataDog::Agent|OpenTracing::Implementation::DataDog::Agent> for more.

It also accepts a plain hash refference with key-value pairs suitable to
construct a Agent.

=cut

has agent => (
    is          => 'lazy',
    isa         => Object,
    handles     => [qw/send_span/],
    coerce
    => sub { is_plain_hashref $_[0] ? Agent->new( %{$_[0]} ) : $_[0] },
    default     => sub { {} }, # XXX this does not return an Object !!!
);



sub extract_context {
    undef
}



sub inject_context { ... }



sub build_span {
    my $self = shift;
    my %opts = @_;
    
    my $span = Span->new(
        
        operation_name  => $opts{ operation_name },
        
        child_of        => $opts{ child_of },
        
        maybe
        start_time      => $opts{ start_time },
        
        maybe
        tags            => $opts{ tags },
        
        context         => $opts{ context },
        
        on_finish     => sub {
            my $span = shift;
            $self->send_span( $span )
        },
        
    );
    
    return $span
}



sub build_context {
    my $self = shift;
    my %opts = @_;
    
    my $span_context = SpanContext->new(
        
        resource_name   => $opts{ resource_name },
        
        maybe
        service_name    => $opts{ service_name },
        
        maybe
        service_type    => $opts{ service_type },
    );
    
    return $span_context
}

=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=item L<OpenTracing::Role::Tracer>

Role for OpenTracing Implementations.

=back



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'OpenTracing::Implementation::DataDog'
is Copyright (C) 2019 .. 2020, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut

1;
