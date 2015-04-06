#!/bin/bash

# echo "The script you are running has basename `basename $0`, dirname `dirname $0`"
# echo "The present working directory is `pwd`"

cd "`dirname "$0"`"


# ffmpeg -i "SCARY H0USE - Funny Minions Video (1).mp4" -r 2 -s 640x480 test-frame-%05d.png 


 
ffmpeg -r 0.5 -i "ROYALTY FREE HD STOCK FOOTAGE MONTAGE from Nobody Films - Version 2.mp4" -s:v 640x480 test-frame-%05d.png 