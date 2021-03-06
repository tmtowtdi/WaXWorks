
package MyApp::GUI::MainFrame::MenuBar::Help {
    use v5.14;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);
    with 'MyApp::Roles::Platform';

    use MyApp::GUI::Dialog::About;
    use MyApp::GUI::Dialog::Help;

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';
    with 'MyApp::Roles::Menu';

    has 'itm_about' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_ABOUT) },
    );
    has 'itm_help' => (
        is          => 'rw',
        isa         => 'Wx::MenuItem',
        default     => sub{ Wx::MenuItem->new($_[0], wxID_HELP) },
    );


    sub FOREIGNBUILDARGS {#{{{
        return; 
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Append( $self->itm_about );
        $self->Append( $self->itm_help );

        $self->_set_events;
        return $self;
    }

    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( $self->parent,  $self->itm_about->GetId,   sub{$self->OnAbout(@_)}    );
        EVT_MENU( $self->parent,  $self->itm_help->GetId,    sub{$self->OnHelp(@_)}     );
        return 1;
    }#}}}

    sub OnAbout {#{{{
        my $self  = shift;
        my $frame = shift;  # Wx::Frame
        my $event = shift;  # Wx::CommandEvent
        my $d = MyApp::GUI::Dialog::About->new( app => wxTheApp );
        $d->show();
        return 1;
    }#}}}
    sub OnHelp {#{{{
        my $self  = shift;
        my $d = MyApp::GUI::Dialog::Help->new();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame::MenuBar::Help - Help menu; implements L<MyApp::GUI::Roles::Menu>

=head1 SYNOPSIS

Assuming C<$self> is a Wx::MenuBar:

 $help_menu = MyApp::GUI::MainFrame::MenuBar::Help->new();
 $self->Append( $help_menu, "&Help" );

=head1 COMPONENTS

=over 4

=item * About (stock)

Opens a L<MyApp::GUI::Dialog::About> pseudo-dialog.

=item * Help (stock)

Opens a L<MyApp::GUI::Dialog::Help> dialog.

=back
