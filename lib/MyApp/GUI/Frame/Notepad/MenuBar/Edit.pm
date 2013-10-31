
package MyApp::GUI::Frame::Notepad::MenuBar::Edit {
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

    sub FOREIGNBUILDARGS {#{{{
        return; # Wx::Menu->new() takes no arguments
    }#}}}
    sub BUILD {
        my $self = shift;
        $self->Append( $self->itm_cut   );
        $self->Append( $self->itm_copy  );
        $self->Append( $self->itm_paste );
        $self->_set_events;
        return $self;
    }

    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( $self->parent,  $self->itm_copy,  sub{$self->OnCopy(@_)}     );
        EVT_MENU( $self->parent,  $self->itm_cut,   sub{$self->OnCut(@_)}      );
        EVT_MENU( $self->parent,  $self->itm_paste, sub{$self->OnPaste(@_)}    );
        return 1;
    }#}}}

    ### For cut/copy/paste, and anything else that directly affects a window 
    ### owned by somebody else (in this case, the main_frame), don't code the 
    ### action here; delegate to the owning frame and let it figure out what 
    ### should happen.
    sub OnCopy {#{{{
        my $self = shift;
        $self->parent->do_copy();
        return 1;
    }#}}}
    sub OnCut {#{{{
        my $self = shift;
        $self->parent->do_cut();
        return 1;
    }#}}}
    sub OnPaste {#{{{
        my $self = shift;
        $self->parent->do_paste();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::Frame::Notepad::MenuBar::Edit - Edit menu; implements L<MyApp::GUI::Roles::Menu>

=head1 SYNOPSIS

Assuming C<$self> is a Wx::MenuBar:

 $edit_menu = MyApp::GUI::Frame::Notepad::MenuBar::Edit->new();
 $self->Append( $edit_menu, "&Edit" );

=head1 COMPONENTS

=over 4

=item * Copy (stock)

=item * Paste (stock)

=item * Preferences

Opens what should eventually be a Preferences dialog, but which is currently 
just an empty dialog.

=back

