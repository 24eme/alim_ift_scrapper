#!bin/bash

DB=$1
PDF="$2"

ADRESSE=$(echo $DB)"/ETABLISSEMENT/_search?q="

FILE=$(echo $(basename "$PDF") | cut -d'.' -f1 | tr -d [:digit:] | sed 's/_/ /g' | sed -E "s/(Bilan|IFT|2023|-|_)//g")


curl_ret=$(curl -s $ADRESSE$(echo "$FILE""+doc.statut:ACTIF" | sed 's/ /%20/g'))

# Première verification si on a pas de match
if [ "$(echo $curl_ret | jq -c '[.hits.total]')" == "[0]" ]
then
  echo "⚠️ ⚠️  Pas de correpondance pour "$(echo $(basename "$PDF") | cut -d'/' -f2)
  exit
fi

nom_export=$(echo $curl_ret | jq '.hits.hits[0]._source.doc.nom' | sed 's/\"//g' | awk '{print tolower($0)}')
nom_fichier=$(echo $FILE | cut -d' ' -f1 | awk '{print tolower($0)}' | xargs -0)
prenom_fichier=$(echo $FILE | cut -d' ' -f2 | awk '{print tolower($0)}' | xargs -0)


# condition pour verifier si le nom dans le match trouvé correspond au nom du fichier
# attention : peu fiable (la raison sociale peut etre dans le nom du fichier, ou il peut y avoir
# des fautes d'orthographe dans les noms)
if [[ ! ($nom_export =~ "$nom_fichier") && ! ($nom_export =~ "$prenom_fichier") ]]
then
  echo "⚠️ ⚠️  Mauvaise correpondance pour "$(echo $(basename "$PDF") | cut -d'/' -f2)", nom dans l'export : "$(echo "$nom_export")" et nom du fichier :" "$nom_fichier" "$prenom_fichier"
  exit
fi


RS_MATCH=$(echo $curl_ret | jq -c '[.hits.hits[0]._source.doc.raison_sociale]' | sed 's/ /_/g' | tr -d '"[]')
SIRET_MATCH=$(echo $curl_ret | jq -c '[.hits.hits[0]._source.doc.siret]' | tr -d '"[]')
CVI_MATCH=$(echo $curl_ret | jq -c '[.hits.hits[0]._source.doc.cvi]' | tr -d '"[]')
CDP_MATCH=$(echo $curl_ret | jq -c '[.hits.hits[0]._source.doc.identifiant]' | tr -d '"[]')

MATCH=$(echo $RS_MATCH $SIRET_MATCH $CVI_MATCH $CDP_MATCH | tr -d '"[]')
SCORE=$(echo $curl_ret | jq '.hits.hits[0]._score')

echo $SCORE $(echo $(basename "$PDF")) $(echo $(basename "$PDF") | sed 's/.pdf//g')'_'$SIRET_MATCH'_'$CVI_MATCH'_'$CDP_MATCH'.pdf' $FILE
