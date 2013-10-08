#!/home/jon/perl5/perlbrew/perls/perl-5.14.2/bin/perl

use v5.14;
use warnings;

#use Wx::Perl::SplashFast( "var/splash.png", 2000 );

use FindBin;
use lib $FindBin::Bin . '/../lib';

use MyApp;
use Wx qw(:allclasses);

my $app = MyApp->new();
$app->MainLoop();

