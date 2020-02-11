requires        "OpenTracing::Role", '0.05';
requires        "OpenTracing::Implementation", '0.03';

requires        "Carp";
requires        "Exporter";
requires        "HTTP::Request";
requires        "JSON::MaybeXS";
requires        "LWP::UserAgent";
requires        "List::Util";
requires        "Moo";
requires        "Moo::Role";
requires        "MooX::Attribute::ENV";
requires        "MooX::HandlesVia";
requires        "PerlX::Maybe";
requires        "Ref::Util";
requires        "Sub::Trigger::Lock";
requires        "Syntax::Feature::Maybe";
requires        "Time::HiRes";
requires        "Try::Tiny";
requires        "Types::Common::String";
requires        "Types::Interface";
requires        "Types::Standard";
requires        "aliased";
requires        "syntax";

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires    "Test::Most";
};
