package Borang::HTML::Widget::Text;

use 5.010;
use strict;
use warnings;

use HTML::Entities;

use Mo qw(build default);
extends 'Borang::HTML::Widget';

has size => (is => 'rw');
has max_len => (is => 'rw');
has mask => (is => 'rw');

# TODO: Mask can be a format pattern, e.g.: "##.##.##" This will result in 3
# HTML text fields that can only enter two digits each.

# AUTHORITY
# DATE
# DIST
# VERSION

sub to_html {
    my $self = shift;

    my $value = $self->value;

    join(
        "",
        (defined $self->label ? "<label for=" . $self->name .">".encode_entities($self->label)."<label>" : ''),
        "<input name=", $self->name,
        (defined($self->size) ? " size=".$self->size : ""),
        (defined($self->max_len) ? " maxlength=".$self->max_len : ""),
        (" type=password") x !!$self->mask,
        (" value=\"", encode_entities($value), "\"") x !!defined($value),
        ">",
    );
}

1;
# ABSTRACT: Text input widget

=for Pod::Coverage .+

=head1 ATTRIBUTES

=head2 size => int

=head2 mask => bool

Whether to mask text being entered (e.g. for password entry)
