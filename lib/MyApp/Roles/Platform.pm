use v5.14;

package MyApp::Roles::Platform {
    use Data::GUID;
    use Moose::Role;
    use Try::Tiny;
    use Wx qw(:everything);

    has 'sizer_debug' => (
        is      => 'rw', 
        isa     => 'Int',  
        lazy    => 1, 
        default => 0,
        documentation => q{
            draws boxes with titles around all sizers created by build_sizer() if true.
        }
    );

    after BUILD => sub {
        my $self = shift;
        return 1;
    };

    sub build_sizer {#{{{
        my $self        = shift;
        my $parent      = shift;
        my $direction   = shift;
        my $name        = shift || Data::GUID->new()->as_string();
        my $force_box   = shift || 0;
        my $pos         = shift || wxDefaultPosition;
        my $size        = shift || wxDefaultSize;

        my $hr = { };
        if( $self->sizer_debug or $force_box ) {
            $hr->{'box'} = Wx::StaticBox->new($parent, -1, $name, $pos, $size),
            $hr->{'box'}->SetFont( wxTheApp->wxresolve(service => '/fonts/para_text_1') );
            $hr->{'sizer'} = Wx::StaticBoxSizer->new($hr->{'box'}, $direction);
        }
        else {
            $hr->{'sizer'} = Wx::BoxSizer->new($direction);
        }

        return $hr->{'sizer'};
    }#}}}

    no Moose::Role;
}

1;

__END__

=head1 NAME

MyApp::Roles::Platform - Role for building a platform (frame, dialog, 
panel) on which other windows will be built.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 PROVIDED METHODS

=head2 build_sizer

Builds and returns a sizer.  The simplest and most common usage returns an 
invisible sizer when $self->sizer_debug is off, and a visible box with the 
sizer's name when $self->sizer_debug is on.

 $sizer = $self->build_sizer($self->parent, wxHORIZONTAL, 'My Sizer Name');

You can force the box to always display regardless of the sizer_debug setting, 
and also modify the sizer's position and size if needed:

 $sizer = $self->build_sizer(
  $self->parent,
  wxHORIZONTAL,
  'My Sizer Name',
  1,                # Force the box to be drawn
  Wx::Position->new(...),
  Wx::Size->new(...),
 );

=cut
