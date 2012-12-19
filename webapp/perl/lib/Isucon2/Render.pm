package Pog::Util::Render;
use common::sense;
use Carp qw/croak/;
use Exporter 'import';
use Encode ();
use Text::CSV_XS;
use Text::Xslate;
use Pog::Util ();

our @EXPORT_OK = qw/render_template/;

sub render_template {
    my ($template, $vars, $type) = @_;
    croak 'Usage: render_template($template, $vars[, $type])' unless $template and $vars;

    my $tx = Text::Xslate->new(
        path   => ('/home/homepage/webapp/perl/views'),
        type   => ($type || 'html'),
        module => [
            'Text::Xslate::Bridge::TT2Like' => [
                -exclude => [qw/array::sort array::nsort hash::sort hash::nsort/],
            ],
        ],
    );
    my $str = $tx->render("${template}.tx", $vars);
    chomp $str;
    return $str;
}

1;
