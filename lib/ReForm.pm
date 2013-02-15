package ReForm;

use 5.010;
use Log::Any qw($log);
use Moo;

# VERSION

our $renderer_re = qr/\A[A-Za-z_]\w*\z/;

has spec      => (is => 'ro');
has parent    => (is => 'rw'); # for subform
has renderers => (is => 'rw');

sub BUILD {
    require Data::Sah;

    my ($self, $args) = @_;

    # normalize fields' schemas.
    unless ($args->{spec_is_normalized}) {
        $self->{spec}{fields} //= {};
        my $ff = $self->{spec}{fields};
        for my $fn (keys %$ff) {
            next unless $ff->{$fn}{schema};
            $ff->{$fn}{schema} = Data::Sah::normalize_schema(
                $ff->{$fn}{schema});
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

 # create form specification (form spec is common to all kinds of forms: HTML,
 # Console, etc)

 my $i;
 my $form_spec = {
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

 # HTML form

 my $rf = ReForm::HTML->new(spec => $form_spec);

 ## get form data from PSGI env (or Plack request, or CGI object)
 my $res = $rf->get_data(psgi_env => $env); # -> {first_name=>'...', ...}
 my $data = $res->[2] if $res->[0] == 200;

 ## render to HTML
 say $rf->render; # -> '<form><input name=first_name>...'

 ## render to HTML (prefill with data)
 say $rf->render(data => $data);

 # Console form

 $rf = ReForm::Console->new(spec => $form_spec):

 ## render to STDOUT as well as get data from STDIN
 $res = $rf->render();
 $data = $res->[2] if $res->[0] == 200;


=head1 DESCRIPTION

L<ReForm> is yet another form handling module/framework. Features:

=over

=item * Clearer separation between semantics (e.g. boolean data type) and presentation (e.g. checkbox or radio Yes/No or select Yes/No)

=item * Subforms

=item * Multipage form

=item * Translation

=item * Multiple renderers: HTML, Console, ncurses (planned), Wx (possible)

=item * HTML renderer: CSS, AJAX, jQuery, Bootstrap, templates

=back


=head1 ATTRIBUTES

=head2 spec => HASH

Form specification. See L</"FORM SPECIFICATION">.


=head1 METHODS

=head2 new(%args)

You can pass attributes to set them and any of the options below:

=over

=item * spec_is_normalized => BOOL (default: 0)

If set to 1, will assume form specification is already normalized and will not
normalize it (e.g. normalize the schemas of form fields, etc).

=back

=head2 $rf->render(%opts)


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
