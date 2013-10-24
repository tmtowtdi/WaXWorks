use v5.14;

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
    has 'icon_bundle' => (
        is          => 'ro',
        isa         => 'Wx::IconBundle',
        lazy_build  => 1,
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

        ### Set the application Icon
        $self->main_frame->SetIcons( $self->icon_bundle );

        ### Set the main frame as the app top window
        $self->SetTopWindow( $self->main_frame );

        ### Log the fact that we've started.
        my $logger = $self->resolve( service => '/Log/logger' );
        $logger->component(wxTheApp->GetAppName);
        $logger->debug( 'Starting ' . wxTheApp->GetAppName() );

        $self->main_frame->Show(1);
        $self->_set_events();
        return $self;
    }
    sub _build_bb {#{{{
        my $self = shift;
        return MyApp::Model::Container->new( name => 'plain container' );
    }#}}}
    sub _build_icon_bundle {#{{{
        my $self = shift;

    ### CHECK
        ### Testing with the frai icon bundle:
        ###     - When the only file in the bundle was either the _16 or the 
        ###     _32, all icons appeared to work properly.  None of the other 
        ###     sizes seemed to have any effect at all, and I didn't notice a 
        ###     difference between using the _16 and the _32.

        my $bundle  = Wx::IconBundle->new();
        my $ico_dir = io $self->resolve(service => q{/Directory/icon_bundle});
        my @images  = grep{ /\.(png|gif|jpg)$/ } $ico_dir->all();
        map{ $bundle->AddIcon( Wx::Icon->new($_, wxBITMAP_TYPE_ANY) ) }@images;

        return $bundle;
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

    sub poperr {#{{{
        my $self    = shift;
        my $message = shift || 'Unknown error occurred';
        my $title   = shift || 'Error!';
        #Wx::MessageBox($message, $title, wxICON_EXCLAMATION, $self->main_frame->frame );
        Wx::MessageBox($message, $title, wxICON_EXCLAMATION, $self->main_frame );
        return;
    }#}}}
    sub popmsg {#{{{
        my $self    = shift;
        my $message = shift || 'Everything is fine';
        my $title   = shift || wxTheApp->GetAppName();
        Wx::MessageBox($message,
                        $title,
                        wxOK | wxICON_INFORMATION,
                        #$self->main_frame->frame );
                        $self->main_frame );
        return;
    }#}}}
    sub popconf {#{{{
        my $self    = shift;
        my $message = shift || 'Everything is fine';
        my $title   = shift || wxTheApp->GetAppName;

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
                                    #$self->main_frame->frame );
                                    $self->main_frame);
        return $resp;
    }#}}}
    sub o_creat_database_log {#{{{
        my $self = shift;

        unless( -e $self->resolve(service => '/DatabaseLog/db_file') ) {
            my $log_schema = $self->resolve( service => '/DatabaseLog/schema' );
            $log_schema->deploy;
        }
        return 1;
    }#}}}

    sub OnExit {#{{{
        my $self = shift;

        my $logger = $self->resolve( service => '/Log/logger' );
        $logger->component(wxTheApp->GetAppName);

        ### Prune old log entries
        my $now   = DateTime->now();
        my $dur   = DateTime::Duration->new(days => $self->logs_expire);
        my $limit = $now->subtract_duration( $dur );
        $logger->debug('Pruning old log entries');
        $logger->prune_bydate( $limit );
        $logger->debug('Closing application');

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
