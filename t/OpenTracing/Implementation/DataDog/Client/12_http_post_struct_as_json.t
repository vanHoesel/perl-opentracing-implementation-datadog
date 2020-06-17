use Test::Most;

use Test::JSON;
use Test::URI;

use aliased 'OpenTracing::Implementation::DataDog::Client';

use lib 't/lib';
use UserAgent::Fake;

subtest "Test a single request" => sub {
    
    my $http_user_agent;
    lives_ok {
        $http_user_agent = UserAgent::Fake->new
    } "Created a mocked 'http_user_agent'"
    
    or return;
    
    my $datadog_client;
    lives_ok {
        $datadog_client = Client->new(
            http_user_agent => $http_user_agent,
            scheme          => 'https',
            host            => 'test-host',
            port            => '1234',
            path            => 'my/traces',
        ) # we do need defaults here, to not break when ENV was set already
    } "Created a 'datadog_client'"
    
    or return;
    
    my $response;
    lives_ok {
        $response = $datadog_client->http_post_struct_as_json(
            [ 
                { foo => 1, bar => 2 },
                { baz => 3 },
                'Hello World',
            ]
        )
    } "Made a 'http_post_struct_as_json' call"
    
    or return;
    
    my @requests = $http_user_agent->get_all_requests();
    my $test_request = $requests[0];
    
    my $uri = $test_request->uri;
    uri_scheme_ok( $uri, 'https');
    uri_host_ok  ( $uri, 'test-host');
    uri_port_ok  ( $uri, '1234');
    uri_path_ok  ( $uri, '/my/traces');
    
    my $content = $test_request->decoded_content;
    is_json $content, qq/[{"bar":2,"foo":1},{"baz":3},"Hello World"]/,
        "... and send the expected JSON";
    
};


done_testing;
