use v5.10;

package MyApp::Model::Logger {
    use warnings;
    use DateTime::Format::ISO8601;
    use DateTime::TimeZone;
    use DBI;
    use Log::Dispatch;
    use Moose;

    use MyApp::Model::Logger::Outputs::DBI;
    use MooseX::NonMoose;
    extends 'Log::Dispatch';

    has 'schema' => (
        is          => 'ro',
        isa         => 'MyApp::Model::LogsSchema',
        required    => 1,
    );
    #######################
    has 'logs_expire' => (
        is          => 'ro',
        isa         => 'Int',
        default     => 7,
        documentation => q{
            Log entries older than this many days will be pruned from the 
            logging database on app exit.
        }
    );
    has 'output_dbi' => (
        is          => 'ro',
        isa         => 'MyApp::Model::Logger::Outputs::DBI',
        lazy_build  => 1,
    );
    has 'table' => (
        is          => 'ro',
        isa         => 'Str',
        default     => 'Logs',
    );
    has 'tz_local' => (
        is          => 'ro',
        isa         => 'Str',
        lazy_build  => 1,
    );
    has 'tz_use' => (
        is          => 'ro',
        isa         => 'Str',
        lazy        => 1,
        #default     => 'UTC',
        default     => sub{ $_[0]->tz_local },
        documentation => q{
            Log entries get a timestamp; this determines the timezone to use.  
            You probably want the user's local timezone, but you might want 
            UTC.  Pick the default that suits you.
        }
    );

    sub BUILD {
        my $self = shift;
        $self->add( $self->output_dbi );
        return $self;
    }
    sub _build_tz_local {#{{{
        my $self = shift;
        return DateTime::TimeZone->new( name => 'local' )->name();
    }#}}}
    sub _build_output_dbi {#{{{
        my $self = shift;
        my $o = MyApp::Model::Logger::Outputs::DBI->new(
            name        => 'dbi',
            min_level   => 'debug',
            time_zone   => $self->tz_use,
            dbh         => $self->schema->storage->dbh,
            table       => $self->table,
            callbacks   => sub{ my %h = @_; return sprintf "%s", $h{'message'}; }
        );

        return $o;
    }#}}}

    sub prune_bydate {#{{{
        my $self = shift;
        my $date = shift;
        ref $date eq 'DateTime' or return;
        my $oldest = $date->iso8601;
        my $dbh = $self->schema->storage->dbh;
        my $sth = $dbh->prepare(qq/ DELETE FROM $self->{'table'} WHERE datetime < ? /);
        return $sth->execute($oldest);
    }#}}}


    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;


__END__

=head1 NAME

MyApp::Model::Logger - Application-wide logger

=head1 SYNOPSIS

 my $db = MyApp::Model::Database->new( E<lt>Path::Class::Dir object indicating SQLite data directoryE<gt>  );
 my $l = MyApp::Model::Logger->new( schema => $db->logs_schema );

 $l->component("MyTest");
 $l->debug("This is a debug message");
 $l->info("This is an info message");

 ...time passes, you're about to close your app...

 $l->prune_bydate();    # clear out old log entries

=head1 DESCRIPTION

=head1 AUTHOR

Jonathan D. Barton <tmtowtdi@gmail.com>

=head1 LICENSE

Copyright 2013 Jonathan D. Barton. All rights reserved.

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

