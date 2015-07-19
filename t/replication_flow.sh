#!/bin/bash

sandbox_home=$SANDBOX_HOME
replication_dir=repl_deployment


function ok_equal
{
    fact="$1"
    expected="$2"
    msg="$3"
    if [ "$fact" == "$expected" ]
    then
        echo -n "ok"
    else
        echo -n "not ok"
    fi
    echo " - $msg";
}

make_replication_sandbox --replication_directory=$replication_dir $TEST_VERSION 
ok_equal $? 0 "Replication directory created"
sleep 1
$sandbox_home/$replication_dir/test_replication
ok_equal $? 0 "Replication test was successful"

sbtool -o delete -s $sandbox_home/$replication_dir 
ok_equal $? 0 "Regular replication directory $replication_dir removed"

make_replication_sandbox --circular=3 --replication_directory=$replication_dir $TEST_VERSION 
ok_equal $? 0 'circular replication installed'
sleep 1

$sandbox_home/$replication_dir/test_replication
ok_equal $? 0 "Replication test was successful"

sbtool -o delete -s $sandbox_home/$replication_dir 
ok_equal $? 0 "Circular replication directory $replication_dir removed"

