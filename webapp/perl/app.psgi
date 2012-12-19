#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use FindBin::libs;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/extlib/lib/perl5";

use Isucon2;
use Isucon2::API;

use Plack::Builder;
use Devel::KYTProf;
my $isucon2 = Isucon2->new;

Devel::KYTProf->add_prof(
    "Text::Xslate",
    "render",
    sub {
        my ($orig, $self, $file, $args) = @_;
        return sprintf '%s %s', "render", $file;
    },
    threshold => 0,
    mutes     => [qw/
        DBI
        DBI::st
        Cache::Memcached::Fast
    /],
);
builder {
    enable 'Static',
        path => qr!^/(?:(?:css|js|images)/|favicon\.ico$)!,
        root => $isucon2->root_dir . '/public';
    $isucon2->psgi;
};
