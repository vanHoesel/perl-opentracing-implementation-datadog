use Test::Most;
use HTTP::Headers;


use aliased 'OpenTracing::Implementation::DataDog::Tracer';



subtest 'No default_context or callback' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new( );
    } "Can create a Tracer, without any attributes";
    
    
    my $test_span_context;
    lives_ok {
        $test_span_context = $test_tracer
            ->extract_context(
                bless( { foo => 0, bar => [ 1, 2 ] }, 'HTTP::Headers' )
            )
        #
        # XXX: this needs a FORMAT and a carrier
    } "... and can call 'extract_context'";
    
    ok !defined $test_span_context,
        "... but returns 'undef'"
};

subtest 'HTTP Headers' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new(
            default_service_name  => 'test',
            default_resource_name => '/path',
        );
    } "Can create a Tracer, with default service name";
    
    my $trace_id = '5611920385980137472';
    my $span_id  = '8888811111122222200';
    
    my $test_span_context;
    lives_ok {
        $test_span_context = $test_tracer->extract_context(HTTP::Headers->new(
             "x-datadog-trace-id"  => $trace_id,
             "x-datadog-parent-id" => $span_id,
        ))
    } "... and can call 'extract_context'";
    
    ok defined $test_span_context, "... and returns a context";
    is $test_span_context->trace_id, $trace_id, 'trace id';
    is $test_span_context->span_id, $span_id, 'span id';
};

done_testing( );
