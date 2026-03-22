# Changelog — nhl-scores-plasmoid

All notable changes to this project will be documented in this file.

---

## [4.4.0] — 2026-03-22

### Added

- **Penalty view in game detail** — the game detail popup now features a three-way toggle: **Goals · Penalties · ⭐ Stars**. Each tab displays its content while the active tab appears bold; inactive tabs are dimmed. The toggle is only visible for completed and live games.
- **Penalties grouped by period** — penalty entries are organized under period separators (1st period, 2nd period, etc.) matching the goals section layout. Each row shows: team badge, time, player name and number, infraction description, and duration.
- **Penalty player names clickable** — player names in the penalty view link to the full player profile. Player IDs are resolved by cross-referencing the boxscore `playerByGameStats` roster (sweater number + team), with a race-condition fix that handles landing and boxscore arriving in any order.
- **28 penalty infractions translated** — `penaltyDesc()` function maps API `descKey` values to localized strings (e.g. `slashing` → `Bâton élevé frappé`, `hooking` → `Accrocher`).
- **Three stars moved into toggle** — the three stars section is now part of the Goals/Penalties/Stars toggle instead of a separate section below the goals list. Star player names are clickable.
- **Game count badges on calendar** — each day in the full-day calendar now shows a small colored badge with the number of games scheduled, loaded by fetching 4–5 weekly schedule requests to cover the entire month.
- **📅 Calendar label on button** — the calendar button in the day view header now reads `📅  Calendar` instead of just an icon.
- **Poll timer configurable** — a new `Refresh interval` ComboBox in General settings allows choosing 10, 20, 30, 45, or 60 seconds for the live refresh interval. Default remains 20 seconds.
- **Goal sound volume slider** — a volume slider (0–100%) has been added to the Notifications section in General settings. The slider controls the `AudioOutput.volume` of the goal sound in real time.
- **`onErrorOccurred` fallback for goal sound** — if the team-specific MP3 is missing, the `MediaPlayer` automatically falls back to `siren.wav`.

### Changed

- **`detailShowPenalties: bool` → `detailView: string`** — replaced the boolean penalty toggle with a three-state string property (`'goals'` | `'penalties'` | `'stars'`), making it easy to add future tabs.
- **`resolvePenaltyIds(pmap)`** — penalty player ID resolution is now a standalone function called from both the landing parser and the boxscore parser, ensuring IDs are always resolved regardless of which response arrives first.
- **`fetchCalendarMonth(year, month)`** — now makes 4–5 parallel requests (one per 7-day window) instead of a single request for the 1st of the month, covering the full month's game counts.
- **`configDisplay.qml` stubs rebuilt** — all 19 `cfg_*` properties from `main.xml` are now properly declared as stubs in `configDisplay.qml`, eliminating `Setting initial properties failed` errors on config open.

### Fixed

- **`pastDays` not triggering refresh** — `onPastDaysChanged` and `onShowTodayChanged` handlers were missing from the `Connections` block. Adding them ensures the widget refreshes immediately when these options are changed in settings.
- **`pastDays = 0` not working** — `Plasmoid.configuration.pastDays || 0` treated `0` as falsy and defaulted to the previous value. Fixed with `!== undefined` check.
- **Config Apply button grayed out** — `onActivated` on `ComboBox` and `onMoved` on `Slider` do not mark the config as dirty in Plasma. Changed to `onCurrentIndexChanged` and `onValueChanged` respectively, with a `ready` flag on the ComboBox to prevent writes during initialization.
- **Obsolete stubs in `configDisplay.qml`** — `cfg_showYesterday` and `cfg_showTwoDaysAgo` were still declared as stubs after being removed from `main.xml`, causing Plasma config errors.

### Localization

- **fr.po** — 204 entries. Added 28 penalty infraction translations, `Penalties` → `Pénalités`, `Stars` → `Étoiles`, `Refresh interval:`, `Goal sound volume:`, `Calendar`, `Today`, day abbreviations.

---

## [4.3.0] — 2026-03-21

### Added

