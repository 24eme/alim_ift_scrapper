<?php

  $bilanParcelles = json_decode(file_get_contents($argv[1]), true);
  if (!$bilanParcelles) {
    echo "ERROR: corrupted json ".$argv[1]."\n";
    exit(1);
  }
  $siret = $argv[2];
  $cvi = $argv[3];
  $cdp = $argv[4];
  $raison_sociale = $argv[5];
  $fichier = $argv[6];
  $export_dir = '.';
  if (isset($argv[7])) {
    $export_dir = $argv[7];
  }
  $csvPath = $export_dir.'/export_ift.csv';

  $dirname = dirname($csvPath);
  if (!is_dir($dirname)) {
    mkdir($dirname, 0755, true);
  }

  $header = ["Raison Sociale", "SIRET", "CVI", "CDP", "Campagne", "Surface vigne (HA)", "Nom parcelle", "Surface parcelle", "Date traitement", "Culture", "Produit", "Numéro AMM", "Cible", "Dose Appliquée", "Dose de référence", "Pourcentage traité", "Volume de bouillie", "IFT", "Segment", "Observation", "Date création", "Fichier origine"];

  $addHeader = !file_exists($csvPath);
  $csvOutput = fopen($csvPath, 'a');
  if (! $csvOutput) {
    echo "Erreur à la création du fichier " . $csvPath . ' ';
    exit(2);
  }

  if ($addHeader) {
    fputcsv($csvOutput, $header, ';');
  }

  $parcellesCultivees = [];
  $surface_vigne = 0;
  if (!isset($bilanParcelles['campagne']['libelle']) || !isset($bilanParcelles['bilanParcellesCultivees'])) {
	echo "ERR: campagne or bilanParcellesCultuvees missing in ".$fichier." (".$bilanParcelles.")\n";
	print_r([$bilanParcelles]);
        exit(3);
  }
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
        $traitement["dateTraitement"],
        $traitement["culture"]["libelle"],
        $traitement["produitLibelle"],
        isset($traitement["numeroAmm"]) ? $traitement["numeroAmm"]["idMetier"] : '',
        isset($traitement["cible"]["libelle"]) ? $traitement["cible"]["libelle"] : '',
        isset($traitement["dose"]) ? str_replace('.', ',', $traitement["dose"]) : '',
        isset($traitement["doseReference"]) ? str_replace('.', ',', $traitement["doseReference"]) : '',
        str_replace('.', ',', $traitement["facteurDeCorrection"]),
        "-",
        str_replace('.', ',', $traitement["ift"]),
        $traitement["segment"]["libelle"],
        isset($traitement["avertissement"]["libelle"]) ? $traitement["avertissement"]["libelle"] : '' ,
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
