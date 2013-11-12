#!/usr/bin/perl

use v5.14;
use warnings;

BEGIN {
    ### To display the splash screen immediately, this must happen as early as 
    ### possible.
    use FindBin;
    use Wx::Perl::SplashFast( "$FindBin::Bin/../var/img/splash.png", 50 );
}

use lib $FindBin::Bin . '/../lib';
use MyApp;

my $app = MyApp->new( root_dir => "$FindBin::Bin/.." );
$app->MainLoop();

