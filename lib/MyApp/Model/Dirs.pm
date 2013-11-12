use v5.14;

package MyApp::Model::Dirs {
    use warnings;
    use Moose;
    use MyApp::Types;

    has 'root' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        required    => 1,
        coerce      => 1,
    );
    #############
    has 'assets' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return $_[0]->root->subdir(qw/var/) }
    );
    has 'data' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return $_[0]->assets->subdir(qw/db/) }
    );
    has 'html' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return $_[0]->assets->subdir(qw/doc html/) }
    );
    has 'html_idx' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return $_[0]->assets->subdir(qw/doc html idx/) }
    );
    has 'img' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return $_[0]->assets->subdir(qw/img/) }
    );
    has 'wav' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return $_[0]->assets->subdir(qw/wav/) }
    );

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;


__END__

=head1 NAME

MyApp::Model::Dirs - Easy access to application-specific directories

=head1 SYNOPSIS

 my $dirs = MyApp::Model::Dirs->new( root => '/application/root/directory' );
 my $directory_with_html_help_files = $dirs->html;

=head1 DESCRIPTION

Abstracts away the specific location of any directories that your app needs to 
access, so if you need to move a directory for any reason, you can update this 
module instead of having to track down every directory access in your app.

=head1 METHODS

=head2 Constructor (new)

=over 4

=item * ARGS

=over 8

=item * hashref - required

This must contain the key 'root', pointing to your application's root 
directory.

=back

=item * RETURNS

=over 8

=item * MyApp::Model::Dirs object

=back

=back

=head2 PROVIDED DIRECTORIES

Additional directories can be added easily by following the existing code as 
example.

=over 4

=item * root - the root directory you provided in the constructor

All of the other directories provided will be children of this root.

=item * html - the root directory of your HTML help files

=item * html_idx - the directory containing the search index created by 
bin/update_help.pl (indexes your help files so the Help applet's search 
feature will work).

=item * assets - the root directory containing all of your media assets

=item * data - the directory containing your SQLite database file

=item * img - the root directory containing your image assets

=item * wav - the root directory containing your sound assets

=back

=head1 AUTHOR

Jonathan D. Barton <tmtowtdi@gmail.com>

=head1 LICENSE

Copyright 2013 Jonathan D. Barton. All rights reserved.

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

