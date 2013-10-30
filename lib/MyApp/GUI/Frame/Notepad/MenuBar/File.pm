
package MyApp::GUI::Frame::Notepad::MenuBar::File {
    use v5.14;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';
    with 'MyApp::Roles::Menu';

    has 'itm_exit' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_EXIT) },
    );
    has 'itm_open' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_OPEN) },
    );
    has 'itm_new' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_NEW) },
    );
    has 'itm_save' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_SAVE) },
    );
    has 'itm_saveas' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_SAVEAS) },
    );


    sub BUILD {
        my $self = shift;

        $self->Append( $self->itm_new );
        $self->Append( $self->itm_open );
        $self->Append( $self->itm_save );
        $self->Append( $self->itm_saveas );
        $self->Append( $self->sep );

        $self->Append( $self->itm_exit );


        $self->_set_events;
        return $self;
    }
    sub _build_file_saveas {#{{{
        my $self = shift;
        my $fd = Wx::FileDialog->new(
            $self->parent,
            "Choose a file...",
            q{},        # default dir
            q{},        # default file
            '*.txt',
            wxFD_SAVE
            |wxFD_OVERWRITE_PROMPT
            ,
        );
        return $fd;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( $self->parent,  $self->itm_exit,     sub{$self->OnQuit(@_)} );
        EVT_MENU( $self->parent,  $self->itm_open,     sub{$self->OnOpen(@_)} );
        EVT_MENU( $self->parent,  $self->itm_new,      sub{$self->OnNew(@_)} );
        EVT_MENU( $self->parent,  $self->itm_save,     sub{$self->OnSave(@_)} );
        EVT_MENU( $self->parent,  $self->itm_saveas,   sub{$self->OnSaveAs(@_)} );
        return 1;
    }#}}}

    sub OnOpen {#{{{
        my $self  = shift;
        my $frame = shift;
        my $event = shift;

        $self->parent->main_frame->do_open();
        return 1;
    }#}}}
    sub OnNew {#{{{
        my $self  = shift;
        my $frame = shift;
        my $event = shift;
        $self->parent->main_frame->do_new();
        return 1;
    }#}}}
    sub OnQuit {#{{{
        my $self  = shift;
        my $frame = shift;
        my $event = shift;
        $frame->Close(1);
        return 1;
    }#}}}
    sub OnSave {#{{{
        my $self  = shift;
        my $frame = shift;
        my $event = shift;
        ### Delegate
        $self->parent->main_frame->do_save();
        return 1;
    }#}}}
    sub OnSaveAs {#{{{
        my $self  = shift;
        my $frame = shift;
        my $event = shift;
        ### Delegate
        $self->parent->main_frame->do_saveas();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::Frame::Notepad::MenuBar::File - File menu; implements L<MyApp::GUI::Roles::Menu>

=head1 SYNOPSIS

Assuming C<$self> is a Wx::MenuBar:

 $file_menu = MyApp::GUI::Frame::Notepad::MenuBar::File->new();
 $self->Append( $file_menu, "&File" );

=head1 COMPONENTS

=over 4

=item * Quit (stock)

=back

