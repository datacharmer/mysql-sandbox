use strict;
use warnings;
use Test::More ;

BEGIN {
    if ($^O =~ /^(?:mswin|win)/i) {
        diag 'NOT SUPPORTED ON WINDOWS';
        plan skip_all => 'This module is not for Windows';        
    }
    else {
        plan tests => 3;
        use_ok('MySQL::Sandbox') ;
        use_ok('MySQL::Sandbox::Scripts') ;
        use_ok('MySQL::Sandbox::Recipes') ;
    }
}
#BEGIN { use_ok('MySQL::Sandbox') };
#BEGIN { use_ok('MySQL::Sandbox::Scripts') };
#BEGIN { use_ok('MySQL::Sandbox::Recipes') };


