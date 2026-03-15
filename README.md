# NHL Scores — Plasma 6 Applet

> **English** | [Français](#français)

A real-time NHL scores applet for KDE Plasma 6. Displays live scores, schedules, standings, player stats, team hubs, league leaders, and playoff information directly in your panel or desktop.

![Version](https://img.shields.io/badge/version-4.0.0-blue)
![Plasma](https://img.shields.io/badge/Plasma-6-informational)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green)

---

## Features

- **Live scores** — real-time score updates with period, clock, and intermission countdown
- **Power play indicator** — PP / 5v3 / 4v4 / 3v3 badge with team color, empty net 🥅 detection
- **Penalty box** — active penalties with player name, number and time remaining
- **Game detail popup** — logos, scores, shots on goal, goals by period with scorers and assists, team stats, probable goalies, points leaders, series score in playoff mode
- **Team hub** — click any team logo or badge to open a full team page: record, standings position, head coach, last 5 results, next game, with links to schedule and stats
- **Team schedule & stats** — full season schedule and player/goalie statistics per team
- **Wild Card standings** — clickable standings with playoff cutoff separator; click any team to open their hub
- **League leaders** — top 10 per category: Points, Goals, Assists, PIM, Wins, Shutouts, GAA, SV%; colored team badges and rank highlights
- **Full day view** — click a date separator to see all games for that day (not just followed teams), with live scores, periods and final results
- **Playoff mode** — automatic detection; series score, round label, game number, and full bracket view via 🏆 button
- **Goal notification** — sound (siren) + visual banner in the favorite team's colors on every goal; no external install required
- **Three display modes** (panel only):
  - *Score below* — uniform cards with team badges, score and status
  - *Score next to name* — compact inline row layout
  - *Ultra-compact* — colored dots with team initial and score only
- **Date group separators** — upcoming games grouped by date with clickable `|DD/MM|` markers
- **Team color gradients** — subtle background gradients using each team's official colors
- **Colored popup separators** — horizontal dividers use a team color gradient
- **Desktop widget** — enriched card view with clickable date separators, Standings and Leaders buttons
- **Vertical panel** — stacked tile layout adapts automatically
- **French translation** — full `fr.po` with 136 entries

---

## Requirements

- KDE Plasma 6
- Qt 6 / QML
- Internet connection (NHL public API)

---

## Installation

### From .plasmoid file

```bash
kpackagetool6 -t Plasma/Applet -i org.dany.nhlscores-4.0.plasmoid
```

### From source

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
kpackagetool6 -t Plasma/Applet -i .
```

### Update an existing installation

```bash
kpackagetool6 -t Plasma/Applet -u org.dany.nhlscores-4.0.plasmoid
```

---

## Sound Notifications

The goal siren is bundled inside the plasmoid (`contents/sounds/siren.ogg`) and plays via Qt Multimedia — no external installation required. Simply select your favorite team in **General → Notifications → Sound notification for team**.

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
| Sound notification for team | Favorite team for goal siren notification |

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
| `/v1/score/{date}` | All games for a specific date (day view) |
| `/v1/scoreboard/{date}` | Scores, game status, clock |
| `/v1/gamecenter/{id}/landing` | Goals, stats, ice surface (PP/penalties) |
| `/v1/gamecenter/{id}/play-by-play` | Live clock, intermission time |
| `/v1/standings/now` | Wild Card standings, team records |
| `/v1/club-schedule-season/{team}/now` | Team schedule |
| `/v1/club-stats/{team}/now` | Team player statistics |
| `/v1/skater-stats-leaders/current` | League skater leaders |
| `/v1/goalie-stats-leaders/current` | League goalie leaders |
| `/v1/playoff-bracket/now` | Playoff bracket |

---

## License

GPL-3.0-or-later © Dany Martineau

---
---

# Français

> [English](#nhl-scores--plasma-6-applet) | **Français**

Un applet de scores NHL en temps réel pour KDE Plasma 6. Affiche les scores en direct, les calendriers, le classement, les statistiques des joueurs, les hubs d'équipe, les meneurs de la ligue et les informations sur les séries directement dans votre panneau ou sur votre bureau.

---

## Fonctionnalités

- **Scores en direct** — mises à jour en temps réel avec période, chronomètre et compte à rebours d'entracte
- **Indicateur d'avantage numérique** — pastille PP / 5v3 / 4v4 / 3v3 avec couleur d'équipe, détection du filet désert 🥅
- **Boîte de punition** — punitions actives avec nom du joueur, numéro et temps restant
- **Popup de détail de match** — logos, scores, tirs au but, buts par période avec buteurs et passeurs, statistiques d'équipe, gardiens probables, meneurs de points, score de série en mode éliminatoires
- **Hub d'équipe** — cliquez sur n'importe quel logo ou pastille pour ouvrir une page complète : fiche, position au classement, entraîneur, 5 derniers résultats, prochain match, liens vers le calendrier et les stats
- **Calendrier et stats d'équipe** — calendrier complet de la saison et statistiques des joueurs/gardiens par équipe
- **Classement Wild Card** — classement cliquable avec séparateur de qualification aux séries; cliquer sur une équipe ouvre son hub
- **Meneurs de la ligue** — top 10 par catégorie : Points, Buts, Passes, PUN, Victoires, Blanchissages, MOY, %ARR; pastilles d'équipe colorées et rang mis en évidence
- **Vue journée complète** — cliquer sur un séparateur de date affiche tous les matchs de cette journée (pas seulement les équipes suivies), avec scores en direct, périodes et résultats finaux
- **Mode séries éliminatoires** — détection automatique; score de série, ronde, numéro de match et bracket complet via le bouton 🏆
- **Notification de but** — son (sirène) + bannière visuelle aux couleurs de l'équipe favorite à chaque but; aucune installation externe requise
- **Trois modes d'affichage** (panneau seulement) :
  - *Score en dessous* — cartes uniformes avec pastilles d'équipe, score et statut
  - *Score à côté du nom* — disposition en rangée compacte
  - *Ultra-compact* — points colorés avec initiale et score seulement
- **Séparateurs de dates cliquables** — les parties à venir sont regroupées par date avec des marqueurs `|JJ/MM|`
- **Dégradés aux couleurs d'équipe** — arrière-plans subtils utilisant les couleurs officielles de chaque équipe
- **Séparateurs colorés dans les popups** — les séparateurs horizontaux utilisent un dégradé aux couleurs des équipes
- **Widget bureau** — vue enrichie en cartes avec séparateurs de dates cliquables, boutons Classement et Meneurs
- **Panneau vertical** — disposition en tuiles empilées adaptée automatiquement
- **Traduction française** — `fr.po` complet avec 136 entrées

---

## Prérequis

- KDE Plasma 6
- Qt 6 / QML
- Connexion Internet (API publique NHL)

---

## Installation

### Depuis un fichier .plasmoid

```bash
kpackagetool6 -t Plasma/Applet -i org.dany.nhlscores-4.0.plasmoid
```

### Depuis les sources

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
kpackagetool6 -t Plasma/Applet -i .
```

### Mettre à jour une installation existante

```bash
kpackagetool6 -t Plasma/Applet -u org.dany.nhlscores-4.0.plasmoid
```

---

## Notifications sonores

La sirène de but est incluse dans le plasmoid (`contents/sounds/siren.ogg`) et joue via Qt Multimedia — aucune installation externe requise. Sélectionnez simplement votre équipe favorite dans **Général → Notifications → Notification sonore pour l'équipe**.

---

## Traductions

L'applet utilise **KI18n** via des appels `i18n()` en QML. L'anglais est la langue source. Le français est fourni via gettext (`.po` → `.mo`).

### Compiler le catalogue français

```bash
cd translate
./build.sh
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
| Durée du clignotement de but | Durée de l'animation lors d'un but (0 = désactivé) |
| Notification sonore pour l'équipe | Équipe favorite pour la sirène de but |

### Onglet Affichage
| Paramètre | Description |
|---|---|
| Disposition du score | Score en dessous / Score à côté / Ultra-compact (panneau seulement) |
| Mode de date | Fuseau horaire local ou fuseau de l'aréna |
| Couleurs des pastilles | Couleurs personnalisées pour les pastilles EN DIRECT / À VENIR / FINAL |
| Afficher suffixe Prol./TB | Afficher Prol. ou TB dans la pastille de statut |
| Afficher l'heure des parties à venir | Montrer l'heure de début sous la pastille |

---

## Sources de données

Toutes les données proviennent de l'API publique officielle NHL (`api-web.nhle.com`) :

| Endpoint | Utilisation |
|---|---|
| `/v1/score/{date}` | Tous les matchs d'une journée (vue journée) |
| `/v1/scoreboard/{date}` | Scores, statut des matchs, chronomètre |
| `/v1/gamecenter/{id}/landing` | Buts, stats, surface de glace (AN/punitions) |
| `/v1/gamecenter/{id}/play-by-play` | Chronomètre en direct, temps d'entracte |
| `/v1/standings/now` | Classement Wild Card, fiches d'équipe |
| `/v1/club-schedule-season/{team}/now` | Calendrier d'équipe |
| `/v1/club-stats/{team}/now` | Statistiques des joueurs |
| `/v1/skater-stats-leaders/current` | Meneurs patineurs |
| `/v1/goalie-stats-leaders/current` | Meneurs gardiens |
| `/v1/playoff-bracket/now` | Bracket des séries |

---

## Licence

GPL-3.0-or-later © Dany Martineau