- **Player search** — a 🔍 Search button has been added to the game detail popup navigation bar (between Leaders and NHL.com). The search view provides a text field to search for any NHL player, active or retired, using the `search.d3.nhle.com` API. Results show a colored team badge (active players) or 🏒 icon (retired), player name, position, and retired status. Clicking any result opens the full player profile view.
- **Full-day calendar** — clicking the 📅 button in the day view header opens a monthly calendar. Navigation uses ‹ › arrows for month-by-month browsing and a year dropdown (2006–present) for quick year jumps. Today's date is highlighted with a colored circle; the currently displayed date is highlighted in accent color. Clicking any day opens the full day view for that date. Future dates are shown dimmed.
- **Clickable scorers and assistants** — in the game detail popup goals section, scorer names and assist names are now displayed in accent color and are clickable. Clicking opens the full player profile. The back button returns to the match popup (`‹ Match`).
- **Date displayed in game detail popup** — for completed and live games (FINAL / LIVE), the game date and time are now shown below the team logos, centered, in the format `hh:mm  ·  Day D Mon YYYY`.
- **‹ Match back button in Leaders view** — replaced the ✕ close button with a `‹ Match` back button consistent with the Standings view navigation.

### Changed

- **Day view header** — the date label is now centered between the ✕ button and the new 📅 calendar button.
- **`openSchedule(team, showStats)`** — now accepts a second parameter. When `showStats = true`, `fetchTeamStats` is called immediately alongside `fetchSchedule`, fixing the blank statistics view when opening Stats directly from the team hub.
- **`openDayView` uses local date** — date ISO strings are now built using `getFullYear/Month/Date` (local time) instead of UTC variants, fixing the off-by-one day issue for evening games when navigating from the panel applet.
- **Hub team name** — the team hub now shows the full team name resolved from `teamCommonName + teamPlaceNameWithPreposition` (e.g. "Maple Leafs de Toronto" in French).
- **All inline `component` declarations removed** — QML `component` blocks nested inside `ScrollView` or `ColumnLayout` caused silent rendering failures in Plasma 6. Replaced with `Repeater` delegates, direct `Label` elements, and explicit property storage on parent items.

### Fixed

- **Day view and Leaders view disappeared** — both views were accidentally removed during the team hub refactoring. Reinserted before the hub view with correct `visible` conditions.
- **`LeaderSection` not a type** — the `LeaderSection` component was defined in a separate file that no longer existed. Replaced with 8 inline `ColumnLayout` + `Repeater` sections directly in the leaders view.
- **Stats blank when opening from hub** — `openSchedule` reset `scheduleShowStats = false` unconditionally, then the Stats button set it back to `true` — but the reset happened last. Fixed by passing `showStats` as a parameter and calling `fetchTeamStats` immediately when `true`.
- **Calendar overlay on day view** — `calendarOpen` was not included in the `visible` condition of the day view. Added `&& !root.calendarOpen`.
- **`calendarOpen` not reset** — opening a game detail from the calendar left `calendarOpen = true`, causing the popup to appear behind the calendar. Added `calendarOpen = false` to `openDetail` and `openDayView`.
- **`scorerId = 0` for scorers** — `scorerId` was stored in `detailGoals` but not propagated to `detailGoalsByPeriod` (the flat list used by the Repeater). Added `scorerId: gobj.scorerId || 0` to the flat list push.
- **`dayCell is not defined`** — the empty-cell delegate in the calendar referenced `dayCell.implicitHeight` from a different `Repeater`. Replaced with a fixed height of `38`.
- **`fetchTeamStats` called twice** — the toggle button called it once directly and once inside a duplicate `if` block. Consolidated into a single guarded call.
- **Player profile overlapping game detail** — `playerOpen` from `'detail'` context was not excluded from the detail popup's `visible` condition. Added `&& !(root.playerOpen && root.playerFrom === 'detail')`.
- **Search debug logs removed** — 4 `console.log` calls left from the search endpoint debugging were cleaned up.

### Localization

- **fr.po** — 169 entries. New strings: `Search` → `Recherche`, `Player name…` → `Nom du joueur…`, `No results` → `Aucun résultat`, `Retired` → `Retraité`, `‹ Search` → `‹ Recherche`, `Calendar` → `Calendrier`, `Today` → `Aujourd'hui`, day abbreviations (Di/Lu/Ma/Me/Je/Ve/Sa).

---

## [4.2.0] — 2026-03-20

### Added

