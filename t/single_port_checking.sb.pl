#
# test for replication and group sandbox port checking
#
my $TEST_VERSION = $ENV{TEST_VERSION};
my ($bare_version, $version) = get_bare_version ($TEST_VERSION);
my $SANDBOX_HOME= $ENV{SANDBOX_HOME} || "$ENV{HOME}/sandboxes";
my $custom_port  = 11000;
my $custom_port1 = $custom_port + 1;

ok_exec({
command     => "make_sandbox $TEST_VERSION -- --sandbox_port=$custom_port --no_confirm --master",
expected    => 'sandbox server started',
msg         => 'server 1 started',
});

ok_exec({
command     => "make_sandbox $TEST_VERSION -- --sandbox_port=$custom_port --check_port --no_confirm --master",
expected    => 'sandbox server started',
msg         => 'server 2 started',
});

ok_sql({
path        => "$SANDBOX_HOME/msb_${version}/",
query       => "show variables like 'port'",
expected    => $custom_port,
msg         => 'right port on server 1',
});

ok_sql({
path        => "$SANDBOX_HOME/msb_${version}/",
query       => "show variables like 'server_id'",
expected    => $custom_port,
msg         => 'right server_id on server 1',
});

ok_sql({
path        => "$SANDBOX_HOME/msb_${version}_a",
query       => "show variables like 'port'",
expected    => "$custom_port1",
msg         => 'right port on server 2',
});

ok_sql({
path        => "$SANDBOX_HOME/msb_${version}_a",
query       => "show variables like 'server_id'",
expected    => "$custom_port1",
msg         => 'right server_id on server 2',
});

ok_exec ({
command     => "sbtool -o delete -s $SANDBOX_HOME/msb_${version}/",
expected    => 'has been removed',
msg         => 'server 1 stopped and removed',
});

ok_exec({
command     => "sbtool -o delete -s $SANDBOX_HOME/msb_${version}_a",
expected    => "has been removed",
msg         => "server 2 stopped and removed",
});
