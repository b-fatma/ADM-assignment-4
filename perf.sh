#!/bin/bash

n="$1"
file_path="$3"

test "$n" -a "$file_path" \
|| {
	echo 'need two arguments: number of data values, and file path' >&2
	exit 1
}

rm -rf exec data perf
mkdir -p exec data perf
cp -f plot-template.gp plot.gp

i=0
for s in \
	src/sort-branched-inplace.c \
	src/sort-predicated-inplace.c
do

	z=${s#*/}
	z=${z%.*}
	for c in gcc clang
	do
		for o in 0 3
		do
			i=$[i+1]
			j="$(printf '%02d' $i)"
			o=-O$o
			e=exec/$z-$c$o
			d=data/$z-$c$o.data
			p=perf/$j-$z-$c$o.perf
			echo
			echo $s $z $c $o $e $d
			echo
			$c -Wformat=2 -Wextra -Wall -Wpedantic -Werror -pedantic-errors $o $s -o $e \
			|| exit 1
			{
				{
					perf stat -e branches -e branch-misses \
					./$e $n $lines $file_path \
					|| exit 1
				} \
				| tee $d
			} \
			|& tee $p
			printf '%-26s %15s %15s %9s\n' '' 'branches' 'misses' '%'
			echo '--------------------------------------------------------------------'
			for q in perf/*
			do
				qq=${q#*-}
				qq=${qq%.*}
				printf '%-26s ' $qq
				grep 'branch.*:u' $q \
				| tr '\n' '\t' \
				| awk '{printf "%15s %15s %9s\n",$1,$3,$6}'
			done
			echo
			read
			sed -i "s|^#\(. '$d'\)| \1|" plot.gp
			gnuplot -p plot.gp \
			|& grep -v '^qt.qpa.qgnomeplatform.theme: The desktop style for QtQuick Controls 2 applications is not available on the system (qqc2-desktop-style). The application may look broken.$'
			read
		done
	done
done
