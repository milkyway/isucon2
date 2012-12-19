package Isucon2::API;
use common::sense;
use Mouse;
use Isucon2::Config;
#use Isucon2::Log;
use Isucon2::Storage::DB::API::Isucon2;
#use Isucon2::Util::Loader;

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { Isucon2::Config->instance->config },
    lazy    => 1,
);

has _db => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{ isucon2 => isucon2::Storage::DB::API::Isucon2->instance } },
    lazy    => 1,
);

sub db {
    my ($self, $database) = @_;
    $self->_db->{$database || 'isucon2'};
}

#sub log { Pog::Log->instance->logger }

sub loader {
    my ($self, $name, @args) = @_;
    $name = $name ? "API::$name" : 'API';
    Isucon2::Util::Loader->instance->load($name, @args);
}

#sub g      { Pog::Util::Loader->instance->load('Service::Google') }
#sub police { Pog::Util::Loader->instance->load('Service::Police') }

__PACKAGE__->meta->make_immutable;

1;
