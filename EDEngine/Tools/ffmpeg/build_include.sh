#!/bin/sh

rm -Rf include > /dev/null
mkdir include > /dev/null
	
rm temp.tar -f > /dev/null
find compat libavformat libavcodec libavdevice  libavutil libavresample libswresample libswscale libavfilter libpostproc -iname "*.h" -exec tar -rvf temp.tar {} \;
tar xvf temp.tar -C include > /dev/null
rm temp.tar -f > /dev/null

find include -iname "*.h" -exec sed -i 's/"config.h"/"ffconfig.h"/g' '{}' \;