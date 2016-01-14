#!/bin/bash
if [ -z "$1" ]
then
    echo "VERSION required";
    exit
fi

export VERSION=$1

required_tools=(perl make pod2markdown)
for tool in ${required_tools[*]}
do
    tool_exists=$(type -P "$tool") 
    if [ -z "$tool_exists" ]
    then
        echo "# $tool not found in PATH"
        exit 1
    fi
done

export YEAR=$(date +%Y)
TOOLS="deploy_to_remote_sandboxes.sh low_level_make_sandbox make_multiple_custom_sandbox"
TOOLS="$TOOLS make_multiple_sandbox make_replication_sandbox make_sandbox make_sandbox_from_installed"
TOOLS="$TOOLS make_sandbox_from_source msandbox msb sbtool test_sandbox"
LIBS="lib/MySQL/Sandbox.pm lib/MySQL/Sandbox/Scripts.pm lib/MySQL/Sandbox/Recipes.pm"

CHANGE_COPYRIGHT_YEAR='BEGIN{$y=shift;};s/(2006-)\d+ (Giuseppe Maxia)/$1$y $2/'
CHANGE_VERSION='BEGIN{$V=shift;};s/^(our \$VERSION=)([^;]+)/$1"$V"/' 

for TOOL in $TOOLS
do
    perl -i.bak -pe $CHANGE_COPYRIGHT_YEAR $YEAR bin/$TOOL
done
for LIB in $LIBS
do
    perl -i.bak -pe $CHANGE_VERSION $VERSION $LIB
    perl -i.1bak -pe $CHANGE_COPYRIGHT_YEAR $YEAR $LIB
done

pod2markdown lib/MySQL/Sandbox.pm > README.md

perl Makefile.PL PREFIX=$HOME/usr/local
make

make test
if [ "$?" != "0" ]
then
    exit 1
fi

if [ "$2" == "install" ] 
then
    echo "DOING!!"
    make install
    echo "DONE!!"
else
    if [  -f MySQL-Sandbox-$VERSION.tar.gz ]
    then
        echo "file MySQL-Sandbox-$VERSION.tar.gz already exists"
        exit 
    fi
    make dist
fi

make clean

find . -name "*~" -exec rm {} \;
find . -name "*.bak" -exec rm {} \;
find . -name "*.1bak" -exec rm {} \;
rm -rf t/test_sb/
rm -f pod*.tmp
rm -f Makefile.old


