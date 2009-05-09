#!_BINBASH_
__LICENSE__

#-----------------------------------------
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
. "$SBDIR/sandbox_env"
#-----------------------------------------

TIMEOUT=10
if [ -f $PIDFILE ]
then
    MYPID=`cat $PIDFILE`
    echo "Attempting normal termination --- kill -15 $MYPID"
    kill -15 $MYPID
    # give it a chance to exit peacefully
    ATTEMPTS=1
    while [ -f $PIDFILE ]
    do
        ATTEMPTS=$(( $ATTEMPTS + 1 ))
        if [ $ATTEMPTS = $TIMEOUT ]
        then
            break
        fi
        sleep 1
    done
    if [ -f $PIDFILE ]
    then
        echo "SERVER UNRESPONSIVE --- kill -9 $MYPID"
        kill -9 $MYPID
        rm -f $PIDFILE
    fi
fi


