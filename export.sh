#!/bin/bash

PDF=$1
INFO_OPERATEUR=$(echo $(basename $PDF) | cut -d'?' -f1)
SIRET=$(echo $INFO_OPERATEUR | cut -d'_' -f1)
CVI=$(echo $INFO_OPERATEUR | cut -d'_' -f2)
RAISON_SOCIALE=$(echo $INFO_OPERATEUR | cut -d'_' -f3 | sed 's/+/ /g')
CDP=$(echo $INFO_OPERATEUR | cut -d'_' -f4)
FICHIER=$(echo $(basename $PDF) | cut -d'?' -f2)

DIRNAME_TMP_IFT=/tmp/json_ift
ADRESSE=$(echo $DB)"/ETABLISSEMENT/_search?q="

JSON_FILE=$DIRNAME_TMP_IFT/$CDP".json"
mkdir $DIRNAME_TMP_IFT 2> /dev/null

CLE=$(strings "$PDF" | grep https | sed 's/.*https/https/' | sed 's/).*//' | grep verifier-bilan-ift | cut -d '/' -f 6)

curl -s "https://alim.api.agriculture.gouv.fr/ift/v5/api/ift/bilan/verifier/$CLE" > $JSON_FILE

php script_ift.php $JSON_FILE $SIRET $CVI $CDP "$RAISON_SOCIALE" "$FICHIER" 2> /dev/null
php script_total.php $JSON_FILE $SIRET $CVI $CDP "$RAISON_SOCIALE" "$FICHIER" 2> /dev/null
