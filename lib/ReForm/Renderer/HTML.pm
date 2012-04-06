package ReForm::Renderer::HTML;

use 5.010;
use Moo;
extends 'ReForm::Renderer';
with 'ReForm::Role::Renderer';

sub render {
    my ($self, $opts) = @_;
    $opts //= {};

    my $form = $self->form;
    my $spec = $form->spec;

    for my $f ($spec->{fields}) {
    }
}

1;
# ABSTRACT: Render form to HTML
