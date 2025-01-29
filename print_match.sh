#!bin/bash

DB=$1
PDF="$2"

ADRESSE=$(echo $DB)"/ETABLISSEMENT/_search?q="

FILE=$(echo $(basename "$PDF") | cut -d'.' -f1 | tr -d [:digit:] | sed 's/_/%20/g' | sed -E "s/(Bilan|IFT|2023|-|_)//g")


curl_ret=$(curl -s $ADRESSE$(echo "$FILE""+doc.statut:ACTIF"))

# Première verification si on a pas de match
if [ "$(echo $curl_ret | jq -c '[.hits.total]')" == "[0]" ]
then
  echo "⚠️ ⚠️  Pas de correpondance pour "$(echo $(basename "$PDF") | cut -d'/' -f2)
  exit
fi

nom_export=$(echo $curl_ret | jq '.hits.hits[0]._source.doc.nom' | sed 's/\"//g' | awk '{print tolower($0)}')
nom_fichier=$(echo $FILE | sed 's/%20/ /g' | cut -d' ' -f1 | awk '{print tolower($0)}' | xargs -0)
prenom_fichier=$(echo $FILE | sed 's/%20/ /g' | cut -d' ' -f2 | awk '{print tolower($0)}' | xargs -0)


# condition pour verifier si le nom dans le match trouvé correspond au nom du fichier
# attention : peu fiable (la raison sociale peut etre dans le nom du fichier, ou il peut y avoir
# des fautes d'orthographe dans les noms)
if [[ ! ($nom_export =~ "$nom_fichier") && ! ($nom_export =~ "$prenom_fichier") ]]
then
  echo "⚠️ ⚠️  Mauvaise correpondance pour "$(echo $(basename "$PDF") | cut -d'/' -f2)", nom dans l'export : "$(echo "$nom_export")" et nom du fichier :" "$nom_fichier" "$prenom_fichier"
  exit
fi


MATCH=$(echo $curl_ret | jq -c '[.hits.hits[0]._source.doc.raison_sociale, .hits.hits[0]._source.doc.siret, .hits.hits[0]._source.doc.cvi, .hits.hits[0]._source.doc.identifiant]' | sed 's/,/ /g' | tr -d '"[]')
SCORE=$(echo $curl_ret | jq '.hits.hits[0]._score')

# on considère (apres observation) qu'au dessus de 1.2 de score le résultat est fiable
if [[ "$SCORE" < "1.2" ]]
then
  echo "SCORE INSUFFISANT : [" $(echo $SCORE) "] -- Le fichier "$(echo $(basename "$PDF") | cut -d'/' -f2)" on match les infos : "$(echo "$MATCH")
  bash rename.sh $PDF "null" "null" "null" "null"
else
  SIRET=$(echo $curl_ret | jq '.hits.hits[0]._source.doc.siret' | sed 's/\"//g')
  CVI=$(echo $curl_ret | jq '.hits.hits[0]._source.doc.cvi' | sed 's/\"//g')
  RAISON_SOCIALE=$(echo $curl_ret | jq '.hits.hits[0]._source.doc.raison_sociale' | sed 's/"//g' | sed 's/ /+/g')
  CDP=$(echo $curl_ret | jq '.hits.hits[0]._source.doc.identifiant' | sed 's/\"//g')
  bash rename.sh $PDF $SIRET $CVI $RAISON_SOCIALE $CDP
fi
