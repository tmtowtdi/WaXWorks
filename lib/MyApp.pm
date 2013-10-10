use v5.14;

package MyApp {
    use warnings;

    use Data::Dumper::GUI;
    use FindBin;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_TIMER);

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

    has 'timer' => (
        is          => 'rw',
        isa         => 'Wx::Timer',
        lazy_build  => 1,
    );

    has 'main_frame' => (
        is          => 'rw',
        isa         => 'MyApp::GUI::MainFrame',
        lazy_build  => 1,
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

        $self->SetTopWindow( $self->main_frame );
        $self->main_frame->Show(1);

        ### Log the fact that we've started.
        my $logger = $self->resolve( service => '/Log/logger' );
        $logger->debug( 'Starting ' . $self->app_name );

        $self->_set_events();
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
    sub _build_db_log_file {#{{{
        my $self = shift;
        my $file = $self->root_dir . '/var/log.sqlite';
        return $file;
    }#}}}
    sub _build_main_frame {#{{{
        my $self = shift;
        #my $frame = MyApp::GUI::MainFrame->new( app => $self );
        my $frame = MyApp::GUI::MainFrame->new();
        return $frame;
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
        return MyApp::Model::WxContainer->new(
            name            => 'wx container',
            root_dir        => $self->root_dir,
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_TIMER( $self, $self->timer->GetId,  sub{$self->OnTimer(@_)} );
        return 1;
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
