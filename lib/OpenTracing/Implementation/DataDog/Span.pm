package OpenTracing::Implementation::DataDog::Span;

our $VERSION = 'v0.30.1';

use syntax 'maybe';

use Moo;

with 'OpenTracing::Role::Span';

use OpenTracing::Implementation::DataDog::Utils qw/random_64bit_int/;

use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use Types::Standard qw/Str/;
use Ref::Util qw/is_plain_hashref/;
use Carp;
has '+operation_name' => (
    isa => Str->where( 'length($_) <= 100' ),
);



has '+span_id' => (
    default => sub{ random_64bit_int() }
);



has '+context' => (
    coerce
    => sub { is_plain_hashref $_[0] ? SpanContext->new( %{$_[0]} ) : $_[0] },
    default
    => sub { croak "Can not construct a default SpanContext" },
);

# OpenTracing does not provide any public method to instantiate a SpanContext.
# But rootspans do need to have a context which comes from
# the `$TRACER->extract_context` call, or it returns `undef` if there was no
# such context.
# Passing in a plain hash reference instead of a SpanContext will
# instantiate such context with a 'fresh' `trace_id`



1;
