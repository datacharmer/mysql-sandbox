warn "\n*************************************************************\n";
warn "to test the package properly, you should run test_sandbox\n";
warn "*************************************************************\n\n";

use Test::More tests => 2;
BEGIN { use_ok('MySQL::Sandbox') };
BEGIN { use_ok('MySQL::Sandbox::Scripts') };

