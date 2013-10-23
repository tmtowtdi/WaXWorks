#!/usr/bin/perl

use v5.14;
use warnings;

use FindBin;
use lib $FindBin::Bin . '/../lib';
use MyApp::Model::SearchIndex::Help;

my $help = MyApp::Model::SearchIndex::Help->new();


my $cnt = fully_reindex( $help );
say "$cnt documents were indexed.";

### For testing that your re-indexing worked; use if desired
#search_test($help, 'nonsense');

sub fully_reindex {#{{{
    my $help = shift;

    my @help_files = grep{ /\.html?$/ }$help->html_dir->children();

    my $docs = [];
    foreach my $file( @help_files ) {

        my $html_content = $help->slurp($file);
        $help->xparse($html_content);

        my $title       = $help->get_doc_title          || 'No Title';
        my $summary     = $help->get_doc_summary()      || 'No Summary';
        my $raw_content = $help->strip($html_content);
        $help->reset();


        push @{$docs}, {
            content     => $raw_content,
            filename    => $file,
            summary     => $summary,
            title       => $title,
        };
    }
        
    $help->replace_docs( $docs );
    return scalar @$docs;
}#}}}
sub search_test {#{{{
    my $help    = shift;
    my $query   = shift;

    my $hits = $help->searcher->hits( query => $query );
    while( my $h = $hits->next ) {
        say "Filename: $h->{'filename'}";
        say "Title: $h->{'title'}";
        say "Summary: $h->{'summary'}";
        say "Contents: $h->{'content'}";
        say '---------------';
    }


}#}}}

