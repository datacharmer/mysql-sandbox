#!/bin/bash
if [ ! -f test_versions.txt ]
then
    echo "test_versions.txt not found"
    exit 1
fi

echo "" >> results.txt
echo "## $(date)" >> results.txt
echo "#" >> results.txt
for V in $(cat test_versions.txt)   
do 
    perl Makefile.PL 
    make 
    TEST_VERSION=$V make test 
    EC=$? 
    echo "`date` - $V - $EC" >> results.txt   
    running_mysql=$(ps auxw |grep mysqld)
    if [ -n "$running_mysql" ]
    then
        pkill mysqld
        sleep 10
    fi
done

