package OpenTracing::Implementation::DataDog::Tracer;

use strict;
use warnings;

=head1 NAME

OpenTracing::Implementation::DataDog::Tracer - Keep track of traces

=head1 SYNOPSIS

    use aliased 'OpenTracing::Implementation::DataDog::Tracer';
    use aliased 'OpenTracing::Implementation::DataDog::Agent';
    use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';
    
    my $TRACER = Tracer->new(
        agent                 => Agent->new(),
        scope_manager         => ScopeManager->new(),
        default_scope_builder => sub {
            return {
                service_name  => 'Your Service name',
                resource_name => 'Some Resource name',
            }
        },
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

use aliased 'OpenTracing::Implementation::DataDog::Span';
use aliased 'OpenTracing::Implementation::DataDog::SpanContext';
use aliased 'OpenTracing::Implementation::DataDog::Agent';
use aliased 'OpenTracing::Implementation::DataDog::ScopeManager';

use Carp;
use Ref::Util qw/is_plain_hashref/;
use Types::Standard qw/HashRef InstanceOf Maybe Object CodeRef/;


has agent => (
    is          => 'lazy',
    isa         => Object,
    handles     => [qw/send_span/],
    coerce
    => sub { is_plain_hashref $_[0] ? Agent->new( %{$_[0]} ) : $_[0] },
    default     => sub { {} },
);


has default_context => (
    is          => 'lazy',
    isa
    => Maybe[InstanceOf['OpenTracing::Implementation::DataDog::SpanContext']],
    coerce
    => sub { is_plain_hashref $_[0] ? SpanContext->new( %{$_[0]} ) : $_[0] },
    reader      => 'get_default_context',
    writer      => 'set_default_context',
);


sub _build_default_context {
    shift->default_context_builder->( @_ );
}


has default_context_builder => (
    is          => 'lazy',
    isa         => CodeRef,
    default     => sub { croak "Can not construct a default SpanContext" }
);



=head1 CAVEATS

C<extract_context> and C<inject_context> do not support any off the defined
methods at all. All that C<extract_context> does at this moment, is providing a
deafault C<SpanContext>, either given or cuntructed using a code-reference in
C<default_context_builder>

=cut



sub extract_context { $_[0]->get_default_context() }



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
        
        on_DEMOLISH     => sub {
            my $span = shift;
            $self->send_span( $span )
        },
        
    );
    
    return $span
}



sub _build_scope_manager {
    my $self = shift;
    
    return ScopeManager->new( @_ )
}

1;

