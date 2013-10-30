use v5.14;

package MyApp::Roles::StatusBar {
    use Moose::Role;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_CLOSE EVT_SIZE);

    requires 'gauge_class';

    has 'frame' => (
        is          => 'rw', 
        isa         => 'Wx::Frame',
        required    => 1,
    );
    has 'caption' => (
        is          => 'rw', 
        isa         => 'Str',
        lazy        => 1,
        default     => q{},
    );
    has 'caption_field' => (
        is          => 'rw', 
        isa         => 'Int',
        default     => 0,
        documentation => q{
            The field where the caption goes, starting at 0
        }
    );
    has 'field_count' => (
        is          => 'rw', 
        isa         => 'Int',
        lazy        => 1,
        default     => q{2},
    );
    has 'field_widths' => (
        is          => 'rw', 
        isa         => 'ArrayRef[Int]',
        lazy        => 1,
        default     => sub{ [-1, 100] },
        documentation => q{
            Must contain exactly $self->field_count elements.
            Negatives are proportions (variable width), positives are pixel counts (fixed widths).
        }
    );
    has 'gauge' => (
        is          => 'rw', 
        isa         => 'Maybe[Wx::Gauge]',
        lazy_build  => 1,
    );
    has 'gauge_field' => (
        is          => 'rw', 
        isa         => 'Int',
        default     => 1,
        documentation => q{
            The field where the gauge goes, starting at 0
        }
    );

    sub FOREIGNBUILDARGS {#{{{
        my $self = shift;
        my %args = @_;

        return ( $args{'frame'}, -1 );
    }#}}}
    sub BUILD {
        my $self = shift;
        $self->init();
        return $self;
    }
    sub _build_gauge {#{{{
        my $self = shift;

        my $rect = $self->GetFieldRect( $self->gauge_field );
        my $pos  = Wx::Point->new( $rect->x,       $rect->y );
        my $size = Wx::Size->new ( $rect->width,   $rect->height );

        if( $self->gauge_class eq 'none' ) {
            return;
        }

        my $g = ($self->gauge_class)->new(
            parent      => $self,
            position    => $pos,
            size        => $size,
        );
        return $g;
    }#}}}

    sub init {#{{{
        my $self = shift;

        if( $self->has_gauge ) {
            $self->gauge->Destroy();
            $self->clear_gauge();
        }
        $self->SetFieldsCount( $self->field_count );
        $self->SetStatusWidths( @{$self->field_widths} );
        $self->change_caption( $self->caption );
        $self->gauge;

        return 1;
    }#}}}
    sub change_caption {#{{{
        my $self    = shift;
        my $text    = shift || q{};
        
        my $old_text = $self->GetStatusText( $self->caption_field );
        $self->SetStatusText( $text, $self->caption_field );
        return $old_text;
    }#}}}

    no Moose::Role;
}

1;

__END__

=head1 NAME

MyApp::Roles::StatusBar - Status bar displayed at the bottom of a frame.

=head1 SYNOPSIS

A complete status bar:

 package Some::StatusBar {
  use Moose;
  use MooseX::NonMoose::InsideOut;
  extends 'Wx::StatusBar';
  use MyApp::GUI::Frame::Notepad::StatusBar::Gauge;

  # The gauge_class attribute is required by this role, so it must be
  # declared BEFORE the role itself.

  has 'gauge_class' => ( is => 'rw', isa  => 'Str',
   default => 'Some::Gauge::Implementing::StatusBarGauge::Role',
  );
  with 'MyApp::Roles::StatusBar';

  no Moose;
  __PACKAGE__->meta->make_immutable;
 }

From there, to include your status bar in a frame (assume here that C<$self> is 
your Wx::Frame):

 # Create the status bar
 $status_bar = Some::StatusBar->new(
  frame => $self, caption => "Some String"
 );

 # Add it to the current frame
 $self->SetStatusBar( $status_bar );

 # Define which field of the bar will display helpstrings, which come from
 # mousing over menu items.  Zero-based.
 $self->SetStatusBarPane(1);

To make sure that the status bar continues to display properly when the user 
resizes its parent frame, add this to that parent frame's EVT_SIZE handler:

 $status_bar->init();

=head1 ATTRIBUTES

CHECK this needs documentation

=head1 METHODS

=head2 change_caption

Changes the text displayed in the main caption field.  By default, this is the 
first field.  The caption field can be cleared by sending an empty string, or 
simply by sending no argument at all.

=over 4

=item * ARGS

=over 8

=item * semi-optional scalar - the text to display.

=back

=item * RETURNS

=over 8

=item * scalar - the previously-set caption.

=back

=back

=head2 init

Resizes and resets the status bar and its components, including resetting the 
gauge (if used).  This should be called as part of the parent frame's 
C<EVT_SIZE> event handler.

=over 4

=item * ARGS

=over 8

=item * none

=back

=item * RETURNS

=over 8

=item * true

=back

=back

