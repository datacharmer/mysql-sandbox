use strict;
use warnings;
use lib './t';
use Test_Helper;
use MySQL::Sandbox;

find_plugindir('5.5.4', '5.5.31');

test_sandbox( 'test_sandbox --user_test=./t/semi_synch_plugin_install.sb.pl', 9);
