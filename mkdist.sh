#!/bin/bash
if [ "$1" == "" ]
then
    echo "VERSION required";
    exit
fi

VERSION=$1

perl -i.bak -pe 'BEGIN{$V=shift;};s/^(our \$VERSION=)([^;]+)/$1"$V"/' $VERSION lib/MySQL/Sandbox.pm
perl -i.bak -pe 'BEGIN{$V=shift;};s/^(our \$VERSION=)([^;]+)/$1"$V"/' $VERSION lib/MySQL/Sandbox/Scripts.pm
perl -i.bak -pe 'BEGIN{$V=shift;};s/^(our \$VERSION=)([^;]+)/$1"$V"/' $VERSION lib/MySQL/Sandbox/Recipes.pm

pod2text lib/MySQL/Sandbox.pm > README
pod2html lib/MySQL/Sandbox.pm > ./drafts/sandbox.html
pod2html lib/MySQL/Sandbox/Recipes.pm > ./drafts/cookbook.html

# perl Makefile.PL PREFIX=$HOME/usr/local
perl Makefile.PL PREFIX=$HOME/usr/local
make

make test
if [ "$2" == "install" ] 
then
    echo "DOING!!"
    make install
    echo "DONE!!"
else
    if [  -f $HOME/workdir/new_sandbox/dists/MySQL-Sandbox-$VERSION.tar.gz ]
    then
        echo "file $HOME/workdir/new_sandbox/dists/MySQL-Sandbox-$VERSION.tar.gz already exists"
        exit 
    fi
    make dist
    mv *.gz ~/workdir/new_sandbox/dists/
fi

make clean

find . -name "*~" -exec rm {} \;
find . -name "*.bak" -exec rm {} \;
rm -rf t/test_sb/
rm -f pod*.tmp

