# Changelog — nhl-scores-plasmoid

All notable changes to this project will be documented in this file.

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
