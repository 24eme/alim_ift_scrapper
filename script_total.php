<?php

  $bilanGroupes = json_decode(file_get_contents($argv[1]), true);
  $csvPath ='./export_total.csv';
  $siret = $argv[2];
  $cvi = $argv[3];
  $cdp = $argv[4];
  $raison_sociale = $argv[5];
  $fichier = $argv[6];
  $dirname = dirname($csvPath);
  if (!is_dir($dirname)) {
    mkdir($dirname, 0755, true);
  }

  $header = ["Culture", "Raison Sociale", "SIRET", "CVI", "CDP", "Surface (Ha)", "Semences", "Biocontrôle", "Herbicides", "Insecticides acaricides", "Fongicides bactéricides", "Autres", "Total", "Fichier origine"];

  $addHeader = !file_exists($csvPath);
  $csvOutput = fopen($csvPath, 'a');
  if (! $csvOutput) {
    echo "Erreur à la création du fichier " . $csvPath;
    exit;
  }

  if ($addHeader) {
    fputcsv($csvOutput, $header, ';');
  }

  foreach ($bilanGroupes["bilanGroupesCultures"] as $culture) {
    if ($culture["groupeCultures"]["libelle"] != "Vigne") {
      continue;
    }

    fputcsv($csvOutput, [
      $culture["groupeCultures"]["libelle"], $raison_sociale, $siret, $cvi, $cdp,
      str_replace('.', ',', floatval($culture["bilanParSegment"]["surface"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["semences"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["biocontrole"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["herbicide"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["insecticidesAcaricides"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["fongicidesBactericides"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["autres"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["total"])),
      $fichier
      ],
      ';');
  }

  if (! fclose($csvOutput)) {
    echo "Erreur à la fermeture du fichier " . $csvPath;
    exit;
  }

  return ;
