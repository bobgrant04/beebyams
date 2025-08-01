#!/bin/bash

rm -rf build
mkdir -p build


SYSTEMS="beebyams"




VERSION=`grep '#VERSION#' VERSION.asm | cut -d\" -f2`
echo "Building $SYSTEMS version $VERSION"

# Set the BEEBASM executable for the platform
# Let's see if the user already has one on their path
BEEBASM=$(type -path beebasm 2>/dev/null)
if [ "$(uname -s)" == "Darwin" ]; then
    BEEBASM=${BEEBASM:-./tools/beebasm/beebasm-darwin}
    MD5SUM=md5
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    if [ "$(uname -m)" == "x86_64" ]; then
        BEEBASM=${BEEBASM:-./tools/beebasm/beebasm64}
    else
        BEEBASM=${BEEBASM:-./tools/beebasm/beebasm32}
    fi
    MD5SUM=md5sum
fi
BEEBASM=${BEEBASM:-./tools/beebasm/beebasm.exe}
#BEEBASM=${BEEBASM:-./tools/beebasm/beebasm64}./
MD5SUM=md5sum
echo Using $BEEBASM



for system in $SYSTEMS
do
	# Create a blank SSD image
	mkdir -p ./build/$system
	sys=./build/$system.ssd
	./tools/blank_ssd.pl ${sys}
	./tools/title.pl ${sys} "$system $VERSION"
    
	if [ $system == "beebyams" ]; then
        DEVICES="ASR ALTER ALTER+ ADR CMD COMPRESS CRC DIN IMPORT MAGIC MMCDISC MMUDISP U WHATFS X GFN pubstr"
    else
        DEVICES=""
    fi

    for device in $DEVICES
    do
        build=./build/${device}
        mkdir -p ${build}
        ssd=${build}/$device.ssd
        rm -f ${ssd}

        echo
		name=$device.asm
	
        
        echo "Building ${device}/$name..."
      

		# run beebasm
		$BEEBASM -i $name -do ${build}/${device}.ssd -v >& ${build}/${name}.log
        # create single disk image  
		$BEEBASM -i $name -di $sys -do ./build/new.SSD
		rm $sys
		mv ./build/new.SSD $sys
	

           
        
        # Copy utilities
        #if [ $system = MMFS ]; then
         #\ tools/mmb_utils/putfile.pl ${ssd} utilities/bin/IDTOM
         #\ tools/mmb_utils/putfile.pl ${ssd} utilities/bin/IMTOD
        #\#else
        #\#  tools/mmb_utils/putfile.pl ${ssd} utilities/bin/IDTOM2
        #\  tools/mmb_utils/putfile.pl ${ssd} utilities/bin/IMTOD2
        #\fi
        #\echo
        #\tools/mmb_utils/info.pl  ${ssd}

        #\rm -f DEVICE.asm

    done # for device

done # for system beebyams
