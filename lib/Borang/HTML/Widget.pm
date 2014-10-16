package Borang::HTML::Widget;

# DATE
# WARNING

use 5.010;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

1;
# ABSTRACT: Base class for HTML form widgets
