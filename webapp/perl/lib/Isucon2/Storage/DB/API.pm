package Isucon2::Storage::DB::API;
use common::sense;
use Mouse;
use Isucon2::Storage::DB::Connection;

has database => (
    is  => 'ro',
    isa => 'Str',
);

has connection => (
    is      => 'ro',
    isa     => 'Isucon2::Storage::DB::Connection',
    default => sub { Isucon2::Storage::DB::Connection->instance },
    lazy    => 1,
);

sub master { $_[0]->connection->master($_[0]->database) }
sub slave  { $_[0]->connection->slave($_[0]->database)  }

# master
sub insert         { shift->master->insert(@_) }
sub bulk_insert    { shift->master->bulk_insert(@_) }
sub find_or_create { shift->master->find_or_create(@_) }
sub update         { shift->master->update(@_) }
sub delete         { shift->master->delete(@_) }

# slave
sub count             { shift->slave->count(@_) }
sub single            { shift->slave->single(@_) }
sub search            { shift->slave->search(@_) }
sub search_named      { shift->slave->search_named(@_) }
sub search_by_sql     { shift->slave->search_by_sql(@_) }
sub search_rs         { shift->slave->search_rs(@_) }
sub search_with_pager { shift->slave->search_with_pager(@_) }
sub rs                { shift->slave->resultset(@_) }
sub rs_with_pager     { shift->slave->resultset_with_pager(@_) }

# txn
sub txn_scope    { shift->master->txn_scope(@_) }
sub txn_begin    { shift->master->txn_begin(@_) }
sub txn_commit   { shift->master->txn_commit(@_) }
sub txn_rollback { shift->master->txn_rollback(@_) }
sub txn_end      { shift->master->txn_end(@_) }

__PACKAGE__->meta->make_immutable;

1;
