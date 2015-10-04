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
perl -i.1bak -pe 'BEGIN{$y=shift;};s/(2006-)\d+ (Giuseppe Maxia)/$1$y $2/' $YEAR lib/MySQL/Sandbox.pm
perl -i.bak -pe 'BEGIN{$V=shift;};s/^(our \$VERSION=)([^;]+)/$1"$V"/' $VERSION lib/MySQL/Sandbox.pm
perl -i.bak -pe 'BEGIN{$V=shift;};s/^(our \$VERSION=)([^;]+)/$1"$V"/' $VERSION lib/MySQL/Sandbox/Scripts.pm
perl -i.bak -pe 'BEGIN{$V=shift;};s/^(our \$VERSION=)([^;]+)/$1"$V"/' $VERSION lib/MySQL/Sandbox/Recipes.pm

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

