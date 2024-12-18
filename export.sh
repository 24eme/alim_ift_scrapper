#!/bin/bash

if (( $# != 5 )); then
  >&2 echo "./export.sh <clé> <raison sociale> <siret> <cdp> <dossier_output>"
  exit 2
fi

CLE=$1
RAISON_SOCIALE=$2
SIRET=$3
CDP=$4
DIR_OUTPUT=$5

DIRNAME_TMP_IFT=/tmp/json_ift

JSON_FILE=$DIRNAME_TMP_IFT/$(date +%Y%m%d%H%M%S)"_"$CDP".json"

mkdir $DIRNAME_TMP_IFT 2> /dev/null

curl "https://alim.api.agriculture.gouv.fr/ift/v5/api/ift/bilan/verifier/$CLE" > $JSON_FILE

php script_ift.php $JSON_FILE $RAISON_SOCIALE $SIRET $CDP $DIR_OUTPUT
php script_total.php $JSON_FILE $RAISON_SOCIALE $SIRET $CDP $DIR_OUTPUT
