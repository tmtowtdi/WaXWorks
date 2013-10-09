
package MyApp::GUI::MainFrame::MenuBar::File {
    use v5.14;
    use Moose;
    use Wx qw(:everything);
    use Wx::Event qw(EVT_MENU);

    use MooseX::NonMoose::InsideOut;
    extends 'Wx::Menu';

    has 'app' => (
        is          => 'rw',
        isa         => 'MyApp',
        required    => 1,
    );
    has 'itm_exit' => (is => 'rw', isa => 'Wx::MenuItem', lazy_build => 1);

    sub FOREIGNBUILDARGS {#{{{
        return;
    }#}}}
    sub BUILD {
        my $self = shift;
        $self->Append( $self->itm_exit );
        $self->_set_events;
        return $self;
    }

    sub _build_itm_exit {#{{{
        my $self = shift;
        return Wx::MenuItem->new(
            $self, -1,
            '&Exit',
            'Exit',
            wxITEM_NORMAL,
            undef   # if defined, this is a sub-menu
        );
    }#}}}
    sub _set_events {#{{{
        my $self = shift;
        EVT_MENU( $self->app->GetTopWindow,  $self->itm_exit, sub{$self->OnQuit(@_)} );
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
