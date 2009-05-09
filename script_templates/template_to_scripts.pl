#!/usr/bin/perl
use strict;
use warnings;

my $module = shift
    or die "need the file name for Scripts.pm \n";

open my $FHM, '<', $module
    or die "can't open $module ($!)\n";
my $pre_scripts = '';
my $post_scripts = '';
my $scripts_found = 0;
my $before_scripts = 1;
my $in_scripts = 0;
my $after_scripts =0;

while (my $line = <$FHM> ) {
    if ($after_scripts) {
        $post_scripts .= $line;
    }    
    elsif ($line =~ /# --- START SCRIPTS IN CODE ---/ ) {
        $before_scripts =0;
        $in_scripts =1; 
        $scripts_found =1;
        $pre_scripts .= $line;
    }
    elsif ($before_scripts) {
        $pre_scripts .= $line;
    }
    elsif ( $in_scripts && ($line =~ /# --- END SCRIPTS IN CODE ---/ )) {
        $in_scripts = 0;
        $after_scripts =1;
        $post_scripts .= $line;
    }
    elsif ($in_scripts) {
        #
    }
    else {
        die "unhandled line ($.)\n";
    }
}
close $FHM;
unless ($scripts_found) {
    die "could not find scripts in code within $module\n";
}

my @files = grep { /(?<!~)$/ } glob('./process/*');

my $scripts_text = '';

print $pre_scripts, 
    "my \%scripts_in_code = (\n";

for my $fname (@files) {
    my $name = $fname;
    $name =~ s{.*/}{};
    my $tag = clean_name($name);
    print "\n";
    print "'$name' => <<'$tag',\n";
    open my $FH, '<', $fname
        or die "can't open $fname ($!) \n";
    while (my $line = <$FH>) {
        print $line;
    }
    close $FH;
    print "\n$tag\n";
}
print ");\n",
    $post_scripts;

sub clean_name {
    my ($name) = @_;
    $name =~ s/\./_/g;
    return uc $name;
}

