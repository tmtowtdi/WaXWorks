use v5.14;

package MyApp::Model::Assets {
    use warnings;
    use Carp;
    use English qw( -no_match_vars );
    use Moose;
    use Wx qw(:everything);

    use MyApp::Model::Assets::Zipfile;

    has 'assets_root' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        coerce      => 1,
        documentation => q{
            Conditionally required; if any of your assets are stored as regular 
            files on the filesystem, this needs to be the path to the root of 
            those assets.
        },
    );
    has 'zip_file' => (
        is          => 'ro',
        isa         => 'PathClassFile',
        coerce      => 1,
        documentation => q{
            Also conditionally required; if any of your assets are coming out of a 
            .zip file, you do need to provide this.
        },
    );
    ############
    has 'zip' => (
        is          => 'ro',
        isa         => 'MyApp::Model::Assets::Zipfile',
        lazy_build  => 1,
    );

    sub _build_zip {#{{{
        my $self = shift;
        return MyApp::Model::Assets::Zipfile->new( file => $self->zip_file->stringify );
    }#}}}

    sub image_from_zip {#{{{
        my $self = shift;
        my $path = shift;

        ### path needs to be relative - no leading slash.  But that's 
        ### counter-intuitive.  If it's provided, just strip it rather than 
        ### dying.
        $path =~ s{^/}{};

        my $contents = $self->zip->read_member($path) or return;
        open my $sfh, '<', \$contents or croak "Unable to open stream: $ERRNO";
        my $img = Wx::Image->new($sfh, wxBITMAP_TYPE_ANY);
        close $sfh or croak "Unable to close stream: $ERRNO";
        return $img;
    }#}}}
    sub image_from_file {#{{{
        my $self = shift;
        my $path = shift;

        return unless( -e -r $path );
        my $img = Wx::Image->new($path, wxBITMAP_TYPE_ANY);
        return $img;
    }#}}}
    sub image {#{{{
        my $self = shift;
        my $path = shift;

        my $img = $self->image_from_zip($path) || $self->image_from_file($path);
        return $img;
    }#}}}

    sub sound_from_file {#{{{
        my $self = shift;
        my $file = shift;

        my $path = $self->dirs->wav->file( $file );
        return unless $path->stat;

        my $sound = Wx::Sound->new($path);
        return unless $sound->IsOk;

        return $sound;
    }#}}}
    sub sound {#{{{
        my $self = shift;
        my $path = shift;

        my $sound = $self->sound_from_file($path);
        return $sound;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;


__END__

=head1 NAME

MyApp::Model::Assets - Container for media assets

=head1 SYNOPSIS

 $assets = MyApp::Model::Assets->new(
  assets_root => '/path/to/directory/with/media/assets'
 );
 $image = $assets->image_from_file('images/file_picture.png');

OR

 $assets = MyApp::Model::Assets->new(
  zip_file => '/path/to/zip_file/with/media/assets.zip'
 );
 $image = $assets->image_from_zip('images/zip_picture.png');

OR

 $assets = MyApp::Model::Assets->new(
  assets_root => '/path/to/directory/with/media/assets',
  zip_file => '/path/to/zip_file/with/media/assets.zip'
 );

 $image_one = $assets->image_from_file('images/file_picture.png');
 $image_two = $assets->image_from_zip('images/zip_picture.png');

However you got the image:

 $image->Rescale( $width, $height );
 $bmp = Wx::Bitmap->new($image);

 $static = Wx::StaticBitmap->new(
    $parent_frame_dialog_or_panel, -1,
    $bmp,
    wxDefaultPosition,
    Wx::Size->new($img->GetWidth, $img->GetHeight),
    wxFULL_REPAINT_ON_RESIZE
 );

...And now $static can be placed into a sizer like you'd do with any other 
wxwidget.

=head1 DESCRIPTION

Finds the requested asset, and returns the appropriate Wx object created from 
that asset resource.  So an image stored on the filesystem or in a zip file as 
a .png will be returned as a Wx::Image, ready for processing.

=head1 METHODS

=head2 Constructor (new)

=over 4

=item * ARGS

=over 8

=item * hashref (required)

Assets can be stored either as files on your filesystem, or entries in a .zip 
file, or I<both>.

You must tell the constructor where you're storing your assets by supplying 
the correct keys to the passed hashref:

 assets_root => path on your filesystem to the root containing assets files

 zip_file => path on your filesystem to the zip file containing asset resources

You must include at least one of these.  If you have assets stored both on the 
filesystem and in a zip file, you may provide both.

=back

=item * RETURNS

=over 8

=item * MyApp::Model::Assets object

=back

=back

=head2 image_from_file

=over 4

=item * ARGS

=over 8

=item * scalar (required) - path to the image (relative to assets_root)

=back

=item * RETURNS

=over 8

=item * Wx::Image on success, undef on failure. 

=back

=back

=head2 image_from_zip

=over 4

=item * ARGS

=over 8

=item * scalar (required) - path to the image in the zip file

=back

=item * RETURNS

=over 8

=item * Wx::Image on success, undef on failure.

=back

=back

=head2 image

Attempts to find your image first on the filesystem, and next in your zip 
file.

If the image is in your zip file, calling this method will be slower than 
simply calling L</image_from_zip> in the first place.

=over 4

=item * ARGS

=over 8

=item * scalar (required) - path to the image

=back

=item * Wx::Image on success, undef on failure

=over 8

=item * nothing

=back

=back

=head2 sound_from_file

=over 4

=item * ARGS

=over 8

=item * scalar (required) - path to your sound file

=back

=item * RETURNS

=over 8

=item * Wx::Sound on success, undef on failure

=back

=back

=head2 sound

Simply calls L</sound_from_file>, as sounds cannot be drawn as streams from a 
zip file.  Included for consistency with L</image>.

=over 4

=item * ARGS

=over 8

=item * scalar (required) - path to your sound file

=back

=item * RETURNS

=over 8

=item * Wx::Sound on success, undef on failure

=back

=back

=head1 AUTHOR

Jonathan D. Barton <tmtowtdi@gmail.com>

=head1 LICENSE

Copyright 2013 Jonathan D. Barton. All rights reserved.

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

