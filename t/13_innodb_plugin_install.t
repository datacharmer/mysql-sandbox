use strict;
use warnings;
use lib './t';
use Test_Helper;
use MySQL::Sandbox;

confirm_version('5.1.6','5.1.99');

find_plugindir('5.1.40', '5.1.73');

test_sandbox( 'test_sandbox --user_test=./t/innodb_plugin_install.sb.pl', 16);
