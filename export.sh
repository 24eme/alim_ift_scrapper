#!/bin/bash

DB=$1
PDF=$2

MATCHSIRET=$(echo $(basename "$PDF") | grep -Eo "[^0-9]([0-9]{14})[^0-9]" | grep -Eo "[0-9]{14}")
MATCHCVI=$(echo $(basename "$PDF") | grep -Eo "[^0-9]([0-9X]{10})[^0-9]" | grep -Eo "[0-9X]{10}")
MATCHCDP=$(echo $(basename "$PDF") | grep -Eo "[^0-9X]+(CDP[0-9]+)[^0-9]" | grep -Eo "CDP[0-9]+")

QUERY=""
if test "$MATCHCVI" ; then
  QUERY="doc.cvi:$MATCHCVI"
fi
if test "$MATCHCDP" ; then
  if test "$QUERY" ; then
    QUERY="$QUERY+OR+"
  fi
  QUERY="$QUERY""doc.identifiant:$MATCHCDP";
fi
if test "$MATCHSIRET" ; then
  if test "$QUERY"; then
    QUERY="$QUERY+OR+"
  fi
  QUERY="$QUERY""doc.siret:$MATCHSIRET";
fi

SIRET="-"
CVI="-"
CDP="-"
RS="-"

if test "$QUERY" ; then

  curl_ret=$(curl -s $DB"/ETABLISSEMENT/_search?q=$QUERY+doc.statut:ACTIF" | jq -c '[.hits.hits[0]._source.doc.siret, .hits.hits[0]._source.doc.cvi, .hits.hits[0]._source.doc.identifiant, .hits.hits[0]._source.doc.raison_sociale]' | sed 's/,/ /g' | tr -d '"[]')

  SIRET=$(echo $curl_ret | grep -Eo "^([0-9]{14})[^0-9]" || echo "-")
  CVI=$(echo $curl_ret | grep -Eo "[^0-9]([0-9X]{10})[^0-9]" || echo "-")
  CDP=$(echo $curl_ret | grep -Eo "[^0-9X]+(CDP[0-9]+)[^0-9]" || echo "-")
  RS=$(echo $curl_ret | cut -d' ' -f4-)

  if test ! "$RS" ; then
    RS='-'
  fi
fi

DIRNAME_TMP_IFT=/tmp/json_ift
JSON_FILE=$DIRNAME_TMP_IFT/$(echo $(basename $PDF) | cut -d'.' -f1)".json"
mkdir $DIRNAME_TMP_IFT 2> /dev/null

CLE=$(strings "$PDF" | grep https | sed 's/.*https/https/' | sed 's/).*//' | grep verifier-bilan-ift | cut -d '/' -f 6)

if ! test $CLE; then
	echo "ERROR: $PDF: Clé non trouvée" >&2
	exit 2
fi
curl -s "https://alim.api.agriculture.gouv.fr/ift/v5/api/ift/bilan/verifier/$CLE" > $JSON_FILE

php script_ift.php $JSON_FILE $SIRET $CVI $CDP "$RS" "$(basename $PDF)" 2> /dev/null
php script_total.php $JSON_FILE $SIRET $CVI $CDP "$RS" "$(basename $PDF)" 2> /dev/null
