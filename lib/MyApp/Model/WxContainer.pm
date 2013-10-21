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

    has 'root_dir' => ( is => 'rw', isa => 'Str', required => 1     );
    has 'zip_file' => ( is => 'rw', isa => 'Str', lazy_build => 1   );

    sub BUILD {
        my $self = shift;

        container $self => as {
            container 'assets' => as {#{{{
                my $zip             = Archive::Zip->new($self->zip_file);
                service 'zip'       => $zip;
                service 'zip_file'  => $self->zip_file;

                container 'images' => as {#{{{
                    my %img_subdirs = ();
                    foreach my $member( $zip->membersMatching("images/.*(png|ico|gif|jpe?g)\$") ) {
                        $member->fileName =~ m{images/([^/]+)/};
                        my $dirname = $1;
                        push @{$img_subdirs{$dirname}}, $member;
                    }

                    foreach my $dir( keys %img_subdirs ) {
                        container "$dir" => as {
                            foreach my $image_member(@{ $img_subdirs{$dir} }) {
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
            container 'fonts' => as {#{{{
                ### Swiss is variable-width sans-serif (arial).
                ### Modern is fixed-width.

                service 'para_text_1'       => Wx::Font->new(8,  wxSWISS, wxNORMAL, wxNORMAL, 0);
                service 'para_text_2'       => Wx::Font->new(10, wxSWISS, wxNORMAL, wxNORMAL, 0);
                service 'para_text_3'       => Wx::Font->new(12, wxSWISS, wxNORMAL, wxNORMAL, 0);
                service 'bold_para_text_1'  => Wx::Font->new(8,  wxSWISS, wxNORMAL, wxBOLD, 0);
                service 'bold_para_text_2'  => Wx::Font->new(10, wxSWISS, wxNORMAL, wxBOLD, 0);
                service 'bold_para_text_3'  => Wx::Font->new(12, wxSWISS, wxNORMAL, wxBOLD, 0);

                service 'modern_text_1'       => Wx::Font->new(8,  wxMODERN, wxNORMAL, wxNORMAL, 0);
                service 'modern_text_2'       => Wx::Font->new(10, wxMODERN, wxNORMAL, wxNORMAL, 0);
                service 'modern_text_3'       => Wx::Font->new(12, wxMODERN, wxNORMAL, wxNORMAL, 0);
                service 'bold_modern_text_1'  => Wx::Font->new(8,  wxMODERN, wxNORMAL, wxBOLD, 0);
                service 'bold_modern_text_2'  => Wx::Font->new(10, wxMODERN, wxNORMAL, wxBOLD, 0);
                service 'bold_modern_text_3'  => Wx::Font->new(12, wxMODERN, wxNORMAL, wxBOLD, 0);

                service 'header_1'   => Wx::Font->new(22, wxSWISS, wxNORMAL, wxBOLD, 0);
                service 'header_2'   => Wx::Font->new(20, wxSWISS, wxNORMAL, wxBOLD, 0);
                service 'header_3'   => Wx::Font->new(18, wxSWISS, wxNORMAL, wxBOLD, 0);
                service 'header_4'   => Wx::Font->new(16, wxSWISS, wxNORMAL, wxBOLD, 0);
                service 'header_5'   => Wx::Font->new(14, wxSWISS, wxNORMAL, wxBOLD, 0);
                service 'header_6'   => Wx::Font->new(12, wxSWISS, wxNORMAL, wxBOLD, 0);
                service 'header_7'   => Wx::Font->new(10, wxSWISS, wxNORMAL, wxBOLD, 0);
            };#}}}
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

__END__

=head1 NAME

MyApp::Model::WxContainer - Bread board containing GUI-related assets and settings.

=head1 SYNOPSIS

 $container = MyApp::Model::WxContainer->new(
  name     => 'a unique arbitrary container name',
  root_dir => "/path/to/app/install/dir"
 );

 my $img = $container->resolve(service => '/assets/images/app/home.png');
 $img->rescale( $some_width, $some_height );
 my $home_bmp = Wx::Bitmap->new($img);

 my $home_static_bmp = Wx::StaticBitmap->new(
  $self, -1,
  $bmp,
  wxDefaultPosition,
  Wx::Size->new($img->GetWidth, $img->GetHeight),
  wxFULL_REPAINT_ON_RESIZE
 );

 # Now, $home_static_bmp can be placed on the screen.

=head1 DESCRIPTION

=head1 SERVICES

Services are accessed from the container with:

 my $svc = $container->resolve( service => $service_name_as_indicated_below );

=over 4

=item * /assets/zip_file

The full path, as a string, to the assets.zip file.

=item * /assets/zip

An L<Archive::Zip> object representing the assets.zip file.

=item * /assets/images/E<lt>DIRECTORYE<gt>/E<lt>IMAGE_FILEE<gt>

The selected image as a Wx::Image object.

=item * /fonts/<FONT TYPE>

Fonts are organized as "para_text", "modern_text", and "header".  

para_text and modern_text fonts are meant to be used as normal paragraph fonts.  
Both range in size from 1 to 3, with the font size increasing as the number 
increases.  Both have regular and bolded versions available:

 my $small              = $container->resolve( service => '/fonts/para_text_1' );
 my $medium_bold        = $container->resolve( service => '/fonts/bold_para_text_2' );
 my $small_code         = $container->resolve( service => '/fonts/modern_text_1' );
 my $large_bold_code    = $container->resolve( service => '/fonts/bold_modern_text_3' );

headers range from 1 to 7, with their sizes I<decreasing> as their numbers 
increase, in the same way that HTML headers do:

 my $large_header = $container->resolve( service => '/fonts/header_1' );
 my $tiny_header  = $container->resolve( service => '/fonts/header_7' );

Whatever font you go with:

 my $font = $container->resolve( service => '/fonts/CHOSEN_FONT' );
 my $window = Wx::SomeControl->new( ... );
 $window->SetFont( $font );

=back

=head2 THE ASSETS FILE

Assets are meant to be contained in a single .zip file, which lives in 
var/assets.zip.  The idea is that all media assets can be contained within 
this one file, though it currently only contains images.

If other asset types are needed, a new container, sibling to the 'images' 
container, will need to be added.

=head3 IMAGES

All image assets must live in a subdirectory of images/.  GIF, ICO, JPEG, and 
PNG files are supported.  You can freely add more subdirectories under 
images/, and sub-containers and services will be created for those new 
subdirectories automatically without any code changes.

So if your app requires a collection of emotes, open assets.zip, create 
images/emotes/, and add your emote images there.  Those images would then 
become available to your app with

 my $smile = $container->resolve(service => '/assets/images/emotes/smile.png');

HOWEVER, you may only add a single level of subdirectories under images:

 ### Fine.
 images/emotes/
 images/emotes/smile.png
 images/emotes/cry.png

 ### NOT Fine - the additional 'happy' subdirectory will not work.
 images/emotes/happy/
 images/emotes/happy/smile.png
 images/emotes/happy/laugh.png


