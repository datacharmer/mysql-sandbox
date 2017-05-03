#
# Test hiding data dictionary
#

my $TEST_VERSION = $ENV{TEST_VERSION};
my $SANDBOX_HOME= $ENV{SANDBOX_HOME} || "$ENV{HOME}/sandboxes";
my ($version, $name_version) = get_bare_version($TEST_VERSION);
my $install_dir = 'msb_dd_test';
my $install_port = 18001;


sub test_run
{
    my ($tests) = @_;
    ok_exec({
        command     =>  "make_sandbox $TEST_VERSION -- "
                       . "--no_confirm --sandbox_directory=$install_dir"
                       . "  --expose_dd_tables "
                       . " --sandbox_port=$install_port ",
        expected    => 'sandbox server started' ,
        msg         => 'sandbox server started',
    });

    for my $test (@$tests)
    {
        ok_sql({
            path      => "$SANDBOX_HOME/$install_dir",
            query     => $test->{query},
            expected  => $test->{expected},
            msg       => $test->{msg},
        });
    }
    ok_exec( {
        command => "sbtool -o delete -s $sandbox_home/$install_dir ",
        expected => 'has been removed',
        msg      => "$install_dir removed"
    });
}

my @tests = (
    {
        query   => "select version() REGEXP 'debug'",
        expected => '1',
        msg  => 'mysqld-debug is running'
    },
    {
        query   => "select \@\@debug is not NULL",
        expected => '1',
        msg  => '@debug variable is set'
    },
    {
        query   => "select count(*) from mysql.tables where name ='tables' and schema_id=1",
        expected => '1',
        msg  => 'table "mysql.tables" is readable'
    },
    {
        query   =>   "select count(*) from mysql.tables "
                   . " where name='dd_hidden_tables' "
                   . " and schema_id = (select id from mysql.schemata where name='sys')",
        expected => '1',
        msg  => 'table "sys.dd_hidden_tables" exists'
    }

);


test_run( \@tests)
