# PlacementState.gd — Analysis

> Source: `Source/Gameplay/StateMachine/PlayerStates/PlacementState.gd` · 46 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The very first phase of a match — players take turns claiming unoccupied countries one at a time until the whole 42-country map is claimed, then (once fully claimed) continue cycling through this same state to place any remaining starting troops on their own territory.

## Surface

- `country_clicked(player, country)` (20–29) — the entire phase's logic in one method: claim an unoccupied country (assign occupier, increment global occupied-country counter, register with the player), or add a troop to an already-owned country once the whole map is claimed; either way, ends the player's turn immediately (`emit_signal("turn_completed")` — placement is strictly one-country-per-turn).
- `all_troops_placed(player)` (34–35) — transition trigger once a player has placed all their starting troops (checked externally by [Game.md](./Game.md)'s `active_player_changed`/`all_players_placed_all_troops`).

## Findings

- **[Smell] — `country_clicked`'s single `if` condition conflates two structurally different actions ("claim empty land" vs. "reinforce owned land") with no comment distinguishing them.** Lines 20–21: `if not country.occupier or (country.occupier == player and GamePlay.game.occupied_countries == GamePlay.game.total_countries):` — correct as far as this reading can verify (claim-phase vs. reinforce-phase split on whether the map is fully claimed yet), but the two cases share one code path with only nested `if not country.occupier:` (22) distinguishing them internally, making the method's single responsibility hard to state in one sentence. Not a bug, but the density here is exactly the kind of code that hides an edge case a straightforward read-through can miss. *Severity guess:* low.
- **[Smell] — no bounds/re-entrancy guard on `emit_signal("turn_completed")`.** (29) Every successful claim/reinforce ends the turn unconditionally, immediately — there is no protection against this being invoked twice in the same frame (e.g., a rapid double-click or, in principle, a duplicate replicated network call) beyond whatever externally throttles the underlying click signal ([Country.md](./Country.md)'s `_on_input_event`). Not confirmed to be reachable; flagged for completeness. *Severity guess:* low.

## Cross-references

Its one explicit call to `country.update()` (line 28) is the sole call site for [Country.md](./Country.md)'s guarded `update()` method — see that file's `_process`-vs-`update()` finding for why this matters.
