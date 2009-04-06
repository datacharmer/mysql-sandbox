BEGIN {
    $ENV{TEST_SANDBOX_HOME}="$ENV{PWD}/t/test_sb";
    $ENV{PERL5LIB}="$ENV{PWD}/lib";
    $ENV{PATH}="$ENV{PWD}/bin:$ENV{PATH}";
};

use Test::More ;
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
    plan tests => 7;
}
else {

    plan skip_all => "no binaries found for $test_version "
         ."- See the README under 'TESTING' for more options.\n";
}

ok_shell("test_sandbox --versions=$test_version > "
        . " $ENV{PWD}/test_result.log 2>&1 ",'test_sandbox');

ok( -d $ENV{'TEST_SANDBOX_HOME'}, 'sandbox home created' ) or die;
ok_shell( "$ENV{'TEST_SANDBOX_HOME'}/stop_all", 'sandboxes stopped' ) or die;
ok_shell( "$ENV{'TEST_SANDBOX_HOME'}/clear_all", 'sandboxes cleared' ) or die;
ok_shell( "rm -rf $ENV{'TEST_SANDBOX_HOME'}", 'sandboxes removed' );

ok_shell("test_sandbox --versions=$test_version --tests=sbtool > "
        . " $ENV{PWD}/test_sbtool_result.log 2>&1 ",'test sbtool');

ok_shell("test_sandbox --versions=$test_version --tests=smoke > "
        . " $ENV{PWD}/test_smoke_result.log 2>&1 ",'test sbtool');

sub ok_shell {
    my ($command , $description) = @_;
    my $result = system($command);
    # warn "\n<$?><$result>\n";
    return ok(($? >=0) , $description);
}

__END__

warn "\n" .
     "******************************************************************\n" .
     "** To test the package properly, you should run test_sandbox    **\n" .
     "** Use test_sandbox --help for more information                 **\n" .
     "******************************************************************\n" .
     "** To run test_sandbox without installing it, use               **\n" .
     "** PERL5LIB=\$PWD/lib PATH=\$PWD/bin:\$PATH test_sandbox [options] **\n" .
     "******************************************************************\n" .
     "** You can set the version or tarball to test, by setting       **\n" .
     "** the TEST VERSION environment variable before 'make test'     **\n" .
     "******************************************************************\n" ;

