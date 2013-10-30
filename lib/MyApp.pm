use v5.14;

### CHECK
### POD is missing a lot of methods - fix that.

package MyApp {
    use warnings;

    use Data::Dumper::GUI;
    use DateTime;
    use DateTime::Duration;
    use FindBin;
    use IO::All;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_CLOSE EVT_TIMER);

    use MooseX::NonMoose;
    extends 'Wx::App';

    use MyApp::Model::Container;
    use MyApp::Model::WxContainer;
    use MyApp::GUI::MainFrame;

    our $VERSION = '0.1';

    has 'bb' => (
        is          => 'ro',
        isa         => 'MyApp::Model::Container',
        lazy_build  => 1,
        handles => {
            resolve     => 'resolve',
            root_dir    => 'root_dir',
        },
        documentation => q{
            For non-GUI elements only (database connections, paths, etc).  See 
            wxbb for GUI elements.
        }
    );
    has 'icon_image' => (
        is          => 'ro',
        isa         => 'Str',
        default     => 'shiny_camel_512.png',
        documentation => q{
            Name of an image in assets.zip:/images/icons/.
            Any image size should work, but it will be rescaled to 32x32, so the 
            original should be square.
        }
    );
    has 'logs_expire' => (
        is          => 'ro',
        isa         => 'Int',
        default     => 7,
        documentation => q{
            Log entries older than this many days will be pruned from the 
            logging database on app exit.
        }
    );
    has 'main_frame' => (
        is          => 'ro',
        isa         => 'MyApp::GUI::MainFrame',
        lazy_build  => 1,
    );
    has 'timer' => (
        is          => 'ro',
        isa         => 'Wx::Timer',
        lazy_build  => 1,
    );
    has 'wxbb' => (
        is          => 'ro',
        isa         => 'MyApp::Model::WxContainer',
        lazy_build  => 1,
        handles => {
            wxresolve => 'resolve',
        },
        documentation => q{
            For GUI elements only (images, fonts, etc).  See bb for non-GUI 
            elements.
        }
    );

    sub FOREIGNBUILDARGS {#{{{
        return ();
    }#}}}
    sub BUILD {
        my $self = shift;

        ### Make sure that the logging database has been deployed
        $self->o_creat_database_log();

        ### Set the main frame icon
        $self->main_frame->SetIcon( $self->get_app_icon() );

        ### Set the main frame as the app top window
        $self->SetTopWindow( $self->main_frame );

        ### Log the fact that we've started.
        my $logger = wxTheApp->resolve( service => '/Log/logger' );
        $logger->component(wxTheApp->GetAppName);
        $logger->info( 'Starting ' . wxTheApp->GetAppName() );

        $self->main_frame->Show(1);
        $self->_set_events();
        return $self;
    }
    sub _build_bb {#{{{
        my $self = shift;
        return MyApp::Model::Container->new( name => 'plain container' );
    }#}}}
    sub _build_main_frame {#{{{
        my $self = shift;
        my $frame = MyApp::GUI::MainFrame->new();
        return $frame;
    }#}}}
    sub _build_root_dir {#{{{
        my $self = shift;
        return "$FindBin::Bin/..";
    }#}}}
    sub _build_timer {#{{{
        my $self = shift;

        ### Start the timer with:
        ###     $self->timer->Start( $milliseconds, wxTIMER_ONE_SHOT );
        ### or
        ###     $self->timer->Start( $milliseconds, wxTIMER_CONTINUOUS );
        ###
        ### Those will send a Timer event to us (MyApp.pm) that will be 
        ### handled by OnTimer.

        my $t = Wx::Timer->new();
        $t->SetOwner( $self );
        return $t;
    }#}}}
    sub _build_wxbb {#{{{
        my $self = shift;
        return MyApp::Model::WxContainer->new( name => 'wx container' );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_TIMER( $self, $self->timer->GetId,  sub{$self->OnTimer(@_)} );
        EVT_CLOSE( $self,                       sub{$self->OnClose(@_)} );
        return 1;
    }#}}}

    sub dos2unix {#{{{
        my $self    = shift;
        my $content = shift;

        $content =~ s/0x100x12/0x10/g;
        return $content;
    }#}}}
    sub get_app_icon {#{{{
        my $self = shift;

        my $image = wxTheApp->wxresolve(service => q{/assets/images/icons/} . $self->icon_image);
        $image->Rescale(32,32);
        my $bmp = Wx::Bitmap->new($image);

        my $icon = Wx::Icon->new();
        $icon->CopyFromBitmap($bmp);
        return $icon;
    }#}}}
    sub get_new_window_position {#{{{
        my $self                = shift;
        my $reference_window    = shift || wxTheApp->GetTopWindow;
        my $orig_pos = $reference_window->GetPosition();
        return Wx::Point->new( $orig_pos->x + 30, $orig_pos->y + 30 );
    }#}}}
    sub get_wav {#{{{
        my $self = shift;
        my $file = shift;

        my $path = join '/', (wxTheApp->resolve( service => '/Directory/wav'), $file);
        return unless -e $path;
        return $path;
    }#}}}
    sub o_creat_database_log {#{{{
        my $self = shift;

        unless( -e wxTheApp->resolve(service => '/DatabaseLog/db_file') ) {
            my $log_schema = wxTheApp->resolve( service => '/DatabaseLog/schema' );
            $log_schema->deploy;
        }
        return 1;
    }#}}}
    sub poperr {#{{{
        my $self    = shift;
        my $message = shift || 'Unknown error occurred';
        my $title   = shift || 'Error!';
        Wx::MessageBox($message, $title, wxICON_EXCLAMATION, $self->main_frame );
        return 1;
    }#}}}
    sub popmsg {#{{{
        my $self    = shift;
        my $message = shift || 'Everything is fine';
        my $title   = shift || wxTheApp->GetAppName();
        Wx::MessageBox($message, $title, wxOK | wxICON_INFORMATION, $self->main_frame );
        return 1;
    }#}}}
    sub popconf {#{{{
        my $self        = shift;
        my $question    = shift;
        my $title       = shift || wxTheApp->GetAppName;

        unless( $question ) {
            wxTheApp->poperr(
                "popconf() called without being passed a question; this makes no sense!"
            );
            return 0;
        }

        my $resp = Wx::MessageBox($question,
                                    $title,
                                    wxYES_NO|wxYES_DEFAULT|wxICON_QUESTION|wxSTAY_ON_TOP,
                                    $self->main_frame);
        return $resp;
    }#}}}
    sub throb_end {#{{{
        my $self = shift;
        $self->main_frame->status_bar->gauge->stop();
        $self->main_frame->status_bar->gauge->reset();
        return 1;
    }#}}}
    sub throb_start {#{{{
        my $self    = shift;
        my $pause   = shift || 50;   # milliseconds
        $self->main_frame->status_bar->gauge->start( $pause, wxTIMER_CONTINUOUS );
        return 1;
    }#}}}
    sub unix2dos {#{{{
        my $self    = shift;
        my $content = shift;

        ### Don't muck with it if it's already using DOS line endings.
        return $content if $content =~ /0x100x12/;

        $content =~ s/0x10/0x100x12/g;
        return $content;
    }#}}}

    sub OnExit {#{{{
        my $self = shift;

        my $logger = wxTheApp->resolve( service => '/Log/logger' );
        $logger->component(wxTheApp->GetAppName);

        ### Prune old log entries
        my $now   = DateTime->now();
        my $dur   = DateTime::Duration->new(days => $self->logs_expire);
        my $limit = $now->subtract_duration( $dur );
        $logger->debug('Pruning old log entries');
        $logger->prune_bydate( $limit );
        $logger->info('Closing application');

        return 1;
    }#}}}
    sub OnInit {#{{{
        my $self = shift;
        Wx::InitAllImageHandlers();

        ### If the main frame is closed, the application exits.
        $self->SetExitOnFrameDelete(1);

        ### These don't need to be set to the same string; doing so here for 
        ### eg.
        wxTheApp->SetAppName( "MyApp" );
        wxTheApp->SetClassName( "MyApp" );

        $self->SetVendorName( "Jonathan D. Barton" );

        return 1;
    }#}}}
    sub OnTimer {#{{{
        my $self = shift;
        say "OnTimer called";
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp - wxperl Template Application with some built-in helpers.

=head1 SYNOPSIS

 use MyApp;
 my $app = MyApp->new();
 $app->MainLoop();

=head1 DESCRIPTION

Meant as a starting point for creating new wxperl applications, MyApp provides 
structure, as well as some tools that will be helpful in developing a new app.

=head1 DOCUMENTATION MAP

=over 2

=item * L<MyApp::GettingStarted.pod>

=item * L<MyApp::TBD.pod>

=item * L<MyApp::GUI::MainFrame>

=back

=head1 METHODS

=head2 get_new_window_position 

Returns a Wx::Point to be used as a new dialog's or frame's starting position, 
relative to another window.  Maintains visual consistency so the user knows 
where their new window will pop up.

 # Relative to the main frame
 my $point = wxTheApp->get_new_window_position();

or

 # Relative to $some_other_frame
 my $point = wxTheApp->get_new_window_position( $some_other_frame );

 # Let's get meta!
 my $new_frame = New::Frame::Class->new(
    starting_position => $point,
 );

By default, the point returned will be 30 pixels to the right and 30 pixels 
below the starting point of the referenced window.

=over 4

=item * ARGS

=over 8

=item * optional Wx::Window - defaults to C<wxTheApp-E<gt>ĜetTopWindow>

=back

=item * RETURNS

=over 8

=item * Wx::Point

=back

=item * USAGE

=back

=head2 popconf

Displays a yes/no question dialog and returns the user's response.

=over 4

=item * ARGS

=over 8

=item * scalar - yes/no question to ask the user (required)

=item * scalar - title of the popup window (optional; defaults to the App 
Name).

=back

=item * RETURNS

=over 8

=item * integer - either wxYES or wxNO

If popconf() is called but no question is passed to it, L</poperr> will be 
called, letting you know that you really need to ask a question.  In that 
case, popconf's return value will be false.

=back

=item * USAGE

 if( wxYES == wxTheApp->popconf("Are you really sure", "Really really?") ) {
  # Do Eeet
 }
 else {
  # User did not say 'yes', so don't really do eeet.
 }

wxYES and wxNO are I<both positive integers>, so don't do this:

 if( wxTheApp->popconf("Are you really sure", "Really really?") ) {
  # Do Eeet
 }
 else {
  # User said 'no', so don't really do eeet.
    ### GONNNNNG!  THAT IS WRONG! ###
 }

That code will never hit the else block, even if the user choses 'No', since 
the 'No' response is true.  This is very likely to be A Bad Thing.

=back

=head2 poperr

Displays an error message popup to the user.

 wxTheApp->poperr( "You did something wrong here.", "Whoopsie" );

=over 4

=item * ARGS

=over 8

=item * optional scalar - error message

This is technically optional, and will default to "Unknown error occurred".  
However, that's not terribly helpful, so sending a meaningful error message is 
strongly recommended.

=item * optional scalar - dialog title

Defaults to simply "Error!", which is usually fine.

=back

=item * RETURNS

=over 8

=item * true

=back

=back

=head2 popmsg

Similar to L</poperr>.  The only differences between the two are the icon that 
gets displayed in the popup, and the default dialog title.

 wxTheApp->popmsg( "Some dogs are brown.", "This is a Title" );

=over 4

=item * ARGS

=over 8

=item * optional scalar - Message to display

Like with L</poperr>, calling this without sending a specific message doesn't 
make much sense.  But if you do, the displayed message will defaulit to "Everything 
is fine".

=item * optional scalar - Dialog title

Defaults to wxTheApp->GetAppName()

=back

=item * RETURNS

=over 8

=item * true

=back

=back

=head2 throb_end

=over 4

=item * ARGS

=over 8

=item * none

=back

=item * RETURNS

=over 8

=item * true

=back

=item * USAGE

 wxTheApp->throb_end();

Stops the indeterminate throbber gauge, and resets it (clears its status).  
Does nothing if the throbber was not running.

See L</throb_start>.

=back

=head2 throb_start

=over 4

=item * ARGS

=over 8

=item * Optional scalar - milliseconds to pause between pulses.  Defaults to 
50.

=back

=item * RETURNS

=over 8

=item * true

=back

=item * USAGE

 wxTheApp->throb_start();

Starts pulsing the throbber gauge in the main frame's status bar.  This will 
continue until L</throb_end> is called.

Indicates that the program is doing something.

=back

=head2 unix2dos, dos2unix

Multiline text controls use Unix-style (C<0x10>) line terminators, regardless 
of the current OS.

On Windows, if you're saving a TextCtrl's contents to a file, or pulling a 
file's contents into a TextCtrl, you'll want to use these to change the line 
endings as appropriate.

Note that both L</save_file> and L</open_file> are managing line-ending 
conversions, so you don't need to perform your own conversions if you're using 
those.

=over 4

=item * ARGS

=over 8

=item * scalar - string to be dos-ified (unix2dos) or unix-ified (dos2unix)

=back

=item * RETURNS

=over 8

=item * scalar - the dos-ified (unix2dos) or unix-ified (dos2unix) string.

=back

=back