- **Manual refresh button** — a 🔄 button has been added to both the game detail popup (next to NHL.com) and the desktop widget header (next to Leaders). Clicking it triggers an immediate data refresh.
- **"Updated X min ago" indicator** — the desktop widget header now shows a relative time label ("just now", "1 min ago", "5 min ago") instead of a static clock time. The label refreshes automatically every minute.
- **Timezone indicator in day view** — each upcoming game in the full day view now shows a second line under the start time indicating whether the time is displayed in local timezone ("local") or arena timezone ("arena"), respecting the Date mode setting configured in Display.
- **Player profile view** — clicking any player in the League Leaders view opens a full player profile page containing:
  - Full-width headshot photo with the player's name overlaid at the bottom
  - Team, sweater number, position, height, weight, and birth date/city below the photo
  - Current season stats (PJ / Goals / Assists / PTS / +/-) with labels above values, centered and spaced
  - Complete season-by-season history table with columns: Season, League, Team, GP, G, A, PTS, +/- (or GP, W, GAA, SV%, SO for goalies)
  - NHL team rows show a colored team badge; other leagues show the team name truncated
  - NHL career totals row highlighted in accent color at the bottom of the history table
- **Player profile accessible from team stats** — clicking any skater or goalie row in the team statistics view (Schedule → Stats tab) also opens the player profile. The back button contextually shows `‹ Leaders` or `‹ Stats` depending on the entry point.
- **`resolveNHLAbbrev()` function** — resolves a team's common name (e.g. "Oilers") to its abbreviation (e.g. "EDM") using a static lookup table of all current and historical NHL franchises, without requiring standings data to be loaded.

### Changed

- **`openPlayer(id, from)`** — the function now accepts a second parameter (`'leaders'` or `'teamstats'`) to control the back button label in the player profile view.
- **`scheduleSkaters` and `scheduleGoalies`** — both now include a `playerId` field sourced from the NHL API, enabling navigation to the player profile.
- **Player profile back button** — shows `‹ Leaders` when opened from the leaders view, and `‹ Stats` when opened from team statistics.
- **Season history `+/-`** — displays `–` for seasons in leagues that don't track plus/minus (junior leagues, international tournaments, etc.) instead of `0`.
- **Season history team column** — uses `teamName.default` (full team name, truncated) for non-NHL teams, and a colored badge resolved via `resolveNHLAbbrev()` for NHL seasons.

### Fixed

- **NHL career total row showing no data** — the row used `visible: false` with conditional `Layout.preferredWidth` to switch between skater and goalie columns, but QML `RowLayout` does not remove invisible items from layout. Replaced with a `Repeater` that builds the correct column set in JavaScript, eliminating the visibility issue entirely.
- **Season history column misalignment** — `Layout.fillWidth: true` with `visible: false` labels left invisible items occupying space. Fixed by using explicit `Layout.preferredWidth: 0` when hidden and fixed widths for all columns, matching headers and data rows exactly.
- **`teamAbbrev` undefined in `seasonTotals`** — the NHL API does not include `teamAbbrev` in `seasonTotals` entries; only `teamCommonName` and `teamName` are present. Fixed by resolving the abbreviation via `resolveNHLAbbrev()`.
- **`standingsData` empty when opening player profile** — `resolveNHLAbbrev()` previously depended on `standingsData` being loaded, which is not guaranteed when navigating from Leaders. Replaced with a self-contained static lookup table.

### Localization

- **fr.po updated** — 6 new entries: `NHL Total` → `Total NHL`, `Season` → `Saison`, `Season history` → `Historique`, `Season stats` → `Stats de la saison`, `‹ Leaders` → `‹ Meneurs`, `‹ Stats` → `‹ Statistiques`. Total: 145 entries.

---

## [4.1.0] — 2026-03-19

### Added

- **Team statistics with progress bars** — the game detail popup now displays team stats styled like NHL.com: Faceoffs %, Power Play, PIM, Hits, Blocked Shots, Giveaways, and Takeaways, each with a bicolor progress bar in the away/home team colors. During live games, stats are aggregated in real time from `playerByGameStats` (forwards + defense). After the game, stats are sourced from `teamGameStats`.
- **Standings modes** — the standings popup now has three toggle buttons: **Wild Card** (existing), **Divisions** (all 4 divisions with playoff cutoff separator), **League** (all 32 teams ranked by points).
- **League standings table** — in League mode, the table shows GP, W, L, OT, PTS, GF, GA, S/O, HOME, AWAY, L10, and STRK. Clicking any sortable column header (GP, W, L, OT, PTS, GF, GA) sorts ascending or descending with a ↑/↓ arrow indicator. The active sort column is highlighted.
- **Per-team goal sound notifications** — multiple teams can now have sound notifications enabled simultaneously. Each team plays its own sound file (`contents/sounds/{abbrev}.mp3`, e.g. `mtl.mp3`). Notifications fire only for teams that are also in the followed favorites.
- **Sound preview on toggle** — clicking the 🎵 badge on a team chip in General settings plays the team's sound immediately as a preview. Clicking again stops it.
- **🎵 badge on team chips** — in General settings, each selected (followed) team chip shows a small badge in the top-right corner: dark = no sound, yellow = sound enabled. Clicking the badge toggles the sound for that team independently of the follow status.
- **OT/SO suffix under Final badge** — completed games that ended in overtime show `Final` on line 1 and `OT` (or `TB` in French) on line 2 of the status badge. Regular-time finals show only `Final` with no second line.

