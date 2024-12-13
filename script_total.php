<?php
  if ($argc != 6) {
    echo "php script_application.php <doc_json> <raison_sociale> <SIRET> <CDP> <chemin_fichier_export>";
    exit;
  }

  $bilanGroupes = json_decode(file_get_contents($argv[1]), true);
  $raison_sociale = $argv[2];
  $siret = $argv[3];
  $cdp = $argv[4];
  $csvPath = $argv[5];

  $header = ["Culture", "Raison Sociale", "SIRET", "CDP", "Surface (Ha)", "Semences", "Biocontrôle", "Herbicides", "Insecticides acaricides", "Fongicides bactéricides", "Autres", "Total"];

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
      $culture["groupeCultures"]["libelle"], $raison_sociale, $siret, $cdp,
      str_replace('.', ',', floatval($culture["bilanParSegment"]["surface"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["semences"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["biocontrole"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["herbicide"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["insecticidesAcaricides"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["fongicidesBactericides"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["autres"])),
      str_replace('.', ',', floatval($culture["bilanParSegment"]["total"]))
      ],
      ';');
  }

  if (! fclose($csvOutput)) {
    echo "Erreur à la fermeture du fichier " . $csvPath;
    exit;
  }

  return ;
