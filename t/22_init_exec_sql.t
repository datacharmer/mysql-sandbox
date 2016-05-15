use strict;
use warnings;
use lib './t';
use Test_Helper;
use MySQL::Sandbox;

#confirm_version('5.6.6','5.7.99');
test_sandbox( 'test_sandbox --user_test=./t/init_exec_sql.sb.pl', 19);
