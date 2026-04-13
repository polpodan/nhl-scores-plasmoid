# Changelog

All notable changes to this project will be documented in this file.

## [5.4.0] - 2026-04-12

### Added
- **Sliding Time Interval Selector:** Replaced static "Past days" options with a precision Range Slider in General settings. Users can now set a custom window from **-60h to +120h** (6h steps) relative to current time.
- **Intelligent Caching System:** Implemented persistent storage for scores, standings, and player profiles. Data is now saved across sessions using Plasma configuration.
- **Robust Offline Mode:** Automatic detection of network failures with transparent fallback to cached data. Added a discrete "Offline" indicator (󰖪) in the panel and header.
- **Advanced Color Collision Engine:** Dynamic detection of teams with similar primary/secondary colors (e.g., Toronto vs. Tampa Bay). The engine now forces contrast adjustments and secondary color usage to ensure both teams remain distinct.
- **Internal Badge Contrast:** Text color inside team badges now calculates contrast based on the **actual rendered color** of the badge, preventing "invisible text" issues on adapted backgrounds.
- **Detailed Leader Stats:** Added "G", "A", or "PTS" suffixes to the pre-game leaders list for immediate statistical context.

### Changed
- **Modular Architectural Refactor:** Deconstructed the monolithic `DetailView.qml` into 6 specialized sub-components (`DetailHeader`, `MatchPreview`, `MatchStats`, `GoalsList`, etc.) for significantly improved maintainability.
- **Performance UI Updates:** Replaced full model resets (`.clear()`) with a granular update pattern. The applet now only updates modified properties, eliminating UI flickering and reducing CPU usage.
- **Smart Franchise Resolution:** Replaced team IDs with official NHL Franchise IDs, ensuring accurate historical records for relocated teams (e.g., Jets/Thrashers, Avalanche/Nordiques).
- **Timezone-Aware Calendar:** Fixed a date-offset bug where Western Conference games started after midnight UTC would appear on the wrong day in the season calendar.

### Fixed
- **Type Safety in Logic:** Fixed `ReferenceError` and `TypeError` exceptions caused by strict Plasma 6 QML/JS isolation and color object handling.
- **Desktop Interactivity:** Ensured clicking any part of the desktop widget (including logos) in compact mode correctly opens the match detail popup.
- **Visual Alignment:** Corrected centering and overflow issues in the "Compact Desktop" representation.

## [5.3.0] - 2026-04-08

### Added
- **Official NHL Standings Indicators:** Added support for official clinch indicators (**x**, **y**, **z**) and elimination markers (**E**) across all standings modes.
- **Standings Legend:** Centered legend at the bottom of the standings view explaining all qualification and elimination markers.
- **Smart Morning View:** Refined logic to show yesterday's games until 12:00 PM today even with "Past days" set to 0.
- **Enhanced Player Playoff Stats:** Career playoff history is now fully calculated and displayed in a dedicated tab.
- **Unified Vertical Alignment:** Forced perfect horizontal baseline for all panel elements in both Inline and Stacked modes.

### Fixed
- **Horizontal Scrolling:** Eliminated the need for horizontal scrolling in the Playoff Bracket via a new vertical tree layout.
- **Color Conflicts:** Fixed Florida (FLA) vs Montreal (MTL) and New Jersey (NJD) vs Montreal (MTL) color clashing in special situations.

## [5.2.0] - 2026-04-05

### Added
- **Team Logo Customization:** New option to choose between classic colored badges (Pastilles) and official team logos.
- **Local Logo Storage:** Team logos are now bundled locally for instant loading and offline support.
- **SVG Rendering Optimization:** Added `sourceSize` support for pixel-perfect sharpness on HiDPI screens.
- **Contrast-Aware Themes:** Automatic switching between `_light` and `_dark` logo variants based on Plasma theme brightness.
- **Advanced Pre-Game Hub:** Integrated seasonal comparisons: PP%, PK%, Faceoff%, GF/G, and GA/G.
- **Goal Video Highlights:** Direct access to official NHL goal highlights via an integrated play button.

### Fixed
- **Flickering Issues:** Resolved a bug where season series info would disappear after a few seconds.
- **Responsive Sizing:** Decoupled logo sizes from font scales for a more consistent panel width.

## [5.1.0] - 2026-04-03

### Added
- **Multi-language Expansion:** Added support for Russian, Finnish, Swedish, German, Czech, and Slovak.
- **Real-time Situation Indicators:** Live power play and empty net (🥅) indicators on game status badges.
- **Team-Specific Goal Songs:** Goal notifications now play official team-specific songs.
- **Future Calendar Data:** The main calendar now displays the number of scheduled games for future dates.

## [5.0.0] - 2026-03-30

### Added
- **Centralized ApiService Layer:** Unified all NHL API calls into a robust service in `logic.js`.
- **Grouped State Management:** Refactored application state into logical `QtObject` groups (nav, glob, std, lead, etc.).
- **Redesigned Pre-Game Popup:** Major visual overhaul with XL logos and improved layout.
- **Detailed Goalie Career Stats:** Correct calculation of NHL totals and GAA weighted averages.

### Changed
- **Statistical Precision:** Updated all goalie statistics to 3 decimal places.
- **Enhanced Player Career Table:** Centered and aired out design for better legibility.
