package ReForm::Control;

use 5.010;
use Moo;

# VERSION

has renderer => (is => 'rw');
has name     => (is => 'rw');

our $control_re = qr/\A[A-Za-z_]\w*\z/;

sub field {
    my ($self) = @_;
    $self->renderer->main->form->{fields}{ $self->name };
}

1;
# ABSTRACT: Base class for form control

=for Pod::Coverage ^()$

=head1 ATTRIBUTES

=head2 renderer => OBJ

References the form renderer object.

=head2 name => STR

Field name.

=head1 METHODS

=head2 render(%args) => ANY

Render control.

Arguments:

=over

=item * field => HASH

Field specification.

=back

=cut
