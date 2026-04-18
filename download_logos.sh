#!/bin/bash

# Dossier de destination
DEST="contents/logos"
mkdir -p "$DEST"

# Liste des abréviations des équipes NHL actuelles
TEAMS=("ANA" "ARI" "BOS" "BUF" "CGY" "CAR" "CHI" "COL" "CBJ" "DAL" "DET" "EDM" "FLA" "LAK" "MIN" "MTL" "NSH" "NJD" "NYI" "NYR" "OTT" "PHI" "PIT" "SJS" "SEA" "STL" "TBL" "TOR" "UTA" "VAN" "VGK" "WSH" "WPG")

# Mapping des logos historiques vers leurs périodes spécifiques sur le serveur NHL
declare -A HIST_MAP
HIST_MAP["HFD"]="19921993-19961997"
HIST_MAP["QUE"]="19791980-19941995"
HIST_MAP["WIN"]="19901991-19951996"
HIST_MAP["MNS"]="19911992-19921993"
HIST_MAP["ATL"]="19992000-20102011"
HIST_MAP["CLR"]="19761977-19811982"
HIST_MAP["KCS"]="19741975-19751976"
HIST_MAP["AFM"]="19721973-19791980"

echo "Téléchargement des logos NHL dans $DEST..."

# 1. Logos actuels
for team in "${TEAMS[@]}"; do
    echo "Récupération de $team..."
    curl -s "https://assets.nhle.com/logos/nhl/svg/${team}_light.svg" -o "$DEST/${team}_light.svg"
    curl -s "https://assets.nhle.com/logos/nhl/svg/${team}_dark.svg" -o "$DEST/${team}_dark.svg"
done

# 2. Logos historiques
for team in "${!HIST_MAP[@]}"; do
    PERIOD="${HIST_MAP[$team]}"
    echo "Récupération historique de $team ($PERIOD)..."
    URL_BASE="https://assets.nhle.com/logos/nhl/svg/${team}_${PERIOD}"
    
    # On télécharge la version light
    curl -s "${URL_BASE}_light.svg" -o "$DEST/${team}_light.svg"
    
    # On vérifie si le fichier est valide (pas un 404 HTML)
    if grep -q "<html>" "$DEST/${team}_light.svg"; then
        echo "  -> Erreur: Logo $team non trouvé sur le serveur."
        rm "$DEST/${team}_light.svg"
    else
        # Si valide, on essaie la version dark, sinon on duplique la light
        curl -s "${URL_BASE}_dark.svg" -o "$DEST/${team}_dark.svg"
        if grep -q "<html>" "$DEST/${team}_dark.svg"; then
            cp "$DEST/${team}_light.svg" "$DEST/${team}_dark.svg"
        fi
    fi
done

echo "Terminé ! Les logos (actuels et historiques) sont prêts."
