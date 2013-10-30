use v5.14;

package MyApp::GUI::Frame::Notepad::MenuBar {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::MenuBar';
    with 'MyApp::Roles::MenuBar';

    use MyApp::GUI::Frame::Notepad::MenuBar::File;
    use MyApp::GUI::Frame::Notepad::MenuBar::Edit;

    has 'menu_file'     => (is => 'rw', isa => 'MyApp::GUI::Frame::Notepad::MenuBar::File',      lazy_build => 1);
    has 'menu_edit'     => (is => 'rw', isa => 'MyApp::GUI::Frame::Notepad::MenuBar::Edit',      lazy_build => 1);

    has 'menu_list'     => (is => 'rw', isa => 'ArrayRef[HashRef]',
        default => sub {
            [
                { attribute => 'menu_file',     label => "&File" },
                { attribute => 'menu_edit',     label => "&Edit" },
            ]
        },
        documentation => q{
            Maintains the order of display of menu items.
        }
    );

    sub FOREIGNBUILDARGS {#{{{
        return ();
    }#}}}
    sub BUILD {
        my $self = shift;

        foreach my $submenu( @{$self->menu_list} ) {
            my $a = $submenu->{'attribute'};
            my $l = $submenu->{'label'};
            $self->Append( $self->$a, $l );
        }

        return $self;
    }
    sub _build_menu_file {#{{{
        my $self = shift;
        return MyApp::GUI::Frame::Notepad::MenuBar::File->new( parent => $self->parent );
    }#}}}
    sub _build_menu_edit {#{{{
        my $self = shift;
        return MyApp::GUI::Frame::Notepad::MenuBar::Edit->new( parent => $self->parent );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::Frame::Notepad::MenuBar - MenuBar for Notepad frame; implements L<MyApp::GUI::Roles::MenuBar>

=head1 SYNOPSIS

Assuming C<$self> is a MyApp::GUI::Frame::Notepad frame:

 $menu_bar = MyApp::GUI::Frame::Notepad::MenuBar->new( parent => $self );
 $self->SetMenuBar( $menu_bar );

=head1 COMPONENTS

=over 4

=item * L<MyApp::GUI::Frame::Notepad::MenuBar::File>

=item * L<MyApp::GUI::Frame::Notepad::MenuBar::Edit>

=back

