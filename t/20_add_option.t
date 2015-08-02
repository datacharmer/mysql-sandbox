use strict;
use warnings;
use lib './t';
use Test_Helper;
use MySQL::Sandbox;

test_sandbox( 'test_sandbox --user_test=./t/add_option.sb.pl', 6);
