package ReForm::Control;

use 5.010;
use Moo;

# VERSION

has renderer => (is => 'rw');

has controls => (is => 'rw', default => sub { {} });

our $control_re = qr/\A[A-Za-z_]\w*\z/;

sub field {
    my ($self, $name) = @_;
    $self->renderer->main->form->{fields}{$name};
}

sub get_control {
    my ($self, $name) = @_;

    return $self->controls->{$name} if $self->controls->{$name};

    die "Invalid control name `$name`" unless $name =~ $control_re;
    my $module = ref($self) . "::Control::$name";
    if (!eval "require $module; 1") {
        die "Can't load control module $module".($@ ? ": $@" : "");
    }

    my $obj = $module->new(renderer => $self);
    $self->controls->{$name} = $obj;

    return $obj;
}

1;
# ABSTRACT: Base class for form control

=for Pod::Coverage ^()$

=head1 ATTRIBUTES

=head2 renderer => OBJ

References the form renderer object.


=head1 METHODS

=head2 render(%args) => ANY

Render control.

Arguments:

=over

=item * field => HASH

Field specification.

=back

=cut
