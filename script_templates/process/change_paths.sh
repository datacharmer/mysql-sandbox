#!_BINBASH_
__LICENSE__
if [ "$1" = "" ]
then
    OLD_SB_LOCATION=_HOME_DIR_/_SANDBOXDIR_
else
    OLD_SB_LOCATION=$1
fi

if [ "$2" = "" ]
then
    NEW_SB_LOCATION=$PWD
else
    NEW_SB_LOCATION=$2
fi

if [ $OLD_SB_LOCATION = $NEW_SB_LOCATION ]
then
    echo Old location and new location must be different.
    echo Move the sandbox to the new location and then run this script.
    exit
fi

if [ ! -d "$NEW_SB_LOCATION" ]
then
    echo "new location must be a directory"
    exit
fi

PERL_SCRIPT1='BEGIN{$old=shift;$new=shift};'
PERL_SCRIPT2='s/$old/$new/g' 
PERL_SCRIPT="$PERL_SCRIPT1 $PERL_SCRIPT2"

SCRIPTS1="start stop send_kill clear restart my.sandbox.cnf "
SCRIPTS2="load_grants my use sandbox_env $0"
SCRIPTS="$SCRIPTS1 $SCRIPTS2"

for SCRIPT in $SCRIPTS
do
    perl -i.bak -pe "$PERL_SCRIPT" $OLD_SB_LOCATION $NEW_SB_LOCATION $SCRIPT
done
echo "($PWD) The old scripts have been saved as filename.path.bak"
