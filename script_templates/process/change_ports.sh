#!_BINBASH_
__LICENSE__

OLD_PORT=_SERVERPORT_

if [ "$1" = "" ]
then
    echo "new port required"
    exit
else
    NEW_PORT=$1
fi

if [ $OLD_PORT = $NEW_PORT ]
then
    echo Old port and new port must be different.
    exit
fi

PERL_SCRIPT1='BEGIN{$old=shift;$new=shift};'
PERL_SCRIPT2='s/sandbox$old/sandbox$new/g;'
PERL_SCRIPT3='s/\b$old\b/$new/' 
PERL_SCRIPT="$PERL_SCRIPT1 $PERL_SCRIPT2 $PERL_SCRIPT3"

SCRIPTS1="start stop send_kill clear restart my.sandbox.cnf "
SCRIPTS2="load_grants my use sandbox_env $0"
SCRIPTS="$SCRIPTS1 $SCRIPTS2"
for SCRIPT in $SCRIPTS
do
    perl -i.port.bak -pe "$PERL_SCRIPT" $OLD_PORT $NEW_PORT $SCRIPT
done
echo "($PWD) The old scripts have been saved as filename.port.bak"

