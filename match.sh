#!bin/bash

DOSSIER_PDF=$1
DOSSIER_OUTPUT=$2

ADRESSE=""
DATE=$(date +%Y%m%d%H%M%S)

for pdf in $DOSSIER_PDF/*.pdf
  do
    FILE=$(echo "${pdf}" | cut -d'/' -f3 | cut -d'.' -f1)
    SIRET=$(echo "$FILE" | grep -Eo "([^0-9]+|^)[0-9]{14}([^0-9]+|$)" | grep -Eo "[0-9]{14}")
    CVI=$(echo "$FILE" | grep -Eo "([^0-9]+|^)[0-9]{10}([^0-9]+|$)" | grep -Eo "[0-9]{10}")

    if [[ -z $SIRET || -z $CVI ]]
    then
      echo "Pas de correspondance trouvée pour $(basename "${pdf}")"
      bash export.sh "-" "-" "-" "-" $DOSSIER_OUTPUT \""${pdf}"\" $DATE
      continue
    fi

    curl_ret=$(curl $ADRESSE"doc.siret:$SIRET+OR+doc.cvi:$CVI")
    if [ "$(echo $curl_ret | jq -c '[.hits.total]')" == "[0]" ]
    then
      echo "Pas de correspondance trouvée pour $(basename "${pdf}")"
      bash export.sh "-" "-" "-" "-" $DOSSIER_OUTPUT \""${pdf}"\" $DATE
    else
      cdp_raisonsociale=$(echo $curl_ret | jq -c '[.hits.hits[0]._source.doc.compte, .hits.hits[0]._source.doc.raison_sociale]' | sed 's/,/ /g' | tr -d '"[]')
      CDP=$(echo $cdp_raisonsociale | cut -d' ' -f1 | cut -d'-' -f2)
      RAISON_SOCIALE=$(echo $cdp_raisonsociale | cut -d' ' -f2)

      echo "Correspondance trouvée pour $(basename "${pdf}")"

      bash export.sh $SIRET $CVI $CDP $RAISON_SOCIALE $DOSSIER_OUTPUT \""${pdf}"\" $DATE
    fi

  done
