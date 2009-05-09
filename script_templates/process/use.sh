#!_BINBASH_
__LICENSE__

#-----------------------------------------
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
. "$SBDIR/sandbox_env"
#-----------------------------------------


if [ -f $PIDFILE ]
then
    $MYSQL --defaults-file=$SBDIR/my.sandbox.cnf $MYCLIENT_OPTIONS "$@"
fi

