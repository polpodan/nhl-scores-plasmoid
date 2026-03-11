# Changelog — nhl-scores-plasmoid

All notable changes to this project are documented in this file.

- - -
## \[3.1.0] — 2026-03-11

### New Features

- **Team schedule viewer** — Clicking on a team badge in the match detail popup
  now opens a full team schedule, showing the last 5 completed games and all
  upcoming games. Each entry displays the opponent (with coloured badge), date,
  score or start time, and a W / L / OTW / OTL result badge.
- **Team player stats** — A "Stats" button in the schedule view toggles to a full
  roster statistics panel. Skaters are listed by points (G / A / PTS / +/−),
  followed by goalies (GP / W / L / GAA / SV%). Stats are loaded lazily on
  first access.
- **Assists totals** — Assist counts are now displayed alongside each assistant's
  name in the goal summary (e.g. *Suzuki (52), Anderson (30)*), matching the
  existing scorer total format.
- **Goals grouped by period** — The match detail popup now organises goals under
  period headers (*1st period*, *2nd period*, etc.). Periods with no goals show *
  No goals recorded.* Playoff multi-overtime periods (2OT, 3OT, …) are fully
  supported and sorted correctly.

### Improvements

- **Detail popup toggle** — Clicking the same game a second time now closes the
  popup instead of reloading it.
- **Enriched tooltip** — Hovering over the plasmoid now shows one line per game
  (score + period/clock for live games, start time for upcoming games, final
  score for finished games) instead of a generic count.
- **"Goals" heading hidden for upcoming games** — The *Goals* section header no
  longer appears when the game has not yet started.
- **Desktop view centred** — Game cards, score rows, and the header bar are now
  centred at a maximum width of 480 px on the desktop (planar) representation.
- **Standings divisions fixed** — Division filtering now correctly uses the NHL
  API English names (*Atlantic*, *Metropolitan*, *Central*, *Pacific*) for data
  matching while displaying French labels (*Atlantique*, *Métropolitaine*, *
  Centrale*, *Pacifique*) in the UI. The top 6 teams per conference were
  previously missing; this is now resolved.

### Localisation (fr.po)

- Added translations for: `GOAL → BUT`, period labels (*1re période*, *2e période*
  , …), intermission labels, `Overtime → Prolongation`, `Shootout → Tirs de
  barrage`, `Starts at → Début à`, `Goal blink duration`, `Schedule → Calendrier`
  , `Stats`, `Player → Joueur`, `Goalies → Gardiens`, column headers (PJ, B, A,
  PTS, +/−).
- Removed obsolete entries: `NHL Goal!`, `Notify on goals`, `Show yesterday`, `
  Notifications`.
- Fixed 3 duplicate `msgid` entries (`No games`, `Upcoming`, `Final`) that
  caused `msgfmt` fatal errors.

### Bug Fixes

- **Variable collision** in `fetchSchedule` — inner `var result` (W/L string)
  was shadowing the outer `var result` (games array) due to JavaScript `var`
  hoisting; renamed to `matchResult`.
- **Missing `sz` injection** in the full-representation `Loader` `onLoaded`
  handlers — team badge font size was not being passed in the panel list view.
- **Unused variable** `var now = Date.now()` removed from `fetchSchedule`.
- `schedulePastGames`** root property** removed; replaced by inline constant `5`.
- **Playoff OT period naming** — periods beyond the third are now correctly
  labelled `OT`, `2OT`, `3OT`, … instead of all collapsing to `OT`.
- **Schedule delegate alignment** — first row in the schedule list was
  misaligned; fixed by giving each delegate full `ListView` width and centring
  content internally.

- - -
## \[3.0.0] — 2026-03-10

### New Features

- Desktop (planar) representation with enriched game cards, goal banner, and
  shared detail / standings views.
- Score blinking on goals — only the scoring team's badge and score flash,
  using a configurable duration (replaces system notifications).
- Intermission badge (`INT`) shown during period breaks.
- FINAL badge now shows the game date on a second line.
- Standings view fixed width (340 px), centred.

### Improvements

- Dynamic compact sizing (`sz`) with automatic `forceInline` threshold below ~36
  px.
- Vertical separators between games in horizontal compact mode.
- Config file root `Item` with `implicitWidth/Height` to suppress Qt warnings.

- - -
## \[1.8.0] — 2026-03-09

### New Features

- Wild Card standings view with conference / division grouping.
- Unified status badge (single merged badge replacing separate team badges).
- Vertical panel support with fixed layout.
- French localisation (`fr.po`).
- `install.sh` self-extracting installer.
- Goal scorer stats in detail popup (`goalsToDate`).
- Adaptive `pollTimer` (faster refresh during live games).
- Team text colour contrast (WCAG-compliant `teamTextColor()`).

- - -
## \[1.0.0] — 2026-03-08

- Initial release: compact scoreboard, live clock, game detail popup (goals +
  team stats), tooltip, favourite team filter, configurable colours and layout.
