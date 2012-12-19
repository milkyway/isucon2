package Isucon2::Loader;
use common::sense;
use Mouse;
use Carp qw/croak/;
use Readonly;
use Module::Load ();

Readonly my $PACKAGE => 'Pog';

has _loaded => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} },
    lazy    => 1,
);

my $instance;
sub instance { $instance //= shift->new(@_) }

sub load {
    my ($self, $name, @args) = @_;
    croak "Usage: $self->load(\$name[, \@args])" unless $name;
    my $class = join '::', $PACKAGE, $name;
    unless (exists $self->_loaded->{$class}) {
        Module::Load::load($class);
        $self->_loaded->{$class} = $class->new(@args);
    }
    return $self->_loaded->{$class};
}

__PACKAGE__->meta->make_immutable;

1;
