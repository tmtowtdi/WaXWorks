use v5.14;

package MyApp::GUI::MainFrame::MenuBar::Tools {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MyApp::GUI::Dialog::LogViewer;
    use MyApp::GUI::Frame::PodViewer;

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';
    with 'MyApp::Roles::Menu';

    has 'itm_logview'       => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_podview'       => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);

    sub FOREIGNBUILDARGS {#{{{
        return;
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Append( $self->itm_logview       );
        $self->Append( $self->itm_podview       );

        $self->_set_events;
        return $self;
    }

    sub _build_itm_logview {#{{{
        my $self = shift;
        my $lv = Wx::MenuItem->new(
            $self, -1,
            '&Log Viewer',
            "Open the Log Viewer",
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
        return $lv;
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
        EVT_MENU( $self->parent,  $self->itm_logview,      sub{$self->OnLogViewer(@_)} );
        EVT_MENU( $self->parent,  $self->itm_podview,      sub{$self->OnPodViewer(@_)} );
        return 1;
    }#}}}

    sub OnLogViewer {#{{{
        my $self = shift;

        ### Determine starting point of LogViewer window
        my $frame_pos   = wxTheApp->get_new_window_position( $self->parent );
        my $dialog_pos  = Wx::Point->new( $frame_pos->x + 30, $frame_pos->y + 30 );
        my $log_viewer  = MyApp::GUI::Dialog::LogViewer->new( position => $dialog_pos );
        return 1;
    }#}}}
    sub OnPodViewer {#{{{
        my $self = shift;

        ### Determine starting point of PodViewer window
        my $frame_pos   = wxTheApp->get_new_window_position( $self->parent );
        my $dialog_pos  = Wx::Point->new( $frame_pos->x + 30, $frame_pos->y + 30 );
        my $pod_viewer  = MyApp::GUI::Frame::PodViewer->new(
                                position => $dialog_pos,
                                size => Wx::Size->new(700, 600),
                            );
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame::MenuBar::Tools - Tools menu; implements L<MyApp::GUI::Roles::Menu>

=head1 SYNOPSIS

Assuming C<$self> is a Wx::MenuBar:

 $tools_menu = MyApp::GUI::MainFrame::MenuBar::Tools->new();
 $self->Append( $tools_menu, "&Tools" );

=head1 COMPONENTS

=over 4

=item * Log Viewer

Opens a L<MyApp::GUI::Dialog::LogViewer> dialog.

=item * Pod Viewer

Opens a L<MyApp::GUI::Frame::PodViewer> frame.

=back

