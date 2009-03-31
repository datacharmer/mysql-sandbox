
BEGIN {
    $ENV{PERL5LIB}="$ENV{PWD}/lib";
    $ENV{PATH}="$ENV{PWD}/bin:$ENV{PATH}";
};
use strict;
use warnings;
use Test::More tests => 28;

# 7 tests
ok_shell_result( "sandbox",
            ['available',
            'low_level_make_sandbox', 
            'make_sandbox',
            'make_replication_sandbox',
            'make_multiple_sandbox',
            'make_multiple_custom_sandbox'],
            "sandbox");

# 3 tests
ok_shell_result( "low_level_make_sandbox --help", 
            ['low_level_make_sandbox',
            '-d --sandbox_directory = name'], 
            "low_level_make_sandbox");

# 3 tests
ok_shell_result( "make_sandbox --help", 
            ['make_sandbox', 
            'version'
            ], 
            "make_sandbox");

# 3 tests
ok_shell_result( "make_replication_sandbox --help", 
            ['make_replication_sandbox', 
            '--sandbox_base_port = number'],
            "make_replication_sandbox");

# 3 tests
ok_shell_result( "make_multiple_sandbox --help", 
            ['make_multiple_sandbox',
            '--sandbox_base_port = number'], 
            "make_multiple_sandbox");

# 3 tests
ok_shell_result( "make_multiple_custom_sandbox --help", 
            ['make_multiple_custom_sandbox',
            '--sandbox_base_port = number'],
            "make_multiple_custom_sandbox");

# 3 tests
ok_shell_result( "sbtool --help", 
            ['sbtool',
            '--operation'],
            "sbtool");

# 3 tests
ok_shell_result( "test_sandbox  --help",
            ['test_sandbox',
            '--tarball=/path/to/tarball'],
            "test_sandbox");

sub ok_shell {
    my ($command , $description) = @_;
    my $result = system($command);
    # warn "\n<$?><$result>\n";
    return ok($? >=0 , $description);
}

sub ok_shell_result {
    my ($command, $search_items, $description) = @_;
    my $result = qx($command); 
    ok($? >=0 , $description);
    for my $item (@{ $search_items}) {
        ok( $result =~ /$item/ , "$description - $item" );
    }
}
