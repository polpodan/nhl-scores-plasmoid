
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# Compile French catalog and install to user locale dir
mkdir -p ~/.local/share/locale/fr/LC_MESSAGES
msgfmt fr.po -o ~/.local/share/locale/fr/LC_MESSAGES/org.dany.nhlscores.mo
printf '
Installed to ~/.local/share/locale/fr/LC_MESSAGES/org.dany.nhlscores.mo
'
