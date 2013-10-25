use v5.14;

package MyApp::Model::Container {
    use Bread::Board;
    use Carp;
    use DateTime::TimeZone;
    use FindBin;
    use Moose;
    use MooseX::NonMoose;

    use MyApp::Model::DBILogger;

    ### This exists, commented, as a reminder not to get clever and add it.  
    ### It doesn't play well with Bread::Board.
    #use Moose::Util::TypeConstraints;

    extends 'Bread::Board::Container';

    ### Directories
    has 'root_dir' => (
        is          => 'rw',
        isa         => 'Str',
        lazy_build  => 1,
    );

    ### Logging
    has 'db_log_file'   => (
        is          => 'rw', 
        isa         => 'Str', 
        lazy_build  => 1,
    );
    has 'local_tz' => (
        is          => 'rw', 
        isa         => 'Str', 
        lazy_build  => 1,
        documentation => q{
            The name of your local TZ.  Built automatically.
        }
    );
    has 'log_tz' => (
        is          => 'rw', 
        isa         => 'Str', 
        lazy        => 1,
        default     => sub{ $_[0]->local_tz },
        #default    => 'UTC';
        documentation => q{
            The TZ that gets used for log entries; choose the default that 
            makes you happy.
        }
    );
    has 'log_component' => (
        is      => 'rw', 
        isa     => 'Str', 
        lazy    => 1,       
        default => 'main',
        documentation => q{
            Which part ("component") of your app is producing this log entry?
                log->component( 'ArbitraryString' );
                log->debug( 'some debug message' );
            That 'some debug message' log entry will contain 'ArbitraryString' in its 
            component field.  Makes it easier to look at just the log entries you're 
            interested in.
        }
    );
    has 'run' => (
        is  => 'rw', 
        isa => 'Int',
        documentation => q{
            A sequential integer that gets incremented each time this program is run.  
        }
    );
    has 'sql_options' => (
        is      => 'rw',
        isa     => "HashRef[Any]",
        lazy    => 1,
        default => sub{ {sqlite_unicode => 1, quote_names => 1} },
    );

    sub BUILD {
        my $self = shift;

        container $self => as {
            container 'DatabaseLog' => as {#{{{
                service 'db_file'       => $self->db_log_file;
                service 'sql_options'   => $self->sql_options;
                service 'dsn' => (#{{{
                    dependencies => {
                        db_file => depends_on('DatabaseLog/db_file'),
                    },
                    block => sub {
                        my $s = shift;
                        my $dsn = 'DBI:SQLite:dbname=' . $s->param('db_file');
                        return $dsn;
                    },
                );#}}}
                service 'connection' => (#{{{
                    class        => 'DBI',
                    dependencies => {
                        dsn         => (depends_on('DatabaseLog/dsn')),
                        sql_options => (depends_on('DatabaseLog/sql_options')),
                    },
                    block => sub {
                        my $s = shift;
                        return DBI->connect(
                            $s->param('dsn'),
                            q{},
                            q{},
                            $s->param('sql_options'),
                        );
                    },
                );#}}}
                service 'schema' => (#{{{
                    dependencies => [
                        depends_on('DatabaseLog/dsn'),
                        depends_on('DatabaseLog/sql_options'),
                    ],
                    class => 'MyApp::Model::LogsSchema',
                    block => sub {
                        my $s = shift;
                        my $conn = MyApp::Model::LogsSchema->connect(
                            $s->param('dsn'),
                            $s->param('sql_options'),
                        );
                        return $conn;
                    }
                );#}}}
            };#}}}
            container 'Directory' => as {#{{{
                service 'wav'   => join q{/}, $self->root_dir, qw(var wav);

                container 'doc' => as {
                    service 'html'      => join q{/}, $self->root_dir, qw(var doc html);
                    service 'html_idx'  => join q{/}, $self->root_dir, qw(var doc html idx);
                };
            };#}}}
            container 'Log' => as {#{{{
                service 'log_tz'        => $self->log_tz;
                service 'log_component' => $self->log_component;
                container 'Outputs' => as {#{{{
                    service 'dbi' => (#{{{
                        class => 'MyApp::Model::DBILogger',
                        dependencies => {
                            log_component   => depends_on('/Log/log_component'),
                            log_tz          => depends_on('/Log/log_tz'),
                            db_connection   => depends_on('/DatabaseLog/connection'),
                        },
                        block => sub {
                            my $s = shift;

                            my %args = (
                                name        => 'dbi',
                                min_level   => 'debug',
                                component   => $s->param('log_component'),
                                time_zone   => $s->param('log_tz'),
                                dbh         => $s->param('db_connection'),
                                table       => 'Logs',
                                callbacks   => sub{ my %h = @_; return sprintf "%s", $h{'message'}; }
                            );

                            if( $self->run ) { $args{'run'} = $self->run; }
                            my $l = MyApp::Model::DBILogger->new(%args);
                            unless( $self->run ) { $self->run( $l->run ); }

                            return $l;
                        }
                    );#}}}
                };#}}}
                service 'logger' => (#{{{
                    dependencies => [
                        depends_on('/Log/Outputs/dbi'),
                    ],
                    class => 'Log::Dispatch',
                    block => sub {
                        my $s = shift;
                        my $Outputs_container   = $s->parent;
                        my $outputs             = $Outputs_container->get_sub_container('Outputs');
                        my $log                 = Log::Dispatch->new;
                        $log->add( $outputs->get_service('dbi')->get );
                        $log;
                    }
                );#}}}
            };#}}}
        };

        return $self;
    }
    sub _build_db_log_file {#{{{
        my $self = shift;
        return $self->root_dir . '/var/db/log.sqlite';
    }#}}}
    sub _build_local_tz {#{{{
        my $self = shift;
        return DateTime::TimeZone->new( name => 'local' )->name();
    }#}}}
    sub _build_root_dir {#{{{
        my $self = shift;
        return "$FindBin::Bin/..";
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;
