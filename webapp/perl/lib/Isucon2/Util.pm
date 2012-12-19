package Pog::Util;
use common::sense;
use Carp qw/croak/;
use FindBin;
use Readonly;
use Try::Tiny;
use Exporter 'import';
use Cwd qw/abs_path/;
use File::Spec;
use Clone qw/clone/;
use Scalar::Util qw/blessed/;
use Hash::Merge ();
use Encode qw/is_utf8 encode_utf8 decode_utf8/;
use Digest::SHA qw/sha1_hex sha256_hex/;
use Crypt::CBC;
use AnyEvent;
use AnyEvent::FIFO;
use Coro qw/unblock_sub/;
use Pog::Config;
use Pog::Log;

our @EXPORT_OK = qw/
    to_sha1 to_sha256 encrypt decrypt
    home merge concurrent
/;

Readonly my $FIFO_NUM => 10;

my $log = Pog::Log->instance->logger;

sub to_sha1 {
    my $str = shift;
    is_utf8($str) ? sha1_hex encode_utf8 $str : sha1_hex $str;
}

sub to_sha256 {
    my $str = shift;
    is_utf8($str) ? sha256_hex encode_utf8 $str : sha256_hex $str;
}

sub encrypt {
    my ($str, $key) = @_;
    &_crypt($key)->encrypt_hex(is_utf8($str) ? encode_utf8 $str : $str);
}

sub decrypt {
    my ($str, $key) = @_;
    $str = &_crypt($key)->decrypt_hex($str);
    is_utf8($str) ? $str : decode_utf8 $str;
}

sub _crypt {
    return Crypt::CBC->new({
        key    => (shift || Pog::Config->instance->config->{util}{crypt_key}),
        cipher => 'Rijndael',
    });
}

sub home {
    my $class = shift;

    my $parts;
    my $file = join '/', split /::/, (blessed $class || $class) . '.pm';
    if (my $path = $INC{$file}) {
        $path =~ s/$file$//;
        my @home = File::Spec->splitdir($path);

        while (@home) {
            last unless $home[-1] =~ /^b?lib$/ || $home[-1] eq '';
            pop @home;
        }

        $parts = [File::Spec->splitdir(abs_path(File::Spec->catdir(@home) || '.'))];
    }
    $parts = [split m{/}, $FindBin::Bin] unless $parts;

    return File::Spec->catdir(@$parts);
}

sub merge {
    my ($a, $b) = @_;
    $a ||= +{};
    $b ||= +{};

    my $merge = Hash::Merge->new;
    my $old_behavior = $merge->get_behavior;
    $merge->specify_behavior({
        SCALAR => {
            SCALAR => sub { $_[1] },
            ARRAY  => sub { $_[1] },
            HASH   => sub { $_[1] },
        },
        ARRAY => {
            SCALAR => sub { $_[1] },
            ARRAY  => sub { $_[1] },
            HASH   => sub { $_[1] },
        },
        HASH => {
            SCALAR => sub { $_[1] },
            ARRAY  => sub { $_[1] },
            HASH   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
        },
    }, 'STRICT_MODE');

    my $config = $merge->merge(clone($a), clone($b));
    $merge->set_behavior($old_behavior);

    return $config;
}

sub concurrent {
    my ($data, $callback, $num) = @_;
    croak 'Usage: fifo($data, $callback[, $num])' unless $data and $callback;
    return 0 unless @$data;

    my $cv   = AE::cv;
    my $fifo = AnyEvent::FIFO->new(max_active => ($num || $FIFO_NUM));
    for my $datum (@$data) {
        $cv->begin;
        $fifo->push(unblock_sub {
            my ($guard, $datum) = @_;
            try { $callback->($datum) } catch { $log->error($_) };
            undef $guard;
            $cv->end;
        }, $datum);
    }
    $cv->recv;

    return 1;
}

1;
