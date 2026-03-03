
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"/..
mkdir -p translate
# Extract from QML using gettext, looking for i18n()/i18np()
find contents -name '*.qml' | xargs xgettext   --from-code=UTF-8 -L JavaScript   -k i18n -k i18np:1,2   -o translate/template.pot
# Merge into fr.po
if [ -f translate/fr.po ]; then
  msgmerge --update --backup=off translate/fr.po translate/template.pot
else
  msginit --no-translator -i translate/template.pot -o translate/fr.po --locale=fr
fi
printf '
Updated translate/fr.po.
'
