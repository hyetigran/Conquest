# FortifyState.gd — Analysis

> Source: `Source/Gameplay/StateMachine/PlayerStates/FortifyState.gd` · 90 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The turn's final phase — move troops between any two of the player's own countries that are connected through a chain of the player's own territory (not just direct neighbors), then end the turn.

## Surface

- `push_countries_in_fortify_state` (13–25) — deactivates any owned country with only 1 troop or no directly-adjacent allied country.
- `select_country` / `activate_bordering_countries` (47–59) — a recursive flood-fill that activates every country reachable from the selected one through a chain of same-occupier territory, correctly guarding against re-visiting already-`Selected`/`Active` nodes to terminate the recursion.
- `country_clicked` (36–45) — select a source, then a destination; opens `MoveMenu` in `"Fortify"` mode (see [MoveMenu.md](../ui/MoveMenu.md)'s finding about that bare-string state parameter).
- `go_pressed` (68–69) — ends the turn immediately (fortify is optional — a player can decline to move anything and just end their turn).
- `troops_moved` (74–79) — applies the move and ends the turn (fortify allows exactly one move per turn, unlike a free-form move phase).

## Findings

- **[Smell] — `unselect_country` fully re-runs the O(countries × neighbors) `push_countries_in_fortify_state` scan just to deselect one country.** (61–63) Clicking to cancel a selection re-evaluates every owned country's eligibility from scratch rather than simply reverting the specific countries that `select_country`'s flood-fill had activated. Functionally fine at this game's scale (≤6 players × ≤42 countries), but architecturally it means "select" and "deselect" aren't inverses of the same operation — deselect works by recomputing global state rather than undoing local state. *Severity guess:* low (performance/maintainability, not correctness at this scale).

## Cross-references

Shares the `"Fortify"` bare-string state-dispatch value with [MoveMenu.md](../ui/MoveMenu.md). Uses `bordering_countries_nodes` correctly, same as [AttackState.md](./AttackState.md).
