
package MyApp::GUI::MainFrame::MenuBar::Edit {
    use v5.14;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';

    has 'itm_copy'      => (is => 'rw', isa => 'Wx::MenuItem', lazy_build => 1);
    has 'itm_paste'     => (is => 'rw', isa => 'Wx::MenuItem', lazy_build => 1);
    has 'itm_prefs'     => (is => 'rw', isa => 'Wx::MenuItem',  lazy_build => 1);

    sub FOREIGNBUILDARGS {#{{{
        return; # Wx::Menu->new() takes no arguments
    }#}}}
    sub BUILD {
        my $self = shift;
        $self->Append( $self->itm_copy );
        $self->Append( $self->itm_paste );
        $self->Append( $self->itm_prefs );
        $self->_set_events;
        return $self;
    }

    sub _build_itm_copy {#{{{
        my $self = shift;
        return Wx::MenuItem->new( $self, wxID_COPY );
    }#}}}
    sub _build_itm_paste {#{{{
        my $self = shift;
        return Wx::MenuItem->new( $self, wxID_PASTE );
    }#}}}
    sub _build_itm_prefs {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Preferences',
            'Preferences',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU(wxTheApp->GetTopWindow,  $self->itm_prefs, sub{$self->OnPrefs(@_)});
        return 1;
    }#}}}

    sub OnPrefs {#{{{
        my $self = shift;

        ### Determine starting point of Prefs window
        my $frame_pos   = wxTheApp->GetTopWindow->GetPosition();
        my $dialog_pos  = Wx::Point->new( $frame_pos->x + 30, $frame_pos->y + 30 );

        my $dialog = Wx::Dialog->new(
            wxTheApp->GetTopWindow, 
            -1,
            "Preferences Dialog",
            $dialog_pos,
            wxDefaultSize,
            wxRESIZE_BORDER|wxDEFAULT_DIALOG_STYLE
        );

        $dialog->Show(1);
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame::MenuBar::Edit - Edit menu

=head1 SYNOPSIS

Assuming C<$self> is a Wx::MenuBar:

 $edit_menu = MyApp::GUI::MainFrame::MenuBar::Edit->new();
 $self->Append( $edit_menu, "&Edit" );

=head1 COMPONENTS

=over 4

=item * Copy (stock)

=item * Paste (stock)

=item * Preferences

Opens what should eventually be a Preferences dialog, but which is currently 
just an empty dialog.

=back

