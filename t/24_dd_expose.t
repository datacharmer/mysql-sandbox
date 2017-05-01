use strict;
use warnings;
use lib './t';
use Test_Helper;
use MySQL::Sandbox;

confirm_version('8.0.0','8.0.99');
my $basedir="$ENV{SANDBOX_BINARY}/$ENV{TEST_VERSION}";
my $mysqld_debug= "$basedir/bin/mysqld-debug";
unless ( -x $mysqld_debug )
{
    skip_version($ENV{TEST_VERSION}, "no mysqld-debug found in $basedir/bin");
}
test_sandbox( 'test_sandbox --user_test=./t/dd_expose.sb.pl', 6);
