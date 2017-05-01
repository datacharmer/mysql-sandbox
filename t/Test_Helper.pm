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
    my $opt_mysql= $ENV{SANDBOX_BINARY} || "$ENV{HOME}/opt/mysql";
    unless  ( -d  -d $opt_mysql)
    {
        skip_all ("This test module requires tarballs extracted in $ENV{HOME}/opt/bin");
    }
    use MySQL::Sandbox qw/split_version/;
    $ENV{TEST_SANDBOX_HOME}="$ENV{PWD}/t/test_sb";
    $ENV{PERL5LIB}="$ENV{PWD}/lib";
    $ENV{PATH}="$ENV{PWD}/bin:$ENV{PATH}";
    $ENV{TEST_VERSION} = $ENV{TEST_VERSION} || '5.6.29';
    $ENV{SANDBOX_AS_ROOT} = 1;
    for my $env_var (qw(NODE_OPTIONS MASTER_OPTIONS SLAVE_OPTIONS))
    {
        if ($ENV{$env_var})
        {
            $ENV{$env_var} = undef;
        }
    }
    $test_version = $ENV{TEST_VERSION} ;
};

use strict;
use warnings;
use base qw( Exporter);
our @ISA= qw(Exporter);
our @EXPORT_OK= qw( test_sandbox find_plugindir skip_all confirm_version skip_version);
our @EXPORT = @EXPORT_OK;

#sub get_version_parts
#{
#    my ($version) = @_;
#    if ($version =~ /(\d+)\.(\d+)\.(\d+)/)
#    {
#        my ($major, $minor, $rev) = ($1, $2, $3) ;
#        return ($major, $minor, $rev);
#    }    
#    else
#    {
#        die "# version $version does not have expected components"
#    }
#}

sub skip_version 
{
    my ($version, $reason) = @_;
    warn "# skipping version $version for this test. $reason\n";
    print "1..1\n";
    print "ok 1 # $reason\n";
    exit
}

sub confirm_version
{
    my ($min_version, $max_version) = @_;
    my $will_skip =0;
    my ($major, $minor, $rev) = split_version($test_version);
    my ($major1, $minor1, $rev1) = split_version($min_version);
    my ($major2, $minor2, $rev2) = split_version($max_version);
    my $compare_test = sprintf("%05d-%05d-%05d", $major,  $minor,  $rev);
    my $compare_min  = sprintf("%05d-%05d-%05d", $major1, $minor1, $rev1);
    my $compare_max  = sprintf("%05d-%05d-%05d", $major2, $minor2, $rev2);
    unless (($compare_test ge $compare_min) && ($compare_test le $compare_max))
    {
        skip_version( $test_version, "It is not in the required range ($min_version - $max_version)");
    }
}

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
    my ($minimum_version, $maximum_version, $use_current) = @_;
    my $minimum_version_str;
    my $maximum_version_str;
    if ($minimum_version =~ /(\d+)\.(\d+)\.(\d+)/)
    {
        $minimum_version_str = sprintf('%02d-%02d-%02d', $1, $2, $3);
    }
    else
    {
        die "# Invalid minimum version provided : $minimum_version\n";
    }
    if ($maximum_version =~ /(\d+)\.(\d+)\.(\d+)/)
    {
        $maximum_version_str = sprintf('%02d-%02d-%02d', $1, $2, $3);
    }
    else
    {
        die "# Invalid maximum version provided : $maximum_version\n";
    }
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
                    grep { ($_ ge $minimum_version_str) && ($_ le $maximum_version_str) }
                    map { m{(\d)\.(\d)\.(\d+)/?$}; sprintf('%02d-%02d-%02d',$1,$2,$3) }
                        grep { /\d+\.\d+\.\d+/ } 
                        grep { -d $_ } 
                            glob("$ENV{SANDBOX_BINARY}/*/" ) ;
        unless (@dirs) {
            skip_all("no directories found under $ENV{SANDBOX_BINARY}");
        }
        $highest_version = $dirs[0];
        if ($highest_version lt $minimum_version_str)  {
            skip_all("no suitable version found for this test");
        }
        my $TEST_VERSION = $ENV{TEST_VERSION} || $highest_version;
        # print "<@dirs> <$highest_version> <$TEST_VERSION>\n";
        unless ( grep { $TEST_VERSION eq $_ } @dirs ) {
            #skip_all("$TEST_VERSION is not suitable for this test");
            $TEST_VERSION = $highest_version unless $use_current;
        }
        warn "# Testing plugin with <$TEST_VERSION>\n";
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

