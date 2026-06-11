#!/bin/bash

for file in mcl_maps/*.tga; do
    dst_file=${file%.*}.bin
    convert $file -bordercolor white -border 1 PNG:/dev/stdout | \
	stream -map "BGRA" -storage-type char -extract "0,0+130,130" \
	       /dev/stdin $dst_file
    if test $? -ne 0; then
	printf "Could not convert map: %s\n" file
    fi
    truncate -s 135200 $dst_file
done
