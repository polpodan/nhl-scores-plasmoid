# NHL Scores — Plasma 6 Applet

> **English** | [Français](#français)

A real-time NHL scores applet for KDE Plasma 6. Displays live scores, schedules, standings, player stats, team hubs, league leaders, and playoff information directly in your panel or desktop.

![Version](https://img.shields.io/badge/version-5.2-blue)
![Plasma](https://img.shields.io/badge/Plasma-6-informational)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green)

---

## Features

- **Live scores** — real-time score updates with period, clock, and intermission countdown
- **Custom Team Display** — choose between classic **colored badges (Pastilles)** or **official team logos** throughout the applet
- **Local Logo Storage** — all 33 team logos are stored locally for instant loading and offline support
- **Smart Color Adaptation** — away teams automatically switch to their secondary color when playing an opponent with similar colors (e.g., NJD vs MTL)
- **High-Definition Graphics** — optimized SVG rendering (`sourceSize`) for crisp logos on all screen resolutions (HiDPI)
- **Goal highlights** — 🎬 Watch goal videos directly from the hub via official NHL Brightcove player
- **Advanced Pre-game Stats** — comprehensive seasonal comparisons: PP%, PK%, Faceoff%, GF/G, and GA/G
- **Power play indicator** — PP / 5v3 / 4v3 badge with team color and **active penalty clock**
- **Penalty box** — active penalties with player name, number and time remaining
- **Team hub** — click any team logo to open a full team page: record, standings, head coach, last 5 results, next game, and season calendar
- **Team schedule & stats** — full season schedule and statistics per team
- **Wild Card standings** — clickable standings with playoff cutoff separator
- **League leaders** — top 10 per category: Points, Goals, Assists, PIM, Wins, Shutouts, GAA, SV%
- **Goal notification** — **Team-specific goal songs** + visual banner in the favorite team's colors
- **Player search** — 🔍 Search any NHL player (active or retired) by name
- **Multi-language support** — available in 8 languages: EN, FR, RU, FI, SV, DE, CS, SK
- **Vertical panel** — stacked tile layout adapts automatically to narrow panels

---

## Installation

### From source

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
# Download team logos
./download_logos.sh
# Install
kpackagetool6 -t Plasma/Applet -i .
```

### Update an existing installation

```bash
kpackagetool6 -t Plasma/Applet -u .
```

---

## Configuration

### Display tab
| Setting | Description |
|---|---|
| Icon style | Switch between Pastilles (badges) and official Logos |
| Score layout | Score below / Score next to name / Ultra-compact |
| Date mode | Local timezone or venue (arena) timezone |
| Status badge colors | Custom colors for LIVE / UPCOMING / FINAL states |

---

## Data Sources

All data is fetched from the official NHL public API (`api-web.nhle.com`):

| Endpoint | Used for |
|---|---|
| `/v1/scoreboard/{date}` | Scores, game status, clock |
| `/v1/gamecenter/{id}/landing` | Goals, Probable goalies, Player comparison |
| `/v1/gamecenter/{id}/right-rail` | Season stats comparison, Season series results, Coaches |
| `/v1/gamecenter/{id}/play-by-play` | Live clock, Situation code (PP/EN) |
| `/v1/standings/now` | Standings, Team records |

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
- **Personnalisation d'équipe** — choisissez entre les **pastilles colorées** classiques ou les **logos officiels** des équipes partout dans l'applet
- **Stockage local des logos** — les 33 logos d'équipes sont stockés localement pour un chargement instantané et une économie de bande passante
- **Adaptation intelligente des couleurs** — les équipes visiteuses basculent automatiquement sur leur couleur secondaire en cas de conflit (ex: NJD vs MTL)
- **Graphismes Haute Définition** — rendu SVG optimisé (`sourceSize`) pour des logos nets sur toutes les résolutions (HiDPI)
- **Faits saillants (vidéo)** — 🎬 Visionnez les buts directement depuis le hub via le lecteur officiel Brightcove de la NHL
- **Stats d'avant-match avancées** — comparaisons saisonnières complètes : % AN, % IN, % Mises au jeu, BP/MJ et BC/MJ
- **Indicateur d'avantage numérique** — pastille PP / 5v3 / 4v3 avec couleur d'équipe et **chrono de punition actif**
- **Hub d'équipe** — cliquez sur n'importe quel logo pour ouvrir une page complète : fiche, classement, entraîneur, 5 derniers résultats et calendrier complet
- **Calendrier et stats d'équipe** — calendrier complet de la saison et statistiques par équipe
- **Classement Wild Card** — classement cliquable avec séparateurs de qualification aux séries
- **Meneurs de la ligue** — top 10 par catégorie : Points, Buts, Passes, PUN, Victoires, Blanchissages, MOY, %ARR
- **Notification de but** — **Chansons de but officielles** par équipe + bannière visuelle aux couleurs de l'équipe
- **Recherche de joueurs** — bouton 🔍 pour chercher n'importe quel joueur NHL (actif ou retraité)
- **Support multilingue** — disponible en 8 langues : EN, FR, RU, FI, SV, DE, CS, SK
- **Panneau vertical** — disposition adaptée automatiquement aux panneaux étroits

---

## Installation

### Depuis les sources

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
# Télécharger les logos d'équipe
chmod +x download_logos.sh
./download_logos.sh
# Installer
kpackagetool6 -t Plasma/Applet -i .
```

---

## Configuration

### Onglet Affichage
| Paramètre | Description |
|---|---|
| Style d'icône | Basculer entre les Pastilles et les Logos officiels |
| Disposition du score | Score en dessous / Score à côté / Ultra-compact |
| Mode de date | Fuseau horaire local ou fuseau de l'aréna |
| Couleurs des pastilles | Couleurs personnalisées pour les pastilles de statut |

---

## Licence

GPL-3.0-or-later © Dany Martineau
