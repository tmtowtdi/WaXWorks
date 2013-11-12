use v5.14;

package MyApp::Model::Assets::Zipfile {
    use warnings;
    use Archive::Zip qw(:ERROR_CODES);
    use Moose;
    use MyApp::Types;

    use MooseX::NonMoose;
    extends 'Archive::Zip::Archive';

    has 'file' => (
        is          => 'ro',
        isa         => 'PathClassFile',
        coerce      => 1,
        required    => 1,
    );

    has 'zip' => (
        is          => 'ro',
        isa         => 'Archive::Zip',
        lazy        => 1,
        default     => sub{ Archive::Zip->new( $_[0]->file ) },
    );


    sub FOREIGNBUILDARGS {#{{{
        my $class = shift;
        my %args  = @_;  
        return $args{'file'};
    }#}}}

    sub get_member {#{{{
        my $self = shift;
        my $path = shift;
        return $self->memberNamed($path);
    }#}}}
    sub read_member {#{{{
        my $self            = shift;
        my $path_or_member  = shift;

        unless( ref $path_or_member eq 'Archive::Zip::ZipFileMember' ) {
            $path_or_member = $self->get_member( $path_or_member ) or return undef;
        }

        my( $str, $status ) = $path_or_member->contents;
        return undef unless $status == AZ_OK;
        return $str;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::Model::Assets::Zipfile - Access assets stored in a .zip file

=head1 SYNOPSIS

 $zip  = MyApp::Model::Assets::Zipfile->new( file => '/path/to/file.zip' );
 $name = 'images/some_image.png';

 $member = $zip->get_member( $name );

 $contents = $zip->read_member( $member );
 ...OR...
 $contents = $zip->read_member( $name );

=head1 DESCRIPTION

Sometimes it makes sense to store some of your assets in a zip file.  Some 
widgets must be stored in their own non-archive file for wxwidgets to be able 
to deal with them, and reading an asset from a .zip file is going to be slower 
than just reading it from the filesystem.

However, if you have many assets (generally, images), updating all of them by 
replacing a single .zip file can be more convenient than replacing each 
individual file.

=head1 METHODS

=head2 Constructor (new)

=over 4

=item * ARGS

=over 8

=item * required hashref - C<file =E<gt> '/path/to/zipfile.zip'>

=back

=item * RETURNS

=over 8

=item * MyApp::Model::Assets::Zipfile object

=back

=back

=head2 get_member

Returns the Archive::Zip::ZipFileMember of the requested member.  Generally 
not useful; see L</read_member>.

=over 4

=item * ARGS

=over 8

=item * required scalar - 'path/to/desired/asset.ext'

=back

=item * RETURNS

=over 8

=item * Archive::Zip::ZipFileMember object or undef if the requested member 
does not exist

=back

=back

=head2 read_member

=over 4

=item * ARGS

=over 8

=item * required - either a scalar 'path/to/desired/asset.ext' or an 
Archive::Zip::ZipFileMember as returned by L</get_member>.

=back

=item * RETURNS

=over 8

=item * scalar - the contents of the requested member

=back

=back

=head1 AUTHOR

Jonathan D. Barton <tmtowtdi@gmail.com>

=head1 LICENSE

Copyright 2013 Jonathan D. Barton. All rights reserved.

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

