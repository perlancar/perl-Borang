package ReForm::Renderer;

use 5.010;
use Moo;

# VERSION

has main => (is => 'rw');

has controls => (is => 'rw', default => sub { {} });

our $control_re = qr/\A[A-Za-z_]\w*\z/;

sub get_control {
    my ($self, $name) = @_;

    return $self->controls->{$name} if $self->controls->{$name};

    die "Invalid control name `$name`" unless $name =~ $control_re;
    my $module = ref($self) . "::Control::$name";
    if (!eval "require $module; 1") {
        die "Can't load control module $module".($@ ? ": $@" : "");
    }

    my $obj = $module->new(renderer => $self, name => $name);
    $self->controls->{$name} = $obj;

    return $obj;
}

1;
# ABSTRACT: Base class for form renderer

=for Pod::Coverage ^()$

=head1 ATTRIBUTES

=head2 main => OBJ

References the main ReForm object.

=head2 controls => HASH

A mapping between control names and objects, for caching.


=head1 METHODS

=head2 get_control($name) => OBJ

Get control (widget) object.

=cut
