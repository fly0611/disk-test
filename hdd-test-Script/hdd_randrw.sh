#!/bin/bash
#
#read -p "Please enter the test disk path [/dev/sdd]:" path
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

random_size=(4 64 256)
path=$1

#
Randrw=(randread randwrite 'randrw --rwmixwrite=30' 'randrw --rwmixwrite=20')
randrw=(randread randwrite rwmixwrite=30 rwmixwrite=20)

for i in ${random_size[*]}
do
  for x in `seq 0 $[${#Randrw[@]}-1]`
  do
    mkdir ./$i\-"${randrw[$x]}"
    mkdir_path=`cd ./$i\-"${randrw[$x]}" && pwd`
    ./nmon -f -s 2 -c 1900 -m $mkdir_path &
    echo "----------Runing "$i"K ${randrw[$x]} ----------"
    Fio=" --ioengine=libaio --randrepeat=0 --norandommap --thread --direct=1 --group_reporting --name="$i+"${randrw[$x]}"" --ramp_time=30 --runtime=3600 --time_based --numjobs=1 --iodepth=16 --filename="$path" --rw="${Randrw[$x]}" --bs="$i"k --output="$mkdir_path"/"$i"K_randR.log --log_avg_msec=1000 --write_iops_log="$mkdir_path"/"$i"K_randR_iops.log --write_lat_log="$mkdir_path"/"$i"K_randR_lat.log"
    fio $Fio
		echo
    echo
    echo "sleep 600s,please waitting..."
    echo ""
    sleep 600
  done
done
