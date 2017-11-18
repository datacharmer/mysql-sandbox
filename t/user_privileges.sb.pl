###########################################
# checking default user privileges
###########################################
#

my $TEST_VERSION = $ENV{TEST_VERSION};
my ($bare_version, $version, $major, $minor, $rev) = get_bare_version ($TEST_VERSION);
my $SANDBOX_HOME= $ENV{SANDBOX_HOME} || "$ENV{HOME}/sandboxes";
my $password_field='password';
my $number_of_users = 8;

if ( (($major ==5) &&  ($minor > 7) )
        or 
    ( ($major ==5) && ($minor == 7) && ($rev > 5) ) 
        or 
    ( ($major ==8) && ($minor == 0) ) 
   )
# Starting with MySQL 5.7.6, the 'password' column in the user table is gone
# There is , instead, a column named 'authentication_string'
{
    $password_field='authentication_string';
}

if ( (($major ==5) &&  ($minor > 7) )
        or 
    ( ($major ==5) && ($minor == 7) && ($rev > 8) ) 
        or 
    ( ($major ==8) && ($minor == 0) ) 
   )
# Starting with MySQL 5.7.9 we have the mysql.sys user created by default.
{
   $number_of_users = 9;
}

if (
    ( ($major ==5) && ($minor == 7) && ($rev >= 19))
     or
    ( ($major ==8) && ($minor == 0) && ($rev >= 3))
   )
# Starting with MySQL 5.7.19 we have the mysql.session user created by default.
{
   $number_of_users = 10;
}

# Starting with MySQL 8.0.4 we have also users mysql.session and
# mysql.infoschema created by default.
if  (($major ==8) &&  ($minor == 0)  && ($rev > 3))
{
    $number_of_users = 11;
}
ok_exec({
command  => "make_sandbox $TEST_VERSION -- --no_confirm --sandbox_directory=msb_XXXX",
expected => "sandbox server started",
msg      => "sandbox creation",
});

#+-----------+-------------+-------------------------------------------+
#| host      | user        | password                                  |
#+-----------+-------------+-------------------------------------------+
#| localhost | root        | *6C387FC3893DBA1E3BA155E74754DA6682D04747 | 
#| 127.%     | msandbox    | *6C387FC3893DBA1E3BA155E74754DA6682D04747 | 
#| localhost | msandbox    | *6C387FC3893DBA1E3BA155E74754DA6682D04747 | 
#| localhost | msandbox_rw | *6C387FC3893DBA1E3BA155E74754DA6682D04747 | 
#| 127.%     | msandbox_rw | *6C387FC3893DBA1E3BA155E74754DA6682D04747 | 
#| 127.%     | msandbox_ro | *6C387FC3893DBA1E3BA155E74754DA6682D04747 | 
#| localhost | msandbox_ro | *6C387FC3893DBA1E3BA155E74754DA6682D04747 | 
#| 127.%     | rsandbox    | *B07EB15A2E7BD9620DAE47B194D5B9DBA14377AD | 
#+-----------+-------------+-------------------------------------------+

ok_sql({
path     => "$SANDBOX_HOME/msb_XXXX/",
query    => "select count(*) from mysql.user",
expected => "$number_of_users",
msg      => "number of users",
});

ok_sql({
path     => "$SANDBOX_HOME/msb_XXXX/",
query    => "select count(*) from mysql.user where host = '127.%'",
expected => "4",
msg      => "number of users with host '127.%'",
});

ok_sql({
path     => "$SANDBOX_HOME/msb_XXXX/",
query    => "select count(*) from mysql.user where user = 'msandbox'",
expected => "2",
msg      => "number of 'msandbox' users",
});

ok_sql({
path     => "$SANDBOX_HOME/msb_XXXX/",
query    => "select count(*) from mysql.user where $password_field = password('msandbox')",
expected => "7",
msg      => "number of 'msandbox' passwords",
});

