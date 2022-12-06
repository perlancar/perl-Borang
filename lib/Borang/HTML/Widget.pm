package Borang::HTML::Widget;

use 5.010;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

use Mo qw(build default);

#has form => (is => 'rw');
has name => (is => 'rw');
has value => (is => 'rw');
has label => (is => 'rw');

1;
# ABSTRACT: Base class for HTML form widgets

=head1 ATTRIBUTES

=head2 name => str

Widget name.

=head2 value => any

The current value that the widget stores.
