#!/bin/bash

#   USAGE:  loadRSS.sh初始化脚本

MAX=100

localserver="/var/www/iHIT"
echo "0^0^-1" > $localserver/info

for((i=0;i<MAX;i++))
do
    #创建MAX个文件夹,用来记录MAX条新闻
    mkdir $localserver/$i
done
