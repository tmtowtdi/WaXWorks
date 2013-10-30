use v5.14;

package MyApp::Roles::StatusBarGauge {
    use Moose::Role;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_TIMER);

    has 'layout' => (
        is          => 'rw', 
        isa         => 'Int',
    );
    has 'parent' => (
        is          => 'rw', 
        isa         => 'Wx::StatusBar',
        required    => 1,
    );
    has 'position' => (
        is          => 'rw', 
        isa         => 'Wx::Point',
    );
    has 'size' => (
        is          => 'rw', 
        isa         => 'Wx::Size',
    );
    has 'timer' => (
        is          => 'rw', 
        isa         => 'Wx::Timer',
        default     => sub { return Wx::Timer->new },
        handles => {
            start => 'Start',
            stop  => 'Stop',
        }
    );

    sub FOREIGNBUILDARGS {#{{{
        my $self = shift;
        my %args = @_;

        return (
            $args{'parent'},
            -1,
            0,
            $args{'position'}   // wxDefaultPosition,
            $args{'size'}       // wxDefaultSize,
            $args{'layout'}     // wxGA_HORIZONTAL,
        );
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->timer->SetOwner( $self );

        $self->_set_events();
        return $self;
    }
    sub _build_timer {#{{{
        my $self = shift;
        return Wx::Timer->new;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_TIMER(   $self,  $self->timer->GetId,   sub{$self->OnTimer(@_)}     );
        return 1;
    }#}}}

    sub OnTimer {#{{{
        my $self = shift;
        $self->Pulse();
        wxTheApp->Yield;
    }#}}}

    no Moose::Role;
}

1;

__END__

=head1 NAME

MyApp::Roles::StatusBarGauge - Persistent progress meter/throbber 
to be displayed in a status bar.

=head1 SYNOPSIS

Most gauges won't need to do anything other than implement this role; this is 
the complete code for a gauge:

 package MyGauge {
  use Moose;
  use MooseX::NonMoose::InsideOut;
  extends 'Wx::Gauge';
  with 'MyApp::Roles::StatusBarGauge';
  no Moose;
  __PACKAGE__->meta->make_immutable;
 }

To add that gauge to a Wx::StatusBar $status_bar:

 # Get the position and size of the field where we want to place the gauge:
 $rect = $self->GetFieldRect( $status_bar->gauge_field );
 $pos  = Wx::Point->new( $rect->x,       $rect->y );
 $size = Wx::Size->new ( $rect->width,   $rect->height );

 $gauge = MyGauge->new(
  parent      => $status_bar,   # required
  position    => $pos,          # optional
  size        => $size,         # optional
 );

Use an indeterminate "throbber":

 # Start the gauge throbbing:
 wxTheApp->throb_start( $status_bar );

 code_that_takes_some_time_to_run();

 # Stop the gauge
 wxTheApp->throb_end( $status_bar );

=head1 DESCRIPTION

Getting the gauge to reset after it's finished throbbing is unintuitive.  

CHECK FINISH THIS THOUGHT





