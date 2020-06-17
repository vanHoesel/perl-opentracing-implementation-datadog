requires        "OpenTracing::Role", '>= v0.81.2';
requires        "OpenTracing::Implementation", '0.03';

requires        "Carp";
requires        "Exporter";
requires        "HTTP::Request";
requires        "HTTP::Response::Maker";
requires        "JSON::MaybeXS";
requires        "LWP::UserAgent";
requires        "Moo";
requires        "Moo::Role";
requires        "MooX::Attribute::ENV";
requires        "MooX::HandlesVia";
requires        "MooX::Enumeration";
requires        "PerlX::Maybe";
requires        "Ref::Util";
requires        "Sub::Trigger::Lock";
requires        "Syntax::Feature::Maybe";
requires        "Try::Tiny";
requires        "Types::Common::String";
requires        "Types::Interface";
requires        "Types::Standard";
requires        "Type::Tiny::XS";
requires        "aliased";
requires        "syntax";

on 'develop' => sub {
    requires    "ExtUtils::MakeMaker::CPANfile";
};

on 'test' => sub {
    requires    "Test::JSON";
    requires    "Test::Most";
    requires    "Test::OpenTracing::Interface";
    requires    "Test::URI";
};
