package OpenTracing::Implementation::DataDog::Client;

=head1 NAME

OpenTracing::Implementation::DataDog::Client - A Client that sends off the spans

=head1 SYNOPSIS

    use alias OpenTracing::Implementation::DataDog::Client;
    
    my $datadog_client = ->new(
        http_user_agent => LWP::UserAgent->new();
        host            => 'localhost',
        port            => '8126',
        path            => 'v0.3/traces',
    ); # these are defaults

and later:

    $datadog_client->send_span( $span );

=cut



=head1 DESCRIPTION

The main responsabillity of this C<Client> is to provide the C<send_span>
method, that will send the data to the local running DataDog agent.

It does this by calling L<to_struct> that massages the generic OpenTracing data,
like C<baggage_items> from L<SpanContext> and C<tags> from C<Span>, together
with the DataDog specific data like C<resource_name>.

This structure will be send of as a JSON string to the local installed DataDog
agent.

=cut



our $VERSION = 'v0.43.3';

use English;

use Moo;
use MooX::Attribute::ENV;
use MooX::HandlesVia;
use MooX::ProtectedAttributes;
use MooX::Should;

use Carp;
use HTTP::Request ();
use JSON::MaybeXS qw(JSON);
use LWP::UserAgent;
use PerlX::Maybe qw/maybe provided/;
use Types::Standard qw/ArrayRef Enum HasMethods/;
use Types::URI qw/Uri/;

use OpenTracing::Implementation::DataDog::Utils qw(
    nano_seconds
);



=head1 OPTIONAL ATTRIBUTES

The attributes below can be set during instantiation, but none are required and
have sensible defaults, that may actually play nice with known DataDog
environment variables

=cut



=head2 C<http_user_agent>

A HTTP User Agent that connects to the locally running DataDog agent. This will
default to a L<LWP::UserAgent>, but any User Agent will suffice, as long as it
has a required delegate method C<request>, that takes a L<HTTP::Request> object
and returns a L<HTTP::Response> compliant response object.

=cut

has http_user_agent => (
    is => 'lazy',
    should => HasMethods[qw/request/],
    handles => { _send_http_request => 'request' },
);

sub _build_http_user_agent {
    return LWP::UserAgent->new( )
}



=head2 C<scheme>

The scheme being used, should be either C<http> or C<https>,
defaults to C<http>

=cut

has scheme => (
    is => 'ro',
    should => Enum[qw/http https/],
    default => 'http',
);



=head2 C<host>

The host-name where the DataDog agent is running, which defaults to
C<localhost> or the value of C<DD_AGENT_HOST> environment variable if set.

=cut

has host => (
    is      => 'ro',
    env_key => 'DD_AGENT_HOST',
    default => 'localhost',
);



=head2 C<port>

The port-number the DataDog agent is listening at, which defaults to C<8126> or
the value of the C<DD_TRACE_AGENT_PORT> environment variable if set.

=cut

has port => (
    is => 'ro',
    env_key => 'DD_TRACE_AGENT_PORT',
    default => '8126',
);



=head2 C<path>

The path the DataDog agent is expecting requests to come in, which defaults to
C<v0.3/traces>.

=cut

has path => (
    is => 'ro',
    default => 'v0.3/traces',
);
#
# maybe a 'version number' would be a better option ?



=head2 C<agent_url>

The complete URL the DataDog agent is listening at, and defaults to the value of
the C<DD_TRACE_AGENT_URL> environment variable if set. If this is set, it takes
precedence over any of the other settings.

=cut

has agent_url => (
    is => 'ro',
    env_key => 'DD_TRACE_AGENT_URL',
    default => undef,
    should  => Uri,
);



has uri => (
    is => 'lazy',
    init_arg => undef,
);

sub _build_uri {
    my $self = shift;
    
    return
        $self->agent_url
        //
        "$self->{ scheme }://$self->{ host }:$self->{ port }/$self->{ path }"
}
#
# URI::Template is a nicer solution for this and more dynamic



protected_has _default_http_headers => (
    is          => 'lazy',
    isa         => ArrayRef,
    init_arg    => undef,
    handles_via => 'Array',
    handles     => {
        _default_http_headers_list => 'all',
    },
);

sub _build__default_http_headers {
    return [
        'Content-Type'                  => 'application/json; charset=UTF-8',
        'Datadog-Meta-Lang'             => 'perl',
        'Datadog-Meta-Lang-Interpreter' => $EXECUTABLE_NAME,
        'Datadog-Meta-Lang-Version'     => $PERL_VERSION->stringify,
        'Datadog-Meta-Tracer-Version'   => $VERSION,
    ]
}



has _json_encoder => (
    is              => 'lazy',
    init_arg        => undef,
    handles         => { _json_encode => 'encode' },
);

sub _build__json_encoder {
    JSON()->new->utf8->canonical->pretty
}
#
# I just love readable and consistant JSONs



protected_has _span_buffer => (
   is          => 'rw',
   isa         => ArrayRef,
   init_args   => undef,
   default     => sub { [] },
   handles_via => 'Array',
   handles     => {
       _buffer_span         => 'push',
       _buffered_spans      => 'all',
       _empty_span_buffer   => 'clear',
   },
);



=head1 DELEGATED INSTANCE METHODS

