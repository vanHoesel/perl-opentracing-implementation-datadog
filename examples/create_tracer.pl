use lib '../lib';

use strict;
use warnings;

use aliased 'OpenTracing::Implementation::DataDog::Tracer';
use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

my $tracer = Tracer->new;

#use DDP; p $tracer->agent;


my $span_context = SpanContext->new(
    resource_name => 'some_resource',
    service_name  => 'my_test_app',
);

#use DDP; p $span_context;

do {
    my $scope = $tracer->start_active_span( "Foo" , child_of => $span_context );
    
    
    do {
        my $scope1 = $tracer->start_active_span( "Bar1"  );
        $scope1->close();
    };
    
    
    do {
        my $scope2 = $tracer->start_active_span( "Bar2"  );
        $scope2->get_span->set_baggage_item( extra => 'stuff');
        $scope2->get_span->set_tag( 'http.method' => 'GET' );
        do {
            my $scope9 = $tracer->start_active_span( "Quux"  );
            $scope9->get_span->set_tag( 'db.instance' => "mysql.host");
            $scope9->close();
        };
         $scope2->close();
    };
    
    
    do {
        my $scope3 = $tracer->start_active_span( "Bar3"  );
#       $scope3->close();
    };
    
    
    do {
        my $scope4 = $tracer->start_active_span( "Bar4"  );
        $scope4->close();
    };
    
#   use DDP; p $scope;
#   use DDP; p $scope->get_span;
    
    $scope->close();
    
    undef $scope;
};

sleep 0;

__END__
