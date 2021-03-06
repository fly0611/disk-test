#!/bin/bash
#
#read -p "Please enter the test disk path [/dev/sdd]:" path
#
z='/dev/nvme[0-9][a-z][1-9]'
if [[ $1 == $z ]]
  then
    :
  else
    echo "Please input it in the following format:   $0 /dev/nvme01"
    exit 10 
fi

#

random_size=(4 8)
path=$1

#
Randrw=(randread randwrite 'randrw --rwmixwrite=30' 'randrw --rwmixwrite=20')
randrw=(randread randwrite rwmixwrite=30 rwmixwrite=20)
#预处理
fio --ioengine=libaio --direct=1 --thread --norandommap --filename="$path" --name=init_seq --output=init_seq.log --rw=write --bs=128k --numjobs=1 --iodepth=64 --loops=1
fio --ioengine=libaio --direct=1 --thread --norandommap --filename="$path" --name=init_rand --output=init_rand.log --rw=randwrite --bs=4k --numjobs=8 --iodepth=32 --ramp_time=60 --runtime=3600
#
for i in ${random_size[*]}
do
  for x in `seq 0 $[${#Randrw[@]}-1]`
  do
    mkdir ./$i\-"${randrw[$x]}"
    mkdir_path=`cd ./$i\-"${randrw[$x]}" && pwd`
    ./nmon -f -s 2 -c 1800 -m $mkdir_path &
    echo "----------Runing "$i"K ${randrw[$x]} ----------"
    Fio=" --ioengine=libaio --randrepeat=0 --norandommap --thread --direct=1 --group_reporting --name="$i+"${randrw[$x]}"" --ramp_time=30 --runtime=3600 --time_based --numjobs=8 --iodepth=32 --filename="$path" --rw="${Randrw[$x]}" --bs="$i"k --output="$mkdir_path"/"$i"K_randR.log --log_avg_msec=1000 --write_iops_log="$mkdir_path"/"$i"K_randR_iops.log --write_lat_log="$mkdir_path"/"$i"K_randR_lat.log"
    fio $Fio
    echo ""
  done
done
#
#
#4k随机读写延时

random_size=(4)
path=$1

#
Randrw=(randread randwrite)
randrw=(randread randwrite)
#
for i in ${random_size[*]}
do
  for x in `seq 0 $[${#Randrw[@]}-1]`
  do
    mkdir ./$i\-"${randrw[$x]}"\-latency
    mkdir_path=`cd ./$i\-"${randrw[$x]}"\-latency && pwd`
    ./nmon -f -s 2 -c 1800 -m $mkdir_path &
    echo "----------Runing "$i"K ${randrw[$x]} ----------"
    Fio=" --ioengine=libaio --randrepeat=0 --norandommap --thread --direct=1 --group_reporting --name="$i+"${randrw[$x]}"" --ramp_time=30 --runtime=3600 --time_based --numjobs=1 --iodepth=1 --filename="$path" --rw="${Randrw[$x]}" --bs="$i"k --output="$mkdir_path"/"$i"K_randR.log --log_avg_msec=1000 --write_iops_log="$mkdir_path"/"$i"K_randR_iops.log --write_lat_log="$mkdir_path"/"$i"K_randR_lat.log"
    taskset -c 27 fio $Fio
    echo ""
  done
done
#
#read and write
#=====================
#=====================
random_size=(128)

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
    Fio=" --ioengine=libaio --randrepeat=0 --norandommap --thread --direct=1 --group_reporting --name="$i+"${randrw[$x]}"" --ramp_time=30 --runtime=3600 --time_based --numjobs=1 --iodepth=64 --filename="$path" --rw="${Randrw[$x]}" --bs="$i"k --output="$mkdir_path"/"$i"K_randR.log --log_avg_msec=1000 --write_iops_log="$mkdir_path"/"$i"K_randR_iops.log --write_lat_log="$mkdir_path"/"$i"K_randR_lat.log"
    fio $Fio
    echo ""
  done
done
