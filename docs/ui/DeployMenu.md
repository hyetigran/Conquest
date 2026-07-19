# DeployMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/DeployMenu.gd` · 40 lines · Layer: UI · Audited: 2026-07-18

## Purpose

The troop-deployment overlay used during the Draft/Placement phases — lets the active player pick how many troops (of those available) to place on a chosen country.

## Lifecycle

`_ready()` calls `add_troops(7)` — a hardcoded placeholder count shown before the real call from `DraftState`/`PlacementState` arrives, same pattern as `AttackingMenu`'s hardcoded 8.

## Surface

- `add_troops(troops, c)` (15–24) — sets slider bounds/label for the chosen country.
- `cancel()` (26–28), `deploy()` (30–33) — dismiss / emit `deployed` with the chosen count and country.
- `value_changed(value)` (35–39) — pluralization only, duplicated verbatim from `AttackingMenu.value_changed` and `MoveMenu.value_changed`.

## Permissions & validation

- **Checks missing:** `add_troops` takes `troops` at face value with no check that `troops > 0`; a caller passing 0 would set a slider with `max_value = 0`, silently unusable with no feedback.

## Data touches

None.

## Shared state

`GamePlay.game.active_player.overlay` via `cancel()`.

## Findings

- **[Smell] — `value_changed`'s pluralization logic is duplicated three times** (here, in [AttackingMenu.md](./AttackingMenu.md), and in [MoveMenu.md](./MoveMenu.md)), byte-identical each time:
  ```
  if value == 1:
  	troops_range.suffix = "troop"
  else:
  	troops_range.suffix = "troops"
  ```
  A single shared helper (or a `TroopsRange` custom control) would remove three copies of the same four lines. *Severity guess:* low (maintainability only).
- **[Smell] — hardcoded placeholder value (`7`) shown before real data arrives** (line 13), same pattern as `AttackingMenu`'s hardcoded `8`. Cosmetic today (overwritten almost immediately by the real caller), but if a caller ever fails to call `add_troops` again — e.g. an error before `DraftState` hands off real data — the player would see and could act on a fabricated "7 troops available" figure. *Severity guess:* low.

## Cross-references

Duplicate pluralization logic with [AttackingMenu.md](./AttackingMenu.md) and [MoveMenu.md](./MoveMenu.md).
