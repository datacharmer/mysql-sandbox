use lib './t';
use Test_Helper;
if ( $ENV{TEST_VERSION} =~ /5.7.[678]/)
{
    print "1..1\n";
    print "ok - test user_privileges.sb.pl is broken in MySQL 5.7.6\n";
}
else
{
    test_sandbox( 'test_sandbox --user_test=./t/user_privileges.sb', 50, 0);
}
