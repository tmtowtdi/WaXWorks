use v5.14;

package MyApp::GUI::MainFrame::MenuBar {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::MenuBar';

    use MyApp::GUI::MainFrame::MenuBar::File;
    use MyApp::GUI::MainFrame::MenuBar::Edit;
    use MyApp::GUI::MainFrame::MenuBar::Tools;
    use MyApp::GUI::MainFrame::MenuBar::Help;


    has 'menu_file'     => (is => 'rw', isa => 'MyApp::GUI::MainFrame::MenuBar::File',   lazy_build => 1);
    has 'menu_edit'     => (is => 'rw', isa => 'MyApp::GUI::MainFrame::MenuBar::Edit',   lazy_build => 1);
    has 'menu_tools'    => (is => 'rw', isa => 'MyApp::GUI::MainFrame::MenuBar::Tools',  lazy_build => 1);
    has 'menu_help'     => (is => 'rw', isa => 'MyApp::GUI::MainFrame::MenuBar::Help',   lazy_build => 1);

    has 'menu_list'     => (is => 'rw', isa => 'ArrayRef[HashRef]',
        default => sub {
            [
                { attribute => 'menu_file',    label => "&File" },
                { attribute => 'menu_edit',    label => "&Edit" },
                { attribute => 'menu_tools',   label => "&Tools" },
                { attribute => 'menu_help',    label => "&Help" },
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
        return MyApp::GUI::MainFrame::MenuBar::File->new();
    }#}}}
    sub _build_menu_edit {#{{{
        my $self = shift;
        return MyApp::GUI::MainFrame::MenuBar::Edit->new();
    }#}}}
    sub _build_menu_help {#{{{
        my $self = shift;
        return MyApp::GUI::MainFrame::MenuBar::Help->new();
    }#}}}
    sub _build_menu_tools {#{{{
        my $self = shift;
        return MyApp::GUI::MainFrame::MenuBar::Tools->new();
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
