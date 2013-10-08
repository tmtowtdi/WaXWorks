
use v5.14;

package MyApp::Model::LogsSchema::Logs {#{{{
    use base 'DBIx::Class::Core';
    use Carp;
    use DateTime;
    use DateTime::Format::ISO8601;

    __PACKAGE__->table('Logs');
    __PACKAGE__->load_components(qw/FilterColumn/);
    __PACKAGE__->add_columns( 
        id          => {data_type => 'integer', is_auto_increment => 1, is_nullable => 0, extra => {unsigned => 1} },
        run         => {data_type => 'integer',                         is_nullable => 0 },
        level       => {data_type => 'varchar', size => 16,             is_nullable => 1 },
        component   => {data_type => 'varchar', size => 32,             is_nullable => 1 },
        datetime    => {data_type => 'datetime',                        is_nullable => 1 },
        message     => {data_type => 'text',                            is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key( 'id' ); 
    __PACKAGE__->filter_column( datetime => {
        filter_to_storage   => '_datetime_to_column',
        filter_from_storage => '_column_to_datetime',
    });

    sub _datetime_to_column {#{{{
        my $self = shift;
        my $cand = shift;

        return $cand->iso8601 if ref $cand eq 'DateTime';
        return unless $cand;
        croak "Invalid date format" unless $cand =~ m/^\d{4}-\d\d-\d\d[T ]\d\d:\d\d:\d\d$/;
        return $cand;
    }#}}}
    sub _column_to_datetime {#{{{
        my $self = shift;
        my $cand = shift;

        ### It's nullable so a false value will be undef.
        return unless $cand;

        ### The Schemas insert the value in ISO8601, so the 'T' exists between 
        ### date and time.  But if you enter a date manually using SQLite 
        ### manager, it omits the T.  Parsing from 8601 requires the 'T', so jam 
        ### it in there if it's missing.
        $cand =~ s/^(\d{4}-\d\d-\d\d) (\d\d:\d\d:\d\d)$/$1T$2/;

        if( $cand =~ m/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d$/ ) {
            return DateTime::Format::ISO8601->parse_datetime($cand);
        }
        else {
            croak "Invalid datetime format in database -$cand-"
        }
        return 1;
    }#}}}

}#}}}

package MyApp::Model::LogsSchema {
    use v5.14;
    use base qw(DBIx::Class::Schema);
    __PACKAGE__->load_classes(qw/Logs/);
}

1;
