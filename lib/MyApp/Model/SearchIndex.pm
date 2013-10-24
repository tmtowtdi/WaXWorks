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
    coerce 'pc_from_str', from 'Str', via{ return Path::Class::dir($_) };

    has 'index_directory' => (
        is          => 'ro',
        isa         => 'pc_from_str',
        coerce      => 1,
        required    => 1,
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
        isa         => 'Maybe[Lucy::Search::IndexSearcher]',
        lazy_build  => 1,
        documentation => q{
            Until the search index is built (with bin/update_help.pl or similar), this 
            will be undef.
        }
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

        try { $self->index_directory->resolve }
        catch {
            try{ $self->index_directory->mkpath }
            catch{ croak "Index $self->index_directory is not a directory and could not be created." }
        };

        return $self;
    }

    sub _build_schema {#{{{
        my $self = shift;
        return Lucy::Plan::Schema->new();
    }#}}}
    sub _build_searcher {#{{{
        my $self = shift;

        my $s = try   { Lucy::Search::IndexSearcher->new(index => $self->index_directory) }
                catch { return undef };
        return $s;
    }#}}}
    sub _set_schema_fields {#{{{
        my $self = shift;
        foreach my $f( $self->list_fields ) {
            $self->schema->spec_field( name => $f, type => $self->text_type );
        }
        $self->is_schema_synced(1);
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
        $self->_set_schema_fields unless $self->is_schema_synced;
        my $indexer = Lucy::Index::Indexer->new(
            schema => $self->schema,  
            index  => $self->index_directory,
            create => 1,
            truncate => 1,
        );
    }#}}}
    sub get_indexer {#{{{
        my $self = shift;
        $self->_set_schema_fields unless $self->is_schema_synced;
        my $indexer = Lucy::Index::Indexer->new(
            schema => $self->schema,  
            index  => $self->index_directory,
            create => 1,
        );
    }#}}}
    sub list_fields {#{{{
        my $self = shift;
        return keys %{ $self->fields };
    }#}}}
    sub replace_docs {#{{{
        my $self = shift;
        my $docs = shift;
        $self->add_docs( $docs, $self->get_clean_indexer );
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
 $idx = MyApp::Model::SearchIndex->new(
  index_directory => '/path/to/index/directory'
 ); 

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

 if( $idx->searcher ) {
  $hits = $idx->searcher->hits( query => 'brand new' );
  while( my $h = $hits->next ) {
   say $h->{'summary'};    # 'This is a...',
   say $h->{'content'};    # 'This is a brand new document content to overwrite the previous.',
  }
 }
 else {
  say "The index does not contain any data yet so it cannot be searched.";
  say "Update your index, then try again.";
 }

=head1 DESCRIPTION

Creates and searches a L<Lucy> document index, and is used by the included 
Help browser.  SearchIndex can also be useful to other parts of your final app 
if you have need of another searchable document index.

=head1 METHODS

=head2 CONSTRUCTOR - new

=over 4

=item * ARGS

=over 8

=item * hash

=over 12

=item * C<index_directory =E<gt> '/path/to/directory'>

=back

=back

=item * RETURNS

=over 8

=item * MyApp::Model::SearchableIndex object

=back

=back

The C<index_directory> will be created if it does not already exist, and will 
contain the document index.

=head2 add_docs

=over 4

=item * ARGS

=over 8

=item * arrayref - of files to be I<added to the existing index>

=back

=item * RETURNS

=over 8

=item * nothing

=back

=back

See also L</replace_docs>.

=head2 add_field

=over 4

=item * ARGS

=over 8

=item * scalar - name of the field to add

=back

=item * RETURNS

=over 8

=item * nothing

=back

=back

Adds a field to the schema.

=head2 delete_field

=over 4

=item * ARGS

=over 8

=item * scalar - field to be deleted

=back

=item * RETURNS

=over 8

=item * nothing

=back

=back

Removes a field from the schema

=head2 get_clean_indexer

=over 4

=item * ARGS

=over 8

=item * nothing

=back

=item * RETURNS

=over 8

=item * Lucy::Index::Indexer object

=back

=back

Returns a L<Lucy::Index::Indexer> object I<pointing to a clean index>.  This 
means that the document index (pointed to by L</index_directory>) will be 
I<completely cleared of all of its content>!

So only use this when you're about to fully re-create your index.  See 
L</get_indexer> to non-destructively get an indexer.

=head2 get_indexer

=over 4

=item * ARGS

=over 8

=item *

=back

=item * RETURNS

=over 8

=item * Lucy::Index::Indexer object

=back

=back

Returns a L<Lucy::Index::Indexer> object.  Points to the existing 
L</index_directory> without cleaning it out first.

=head2 list_fields

=over 4

=item * ARGS

=over 8

=item * nothing

=back

=item * RETURNS

=over 8

=item * list - Names of the fields that have so far been added to the schema.

=back

=back

=head2 replace_docs

=over 4

=item * ARGS

=over 8

=item * arrayref - files to be I<inserted into a new, clean index, destroying 
any already-existing documents>

=back

=item * RETURNS

=over 8

=item * nothing

=back

=back

See also L</add_docs>

=head2 searcher

=over 4

=item * ARGS

=over 8

=item * none

=back

=item * RETURNS

=over 8

=item * Either a L<Lucy::Search::IndexSearcher> object or C<undef> if the index 
has not been created yet.

=back

=back

