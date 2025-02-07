#!bin/bash

PDF=$1
SIRET=$2
CVI=$3
RAISON_SOCIALE=$4
CDP=$5

FILE=$(echo $(basename "$PDF"))
if [[ -z $SIRET || -z $CVI ]]
then
  mv $PDF $(dirname $PDF)'/incorrect/'$FILE
else
  mv $PDF $(dirname $PDF)'/'$FILE'_'$SIRET'_'$CVI'_'$CDP
fi