The following method(s) are required by the L<DataDog::Tracer|
OpenTracing::Implementation::DataDog::Tracer>:

=cut



=head2 C<send_span>

This method gets called by the L<DataDog::Tracer|
OpenTracing::Implementation::DataDog::Tracer> to send a L<Span> with its
specific L<DataDog::SpanContext|OpenTracing::Implementation::DataDog::Tracer>.

This will typically get called during C<on_finish>.

=head3 Required Positional Arguments

=over

=item C<$span>

A L<OpenTracing Span|OpenTracing::Interface::Span> compliant object, that will
be serialised (using L<to_struct> and converted to JSON).

=back

=head3 Returns

A boolean, that comes from L<< C<is_succes>|HTTP::Response#$r->is_success >>.

=cut

sub send_span {
    my $self = shift;
    my $span = shift;
    
    $self->_buffer_span($span);
    
    return $self->_flush_span_buffer();
}



=head1 INSTANCE METHODS

=cut



=head2 C<to_struct>

Gather required data from a single span and its context, tags and baggage items.

=head3 Required Positional Arguments

=over

=item C<$span>

=back

=head3 Returns

a hashreference with the following keys:

=over

=item C<trace_id>

=item C<span_id>

=item C<resource>

=item C<service>

=item C<type> (optional)

=item C<env> (optional)

=item C<hostname> (optional)

=item C<name>

=item C<start>

=item C<duration>

=item C<parent_id> (optional)

=item C<error> (TODO)

=item C<meta> (optional)

=item C<metrics>

=back

=head3 Notes

This data structure is specific for sending it through the DataDog agent and
therefore can not be a intance method of the DataDog::Span object.

=cut

sub to_struct {
    my $self = shift;
    my $span = shift;
    
    my $context = $span->get_context();
    
    my %meta_data = (
        $span->get_tags,
        $context->get_baggage_items,
    );
    
    # fix issue with meta-data, values must be string!
    %meta_data =
        map { $_ => "$meta_data{$_}" } keys %meta_data
    if %meta_data;
    
    my $data = {
        trace_id  => $context->trace_id,
        span_id   => $context->span_id,
        resource  => $context->get_resource_name,
        service   => $context->get_service_name,
        
        maybe
        type      => $context->get_service_type,
        
        maybe
        env       => $context->get_environment,
        
        maybe
        hostname  => $context->get_hostname,
        
        name      => $span->get_operation_name,
        start     => nano_seconds( $span->start_time() ),
        duration  => nano_seconds( $span->duration() ),
        
        maybe
        parent_id => $span->get_parent_span_id(),
        
#       error     => ... ,
        
        provided %meta_data,
        meta      => { %meta_data },
        
#       metrics   => ... ,
    };
    
    # TODO: use Hash::Ordered, so we can control what will be the first item in
    #       the long string of JSON text. But this needs investigation on how
    #       this behaves with JSON
    
    return $data
}



=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=item L<DataDog Docs API Tracing|https://docs.datadoghq.com/api/v1/tracing/>

The DataDog B<Agent API> Documentation.

=item L<LWP::UserAgent>

Web user agent class

=item L<JSON::Maybe::XS>

Use L<Cpanel::JSON::XS> with a fallback to L<JSON::XS> and L<JSON::PP>

=item L<HTTP::Request>

HTTP style request message

=item L<HTTP::Response>

HTTP style response message

=back



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'OpenTracing::Implementation::DataDog'
is Copyright (C) 2019 .. 2021, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut



# _flush_span_buffer
#
# Flushes the spans in the span buffer and send them off to the DataDog agent
# over HTTP.
#
# Returns the number off flushed spans or `undef` in case of an error.
#
sub _flush_span_buffer {
    my $self = shift;
    
    my @structs = map {$self->to_struct($_) } $self->_buffered_spans();
    
    my $resp = $self->_http_post_struct_as_json( [ \@structs ] );
    
    return
        unless $resp->is_success;
    
    $self->_empty_span_buffer();
    
    return scalar @structs;
}



# _http_headers_with_trace_count
#
# Returns a list of HTTP Headers needed for DataDog
#
# This feature was originally added, so the Trace-Count could dynamically set
# per request. That was a design flaw, and now the count is hardcoded to '1',
# until we figured out how to send multiple spans.
#
sub _http_headers_with_trace_count {
    my $self = shift;
    my $count = shift;
    
    return (
        $self->_default_http_headers_list,
        
        maybe
        'X-Datadog-Trace-Count' => $count,
    )
}



# _http_post_struct_as_json
#
# Takes a given data structure and sends an HTTP POST request to the tracing
# agent.
#
# It is the caller's responsibility to generate the correct data structure!
#
# Returns an HTTP::Response object, which may indicate a failure.
sub _http_post_struct_as_json {
    my $self = shift;
    my $struct = shift;
    
    my $encoded_data = $self->_json_encode($struct);
    do { warn "$encoded_data\n" }
        if $ENV{OPENTRACING_DEBUG};
    
    my @headers = $self->_http_headers_with_trace_count( scalar @{$struct->[0]} );
    my $rqst = HTTP::Request->new( 'POST', $self->uri, \@headers, $encoded_data );
        
    my $resp = $self->_send_http_request( $rqst );
    
    return $resp;
}

1;
