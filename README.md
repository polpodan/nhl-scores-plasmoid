# NHL Scores (Plasma 6 Applet)

Live NHL scores for Plasma 6. English is the source language. French is
provided via gettext (`.po` → `.mo`).

## Install (local user)

```bash
kpackagetool6 -t Plasma/Applet -i org.dany.nhlscores-3.0.plasmoid
```
## Translations

We use **KI18n** in QML via `i18n()` and ship a `translate/` helper. Build the
French catalog:

```bash
cd translate
./build.sh
```
This will produce and install 
`~/.local/share/locale/fr/LC_MESSAGES/plasma_applet_org.dany.nhlscores.mo`.

See KDE developer docs: i18n in Plasma widgets.\[1]

## Icon

You may place
~/.local/share/plasma/plasmoids/org.dany.nhlscores/contents/icons/org.dany.nhlsc
res.svg into ~/.local/share/icons/hicolor/scalable/apps/ with these commands:

```bash
mkdir -p ~/.local/share/icons/hicolor/scalable/apps/
cp ~/.local/share/plasma/plasmoids/org.dany.nhlscores/contents/icons/org.dany.nhlscores.svg ~/.local/share/icons/hicolor/scalable/apps/
```
## License

GPL-3.0-or-later © Dany Martineau

