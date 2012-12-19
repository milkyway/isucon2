use DBIx::Skinny::Schema::Loader qw/make_schema_at/;
print make_schema_at(
  'Isucon2::DB::Schema',
  {},
  [ 'dbi:mysql:isucon2', 'root', '' ]
);
