# NHL Scores — Plasma 6 Applet

> **English** | [Français](#français)

A real-time NHL scores applet for KDE Plasma 6. Displays live scores, schedules, standings, player stats, and team information directly in your panel or desktop.

![Version](https://img.shields.io/badge/version-3.3.0-blue)
![Plasma](https://img.shields.io/badge/Plasma-6-informational)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green)

---

## Features

- **Live scores** — real-time score updates with period, clock, and intermission countdown
- **Power play indicator** — PP / 4v4 / 3v3 badge with team color, empty net 🥅 detection
- **Penalty box** — active penalties with player name, number and time remaining
- **Game detail popup** — logos, scores, shots on goal, goals by period with scorers and assists, team stats, probable goalies, points leaders
- **Team schedule & stats** — click any team badge to view their schedule and full player/goalie statistics
- **Wild Card standings** — clickable standings with playoff cutoff separator
- **Three display modes**:
  - *Score below* — uniform cards with team badges, score and status
  - *Score next to name* — compact inline row layout
  - *Ultra-compact* — colored dots with team initial and score only
- **Date group separators** — upcoming games grouped by date with `|DD/MM|` markers
- **Team color gradients** — subtle background gradients using each team's official colors
- **Colored popup separators** — horizontal dividers in the detail popup use a team color gradient
- **Desktop widget** — enriched card view when placed on the desktop
- **Vertical panel** — stacked tile layout adapts automatically
- **French translation** — full `fr.po` with 170 entries

---

## Requirements

- KDE Plasma 6
- Qt 6 / QML
- Internet connection (NHL public API)

---

## Installation

### From .plasmoid file

```bash
kpackagetool6 -t Plasma/Applet -i org.dany.nhlscores-3.3.plasmoid
```

### From source

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
kpackagetool6 -t Plasma/Applet -i .
```

### Update an existing installation

```bash
kpackagetool6 -t Plasma/Applet -u org.dany.nhlscores-3.3.plasmoid
```

---

## Translations

The applet uses **KI18n** via `i18n()` calls in QML. English is the source language. French is provided via gettext (`.po` → `.mo`).

### Build the French catalog

```bash
cd translate
./build.sh
```

This produces and installs:
```
~/.local/share/locale/fr/LC_MESSAGES/plasma_applet_org.dany.nhlscores.mo
```

See [KDE developer docs: i18n in Plasma widgets](https://develop.kde.org/docs/plasma/widget/i18n/).

---

## Configuration

### General tab
| Setting | Description |
|---|---|
| Favorite teams | Filter to show only selected teams |
| Max games to display | Maximum number of game cards shown (1–20) |
| Days ahead | How many days of upcoming games to fetch (0–14) |
| Show yesterday's games | Include completed games from yesterday |
| Show games from two days ago | Include completed games from two days ago |
| Goal blink duration | Duration of score blink animation on goal (0 = disabled) |

### Display tab
| Setting | Description |
|---|---|
| Score layout | Score below / Score next to name / Ultra-compact (panel only) |
| Date mode | Local timezone or venue (arena) timezone |
| Status badge colors | Custom colors for LIVE / UPCOMING / FINAL badges |
| Show OT/SO suffix | Display OT or SO suffix in the status badge |
| Show upcoming game time | Show start time under the badge for upcoming games |

---

## Icon

Place the applet icon in the system icon theme for better integration:

```bash
mkdir -p ~/.local/share/icons/hicolor/scalable/apps/
cp ~/.local/share/plasma/plasmoids/org.dany.nhlscores/contents/icons/org.dany.nhlscores.svg \
   ~/.local/share/icons/hicolor/scalable/apps/
```

---

## Data Sources

All data is fetched from the official NHL public API (`api-web.nhle.com`):

| Endpoint | Used for |
|---|---|
| `/v1/scoreboard/{date}` | Scores, game status, clock |
| `/v1/gamecenter/{id}/landing` | Goals, stats, ice surface (PP/penalties) |
| `/v1/gamecenter/{id}/play-by-play` | Live clock, intermission time |
| `/v1/standings/now` | Wild Card standings |
| `/v1/club-schedule-season/{team}/now` | Team schedule |
| `/v1/club-stats/{team}/now` | Team player statistics |

---

## License

GPL-3.0-or-later © Dany Martineau

---
---

# Français

> [English](#nhl-scores--plasma-6-applet) | **Français**

Un applet de scores NHL en temps réel pour KDE Plasma 6. Affiche les scores en direct, les calendriers, le classement, les statistiques des joueurs et les informations d'équipe directement dans votre panneau ou sur votre bureau.

---

## Fonctionnalités

- **Scores en direct** — mises à jour en temps réel avec période, chronomètre et compte à rebours d'entracte
- **Indicateur d'avantage numérique** — pastille PP / 4v4 / 3v3 avec couleur d'équipe, détection du filet désert 🥅
- **Boîte de punition** — punitions actives avec nom du joueur, numéro et temps restant
- **Popup de détail de match** — logos, scores, tirs au but, buts par période avec buteurs et passeurs, statistiques d'équipe, gardiens probables, meneurs de points
- **Calendrier et stats d'équipe** — cliquez sur n'importe quelle pastille d'équipe pour voir son calendrier et ses statistiques complètes
- **Classement Wild Card** — classement cliquable avec séparateur de qualification aux séries
- **Trois modes d'affichage** :
  - *Score en dessous* — cartes uniformes avec pastilles d'équipe, score et statut
  - *Score à côté du nom* — disposition en rangée compacte
  - *Ultra-compact* — points colorés avec initiale et score seulement
- **Séparateurs de dates** — les parties à venir sont regroupées par date avec des marqueurs `|JJ/MM|`
- **Dégradés aux couleurs d'équipe** — arrière-plans subtils utilisant les couleurs officielles de chaque équipe
- **Séparateurs colorés dans les popups** — les séparateurs horizontaux du popup de détail utilisent un dégradé aux couleurs des équipes
- **Widget bureau** — vue enrichie en cartes lorsque placé sur le bureau
- **Panneau vertical** — disposition en tuiles empilées adaptée automatiquement
- **Traduction française** — `fr.po` complet avec 170 entrées

---

## Prérequis

- KDE Plasma 6
- Qt 6 / QML
- Connexion Internet (API publique NHL)

---

## Installation

### Depuis un fichier .plasmoid

```bash
kpackagetool6 -t Plasma/Applet -i org.dany.nhlscores-3.3.plasmoid
```

### Depuis les sources

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
kpackagetool6 -t Plasma/Applet -i .
```

### Mettre à jour une installation existante

```bash
kpackagetool6 -t Plasma/Applet -u org.dany.nhlscores-3.3.plasmoid
```

---

## Traductions

L'applet utilise **KI18n** via des appels `i18n()` en QML. L'anglais est la langue source. Le français est fourni via gettext (`.po` → `.mo`).

### Compiler le catalogue français

```bash
cd translate
./build.sh
```

Cela produit et installe :
```
~/.local/share/locale/fr/LC_MESSAGES/plasma_applet_org.dany.nhlscores.mo
```

---

## Configuration

### Onglet Général
| Paramètre | Description |
|---|---|
| Équipes favorites | Filtrer pour afficher uniquement les équipes sélectionnées |
| Nombre max de parties | Nombre maximum de cartes de matchs affichées (1–20) |
| Jours à venir | Nombre de jours de parties à venir à récupérer (0–14) |
| Afficher les parties d'hier | Inclure les parties terminées d'hier |
| Afficher les parties d'avant-hier | Inclure les parties terminées d'avant-hier |
| Durée du clignotement de but | Durée de l'animation de clignotement lors d'un but (0 = désactivé) |

### Onglet Affichage
| Paramètre | Description |
|---|---|
| Disposition du score | Score en dessous / Score à côté / Ultra-compact (panneau seulement) |
| Mode de date | Fuseau horaire local ou fuseau de l'aréna |
| Couleurs des pastilles | Couleurs personnalisées pour les pastilles EN DIRECT / À VENIR / FINAL |
| Afficher suffixe Prol./TB | Afficher Prol. ou TB dans la pastille de statut |
| Afficher l'heure des parties à venir | Montrer l'heure de début sous la pastille |

---

## Icône

Placez l'icône de l'applet dans le thème d'icônes système pour une meilleure intégration :

```bash
mkdir -p ~/.local/share/icons/hicolor/scalable/apps/
cp ~/.local/share/plasma/plasmoids/org.dany.nhlscores/contents/icons/org.dany.nhlscores.svg \
   ~/.local/share/icons/hicolor/scalable/apps/
```

---

## Sources de données

Toutes les données proviennent de l'API publique officielle NHL (`api-web.nhle.com`) :

| Endpoint | Utilisation |
|---|---|
| `/v1/scoreboard/{date}` | Scores, statut des matchs, chronomètre |
| `/v1/gamecenter/{id}/landing` | Buts, stats, surface de glace (AN/punitions) |
| `/v1/gamecenter/{id}/play-by-play` | Chronomètre en direct, temps d'entracte |
| `/v1/standings/now` | Classement Wild Card |
| `/v1/club-schedule-season/{team}/now` | Calendrier d'équipe |
| `/v1/club-stats/{team}/now` | Statistiques des joueurs |

---

## Licence

GPL-3.0-or-later © Dany Martineau
