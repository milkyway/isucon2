package Isucon2::Storage::DB::Connection;
use common::sense;
use Mouse;
use Carp qw/croak/;
use Try::Tiny;
use List::Util qw/shuffle/;
use Module::Load ();
use Isucon2::Config;

has model => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
    lazy    => 1,
);

my $instance;
sub instance { $instance //= shift->new(@_) }

sub connect {
    my ($self, $database, $type) = @_;
    croak "Usage: $self->connect(\$database, \$type)" unless $database and $type;

    my $config = Isucon2::Config->instance->config->{'storage.db.connection'};
    croak "Configuration File Error: $database is not defined" unless $config->{$database};
    croak "Configuration File Error: model is not defined" unless $config->{$database}{model};
    return 0 unless $config->{$database}{$type};

    Module::Load::load($config->{$database}{model});

    for (@{$config->{$database}{$type}}) {
        $_->{connect_options} ||= +{
            RaiseError         => 1,
            ShowErrorStatement => 1,
            PrintWarn          => 0,
            PrintError         => 0,
            AutoCommit         => 1,
            mysql_enable_utf8  => 1,
        };
        push @{$self->model->{$database}{$type}}, $config->{$database}{model}->new($_);
    }

    return $self->model->{$database}{$type} ? 1 : 0;
}

sub master {
    my ($self, $database) = @_;
    croak "Usage: $self->master(\$database)" unless $database;

    unless ($self->model->{$database}{master}) {
        my $connected = $self->connect($database, 'master');
        croak "master connection is not defined" unless $connected;
    }

    return (shuffle @{$self->model->{$database}{master}})[0];
}

sub slave {
    my ($self, $database) = @_;
    croak "Usage: $self->slave(\$database)" unless $database;

    unless ($self->model->{$database}{slave}) {
        my $connected = $self->connect($database, 'slave');
        return $self->master($database) unless $connected;
    }

    return (shuffle @{$self->model->{$database}{slave}})[0];
}

__PACKAGE__->meta->make_immutable;

1;
