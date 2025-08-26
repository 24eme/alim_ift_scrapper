#!/bin/bash
. config.inc

PDF=$1

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

  SEARCH_RES_CMD="curl -s $DB/ETABLISSEMENT/_search?q=$QUERY+doc.statut:ACTIF"
  if test "$CACHE_DIR"; then
      mkdir -p $CACHE_DIR"/el/"
      CACHE_FILE=$CACHE_DIR"/el/"$(echo "$QUERY" | md5sum | sed 's/ .*//')".json";
      if ! test -s $CACHE_FILE; then
        $SEARCH_RES_CMD > $CACHE_FILE
      fi
      SEARCH_RES_CMD="cat "$CACHE_FILE
  fi
  curl_ret=$( $SEARCH_RES_CMD | jq -c '[.hits.hits[0]._source.doc.siret, .hits.hits[0]._source.doc.cvi, .hits.hits[0]._source.doc.identifiant, .hits.hits[0]._source.doc.raison_sociale]' | sed 's/,/ /g' | tr -d '"[]')

  SIRET=$(echo $curl_ret | grep -Eo "^([0-9]{14})[^0-9]" || echo "-")
  CVI=$(echo $curl_ret | grep -Eo "[^0-9]([0-9X]{10})[^0-9]" || echo "-")
  CDP=$(echo $curl_ret | grep -Eo "[^0-9X]+(CDP[0-9]+)[^0-9]" || echo "-")
  RS=$(echo $curl_ret | cut -d' ' -f4-)

  if test ! "$RS" ; then
    RS='-'
  fi
fi

DIRNAME_TMP_IFT=/tmp/json_ift
JSON_FILE=$DIRNAME_TMP_IFT/$(echo $(basename "$PDF") | cut -d'.' -f1)".json"
mkdir -p $DIRNAME_TMP_IFT

CLE=$(strings "$PDF" | grep https | sed 's/.*https/https/' | sed 's/).*//' | grep verifier-bilan-ift | tail -n 1 | sed 's/.*verifier-bilan-ift\///')

if ! test $CLE; then
	echo "ERROR: $PDF: Clé non trouvée" >&2
	exit 2
fi
if test $CACHE_DIR ; then
   mkdir -p $CACHE_DIR
   if ! test -s $CACHE_DIR"/"$CLE; then
      curl -s "$API/$CLE" > $CACHE_DIR"/"$CLE
   fi
   JSON_FILE=$CACHE_DIR"/"$CLE
else
   curl -s "$API/$CLE" > "$JSON_FILE"
fi

if ! test -s "$JSON_FILE"; then
   echo "ERROR: unable to generate $JSON_FILE from $API/$CLE" >&2;
   exit 3
fi
php script_ift.php "$JSON_FILE" $SIRET $CVI $CDP "$RS" "$(basename "$PDF")" $EXPORT_DIR
php script_total.php "$JSON_FILE" $SIRET $CVI $CDP "$RS" "$(basename "$PDF")" $EXPORT_DIR
