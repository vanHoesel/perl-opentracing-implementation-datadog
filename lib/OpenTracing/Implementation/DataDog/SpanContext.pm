package OpenTracing::Implementation::DataDog::SpanContext;

use strict;
use warnings;

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

with 'OpenTracing::Role::SpanContext';

use OpenTracing::Implementation::DataDog::Utils qw/random_64bit_int/;

use Carp;
use List::Util qw/any/;
use Ref::Util qw/is_hashref/;
use Types::Standard qw/is_Int/;
use Types::Common::String qw/is_NonEmptyStr/;


# There used to Moo attributes here that had type-checks and made some required.
# But cleaner design made it that developers must still use the parameters and
# will be checked as before, but they will be merged into any given baggage_item
# hash
around BUILDARGS => sub {
    my ( $orig, $class, %args ) = @_;
    
    my $trace_id = delete $args{ trace_id } // random_64bit_int();
    croak "Type mismatch: 'trace_id' must be 'Int'"
        unless is_Int( $trace_id );
    
    my $service_type = delete $args{ service_type } // 'custom';
    croak "Type mismatch: 'service_type' must be 'Enum'"
        unless any { /^$service_type$/ } qw/web db cache custom/;
    
    croak "Missing required 'service_name'"
        unless exists $args{ service_name };
    my $service_name = delete $args{ service_name };
    croak "Type mismatch: 'service_name' must be 'NonEmptyStr'"
        unless is_NonEmptyStr( $service_name );
    
    croak "Missing required 'resource_name'"
        unless exists $args{ resource_name };
    my $resource_name = delete $args{ resource_name };
    croak "Type mismatch: 'resource_name' must be 'NonEmptyStr'"
        unless is_NonEmptyStr( $resource_name );
    
    my %datadog_items = (
        trace_id      => $trace_id,
        service_type  => $service_type,
        service_name  => $service_name,
        resource_name => $resource_name,
    );
    
    # merge new datadog_items into exisitng baggage items (if they exisit)
    #
    my %baggage_items =
        exists $args{ baggage_items }
        &&
        is_hashref( $args{ baggage_items } )
        ?
        ( %{ delete $args{ baggage_items }}, %datadog_items )
        :
        ( %datadog_items );
    
    return {
        %args,
        baggage_items => \%baggage_items
    }
};



=head1 CONSTRUCTORS



=head2 new

    my $span_context = SpanContext->new(
        service_name  => "MyFancyService",
        resource_name => "/clients/{client_id}/contactdetails",
        baggage_items => { $key => $value, .. },
    );

Creates a new SpanContext object;



=head3 parameters

=over

=item trace_id

=item service_name

=item service_type

=item resource_name

=back



=cut

1;