### Changed

- **`showYesterday` / `showTwoDaysAgo` use rolling window** — "Show yesterday's games" now includes games that started within the last 24 hours (rolling), and "Show games from two days ago" covers the last 48 hours. Today's games are always shown regardless of the option. This is intentionally approximate for a more intuitive experience.
- **`badgeLine2` no longer shows the date** — previously displayed the game date under the Final badge; now only shows `OT` or `SO` when applicable, and nothing for regulation finals.
- **`badgeLine1` no longer appends OT/SO suffix to Final** — the suffix is now exclusively handled by `badgeLine2` to avoid duplication.
- **League standings sort** — S/O, HOME, AWAY, L10, and STRK columns are not sortable (composite W-L-OT format); GP, W, L, OT, PTS, GF, GA are sortable with click-to-toggle direction.
- **HOME / AWAY / L10 format** — always shown as `W-L-OT` (e.g. `23-12-0`) for visual consistency, even when OT = 0.

### Fixed

- **`finalWhenText` removed** — dead function no longer called anywhere; cleaned up.
- **`buildStandingsModel` role initialization** — QML `ListModel` roles are determined by the first appended item. Switching from Wild Card to League mode caused all new fields (`gf`, `ga`, `hw`, etc.) to display as 0 because the roles weren't registered. Fixed by prepending and immediately removing a full-schema sentinel item before building the model.
- **`pending=3` / `done()` mismatch in `openTeamHub`** — verified and confirmed balanced (schedule, standings, coach static table each call `done()` exactly once).
- **Stats showing 0 during live games** — `detailStats = st` was assigned before the `playerByGameStats` aggregation completed. Moved the assignment to after the full aggregation.

### Removed

- **Single favorite team sound selector (ComboBox)** — replaced by the per-team 🎵 badge system. The `favoriteTeamSound` property is kept as a legacy fallback for users upgrading from v4.0.
- **Date display under Final badge** — replaced by OT/SO suffix (or nothing for regulation finals).

### Localization

- **fr.po** — new entries: `Divisions`, `League` (→ `Ligue`).

---

## [4.0.0] — 2026-03-15

### Added

- **Team hub** — clicking on a team logo or badge in the game detail popup or in the standings opens a full team hub: season record (W-L-OTL), standings position, head coach name (static table, 2024-25 season), last 5 results (W/L/OTW/OTL with opponent and score), next game with date and time, Schedule and Stats buttons.
- **Schedule and Stats buttons in hub** — from the hub, the schedule and player statistics views are accessible; the back button returns to the hub rather than the previous view.
- **Full day view** — clicking a `|DD/MM|` date separator in the panel applet opens a popup listing all games for that day (not just followed teams): start time (24h format), live score with period and clock, final score, colored team badges. Clicking the date again closes the popup (toggle). Clicking a game opens its detail popup.
- **Date separators in desktop widget** — the desktop widget now displays clickable date separators between game groups, identical to the panel behavior.
- **League leaders view** — accessible via the Leaders button in the game detail popup and in the desktop widget header. Shows top 10 per category in scrollable sections: Points, Goals, Assists, PIM (skaters) + Wins, Shutouts, GAA, SV% (goalies). Each row shows rank, colored team badge, player name and value. The leader of each section is highlighted. Data from `/v1/skater-stats-leaders/current` and `/v1/goalie-stats-leaders/current`.
- **Playoff mode** — automatic detection via `gameType=3` in the scoreboard. In the detail popup for a playoff game: round label (First Round / Second Round / Conference Finals / Stanley Cup Final), prominent series score with leading team indicator, game number (`Game X of 7`), 🏆 button to open the bracket.
- **Playoff bracket view** — accessible via the 🏆 button in a playoff game popup. Shows all active rounds and series with scores and status, loaded from `/v1/playoff-bracket/now`.
- **Goal sound and visual notification** — a banner in the team's colors appears over the applet for 6 seconds showing 🚨 BUT!! / GOAL!! (based on system language), the score and scorer name. A siren sound (`siren.ogg` via `MediaPlayer`) plays simultaneously. The favorite team is configured in General → Notifications. Entirely self-contained in the plasmoid, no external installation required.
- **Favorite team selector** in General → Notifications — 32-team ComboBox for goal sound notifications.
- **Leaders button in desktop widget header** — next to the Standings button.
- **Contextual back navigation** — the back button in standings shows `‹ Team` when reached from the team hub, `‹ Match` when from a game popup. Same logic applies to schedule and stats views.

