#!_BINBASH_
__LICENSE__

#sandbox directory
SBDIR="_HOME_DIR_/_SANDBOXDIR_"

# binaries used for this sandbox
BASEDIR='_BASEDIR_'

# libraries used by the database tools in this sandbox
LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
DYLD_LIBRARY_PATH=$BASEDIR_/lib:$BASEDIR/lib/mysql:$DYLD_LIBRARY_PATH

# The process ID file created when starting mysqld
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"

# options file used to start the server
MYDEF="--defaults-file=$SBDIR/my.sandbox.cnf"

# path to mysqladmin tool
MYSQL_ADMIN="$BASEDIR/bin/mysqladmin"

# path to mysql command line client 
MYSQL="$BASEDIR/bin/mysql"

#
# You can define how to start the server
#
# * mysqld is the standard server
#
# *  mysqld_safe (default) is a daemon that will 
#    restart mysqld if it crashes
#
# * mysqld-debug is the standard server with debugging 
#   options. In a sandbox, you can also get it using
#   ./start --mysqld=mysqld-debug
#
if [ "$MYSQLD_SAFE" = "" ] 
then
    MYSQLD_SAFE="$BASEDIR/bin/mysqld_safe"
fi


# 
# where the output of mysqld_safe goes.
# By default, to /dev/null
if [ "$MYOUTPUT" = "" ]
then
    MYOUTPUT=/dev/null
fi

#
# additional redirection of stderr to stdout
#
if [ "$MYREDIR"  = "" ]
then
    MYREDIR="2>&1"
fi

# 
# If you define $MYFG 
# mysqld runs in foreground
MYBG="&"
if [ "$MYFG" != "" ]
then
    MYBG=""
fi

