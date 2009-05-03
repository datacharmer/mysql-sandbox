#
# Test replication parameters.
# You can affect the replication installation with some 
# environment variables
#  * MASTER_OPTIONS only master
#  * SLAVE_OPTIONS only slaves
#  * NODE_OPTIONS all nodes, master and slaves
#
# Options passed through these variables follow the
# same rule used for make_sandbox and low_level_make_sandbox
# "-c option=value" 
#
my $TEST_VERSION = $ENV{TEST_VERSION} || '5.0.77';
my ($version, $name_version) = get_bare_version($TEST_VERSION);
my $replication_dir = "rsandbox_$name_version";
$ENV{MASTER_OPTIONS} = '-c key-buffer=20M';
$ENV{SLAVE_OPTIONS}  = '-c key-buffer=25M';
$ENV{NODE_OPTIONS}   = '-c max_allowed_packet=3M';

ok_exec({
    command     => "make_replication_sandbox $TEST_VERSION ",
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

