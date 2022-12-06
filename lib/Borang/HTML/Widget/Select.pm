package Borang::HTML::Widget::Select;

use 5.010001;
use strict;
use warnings;

use HTML::Entities;

use Mo qw(build default);
extends 'Borang::HTML::Widget';

has options => (is => 'rw');

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
        "<select name=", $self->name, ">",
        (map {"<option>".encode_entities($_)} @{ $self->options }),
        "</select>",
    );
}

1;
# ABSTRACT: Select box input widget