ok_sql({
path     => "$SANDBOX_HOME/msb_XXXX/",
query    => "select user from mysql.user where $password_field = password('rsandbox')",
expected => "rsandbox",
msg      => "user with 'rsandbox' password",
});

ok_exec({
command  => "$SANDBOX_HOME/msb_XXXX/use -u msandbox_rw -e 'create table test.t1( i int)'",
expected => "ok",
msg      => "table creation allowed",
});

ok_exec({
command  => "$SANDBOX_HOME/msb_XXXX/use -u msandbox_rw -e 'insert into test.t1 values (2011)'",
expected => "ok",
msg      => "table insertion allowed",
});

ok_exec({
command  => "$SANDBOX_HOME/msb_XXXX/use -u msandbox_ro -e 'create table test.t2(i int)' 2>&1 || echo 1",
expected => "denied",
msg      => "table creation denied",
});

ok_exec({
command  => "$SANDBOX_HOME/msb_XXXX/use -u msandbox_ro -e 'select * from test.t1'",
expected => "2011",
msg      => "table selection allowed",
});

ok_exec({
command  => "$SANDBOX_HOME/msb_XXXX/use -u msandbox_rw -e 'drop table test.t1'",
expected => "ok",
msg      => "table drop allowed",
});


ok_exec({
command  => qq($SANDBOX_HOME/msb_XXXX/use -h 127.0.0.1 -u rsandbox -prsandbox -e 'show grants for rsandbox@"127.%"'),
expected => "REPLICATION SLAVE",
msg      => "replication slave user",
});

###########################################
# checking user privileges in replication
###########################################

ok_exec({
command     => "make_replication_sandbox --replication_directory=rsandbox_XXXX $TEST_VERSION ",
expected    => "replication directory installed",
msg         => "replication started",
});

sleep 1;

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/master/",
query    => "select count(*) from mysql.user",
expected => "$number_of_users",
msg      => "number of users (master)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/master/",
query    => "select count(*) from mysql.user where host = '127.%'",
expected => "4",
msg      => "number of users with host '127.%' (master)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/master/",
query    => "select count(*) from mysql.user where user = 'msandbox'",
expected => "2",
msg      => "number of 'msandbox' users (master)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/master/",
query    => "select count(*) from mysql.user where $password_field = password('msandbox')",
expected => "7",
msg      => "number of 'msandbox' passwords (master)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/master/",
query    => "select user from mysql.user where $password_field = password('rsandbox')",
expected => "rsandbox",
msg      => "user with 'rsandbox' password (master)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/master/use -u msandbox_rw -e 'create table test.t1( i int)'",
expected => "ok",
msg      => "table creation allowed (master)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/master/use -u msandbox_rw -e 'insert into test.t1 values (2011)'",
expected => "ok",
msg      => "table insertion allowed (master)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/master/use -u msandbox_ro -e 'create table test.t2(i int)' 2>&1 || echo 1",
expected => "denied",
msg      => "table creation denied (master)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/master/use -u msandbox_ro -e 'select * from test.t1'",
expected => "2011",
msg      => "table selection allowed (master)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/master/use -u msandbox_rw -e 'drop table test.t1'",
expected => "ok",
msg      => "table drop allowed (master)",
});

