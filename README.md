# NHL Scores — Plasma 6 Applet

> **English** | [Français](#français)

A real-time NHL scores applet for KDE Plasma 6. Displays live scores, schedules, standings, player stats, team hubs, league leaders, and playoff information directly in your panel or desktop.

![Version](https://img.shields.io/badge/version-5.4-blue)
![Plasma](https://img.shields.io/badge/Plasma-6-informational)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green)

---

## Features

- **Live scores** — real-time score updates with period, clock, and intermission countdown.
- **Dynamic Time Window** — ⏱️ New Range Slider to set a custom display interval from **-60h to +120h** relative to current time.
- **Intelligent Caching** — faster load times and reduced bandwidth with persistent storage for scores and player data.
- **Offline Mode** — 󰖪 Automatic detection of network loss with fallback to last known data.
- **Custom Team Display** — choose between classic **colored badges (Pastilles)** or **official team logos**.
- **Advanced Color Engine** — automatically resolves color conflicts between teams (e.g., TOR vs. TBL) and adapts text contrast for 100% legibility.
- **Goal highlights** — 🎬 Watch goal videos directly via official NHL player.
- **Team hub** — click any team logo to open a full team page: record, standings, head coach, last 5 results, next game, and season calendar.
- **Player search** — 🔍 Search any NHL player (active or retired) by name.
- **Vertical panel support** — layout adapts automatically to narrow or wide panels.
- **Multi-language support** — available in 8 languages: EN, FR, RU, FI, SV, DE, CS, SK.

---

## Installation

### Easy Installation (Recommended)

The easiest way to install or update the applet is to use the included install script:

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
chmod +x install.sh
./install.sh
```
*This script will automatically download team logos and install/update the applet for the current user.*

### Manual Installation

If you prefer to do it manually:

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
# 1. Download team logos (required for Logo mode)
chmod +x download_logos.sh
./download_logos.sh
# 2. Install using KDE tools
kpackagetool6 -t Plasma/Applet -i .
```

### Update an existing installation

```bash
kpackagetool6 -t Plasma/Applet -u .
```

---

## Configuration

### General tab
| Setting | Description |
|---|---|
| Favorite teams | Select teams to follow in the main view. |
| Time interval | Slider to adjust how many hours of past/future games to show. |
| Notifications | Toggle goal sounds and system alerts. |

### Display tab
| Setting | Description |
|---|---|
| Icon style | Switch between Pastilles (badges) and official Logos. |
| Score layout | Score below / Score next to name / Ultra-compact. |
| Date mode | Local timezone or venue (arena) timezone. |
| Status colors | Custom colors for LIVE / UPCOMING / FINAL states. |

---

## Data Sources

All data is fetched from the official NHL public API (`api-web.nhle.com` and `api.nhle.com`).

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

- **Scores en direct** — mises à jour en temps réel avec période, chronomètre et compte à rebours d'entracte.
- **Fenêtre temporelle dynamique** — ⏱️ Nouveau curseur pour définir un intervalle d'affichage personnalisé de **-60h à +120h**.
- **Mise en cache intelligente** — chargement accéléré et économie de bande passante grâce au stockage persistant des données.
- **Mode Hors-ligne** — 󰖪 Détection automatique des pertes réseau avec basculement sur les dernières données connues.
- **Personnalisation d'équipe** — choisissez entre les **pastilles colorées** classiques ou les **logos officiels**.
- **Moteur de couleurs avancé** — résout automatiquement les conflits de couleurs entre équipes (ex: TOR vs TBL) et adapte le contraste du texte pour une lisibilité parfaite.
- **Faits saillants (vidéo)** — 🎬 Visionnez les buts directement depuis le hub via le lecteur officiel de la NHL.
- **Hub d'équipe** — cliquez sur n'importe quel logo pour ouvrir une page complète : fiche, classement, entraîneur, derniers résultats et calendrier.
- **Recherche de joueurs** — bouton 🔍 pour chercher n'importe quel joueur NHL (actif ou retraité).
- **Support du panneau vertical** — la disposition s'adapte automatiquement aux panneaux étroits ou larges.
- **Support multilingue** — disponible en 8 langues : EN, FR, RU, FI, SV, DE, CS, SK.

---

## Installation

### Installation simplifiée (Recommandé)

Utilisez le script d'installation inclus pour installer ou mettre à jour l'applet :

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
chmod +x install.sh
./install.sh
```
*Ce script télécharge automatiquement les logos et installe/met à jour l'applet pour l'utilisateur courant.*

### Installation manuelle

```bash
git clone https://github.com/polpodan/nhl-scores-plasmoid.git
cd nhl-scores-plasmoid
# 1. Télécharger les logos (requis pour le mode Logos)
chmod +x download_logos.sh
./download_logos.sh
# 2. Installer via les outils KDE
kpackagetool6 -t Plasma/Applet -i .
```

---

## Configuration

### Onglet Général
| Paramètre | Description |
|---|---|
| Équipes favorites | Sélectionnez les équipes à suivre dans la vue principale. |
| Intervalle temporel | Ajustez le nombre d'heures de matchs passés/futurs à afficher. |
| Notifications | Activez les sons de buts et les alertes système. |

### Onglet Affichage
| Paramètre | Description |
|---|---|
| Style d'icône | Basculer entre les Pastilles et les Logos officiels. |
| Disposition | Score en dessous / Score à côté / Ultra-compact. |
| Mode de date | Fuseau horaire local ou fuseau de l'aréna. |
| Couleurs | Couleurs personnalisées pour les pastilles de statut. |

---

## Licence

GPL-3.0-or-later © Dany Martineau
