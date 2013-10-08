#!/usr/bin/perl

use v5.14;
use warnings;
use FindBin;

use lib $FindBin::Bin . '/../lib';
use MyApp;

my $app = MyApp->new();
$app->MainLoop();

