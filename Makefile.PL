use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MySQL::Sandbox',
    VERSION_FROM      => 'lib/MySQL/Sandbox.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    EXE_FILES         => [
                            'bin/sandbox',
                            'bin/sbtool',
                            'bin/test_sandbox',
                            'bin/low_level_make_sandbox',
                            'bin/make_sandbox',
                            'bin/make_replication_sandbox',
                            'bin/make_multiple_sandbox',
                            'bin/make_multiple_custom_sandbox',
                         ],
    ($] >= 5.005 ?     
      (#ABSTRACT       => 'The MySQL Sandbox - A MySQL server installer',
       ABSTRACT_FROM  => 'lib/MySQL/Sandbox.pm',
       AUTHOR         => 'Giuseppe Maxia <gma@cpan.org>'
      ) : ()),
);
