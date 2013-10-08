use v5.14;

BEGIN {
    ### Uncomment to display a splash screen.
    ###
    ### If we're using this, we want it to show up quickly, so it needs to be 
    ### used before we start doing a lot of other stuff.  Trying to create and 
    ### evaluate a "show_splash" attribute of MyApp (or some such) defeats the 
    ### purpose of a quickly-displaying splash screen, so just do this here.
    ### 
    ### At least on Windows, the timeout (milliseconds) works like this:
    ###     - If the timeout period ends before the rest of the app is ready, 
    ###     the splash screen will continue to display.  As soon as the rest 
    ###     of the app starts, the splash screen goes away (nicely synced).
    ###
    ###     - If the timeout period is longer than the amount of time it takes 
    ###     for the rest of the app to display, the splash image will remain 
    ###     displayed for the full length of the timeout.  If you set that 
    ###     timeout too long, the image will remain in your face and could end 
    ###     up being irritating.
    ###
    ### Tested with png, jpg, and gif images.
    ###
    ### I like keeping the original image names and just making a copy of 
    ### whichever one I currently want to be used as the splash image, and 
    ### just rename that copy to "splash.png".
    ###
    ### XKCD image license indicates it should be OK to use that:
    ### http://xkcd.com/license.html
    ###
    ### All this babbling should be somewhere more reasonable than this huge 
    ### comment block.
    use Wx::Perl::SplashFast( "var/splash.png", 50 );
}

