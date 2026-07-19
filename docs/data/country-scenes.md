# Country scene data — Analysis

> Source: `Source/Gameplay/Map/Country/Country.tscn` (base template, 109 lines) + `Source/Gameplay/Map/Country/Countries/*.tscn` (42 per-country instances, ~18 lines each) · Layer: data · Audited: 2026-07-18

## Purpose

The map's static data layer: one base scene (`Country.tscn`) defines every visual/audio/collision node a country needs (sprite, border, name/troop labels, click sounds, a `RectangleShape2D` for the default disabled `CollisionShape2D`, plus the `Country.gd` script — see [Country.md](../gameplay/Country.md)); each of the 42 `Countries/*.tscn` files `instance`s that base scene and overrides exactly three things: the node's own name (which doubles as the country's identity string used as dictionary keys throughout [game_play.gd](../gameplay/game_play.md)), a `groups=[...]` continent tag, and a per-country `CollisionPolygon2D` outline plus (for 41 of 42) two `Country`/`Border` sprite `texture` overrides.

## How this was audited

Per the audit plan in [RECON.md](../RECON.md), all 42 country instances were diffed/aggregated programmatically rather than read individually line-by-line, since they are structurally identical by design; `Country.tscn` and two representative instances (`Afghanistan.tscn`, `Japan.tscn`) were read in full. Cross-checks performed:

1. **Adjacency graph symmetry** — parsed [game_play.gd](../gameplay/game_play.md)'s `bordering_countries` dictionary (42 entries) and verified every edge is reciprocated (if A lists B as a neighbor, B lists A). **Result: 0 asymmetries** — the hand-maintained adjacency data is internally consistent.
2. **Continent membership counts** — parsed each `.tscn`'s `groups=[...]` tag and tallied countries per continent, then compared against [game_play.gd](../gameplay/game_play.md)'s `total_countries_in_continents` (used for continent-control bonus checks in [DraftState.md](../gameplay/DraftState.md)/[InActiveState.md](../gameplay/InActiveState.md)). **Result: exact match** — NorthAmerica 9, SouthAmerica 4, Europe 7, Africa 6, Asia 12, Australia 4, both from the scenes and from the hardcoded totals.
3. **Collision polygon uniqueness** — hashed every country's `CollisionPolygon2D` point array. **Result: 42 unique polygons**, no accidental copy-paste duplicates.
4. **File count** — 42 `.tscn` files, matching [Game.gd](../gameplay/Game.md)'s hardcoded `total_countries = 42`.
5. **Player-count range bounds** — confirmed both [Menu.tscn](../ui/Menu.md) (offline) and [HostGameMenu.tscn](../ui/HostGameMenu.md) (online) configure their `PlayersRange`/`lobby_players` `SpinBox` controls with `min_value=2.0, max_value=6.0` — resolving the "no independent bounds check" smells noted in those files' Phase 2 analyses as low-risk: the UI control itself is correctly bounded, even though the consuming code doesn't re-verify it.

## Findings

- **[Verified, not a bug] — `Afghanistan.tscn`'s missing texture overrides.** Already investigated in [RECON.md](../RECON.md) free finding #5: `Afghanistan.tscn` is the only one of 42 country instances with just 1 `ext_resource` instead of 3, because it relies on `Country.tscn`'s own default placeholder textures, which happen to already be Afghanistan's art (`Country.tscn` lines 4–5: `res://Assets/Graphics/Map/Countries/Afghanistan.png` / `.../Borders/Afghanistan.png`). Restated here as a data-layer finding because it's the base template — not any individual country file — that creates the coupling: **if `Country.tscn`'s default placeholder textures are ever changed (e.g. during an art pass, to a neutral/blank placeholder), `Afghanistan.tscn` alone would silently render the wrong country art, with no diff appearing in its own file** to explain why. Every other country is immune to this because they all explicitly override both textures. *Severity guess:* medium (silent, template-level coupling affecting exactly one of 42 data files, undetectable by looking at the affected file itself).
- **[Data integrity — confirmed clean] — the hand-maintained 42-country adjacency graph has zero symmetry errors and its continent totals exactly match the actual scene data.** Worth recording explicitly (not just as an absence of findings): for hand-authored map data with no schema/test enforcing consistency, getting a 42-node, ~90-edge graph fully symmetric and getting six continent totals to exactly match 42 scene files' group tags is a meaningful sign of care in the original authoring — useful context for a rewrite team deciding whether to trust this data as-is (yes) versus needing to re-derive it from scratch (no).

## Cross-references

The adjacency data itself is duplicated into two dictionaries in [game_play.md](../gameplay/game_play.md) (`bordering_countries` / `bordering_countries_nodes`) — that duplication (not the data's correctness, which is confirmed clean here) is the finding recorded there. The base-template coupling connects to [Country.md](../gameplay/Country.md).
