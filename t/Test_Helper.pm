package Test_Helper;

my $test_version;
BEGIN {
    sub skip_all {
        my ($msg) = @_;
        print "1..1\n",
              "ok - Skipped. $msg\n";
        exit;
    }

    if ($^O =~ /^(?:mswin|win)/i) {
        skip_all ('This module is not for Windows');        
    }
    use MySQL::Sandbox;
    $ENV{TEST_SANDBOX_HOME}="$ENV{PWD}/t/test_sb";
    $ENV{PERL5LIB}="$ENV{PWD}/lib";
    $ENV{PATH}="$ENV{PWD}/bin:$ENV{PATH}";
    $ENV{TEST_VERSION} = $ENV{TEST_VERSION} || '5.6.21';
    $ENV{SANDBOX_AS_ROOT} = 1;
    $test_version = $ENV{TEST_VERSION} ;
};

use strict;
use warnings;
use base qw( Exporter);
our @ISA= qw(Exporter);
our @EXPORT_OK= qw( test_sandbox find_plugindir skip_all);
our @EXPORT = @EXPORT_OK;

sub test_sandbox {
    my ($cmd, $expected_tests, $informative) = @_;
    unless ($cmd) {
        die "command expected\n";
    }
    unless ($expected_tests) {
        die "number of tests expected as second parameter\n";
    }
    $expected_tests =~ /^\d+$/
        or die "the 'expected tests' parameter must be a number \n";

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
        warn  "Testing <$test_version>. "
            . "Please wait. This will take a few minutes\n" if $informative;
        print "1..$expected_tests\n";
    }
    else {
        print "1..1\n";
        print "ok 1 # skip - no binaries found for $test_version\n";
        print " - See the README under 'TESTING' for more options.\n" if $informative;
        exit;
    }

    $ENV{TAP_MODE} =1;
    system ("$cmd --versions=$test_version ");
}

sub find_plugindir {
    my ($minimum_version, $maximum_version) = @_;
    my $plugindir;

    if  ( 
        $ENV{SANDBOX_BINARY} 
        &&
        ( -d $ENV{SANDBOX_BINARY})
        ) 
    {
        #
        # finds the latest 5.x version
        #
        my $highest_version = '';
        my @versions = ();
        my @dirs =  sort { $b cmp $a } 
                    grep { ($_ ge $minimum_version) && ($_ le $maximum_version) }
                    map { m{(\d\.\d\.\d+)/?$}; $1 }
                        grep { /\d+\.\d+\.\d+/ } 
                        grep { -d $_ } 
                            glob("$ENV{SANDBOX_BINARY}/*/" ) ;
        unless (@dirs) {
            skip_all("no directories found under $ENV{SANDBOX_BINARY}");
        }
        $highest_version = $dirs[0];
        if ($highest_version lt $minimum_version)  {
            skip_all("no suitable version found for this test");
        }
        my $TEST_VERSION = $ENV{TEST_VERSION} || $highest_version;
        # print "<@dirs> <$highest_version> <$TEST_VERSION>\n";
        unless ( grep { $TEST_VERSION eq $_ } @dirs ) {
            #skip_all("$TEST_VERSION is not suitable for this test");
            $TEST_VERSION = $highest_version;
        }
        $ENV{TEST_VERSION} = $TEST_VERSION;
        $plugindir = "$ENV{SANDBOX_BINARY}/$TEST_VERSION/lib/plugin";
        unless ( -d $plugindir) {
            $plugindir = "$ENV{SANDBOX_BINARY}/$TEST_VERSION/lib/mysql/plugin";
            unless ( -d $plugindir) {
                skip_all("Plugin directory for $TEST_VERSION not found");
            }
        }
    }
    else {
        skip_all('no $SANDBOX_BINARY found');
    }
    $ENV{'SB_PLUGIN_DIR'} = $plugindir;
}

1;

__END__

