#!/bin/bash
#
#判断nmon是否存在
ls ./nmon 2>&1 >/dev/null
if [ $? -eq '0' ]
  then
    chmod +x nmon
  else
    echo -e "\033[31m [+]Nmon is not in this directory. Please upload it to this directory and rename it to nmon \033[0m"
    exit
fi		

#
#获取所有磁盘
lsscsi |awk '{print $NF}' | grep -v sr[0-9] > all_disk.data
#排除不要有测试的磁盘（如系统盘）
disk=`blkid | grep "TYPE=\"isw_raid_member\"" | awk -F ":" '{print $1}' | cut -d "/" -f 3`
#将不要要测试的磁盘从all_disk.data中删除
echo "$disk" | xargs -n 1 | xargs -I {} echo "\\/dev\\/{}"  > undisk.log
for i in `cat undisk.log`
  do
    sed -i "${i}/d" all_disk.data
  done

#
#filename=`cat all_disk1.data`
#
mkdir ./disk-all
./nmon -f -s 2 -c 1800 -m ./disk-all &
for i in `cat all_disk.data`
do
fio --ioengine=libaio --randrepeat=0 --norandommap --thread --direct=1 --group_reporting --name=all_disk --ramp_time=30 --runtime=3600 --time_based --numjobs=1 --iodepth=16 --filename="$i" --rw=read --bs=2048k --output=./disk-all/`basename ${i}`_2048K_seqW.logout &
done
rm -rf all_disk.data undisk.log all_disk1.data
#=========================================
#
#
#
wait
echo ""
rm -rf ./disk-all/SUM.txt
log=`find ./disk-all -name "*.logout" | cut -d '/' -f 3`
all_size=0
for i in $log
do
name=`echo $i | awk -F'_' '{print $1}'`
size=`cat ./disk-all/$i | grep "^  read" | awk -F ':' '{print $2}'| awk -F ',' '{print $2}'|cut -d "=" -f 2 | cut -d 'K' -f 1`
all_size=$(( $all_size + size ))
echo "$name" "$(($size / 1024))"MB/s >> ./disk-all/SUM.txt
done
echo "======SUM======" >> ./disk-all/SUM.txt
echo SUM "$(($all_size / 1024))"MB/s >> ./disk-all/SUM.txt