### Changed

- **Simplified popup navigation** — the game detail popup header bar is now full-width with 4 buttons: `[✕]` closes the popup, `[Standings]` opens standings, `[Leaders]` opens leaders, `[NHL.com]` opens the browser. The bar is anchored outside the centered `ColumnLayout` to prevent content misalignment.
- **`✕` now fully closes the popup** — `expanded = false` is called alongside `detailOpen = false` to prevent the empty popup issue.
- **Horizontal separators in game popup** — the 5 separators in the game detail popup use an away → home team color gradient.
- **Game popup background removed** — the gradient background that painted visibly on open has been removed; the background is now KDE's default.
- **Game list view removed** — the intermediate "game list" popup (which was buggy) has been removed. Clicking a game from the applet opens the detail popup directly.
- **Status badge redesigned** — 3 layers: period (`1st`, `2nd`, `3rd`, `OT`) / clock / power play (PP). The clock is always below the period, like the intermission countdown. PP font size increased.
- **`livePeriodText()`** — returns only the ordinal (`1st`/`2nd`/`3rd` in English, `1re`/`2e`/`3e` in French) without the word "period".
- **"Starts at" text removed** from desktop widget — the time is already shown in the status badge.
- **`cardWeff` for UPCOMING** — minimum width increased from 76→82px to prevent truncation with `20:00`.
- **Date click is a toggle** — clicking an already-open date closes the popup instead of reloading it.

### Fixed

- **`gameIndex` for `maxGames`** — `DATE_SEP` separators were not counted in `maxGames` but occupied a slot. Each entry now has a `gameIndex` (real game index, -1 for separators), used instead of `index` for visibility.
- **`DATE_SEP` in tooltip** — date separators produced a spurious `0–0 · Final` line in the tooltip. Fixed by skipping `DATE_SEP` entries in the `_tooltipSub` loop.
- **Ultra-compact mode overlap** — switching display modes left elements from the old mode visible. The UC `Row` is now outside `cardBg`, `cardBg` is hidden in UC mode, and `hRepeater.model` is reset on each mode change.
- **`readonly property var cmpSit`** — `readonly` prevented reactive updates to `situationCode`. Removed.
- **6v6 shown as special situation** — line changes temporarily raise the skater count to 6v6. Now treated as a normal situation (no display).
- **`4v4` shown twice** — `ppType="4v4"` combined with `awaySkaters+"v"+homeSkaters="4v4"` produced `"4v4 4v4"`. For even-strength situations (`even=true`), only `ppType` is now displayed.
- **Duplicate QML IDs** — `awayLbl`, `homeLbl` and `goalBanner` were defined twice in different delegates. Renamed to `awayLblVert`, `homeLblVert`, `goalBannerDesk` in secondary delegates.
- **Ghost `DATE_SEP` card in desktop widget** — date separators rendered a blank `0 Upcoming 0` card in the desktop view. Hidden via `visible: statusRole !== 'DATE_SEP'`.
- **`teamHubOpen` persisting** — opening the hub from standings or a game and then closing the popup left `teamHubOpen=true`. Now reset in `openDetail()` and `openDayView()`.
- **Hub → standings → hub navigation** — `standingsOpen=false` from standings now reopens the hub if `teamHubOpen=true`.
- **`openSchedule` closing the hub** — `teamHubOpen = false` in `openSchedule` prevented returning to the hub from the schedule. Removed.
- **Incorrect ESPN coach data** — the ESPN API returned coaches from previous teams due to incorrect team IDs. Replaced with a reliable static table for the 2024-25 season.
- **`bottomPadding` invalid on `RowLayout`** — non-existent QML property. Moved to the parent `ItemDelegate`.
- **Game detail popup misalignment** — the navigation bar inside the centered `ColumnLayout` was pushing content to the right. Bar moved outside the `ColumnLayout` and anchored full-width.
- **`teamHubPlayoffPct` write-to-global error** — MoneyPuck properties were removed but still referenced in `openTeamHub` reset. Removed.
- **Detail popup showing behind day view** — `detailOpen` was not reset when opening the day view, causing an empty popup on re-click. Fixed by adding `detailOpen = false` to `openDayView()`.

