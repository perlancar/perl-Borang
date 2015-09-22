package Borang::HTML::Widget::Radio;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;

use HTML::Entities;

use Mo qw(build default);
extends 'Borang::HTML::Widget';

has radios => (is => 'rw');

sub to_html {
    my $self = shift;

    my $value = $self->value;

    my @res;
    for my $item (@{$self->radios}) {
        my $icaption = ref($item) ? $item->{caption} : $item;
        my $ivalue   = ref($item) ? $item->{value} : $item;

        push(
            @res,
            "<input name=", $self->name, " type=radio",
            ((" value=\"", encode_entities($ivalue), "\"") x !!ref($item)),
            ((" checked") x !!(defined($value) && $value eq $ivalue)),
            ">",
            ((" ", encode_entities($icaption)) x !!defined($icaption)),
        );
    }
    join "", @res;
}

1;
# ABSTRACT: Radio group input widget

=for Pod::Coverage .+

=head1 ATTRIBUTES

=head2 radios => array*

A list of radio items. Example:

 ["on", "off"]

Another example:

 [{caption=>"on", value=>1}, {caption=>"off", value=>0}]
