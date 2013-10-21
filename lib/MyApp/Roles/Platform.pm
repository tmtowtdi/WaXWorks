use v5.14;

package MyApp::Roles::Platform {
    use Data::GUID;
    use Moose::Role;
    use Try::Tiny;
    use Wx qw(:everything);

    has 'sizer_debug' => (
        is      => 'rw', 
        isa     => 'Bool',  
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

        my $sizer;
        if( $self->sizer_debug or $force_box ) {
            my $box = Wx::StaticBox->new($parent, -1, $name, $pos, $size);
            $box->SetFont( wxTheApp->wxresolve(service => '/fonts/para_text_1') );
            $sizer = Wx::StaticBoxSizer->new($box, $direction);
        }
        else {
            $sizer = Wx::BoxSizer->new($direction);
        }

        return $sizer;
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

=head1 PROVIDED ATTRIBUTES

=head2 sizer_debug

Boolean, defaults to false (off).

Since sizers themselves are invisible, initial layout of a new panel can be 
difficult.  By adding a sizer_debug attribute to your class, you can simply 
Switch its value from 0 to 1, then restart your app.  This will cause all 
sizers returned by build_sizer() to be wrapped with a visible static box.

CAUTION - While the static boxes displayed by setting sizer_debug to true are 
useful to see where your sizers are, I<those boxes do take up space>!  If 
you're working with widths and heights to try to get your windows to fit just 
so, you should be doing so with sizer_debug I<turned off>.  Only turn it on to 
get a mental picture of where your sizers are.

 has 'sizer_debug' => ( is => 'rw', isa => 'Int', default => 0 );
 has 'sizer_debug' => ( is => 'rw', isa => 'Int', default => 1 );

=head1 PROVIDED METHODS

=head2 build_sizer

Builds and returns a sizer.  The simplest and most common usage returns an 
invisible sizer when $self->sizer_debug is off, and a visible box with the 
sizer's name when $self->sizer_debug is on.

 $sizer = $self->build_sizer( $self->parent, wxHORIZONTAL, 'My Sizer Name' );

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
