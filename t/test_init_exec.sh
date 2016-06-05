#!/bin/bash
## Test for --*_exec options
## for example
## make_sandbox 5.6.29 -- --pre_start_exec=./test_init_exec.sh
echo "----------------------------------------------------------------"
echo "Stage: $EXEC_STAGE"
if [ "$EXEC_STAGE" == "pre_start_exec" ]
then
    echo "PWD <$PWD> "
    echo "VER <$MYSQL_VERSION> "
    echo "DIR <$SANDBOX_DIR> "
    echo "DATADIR <$DB_DATADIR> "
    echo "BASEDIR <$BASEDIR> "
    echo "SOCKET <$DB_SOCKET> "
    echo "MY_CNF <$MY_CNF>"
    echo "USER/PASSWORD/PORT <$DB_USER> <$DB_PASSWORD> <$DB_PORT> "
    echo "Version components <$MYSQL_MAJOR> <$MYSQL_MINOR> <$MYSQL_REV>"
fi
cd $SANDBOX_DIR
# ls 
echo '## Data directory'
ls  data
echo "----------------------------------------------------------------"
