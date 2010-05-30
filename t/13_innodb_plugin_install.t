use strict;
use warnings;
use lib './t';
use Test_Helper;
use MySQL::Sandbox;

find_plugindir('5.1.40', '5.1.48');

test_sandbox( 'test_sandbox --user_test=./t/innodb_plugin_install.sb.pl', 16);
