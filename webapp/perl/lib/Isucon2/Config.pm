package Isucon2::Config;
use common::sense;
use Mouse;
use Path::Class::Dir;
use Config::Any;

has dir => (
    is      => 'ro',
    isa     => 'Path::Class::Dir',
    default => sub {
        require Isucon2::Util;
        Path::Class::Dir->new(Isucon2::Util::home(__PACKAGE__), '/conf');
    },
    lazy    => 1,
);

has pattern => (
    is      => 'ro',
    isa     => 'RegexpRef',
    default => sub { qr{([^/]+?)\.(?:conf|ya?ml|pl|ini)$} },
    lazy    => 1,
);

has config => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

my $instance;
sub instance { $instance //= shift->new(@_) }

sub _build_config {
    my $self    = shift;
    my $pattern = $self->pattern;
    my $config  = Config::Any->load_files({
        files           => [grep { $_ =~ m/$pattern/ } $self->dir->children],
        use_ext         => 1,
        flatten_to_hash => 1,
    });

    for my $path (keys %$config) {
        (my $file) = $path =~ m/$pattern/;
        $config->{$file} = delete $config->{$path};
    }

    return $config;
}

__PACKAGE__->meta->make_immutable;

1;
