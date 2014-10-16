package Borang::HTML;

use 5.010;
use strict;
use warnings;

use HTML::Entities;
use Perinci::Object;
use Perinci::Sub::Normalize qw(normalize_function_metadata);
use Perinci::Sub::Util::Sort qw(sort_args);
use Text::Markdown qw(markdown);

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

sub _push_text {
    my $self = shift;
    my $r = shift;
    $r->{res} //= "";
    $r->{res} .= join("", @_);
}

sub _gen {
    my ($self, $r, $meta, $values, $parent_args) = @_;

    $r->{prefix} //= "";
    if (!length($r->{prefix})) {
        my $form_name = $parent_args->{name};
        $self->_push_line(
            $r,
            join("",
                 "<form",
                 (defined($form_name) ? " name=$form_name":""),
                 (defined($parent_args->{action}) ? qq[ action="$parent_args->{action}"]:""),
                 (defined($parent_args->{method}) ? qq[ method=$parent_args->{method}]:""),
                 ">",
             )
        );
        $self->_indent($r);
    }

    my $args = $meta->{args} // {};
    for my $argname (sort_args $args) {
        my $fqname = "$r->{prefix}$argname";
        my $argspec = $args->{$argname};
        my $sch = $argspec->{schema} // ['str',{}];
        my ($type, $cl) = ($sch->[0], $sch->[1]);
        my $val = $values->{$argname} // $argspec->{default} //
            $sch->[1]{default};
        if ($argspec->{meta}) {
            $self->_push_line($r, "<div class=subform>");
            $self->_indent($r);
            local $r->{prefix} = ($r->{prefix} ? "$r->{prefix}/":"").
                "$argname/";
            $self->_gen($r, $argspec->{meta}, $val, $parent_args);
            $self->_unindent($r);
            $self->_push_line($r, "</div><!--subform-->");
            next;
        }
        $self->_push_line($r, "<div class=input>");
        $self->_indent($r);
        $self->_push_line(
            $r, "<span class=input_summary>".
                encode_entities(risub($argspec)->langprop('summary') // '').
                    "</span>");
        $self->_push_line($r, "<span class=input_field>");

        if ($type eq 'bool') {
            # choice between radio or select yes/no
            $self->_push_line($r, "<input name=$fqname type=radio value=0".(!$val ? " checked":"")."> off ");
            $self->_push_line($r, "<input name=$fqname type=radio value=1".( $val ? " checked":"")."> on ");
        } else {
            $self->_push_line($r, "<input name=$fqname".
                                  (defined($val) ? ' value="'.encode_entities($val).'"':'').">");
        }

        $self->_push_line($r, "</span>");
        $self->_unindent($r);
        $self->_push_line($r, "</div><!--input-->");

    }

    if (!length($r->{prefix})) {
        $self->_push_line($r, "<div class=input>");
        $self->_push_line($r, "  <span class=input_summary></span>");
        $self->_push_line($r, "  <span class=input_field>");
        $self->_push_line($r, "    <input type=submit>");
        $self->_push_line($r, "  </span>");
        $self->_push_line($r, "</div><!--input-->");

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
        },
        values => {
            summary => 'Form values',
            schema => 'hash',
        },
        name => {
            summary => "HTML form name, will set the <FORM>'s name attribute",
            schema => 'str*',
        },
        method => {
            summary => "HTML form method",
            schema => ['str*', in=>[qw/POST GET/]],
            default => 'POST',
        },
        action => {
            summary => "HTML form action",
            schema => ['str*'],
        },
    },
    result_naked => 1,
};
sub gen_html_form {
    my %args = @_;

    my $meta = $args{meta};
    my $values = $args{values} // {};

    $meta = normalize_function_metadata($meta) unless $args{meta_is_normalized};

    my $r = {};
    my $self = bless {}, __PACKAGE__;
    $self->_gen($r, $meta, $values, \%args);

    my $css = <<'_';
<style>
  form           { display: table }
  .input         { display: table-row }
  .input_summary { display: table-cell; padding: 10px; width: 50% }
  .input_field   { display: table-cell}
  .subform       { padding: 10px }
</style>
_
    $css . $r->{res};
}

# TODO:
# - hint form field length
# - hint when to use textarea instead of input field
#   + when default value contains "\n"
#   + attribute: form.textarea => 1?
# - when to use select?
# - hint to choose which widget?
# - option to show description or show as bubble text

1;
# ABSTRACT: Generate HTML form from Rinci metadata

=for Pod::Coverage ^()$
