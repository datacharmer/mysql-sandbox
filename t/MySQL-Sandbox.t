use strict;
use warnings;
use Test::More tests => 2;
BEGIN { use_ok('MySQL::Sandbox') };
BEGIN { use_ok('MySQL::Sandbox::Scripts') };

END{
warn "\n" .
     "******************************************************************\n" .
     "** To test the package properly, you should run test_sandbox    **\n" .
     "** Use test_sandbox --help for more information                 **\n" .
     "******************************************************************\n" .
     "** To run test_sandbox without installing it, use               **\n" .
     "** PERL5LIB=\$PWD/lib PATH=\$PWD/bin:\$PATH test_sandbox [options] **\n" .
     "******************************************************************\n\n" ;
};


