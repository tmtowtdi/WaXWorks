use v5.14;

package MyApp::Model::SearchIndex::Help {
    use HTML::TreeBuilder::XPath;
    use Moose;
    use MyApp::Model::Container;
    use Path::Class;
    extends 'MyApp::Model::SearchIndex';

    has 'bb'  => (
        is          => 'rw',
        isa         => 'MyApp::Model::Container',  
        lazy        => 1,
        default     => sub{ MyApp::Model::Container->new(name => 'update help') },
        handles => {
            resolve => 'resolve',
        }
    );
    has 'html_dir'  => (
        is          => 'rw',
        isa         => 'Path::Class::Dir',  
        lazy        => 1,
        default     => sub{ Path::Class::dir( $_[0]->resolve(service => '/Directory/doc/html') ) },
    );
    has 'index' => (
        is          => 'rw',
        isa         => 'Path::Class::Dir',
        lazy        => 1,
        default     => sub{ Path::Class::dir( $_[0]->resolve(service => '/Directory/doc/html_idx') ) },
    );
    has 'summary_length' => (
        is          => 'rw',
        isa         => 'Int', 
        default     => 120
    );
    has 'xpath' => (
        is          => 'rw',
        isa         => 'HTML::TreeBuilder::XPath',
        lazy        => 1,
        default     => sub{ HTML::TreeBuilder::XPath->new() },
        handles     => {
            findnodes   => 'findnodes',
            xpath_reset => 'delete',
        }
    );

    sub BUILD {
        my $self = shift;
        return $self;
    }
    sub clean_text {#{{{
        my $self = shift;
        my $text = shift;
        $text = " $text";
        $text =~ s/[\r\n]/ /g;
        $text =~ s/\s{2,}/ /g;
        $text =~ s/\s+$//;
        return $text;
    }#}}}
    sub get_doc_summary {#{{{
        my $self  = shift;

        my @nodeset = $self->findnodes('/html/body/*');
        my $summary  = q{};
        NODE:
        for my $n(@nodeset) {
            next if $n->getName =~ /^h/i;   # skip headers
            $summary .= $self->clean_text($n->getValue);
            last NODE if length $summary > $self->summary_length;
        }
        $summary = substr $summary, 0, $self->summary_length;
        return $summary;
    }#}}}
    sub xparse {#{{{
        my $self = shift;
        my $content = shift;

        ### The help "html" files are really just templates; the wrapper is 
        ### handling the opening and closing tags.  But the missing tags are 
        ### going to give XPath fits, so fake some up.
        $self->xpath->parse("<html><body>$content</body></html>");
    }#}}}

    no Moose;
    __PACKAGE__->meta->make_immutable; 
}

1;

