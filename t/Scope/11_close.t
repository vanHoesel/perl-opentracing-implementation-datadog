use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!

=head1 DESCRIPTION

Test that a class that consumes the role, it complies with OpenTracing Interface

=cut

use strict;
use warnings;

use OpenTracing::Implementation::DataDog::Scope;

our @close_arguments;

my $test_obj = new_ok(
    'OpenTracing::Implementation::DataDog::Scope' => [
        on_close => sub {
            push @main::close_arguments, [ @_ ];
            return;
        },
    ], "Test Object"
);

lives_ok {
    $test_obj->close( )
} "... can do a close";

cmp_deeply(
    [ @close_arguments ] => [
        [ obj_isa('OpenTracing::Implementation::DataDog::Scope') ],
    ],
    "... our 'on_close' CodeRef has been called"
);

throws_ok {
    $test_obj->close( )
} qr/Can't close an already closed scope/,
    "... and can not close again";



done_testing();
