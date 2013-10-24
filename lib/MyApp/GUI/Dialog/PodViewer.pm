use v5.14;

package MyApp::GUI::Dialog::PodViewer {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw( EVT_CLOSE );

    use MooseX::NonMoose;
    extends 'Wx::Perl::PodBrowser';

    has 'position'  => ( is => 'rw', isa => 'Wx::Point', default => sub{wxDefaultPosition} );
    has 'size'      => ( is => 'rw', isa => 'Wx::Size',  default => sub{wxDefaultSize} );

    has 'podtext'  => ( is => 'rw', isa => 'Wx::Perl::PodBrowser' );

    sub FOREIGNBUILDARGS {## no critic qw(RequireArgUnpacking) {{{
        my $self = shift;
        my %args = @_;

        my $pos  = $args{'position'} // Wx::Point->new(10,10);

        return (
            undef, -1, 
            q{POD Viewer},
            $pos,
            wxDefaultSize,
            wxRESIZE_BORDER
            |wxDEFAULT_FRAME_STYLE
            #|wxFRAME_TOOL_WINDOW
        );
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->Show(0);

        $self->SetIcon( wxTheApp->get_app_icon() );
        $self->SetSize( $self->size );
        $self->goto_pod( module => 'MyApp' );
        #$self->goto_pod( filename => join '/', (wxTheApp->root_dir, 'lib/Test.pod') );

        $self->Show(1);
        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_CLOSE( $self, sub{$self->OnClose(@_)} );
        return 1;
    }#}}}

    sub OnClose {#{{{
        my $self    = shift;
        my $window  = shift;
        my $event   = shift;
        $self->Destroy;
        $event->Skip();
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable(); 
}

1;

__END__

=head1 NAME

MyApp::GUI::Dialog::PodViewer - Frame for browsing application POD

=head1 SYNOPSIS

 $pos     = Wx::Point->new( $some_x, $some_y );
 $size    = Wx::Size->new ( $width, $height );
 $p_view  = MyApp::GUI::Dialog::PodViewer->new( position => $pos, size => $size );
 $p_view->Show(1);

=head1 DESCRIPTION

Browse your own application's POD as you work.

Extends L<Wx::Perl::PodBrowser> and L<Wx::Perl::PodRichText>.

