#!/usr/bin/env bash
set -e

# NHL Scores Installation Script
# Orchestrates logos download, translations compilation and applet installation.

# Script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# Team list for logos (including historical for franchise history)
TEAMS=("ANA" "ARI" "BOS" "BUF" "CGY" "CAR" "CHI" "COL" "CBJ" "DAL" "DET" "EDM" "FLA" "LAK" "MIN" "MTL" "NSH" "NJD" "NYI" "NYR" "OTT" "PHI" "PIT" "SJS" "SEA" "STL" "TBL" "TOR" "UTA" "VAN" "VGK" "WSH" "WPG" "HFD" "QUE" "WIN" "MNS" "ATL" "CLR" "KCS" "AFM")

# Translation strings
case "${LANG:0:2}" in
    fr)
        MSG_START="--- Installation de l'applet NHL Scores ---"
        MSG_LOGOS="Vérification et téléchargement des logos d'équipe..."
        MSG_COMPILE="Compilation des traductions..."
        MSG_INSTALL_APPLET="Installation de l'applet..."
        MSG_INSTALL_ICON="Installation de l'icône..."
        MSG_INSTALL_NOTIFY="Installation du fichier de notification (notifyrc)..."
        MSG_UPDATE_CACHE="Mise à jour du cache..."
        MSG_DONE="--- Installation terminée ! ---"
        MSG_ADD_APPLET="Vous pouvez maintenant ajouter l'applet 'Scores LNH' à votre bureau ou panneau."
        MSG_RESTART_NOTE="Note : Si vous ne voyez pas les changements, redémarrez Plasma ou déconnectez-vous."
        ;;
    *)
        MSG_START="--- NHL Scores Applet Installation ---"
        MSG_LOGOS="Checking and downloading team logos..."
        MSG_COMPILE="Compiling translations..."
        MSG_INSTALL_APPLET="Installing applet..."
        MSG_INSTALL_ICON="Installing icon..."
        MSG_INSTALL_NOTIFY="Installing notification file (notifyrc)..."
        MSG_UPDATE_CACHE="Updating cache..."
        MSG_DONE="--- Installation completed! ---"
        MSG_ADD_APPLET="You can now add the 'NHL Scores' applet to your desktop or panel."
        MSG_RESTART_NOTE="Note: If you don't see the changes, restart Plasma or log out."
        ;;
esac

echo "$MSG_START"

# 1. Download logos if missing or incomplete
echo "$MSG_LOGOS"
DEST="contents/logos"
mkdir -p "$DEST"

# Check if we have the light and dark versions of a sample team (e.g., MTL)
# and if we have at least 60 files (33 teams * 2 versions = 66)
LOGO_COUNT=$(ls "$DEST"/*.svg 2>/dev/null | wc -l)

if [ ! -f "$DEST/MTL_light.svg" ] || [ "$LOGO_COUNT" -lt 60 ]; then
    for team in "${TEAMS[@]}"; do
        if [ ! -f "$DEST/${team}_light.svg" ]; then
            echo "  -> $team..."
            curl -s "https://assets.nhle.com/logos/nhl/svg/${team}_light.svg" -o "$DEST/${team}_light.svg"
            curl -s "https://assets.nhle.com/logos/nhl/svg/${team}_dark.svg" -o "$DEST/${team}_dark.svg"
        fi
    done
fi

# 2. Compilation des traductions
echo "$MSG_COMPILE"
if [ -d "translate" ] && [ -f "translate/build.sh" ]; then
    bash translate/build.sh
fi

# 3. Installation de l'applet via kpackagetool6
echo "$MSG_INSTALL_APPLET"
kpackagetool6 --type Plasma/Applet --remove org.dany.nhlscores >/dev/null 2>&1 || true
kpackagetool6 --type Plasma/Applet --install .

# 4. Installation de l'icône système
echo "$MSG_INSTALL_ICON"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"
cp contents/icons/org.dany.nhlscores.svg "$ICON_DIR/"

# 5. Installation du fichier notifyrc
echo "$MSG_INSTALL_NOTIFY"
NOTIFY_DIR="$HOME/.local/share/knotifications6"
mkdir -p "$NOTIFY_DIR"
cp plasma_applet_org.dany.nhlscores.notifyrc "$NOTIFY_DIR/"

# 6. Mise à jour des caches
echo "$MSG_UPDATE_CACHE"
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 >/dev/null 2>&1 || true
fi

echo "$MSG_DONE"
echo "$MSG_ADD_APPLET"
echo "$MSG_RESTART_NOTE"
