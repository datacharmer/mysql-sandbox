# Test for add_option script
#
my $TEST_VERSION = $ENV{TEST_VERSION};
ok_exec ( { 
        command     => "make_sandbox $TEST_VERSION -- --no_confirm --sandbox_directory=single_server",
        expected    => "sandbox server started",
        msg         => "server 1 started",
        dir_name    => 'single_server installed',
    });

    ok ( -x "$sandbox_home/single_server/add_option", "script add_option is installed");

    ok_exec({
         command    => "$sandbox_home/single_server/add_option key-buffer-size=25M",
         expected   => 'ok',
         msg        => 'key buffer size option installed',
     });
    ok_sql({
         path       => "$sandbox_home/single_server",
         query      => "show variables like 'key_buffer_size'",
         expected   => '26214400',
         msg        => 'got right buffer size (25M)',
     });

    my $is_in_my_cnf = qx( grep 'key.buffer.size=25M' "$sandbox_home/single_server/my.sandbox.cnf");
    ok ($is_in_my_cnf && ($is_in_my_cnf =~ /key.buffer.size/), "option key_buffer_size is in configuration file");

    ok_exec( {
        command => "sbtool -o delete -s $sandbox_home/single_server", 
        expected => 'has been removed',
        msg      => "single_server removed"
        });
