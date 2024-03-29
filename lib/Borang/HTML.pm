package Borang::HTML;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

our @ISA;

use Mo qw(build default);
extends 'Borang::BaseEnv';

use HTML::Entities;
use List::Util qw(first max min);
use Locale::TextDomain::UTF8 'Borang';
use Locale::Tie qw($LANG);
use Perinci::Object;
use Perinci::Sub::Normalize qw(normalize_function_metadata);

require Exporter;
push @ISA, qw(Exporter);
our @EXPORT_OK = qw(gen_html_form);

our %SPEC;

sub _md2html {
    require Text::Markdown;
    Text::Markdown::markdown(shift);
}

sub _select_widget {
    my ($self, $r) = @_;

    my $argspec   = $r->{argspec};
    my $argschema = $r->{argschema};
    my ($type, $clset) = @$argschema;

    my $class; # widget class to use
    my $label =
        $clset->{'caption.alt.env.web'} //
        $clset->{'caption'} //
        $clset->{'summary.alt.env.web'} //
        $clset->{'summary'};
    my %cargs = (
        name => $r->{argfqname},
        value => $r->{argvalue} // $clset->{default},
        label => $label,
    ); # class arguments
    $class = $argspec->{"form.widget"};
    if ($class) {
        die "Invalid widget name '$class'" unless $class =~ /\A\w+(::\w+)*\z/;
    } elsif ($type eq 'bool') {
        # XXX choice between radio or select yes/no
        $class = 'Radio';
        $cargs{radios} = [
            {caption=>N__("off"), value=>0},
            {caption=>N__("on"), value=>1},
        ];
    } elsif ($type =~ /^(str|cistr|buf)$/) {

        if ($clset->{in}) {
            $class = "Select";
            $cargs{options} = $clset->{in};
            goto INSTANTIATE_WIDGET;
        }

        $class = "Text";
        my $size_hint = first {defined} (
            $clset->{max_len},
            ($clset->{len_between} ? $clset->{len_between}[1] : undef),
            $clset->{min_len},
            (defined($clset->{default}) ? length($clset->{default}) : undef),
        );
        if (defined $size_hint) {
            $cargs{size} = $size_hint;
            $cargs{size} =  3 if $cargs{size} <  3;
            $cargs{size} = 80 if $cargs{size} > 80;
        }
        if (defined $clset->{max_len}) {
            $cargs{max_len} = $clset->{max_len};
        } elsif (defined $clset->{len_between}) {
            $cargs{max_len} = $clset->{len_between}[1];
        }

    } elsif ($type =~ /^(int|float|num)$/) {

        $class = "Text";
        my $max = max(
            map {abs($_)} (
                grep {defined} (
                    $clset->{min},
                    $clset->{xmin},
                    $clset->{max},
                    $clset->{xmax},
                    ($clset->{between}  ? $clset->{between}[0]  : undef),
                    ($clset->{between}  ? $clset->{between}[1]  : undef),
                    ($clset->{xbetween} ? $clset->{xbetween}[0] : undef),
                    ($clset->{xbetween} ? $clset->{xbetween}[1] : undef),
                    $clset->{default},
                )
            ));
        my $magnitude = log($max)/log(10) if defined($max) && $max > 0;

        if (defined $magnitude) {
            $cargs{size} = $magnitude;
            $cargs{size} = 3 if $cargs{size} < 3;
        }
        if ($type eq 'int') {
            # just enough to type "-" and the number
            $cargs{max_len} = $magnitude+1 if defined $magnitude;
        } elsif ($type eq 'float') {
            # just enough to type "-", integer number, ".", and some digits
            $cargs{max_len} = $magnitude+12 if defined $magnitude;
        }

    } else {
        $class = "Text";
    }

    if ($class eq 'Text') {
        $cargs{mask} //= 1 if $r->{argspec}{is_password} ||
            $r->{argname} =~ /password/i;
    }

  INSTANTIATE_WIDGET:
    $class = "Borang::HTML::Widget::$class";
    {
        (my $classp = "$class.pm") =~ s!::!/!g;
        require $classp;
    }
    $class->new(%cargs);
}

