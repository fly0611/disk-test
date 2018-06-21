#!/bin/bash

#read -p "Please enter the test disk path [/dev/sdd]:" path
#
#
z='/dev/[s,h]d[a-z]'
if [[ $1 == $z ]]
  then
    :
  else
    echo "Please input it in the following format:   $0 /dev/sdb"
    exit 10
fi

#

random_size=(64 128 256 512 1024 2048)
path=$1
#
Randrw=(read write)
randrw=(read write )
#预处理
fio --ioengine=libaio --direct=1 --thread --norandommap --filename="$path" --name=init_seq2 --output=init_seq2.log --rw=write --bs=128k --numjobs=1 --iodepth=64 --loops=1

for i in ${random_size[*]}
do
  for x in `seq 0 $[${#Randrw[@]}-1]`
  do
    mkdir ./$i\-"${randrw[$x]}"
    mkdir_path=`cd ./$i\-"${randrw[$x]}" && pwd`
    ./nmon -f -s 2 -c 1800 -m $mkdir_path &
    echo "----------Runing "$i"K ${randrw[$x]} ----------"
    Fio=" --ioengine=libaio --randrepeat=0 --norandommap --thread --direct=1 --group_reporting --name="$i+"${randrw[$x]}"" --ramp_time=30 --runtime=3600 --time_based --numjobs=1 --iodepth=16 --filename="$path" --rw="${Randrw[$x]}" --bs="$i"k --output="$mkdir_path"/"$i"K_randR.log --log_avg_msec=1000 --write_iops_log="$mkdir_path"/"$i"K_randR_iops.log --write_lat_log="$mkdir_path"/"$i"K_randR_lat.log"
    fio $Fio
    echo ""
  done
done
