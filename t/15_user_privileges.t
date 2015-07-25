use lib './t';
use Test_Helper;

warn "# Using version <$ENV{TEST_VERSION}>\n" if $ENV{SBDEBUG};
test_sandbox( 'test_sandbox --user_test=./t/user_privileges.sb.pl', 50, 0);

