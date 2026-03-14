# Changelog — nhl-scores-plasmoid

All notable changes to this project will be documented in this file.

---

## [3.3] — 2026-03-14

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

## [3.2] — 2026-03-11

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
