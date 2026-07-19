# DraftState.gd — Analysis

> Source: `Source/Gameplay/StateMachine/PlayerStates/DraftState.gd` · 105 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The reinforcement-calculation phase at the start of every turn (after the first): computes how many troops the player gets this turn from base occupation count, continent-control bonuses, and a one-time "first turn" positional bonus — then waits for the player to deploy them via `PlacementState`-shared UI (`DeployMenu`).

## Lifecycle

`enter(player)` (14–23): if the player is already eliminated, immediately emits `turn_completed` and returns (skips this player's turn entirely) — otherwise computes and grants reinforcements, then configures the HUD.

## Surface

- `add_reinforcement_amount` (25–38) — base bonus: `max(3, floor(countries_occupied / 3))`.
- `add_continental_bonus` (40–50) — grants `bonus_troops[continent]` if the player occupies every country in that continent.
- `add_first_turn_bonus` (52–65) — see Findings; a positional bonus applied once per player, on their first turn only.
- `country_clicked` / `troops_deployed` (76–88) — opens/resolves the `DeployMenu` overlay.
- `go_pressed` (90–91) — advances to `AttackState`.

## Findings

- **[Smell] — `add_first_turn_bonus`'s bonus formula gives the *last* player in turn order the *smallest* bonus (zero), the opposite of what a turn-order-compensation mechanic should do.** Lines 52–65:
  ```gdscript
  func add_first_turn_bonus(player: Player):
  	if player.first_turn:
  		var player_name = int(player.name) + 1
  		if player_name > 3:
  			var turn_bonus = player_name % 3
  			...
  			player.increment_reinforcement(turn_bonus)
  		player.first_turn = false
  ```
  For a 6-player game, seat positions 4/5/6 (`player_name` here is a 1-indexed seat position, not a display name — see the naming finding below) get `turn_bonus = player_name % 3` = `1, 2, 0` respectively. Positions 1–3 get no bonus at all (the `player_name > 3` guard skips them). So the *last* player to take a first turn — the one who has watched the most opponents place territory before acting, and who a turn-order-compensation bonus would most plausibly exist to help — gets **zero**, identical to the first three players who get no bonus check at all; the fourth and fifth players get 1 and 2 respectively. Whether this formula was intended to look like this is impossible to tell from the code alone (no comment explains the design), but it doesn't produce a monotonic curve in either direction, which is the shape any "later players get more" or "later players get less" balancing mechanic should have. `add_first_turn_bonus` (52–65). *Severity guess:* medium (game-balance defect, confirmable by playing a 5–6 player game and comparing starting bonuses across seats — not a crash).
- **[Smell] — the local variable `player_name` holds a 1-indexed integer seat position, not a name.** Line 54: `var player_name = int(player.name) + 1` — everywhere else in the codebase (`player.name` is the Godot node name, a stringified seat index like `"0"`), the identifier `player_name` (or `name`) is used for an actual display name string (e.g. `GamePlay.players_data[player.name].name`, used two lines later in the *same function*'s `else` branch, line 61: `" for being at " + str(player_name) + " position"` — where `player_name` is concatenated as a number). Reusing this name for an integer position, in a function that also deals with genuine player-name strings, invites misreading. *Severity guess:* low (readability only).
- **[Smell] — `get_class()` returns `"Reinforce"` while `get_state_name()` returns `"draft"` for the same state.** (93–105) The class is named `DraftState`, its FSM transition key is `"draft"`, but the HUD-facing label (`get_class()`, used by [ActivePlayerHUD.md](../ui/ActivePlayerHUD.md) via `player.hud.set_player_state(get_class())`) and the special-cased first-turn check in [Player.md](./Player.md) (`turn_complete`: `if player_state.get_class() == "Reinforce" and first_turn:`) both key off the string `"Reinforce"` instead. Three different names (`DraftState`, `"draft"`, `"Reinforce"`) for one concept, spread across three files, makes tracing this state by grep unreliable — searching for "Draft" won't find the `Player.gd` special case, and vice versa. *Severity guess:* low (maintainability/traceability).

## Cross-references

The naming-drift finding connects directly to [Player.md](./Player.md)'s `turn_complete` (which pattern-matches on `"Reinforce"`) and [ActivePlayerHUD.md](../ui/ActivePlayerHUD.md) (which displays `get_class()`'s value verbatim).
