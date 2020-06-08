package OpenTracing::Implementation::DataDog::Utils;

=head1 NAME

OpenTracing::Implementation::DataDog::Utils - DataDog Utilities

=cut

our $VERSION = 'v0.30.1';

use Exporter qw/import/;

our @EXPORT_OK = qw/random_64bit_int nano_seconds/;

=head1 EXPORTS OK

The following subroutines can be imported into your namespance:

=cut



=head2 random_64bit_int

Generates a 64bit integers (or actually a 63bit, or signed 64bit)

=cut

sub random_64bit_int { int(rand( 2**63 )) }



=head2 nano_seconds

To turn floatingpoint times into number of nano seconds

=cut

sub nano_seconds { int( $_[0] * 1_000_000_000 ) }




1;