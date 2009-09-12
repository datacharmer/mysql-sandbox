use strict;
use warnings;
use DBI;

my $dbh = DBI->connect(
    'dbi:mysql:;'
    . "mysql_read_default_file=$ENV{HOME}/sandboxes/msb_5_1_35/my.sandbox.cnf",
    undef,
    undef,
    {
        RaiseError => 1, 
        PrintError => 1,
        AutoCommit => 0,
    }
)
    or die "can't connect ($DBI::errstr)\n";
print "Connected successfully\n";

#use Data::Dumper;
#my $result = $dbh->selectall_arrayref(
#        qq{SELECT * FROM INFORMATION_SCHEMA.SCHEMATA}, {Slice => {}} );
#
#print Data::Dumper->Dump( [$result], ['INFORMATION_SCHEMA_ENGINES']);
#$dbh->disconnect();

