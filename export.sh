#!/bin/bash

if (( $# != 6 )); then
  >&2 echo "./export.sh <fichier json> <raison sociale> <siret> <cdp> <fichier output ift> <fichier output total>"
  exit 2
fi

php script_ift.php $1 $2 $3 $4 $5
php script_total.php $1 $2 $3 $4 $6
