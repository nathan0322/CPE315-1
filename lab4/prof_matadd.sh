#!/bin/bash
# prof_matadd.sh
# Get performance of matadd.s for one optimization levels

runCount=5
executable="matadd"
output="prof_${runCount}runs.csv"
temp="rawoutput.tmp"
CFLGln=$(grep -n "CFLAGS =" Makefile | cut -f1 -d:)

printf "Optimization Level, Run Number, Cycles, Instructions, Clock Speed (GHz), Branch Misses, Execution time(s), matadd % runtime utilized\n" > $output
for i in {1..1}; do
    echo "Optimization Level $i"
    sed "${CFLGln}s/CFLAGS =/CFLAGS = -pg -O${i}/" Makefile > Makefile.tmp && mv Makefile.tmp Makefile
    make --quiet
    for j in $(seq 1 $runCount); do
        echo "Run $j"
        printf "$i, " >> $output
        printf "$j, " >> $output
        perf stat ./$executable > /dev/null 2> $temp
        cat $temp | grep -Po "[0-9,]+(?= *cycles)" | tr -d "," | tr -d "\n" >> $output
        printf ", " >> $output
        cat $temp | grep -Po "[0-9,]+(?= *instructions)" | tr -d "," | tr -d "\n" >> $output
        printf ", " >> $output
        cat $temp | grep -Po "[0-9.]+(?= *GHz)" | tr -d "\n" >> $output
        printf ", " >> $output
        cat $temp | grep -Po "[0-9,]+(?= *branch-misses)" | tr -d "," | tr -d "\n" >> $output
        printf ", " >> $output
        cat $temp | grep -Po "[0-9.]+(?= *seconds)" | tr -d "\n" >> $output
        printf ", " >> $output
        ./$executable > /dev/null 2> /dev/null
        gprof ./matadd > $temp
        cat $temp | grep -Po "[0-9.]+(?=[ 0-9.]*for_width)" | head -c 5 >> $output
        printf "\n" >> $output
    done
    rm -f gmon.out
    rm -f $temp
    make --quiet clean
    sed "${CFLGln}s/CFLAGS = -pg -O${i}/CFLAGS =/" Makefile > Makefile.tmp && mv Makefile.tmp Makefile
done

