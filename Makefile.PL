use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'MySQL::Sandbox',
    VERSION_FROM      => 'lib/MySQL/Sandbox.pm', # finds $VERSION
    PREREQ_PM         => {
                            'File::Find' => 1.0,
                            'Socket'     => 1.7,
                         }, 
    EXE_FILES         => [
                            'bin/msb',
                            'bin/msandbox',
                            'bin/sbtool',
                            'bin/test_sandbox',
                            'bin/low_level_make_sandbox',
                            'bin/make_sandbox',
                            'bin/make_sandbox_from_source',
                            'bin/make_sandbox_from_installed',
                            'bin/make_replication_sandbox',
                            'bin/make_multiple_sandbox',
                            'bin/make_multiple_custom_sandbox',
                            'bin/deploy_to_remote_sandboxes.sh',
                         ],
    LICENSE         => 'gpl',
    ($] >= 5.005 ?     
      (
       ABSTRACT_FROM  => 'lib/MySQL/Sandbox.pm',
       AUTHOR         => 'Giuseppe Maxia <gmax@cpan.org>'
      ) : ()),
);
