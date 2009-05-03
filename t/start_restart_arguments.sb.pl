# Test for drill-down start and restart parameters
#
# Creates single and multiple sandboxes, sends a "start_all" call with 
# parameters, and checks that the parameter was received.
#
my $ver = '5.0.77';
my $TEST_VERSION = $ENV{TEST_VERSION} || $ver;
my ($bare_version, $version) = get_bare_version ($ver);
my @test_sb = (
    { 
        command     => "make_sandbox $TEST_VERSION --no_confirm --sandbox_directory=single_server",
        expected    => "sandbox server started",
        msg         => "server 1 started",
        dir_name    => 'single_server',
    },
    {
        command     => "make_multiple_sandbox --group_directory=group_server $TEST_VERSION ",
        expected    => 'group directory installed',
        msg         => 'group directory started',
        dir_name    => 'group_server',
    },
    {
        command     => "make_multiple_custom_sandbox --group_directory=custom_server $TEST_VERSION ",
        expected    => 'group directory installed',
        msg         => 'custom directory started',
        dir_name    => 'custom_server',
    },
    {
        command     => "make_replication_sandbox --replication_directory=replication_server $TEST_VERSION ",
        expected    => 'replication directory installed',
        msg         => 'replication directory started',
        dir_name    => 'replication_server',
    },
    {
        command     => "make_replication_sandbox --circular=3 --replication_directory=replication_server $TEST_VERSION ",
        expected    => 'group directory installed',
        msg         => 'circular directory started',
        dir_name    => 'replication_server',
    },

);
for my $test (@test_sb) {

    ok_exec( $test);
    ok_exec({
         command    => "$sandbox_home/stop_all",
         expected   => 'ok',
         msg        => 'all servers stopped',
     });
    ok_exec({
         command    => "$sandbox_home/start_all --key-buffer=20M",
         expected   => 'ok',
         msg        => 'all servers started',
     });
    ok_exec({
         command    => qq($sandbox_home/use_all "show variables like 'key_buffer_size'"),
         expected   => '20971520',
         msg        => 'got right buffer size (20M)',
     });

    ok_exec({
         command    => "$sandbox_home/restart_all --key-buffer=25M",
         expected   => 'ok',
         msg        => 'all servers restarted',
     });

    ok_exec({
         command    => qq($sandbox_home/use_all "show variables like 'key_buffer_size'"),
         expected   => '26214400',
         msg        => 'got right buffer size (25M)',
     });
    ok_exec( {
        command => "sbtool -o delete -s $sandbox_home/$test->{dir_name} ", 
        expected => 'has been removed',
        msg      => "$test->{dir_name} removed"
        });
}