sub hook_before_args {
    my ($self, $r) = @_;

    my $gen_args  = $r->{gen_args};
    if (!length($r->{prefix})) {
        $self->_push_line(
            $r,
            join("",
                 "<form",
                 (defined($gen_args->{name}) ? " name=$gen_args->{name}":""),
                 (defined($gen_args->{action}) ?
                      qq[ action="$gen_args->{action}"]:""),
                 (defined($gen_args->{method}) ?
                      qq[ method=$gen_args->{method}]:""),
                 ">",
             )
        );
        $self->_indent($r);
        for my $var (@{ $gen_args->{additional_hidden_vars} // [] }) {
            $self->_push_line(
                $r,
                join("",
                     "<input name=\"$var\" type=hidden value=\"",
                     encode_entities($r->{values}{$var} // ""), "\">",
                 ),
            );
        }
    }
}

sub hook_before_submeta {
    my ($self, $r) = @_;
    $self->_push_line($r, "<div class=subform>");
    $self->_indent($r);
}

sub hook_after_submeta {
    my ($self, $r) = @_;
    $self->_unindent($r);
    $self->_push_line($r, "</div><!--subform-->");
}

sub hook_before_arg {
    my ($self, $r) = @_;

    my $label =
        $r->{argschema_clset_dh}->langprop('caption', {alt=>[{env=>"web"}], die=>0}) //
        $r->{argschema_clset_dh}->langprop('summary', {alt=>[{env=>"web"}], die=>0}) //
        $r->{argname};

    $self->_push_line($r, "<div class=input>");
    $self->_push_line(
        $r,
        join('',
             "<span class=input_caption><label for=", $r->{argfqname}, ">",
             encode_entities($label),
             "</label></span>",
         )
    );
    $self->_push_line($r, "<span class=input_field>");
    $self->_indent($r);
}

sub hook_process_arg {
    my ($self, $r) = @_;
    my $widget = $self->_select_widget($r);
    $self->_push_line($r, $widget->to_html);
    # XXX if should create confirm field
    if (0) {
        $self->hook_process_arg($r);
    }
}

sub hook_after_arg {
    my ($self, $r) = @_;
    $self->_push_line($r, "</span>");
    $self->_unindent($r);
    $self->_push_line($r, "</div><!--input-->");
}

sub hook_after_args {
    my ($self, $r) = @_;
    if (!length($r->{prefix})) {
        $self->_push_line($r, "<div class=input>");
        $self->_push_line($r, "  <span class=input_caption></span>");
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
    summary => 'Generate HTML form from Rinci metadata',
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
            schema => ['str*'], # XXX url
        },
        additional_hidden_vars => {
            summary => 'Additional form variables to send, '.
                'in hidden input fields',
            schema => ['array*', of=>'str*'],
            description => <<'_',

Pass additional form variable names to send in hidden input fields, if you need.
The values will be taken from the `values` argument.

_
        },
        lang => {
            summary => "Language",
            schema => ['str*'],
            description => <<'_',

This can be set to select:

* the language of messages in Rinci/DefHash properties/attributes, if multiple
  languages are provided.

_
        },
    },
    result_naked => 1,
};
sub gen_html_form {
    my %args = @_;

    my $meta = $args{meta};
    my $values = $args{values} // {};

    $meta = normalize_function_metadata($meta) unless $args{meta_is_normalized};

    local $LANG = $args{lang} if $args{lang};

    my $r = {
        gen_args => \%args,
        meta     => $meta,
        values   => $values,
        prefix   => '',
    };
    my $self = __PACKAGE__->new;
    $self->_gen($r);

    my $css = <<'_';
<style>
  form           { display: table }
  .input         { display: table-row }
  .input_caption { display: table-cell; padding: 10px; width: 50% }
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
# ABSTRACT:

=for Pod::Coverage ^()$

=head1 INTERNAL RECORD ($r)

It is a hash/stash that gets passed around during form generation. The following
are the keys that get set, sorted by the order of setting during form generation
process.

=head2 gen_args => hash

Arguments passed to C<gen_html_form()>.

=head2 meta => hash

=head2 values => hash

=head2 prefix => str

Prefix, should be C<''> (empty string), unless when processing subforms
(argument submetadata) in which is it will be a slash-separated string.

=head2 argname => str

Current argument name that is being processed.

=head2 argfqname => str

Like C<argname>, but fully qualified (e.g. C<a/b> if <b> is a subargument of
C<a>). Provided for convenience. Can also be calculated from C<prefix> and
C<argname>.

=head2 argvalue => any

Current argument's value. Provided for convenience. This is taken from
C<values>, or argument specification's C<default>, or schema's C<default>.

=head2 argspec => array

Current argument's specification. Provided for convenience. Can also be
retrieved via C<< meta->{args}{$argname} >>.

=head2 argschema => array

Current argument's schema. Provided for convenience. Can also be retrieved via
C<< argspec->{schema} >>.
