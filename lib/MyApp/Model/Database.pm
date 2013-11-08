use v5.10;

package MyApp::Model::Database {
    use warnings;
    use Moose;
    use Path::Class qw();

    use MyApp::Model::LogsSchema;

    ### CHECK
    ### this should really have a coercion from Str set up.
    has 'data_dir' => (
        is          => 'ro',
        isa         => 'Path::Class::Dir',
        required    => 1,
    );
    #######################
    has 'sql_options' => (
        is      => 'rw',
        isa     => "HashRef[Any]",
        default => sub{ {sqlite_unicode => 1, quote_names => 1} },
    );
    has 'db_file' => (
        is          => 'ro',
        isa         => 'Path::Class::File',
        lazy        => 1,
        default     => sub{ return Path::Class::File->new( $_[0]->data_dir->file(qw/log.sqlite/) )->absolute->cleanup },
    );
    has 'dsn' => (
        is          => 'ro',
        isa         => 'Str',
        lazy        => 1,
        default     => sub{ 'DBI:SQLite:dbname=' . $_[0]->db_file },
    );
    has 'logs_schema' => (
        is          => 'ro',
        isa         => 'MyApp::Model::LogsSchema',
        lazy_build  => 1,
    );

    sub BUILD {
        my $self = shift;

        ### Make sure that the logging database has been deployed
        $self->_o_creat_database_log();
    }

    sub _build_logs_schema {#{{{
        my $self = shift;
        my $schema = MyApp::Model::LogsSchema->connect(
            $self->dsn,
            $self->sql_options,
        );
        return $schema;
    }#}}}
    sub _o_creat_database_log {#{{{
        my $self = shift;

        unless( $self->db_file->stat ) {
            $self->logs_schema->deploy;
        }
        return 1;
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;


__END__

=head1 NAME

MyApp::Model::Database - App-wide database settings

=head1 SYNOPSIS

 $d = MyApp::Model::Database->new( data_dir => Path::Class::Dir->new('/directory/containing/sqlite/database/files/') );

 say "We're connected to the SQLite file " . $d->db_file;
 say "Our DSN is " . $d->dsn;

=head1 DESCRIPTION

Sets up schemas, dsns, etc needed to connect your app to its database.  

If the database file does not exist, possibly this is a new install or someone 
simply deleted the thing, it will be created, empty (but with the proper 
schema setup for use).

=head1 AUTHOR

Jonathan D. Barton <tmtowtdi@gmail.com>

=head1 LICENSE

Copyright 2013 Jonathan D. Barton. All rights reserved.

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

