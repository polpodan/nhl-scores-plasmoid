#!/usr/bin/env bash
set -euo pipefail

# Dossier racine du dépôt
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCALE_DIR="$ROOT_DIR/contents/locale"

# Identifiant du plasmoid = "KPackage.Id" défini dans metadata.json
APPLET_ID="org.dany.nhlscores"
CATALOG="plasma_applet_${APPLET_ID}"

# Langues à compiler
LANGS=(fr fr_CA)

mkdir -p "$LOCALE_DIR"

for L in "${LANGS[@]}"; do
  PO_FILE="$ROOT_DIR/translate/$L.po"
  # Support pour fr.po mappé sur fr
  if [[ "$L" == "fr" && ! -f "$PO_FILE" && -f "$ROOT_DIR/translate/fr.po" ]]; then
     PO_FILE="$ROOT_DIR/translate/fr.po"
  fi

  OUT_DIR="$LOCALE_DIR/${L}/LC_MESSAGES"
  OUT_MO="$OUT_DIR/${CATALOG}.mo"
  if [[ -f "$PO_FILE" ]]; then
    mkdir -p "$OUT_DIR"
    echo "Compiling $PO_FILE -> $OUT_MO"
    msgfmt -o "$OUT_MO" "$PO_FILE"
  else
    echo "Skip $L (no $PO_FILE)" >&2
  fi
done

echo "OK: *.mo dans $LOCALE_DIR/*/LC_MESSAGES/${CATALOG}.mo"
