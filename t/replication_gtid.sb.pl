#
# Test GTID enabling
# Requires MySQL 5.6 - 5.7+
#
my $TEST_VERSION = $ENV{TEST_VERSION};
my ($version, $name_version) = get_bare_version($TEST_VERSION);
my $replication_dir = "rsandbox_$name_version";

my $GTID_OPTION= ' --gtid';
if ( $ENV{'GTID_FROM_FILE'})
{
    $GTID_OPTION='';
}

ok_exec({
    command     => "make_replication_sandbox $GTID_OPTION $TEST_VERSION",
    expected    => 'replication directory installed',
    msg         => 'replication directory installed',
});

if ( $ENV{'GTID_FROM_FILE'})
{
    ok( (-f "$sandbox_home/$replication_dir/enable_gtid" ), "file enable_gtid found ");

    my $result = qx( $sandbox_home/$replication_dir/enable_gtid );

    ok( $? == 0 , 'enable_gtid ran without errors');

    ok( $result && ($result =~ /# option 'gtid_mode=ON' added to \w+ configuration file/), "enable_gtid added options successfully");
}

ok_sql({
    path    => "$sandbox_home/$replication_dir/master",
    query   => 'select @@global.gtid_mode',
    expected => 'ON',
    msg      => 'Master GTID is enabled',    
});

# When GTID is enabled, the slaves take some time to get the synchronization info.
sleep 3;

ok_sql({
    path    => "$sandbox_home/$replication_dir/master",
    query   => 'select @@global.server_uuid',
    expected => '1111-111111111111',
    msg      => 'Master UUID was modified',    
});

ok_sql({
    path    => "$sandbox_home/$replication_dir/node1",
    query   => 'select @@global.server_uuid',
    expected => '2222-222222222222',
    msg      => 'slave 1 UUID was modified',    
});

ok_sql({
    path    => "$sandbox_home/$replication_dir/node2",
    query   => 'select @@global.server_uuid',
    expected => '3333-333333333333',
    msg      => 'slave 2 UUID was modified',    
});

ok_sql({
    path    => "$sandbox_home/$replication_dir/node1",
    query   => 'select @@global.gtid_mode',
    expected => 'ON',
    msg      => 'Slave1 GTID is enabled',    
});

ok_sql({
    path    => "$sandbox_home/$replication_dir/master",
    query   => "create table test.t1 (id int not null primary key); show tables from test",
    expected => 't1',
    msg      => 'Master created a table',    
});

ok_sql({
    path    => "$sandbox_home/$replication_dir/master",
    query   => "insert into test.t1 values(12345); select * from test.t1",
    expected => '12345',
    msg      => 'Master inserted a row',    
});

sleep 2;

ok_sql({
    path    => "$sandbox_home/$replication_dir/node1",
    query   => "show tables from test",
    expected => 't1',
    msg      => 'slave replicated the table',    
});

ok_sql({
    path    => "$sandbox_home/$replication_dir/node1",
    query   => "select * from test.t1",
    expected => '12345',
    msg      => 'Slave retrieved a row',    
});

ok_sql({
    path    => "$sandbox_home/$replication_dir/master",
    query   => 'select @@global.gtid_executed',
    expected => '1111-111111111111:1-',
    msg      => 'Master has produced a GTID',    
});

#my $executed_set = `$sandbox_home/$replication_dir/m -BN -e 'select \@\@global.gtid_executed'`;
#chomp $executed_set;
my $executed_set = $ENV{SQL_RESULT};

ok_sql({
    path    => "$sandbox_home/$replication_dir/node1",
    query   => 'select @@global.gtid_executed',
    expected => $executed_set,
    msg      => 'Slave has retrieved a GTID',    
});

ok_exec( {
    command => "sbtool -o delete -s $sandbox_home/$replication_dir ", 
    expected => 'has been removed',
    msg      => "$replication_dir removed"
});

