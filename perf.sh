#!/bin/bash

n="$1"
file_path="$2"

test "$n" -a "$file_path" \
|| {
    echo 'need two arguments: number of data values, and file path' >&2
    exit 1
}

rm -rf perf
mkdir -p perf

rm -rf exec
mkdir -p exec

i=0
for s in \
    src/sort-branched-inplace.c \
    src/sort-predicated-inplace.c \
    src/es-sort-branched-inplace.c
do
    z=${s#*/}
    z=${z%.*}
    c=gcc

    i=$[i+1]
    j="$(printf '%02d' $i)"
    o=-O3
    p=perf/$j-$z-$c$o.perf
    echo
    echo $s $z $c $o $p
    echo
    $c -Wformat=2 -Wextra -Wall -Wpedantic -Werror -pedantic-errors $o $s -o exec/$z-$c$o || exit 1
    {
        perf stat -e branches -e branch-misses \
        ./exec/$z-$c$o $n $file_path \
        || exit 1
    } \
    |& tee $p

done


