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
    my ($self, %args) = @_;

    my $rf     = $self->main;
    my $prefix = $self->prefix;
    my $form   = $rf->form;

    my $params;
    if ($args{cgi}) {
        $params = $args{cgi}->Vars;
    } elsif (my $env = $args{psgi_env}) {
        require Plack::Request;
        my $preq = Plack::Request->new($env);
        $params = {
            %{ $preq->parameters },
            %{$env->{'riap.request'}{args} // {}},
        };
    } elsif ($args{plack_req}) {
        $params = $args{plack_req}->parameters;
    } else {
        return undef;
    }

    my $data = {};
    for my $fn ($rf->list_field_names) {
        my $fs = $form->{fields}{$fn};

        # select the appropriate control for each field
        my $ctln = $fs->{$prefix . "control"} // $fs->{control} //
            $self->choose_field_control($fn);

        my $ctl = $self->get_control($ctln);
        $ctl->get_data();
    }
    $data;
}

1;
# ABSTRACT: Render form to HTML

=head1 SYNOPSIS


=head1 METHODS

=head2 $rfhtml->render(%args) => STR

Render form to HTML string.

Arguments:

=head2 $rfhtml->get_data(%args) => HASH

Get form data, either from C<CGI> object, L<PSGI> environment, or
L<Plack::Request> object.

Arguments:

=over

=item * cgi => OBJ

A CGI-compatible object.

=item * psgi_env => HASH

A PSGI environment. Internally will be converted to Plack::Request object, but
will also search for C<riap.request> key (containing a hash) to search for form
parameters already put into the C<args> key of that hash, to work together with
L<Plack::Middleware::PeriAHS::ParseRequest> (e.g. retrieving the already
JSON-decoded/YAML-decoded form parameters).

=item * plack_req => OBJ

A Plack::Request object. Will invoke the parameters() method to get the form
variables.

=back

=cut

