#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

my $sandbox_binary = $ENV{SANDBOX_BINARY} || "$ENV{HOME}/opt/mysql";

unless ( -d $sandbox_binary)
{
    die "# Directory $sandbox_binary not found\n";
}

my @dirs = map { basename $_ } grep {-d $_} glob ("$sandbox_binary/*/") ;

sub dir_split
{
    my ($dir) = @_;
    if ($dir =~ /([^.]+)\.(\d+)\.(\d+)/)
    {
        return ($1, $2, $3);    
    }
    return ;
}

my %test_dirs=();

for my $dir (@dirs)
{
    my ($major, $minor, $rev) = dir_split($dir);    
    next unless $major;
    #next if ($major =~ /^full_/);
    #unless ($major =~ /^[1-9]/)
    unless ($major =~ /^(?:ps|ma)/ or $major =~ /^[1-9]/)
    {
        next;   
    }

    if ($test_dirs{"$major.$minor"})
    {
        if ($test_dirs{"$major.$minor"} > $rev)
        {
            next 
        }
    }
    $test_dirs{"$major.$minor"} = $rev;
    # print "<$major $minor $rev>\n";
}

#print "\n";
for my $dir (sort  keys %test_dirs)
{
    print "$dir.$test_dirs{$dir}\n"
}
