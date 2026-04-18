# NHL Scores — Plasma 6 Applet

> **English** | [Français](#français)

A real-time NHL scores applet for KDE Plasma 6. Displays live scores, schedules, standings, player stats, team hubs, league leaders, and playoff information directly in your panel or desktop.

![Version](https://img.shields.io/badge/version-6.0.0-blue)
![Plasma](https://img.shields.io/badge/Plasma-6-informational)
![License](https://img.shields.io/badge/license-GPL--3.0--or--later-green)

---

## Features

- **Live scores** — real-time score updates with period, clock, and intermission countdown.
- **Deep Historical Database** — 🏛️ Browse League Leaders and Team Statistics for any season back to **1917-18**.
- **Playoff Integration** — Detailed Playoff Bracket with win tracking and "Regular Season vs Playoffs" toggles for all statistics.
- **Stanley Cup Trophy Case** — 🏆 View each team's championship history directly in their Team Hub.
- **Dynamic Time Window** — ⏱️ Range Slider to set a custom display interval from **-60h to +120h** relative to current time.
- **Intelligent Caching** — faster load times and reduced bandwidth with persistent storage for scores and player data.
- **Offline Mode** — 󰖪 Automatic detection of network loss with fallback to last known data.
- **Custom Team Display** — choose between classic **colored badges (Pastilles)** or **official team logos**.
- **Advanced Color Engine** — automatically resolves color conflicts between teams (e.g., TOR vs. TBL) and adapts text contrast for 100% legibility.
- **Goal highlights** — 🎬 Watch goal videos directly via official NHL player.
- **Team hub** — click any team logo to open a full team page: record, standings, championships, player stats, and season calendar.
- **Player search** — 🔍 Search any NHL player (active or retired) by name.
- **Multi-language support** — fully localized in 8 languages: EN, FR, RU, FI, SV, DE, CS, SK.

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

---
---

# Français

> [English](#nhl-scores--plasma-6-applet) | **Français**

Un applet de scores NHL en temps réel pour KDE Plasma 6. Affiche les scores en direct, les calendriers, le classement, les statistiques des joueurs, les hubs d'équipe, les meneurs de la ligue et les informations sur les séries directement dans votre panneau ou sur votre bureau.

---

## Fonctionnalités

- **Scores en direct** — mises à jour en temps réel avec période, chronomètre et compte à rebours d'entracte.
- **Base de données historique** — 🏛️ Consultez les meneurs de la ligue et les statistiques d'équipe pour n'importe quelle saison depuis **1917-18**.
- **Intégration des séries** — Tableau complet des séries éliminatoires avec suivi des victoires et bascule "Saison régulière vs Séries" pour toutes les statistiques.
- **Palmarès de la Coupe Stanley** — 🏆 Affichez l'historique des championnats de chaque équipe directement dans leur hub d'équipe.
- **Fenêtre temporelle dynamique** — ⏱️ Curseur pour définir un intervalle d'affichage personnalisé de **-60h à +120h**.
- **Mise en cache intelligente** — chargement accéléré et économie de bande passante grâce au stockage persistant des données.
- **Mode Hors-ligne** — 󰖪 Détection automatique des pertes réseau avec basculement sur les dernières données connues.
- **Personnalisation d'équipe** — choisissez entre les **pastilles colorées** classiques ou les **logos officiels**.
- **Moteur de couleurs avancé** — résout automatiquement les conflits de couleurs entre équipes (ex: TOR vs TBL) et adapte le contraste du texte pour une lisibilité parfaite.
- **Faits saillants (vidéo)** — 🎬 Visionnez les buts directement depuis le hub via le lecteur officiel de la NHL.
- **Hub d'équipe** — cliquez sur n'importe quel logo pour ouvrir une page complète : fiche, classement, championnats, statistiques des joueurs et calendrier.
- **Recherche de joueurs** — bouton 🔍 pour chercher n'importe quel joueur NHL (actif ou retraité).
- **Support multilingue** — entièrement traduit en 8 langues : EN, FR, RU, FI, SV, DE, CS, SK.

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
