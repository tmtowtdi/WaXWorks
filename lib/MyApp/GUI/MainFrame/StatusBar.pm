use v5.14;

package MyApp::GUI::MainFrame::StatusBar {
    use Moose;
    use MooseX::NonMoose::InsideOut;
    extends 'Wx::StatusBar';
    use MyApp::GUI::MainFrame::StatusBar::Gauge;

    has 'gauge_class' => (
        is          => 'rw', 
        isa         => 'Str',
        default     => 'MyApp::GUI::MainFrame::StatusBar::Gauge',
    );
    with 'MyApp::Roles::StatusBar';

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::MainFrame::StatusBar - Main frame status bar

=head1 SEE ALSO

L<MyApp::Roles::StatusBar>

