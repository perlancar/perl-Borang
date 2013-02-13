package ReForm::Renderer::HTML::Control::TextInput;

use 5.010;
use Moo;
extends 'ReForm::Renderer::HTML::Control';

sub render {
    my ($self, %args) = @_;
    my $fn = $args{field_name};
    my $fs = $self->field($fn);

    # XXX path parent
    "<input name=\"$fn\" />\n";
}

1;
# ABSTRACT: Text input HTML form control

=for Pod::Coverage ^(render)$

