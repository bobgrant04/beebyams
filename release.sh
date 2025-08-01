#!/bin/bash

# A hack, because beebasm doesn't allow string variables
VERS=$(grep "#VERSION#" VERSION.asm  | cut -d\" -f2 | tr . _)
DATE=$(date +"%Y%m%d_%H%M")

#./build.sh $*

README=./build/README.txt

echo "              BEEBYAMS"                          >  ${README}
echo "              =============================="    >> ${README}
echo ""                                                >> ${README}
echo "              Version:                  ${VERS}" >> ${README}
echo "              Date:            ${DATE}"          >> ${README}
echo ""                                                >> ${README}
#cat RELEASE.txt                                        >> ${README}

mkdir -p releases

release=releases/${VERS}_${DATE}
mkdir $release
cp ./build/*.* $release/