package MyApp {
    use warnings;

    use FindBin;
    use Moose;
    use Wx qw(:everything);

    use MooseX::NonMoose;
    extends 'Wx::App';

    use MyApp::Model::Container;
    use MyApp::GUI::MainFrame;

    our $VERSION = '0.1';

    has 'root_dir' => ( is => 'rw', isa => 'Str');
    has 'app_name' => ( is => 'rw', isa => 'Str', default => 'MyApp');

    has 'bb' => (
        is          => 'rw',
        isa         => 'MyApp::Model::Container',
        lazy_build  => 1,
        handles => {
            resolve => 'resolve',
        },
        documentation => q{
            For non-GUI elements only (database connections, paths, etc)
        }
    );

    has 'wxbb' => (
        is          => 'rw',
        isa         => 'MyApp::Model::WxContainer',
        lazy_build  => 1,
        handles => {
            wxresolve => 'resolve',
        },
        documentation => q{
            For GUI elements only (images, fonts, etc)
        }
    );

    has 'db_log_file' => (
        is          => 'rw',
        isa         => 'Str',
        lazy_build  => 1,
    );

    has 'show_splash' => (
        is      => 'rw',
        isa     => 'Bool',
        default => 1,
    );

    sub FOREIGNBUILDARGS {#{{{
        return ();
    }#}}}
    sub BUILD {
        my $self = shift;

        ### Set the app's root directory
        $self->root_dir( "$FindBin::Bin/../" );

        ### Make sure that the logging database has been deployed
        $self->o_creat_database_log();

        ### Log the fact that we've started.
        my $logger = $self->resolve( service => '/Log/logger' );
        $logger->debug( 'Starting ' . $self->app_name );

        my $win = MyApp::GUI::MainFrame->new( app => $self );
        $win->Show(1);
        $self->SetTopWindow($win);

        return $self;
    }
    sub _build_bb {#{{{
        my $self = shift;
        return MyApp::Model::Container->new(
            name            => 'plain container',
            root_dir        => $self->root_dir,
            db_log_file     => $self->db_log_file,
        );
    }#}}}
    sub _build_wxbb {#{{{
        my $self = shift;
        return MyApp::Model::WxContainer->new(
            name            => 'wx container',
            root_dir        => $self->root_dir,
        );
    }#}}}
    sub _build_db_log_file {#{{{
        my $self = shift;
        my $file = $self->root_dir . '/var/log.sqlite';
        return $file;
    }#}}}

    sub poperr {#{{{
        my $self    = shift;
        my $message = shift || 'Unknown error occurred';
        my $title   = shift || 'Error!';
        Wx::MessageBox($message, $title, wxICON_EXCLAMATION, $self->main_frame->frame );
        return;
    }#}}}
    sub popmsg {#{{{
        my $self    = shift;
        my $message = shift || 'Everything is fine';
        my $title   = shift || $self->app_name;
        Wx::MessageBox($message,
                        $title,
                        wxOK | wxICON_INFORMATION,
                        $self->main_frame->frame );
        return;
    }#}}}
    sub popconf {#{{{
        my $self    = shift;
        my $message = shift || 'Everything is fine';
        my $title   = shift || $self->app_name;

=pod

The rv from this will be either wxYES or wxNO.  BOTH ARE POSITIVE INTEGERS.

So don't do this:

 ### BAD AND WRONG AND EVIL

 if( popconf("Are you really sure", "Really?") ) {
  ### Do Eeet
 }
 else {
  ### User said 'no', so don't really do eeet.

  ### 
  ### GONNNNNG!  THAT IS WRONG!
  ### 
 }

That code will never hit the else block, even if the user choses 'No', since the 
'No' response is true.  This could be A Bad Thing.


Instead, you need something like this...

 ### GOOD AND CORRECT AND PURE
 if( wxYES == popconf("Are you really sure", "Really really?") ) {
  ### Do Eeet
 }
 else {
  ### User said 'no', so don't really do eeet.
 }

...or often, more simply, this...

 return if wxNO == popconf("Are you really sure", "Really really?");
 ### do $stuff confident that the user did not say no.

=cut

        my $resp = Wx::MessageBox($message,
                                    $title,
                                    wxYES_NO|wxYES_DEFAULT|wxICON_QUESTION|wxSTAY_ON_TOP,
                                    $self->main_frame->frame );
        return $resp;
    }#}}}
    sub o_creat_database_log {#{{{
        my $self = shift;

        unless( -e $self->db_log_file ) {
            my $log_schema = $self->resolve( service => '/DatabaseLog/schema' );
            $log_schema->deploy;
        }
        return 1;
    }#}}}

    sub OnClose {#{{{
        my($self, $frame, $event) = @_;

        my $logger = $self->resolve( service => '/Log/logger' );
        $logger->component($self->app_name);

        ### Prune old log entries
        my $now   = DateTime->now();
        my $dur   = DateTime::Duration->new(days => $self->logs_expire);
        my $limit = $now->subtract_duration( $dur );
        $logger->debug('Pruning old log entries');
        $logger->prune_bydate( $limit );
        $logger->debug('Closing application');

        $event->Skip();
        return;
    }#}}}
    sub OnInit {#{{{
        my $self = shift;
        ### This gets called automatically by WX; it does not need to be 
        ### explicitly mentioned anywhere in this module.
        Wx::InitAllImageHandlers();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

These make no sense unless a throbber exists, and I haven't added one yet, but
most likely will, so leaving the code here for now.

    sub endthrob {#{{{
        my $self = shift;

        $self->main_frame->status_bar->bar_reset;
        $self->Yield; 
        local %SIG = ();
        $SIG{ALRM} = undef;     ##no critic qw(RequireLocalizedPunctuationVars) - PC thinks $SIG there is a scalar - whoops
        alarm 0;
        return;
    }#}}}
    sub throb {#{{{
        my $self = shift;

        $self->main_frame->status_bar->gauge->Pulse;        ## no critic qw(ProhibitLongChainsOfMethodCalls)
        $self->Yield; 
        local %SIG = ();
        $SIG{ALRM} = sub {  ##no critic qw(RequireLocalizedPunctuationVars) - PC thinks $SIG there is a scalar - whoops
            $self->main_frame->status_bar->gauge->Pulse;    ## no critic qw(ProhibitLongChainsOfMethodCalls)
            $self->Yield; 
            alarm 1;
        };
        alarm 1;
        return;
    }#}}}

 vim: syntax=perl
