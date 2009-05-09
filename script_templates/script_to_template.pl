#!/usr/bin/perl
die "don't want to run this one and overwrite the existing templates\n";
use strict;
use warnings;
use MySQL::Sandbox;
use MySQL::Sandbox::Scripts;
use Data::Dumper;

my $scripts = scripts_in_code();
print Dumper $scripts;

for my $script (keys %{$scripts}) {
    my $fname = "./process/$script";
    open my $FH, '>', $fname
        or die "can't create $fname ($!)\n";
    print $FH $scripts->{$script}, "\n";
    close $FH;
}

