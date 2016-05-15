#
# Test exec and SQL during sandbox initialization
#

my $TEST_VERSION = $ENV{TEST_VERSION};
my ($version, $name_version) = get_bare_version($TEST_VERSION);
my $install_dir = 'msb_init_test';
my $install_port = 8001;


sub test_run
{
    my ($stage, $command, $wanted) = @_;
    ok_exec({
        command     =>  "make_sandbox $TEST_VERSION -- --no_confirm --sandbox_directory=$install_dir "
                       . "--sandbox_port=$install_port "
                       . "--$stage='$command' ",
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
        stage   => 'pre_start_exec',
        command => 'echo "<$EXEC_STAGE>"; ls -d $DB_DATADIR/*/',
        wanted  => [
            {
                expected => '<pre_start_exec>',
                comment  => 'Stage pre_start_exec detected'
            },
            {
                expected => '/mysql/',
                comment  => 'directory /mysql/ found'
            }
        ]
    },
    {
        stage   => 'pre_grants_exec',
        command => 'echo "<$EXEC_STAGE>"; ls $DB_SOCKET; echo "<$DB_PORT>"' ,
        wanted  => [
            {
                expected => '<pre_grants_exec>',
                comment  => 'Stage pre_grants_exec detected'
            },
            {
                expected => "mysql.*$install_port.sock",
                comment  => 'socket file found'
            },
            {
                expected => "<$install_port>",
                comment  => "Port $install_port detected"
            }
        ]
    },
    {
        stage   => 'post_grants_exec',
        command => 'echo "<$EXEC_STAGE>";ls -l $DB_DATADIR/test',
        wanted  => [
            {
                expected => '<post_grants_exec>',
                comment  => 'Stage post_grants_exec detected'
            },
            {
                expected => "/test",
                comment  => 'test directory found'
            }
        ]
    },
    {
        stage   => 'pre_grants_sql',
        command => 'select concat("<",count(*),">") from mysql.user where user like "_sandbox"',
        wanted  => [
            {
                expected => '<0>',
                comment  => 'pre_grants_sql: no users named "?sandbox" found'
            },
        ]
    },
    {
        stage   => 'post_grants_sql',
        command => 'select concat("<",count(*),">") from mysql.user where user like "_sandbox"',
        wanted  => [
            {
                expected => '<3>',
                comment  => 'pre_grants_sql: 3 users named "?sandbox" found'
            },
        ]
    }
);


for my $t (@tests)
{
    test_run( $t->{stage}, $t->{command}, $t->{wanted});
}