ok_exec({
command  => qq($SANDBOX_HOME/rsandbox_XXXX/master/use -h 127.0.0.1 -u rsandbox -prsandbox -e 'show grants for rsandbox@"127.%"'),
expected => "REPLICATION SLAVE",
msg      => "replication slave user (master)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/node1/",
query    => "select count(*) from mysql.user",
expected => "$number_of_users",
msg      => "number of users (node1)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/node1/",
query    => "select count(*) from mysql.user where host = '127.%'",
expected => "4",
msg      => "number of users with host '127.%' (node1)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/node1/",
query    => "select count(*) from mysql.user where user = 'msandbox'",
expected => "2",
msg      => "number of 'msandbox' users (node1)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/node1/",
query    => "select count(*) from mysql.user where $password_field = password('msandbox')",
expected => "7",
msg      => "number of 'msandbox' passwords (node1)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/node1/",
query    => "select user from mysql.user where $password_field = password('rsandbox')",
expected => "rsandbox",
msg      => "user with 'rsandbox' password (node1)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/node1/use -u msandbox_rw -e 'create table test.t11( i int)'",
expected => "ok",
msg      => "table creation allowed (node1)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/node1/use -u msandbox_rw -e 'insert into test.t11 values (2011)'",
expected => "ok",
msg      => "table insertion allowed (node1)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/node1/use -u msandbox_ro -e 'create table test.t2(i int)' 2>&1 || echo 1",
expected => "denied",
msg      => "table creation denied (node1)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/node1/use -u msandbox_ro -e 'select * from test.t11'",
expected => "2011",
msg      => "table selection allowed (node1)",
});

ok_exec({
command  => "$SANDBOX_HOME/rsandbox_XXXX/node1/use -u msandbox_rw -e 'drop table test.t11'",
expected => "ok",
msg      => "table drop allowed (node1)",
});

ok_exec({
command  => qq($SANDBOX_HOME/rsandbox_XXXX/node1/use -h 127.0.0.1 -u rsandbox -prsandbox -e 'show grants for rsandbox@"127.%"'),
expected => "REPLICATION SLAVE",
msg      => "replication slave user (node1)",
});

ok_exec({
command  => "sbtool -o delete -s $SANDBOX_HOME/msb_XXXX",
expected => "ok",
msg      => "single sandbox removed",
});


ok_exec({
command  => "sbtool -o delete -s $SANDBOX_HOME/rsandbox_XXXX",
expected => "ok",
msg      => "replication sandbox removed",
});

#################################################
# checking remote access ('%' instead of '127.%')
#################################################

ok_exec({
command  => "make_sandbox $TEST_VERSION -- --no_confirm --sandbox_directory=msb_XXXX --remote_access=%",
expected => "sandbox server started",
msg      => "sandbox creation",
});

ok_sql({
path     => "$SANDBOX_HOME/msb_XXXX/",
query    => "select count(*) from mysql.user",
expected => "$number_of_users",
msg      => "number of users",
});

ok_sql({
path     => "$SANDBOX_HOME/msb_XXXX/",
query    => "select count(*) from mysql.user where host = '127.%'",
expected => "0",
msg      => "number of users with host '127.%'",
});

ok_sql({
path     => "$SANDBOX_HOME/msb_XXXX/",
query    => "select count(*) from mysql.user where host = '%'",
expected => "4",
msg      => "number of users with host '%'",
});

ok_exec({
command     => "make_replication_sandbox --replication_directory=rsandbox_XXXX --remote_access=% $TEST_VERSION ",
expected    => "replication directory installed",
msg         => "replication started",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/node1/",
query    => "select count(*) from mysql.user",
expected => "$number_of_users",
msg      => "number of users (node1)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/node1/",
query    => "select count(*) from mysql.user where host = '127.%'",
expected => "0",
msg      => "number of users with host '127.%' (node1)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/node1/",
query    => "select count(*) from mysql.user where host = '%'",
expected => "4",
msg      => "number of users with host '%' (node1)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/master/",
query    => "select count(*) from mysql.user",
expected => "$number_of_users",
msg      => "number of users (master)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/master/",
query    => "select count(*) from mysql.user where host = '127.%'",
expected => "0",
msg      => "number of users with host '127.%' (master)",
});

ok_sql({
path     => "$SANDBOX_HOME/rsandbox_XXXX/master/",
query    => "select count(*) from mysql.user where host = '%'",
expected => "4",
msg      => "number of users with host '%' (master)",
});

ok_exec({
command  => "$SANDBOX_HOME/msb_XXXX/stop",
expected => "OK",
msg      => "stopped ",
});

ok_exec({
command     => "$SANDBOX_HOME/rsandbox_XXXX/stop_all",
expected    => "OK",
msg         => "replication stopped",
});




