
package MyApp::Types {
    use Moose::Util::TypeConstraints;
    use Path::Class;

    class_type 'PathClassDir', { class => 'Path::Class::Dir' };
    coerce 'PathClassDir', 
        from 'Str', via{ return Path::Class::dir($_) };

    class_type 'PathClassFile', { class => 'Path::Class::File' };
    coerce 'PathClassFile', 
        from 'Str', via{ return Path::Class::file($_) };

}

1;

__END__

=head1 NAME

MyApp::Types - Customized data types

=head1 SYNOPSIS

# In your MyApp::Example.pm module...

 use MyApp::Types;

 has 'dirname' => (
  is     => 'ro',
  isa    => 'PathClassDir',
  coerce => 1,
 );

# In your calling code...

 use MyApp::Example;

 my $eg = MyApp::Example->new(
  dirname => '/path/to/directory',  # arg is just a string
 );

 say ref $eg->dirname;              # "Path::Class::Dir"

=head1 DESCRIPTION

Sets up data types, some with coercions, used throughout MyApp.

=head1 TYPES

=head2 PathClassDir

A Path::Class::Dir object, coercible from Str.

=head2 PathClassFile

A Path::Class::Dir object, coercible from Str.

=head1 AUTHOR

Jonathan D. Barton <tmtowtdi@gmail.com>

=head1 LICENSE

Copyright 2013 Jonathan D. Barton. All rights reserved.

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

