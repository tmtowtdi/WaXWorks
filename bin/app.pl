#!/usr/bin/perl

use v5.14;
use warnings;

BEGIN {
    ### To display the splash screen immediately, this must happen as early as 
    ### possible.
    use FindBin;
    use Wx::Perl::SplashFast( "$FindBin::Bin/../var/splash.png", 50 );
}

use Time::HiRes qw(gettimeofday tv_interval);

use lib $FindBin::Bin . '/../lib';
use MyApp;

my $app = MyApp->new();


$app->MainLoop();

