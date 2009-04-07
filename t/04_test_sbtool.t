BEGIN {
    $ENV{TEST_SANDBOX_HOME}="$ENV{PWD}/t/test_sb";
    $ENV{PERL5LIB}="$ENV{PWD}/lib";
    $ENV{PATH}="$ENV{PWD}/bin:$ENV{PATH}";
};

use strict;
use warnings;
my $test_version = $ENV{TEST_VERSION} || '5.0.77';

##
# accepts either a bare version 
#   (e.g. 5.0.79)
# or a tarball 
#   (e.g. $HOME/downloads/mysql-5.0.79-osx10.5-x86.tar.gz)
# or the path to a directory containing binaries
#   (e.g. $HOME/opt/mysql/5.0.79)

if (   ( -d $test_version) 
    or (( -f $test_version ) && ($test_version =~ /\.tar\.gz$/) )
    or ( -d "$ENV{HOME}/opt/mysql/$test_version")) {
    warn "Testing <$test_version>. Please wait. This will take a few minutes\n";
    print "1..34\n";
}
else {
    print "1..1\n";
    print "ok 1 # skip - no binaries found for $test_version"
           . " - See the README under 'TESTING' for more options.\n";
    exit;
}

$ENV{TAP_MODE} =1;
system("test_sandbox --versions=$test_version --tests=sbtool");

