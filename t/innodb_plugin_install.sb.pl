# Test for Innodb plugin installation
#
#
my $TEST_VERSION = $ENV{TEST_VERSION};
my ($bare_version, $version) = get_bare_version ($TEST_VERSION);

my $plugindir = $ENV{SB_PLUGIN_DIR} 
    or die "expected environment variable \$SB_PLUGIN_DIR not set\n";

my %plugin_version = (
    '5.1.40' => '1.0.4',
    '5.1.41' => '1.0.5',
    '5.1.42' => '1.0.6',
    '5.1.43' => '1.0.6',
    '5.1.44' => '1.0.6',
    '5.1.45' => '1.0.6',
    '5.1.45' => '1.0.6',
    '5.1.46' => '1.0.7',
    '5.1.47' => '1.0.8',
    '5.1.48' => '1.0.9',
    '5.1.57' => '1.0.16',
    '5.1.63' => '1.0.17',
);

my @test_sb = (
    { 
        type        => 'exec',
        command     => "make_sandbox $TEST_VERSION -- --no_confirm "
                        . "--sandbox_directory=single_server",
        expected    => "sandbox server started",
        msg         => "single server started",
    },
    {
        type        => 'exec',
        command     => "make_replication_sandbox "
                       . "--replication_directory=group_server $TEST_VERSION ",
        expected    => 'replication directory installed',
        msg         => 'group directory started',
    },
    {
        type        => 'exec',
        command     => "sbtool -o plugin "
                       . " --plugin=innodb"
                       . " -s $sandbox_home/single_server ",
        expected    => ['innodb_version',  $plugin_version{$TEST_VERSION}],
        msg         => 'innodb plugin installed on single_server',
    },
    {
        type        => 'sql',
        path        => "$sandbox_home/single_server",
        query       => "create table test.t1 (i int) engine=innodb "
                       . "ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;"
                       . " show create table test.t1 ",
        expected    => ['innodb', 'compressed'],
        msg         => 'innodb plugin working on single_server',
    },
    {
        type        => 'exec',
        command     => "sbtool -o plugin "
                       . " --plugin=innodb"
                       . " -s $sandbox_home/group_server ",
        expected    => ['innodb_version', $plugin_version{$TEST_VERSION} ],
        msg         => 'innodb plugin installed on group_server',
    },
    {
        type        => 'sql',
        path        => "$sandbox_home/group_server/master",
        query       => "create table test.t1 (i int) engine=innodb "
                       . "ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;"
                       . " show create table test.t1 ",
        expected    => ['innodb', 'compressed'],
        msg         => 'innodb plugin working on group_server/master',
    },
    {   type => 'sleep', how_much => 2},
    {
        type        => 'sql',
        path        => "$sandbox_home/group_server/node1",
        query       => " show create table test.t1 ",
        expected    => ['innodb', 'compressed'],
        msg         => 'innodb plugin working on group_server/node1',
    },
    {
        type        => 'sql',
        path        => "$sandbox_home/group_server/node2",
        query       => " show create table test.t1 ",
        expected    => ['innodb', 'compressed'],
        msg         => 'innodb plugin working on group_server/node2',
    },
    { 
        type        => 'exec',
        command     => "$sandbox_home/single_server/stop",
        expected    => "ok",
        msg         => "single server stopped",
    },
    { 
        type        => 'exec',
        command     => "$sandbox_home/group_server/stop_all",
        expected    => "ok",
        msg         => "group server stopped",
    },
  
);

for my $test (@test_sb) {

    if ($test->{type} eq 'exec') {
        ok_exec( $test);
    }
    elsif ($test->{type} eq 'sql') {
        ok_sql($test);
    }
    elsif ($test->{type} eq 'sleep') {
        sleep($test->{how_much} || 1 );
    }
    else {
        die "unrecognized type\n";
    }
}
