<?php
  if ($argc != 6) {
    echo "php script_application.php <doc_json> <raison_sociale> <SIRET> <CDP> <chemin_fichier_export>";
    exit;
  }

  $bilanParcelles = json_decode(file_get_contents($argv[1]), true);
  $raison_sociale = $argv[2];
  $siret = $argv[3];
  $cdp = $argv[4];
  $csvPath = $argv[5];

  $header = ["Raison Sociale", "SIRET", "CDP", "Surface vigne (HA)", "Nom parcelle", "Surface parcelle", "Date traitement", "Culture", "Produit", "Numéro AMM", "Cible", "Dose Appliquée", "Dose de référence", "Pourcentage traité", "Volume de bouillie", "IFT", "Segment", "Observation"];

  $addHeader = !file_exists($csvPath);
  $csvOutput = fopen($csvPath, 'a');
  if (! $csvOutput) {
    echo "Erreur à la création du fichier " . $csvPath;
    exit;
  }

  if ($addHeader) {
    fputcsv($csvOutput, $header, ';');
  }

  $parcellesCultivees = [];
  $surface_vigne = 0;

  foreach ($bilanParcelles['bilanParcellesCultivees'] as $parcelle) {
    if ($parcelle["parcelleCultivee"]["culture"]["libelle"] != "Vigne") {
      continue;
    }
    $surface_vigne += $parcelle["bilanParSegment"]["surface"];
    $parcellesCultivees[] = $parcelle['parcelleCultivee'];
  }

  foreach($parcellesCultivees as $index => $parcelle) {
    foreach ($parcelle['traitements'] as $traitement) {
      fputcsv($csvOutput,
      [
        $raison_sociale, $siret, $cdp, $surface_vigne,
        $parcelle['parcelle']['nom'],
        str_replace('.', ',', $parcelle['parcelle']['surface']),
        $traitement["dateTraitement"], $traitement["culture"]["libelle"],
        $traitement["produitLibelle"], $traitement["numeroAmm"]["idMetier"],
        $traitement["cible"]["libelle"], str_replace('.', ',', $traitement["dose"]),
        str_replace('.', ',', $traitement["doseReference"]),
        str_replace('.', ',', $traitement["facteurDeCorrection"]),
        "-",
        str_replace('.', ',', $traitement["ift"]),
        $traitement["segment"]["libelle"], "-"
      ], ';');
    }
  }

  if (! fclose($csvOutput)) {
    echo "Erreur à la fermeture du fichier " . $csvPath;
    exit;
  }

  return ;
