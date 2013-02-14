package ReForm::Renderer::HTML;

use 5.010;
use Moo;
extends 'ReForm::Renderer';

# VERSION

sub prefix { "html_" }

sub render {
    require SHARYANTO::String::Util;

    my ($self, %args) = @_;
    my $rf = $self->main;

    my $prefix = $self->prefix;

    my $form   = $rf->form;
    my @res;

    push @res, "<form>\n";
    for my $fn ($rf->list_field_names) {
        my $fs = $form->{fields}{$fn};

        # select the appropriate control for each field
        my $ctln = $fs->{$prefix . "control"} // $fs->{control} //
            $self->choose_field_control($fn);
        my $ctl = $self->get_control($ctln);
        push @res, SHARYANTO::String::Util::indent(
            "  ", $ctl->render(field_name => $fn)
        );
    }
    push @res, "</form>\n";

    join("", @res);
}

sub choose_field_control {
    my ($self, $fn) = @_;
    my $fs = $self->main->form->{fields}{$fn};

    my $dtype = $fs->{schema} ? $fs->{schema}[0] : undef;
    if ($dtype eq 'bool') {
        return 'CheckBox';
    } else {
        return 'TextInput';
    }
}

sub get_data {
    # also get control for each field
}

1;
# ABSTRACT: Render form to HTML

=head1 SYNOPSIS


=head1 METHODS

=head2 render

=head2

=cut

