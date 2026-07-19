# InActiveState.gd — Analysis

> Source: `Source/Gameplay/StateMachine/CountryStates/InActiveState.gd` · 51 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The "not currently selectable" country state — the default/rest state for countries not eligible for the active player's current action (owned by someone else during Placement/Fortify, or without a viable target during Attack).

## Surface

- `active_player_changed(country, new_player)` (21–32) — the turn-transition eligibility check: becomes `active` if all countries are occupied and it's the new player's own country during Placement/Fortify, or if it's the new player's own country with >1 troop and has an attackable enemy neighbor during Attack.

## Findings

- **[Bug] — shadowed loop variable causes a runtime type error whenever this method's Attack-phase branch executes.** Lines 25–32:
  ```gdscript
  if new_player.player_state is AttackState:
  	if country.occupier == new_player and country.troops > 1:
  		var has_enemy = false
  		for country in GamePlay.bordering_countries[country.name]:
  			if country.occupier != new_player:
  				has_enemy = true
  		if has_enemy:
  			return country_states.active.new()
  ```
  The `for` loop's iteration variable is named `country` — identical to the method's own parameter `country: Country` (line 21). GDScript allows this (no shadowing warning at parse time in Godot 3), but it means that from the moment the loop starts, `country` no longer refers to the `Country` node passed into the function — it refers instead to each element of `GamePlay.bordering_countries[country.name]`, which (per [game_play.md](./game_play.md)) is a plain **String** (a neighboring country's *name*, e.g. `"China"`), not a `Country` node. The very next line, `if country.occupier != new_player:`, then calls `.occupier` on a String, which has no such property — this throws a runtime error ("Invalid get index 'occupier' (on base: 'String')") every single time this branch is reached. The correct dictionary to iterate is `GamePlay.bordering_countries_nodes[country.name]` (the node-resolved counterpart — used correctly for the identical purpose in [SelectedState.md](./SelectedState.md)'s `clicked()`, lines 25–27 there), with a loop variable name that doesn't collide with the outer parameter (e.g. `neighbor`). This branch runs on every turn transition into Attack phase, for every country the new active player owns with >1 troop — i.e., on the most common turn boundary in the game, for essentially every match with any Attack phase at all. `active_player_changed` (25–32). *Severity guess:* critical (a near-guaranteed runtime error on a core, frequently-hit game-logic path — this is the single highest-confidence bug found in this audit).

## Cross-references

Uses the wrong dictionary from [game_play.md](./game_play.md) (`bordering_countries` instead of `bordering_countries_nodes`); contrast with [SelectedState.md](./SelectedState.md)'s `clicked()`, which uses the correct one for the equivalent lookup — strong evidence this is a copy/adapt mistake rather than an intentional divergence.
