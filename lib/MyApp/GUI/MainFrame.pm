
use v5.14;

package MyApp::GUI::MainFrame {
    use Moose;
    use Wx qw( :everything );
    
    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Frame';

    has 'app' => (
        is          => 'rw',
        isa         => 'MyApp',
        required    => 1,
        weak_ref    => 1,
    );

    sub FOREIGNBUILDARGS {#{{{
        my $self = shift;
        my %args = @_;

        return(
            undef,
            -1,
            $args{'app'}{'app_name'},   # Window title
            wxDefaultPosition,
            wxDefaultSize,
            wxDEFAULT_FRAME_STYLE,
            "MainFrame",                # Window name
        );
    }#}}}
    sub BUILD {
        my $self = shift;
        return $self;
    }
}

1;

