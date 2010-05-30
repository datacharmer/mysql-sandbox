# Test for semi-synch plugin installation
#
#
my $TEST_VERSION = $ENV{TEST_VERSION};
my ($bare_version, $version) = get_bare_version ($TEST_VERSION);

my $plugindir = $ENV{SB_PLUGIN_DIR} 
    or die "expected environment variable \$SB_PLUGIN_DIR not set\n";

# print "<$TEST_VERSION>";exit;

my @test_sb = (
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
                       . " --plugin=semisynch"
                       . " -s $sandbox_home/group_server ",
        expected    => ['@@rpl_semi_sync_master_enabled',  
                        '@@rpl_semi_sync_slave_enabled'],
        msg         => 'semisynch plugin installed on group_server',
    },
    {
        type        => 'sql',
        path        => "$sandbox_home/group_server/master",
        query       => "create table test.t1 (i int);"
                        . "show tables from test",
        expected    => 't1',
        msg         => 'table created on master'
    },
    {
        type        => 'sql',
        path        => "$sandbox_home/group_server/master",
        query       => "select variable_value "
                        . "from information_schema . global_status "
                        . "where variable_name = 'Rpl_semi_sync_master_yes_tx'",
        expected    => 1,
        msg         => 'semi-synch plugin working on group_server/master - 1',
    },
    {
        type        => 'sql',
        path        => "$sandbox_home/group_server/master",
        query       => "select variable_value "
                        . "from information_schema . global_status "
                        . "where variable_name = 'Rpl_semi_sync_master_no_tx'",
        expected    => 0,
        msg         => 'semi-synch plugin working on group_server/master - 2',
    },
    {   type => 'sleep', how_much => 2},
    {
        type        => 'sql',
        path        => "$sandbox_home/group_server/node1",
        query       => " show tables from test ",
        expected    => 't1',
        msg         => 'replication working on group_server/node1',
    },
    {
        type        => 'sql',
        path        => "$sandbox_home/group_server/node2",
        query       => " show tables from test ",
        expected    => 't1',
        msg         => ' replication working on group_server/node2',
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
