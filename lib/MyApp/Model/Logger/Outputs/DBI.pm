use v5.14;

package MyApp::Model::Logger::Outputs::DBI {
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

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

1;


__END__

=head1 NAME

MyApp::Model::Logger::Outputs/DBI - DBI-based output channel for Log::Dispatch.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Jonathan D. Barton <tmtowtdi@gmail.com>

=head1 LICENSE

Copyright 2013 Jonathan D. Barton. All rights reserved.

This library is free software. You can redistribute it and/or modify it under the same terms as perl itself.