### Removed

- **MoneyPuck** — MoneyPuck data (Corsi%, xGF%) removed entirely. The `predictions.htm` page is dynamically generated in JavaScript and inaccessible from QML. The stats CSV does not contain playoff probabilities.
- **ESPN injury report** — the `teams/{id}/injuries` endpoint consistently returns `{}` empty for NHL teams.
- **ESPN news feed** — English-only content, not team-specific.
- **KDE notifications (`org.kde.notification`)** — replaced by `MediaPlayer` + custom QML banner, entirely within the plasmoid without an external `.notifyrc` file.

### Localization

- **fr.po updated** — 136 entries covering `main.qml`, `configGeneral.qml` and `configDisplay.qml`, including all new strings: team hub, leaders, playoffs, day view, sound notifications.

---

## [3.3.0] — 2026-03-14

### Added

- **Power play / empty net indicator in applet** — a colored badge appears below the clock in the compact applet during power plays (PP 5v4, 5v3, 4v4, 3v3) and displays the empty net emoji 🥅 when a goalie has been pulled. The badge uses the power play team's color. The situation is calculated by counting skaters and goalies from `summary.iceSurface` in the gamecenter landing API, since `situationCode` is not available in any NHL scoreboard endpoint.
- **Penalty box display in game detail popup** — active penalties are shown in the detail popup during live games, with the penalized player's number, name, and time remaining per side. Data sourced from `summary.iceSurface.penaltyBox` in the landing API.
- **Intermission countdown** — during intermissions, the remaining time before the next faceoff is displayed in the compact applet badge (below INT) and in the game detail popup. Time is sourced directly from `clock.timeRemaining` in the play-by-play API.
- **Ultra-compact display mode** — a new "Ultra-compact (dots + score)" option in Display settings renders each game as two small colored circles with the team's initial, separated by the score (e.g. 🔴M 3–2 B🟡). Upcoming games show only the two dots. Games are grouped by date with `|DD/MM|` separators. No time or team name is shown, maximizing density.
- **Date group separators** — games are now grouped by date in the compact applet. A `|DD/MM|` separator is injected between groups of upcoming games on different dates, eliminating the repeated date shown on each upcoming game badge.
- **Team color gradients in applet** — each game card in the compact applet (horizontal and vertical modes) has a subtle background gradient from the away team's color to the home team's color during live games. The best-contrast combination of primary and secondary team colors is selected automatically using Euclidean RGB distance.
- **Colored separators in game detail popup** — the five horizontal dividers inside the game detail popup are rendered as a gradient from the away team's color to the home team's color, replacing the plain grey lines.
- **Secondary team colors** — a full table of official secondary colors for all 32 NHL teams is included, used by `bestGradientColors()` to resolve conflicts between teams with similar primary colors (e.g. TOR vs TBL, BOS vs NSH).
- **Standings button in game detail popup** — the game detail popup now has a direct "Standings" button that opens the Wild Card standings without closing the match context. A "‹ Match" back button returns from standings to the open game.
- **`blinkOpacity()` helper function** — replaces 8 verbose inline opacity expressions throughout the code with a single reusable function call.

### Changed

- **Compact applet card layout redesigned** — in "score below" mode, each game is now displayed as a fixed-width card with rounded corners, a subtle status-colored background (green for LIVE, blue for UPCOMING, grey for FINAL), team badges flanking the status badge, and the score centered below. All cards share the same width for a uniform scoreboard appearance.
- **Popup navigation simplified** — the intermediate "game list" popup (the buggy list shown before opening a game detail) has been removed entirely. Clicking a game now opens the detail popup directly. The detail popup has a ✕ close button, a Standings button, and an NHL.com button.
- **`upcomingWhenText()` shows time only** — for upcoming games on a future date, the function now returns only the local start time (not the date), since the date is already provided by the group separator.
- **ARI replaced by UTA** — Arizona Coyotes (ARI) replaced by Utah Hockey Club (UTA) in the team selector and division assignments in `configGeneral.qml` and `teamColors`.
- **Polling interval reduced to 20 s** — both `pollTimer` and `detailRefreshTimer` reduced from 30 s to 20 s for more responsive score and situation updates during live games.

### Fixed

