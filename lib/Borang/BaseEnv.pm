package Borang::BaseEnv;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;

use Mo qw(build default);

use Perinci::Object;
use Perinci::Sub::Util::Sort qw(sort_args);

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

sub _langprop {
    my ($self, $r, $dh, $prop) = @_;
    risub($dh)->langprop({lang=>$r->{gen_args}{lang}}, $prop);
}

sub _gen {
    my ($self, $r) = @_;

    $self->hook_before_args($r);

    my $args = $r->{meta}{args} // {};
    for my $argname (sort_args $args) {
        my $argfqname = "$r->{prefix}$argname";
        my $argspec   = $args->{$argname};
        my $argschema = $argspec->{schema} // ['str',{}];
        my $argvalue  = $r->{values}{$argname} // $argspec->{default} //
            $argschema->[1]{default};

        local $r->{argname}   = $argname;
        local $r->{argfqname} = $argfqname;
        local $r->{argvalue}  = $argvalue;
        local $r->{argspec}   = $argspec;
        local $r->{argschema} = $argschema;

        if ($argspec->{meta}) {
            local $r->{prefix} =
                ($r->{prefix} ? "$r->{prefix}/":""). "$argname/";
            local $r->{meta} = $argspec->{meta};
            local $r->{values} = $argvalue // {};
            $self->hook_before_submeta($r);
            $self->_gen($r);
            $self->hook_after_submeta($r);
            next;
        }

        $self->hook_before_arg($r);
        $self->hook_process_arg($r);
        $self->hook_after_arg($r);
    }

    $self->hook_after_args($r);
}
1;
# ABSTRACT: Base class for Borang form environment

=for Pod::Coverage ^(.+)$

=head1 DESCRIPTION

This is the base class for:

 Borang::HTML
 Borang::CLI
 Borang::CUI
 Borang::GUI


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

