use strict;
use warnings;
use lib './t';
use Test_Helper;
use MySQL::Sandbox;

confirm_version('5.7.12','8.0.99');
test_sandbox( 'test_sandbox --user_test=./t/mysqlx_plugin.sb.pl', 3);
