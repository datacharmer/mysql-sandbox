#
# test for installation with --force option
#
my $TEST_VERSION = $ENV{TEST_VERSION};
my ($bare_version, $version) = get_bare_version ($TEST_VERSION);
my $SANDBOX_HOME= $ENV{SANDBOX_HOME} || "$ENV{HOME}/sandboxes";

my $custom_port = 9000;

ok_exec({
command     => "make_sandbox $TEST_VERSION -- --sandbox_port=$custom_port --no_confirm",
expected    => 'sandbox server started',
msg         => 'server 1 started',
});

ok_sql({
path        => "$SANDBOX_HOME/msb_${version}/",
query       => "create schema db1; show schemas",
expected    => 'db1',
msg         => 'db1 schema was created',
});

ok_exec({
command     => "make_sandbox $TEST_VERSION -- --sandbox_port=$custom_port --no_confirm 2>&1 || echo 1",
expected    => [ 'already exists', 'not specified', 'Installation halted' ],
msg         => 'Server installation denied without --force',
});

ok_exec({
command     => "make_sandbox $TEST_VERSION -- --sandbox_port=$custom_port --no_confirm --force",
expected    => 'sandbox server started',
msg         => 'Same sandbox installation with --force is accepted',
});

ok_sql({
path        => "$SANDBOX_HOME/msb_${version}/",
query       => "show variables like 'port'",
expected    => "$custom_port",
msg         => 'right port on server 1',
});

ok( -d "$SANDBOX_HOME/msb_$version/old_data", "old_data was created."); 
ok( -d "$SANDBOX_HOME/msb_$version/old_data/db1", "db1 schema was preserved in the old datadir."); 
ok( ! -d "$SANDBOX_HOME/msb_$version/data/db1", "db1 schema is not in the new datadir."); 

ok_exec ({
command     => "sbtool -o delete -s $SANDBOX_HOME/msb_${version}/",
expected    => 'has been removed',
msg         => 'server 1 stopped and removed',
});

