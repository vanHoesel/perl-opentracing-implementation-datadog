package OpenTracing::Implementation::DataDog;

=head1 NAME

OpenTracing::Implementation::DataDog - A Global Tracer Implentation

=cut



use aliased 'OpenTracing::Implementation::DataDog::Tracer';


sub bootstrap {
    my $implementation_class = shift;
    
    my @implementation_args  = @_;
    
    return Tracer->new( @implementation_args );
}



1;
