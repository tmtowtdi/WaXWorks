use v5.14;

### If you're trying to change which field holds the helpstrings produced by 
### mousing over menu items, that setting is in MainFrame.pm, not here.  See 
### the call to SetStatusBarPane() in MainFrame.pm.

package MyApp::GUI::MainFrame::StatusBar {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_CLOSE EVT_SIZE);

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::StatusBar';

    use MyApp::GUI::MainFrame::StatusBar::Gauge;

    has 'frame' => (
        is          => 'rw', 
        isa         => 'Wx::Frame',
        required    => 1,
    );
    ##########
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
        default     => q{3},
    );
    has 'field_widths' => (
        is          => 'rw', 
        isa         => 'ArrayRef[Int]',
        lazy        => 1,
        default     => sub{ [-1, 200, 100] },
        documentation => q{
            Must contain exactly $self->field_count elements.
            Negatives are proportions (variable width), positives are pixel counts (fixed widths).
        }
    );
    has 'gauge' => (
        is          => 'rw', 
        isa         => 'MyApp::GUI::MainFrame::StatusBar::Gauge',
        lazy_build  => 1,
    );
    has 'gauge_field' => (
        is          => 'rw', 
        isa         => 'Int',
        default     => 2,
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
        $self->_init();
        return $self;
    }

    sub _init {#{{{
        my $self = shift;

        $self->SetFieldsCount( $self->field_count );
        $self->SetStatusWidths( @{$self->field_widths} );
        $self->change_caption( $self->caption );
        $self->gauge->reset();

        return 1;
    }#}}}
    sub _build_gauge {#{{{
        my $self = shift;

        my $rect = $self->GetFieldRect( $self->gauge_field );
        my $pos  = Wx::Point->new( $rect->x,       $rect->y );
        my $size = Wx::Size->new ( $rect->width,   $rect->height );

        my $g = MyApp::GUI::MainFrame::StatusBar::Gauge->new(
            parent      => $self,
            position    => $pos,
            size        => $size,
        );
        return $g;
    }#}}}

    sub change_caption {#{{{
        my $self    = shift;
        my $text    = shift || q{};
        
        my $old_text = $self->GetStatusText( $self->caption_field );
        $self->SetStatusText( $text, $self->caption_field );
        return $old_text;
    }#}}}
    sub resize {#{{{
        my $self = shift;

        $self->gauge->Destroy();    # _init() will re-create it.
        $self->clear_gauge();
        $self->_init();

        return 1;
    }#}}}


    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame::StatusBar - Status bar displayed at the bottom of the 
main frame.

=head1 SYNOPSIS

Assuming $self is a Wx::Frame onto which you want to add a status bar:

 # Create the status bar
 $status_bar = MyApp::GUI::MainFrame::StatusBar->new(
  frame => $self, caption => "Some String"
 );

 # Add it to the current frame
 $self->SetStatusBar( $status_bar );

 # Define which field of the bar will display helpstrings, which come from
 # mousing over menu items.  Zero-based.
 $self->SetStatusBarPane(1);

To make sure that the status bar continues to display properly when the user 
resizes its parent frame, add this to that parent frame's EVT_SIZE handler:

 $status_bar->resize();

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

=head2 resize

Resizes the status bar and its components.  This should be called as part of 
the parent frame's C<EVT_SIZE> event handler.

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

