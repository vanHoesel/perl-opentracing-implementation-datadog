package OpenTracing::Implementation::DataDog::SpanContext;

=head1 NAME

OpenTracing::Implementation::DataDog::SpanContext - Keep track of traces

=head1 SYNOPSIS

    use aliased OpenTracing::Implementation::DataDog::SpanContext;
    
    my $span_context = SpanContext->new(
        service_name  => "MyFancyService",
        service_type  => "web",
        resource_name => "/clients/{client_id}/contactdetails",
    );
    #
    # please do not add parameter values in the resource,
    # use tags instead, like:
    # $span->set_tag( client_id => $request->query_params('client_id') )

=cut

use Moo;
use MooX::Attribute::ENV;
use MooX::Enumeration;

with 'OpenTracing::Role::SpanContext';

use OpenTracing::Implementation::DataDog::Utils qw/random_64bit_int/;

use Types::Common::String qw/NonEmptyStr/;
use Types::Standard qw/Int/;



has '+trace_id' => (
    isa => Int,
    default => sub{ random_64bit_int() }
);



has service_name => (
    is              => 'ro',
    env_key         => 'DD_SERVICE_NAME',
    required        => 1,
    isa             => NonEmptyStr->where( 'length($_) <= 100' ),
);



has service_type => (
    is              => 'ro',
    default         => 'custom',
    enum            => [qw/web db cache custom/],
    handles         => 2, # such that we have `service_type_is_...`
);



has resource_name => (
    is              => 'ro',
    isa             => NonEmptyStr->where( 'length($_) <= 5000' ),
    required        => 1,
);



=head1 CONSTRUCTORS



=head2 new

    my $span_context = SpanContext->new(
        service_name  => "MyFancyService",
        resource_name => "/clients/{client_id}/contactdetails",
        baggage_items => { $key => $value, .. },
    );

Creates a new SpanContext object;



=head1 ATTRIBUTES



=head2 trace_id

=head2 service_name

=head2 service_type

=head2 resource_name



=cut

1;
