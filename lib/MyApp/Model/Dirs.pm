use v5.10;

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
        default     => sub { return Path::Class::Dir->new($_[0]->root->subdir(qw/var/)) }
    );
    has 'data' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return Path::Class::Dir->new($_[0]->assets->subdir(qw/db/)) }
    );
    has 'html' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return Path::Class::Dir->new($_[0]->assets->subdir(qw/doc html/)) }
    );
    has 'html_idx' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return Path::Class::Dir->new($_[0]->assets->subdir(qw/doc html idx/)) }
    );
    has 'img' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return Path::Class::Dir->new($_[0]->assets->subdir(qw/img/)) }
    );
    has 'wav' => (
        is          => 'ro',
        isa         => 'PathClassDir',
        lazy        => 1,
        coerce      => 1,
        default     => sub { return Path::Class::Dir->new($_[0]->assets->subdir(qw/wav/)) }
    );

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;


__END__

CHECK - docu is incomplete

=head1 NAME

MyApp::Model::Dirs - Easy access to application-specific directories

=head1 SYNOPSIS

 my $dirs       = MyApp::Model::Dirs->new( root => '/application/root/directory' );
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

