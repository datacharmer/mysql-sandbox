#!_BINBASH_
__LICENSE__

#-----------------------------------------
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
. "$SBDIR/sandbox_env"
#-----------------------------------------

if [ "$1" = "" ]
then
    echo "syntax my sql{dump|binlog|admin} arguments"
    exit
fi

SUFFIX=$1
shift

MYSQLCMD="$BASEDIR/bin/my$SUFFIX"

if [ -f $MYSQLCMD ]
then
    $MYSQLCMD --defaults-file=$SBDIR/my.sandbox.cnf "$@"
else
    echo "$MYSQLCMD not found "
fi


