
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

    sub BUILD {
        my $self = shift;

        $self->Append( $self->itm_exit );

        $self->_set_events;
        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( wxTheApp->GetTopWindow,  $self->itm_exit,     sub{$self->OnQuit(@_)} );
        return 1;
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

MyApp::GUI::MainFrame::MenuBar::File - File menu; implements L<MyApp::GUI::Roles::Menu>

=head1 SYNOPSIS

Assuming C<$self> is a Wx::MenuBar:

 $file_menu = MyApp::GUI::MainFrame::MenuBar::File->new();
 $self->Append( $file_menu, "&File" );

=head1 COMPONENTS

=over 4

=item * Quit (stock)

=back

