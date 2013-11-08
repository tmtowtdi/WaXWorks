use v5.10;

package MyApp::Model::Dirs {
    use warnings;
    use Moose;

    has 'root' => (
        is          => 'ro',
        isa         => 'Path::Class::Dir',
        lazy        => 1,
        default     => sub { return Path::Class::Dir->new($FindBin::Bin, '..')->absolute->resolve }
    );

    has 'data' => (
        is          => 'ro',
        isa         => 'Path::Class::Dir',
        lazy        => 1,
        default     => sub { return Path::Class::Dir->new($_[0]->root->subdir(qw/var db/)) }
    );

    has 'html' => (
        is          => 'ro',
        isa         => 'Path::Class::Dir',
        lazy        => 1,
        default     => sub { return Path::Class::Dir->new($_[0]->root->subdir(qw/var doc html/)) }
    );

    has 'html_idx' => (
        is          => 'ro',
        isa         => 'Path::Class::Dir',
        lazy        => 1,
        default     => sub { return Path::Class::Dir->new($_[0]->root->subdir(qw/var doc html idx/)) }
    );

    has 'wav' => (
        is          => 'ro',
        isa         => 'Path::Class::Dir',
        lazy        => 1,
        default     => sub { return Path::Class::Dir->new($_[0]->root->subdir(qw/var wav/)) }
    );

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;


__END__

=head1 NAME

MyApp::Model::Dirs - Easy access to application-specific directories

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

