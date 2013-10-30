use v5.14;

package MyApp::GUI::MainFrame::StatusBar::Gauge {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_TIMER);

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Gauge';
    with 'MyApp::Roles::StatusBarGauge';

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame::StatusBar::Gauge - Main frame gauge

=head1 SYNOPSIS

Assuming $self is a L<MyApp::GUI::MainFrame::StatusBar>:

 # Get the position and size of the field where we want to place the gauge:
 $rect = $self->GetFieldRect( $self->gauge_field );
 $pos  = Wx::Point->new( $rect->x,       $rect->y );
 $size = Wx::Size->new ( $rect->width,   $rect->height );

 $gauge = MyApp::GUI::MainFrame::StatusBar::Gauge->new(
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

