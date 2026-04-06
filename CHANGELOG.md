# Changelog

## [5.2.0] - 2026-04-05

### Added
- **Team Logo Customization:** New option in Display settings to choose between classic colored badges (Pastilles) and team logos throughout the applet.
- **Local Logo Storage:** Team logos are now bundled locally within the plasmoid for instant loading and offline support.
- **Smart Color Adaptation:** Implemented a conflict detection system for teams with similar colors (e.g., NJD vs MTL). The away team automatically switches to its secondary color for better visual distinction.
- **SVG Rendering Optimization:** Added `sourceSize` support for all team logos, ensuring pixel-perfect sharpness on HiDPI and small scales.
- **Contrast-Aware Themes:** Automatically switches between `_light` and `_dark` logo variants based on Plasma theme brightness.
- **Readability Engine:** Dynamically adjusts text colors (scores, names) based on both team colors and theme background to ensure 100% legibility on any theme.
- **Advanced Pre-Game Hub:** Integrated the NHL `right-rail` API to display comprehensive seasonal comparisons: PP%, PK%, Faceoff%, GF/G, and GA/G.
- **Goal Video Highlights:** Watch goal highlights directly via the official NHL Brightcove player using the new play button next to each goal.
- **Unified Preview Layout:** Completely redesigned the pre-game hub layout for better logical flow and visual consistency.
- **Improved Panel Alignment:** Forced vertical centering and fixed heights for status badges to ensure a perfectly aligned panel layout.

### Fixed
- **Flickering Issues:** Fixed a bug where season series info would disappear after a few seconds in the match hub.
- **Responsive Sizing:** Decoupled logo sizes from font scales to maintain a compact panel width when using logos.
- **Filtered Situations:** The panel now only displays high-impact situations (PP, 5v3, 4v3), while the full hub maintains complete information (EN, 3v3, 4v4).
- **Desktop Widget Fixes:** Added click interactivity to date separators on the desktop representation.
- **Localization:** Updated all 8 supported languages with new strings for 5.2 features.

## [5.1.0] - 2026-04-03

### Added
- **Multi-language Expansion:** Added support for 6 new languages (Russian, Finnish, Swedish, German, Czech, and Slovak) in addition to English and French.
- **Real-time Situation Indicators:** Live power play (PP, 5v3, 4v3) and empty net (🥅) indicators on game status badges.
- **Team-Specific Goal Songs:** The goal notification now plays official team-specific goal songs (if available in sounds directory).
- **Multi-Team Sound Notifications:** Support for selecting multiple favorite teams for goal alerts.
- **Future Calendar Data:** The main calendar now displays the number of scheduled games for future dates.

### Fixed
- **Reliable Refresh:** Fixed the manual refresh button in the match hub to properly sync scores, clock, and all game details.
- **Enhanced Player Search:** Improved reliability with a fallback to the official NHL Stats API for all players.
- **Active Penalty Clock:** Fixed live countdown of power play time in the status badge.
- **Layout Adjustments:** Optimized team logo sizes and fixed narrow vertical panel layouts.
- Optimized API polling to reduce redundant data fetching.

## [5.0.0] - 2026-04-01

### Added
- **New Franchise Leaders Hub:** Access all-time franchise records (Points, Goals, Assists) directly from the Team Hub.
- **Active Player Highlighting:** Current NHL players are highlighted with a neon green color and an asterisk in historical lists.
- **Custom Status Badge Colors:** Users can now customize the background colors for LIVE, UPCOMING, and FINAL game states in the settings.
- **OT/SO Suffix Control:** Toggle to show or hide the OT/SO labels in the status badge for a cleaner look.
- **Team-Specific Gradients:** Subtle background gradients in the game hub using official team colors for better immersion.
- **Advanced Standings Logic:** Clickable standings with automatic Wild Card detection and playoff cutoff markers.
