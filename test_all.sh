#!/bin/bash
if [ ! -f test_versions.txt ]
then
    echo "test_versions.txt not found"
    exit 1
fi

echo "" >> results.txt
echo "## $(date)" >> results.txt
echo "#" >> results.txt
[ -z "$SANDBOX_BINARY" ] && SANDBOX_BINARY=$HOME/opt/mysql


for V in $(grep -v '^\s*#' test_versions.txt)   
do 
    if [ ! -d $SANDBOX_BINARY/$V ]
    then
        echo "# $V not found in $SANDBOX_BINARY"
        echo "# $V skipped" >> results.txt
        continue
    fi 
    echo "# Testing $V"
    perl Makefile.PL 
    if [ "$?" != "0" ] ; then continue ; fi
    make 
    if [ "$?" != "0" ] ; then continue ; fi
    TEST_VERSION=$V make test 
    EC=$? 
    echo "`date` - $V - $EC" >> results.txt   
    running_mysql=$(pgrep mysqld)
    if [ -n "$running_mysql" ]
    then
        pkill mysqld
        sleep 10
    fi
done

