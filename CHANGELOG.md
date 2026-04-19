# Changelog

All notable changes to this project will be documented in this file.

## [6.1.0] - 2026-04-18

### Added
- **Instant Bracket Loading:** Implemented persistent local caching for the playoff bracket. After the first load, the bracket displays instantly with the last known scores while updating in the background.
- **Enhanced Historical Database:** Added support for early NHL teams (pre-1940s) including Montreal Maroons, NY Americans, Hamilton Tigers, and original Ottawa Senators with correct colors and abbreviations.
- **Historic Team Identities:** When viewing statistics for past seasons, the applet now dynamically displays the team's name and logo from that era (e.g., "Hartford Whalers" logo and title appear when viewing Carolina's 1990 stats).
- **Goalie Support in Franchise History:** You can now view all-time leaders for Goalie Wins and Shutouts for every franchise.
- **Deceased Legend Detection:** For retired players over 95 years old or with a recorded death date, the interface now respectfully displays "Deceased" and their age at the time of passing instead of a live age.

### Improved
- **Advanced Franchise Filtering:** Aligned the Franchise Leaders view with League Leaders; you can now filter historical records by position (Forwards, Defensemen, or Goalies) with 100% accurate results fetched directly from the NHL API.
- **Visual Harmonization:** Re-centered and redesigned the Franchise Leaders header to perfectly match the main applet aesthetic.
- **Streamlined Team Hub:** Removed redundant UI elements and consolidated the "Season Calendar" access to improve navigation flow.
- **Optimized Scoring Logic:** Playoff series win counts are now calculated with strict game-type filtering, ensuring regular season matchups no longer interfere with playoff series results.

### Fixed
- **API Format Change (2026):** Completely rewrote the bracket parser to support the new flat "series" array format introduced by the NHL API for the 2026 season.
- **Historical Scaling Bug:** Fixed a bug where viewing older teams (e.g., Ottawa Senators 1992) would allow selecting seasons prior to their founding.
- **Translation Completeness:** Finalized French localization for the Stanley Cup Playoffs title and all new historical filters.
- **QML Syntax:** Fixed "Unexpected token let" and other compatibility issues for older Plasma 6 environments.

## [6.0.0] - 2026-04-18

### Added
- **Deep Historical Database:** Users can now browse League Leaders and Team Statistics for any season back to **1917-18**.
- **Playoff Statistical Toggle:** Added a "Reg / Post" switch across all leaderboards to compare regular season vs. playoff performance.
- **Stanley Cup Trophy Case:** The Team Hub now proudly displays each franchise's championship history with a grid of 🏆 icons.
