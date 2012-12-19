package Isucon2::Storage::DB::API::Isucon2;
use common::sense;
use Mouse;
extends 'Isucon2::Storage::DB::API';

has '+database' => (default => 'isucon2');

my $instance;
sub instance { $instance //= shift->new(@_) }

__PACKAGE__->meta->make_immutable;

1;
