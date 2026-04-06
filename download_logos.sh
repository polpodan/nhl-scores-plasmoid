#!/bin/bash

# Dossier de destination
DEST="contents/logos"
mkdir -p "$DEST"

# Liste des abréviations des équipes NHL
TEAMS=("ANA" "ARI" "BOS" "BUF" "CGY" "CAR" "CHI" "COL" "CBJ" "DAL" "DET" "EDM" "FLA" "LAK" "MIN" "MTL" "NSH" "NJD" "NYI" "NYR" "OTT" "PHI" "PIT" "SJS" "SEA" "STL" "TBL" "TOR" "UTA" "VAN" "VGK" "WSH" "WPG")

echo "Téléchargement des logos NHL (Light & Dark) dans $DEST..."

for team in "${TEAMS[@]}"; do
    echo "Récupération de $team..."
    curl -s "https://assets.nhle.com/logos/nhl/svg/${team}_light.svg" -o "$DEST/${team}_light.svg"
    curl -s "https://assets.nhle.com/logos/nhl/svg/${team}_dark.svg" -o "$DEST/${team}_dark.svg"
done

echo "Terminé ! Les variantes ont été enregistrées localement."
