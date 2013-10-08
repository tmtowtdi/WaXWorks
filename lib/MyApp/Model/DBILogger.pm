use v5.14;
use utf8;

package MyApp::Model::DBILogger {
    use warnings;
    use Carp;
    use Data::Dumper;
    use DateTime;
    use DateTime::Format::ISO8601;
    use DBI;
    use Moose;
    use MooseX::NonMoose;

    extends 'Log::Dispatch::DBI';

    has 'run'       => ( is  => 'rw', isa => 'Int', lazy_build => 1                     );
    has 'component' => ( is  => 'rw', isa => 'Str', lazy => 1,      default => 'main'   );
    has 'time_zone' => ( is  => 'rw', isa => 'Str', lazy => 1,      default => 'UTC'    );

    sub _build_run {#{{{
        my $self   = shift;
        my $maxrun = 0;

        my $sth  = $self->{'dbh'}->prepare("SELECT MAX(run) FROM $self->{'table'}");
        $sth->execute() or croak DBI::errstr;
        $maxrun = $sth->fetchrow_array() || 0;
        return ++$maxrun;
    }#}}}
    sub create_statement {#{{{
        my $self = shift;
        my $sth = $self->{dbh}->prepare(<<"SQL");
INSERT INTO $self->{table} ('run', 'component', 'level', 'datetime', 'message') VALUES (?, ?, ?, ?, ?)
SQL
        return $sth;
    }#}}}
    sub log_message {## no critic qw(RequireArgUnpacking) {{{
        my $self = shift;
        my %params = @_;

        my $date;
        if( defined $params{'datetime'} ) {
            if(ref $params{'datetime'} eq 'DateTime') {
                $date = $params{'datetime'}->iso8601;
            }
            elsif( $params{'datetime'} =~ m/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d$/ ) {
                $date = $params{'datetime'};    # it's already in correct format
            }
            else {
                croak "'datetime' parameter must be a DateTime object or ISO8601 format.";
            }
        }
        else {
            $date = DateTime->now( time_zone => $self->time_zone );
        }

        $self->{sth}->execute(
            $self->run, 
            $self->component, 
            $params{'level'}, 
            $date,
            $params{'message'}
        );
        return 1;
    }#}}}
    sub prune_bydate {#{{{
        my $self = shift;
        my $date = shift;
        ref $date eq 'DateTime' or return;
        my $oldest = $date->iso8601;
        my $sth = $self->{'dbh'}->prepare(qq/ DELETE FROM $self->{'table'} WHERE datetime < ? /);
        return $sth->execute($oldest);
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

### Add some methods to Log::Dispatch so we can dick around with the output 
### channel's settings.
sub Log::Dispatch::component {#{{{
    my $self        = shift;
    my $component   = shift;
    $self->{'outputs'}{'dbi'}->component( $component );
    return 1;
}#}}}
sub Log::Dispatch::prune_bydate {#{{{
    my $self    = shift;
    my $date    = shift;
    ref $date eq 'DateTime' or return;
    return $self->{'outputs'}{'dbi'}->prune_bydate( $date );
}#}}}
sub Log::Dispatch::time_zone {#{{{
    my $self        = shift;
    my $time_zone   = shift;
    $self->{'outputs'}{'dbi'}->time_zone( $time_zone );
    return 1;
}#}}}

1;


__END__

=head1 NAME

MyApp::Model::DBILogger - DBI-based output channel for Log::Dispatch.

=head1 SYNOPSIS

 my $dbh = DBI->connect("dbi:SQLite:dbname=/path/to/database/file.sqlite", q{}, q{} );

 my $dbi_output = MyApp::Model::DBILogger->new(
  name        => 'dbi',
  min_level   => 'debug',
  dbh         => $dbh,
  table       => 'Logs',
  callbacks   => sub{ my %h = @_; return sprintf "%s", $h{'message'}; }
 );

 my $l = Log::Dispatch->new();
 $l->add( $dbi_output );

 $l->debug("This is a debug level message in component 'main'");
 $l->log(level => 'debug', message => "This too; just more explicit syntax.");

 $l->component("Some::Class");
 $l->info("This is an info level message in component 'Some::Class'");

 $l->component("Some::Other::Class");
 $l->time_zone("America/New_York");
 $l->info("This is an info level message in component 'Some::Other::Class' using a custom time zone.");

 use DateTime;
 use DateTime::Duration;

 # Delete all log entries older than 7 days.
 my $now   = DateTime->now();
 my $dur   = DateTime::Duration->new(days => 7);
 my $limit = $now->subtract( $dur );
 $l->prune_bydate( $limit );

=head1 Additional Log::Dispatch Methods

MyApp::Model::DBILogger does not require Log::Dispatch to be subclassed, but it 
does add a few methods to Log::Dispatch.

=head2 component

The 'component' attribute defaults to 'main'.  However, there's no guarantee 
that it will remain there, so you should re-set it each time you want to 
create a log entry:

 $obj->logger->info("This is in the 'main' component.");
 $obj->some_random_sub();
 $obj->logger->info("WHOOPS - this is in the 'some_random_sub' component.");

 $obj->logger->component('main');
 $obj->logger->info("Yay - this is back in the 'main' component.");

 sub some_random_sub {
  my $s = shift;
  $s->logger->component('some_random_sub');
  $s->logger->info("This is in the 'some_random_sub' component.");
  return 1;
 }

=head2 time_zone

The time zone used for log entries.  Defaults to 'UTC'.

 $obj->logger->info('This will have a UTC timestamp attached to it.');

 $obj->logger->time_zone('America/New_York');
 $obj->logger->info('This will have an America/New_York timestamp attached to it.');

=head2 run

A simple integer ID that remains constant throughout a single run of the 
program.  Upon restart, this number will be incremented by 1.

There's no need to mangle this yourself.
 
 $obj->logger->info("Assuming this is the user's very first run of this program, this will have a 'run' setting of '1'.");
 $obj->logger->info("So will this.");

 $obj->component("Changing::Components::Here");
 $obj->time_zone("America/New_York");

 $obj->logger->info("Still 'run' ID of '1'.");

 ...user exits the program, later in the day re-runs it...

 $obj->logger->info("This will have a 'run' setting of '2'.");
 $obj->logger->info("So will this.");

 ...etc...

This is to make it easier to eyeball the Logs table and see which entries are 
from which run of the program.

=cut

CREATE TABLE "Logs" (
    "id" INTEGER PRIMARY KEY  AUTOINCREMENT  NOT NULL, 
    "run" INTEGER,
    "level" VARCHAR,
    "component" VARCHAR, 
    "datetime" DATETIME NOT NULL  DEFAULT CURRENT_TIMESTAMP, 
    "message" TEXT
)

