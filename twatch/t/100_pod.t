#!/bin/bash

NUMBER=0

list_files=`\
    find lib -type f '(' -name '*.p[lm]' ')' \
    | grep -v '\.svn' \
    | tee list_perl_files.txt`

total=`wc -l list_perl_files.txt|awk '{print $1}'`

rm -f list_perl_files.txt

echo 1..$total
echo "**************** Test inline documentation : Pod ********"

begin=$1

test -z "$begin" && begin=0

for file in $list_files; do
    NUMBER=$[ $NUMBER + 1 ]

    if test $NUMBER -lt $begin; then
        echo skip $NUMBER - podchecker $file
        continue
    fi

    output=`podchecker $file 2>&1`

    if test $? -eq 0; then
        if echo $output|grep -q WARNING:; then
            echo fail $NUMBER - podchecker $file
            exec podchecker $file
        fi

        echo ok $NUMBER - podchecker $file
    else
        quit_code=$?
        echo fail $NUMBER - podchecker $file
        exec podchecker $file
    fi

done

