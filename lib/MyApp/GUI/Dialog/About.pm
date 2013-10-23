
package MyApp::GUI::Dialog::About {
    use Moose;

    has 'app'   => ( is => 'ro', isa => 'MyApp', required => 1  );

    has 'info'  => (
        is          => 'rw',
        isa         => 'Wx::AboutDialogInfo',
        lazy_build  => 1,
    );

    has 'copyright'  => (
        is          => 'ro',
        isa         => 'Str',
        default     => 'Copyright 2012, 2013 Jonathan D. Barton',
    );
    has 'description'  => (
        is          => 'ro',
        isa         => 'Str',
        default     => 'A short description of this app.'
    );
    has 'license'  => (
        is          => 'ro',
        isa         => 'Str',
        default     => qq{This is free software; you can redistribute it and/or modify it under\nthe same terms as the Perl 5 programming language system itself.},
    );

    ### Credits
    ### Just delete any names that don't apply
    has 'artists'  => (
        is          => 'ro',
        isa         => 'ArrayRef[Str]',
        default     => sub {[
            'Some Artist',
            'Ann Other Artist',
            'Y. A. Artist ',        # you get the idea
        ]},
    );
    has 'developers'  => (
        is          => 'ro',
        isa         => 'ArrayRef[Str]',
        default     => sub {[
            'Jonathan D. Barton',   # etc
        ]},
    );
    has 'doc_writers'  => (
        is          => 'ro',
        isa         => 'ArrayRef[Str]',
        default     => sub {[
            'Jonathan D. Barton',
        ]},
    );

    sub BUILD {
        my $self = shift;

        $self->info->SetName( $self->app->GetAppName );
        $self->info->SetVersion( "$MyApp::VERSION - wxPerl $Wx::VERSION" );
        $self->info->SetCopyright( $self->copyright );
        $self->info->SetDescription( $self->description );
        $self->info->SetLicense( $self->license );

        for my $a( @{$self->artists} ) {
            $self->info->AddArtist($a);
        }
        for my $d( @{$self->developers} ) {
            $self->info->AddDeveloper($d);
        }
        for my $d( @{$self->doc_writers} ) {
            $self->info->AddDocWriter($d);
        }

        return $self;
    }
    sub _build_info {#{{{
        my $self = shift;
        return Wx::AboutDialogInfo->new();
    }#}}}

    sub show {#{{{
        my $self = shift;
        Wx::AboutBox($self->info);
        return;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;

__END__

=head1 NAME

MyApp::GUI::Dialog::About - Standard about dialog

=head1 SYNOPSIS

 $about = MyApp::GUI::Dialog::About->new( app => wxTheApp );

=head1 DESCRIPTION

Most other frames, dialogs, etc in this app extend their Wx:: counterparts.  
However, there is no C<Wx::AboutDialog> class; instead, C<Wx::AboutBox> is a 
function which will display either a native About dialog box if possible, or a 
Generic one if not.

Since this class is not extending a Wx:: class, it has no access to the 
standard C<wxTheApp> used by other classes, so the app object must be passed 
in to the constructor.

