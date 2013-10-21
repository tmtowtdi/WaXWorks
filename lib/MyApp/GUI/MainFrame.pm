use v5.14;

package MyApp::GUI::MainFrame {
    use Data::Dumper::GUI;
    use Moose;
    use Wx qw( :everything );
    use Wx::Event qw(EVT_CLOSE);
    
    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Frame';

    use MyApp::GUI::MainFrame::MenuBar;

    has 'menu_bar' => (
        is          => 'rw',
        isa         => 'MyApp::GUI::MainFrame::MenuBar',
        lazy_build  => 1,
    );

    sub FOREIGNBUILDARGS {#{{{
        my $self = shift;
        my %args = @_;

        return(
            undef,
            -1,
            wxTheApp->GetAppName(),     # Window title
            wxDefaultPosition,
            wxDefaultSize,
            wxDEFAULT_FRAME_STYLE,
            "MainFrame",                # Window name
        );
    }#}}}
    sub BUILD {
        my $self = shift;

        ### The SplashScreen, if used, automatically starts as the TopWindow 
        ### since it's the first window created.
        ###
        ### MyApp.pm is setting this MainFrame as the top window, but it can't 
        ### do so until this constructor completes and returns the MainFrame 
        ### object.
        ###
        ### However, while building the MainFrame object, we're building the  
        ### menubar (as part of this MainFrame).  That menubar wants to 
        ### display a Dialog (Edit... Preferences, and likely any other 
        ### Dialogs it may end up wanting to open) whose position is relative 
        ### to the TopWindow (which is currently still set as the 
        ### SplashScreen).
        ###
        ### So set ourselves as the TopWindow now to keep from confusing the 
        ### MenuBar.
        wxTheApp->SetTopWindow($self);

        $self->SetMenuBar($self->menu_bar);

        $self->_set_events;
        return $self;
    }

    sub _build_menu_bar {#{{{
        my $self = shift;
        my $mb = MyApp::GUI::MainFrame::MenuBar->new();
        return $mb;
    }#}}}
    sub _set_events {
        my $self = shift;
    }

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
