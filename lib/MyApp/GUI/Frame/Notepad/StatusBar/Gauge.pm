use v5.14;

package MyApp::GUI::Frame::Notepad::StatusBar::Gauge {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_TIMER);

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Gauge';

    has 'range' => (
        is          => 'rw', 
        isa         => 'Int',
        trigger     => \&_set_range,
    );
    has 'timer' => (
        is          => 'rw', 
        isa         => 'Wx::Timer',
        lazy        => 1,
        default     => sub{ Wx::Timer->new },
        handles => {
            start => 'Start',
            stop  => 'Stop',
        }
    );


    sub FOREIGNBUILDARGS {#{{{
        my $self = shift;
        my %args = @_;

        my $rect  = $args{'parent'}->GetFieldRect(1);
        my $range = $args{'range'} || 100;

        return (
            $args{'parent'},
            -1,
            $range,
            $args{'position'}   // wxDefaultPosition,
            $args{'size'}       // wxDefaultSize,
            wxGA_HORIZONTAL
        );
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->timer->SetOwner( $self );
        $self->range(100);

        $self->_set_events();
        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_TIMER(   $self,  $self->timer->GetId,   sub{$self->OnTimer(@_)}     );
        return 1;
    }#}}}
    sub _set_range {#{{{
        my $self  = shift;
        my $range = shift;
        my $prev_range = $self->GetRange();
        $self->SetRange( $range );
        $self->{'range'} = $range;
        return $prev_range;
    }#}}}

    sub reset {#{{{
        my $self = shift;

        ### Just stopping leaves the gauge indicator wherever it left off (at 
        ### least under Windows XP).  reset() clears the indicator. 

        my $old_range = $self->range( 0 );
        $self->SetValue(0);
        $self->range( $old_range );
    }#}}}

    sub OnTimer {#{{{
        my $self = shift;
        $self->Pulse();
        wxTheApp->Yield;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::Frame::Notepad::StatusBar::Gauge - Persistent progress meter/throbber 
displayed in the status bar.

=head1 SYNOPSIS

Assuming $self is a L<MyApp::GUI::Frame::Notepad::StatusBar>:

 # Get the position and size of the field where we want to place the gauge:
 $rect = $self->GetFieldRect( $self->gauge_field );
 $pos  = Wx::Point->new( $rect->x,       $rect->y );
 $size = Wx::Size->new ( $rect->width,   $rect->height );

 $gauge = MyApp::GUI::Frame::Notepad::StatusBar::Gauge->new(
  parent      => $self,
  position    => $pos,
  size        => $size,
 );

Use an indeterminate "throbber":

 # Start the gauge throbbing every 100 milliseconds
 $gauge->start( 100, wxTIMER_CONTINUOUS );

 code_that_takes_some_time_to_run();

 # Stop the gauge
 $gauge->stop();

Or do something with a set endpoint:

 $gauge->range(38);
 my $cnt = 0;
 foreach $element( @array_with_38_elements ) {
    $cnt++;
    do_stuff( $element );
    $gauge->SetValue( $cnt );
 }

Either way, clean up when you're finished:

 $gauge->reset();

