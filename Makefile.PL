use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile1(
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
                            'bin/make_sandbox_from_url',
                            'bin/make_replication_sandbox',
                            'bin/make_multiple_sandbox',
                            'bin/make_multiple_custom_sandbox',
                            'bin/deploy_to_remote_sandboxes.sh',
                         ],
    LICENSE         => 'apache',
    ABSTRACT_FROM => 'lib/MySQL/Sandbox.pm',
    AUTHOR => 'Giuseppe Maxia <gmax@cpan.org>',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/datacharmer/mysql-sandbox.git',
                web => 'https://github.com/datacharmer/mysql-sandbox',
            },
        },
    },
    #TEST_REQUIRES => {
    #},
);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}

