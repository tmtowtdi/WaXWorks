use v5.14;

=pod

When the whole app shuts down this gets a resize event, which calls reset(), 
which destroys the gauge.

That's resulting in :
    pure virtual method called
    terminate called without an active exception

    This application has requested the Runtime to terminate it in an unusual 
    way.
    Please contact the application's support team for more information.

...and MyApp::OnExit() then does not get called.



- OnResize
    - calls reset()
        - which destroys the gauge


We need that to happen on a normal resize, or the entire status bar ends up 
all fucked up after the resize.

Also, MyApp::throb_end() is calling reset() as well.  Once the throbber starts 
moving the gauge, there doesn't appear to be any way of clearing it other than 
destroying it and re-creating it.  After it stops, it maintains its last 
position, even if we SetValue(0).

What we need is some way of determining if a given OnResize event is being 
triggered by the app closing down; I'm not sure yet how to do that.


=cut



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
        weak_ref    => 1,
    );
    ##########
    has 'caption' => (
        is          => 'rw', 
        isa         => 'Str',
        lazy        => 1,
        default     => q{},
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
        isa         => 'MyApp::GUI::MainFrame::StatusBar::Gauge',
        lazy_build  => 1,
    );

    sub FOREIGNBUILDARGS {#{{{
        my $self = shift;
        my %args = @_;

        return ( $args{'frame'}, -1 );
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->init();

        $self->_set_events();
        return $self;
    }

    sub _build_gauge {#{{{
        my $self = shift;

        my $rect = $self->GetFieldRect(1);
        my $pos  = Wx::Point->new( $rect->x,       $rect->y );
        my $size = Wx::Size->new ( $rect->width,   $rect->height );

        my $g = MyApp::GUI::MainFrame::StatusBar::Gauge->new(
            parent      => $self,
            position    => $pos,
            size        => $size,
        );
        return $g;

    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_SIZE(   $self,  sub{$self->OnResize(@_)}    );
        return 1;
    }#}}}

    sub init {#{{{
        my $self = shift;

        $self->SetFieldsCount( $self->field_count );
        $self->SetStatusWidths( @{$self->field_widths} );
        $self->change_caption( $self->caption );
        $self->gauge->reset();

        return 1;
    }#}}}
    sub reset {#{{{
        my $self = shift;

        $self->gauge->Destroy();    # init() will re-create it.
        $self->clear_gauge();
        $self->init();

        return 1;
    }#}}}
    sub change_caption {#{{{
        my $self        = shift;
        my $new_text    = shift;

        my $old_text = $self->GetStatusText(0);
        $self->caption($new_text);
        $self->SetStatusText($new_text, 0);
        return $old_text;
    }#}}}

    sub OnResize {#{{{
        my $self        = shift;
        my $status_bar  = shift;
        my $event       = shift;

#my $logger = wxTheApp->resolve( service => '/Log/logger' );
#$logger->component('statusbar');
#$logger->debug('resize');

        if( wxTheApp->has_main_frame ) {
#$logger->debug('resize - with main frame');
            $self->reset();
        }
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
