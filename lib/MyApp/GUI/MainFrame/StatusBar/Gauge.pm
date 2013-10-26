use v5.14;

package MyApp::GUI::MainFrame::StatusBar::Gauge {
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_TIMER);

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Gauge';

    has 'timer' => (
        is          => 'rw', 
        isa         => 'Wx::Timer',
        lazy        => 1,
        default     => sub{ Wx::Timer->new },
    );

    sub FOREIGNBUILDARGS {#{{{
        my $self = shift;
        my %args = @_;

        my $rect = $args{'parent'}->GetFieldRect(1);

        return (
            $args{'parent'},
            -1,
            100,                # value range
            $args{'position'}   // wxDefaultPosition,
            $args{'size'}       // wxDefaultSize,
            wxGA_HORIZONTAL
        );
    }#}}}
    sub BUILD {
        my $self = shift;

        $self->timer->SetOwner( $self );

        $self->_set_events();
        return $self;
    }
    sub _set_events {#{{{
        my $self = shift;
        EVT_TIMER(   $self,  $self->timer->GetId,   sub{$self->OnTimer(@_)}     );
        return 1;
    }#}}}

    sub reset {
        my $self = shift;
        $self->SetValue(0);
        $self->Layout();
    }
    sub OnTimer {#{{{
        my $self = shift;
        $self->Pulse();
        wxTheApp->Yield;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;
