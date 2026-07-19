# AttackingMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/AttackingMenu.gd` · 85 lines · Layer: UI · Audited: 2026-07-18

## Purpose

The attack-configuration overlay: lets the active player pick how many troops to commit when attacking a neighboring country, showing both the attacker's and defender's country/troop/player info side by side.

## Lifecycle

`_ready()` (25–26) calls `attack_details()` with no arguments, which (per the `pc == null` branch, lines 30–34) sets a **hardcoded default of 8 troops** purely so the range control has *something* to show before the real call arrives from `AttackState`/`Country` with actual country data.

## Surface

- `attack_details(pc, oc)` (28–62) — the main setup entry point; populates both country panels and player identity.
- `cancel()` (64–66) — hides self and the owning overlay.
- `attack()` (68–72) — emits `attacked` with troop counts and both countries, resets and hides.
- `value_changed(value)` (74–78) — pluralizes the troop-count suffix.
- `count_troops(troops)` (81–84) — tracks attacker/defender troop counts as the slider moves.

## Permissions & validation

- **Checks missing:** no validation that `player_country.troops >= 2` before computing `troops_range.max_value = player_country.troops - 1` (line 41) — if a country with exactly 1 troop somehow reaches this menu (shouldn't happen under normal Risk rules, but nothing here enforces it), `max_value` becomes 0, silently disabling the slider rather than surfacing an error. No independent check that `opponent_country`/`player_country` are actually adjacent or hostile — that's assumed to have been validated by the caller (`Country`/`AttackState`), not re-checked here.

## Data touches

None directly (pure UI over `Country` objects passed in by reference).

## Shared state

Reads `GamePlay.online`, `GamePlay.players_data`; reads `Server.my_lobby.players`; reads/writes `GamePlay.game.active_player.overlay` (line 65, via `cancel()`).

## Findings

- **[Smell] — duplicated online/offline player-lookup branching**, identical pattern to [ActivePlayerHUD.md](./ActivePlayerHUD.md)'s `set_player_name`, repeated *twice* in this file alone (once for the attacking player, lines 44–49; once for the opponent, lines 54–59). Four total copies of the same branch across two files. *Severity guess:* medium.
- **[Dead code] — two commented-out lines using a third, apparently abandoned lookup path.** Lines 50 and 60: `#player_icon.color = GamePlay.colors[str(int(player_country.occupier.name) + 1)]` and the opponent equivalent. These reference a `GamePlay.colors` dictionary keyed by `occupier.name + 1` that isn't used anywhere else in the currently-live code path — either a prior color-lookup scheme that was replaced but not deleted, or a hint that `GamePlay.colors` still exists and is used elsewhere (to confirm in Phase 3). *Severity guess:* low.
- **[Smell] — `attack_details()` overloads "no player country yet" and "reset to default 8" into one code path** (lines 28–34) using `pc == null` as a sentinel for both "menu just opened, show placeholder" and (potentially) "no country was actually passed." If a caller ever legitimately wants to clear the display without showing a fake "8 troops available" default, there's no way to distinguish that from initial boot. *Severity guess:* low.

## Cross-references

Duplicated lookup logic with [ActivePlayerHUD.md](./ActivePlayerHUD.md). Depends on `Country` (see [Country.md](../gameplay/Country.md)) for `.troops`, `.occupier`, `.get_name()`.
