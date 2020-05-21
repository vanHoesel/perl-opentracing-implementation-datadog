package OpenTracing::Implementation::DataDog::Span;

our $VERSION = 'v0.30.1';

use syntax 'maybe';

use Moo;

with 'OpenTracing::Role::Span';

use OpenTracing::Implementation::DataDog::Utils qw(
    random_64bit_int
    nano_seconds
);

use Types::Standard qw/CodeRef Object/;



has '+span_id' => (
    default => sub{ random_64bit_int() }
);



1;