- **`situationCode` unavailable in NHL APIs** — neither `/v1/score/now` nor `/v1/scoreboard/{date}` nor `/v1/gamecenter/{id}/play-by-play` expose `situationCode`. The field is now computed by counting players in `summary.iceSurface` from the landing endpoint, which is polled alongside `fetchClock` during live games.
- **0v0 situation shown at period start** — when players have not yet taken the ice (start of period, end of intermission), `iceSurface` returns empty arrays. `parseSituation()` now returns `null` when both skater counts are zero, preventing a spurious "0v0 / empty net" display.
- **Polish loop in horizontal compact Repeater** — a `Row` delegate inside a `Row` parent caused a Qt layout polish loop. Fixed by giving the delegate a fixed `height: compactRoot.height` and isolating the ultra-compact `Row` outside of `cardBg`.
- **Ultra-compact mode overlap on layout switch** — switching from another layout mode to ultra-compact left residual elements visible due to QML not destroying `visible:false` children. Fixed by moving the UC `Row` outside `cardBg`, hiding `cardBg` in UC mode, and forcing `hRepeater` model reset on `ultraCompactChanged`.
- **`DATE_SEP` items counted toward `maxGames`** — date separator items injected into `todayGames` were counted by `index < maxGames`, causing fewer real games to display than configured. Fixed by adding a `gameIndex` role (real game index, -1 for separators) and using `gameIndex < maxGames` for visibility.
- **`DATE_SEP` appearing in tooltip** — date separator entries produced spurious "0–0 · Final" lines in the applet tooltip. Fixed by skipping `DATE_SEP` entries in the `_tooltipSub` loop.
- **Score layout ComboBox active in desktop mode** — the score layout selector in Display settings was enabled in desktop (planar) widget mode where it has no effect. It is now grayed out with a "N/A (desktop widget)" label, consistent with the existing vertical panel behavior.
- **`cfg_ultraCompactDefault` missing** — Plasma requires a `*Default` property for every `cfg_*` binding. Added `cfg_ultraCompactDefault` to both `configGeneral.qml` and `configDisplay.qml`.
- **`title` property missing from config pages** — Plasma injects a `title` property into config pages; added `property string title: ""` to both config files to suppress the startup warning.

### Localization

- **fr.po updated** — 15 new entries added for v3.3 additions: ultra-compact layout label, N/A desktop widget, ‹ Match back button, ✕ close button, and date/mode strings. Total: 170 entries across `main.qml`, `configGeneral.qml`, and `configDisplay.qml`.

---

## [3.2.0] — 2026-03-11

### Added

- **NHL team logos in popups** — team logos are loaded dynamically from `assets.nhle.com` and displayed in all popup views. The correct light or dark variant is chosen automatically based on the active Plasma theme. Logos appear in the game detail header (away and home), the schedule/stats navigation bar, and as a full team logo in the schedule and stats views. The compact applet representation retains its original colored badges — logos are exclusive to popups.
- **Clickable teams in standings** — clicking on any team row in the Wild Card standings popup now opens that team's schedule view, consistent with the behavior already available in the game detail popup.
- **Wild Card cutoff separator** — a horizontal separator line is now drawn between positions 8 and 9 in each conference's Wild Card section, visually marking the playoff qualification boundary.
- **Team colors on leaders and goalies** — in the upcoming game preview popup, skater leaders and probable goalie names are now rendered in their respective team's adapted color instead of the default text color.

### Changed

- **Standings title centered and renamed** — the standings popup header is now centered in the navigation bar and reads simply "Classement" (was left-aligned "Wild Card Standings").
- **Standings table centered** — the standings `ListView` is now wrapped in a fixed-width `Item` and centered via `anchors.horizontalCenter`, replacing the previous fragile `x`-calculation approach that caused left-alignment on first render and jitter during resize.
- **Horizontal scrollbar suppressed** — `ScrollBar.horizontal.policy: ScrollBar.AlwaysOff` is set on the standings `ScrollView`, eliminating the spurious horizontal scrollbar that appeared when the popup was wide.

### Fixed

- **Standings left-aligned on open** — the standings table was positioned to the left on first render and only centered after a resize event; the `ListView` is now correctly centered from the initial layout pass using Qt's anchor engine rather than a JS binding.
- **Standings horizontal scrollbar inverted** — the horizontal scrollbar appeared when the popup was wide (no overflow) and disappeared when it was narrow (potential overflow); root cause was `anchors.leftMargin/rightMargin` on the `ListView` inflating `contentWidth` beyond `availableWidth`; fixed by removing the margins and setting `ScrollBar.horizontal.policy: ScrollBar.AlwaysOff`.
- **Logo oversized in schedule/stats nav** — using `width`/`height` on an `Image` inside a `RowLayout` does not constrain SVG intrinsic size; replaced with `Layout.preferredWidth/Height` to correctly limit the logo to 96 px.

