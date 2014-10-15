package Borang::HTML;

use 5.010;
use strict;
use warnings;

use Perinci::Sub::Util::Sort qw(sort_args);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gen_html_form);

our %SPEC;

sub _indent {
    my ($self, $r) = @_;
    $r->{indent}++;
}

sub _unindent {
    my ($self, $r) = @_;
    $r->{indent}--;
    die "BUG: negative indent" if $r->{indent} < 0;
}

sub _push_line {
    my $self = shift;
    my $r = shift;
    $r->{res} //= "";
    $r->{res} .= (("  ") x ($r->{indent}//0)) . "$_\n" for @_;
}

sub _gen {
    my ($self, $r, $meta) = @_;

    $r->{prefix} //= "";
    if (!length($r->{prefix})) {
        $self->_push_line($r, "<form>");
        $self->_indent($r);
    }

    my $args = $meta->{args} // {};
    for my $argname (sort_args $args) {
        my $argspec = $args->{$argname};
        my $sch = $argspec->{schema} // ['str',{}];
        my ($type, $cl) = ($sch->[0], $sch->[1]);
        $self->_push_line($r, "<input>");
    }

    if (!length($r->{prefix})) {
        $self->_unindent($r);
        $self->_push_line($r, "</form>");
    }
}

$SPEC{gen_html_form} = {
    v => 1.1,
    args => {
        meta => {
            schema => 'hash*',
        },
        meta_is_normalized => {
            schema => 'bool',
        }
    },
    result_naked => 1,
};
sub gen_html_form {
    my %args = @_;

    my $meta = $args{meta};
    unless ($args{meta_is_normalized}) {
        require Perinci::Sub::Normalize;
        $meta = Perinci::Sub::Normalize::normalize_function_metadata($meta);
    }

    my $r = {};
    my $self = bless {}, __PACKAGE__;
    $self->_gen($r, $meta);
    $r->{res};
}

1;
# ABSTRACT: Generate HTML form from Rinci metadata

=for Pod::Coverage ^()$
