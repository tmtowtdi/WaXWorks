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

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;


__END__

CHECK - docu is incomplete

=head1 NAME

MyApp::Model::Assets - Container for media assets

=head1 SYNOPSIS

 my $dirs       = MyApp::Model::Dirs->new();
 my $root       = $dirs->root;
 my $html       = $dirs->html;
 my $html_idx   = $dirs->html_idx;
 my $wav        = $dirs->wav;

=head1 DESCRIPTION

=head1 AUTHOR

Jonathan D. Barton <tmtowtdi@gmail.com>

=head1 LICENSE

Copyright 2013 Jonathan D. Barton. All rights reserved.

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

