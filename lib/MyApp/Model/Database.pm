use v5.14;

package MyApp::Model::Database {
    use warnings;
    use Moose;

    use MyApp::Types;
    use MyApp::Model::LogsSchema;

    has 'data_dir' => (
        is          => 'ro',
        isa         => 'PathClassDir',
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
        isa         => 'PathClassFile',
        lazy        => 1,
        default     => sub{ return $_[0]->data_dir->file( qw/log.sqlite/ ) },
        writer      => '_update_db_file',
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

        ### Clean up the db_file path if it's messy.  But "cleanup", not 
        ### "resolve" - it may not already exist, in which case we'll deal 
        ### with it in the next step.
        $self->_update_db_file( $self->db_file->absolute->cleanup );

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

 $d = MyApp::Model::Database->new( data_dir => wxTheApp->dirs->data );

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

