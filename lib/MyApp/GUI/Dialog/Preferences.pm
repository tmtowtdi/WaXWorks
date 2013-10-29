use v5.14;

package MyApp::GUI::Dialog::Preferences {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_BUTTON EVT_CHOICE EVT_CLOSE EVT_SIZE);

    with 'MyApp::Roles::Platform';

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Dialog';

    has 'sizer_debug' => ( is => 'rw', isa => 'Bool', default => 0 );
    ###############
    has 'border_size' => (
        is      => 'ro', 
        isa     => 'Int',
        default => 10,
        documentation => q{
            The amount of space used to separate components from each other and 
            from the edges of the dialog.
        }
    );
    has 'position' => (
        is      => 'rw', 
        isa     => 'Wx::Point',
        default => sub{ Wx::Point->new(10,10) },
        documentation => q{
            Starting position of the dialog
        }
    );
    has 'size' => (
        is      => 'rw', 
        isa     => 'Wx::Size',
        default => sub{ Wx::Size->new(650,700) },
        documentation => q{
            Starting size of the dialog
        }
    );
    has 'title' => (
        is      => 'ro', 
        isa     => 'Str',
        default => 'Preferences',
    );
    ##############
    has 'txt_test'  => (is => 'rw', isa => 'Wx::TextCtrl',    lazy_build => 1);
    has 'szr_main'  => (is => 'rw', isa => 'Wx::Sizer',       lazy_build => 1);

    sub FOREIGNBUILDARGS {## no critic qw(RequireArgUnpacking) {{{
        my $self = shift;
        my %args = @_;

        my $pos = $args{'position'} // Wx::Point->new(10,10);

        return (
            undef, -1, 
            q{},
            $pos,
            wxDefaultSize,
            wxRESIZE_BORDER|wxDEFAULT_DIALOG_STYLE
        );
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Show(0);
        $self->SetTitle( $self->title );
        $self->SetSize( $self->size );

        ### This was just added for testing something; fool with it or delete 
        ### it.
        #$self->szr_main->Add($self->txt_test, 0, wxALL, $self->border_size);

        $self->SetSizer($self->szr_main);
        $self->_set_events();
        $self->Layout();
        $self->Show(1);
        return $self;
    }
    sub _build_position {#{{{
        my $self = shift;
        return Wx::Point->new(10, 10);
    }#}}}
    sub _build_size {#{{{
        my $self = shift;
        my $s = Wx::Size->new(650, 700);
        return $s;
    }#}}}
    sub _build_szr_main {#{{{
        my $self = shift;

        return $self->build_sizer($self, wxVERTICAL, 'Main');
    }#}}}
    sub _build_txt_test {#{{{
        my $self = shift;

        my $v = Wx::TextCtrl->new(
            $self, -1, 
            q{},
            wxDefaultPosition, 
            Wx::Size->new(150,25)
        );

        my $tt = Wx::ToolTip->new( "Use this for testing copy and pasting from the Edit menu.");
        $v->SetToolTip($tt);

       return $v;
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE(      $self,                              sub{$self->OnClose(@_)}         );
        EVT_SIZE(       $self,                              sub{$self->OnResize(@_)}        );
        return 1;
    }#}}}

    sub OnClose {#{{{
        my($self, $dialog, $event) = @_;
        $self->Destroy;
        $event->Skip();
        return 1;
    }#}}}
    sub OnResize {#{{{
        my $self    = shift;
        my $dialog  = shift;
        my $event   = shift;    # Wx::SizeEvent

        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

=head1 NAME

MyApp::GUI::Dialog::LogViewer - Dialog for browsing log entries

=head1 SYNOPSIS

 $pos     = Wx::Point->new( $some_x, $some_y );
 $l_view  = MyApp::GUI::Dialog::LogViewer->new( position => $pos );
 $l_view->Show(1);

=head1 DESCRIPTION

The LogViewer is a paginated list of all of the log entries produced by the 
app.  Entries can be filtered to only show logs produced by the specific app 
component you're currently interested in.

