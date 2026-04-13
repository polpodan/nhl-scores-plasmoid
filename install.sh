#!/usr/bin/env bash
set -e

# NHL Scores Installation Script
# Orchestrates logos download, translations compilation and applet installation.

# Script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

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
if [ ! -f "contents/logos/MTL.svg" ]; then
    chmod +x download_logos.sh
    ./download_logos.sh
else
    # Simple check if we have roughly enough files
    LOGO_COUNT=$(ls contents/logos/*.svg 2>/dev/null | wc -l)
    if [ "$LOGO_COUNT" -lt 30 ]; then
        ./download_logos.sh
    fi
fi

# 2. Compilation des traductions
echo "$MSG_COMPILE"
if [ -d "translate" ] && [ -f "translate/build.sh" ]; then
    bash translate/build.sh
fi

# 3. Installation de l'applet via kpackagetool6
echo "$MSG_INSTALL_APPLET"
# We try to remove first to ensure a clean install/upgrade
kpackagetool6 --type Plasma/Applet --remove org.dany.nhlscores >/dev/null 2>&1 || true
kpackagetool6 --type Plasma/Applet --install .

# 4. Installation de l'icône système (pour le lanceur d'application)
echo "$MSG_INSTALL_ICON"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"
cp contents/icons/org.dany.nhlscores.svg "$ICON_DIR/"

# 5. Installation du fichier notifyrc pour les notifications système
echo "$MSG_INSTALL_NOTIFY"
NOTIFY_DIR="$HOME/.local/share/knotifications6"
mkdir -p "$NOTIFY_DIR"
cp plasma_applet_org.dany.nhlscores.notifyrc "$NOTIFY_DIR/"

# 6. Mise à jour des caches (Icônes et Plasma)
echo "$MSG_UPDATE_CACHE"
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

# Force Plasma to reload the metadata/translations cache
if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 >/dev/null 2>&1 || true
fi

echo "$MSG_DONE"
echo "$MSG_ADD_APPLET"
echo "$MSG_RESTART_NOTE"
