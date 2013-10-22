use v5.14;

package MyApp::Model::SearchIndex {
    use Carp qw(croak);
    use Lucy::Analysis::PolyAnalyzer;
    use Lucy::Index::Indexer;
    use Lucy::Plan::Schema;
    use Lucy::Plan::FullTextType;
    use Lucy::Search::IndexSearcher;
    use Moose;
    use Moose::Util::TypeConstraints;
    use Try::Tiny;

    subtype 'pc_from_str', as 'Path::Class::Dir';
    coerce 'pc_from_str', from 'Str', via{ say "-$_-"; return Path::Class::dir($_) };

    has 'index' => (
        is          => 'ro',
        isa         => 'pc_from_str',
        coerce      => 1,
        documentation => q{ Must be a directory. },
    );
    has 'fields' => (
        is          => 'ro',
        isa         => 'HashRef[Bool]',
        lazy        => 1,
        default     => sub{ {title => 1, content => 1} },
    );
    has 'is_schema_synced' => (
        is          => 'rw',
        isa         => 'Bool',
        default     => 0,
    );
    has 'poly' => (
        is          => 'ro',
        isa         => 'Lucy::Analysis::PolyAnalyzer',
        default     => sub{ Lucy::Analysis::PolyAnalyzer->new(language => 'en') },
    );
    has 'searcher' => (
        is          => 'ro',
        isa         => 'Lucy::Search::IndexSearcher',
        lazy        => 1,
        default     => sub{ Lucy::Search::IndexSearcher->new(index => $_[0]->index) },
    );
    has 'schema' => (
        is          => 'ro',
        isa         => 'Lucy::Plan::Schema',
        lazy_build  => 1,
    );
    has 'text_type' => (
        is          => 'ro',
        isa         => 'Lucy::Plan::FullTextType',
        lazy        => 1,
        default     => sub{ Lucy::Plan::FullTextType->new(analyzer => $_[0]->poly) },
    );

    sub BUILD {
        my $self = shift;

        try { $self->index->resolve }
        catch {
            try{ $self->index->mkpath }
            catch{ croak "Index $self->index is not a directory and could not be created." }
        };

        return $self;
    }

    sub _build_schema {#{{{
        my $self = shift;
        return Lucy::Plan::Schema->new();
    }#}}}

    sub add_docs {#{{{
        my $self    = shift;
        my $docs    = shift;
        my $indexer = shift || $self->get_indexer;

        foreach my $doc( @{$docs} ) {
            ### Ensure the documents passed in do not contain any fields that 
            ### aren't already part of the schema.
            my $doc_to_add = {};
            @{$doc_to_add}{$self->list_fields} = @{$doc}{$self->list_fields};

            $indexer->add_doc( $doc_to_add );
        }
        $indexer->commit;
    }#}}}
    sub replace_docs {#{{{
        my $self = shift;
        my $docs = shift;

        $self->add_docs( $docs, $self->get_clean_indexer );
    }#}}}
    sub add_field {#{{{
        my $self = shift;
        my $field = shift;
        $self->fields->{$field} = 1;
        $self->is_schema_synced(0);
        return 1;
    }#}}}
    sub delete_field {#{{{
        my $self = shift;
        my $field = shift;
        $self->is_schema_synced(0);
        return delete $self->fields->{$field};
    }#}}}
    sub get_clean_indexer {#{{{
        my $self = shift;
        $self->set_schema_fields unless $self->is_schema_synced;
        my $indexer = Lucy::Index::Indexer->new(
            schema => $self->schema,  
            index  => $self->index,
            create => 1,
            truncate => 1,
        );
    }#}}}
    sub get_indexer {#{{{
        my $self = shift;
        $self->set_schema_fields unless $self->is_schema_synced;
        my $indexer = Lucy::Index::Indexer->new(
            schema => $self->schema,  
            index  => $self->index,
            create => 1,
        );
    }#}}}
    sub list_fields {#{{{
        my $self = shift;
        return keys %{ $self->fields };
    }#}}}
    sub set_schema_fields {#{{{
        my $self = shift;
        foreach my $f( $self->list_fields ) {
            $self->schema->spec_field( name => $f, type => $self->text_type );
        }
        $self->is_schema_synced(1);
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

__END__

=head1 NAME

MyApp::Model::SearchIndex - A searchable document index

=head1 SYNOPSIS

 ### Directory will be created if it does not already exist.
 $idx = MyApp::Model::SearchIndex->new( index => '/path/to/index/directory' ); 

 $idx->add_field('summary');
 $idx->delete_field('title');

 $document => {
    summary => 'This is a...',
    content => 'This is an example document content',
 };
 $idx->add_docs([ $document ]);

 $another_document => {
    summary => 'This is a...',
    content => 'This is another example document content',
 };
 $yet_another_document => {
    summary => 'This is a...',
    content => 'This is yet another example document content',
 };
 $idx->add_docs([ $another_document, $yet_another_document ]);

The index now contains three documents.

 $new_document => {
    summary => 'This is a...',
    content => 'This is a brand new document content to overwrite the previous.',
 };
 $idx->replace_docs([ $new_document ]);

The index now contains only one document.

 $hits = $idx->searcher->hits( query => 'brand new' );
 while( my $h = $hits->next ) {
    say $h->{'summary'};    # 'This is a...',
    say $h->{'content'};    # 'This is a brand new document content to overwrite the previous.',
 }

