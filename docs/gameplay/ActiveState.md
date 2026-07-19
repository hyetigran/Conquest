# ActiveState.gd — Analysis

> Source: `Source/Gameplay/StateMachine/CountryStates/ActiveState.gd` · 55 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The "selectable" country state — a country the active player can currently interact with (click to select/attack/fortify from). Transitions to `InActiveState` if it stops being eligible (e.g. reduced to 1 troop mid-attack, or ownership/turn context changes).

## Surface

- `update(country)` (13–24) — per-tick check: if the active player is in `AttackState` and this country (which they occupy) has exactly 1 troop, transition to `InActiveState` (a country can't be used as an attack source with only its mandatory defender left).
- `clicked(country)` (29–32) — plays a sound and delegates to `GamePlay.game.active_player.country_clicked(country)`.
- `active_player_changed(country, new_player)` (34–37) — if the new active player is in `PlacementState`/`FortifyState` and this country is owned by someone else, become inactive (can't place/fortify on someone else's territory).
- `change_country_state(country, state_name)` (45–49) — string-keyed transition dispatch (`"selected"`/`"in_active"`), same pattern as [MoveMenu.md](../ui/MoveMenu.md)'s bare-string state dispatch.

## Findings

- **[Smell] — dead debug-input code.** Lines 23–24: `#	if Input.is_action_just_pressed("ui_accept"): #		return country_states.in_active.new()` — leftover manual-testing shortcut, commented out but not removed. *Severity guess:* low.
- **[Smell] — `update()`'s guard is a five-level nested `if`** (16–22) instead of a combined boolean condition or early-return chain — purely a readability smell, not a correctness issue; flagged because this exact deep-nesting shape recurs across the `CountryState` family and makes the already-subtle turn/state logic harder to verify by eye (directly relevant to how the [Country.md](./Country.md) `_process`/`update()` guard bug went unnoticed). *Severity guess:* low.

## Cross-references

Called from [Country.md](./Country.md)'s `_process`/`update`. Siblings: [InActiveState.md](./InActiveState.md), [SelectedState.md](./SelectedState.md). Base: [CountryState.md](./CountryState.md).
