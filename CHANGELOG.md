# Changelog

## [5.3.0] - 2026-04-08

### Added
- **Official NHL Standings Indicators:** Added support for official clinch indicators (**x**, **y**, **z**) and elimination markers (**E**) across all standings modes (League, Wild Card, and Divisions).
- **Standings Legend:** Centered legend at the bottom of the standings view explaining all qualification and elimination markers.
- **Smart Morning View (Logic Fix):** Refined logic to show yesterday's games until 12:00 PM today even with "Past days" set to 0, while respecting user selection for any value ≥ 1.
- **Enhanced Player Playoff Stats:** Career playoff history is now fully calculated and displayed in a dedicated tab.
- **Unified Vertical Alignment:** Forced perfect horizontal baseline for all panel elements (logos, scores, status) in both Inline and Stacked modes.
- **Ultra-compact Color Adaptation:** Smart color conflict detection now extends to the ultra-compact representation.

### Fixed
- **Horizontal Scrolling:** Eliminated the need for horizontal scrolling in the Playoff Bracket by implementing a vertical tree layout.
- **Color Conflicts:** Fixed Florida (FLA) vs Montreal (MTL) and New Jersey (NJD) vs Montreal (MTL) color clashing in special situations (Powerplay).
- **Navigation Errors:** Fixed "leagueRow is not defined" and other reference errors in the standings view.
- **Dashing Issues:** Removed redundant separator dashes in upcoming games for the Inline layout.

## [5.2.0] - 2026-04-05

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
