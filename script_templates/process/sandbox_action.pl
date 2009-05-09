#!/usr/bin/perl
__LICENSE__
use strict;
use warnings;
use MySQL::Sandbox;

my $DEBUG = $MySQL::Sandbox::DEBUG;

my $action_list = 'use|start|stop|clear|restart|send_kill';
my $action = shift
    or die "action required {$action_list}\n";
$action =~/^($action_list)$/ 
    or die "action must be one of {$action_list}\n";
my $sandboxdir = $0;
$sandboxdir =~ s{[^/]+$}{};
$sandboxdir =~ s{/$}{};
my $command = $ARGV[0];
if ($action eq 'use' and !$command) {
    die "action 'use' requires a command\n";
}

my @dirs = glob("$sandboxdir/*");

for my $dir (@dirs) {
    if (-d $dir) {
        if ($action eq "use") {
            if ( -x "$dir/use_all" ) {
                print "executing -- $dir/use_all $command\n" if $DEBUG;
                system(qq($dir/use_all "$command"));
            }           
            elsif ( -x "$dir/use" ) {
                print "executing -- $dir/use $command\n" if $DEBUG;
                system(qq(echo "$command" | $dir/use));
            }           
        } 
        elsif ( -x "$dir/${action}_all") {
            print "-- executing  $dir/${action}_all\n" if $DEBUG;
            system("$dir/${action}_all", @ARGV)
        }
        elsif ( -x "$dir/$action") {
            print "-- executing  $dir/$action\n" if $DEBUG;
            system("$dir/$action", @ARGV)
        }
    }
}


