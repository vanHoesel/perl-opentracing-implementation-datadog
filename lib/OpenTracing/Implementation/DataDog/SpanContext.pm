package OpenTracing::Implementation::DataDog::SpanContext;

=head1 NAME

OpenTracing::Implementation::DataDog::SpanContext - A DataDog Implementation

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
use MooX::Enumeration;
use MooX::Attribute::ENV;

with 'OpenTracing::Role::SpanContext';

use OpenTracing::Implementation::DataDog::Utils qw/random_64bit_int/;

use Types::Common::String qw/NonEmptyStr/;
use Types::Standard qw/Int/;



has '+trace_id' => (
    is =>'ro',
    isa => Int,
    default => sub{ random_64bit_int() }
);



has service_name => (
    is              => 'ro',
    env_key         => 'DD_SERVICE_NAME',
    required        => 1,
    isa             => NonEmptyStr->where( 'length($_) <= 100' ),
    reader          => 'get_service_name',
);



has service_type => (
    is              => 'ro',
    default         => 'custom',
    enum            => [qw/web db cache custom/],
    handles         => 2, # such that we have `service_type_is_...`
    reader          => 'get_service_type',
);



has resource_name => (
    is              => 'ro',
    isa             => NonEmptyStr->where( 'length($_) <= 5000' ),
    required        => 1,
    reader          => 'get_resource_name',
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

sub with_service_name { $_[0]->_clone( service_name => $_[1] ) }



sub with_service_type { $_[0]->_clone( service_type => $_[1] ) }



sub with_resource_name { $_[0]->_clone( resource_name => $_[1] ) }



# _clone
#
# Creates a shallow clone of the object, which is fine
#
sub _clone {
    my ( $self, @args ) = @_;
    
    bless { %$self, @args }, ref $self;
    
}





=head2 trace_id

=head2 service_name

=head2 service_type

=head2 resource_name



=cut

1;
