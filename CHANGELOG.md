# Changelog

## [5.1.0] - 2026-04-03

### Added
- **Multi-language Expansion:** Added support for 6 new languages (Russian, Finnish, Swedish, German, Czech, and Slovak) in addition to English and French.
- **Real-time Situation Indicators:** Live power play (PP, 5v3, 4v3) and empty net (🥅) indicators on game status badges.
- **Team-Specific Goal Songs:** The goal notification now plays official team-specific goal songs (if available in sounds directory) instead of a generic siren.
- **Multi-Team Sound Notifications:** Support for selecting multiple favorite teams to receive goal sound and visual banner alerts.
- **Enhanced Player Search:** Improved reliability with a fallback to the official NHL Stats API; now correctly finds both skaters and goalies.
- **Active Penalty Clock:** Live countdown of power play time remaining directly in the status badge.
- **Dynamic Situation Parsing:** Advanced parsing of NHL situation codes for accurate on-ice strength display.

### Fixed
- Fixed layout issues on extremely narrow vertical panels.
- Fixed missing statistics for some retired players in search results.
- Optimized API polling to reduce redundant data fetching during intermissions.
- Improved error handling for team-specific audio file loading.

## [5.0.0] - 2026-04-01

### Added
- **New Franchise Leaders Hub:** Access all-time franchise records (Points, Goals, Assists) directly from the Team Hub.
- **Active Player Highlighting:** Current NHL players are highlighted with a neon green color and an asterisk in historical lists.
- **Configurable History Depth:** New setting to display top 10, 20, or 50 franchise leaders.
- **Season Calendar Integration:** The team calendar is now directly embedded in the Team Hub for better navigation.
- **Multi-language Support:** Added support for 8 languages (en, fr, ru, fi, sv, de, cs, sk) including localized divisions and playoff rounds.
- **Visual Polish:** Added high-contrast stats with black outlines and subtle zebra striping in tables for improved readability.
- **Interactive Cursors:** Mouse cursor now changes to a hand pointer on all clickable elements.

### Changed
- **Architecture Refactor:** Centralized API logic and state management for better performance and reliability.
- **Redesigned Match Hub:** Clean, centered layout with 150x150 team logos and improved information hierarchy.
- **Enhanced Team Hub:** Large 200x200 logos and perfectly centered action buttons.
- **Professional Player Profiles:** Centered layout, automatic age calculation, and bold highlighting for NHL career stats.
- **Navigation System:** Implemented a robust "activeView" system to prevent UI overlaps and fix "Back" button behavior.

### Fixed
- Fixed layout issues on vertical panels (narrow widths like 42px).
- Fixed "undefined" string appearing in player positions.
- Fixed goalie statistics precision (GAA and SV% now always show 3 decimals).
- Fixed API 404 errors by switching to the new official NHL Stats backend.
- Fixed various QML syntax errors and property initialization bugs.
- Fixed irregular row coloring in player history by filtering data at the source.
