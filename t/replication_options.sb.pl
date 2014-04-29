#
# Test replication parameters.
# You can affect the replication installation with some 
# command line options
#  * --master_options only master
#  * --slave_options only slaves
#  * --node_options all nodes, master and slaves
#
my $TEST_VERSION = $ENV{TEST_VERSION};
my ($version, $name_version) = get_bare_version($TEST_VERSION);
my $replication_dir = "rsandbox_$name_version";

$ENV{MASTER_OPTIONS} = '';
$ENV{SLAVE_OPTIONS}  = '';
$ENV{NODE_OPTIONS}   = '';
my $master_options   = '-c key-buffer-size=20M';
my $slave_options    = '-c key-buffer-size=25M';
my $node_options     = '-c max_allowed_packet=3M';

my $command_line_options =   "--master_options='$master_options' "
                           . "--slave_options='$slave_options' "
                           . "--node_options='$node_options' $TEST_VERSION ";

ok_exec({
    command     => "make_replication_sandbox $command_line_options $TEST_VERSION ",
    expected    => 'replication directory installed',
    msg         => 'replication directory installed',
});
sleep 2;
ok_sql({
    path    => "$sandbox_home/$replication_dir/master",
    query   => "show variables like 'key_buffer_size'",
    expected => '20971520',
    msg      => 'master key buffer (20M)',    
});
ok_sql({
    path    => "$sandbox_home/$replication_dir/master",
    query   => "show variables like 'max_allowed_packet'",
    expected => '3145728',
    msg      => 'master max allowed packet (3M)',    
});
ok_sql({
    path    => "$sandbox_home/$replication_dir/node1",
    query   => "show variables like 'max_allowed_packet'",
    expected => '3145728',
    msg      => 'node 1 max allowed packet (3M)',    
});
ok_sql({
    path    => "$sandbox_home/$replication_dir/node2",
    query   => "show variables like 'max_allowed_packet'",
    expected => '3145728',
    msg      => 'node 2 max allowed packet (3M)',    
});

ok_sql({
    path    => "$sandbox_home/$replication_dir/node1",
    query   => "show variables like 'key_buffer_size'",
    expected => '26214400',
    msg      => 'slave 1 key buffer (25M)',    
});
ok_sql({
    path    => "$sandbox_home/$replication_dir/node2",
    query   => "show variables like 'key_buffer_size'",
    expected => '26214400',
    msg      => 'slave 2 key buffer (25M)',    
});
ok_exec( {
    command => "sbtool -o delete -s $sandbox_home/$replication_dir ", 
    expected => 'has been removed',
    msg      => "$replication_dir removed"
});

# Test --master and --slaveof

ok_exec({
    command     => "make_sandbox $TEST_VERSION -- --master --sandbox_directory=msb_master --sandbox_port=8000 --no_confirm",
    expected    => 'sandbox server started',
    msg         => 'sandbox master installed',
});
sleep 2;
ok_exec({
    command     => "make_sandbox $TEST_VERSION -- --no_confirm --sandbox_port=8001 --sandbox_directory=msb_slave --slaveof='master_port=8000' ",
    expected    => 'sandbox server started',
    msg         => 'sandbox master installed',
});
sleep 2;
ok_sql({
    path    => "$sandbox_home/msb_master/",
    query   => "show variables like 'log_bin'",
    expected => 'ON',
    msg      => 'master binlog',    
});
ok_sql({
    path    => "$sandbox_home/msb_master/",
    query   => "show variables like 'server_id'",
    expected => '8000',
    msg      => 'master server ID',    
});

ok_sql({
    path    => "$sandbox_home/msb_slave/",
    query   => "show variables like 'server_id'",
    expected => '8001',
    msg      => 'slave server ID',    
});

ok_sql({
    path    => "$sandbox_home/msb_slave/",
    query   => "show slave status \\G",
    expected => ['Slave_IO_Running: Yes', 'Slave_SQL_Running: Yes'],
    msg      => 'slave server ID',    
});


ok_exec( {
    command => "sbtool -o delete -s $sandbox_home/msb_master ", 
    expected => 'has been removed',
    msg      => "msb_master removed"
});

ok_exec( {
    command => "sbtool -o delete -s $sandbox_home/msb_slave ", 
    expected => 'has been removed',
    msg      => "msb_slave removed"
});

# testing --high_performance
#
ok_exec({
    command     => "make_sandbox $TEST_VERSION -- --high_performance --sandbox_directory=msb_hp --sandbox_port=8000 --no_confirm",
    expected    => 'sandbox server started',
    msg         => 'sandbox hp installed',
});
sleep 2;
ok_sql({
    path    => "$sandbox_home/msb_hp/",
    query   => "show variables like 'innodb%'",
    expected => ['innodb_buffer_pool_size\s*536870912', 'innodb_flush_method\s*O_DIRECT'],
    msg      => 'high performance options',    
});

ok_exec( {
    command => "sbtool -o delete -s $sandbox_home/msb_hp ", 
    expected => 'has been removed',
    msg      => "msb_hp removed"
});

