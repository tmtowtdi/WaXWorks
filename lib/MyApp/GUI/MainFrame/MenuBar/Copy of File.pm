
package MyApp::GUI::MainFrame::MenuBar::File {
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


    sub FOREIGNBUILDARGS {#{{{
        return;
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Append( $self->sep );

        $self->Append( $self->itm_save );
        $self->Append( $self->itm_saveas );
        $self->Append( $self->sep );

        $self->Append( $self->itm_exit );

        $self->_set_events;
        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_exit, sub{$self->OnQuit(@_)} );
        return 1;
    }#}}}

    sub sep {#{{{
        my $self = shift;
        return Wx::MenuItem->new($_[0], wxID_SEPARATOR),
    }#}}}

    sub OnQuit {#{{{
        my $self  = shift;
        my $frame = shift;
        my $event = shift;
        $frame->Close(1);
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame::MenuBar::File - File menu

=head1 SYNOPSIS

Assuming C<$self> is a Wx::MenuBar:

 $file_menu = MyApp::GUI::MainFrame::MenuBar::File->new();
 $self->Append( $file_menu, "&File" );

=head1 COMPONENTS

=over 4

=item * Quit (stock)

=back

=head1 METHODS

=head2 sep

If we define a single Moose attribute as a separator and attempt to use that 
item multiple times, wxwidgets will try to delete both on shutdown, producing 
an error when it tries to delete all but the first.

But defining every separator we might want to use as separate Moose attributes 
seems a little unnecessary.

So if you need a separator, simply call sep() to get a brand new one.

=over 4

=item * ARGS

=over 8

=item * none

=back

=item * RETURNS

=over 8

=item * A new Wx::MenuItem object representing a separator.

=back

=item * USAGE

=back