### Localization

- **fr.po — config files covered** — 26 new entries added for all `i18n()` strings in `configGeneral.qml` and `configDisplay.qml` that were previously untranslated (badge options, color pickers, layout choices, timezone modes, score layout, notification settings, etc.). Total: 108 entries.

## [3.1] — 2026-03-11

### Added

- **Team schedule view** — clicking on a team badge in the game detail popup opens a full schedule for that team, showing the last 5 completed games and all upcoming games with date, opponent, score/time, and W/L/OTW/OTL result badges.
- **Player stats view** — a "Stats" button in the schedule header toggles to a player statistics table showing skaters sorted by points (GP, G, A, PTS, +/-) followed by goalies (GP, W, L, GAA, SV%). Stats are loaded lazily on first access.
- **Assists totals** — assist counts are now displayed alongside the assisting player's name in the goal summary (e.g. "Suzuki (52), Anderson (30)"), matching the existing behavior for goal scorers.
- **Goals grouped by period** — the game detail popup now organizes goals under period headers (1st, 2nd, 3rd, OT, 2OT, 3OT…, SO). Periods with no goals show "No goals recorded." Playoff multiple-overtime periods are fully supported.
- **Intermission badge (INT)** — a dedicated INT badge is shown in place of the period clock during intermissions, consistent with the LIVE badge color.
- **Rich tooltip** — hovering over the applet now shows one line per game with teams, score, period/clock for live games, start time for upcoming games, and "Final" for completed games, instead of a generic count.
- **Detail popup toggle** — clicking the same game a second time while its detail popup is open now closes it instead of reloading it.
- **Goal blink duration setting** — replaced the binary "Notify on goals" checkbox with a configurable blink duration spinbox (0–30 s; 0 = disabled) in General settings.
- **Desktop representation** — enriched card-based layout for planar (desktop widget) form factor, with per-team score blinking, a goal banner, contextual period/time line, and shared detail/standings views.
- **French translations** — added i18n strings for all new UI elements: period labels, intermission, overtime, shootout, schedule, stats, player table headers, goalies separator, goal blink duration, and more.

### Changed

- **Final badge** — the status badge for completed games now shows the date on a second line (e.g. "Final / 08 Mar") in both compact and full representations.
- **Dynamic compact sizing** — the compact representation scales font and badge sizes dynamically based on panel height (`sz = 0.38 × height`), with automatic inline fallback below ~36 px.
- **Standings fixed width** — the standings delegate is now capped at 340 px and centered, preventing it from stretching across wide panels.
- **Desktop cards centered** — all desktop card content (team badges, scores, status badge, contextual line) is now centered within a 480 px maximum width.
- **Conference/division names in French** — division names in the standings model now use French labels (Atlantique, Métropolitaine, Centrale, Pacifique) while keeping the correct English API keys for filtering.
- **Schedule header layout** — three-zone navigation bar: Back button on the left, team badge + view title in the center, Schedule/Stats toggle button on the right.

### Fixed

- **Standings empty divisions** — francizing division display names had broken the API filter (`"Atlantique"` ≠ `"Atlantic"`); API name and display label are now stored separately.
- **OT period shown as empty "Period 4"** — games won in overtime no longer display a spurious empty fourth period in the goal summary. Only regulation periods up to 3 are pre-populated; OT/SO entries appear only when goals exist.
- **Variable collision in fetchSchedule** — `var result` (W/L string) shadowed the outer `result` array due to JS `var` hoisting; renamed to `matchResult`.
- **Missing `sz` injection** — the full-representation game list Loaders were not injecting the `sz` size property into teamColumn/teamRowInline components; now consistent with the compact representation.
- **`Goals` label shown for upcoming games** — the "Goals" section header is now hidden when the game has not yet started.
- **Unused variables removed** — `var now` in `fetchSchedule` and the `schedulePastGames` root property (replaced by an inline constant) were removed.
- **fr.po duplicate entries** — three duplicate `msgid` entries (`No games`, `Upcoming`, `Final`) introduced during a previous update have been removed; `msgfmt --check` now passes cleanly.
- **RowLayout anchor warnings** — `anchors.verticalCenter` on direct children of `RowLayout` replaced with `Layout.alignment: Qt.AlignVCenter` throughout.

---

## [1.8.0] — 2026-03-10

> Initial public release. Core features: live scores polling, compact/full representations, vertical panel support, Wild Card standings, goal notifications, configurable badge colors, French localization.
