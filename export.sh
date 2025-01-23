#!/bin/bash

SIRET=$1
CVI=$2
CDP=$3
RAISON_SOCIALE=$4
DIR_OUTPUT=$5
PDF=$(echo "$6" | tr -d '"')
DATE=$7

DIRNAME_TMP_IFT=/tmp/json_ift

JSON_FILE=$DIRNAME_TMP_IFT/$DATE".json"

mkdir $DIRNAME_TMP_IFT 2> /dev/null
CLE=$(strings "$PDF" | grep https | sed 's/.*https/https/' | sed 's/).*//' | grep verifier-bilan-ift | cut -d '/' -f 6)

curl -s "https://alim.api.agriculture.gouv.fr/ift/v5/api/ift/bilan/verifier/$CLE" > $JSON_FILE

php script_ift.php $JSON_FILE $DIR_OUTPUT $SIRET $CVI $CDP $RAISON_SOCIALE
php script_total.php $JSON_FILE $DIR_OUTPUT $SIRET $CVI $CDP $RAISON_SOCIALE
