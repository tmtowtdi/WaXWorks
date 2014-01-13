use v5.14;

package MyApp {
    use warnings;

    use Data::Dumper;
    use DateTime;
    use DateTime::Duration;
    use IO::All;
    use Moose;
    use Try::Tiny;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_CLOSE EVT_TIMER);

    use MooseX::NonMoose;
    extends 'Wx::App';

    use MyApp::Types;
    use MyApp::Model::Assets;
    use MyApp::Model::Database;
    use MyApp::Model::Dirs;
    use MyApp::Model::Fonts;
    use MyApp::Model::Logger;
    use MyApp::GUI::MainFrame;

    our $VERSION = '0.1';

    has 'root_dir' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        required    => 1,
        writer      => '_update_root_dir',
        coerce      => 1,
    );
    ##########
    has 'assets' => (
        is          => 'ro',
        isa         => 'MyApp::Model::Assets',
        lazy_build  => 1,
    );
    has 'database' => (
        is          => 'ro',
        isa         => 'MyApp::Model::Database',
        lazy        => 1,
        default     => sub{ return MyApp::Model::Database->new( data_dir => $_[0]->dirs->data ) },
    );
    has 'dirs' => (
        is          => 'ro',
        isa         => 'MyApp::Model::Dirs',
        lazy        => 1,
        default     => sub{ return MyApp::Model::Dirs->new( root => $_[0]->root_dir ) },
    );
    has 'fonts' => (
        is          => 'ro',
        isa         => 'MyApp::Model::Fonts',
        lazy        => 1,
        default     => sub{ return MyApp::Model::Fonts->new() },
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
    has 'logger' => (
        is          => 'rw',
        isa         => "MyApp::Model::Logger",
        lazy_build  => 1,
    );
    has 'main_frame' => (
        is          => 'ro',
        isa         => 'MyApp::GUI::MainFrame',
        lazy_build  => 1,
        handles => {
            throb_start => 'throb_start',
            throb_end   => 'throb_end',
        },
    );
    has 'timer' => (
        is          => 'ro',
        isa         => 'Wx::Timer',
        lazy_build  => 1,
    );



    sub FOREIGNBUILDARGS {#{{{
        return ();
    }#}}}
    sub BUILD {
        my $self = shift;

        ### Ensure the root_dir exists and clean it up
        $self->_update_root_dir( $self->root_dir->absolute->resolve );

        ### Set the main frame icon
        $self->main_frame->SetIcon( $self->get_app_icon() );

        ### Set the main frame as the app top window
        $self->SetTopWindow( $self->main_frame );

        ### Log the fact that we've started.
        $self->logger->component( wxTheApp->GetAppName );
        $self->logger->info( 'Starting ' . wxTheApp->GetAppName() );

        $self->main_frame->Show(1);
        $self->_set_events();
        return $self;
    }
    sub _build_assets {#{{{
        my $self = shift;
        return MyApp::Model::Assets->new(
            assets_root => $self->dirs->assets,
            zip_file    => $self->dirs->assets->file( 'assets.zip' ),
        )
    }#}}}
    sub _build_main_frame {#{{{
        my $self = shift;
        my $frame = MyApp::GUI::MainFrame->new();
        return $frame;
    }#}}}
    sub _build_logger {#{{{
        my $self = shift;
        my $l = MyApp::Model::Logger->new( schema => $self->database->logs_schema );
        return $l;
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
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE(      $self,                       sub{$self->OnClose(@_)}    );
        EVT_TIMER(      $self, $self->timer->GetId,  sub{$self->OnTimer(@_)}    );
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

        my $image = $self->assets->image_from_zip( 'images/icons/' . $self->icon_image );
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
    sub get_sound {#{{{
        my $self = shift;
        my $file = shift;

        my $path = $self->dirs->wav->file( $file );
        unless( $path->stat ) {
            wxTheApp->poperr("'$file' does not exist - cannot play sound.");
            return;
        };

        my $sound = Wx::Sound->new($path);
        unless( $sound->IsOk ) {
            wxTheApp->poperr("'$path' exists but appears not to be a sound file.");
            return;
        }

        ### Ubuntu will get to here (if fed a valid wav file).  But it won't 
        ### play it - afaict this is a wx 2.8/wxperl/ubuntu known problem.
        return $sound;
    }#}}}
    sub poperr {#{{{
        my $self    = shift;
        my $message = shift || 'Unknown error occurred';
        my $title   = shift || 'Error!';
        Wx::MessageBox($message, $title, wxICON_EXCLAMATION, $self->main_frame );
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
    sub popmsg {#{{{
        my $self    = shift;
        my $message = shift || 'Everything is fine';
        my $title   = shift || wxTheApp->GetAppName();
        Wx::MessageBox($message, $title, wxOK | wxICON_INFORMATION, $self->main_frame );
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

        $self->logger->component(wxTheApp->GetAppName);

        ### Prune old log entries
        my $now   = DateTime->now();
        my $dur   = DateTime::Duration->new(days => $self->logger->logs_expire);
        my $limit = $now->subtract_duration( $dur );
        $self->logger->debug('Pruning old log entries');
        $self->logger->prune_bydate( $limit );
        $self->logger->info('Closing application');

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

=item * L<wxwidgets documentation|http://docs.wxwidgets.org/2.8/wx_contents.html>

CHECK as I write this I'm still on wxwidgets 2.8, but 3.0 was just released 
yesterday.  It's not showing up in Synaptic yet, and wxperl is not using it 
yet.  When all that gets sorted and we do switch over to 3.0, fix the link 
above to point to the right place.

=item * L<MyApp::GettingStarted.pod>

=item * L<MyApp::GUI::MainFrame>

=back

=head1 METHODS

Arguments in B<bold> are required.

=head2 get_app_icon

B<ARGS> - ()

B<RETURNS> - (Wx::Icon)

 $some_frame->SetIcon( wxTheApp->get_app_icon() );

Returns the Wx::Icon being used by the application.  When creating a new 
frame, it will default to using the OS's default "unassigned" icon.  To 
replace that with the main icon:

=head2 get_new_window_position 

B<ARGS> - (Wx::Window)

B<RETURNS> - (Wx::Point)

 # Relative to the main frame
 my $point = wxTheApp->get_new_window_position();

Returns a Wx::Point to be used as a new dialog's or frame's starting position, 
relative to another window.  Maintains visual consistency so the user knows 
where their new window will pop up.

By default, the point returned will be 30 pixels to the right and 30 pixels 
below the starting point of the referenced window.

The point returned is relative to C<wxTheApp-E<gt>GetTopWindow> if the 
Wx::Window argument is not sent.

=head2 get_sound

B<ARGS> - (B<path to wav file>)

B<RETURNS> - success: (Wx::Sound) - failure: produces L</poperr> and returns 
undef.

 $sound = wxTheApp->get_sound( 'two_tones_up.wav' );
 $sound->Play();

Transforms the requested wav file resource into a Wx::Sound and returns that.

=head2 popconf

B<ARGS> - (B<"Yes/no question" *>, "Window title")

B<RETURNS> - (wxYES or wxNO)

 my $resp = wxTheApp->popconf( 'Are you sure you want to do that?' );

Displays a yes/no question dialog and returns the user's response.

B<*> - If popconf() is called but no question is passed to it, L</poperr> will 
be called, letting you know that you really need to ask a question.  In that 
case, popconf's return value will be false.


 if( wxYES == wxTheApp->popconf( "Are you sure" ) ) {
  # Do stuff
 }
 else {
  # User did not say 'yes', so don't do stuff.
 }

B<CAUTION> - wxYES and wxNO are I<both positive integers>, so don't do this:

 if( wxTheApp->popconf("Are you really sure", "Really really?") ) {
  # Do stuff
 }
 else {
  # User said 'no', so don't really do stuff.
  ### GONNNNNG!  THAT IS WRONG! ###
 }

That code will never hit the else block, even if the user choses 'No', since 
the 'No' response is true.  This is very likely to be A Bad Thing.

=head2 poperr

B<ARGS> - (B<"Error message" *>, "Window title")

B<RETURNS> - (true)

 wxTheApp->poperr( "You did something wrong here.", "Whoopsie" );

Displays an error message popup to the user.

* The error message argument is technically optional, and will default to 
"Unknown error occurred".  However, that's not terribly helpful, so sending a 
meaningful error message is strongly recommended.

The "Window title" argument defaults to simply "Error!".

=head2 popmsg

B<ARGS> - (B<"Message" *>, "Window title")

B<RETURNS> - (true)

 wxTheApp->popmsg( "This is a message.", "This is a title." );

Similar to L</poperr>.  The only differences between the two are the icon that 
gets displayed in the popup, and the default dialog title.

* Like with L</poperr>, the message argument is technically optional, and will 
default to "Everything is fine".  Which is probably better than your program 
exploding, but isn't otherwise helpful.

The "Window title" argument Defaults to wxTheApp->GetAppName().

=head2 throb_end

Stops throbber.  Handled by L<MyApp::GUI::MainFrame#throb_end>.

=head2 throb_start

Starts throbber.  Handled by L<MyApp::GUI::MainFrame#throb_start>.

=head2 unix2dos, dos2unix

B<ARGS> - (B<String>)

B<RETURNS> - (String)

These behave as expected, returning the passed string with a CRLF line 
terminator (unix2dos) or just an LF line terminator (dos2unix).

Multiline text controls in wxwidgets use Unix-style (C<0x10>) line 
terminators, regardless of the current OS, so when saving the contents of 
these text controls to a file in Windows, it's recommended to pass those 
contents through unix2dos before the save.

