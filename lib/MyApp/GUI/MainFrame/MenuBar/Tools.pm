use v5.14;

package MyApp::GUI::MainFrame::MenuBar::Tools {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MyApp::GUI::Dialog::LogViewer;
    use MyApp::GUI::Dialog::PodViewer;

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';

    has 'itm_logview'   => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_podview'   => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);

    sub FOREIGNBUILDARGS {#{{{
        return;
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Append( $self->itm_logview   );
        $self->Append( $self->itm_podview   );

        $self->_set_events;
        return $self;
    }

    sub _build_itm_logview {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Log Viewer',
            'Log Viewer',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_podview {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Pod Viewer',
            'Pod Viewer',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_logview, sub{$self->OnLogViewer(@_)} );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_podview, sub{$self->OnPodViewer(@_)} );
        return 1;
    }#}}}

    sub OnLogViewer {#{{{
        my $self = shift;

        ### Determine starting point of LogViewer window
        my $frame_pos   = wxTheApp->GetTopWindow->GetPosition();
        my $dialog_pos  = Wx::Point->new( $frame_pos->x + 30, $frame_pos->y + 30 );
        my $log_viewer  = MyApp::GUI::Dialog::LogViewer->new( position => $dialog_pos );
        return 1;
    }#}}}
    sub OnPodViewer {#{{{
        my $self = shift;

        ### Determine starting point of PodViewer window
        my $frame_pos   = wxTheApp->GetTopWindow->GetPosition();
        my $dialog_pos  = Wx::Point->new( $frame_pos->x + 30, $frame_pos->y + 30 );
        my $pod_viewer  = MyApp::GUI::Dialog::PodViewer->new(
                                position => $dialog_pos,
                                size => Wx::Size->new(700, 600),
                            );
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
