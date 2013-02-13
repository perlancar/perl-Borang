package ReForm;

use 5.010;
use Log::Any qw($log);
use Moo;

# VERSION

our $renderer_re = qr/\A[A-Za-z_]\w*\z/;

has form      => (is => 'ro');
has parent    => (is => 'ro');
has renderers => (is => 'rw');

sub BUILD {
    require Data::Sah;

    my ($self, $args) = @_;

    # normalize fields' schemas. currently this replaces in-place.
    unless ($args->{form_is_normalized}) {
        $self->{form}{fields} //= {};
        for my $fn (keys %{ $self->{form}{fields} }) {
            next unless $self->{form}{fields}{$fn}{schema};
            $self->{form}{fields}{$fn}{schema} = Data::Sah::normalize_schema(
                $self->{form}{fields}{$fn}{schema}
            );
        }
    }

    # reuse parent's 'renderers'
    if ($self->{parent}) {
        $self->{renderers} = $self->{parent}{renderers};
    } else {
        $self->{renderers} = {};
    }
}

sub get_renderer {
    my ($self, $name) = @_;
    return $self->renderers->{$name} if $self->renderers->{$name};

    die "Invalid renderer name `$name`" unless $name =~ $renderer_re;
    my $module = "ReForm::Renderer::$name";
    if (!eval "require $module; 1") {
        die "Can't load renderer module $module".($@ ? ": $@" : "");
    }

    my $obj = $module->new(main => $self);
    $self->renderers->{$name} = $obj;

    return $obj;
}

sub list_field_names {
    my ($self) = @_;
    my $ff = $self->{form}{fields};
    return sort {
        if (defined($ff->{$a}{pos}) && defined($ff->{$b}{pos})) {
            return $ff->{$a}{pos} <=> $ff->{$b}{pos};
        } elsif (defined($ff->{$a})) {
            return -1;
        } elsif (defined($ff->{$b})) {
            return 1;
        } else {
            return $a cmp $b;
        }
    } keys %$ff;
}

1;

# ABSTRACT: Yet another form handling module

=head1 SYNOPSIS

 use ReForm;
 my $i;
 my $form = {
     name => 'Ask some personal information',
     fields => {
         first_name => {
             schema => ['str*', min_len=>1, max_len=>50],
             req    => 1,
             pos    => ($i = 0),
         },
         last_name => {
             schema => ['str*', min_len=>1, max_len=>100],
             req    => 1,
             pos    => ++$i,
         },
         gender => {
             schema => ['str*', in => [qw/M F/]],
             pos    => ++$i,
         },
     },
 };
 my $rf = ReForm->new(form => $form);

 # HTML

 my $rfhtml = $rf->get_renderer('HTML');

 ## get form data
 my $data   = $rfhtml->get_data(psgi_env => $env); # or cgi_obj => $q

 ## render form
 my $html   = $rfhtml->render();

 ## render form (prefilled with data)
 $html      = $rfhtml->render(data => $data);

 # console

 my $rfconsole = $rf->get_renderer('Console');

 ## get form data
 my $data = $rfconsole->get_data();

 ## render form
 my $text = $rfconsole->render(data => $data);


=head1 DESCRIPTION

L<ReForm> is yet another form handling module/framework. Features:

=over

=item * Clearer separation between semantics (e.g. boolean data type) and presentation (e.g. checkbox or radio Yes/No or select Yes/No)

=item * Subforms

=item * Translation

=item * Multiple renderers: console, TUI (ncurses), HTML

=item * HTML renderer: CSS, AJAX, jQuery, Bootstrap, templates, multipage form

=back


=head1 ATTRIBUTES

=head2 form => HASH

Form specification. See L</"FORM SPECIFICATION">.

=head2 renderers => HASH

A mapping of renderer name and objects, for caching.


=head1 METHODS

=head2 new(%args)

Options:

=over

=item * form_is_normalized => BOOL (default: 0)

If set to 1, will assume form is already normalized and will not
normalize it (e.g. normalize the schemas of form fields, etc).

=back

=head2 $rf->get_renderer($name) => OBJ

Get renderer object (ReForm::Renderer::$name).

=head2 $rf->list_field_names => LIST

List form field names, sorted by position (C<pos>).


=head1 FORM SPECIFICATION

Form specification is a L<DefHash>.

Specification version: 1.

=head2 Properties

=head3 Property: name => STR

From DefHash.

=head3 Property: summary => STR

From DefHash.

=head3 fields => HASH

Mapping of field name and specification. See L</"FIELD SPECIFICATION">.


=head1 FIELD SPECIFICATION

A DefHash.

=head2 Properties

=head3 Property: name => STR

From DefHash.

=head3 Property: summary => STR

From DefHash.

=head3 Property: schema => STR/ARRAY

Sah schema.

=head3 Property: req => BOOL (default: 0)

=head3 Property: pos => [int, min=>1]


=head1 FAQ


=head1 SEE ALSO

Other manuals: L<ReForm::Manual::Tutorial>

Modules used: L<DefHash>, L<Data::Sah>

Other form handling frameworks/modules: XXX

=cut
