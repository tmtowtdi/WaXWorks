use v5.14;

package MyApp::GUI::MainFrame::MenuBar::Examples {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MyApp::GUI::Frame::Notepad;

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';
    with 'MyApp::Roles::Menu';

    has 'itm_end_throb'     => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_notepad'       => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_start_throb'   => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);
    has 'itm_testsound'     => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);

    sub FOREIGNBUILDARGS {#{{{
        return;
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Append( $self->itm_notepad       );
        $self->Append( $self->itm_testsound     );
        $self->Append( $self->itm_start_throb   );
        $self->Append( $self->itm_end_throb     );

        $self->_set_events;
        return $self;
    }

    sub _build_itm_start_throb {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Start Throbber',
            'Start Throbber',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_end_throb {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&End Throbber',
            'End Throbber',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_notepad {#{{{
        my $self = shift;

        return Wx::MenuItem->new(
            $self, -1,
            '&Notepad',
            'Start Notepad Clone',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _build_itm_testsound {#{{{
        my $self = shift;

        ### Works on Windows, but not Ubuntu.  At least not with my setup; 
        ### could be a re-install will fix.

        return Wx::MenuItem->new(
            $self, -1,
            '&Test Sound',
            'Test Sound',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_end_throb,    sub{$self->OnEndThrob(@_)} );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_notepad,      sub{$self->OnNotepad(@_)} );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_start_throb,  sub{$self->OnStartThrob(@_)} );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_testsound,    sub{$self->OnTestSound(@_)} );
        return 1;
    }#}}}

    sub OnEndThrob {#{{{
        my $self = shift;
        wxTheApp->throb_end();
        return 1;
    }#}}}
    sub OnNotepad {#{{{
        my $self = shift;
        my $notepad = MyApp::GUI::Frame::Notepad->new();
        return 1;
    }#}}}
    sub OnStartThrob {#{{{
        my $self = shift;
        wxTheApp->throb_start();
        return 1;
    }#}}}
    sub OnTestSound {#{{{
        my $self = shift;

        my $file = wxTheApp->get_wav( 'two_tones_up.wav' );
        my $sound = Wx::Sound->new($file);
        unless( $sound->IsOk ) {
            wxTheApp->poperr("Sound is not OK");
            return;
        }
        $sound->Play();

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame::MenuBar::Tools - Tools menu

=head1 SYNOPSIS

Assuming C<$self> is a Wx::MenuBar:

 $tools_menu = MyApp::GUI::MainFrame::MenuBar::Tools->new();
 $self->Append( $tools_menu, "&Tools" );

=head1 COMPONENTS

=over 4

=item * Test Sound

Plays a short test sound.  Works on Windows, not on (my, at least) Ubuntu.

=item * Start Throbber

Starts the throbber gauge in the status bar.  Does nothing if it's already 
been started.

=item * End Throbber

Stops the throbber gauge in the status bar.  Does nothing if the throbber is 
not currently throbbing.  Throb.

=back

