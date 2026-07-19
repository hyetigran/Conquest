# StartGameMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/StartGameMenu.gd` · 19 lines · Layer: UI · Audited: 2026-07-18

## Purpose

The main-menu overlay shown after clicking "Play Online" (see [Menu.md](./Menu.md) `play()`) — offers Join or Create, and (per the commented-out code below) once apparently let the player set a player count before starting.

## Surface

- `cancel()` (7–9) — hide-if-parent-is-ColorRect, same pattern as `OptionsMenu.cancel`.
- `start_game()` (11–13) — navigates to `Game.tscn`.
- `_on_Join_pressed()` / `_on_Create_pressed()` (15–19) — navigate to `JoinGameMenu.tscn` / `HostGameMenu.tscn`.

## Findings

- **[Dead code] — a player-count field was wired up and then disabled, leaving stale, now-incorrect code commented out.** Line 5: `#onready var players = $Info/PlayersRange`; line 12: `#GamePlay.players = players.value`. Beyond simply being commented out, the referenced field name `GamePlay.players` **does not exist** on the `GamePlay` autoload as of this reading — `game_play.gd` declares `var players = 3` (a different, apparently unrelated field — to be confirmed in Phase 3) and a distinct `var number_of_players: int = 2` (the field [Menu.md](./Menu.md)'s `create_offline_game()` actually sets). So even if someone uncommented this code to "restore" the feature, it would silently write to the wrong `GamePlay` field rather than the one that (per `Menu.gd`) actually drives player count. `start_game` (11–13). *Severity guess:* low as dead code, but a real trap for anyone who re-enables it without checking `game_play.gd` first.
- **[Smell] — same fragile `get_parent() is ColorRect` overlay-dismissal pattern** as [OptionsMenu.md](./OptionsMenu.md) and [StartGameMenu.md](./StartGameMenu.md) itself here (7–9). *Severity guess:* low.

## Cross-references

Depends on [game_play.md](../gameplay/game_play.md) for the `players` vs. `number_of_players` field confusion noted above. Same overlay-dismissal pattern as [OptionsMenu.md](./OptionsMenu.md).
