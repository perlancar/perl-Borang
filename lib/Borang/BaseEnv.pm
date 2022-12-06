package Borang::BaseEnv;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;

use Mo qw(build default);

use Hash::DefHash;
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
        local $r->{argschema_type}  = $argschema->[0];
        local $r->{argschema_clset} = $argschema->[1];
        local $r->{argschema_clset_dh} = defhash($argschema->[1]);

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


=head1 INTERNAL RECORD

Hash. Usually named C<$r>. It is a stash of name-value pairs that gets passed
around during form generation. The following are the keys that get set, sorted
by the order of setting during form generation process.

=head2 gen_args

Hash. Arguments passed to C<gen_html_form()>.

=head2 meta

Hash (DefHash).

=head2 values

Hash.

=head2 prefix

Str. Prefix, should be C<''> (empty string), unless when processing subforms
(argument submetadata) in which is it will be a slash-separated string.

=head2 argname

Str. Current argument name that is being processed.

=head2 argfqname

Str. Like C<argname>, but fully qualified (e.g. C<a/b> if <b> is a subargument
of C<a>). Provided for convenience. Can also be calculated from C<prefix> and
C<argname>.

=head2 argvalue

Any. Current argument's value. Provided for convenience. This is taken from
C<values>, or argument specification's C<default>, or schema's C<default>.

=head2 argspec

Array. Current argument's specification. Provided for convenience. Can also be
retrieved via C<< meta->{args}{$argname} >>.

=head2 argschema

Array. Current argument's schema (normalized). Provided for convenience. Can
also be retrieved via C<< argspec->{schema} >>.

=head2 argschema_type

Str. The type name of the current argument's schema, which is the first element
of the C<argschema> array.

=head2 argschema_clset

Hash (DefHash). The clause set of the current argument's schema, which is the
second element of the C<argschema> array.

=head2 argschema_clset_dh

Object. A L<Hash::DefHash> object instantiated from C<argschema_clset>.

=cut
