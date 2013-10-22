#!/usr/bin/perl

use v5.14;
use warnings;

use File::Slurp;
use HTML::Strip;
use HTML::TreeBuilder::XPath;

use FindBin;
use lib $FindBin::Bin . '/../lib';
use MyApp::Model::SearchIndex::Help;



my $help = MyApp::Model::SearchIndex::Help->new();

$help->add_field('filename');
$help->add_field('title');     # default, but included to avoid confusion
$help->add_field('content');   # default, but included to avoid confusion
$help->add_field('summary');

my @help_files = grep{ /\.html?$/ }$help->html_dir->children();

my $docs = [];
my $kandi = HTML::Strip->new();
foreach my $file( @help_files ) {

    my $html_content = read_file($file);
    $help->xparse($html_content);

    my $title       = $help->xpath->findvalue("/html/body/h1")  || 'No Title';
    my $summary     = $help->get_doc_summary()                  || 'No Summary';
    my $raw_content = $kandi->parse($html_content);

    $kandi->eof;
    $help->xpath_reset;

    push @{$docs}, {
        content     => $raw_content,
        filename    => $file,
        summary     => $summary,
        title       => $title,
    };
}
    
$help->replace_docs( $docs );
say @$docs . " documents were indexed.";

