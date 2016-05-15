#
# Test exec and SQL during sandbox initialization
#

my $TEST_VERSION = $ENV{TEST_VERSION};
my ($version, $name_version) = get_bare_version($TEST_VERSION);
my $install_dir = 'msb_init_test';
my $install_port = 8001;


sub test_run
{
    my ($plugin, $wanted) = @_;
    ok_exec({
        command     =>  "make_sandbox $TEST_VERSION -- --no_confirm --sandbox_directory=$install_dir "
                       . "--sandbox_port=$install_port "
                       . "--load_plugin='$plugin' ",
        expected    => 'sandbox server started' ,
        msg         => 'sandbox server started',
    });

    for my $w (@{$wanted})
    {
        ok( $ENV{EXEC_RESULT} =~ /$w->{expected}/, "$w->{comment}" );
    }

    ok_exec( {
        command => "sbtool -o delete -s $sandbox_home/$install_dir ",
        expected => 'has been removed',
        msg      => "$install_dir removed"
    });
}

my @tests = (
    {
        plugin => 'mysqlx',
        wanted  => [
            {
                expected => 'mysqlx.*ACTIVE',
                comment  => 'plugin "mysqlx" loaded'
            },
        ]
    },
    );


for my $t (@tests)
{
    test_run( $t->{plugin}, $t->{wanted});
}
