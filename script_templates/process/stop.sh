#!_BINBASH_
__LICENSE__
#-----------------------------------------
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
. "$SBDIR/sandbox_env"
#-----------------------------------------

if [ -f $PIDFILE ]
then
    if [ -f $SBDIR/data/master.info ]
    then
        echo "stop slave" | $SBDIR/use -u root
    fi
    $MYSQL_ADMIN --defaults-file=$SBDIR/my.sandbox.cnf shutdown
    sleep 1
fi
if [ -f $PIDFILE ]
then
    $SBDIR/send_kill
fi
