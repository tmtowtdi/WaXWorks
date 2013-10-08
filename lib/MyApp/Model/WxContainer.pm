use v5.14;
use warnings;

package MyApp::Model::WxContainer {
    use Archive::Zip;
    use Archive::Zip::MemberRead;
    use Bread::Board;
    use Carp;
    use English qw( -no_match_vars );
    use Moose;
    use MooseX::NonMoose;
    use Try::Tiny;
    use Wx qw(:everything);

    extends 'Bread::Board::Container';

    has 'root_dir' => ( is => 'rw', isa => 'Str', required => 1 );

    ### Assets
    has 'zip_file' => ( is => 'rw', isa => 'Str', lazy_build => 1 );

    sub BUILD {
        my $self = shift;

        container $self => as {
            container 'Assets' => as {#{{{
                my $zip             = Archive::Zip->new($self->zip_file);
                service 'zip'       => $zip;
                service 'zip_file'  => $self->zip_file;

=pod

Provides services for all media assets used by the app.  Right now, "all media 
assets" consist of many .png files and a single .ico file.  

The Assets container will hold sub-containers for each type of asset; images, 
sounds, etc.  All of these assets are stored in a zip file.

Keep in mind that, though zip/unzip programs tend to make it look like their 
members are stored in nested directories inside the zip file, those members 
don't actually behave like files and directories in your filesystem.

So the containers and services provided under this Assets container have to be set 
up carefully so they end up resembling the familiar path structure to the user.  
See the images subcontainer for examples.

=cut

                container 'images' => as {#{{{

=pod

Creates and returns a Wx::Image of the requested image, which you can then rescale 
if needed and convert to a bitmap for display:

 my $img = $self->app->bb->resolve(service => '/Assets/glyphs/chalcopyrite.png');
 $img->Rescale(39, 50);
 my $bmp = Wx::Bitmap->new($img);

 my $v = Wx::StaticBitmap->new(
  $self, -1,
  $bmp,
  wxDefaultPosition,
  Wx::Size->new($img->GetWidth, $img->GetHeight),
  wxFULL_REPAINT_ON_RESIZE
 );

Also provides a 'zip_file' service that reports on exactly which file is being 
read from:

 $file = self->app->bb->resolve(service => '/Assets/zip_file');
 say $file; # '/path/to/assets.zip'



You can freely add more subdirectories under images/ in the main assets.zip 
file, and sub-containers and services will be created for those new 
subdirectories automatically without any code changes.

HOWEVER, you may only add a single level of subdirectories under images:

 ### Fine.
 images/my_new_subdirectory/
 images/my_new_subdirectory/my_new_image_1.png
 images/my_new_subdirectory/my_new_image_2.png

 ...then, in calling code...

 my $bmp = $self->app->wxbb->resolve(service => '/Assets/images/my_new_subdirectory/my_new_image_1.png');


 ### NOT Fine - the 'futher_nested_subdirectory' will not work.  If you 
 ### absolutely must have this, you'll need to update the code under the images 
 ### container.
 images/my_new_subdirectory/further_nested_subdirectory/
 images/my_new_subdirectory/further_nested_subdirectory/my_new_image_1.png
 images/my_new_subdirectory/further_nested_subdirectory/my_new_image_2.png
 ...



The Assets zip file currently contains different members for the same image if 
that image has different sizes:

    images/glyphs/chalcopyrite.png
    images/glyphs/chalcopyrite_39x50.png
    images/glyphs/chalcopyrite_79x100.png

I now plan to keep just 'chalcopyrite.png' and rescale it as needed, so I'll 
ultimately be able to get rid of all of the resized images in the .zip file, 
which should save some space and time.

=cut

                    my %dirs = ();

                    foreach my $member( $zip->membersMatching("images/.*(png|ico)\$") ) {
                        $member->fileName =~ m{images/([^/]+)/};
                        my $dirname = $1;
                        push @{$dirs{$dirname}}, $member;
                    }

                    foreach my $dir( keys %dirs ) { # 'glyphs', 'planetside', etc
                        container "$dir" => as {
                            foreach my $image_member(@{ $dirs{$dir} }) {
                                $image_member->fileName =~ m{images/$dir/(.+)$};
                                my $image_filename = $1; # just the image name, eg 'beryl.png'

                                service "$image_filename" => (
                                    block => sub {
                                        my $s = shift;
                                        my $zfh = Archive::Zip::MemberRead->new(
                                            $zip,
                                            $image_member->fileName,
                                        );
                                        my $binary;
                                        while(1) {
                                            my $buffer = q{};
                                            my $read = $zfh->read($buffer, 1024);
                                            $binary .= $buffer;
                                            last unless $read;
                                        }
                                        open my $sfh, '<', \$binary or croak "Unable to open stream: $ERRNO";
                                        my $img = Wx::Image->new($sfh, wxBITMAP_TYPE_ANY);
                                        close $sfh or croak "Unable to close stream: $ERRNO";
                                        return(wantarray) ? ($img, $binary) : $img;
                                    }
                                );
                            }
                        }
                    }
                };# images }}}
            };# Assets }}}
        };

        return $self;
    }
    sub _build_zip_file {#{{{
        my $self = shift;
        return join q{/}, $self->root_dir, 'var/assets.zip';
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

