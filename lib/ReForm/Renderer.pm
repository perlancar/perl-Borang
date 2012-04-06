package ReForm::Renderer;

use 5.010;
use Moo;

has form => (is=>'rw');

sub BUILD {
    my ($self, $args) = @_;
}

1;
# ABSTRACT: Base class for form renderer
