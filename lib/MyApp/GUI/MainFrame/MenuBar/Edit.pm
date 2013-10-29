
package MyApp::GUI::MainFrame::MenuBar::Edit {
    use v5.14;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MyApp::GUI::Dialog::Preferences;

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';
    with 'MyApp::Roles::Menu';

    has 'itm_copy' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_COPY) },
    );
    has 'itm_cut' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_CUT) },
    );
    has 'itm_paste' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_PASTE) },
    );
    has 'itm_prefs' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        lazy_build  => 1,
        documentation => q{
            Yes, there does exist a wxID_PREFERENCES, but its accelerator key is 
            "P", which we already have assigned to "Paste", and it doesn't have 
            a keyboard shortcut.
            So instead of using the stock Preferences menu item ID, we're 
            building our own.
        }
    );

    sub FOREIGNBUILDARGS {#{{{
        return; # Wx::Menu->new() takes no arguments
    }#}}}
    sub BUILD {
        my $self = shift;
        $self->Append( $self->itm_cut   );
        $self->Append( $self->itm_copy  );
        $self->Append( $self->itm_paste );
        $self->Append( $self->itm_prefs );
        $self->_set_events;
        return $self;
    }

    sub _build_itm_prefs {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            "P&references\tCtrl-R",
            'Update Application Preferences',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_copy,  sub{$self->OnCopy(@_)}     );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_cut,   sub{$self->OnCut(@_)}      );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_paste, sub{$self->OnPaste(@_)}    );
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_prefs, sub{$self->OnPrefs(@_)}    );
        return 1;
    }#}}}

    ### For cut/copy/paste, and anything else that directly affects a window 
    ### owned by somebody else (in this case, the main_frame), don't code the 
    ### action here; delegate to the owning frame and let it figure out what 
    ### should happen.
    sub OnCopy {#{{{
        my $self = shift;
        wxTheApp->main_frame->do_copy();
        return 1;
    }#}}}
    sub OnCut {#{{{
        my $self = shift;
        wxTheApp->main_frame->do_cut();
        return 1;
    }#}}}
    sub OnPaste {#{{{
        my $self = shift;
        wxTheApp->main_frame->do_paste();
        return 1;
    }#}}}
    sub OnPrefs {#{{{
        my $self = shift;

        ### Determine starting point of Prefs window
        my $frame_pos   = wxTheApp->GetTopWindow->GetPosition();
        my $dialog_pos  = Wx::Point->new( $frame_pos->x + 30, $frame_pos->y + 30 );

        my $dialog = MyApp::GUI::Dialog::Preferences->new(
            position => $dialog_pos,
        );

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

