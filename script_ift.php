<?php

  $bilanParcelles = json_decode(file_get_contents($argv[1]), true);
  $csvPath = './export_ift.csv';
  $siret = $argv[2];
  $cvi = $argv[3];
  $cdp = $argv[4];
  $raison_sociale = $argv[5];
  $fichier = $argv[6];
  $dirname = dirname($csvPath);
  if (!is_dir($dirname)) {
    mkdir($dirname, 0755, true);
  }

  $header = ["Raison Sociale", "SIRET", "CVI", "CDP", "Campagne", "Surface vigne (HA)", "Nom parcelle", "Surface parcelle", "Date traitement", "Culture", "Produit", "Numéro AMM", "Cible", "Dose Appliquée", "Dose de référence", "Pourcentage traité", "Volume de bouillie", "IFT", "Segment", "Observation", "Date création", "Fichier origine"];

  $addHeader = !file_exists($csvPath);
  $csvOutput = fopen($csvPath, 'a');
  if (! $csvOutput) {
    echo "Erreur à la création du fichier " . $csvPath . ' ';
    exit;
  }

  if ($addHeader) {
    fputcsv($csvOutput, $header, ';');
  }

  $parcellesCultivees = [];
  $surface_vigne = 0;
  $campagne = $bilanParcelles['campagne']['libelle'];
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
        $raison_sociale, $siret, $cvi, $cdp, $campagne, $surface_vigne,
        $parcelle['parcelle']['nom'],
        str_replace('.', ',', $parcelle['parcelle']['surface']),
        $traitement["dateTraitement"], $traitement["culture"]["libelle"],
        $traitement["produitLibelle"], $traitement["numeroAmm"]["idMetier"],
        $traitement["cible"]["libelle"], str_replace('.', ',', $traitement["dose"]),
        str_replace('.', ',', $traitement["doseReference"]),
        str_replace('.', ',', $traitement["facteurDeCorrection"]),
        "-",
        str_replace('.', ',', $traitement["ift"]),
        $traitement["segment"]["libelle"],
        $traitement["avertissement"]["libelle"],
        $traitement["dateCreation"],
        $fichier
      ], ';');
    }
  }

  if (! fclose($csvOutput)) {
    echo "Erreur à la fermeture du fichier " . $csvPath;
    exit;
  }

  return ;
