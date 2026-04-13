#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"/..
mkdir -p translate

# Extract from QML and JS using gettext, looking for i18n variants
find contents -name '*.qml' -o -name '*.js' | xargs xgettext \
  --from-code=UTF-8 \
  -L JavaScript \
  --keyword=i18n \
  --keyword=i18np:1,2 \
  --keyword=i18nd:2 \
  --keyword=i18ndp:2,3 \
  --keyword=i18nc:1c,2 \
  --keyword=i18ncp:1c,2,3 \
  -o translate/template.pot

# Merge into fr.po
if [ -f translate/fr.po ]; then
  msgmerge --update --backup=off translate/fr.po translate/template.pot
else
  msginit --no-translator -i translate/template.pot -o translate/fr.po --locale=fr
fi
printf '\nUpdated translate/fr.po.\n'
