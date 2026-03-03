
# NHL Scores (Plasma 6 Applet)

Live NHL scores for Plasma 6. English is the source language. French is provided via gettext (`.po` → `.mo`).

## Install (local user)
```bash
kpackagetool6 --type Plasma/Applet --install .
# or upgrade
kpackagetool6 --type Plasma/Applet --upgrade .
```

## Translations
We use **KI18n** in QML via `i18n()` and ship a `translate/` helper. Build the French catalog:
```bash
cd translate
./build.sh
```
This will produce and install `~/.local/share/locale/fr/LC_MESSAGES/org.dany.nhlscores.mo`.

See KDE developer docs: i18n in Plasma widgets.\[1]

## License
GPL-3.0-or-later © Dany Martineau

[1]: https://develop.kde.org/docs/plasma/widget/translations-i18n/
