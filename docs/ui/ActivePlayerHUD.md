# ActivePlayerHUD.gd — Analysis

> Source: `Source/Gameplay/HUD/ActivePlayerHUD.gd` · 51 lines · Layer: UI · Audited: 2026-07-18

## Purpose

Registered as a global class (`ActivePlayerHUD`, base `HBoxContainer`). Shows the current player's turn indicator during a match: player icon/color, name, current turn-state text ("Draft"/"Attack"/etc.), a reinforcement/draft counter, and the "Go"/end-turn button.

## Lifecycle

No `_ready()` override — purely reactive to setter calls from the game/state-machine layer (`Game.gd` / `PlayerState` subclasses, confirmed in Phase 3).

## Surface

- `set_icon_color`, `set_player_name`, `set_player_state`, `set_reinforcement_label` — display setters called by the active `PlayerState`.
- `hide_draft_icon`/`show_draft_icon`, `hide_go_button`/`show_go_button` — visibility toggles per turn phase.
- `go_pressed()` (47–50) — end-turn button handler; plays a click sound and re-emits `go_pressed` for whoever owns this HUD to react to.

## Permissions & validation

- **Checks missing:** `set_player_name` (19–27) indexes `Server.my_lobby.players[player_number]` (online) or `GamePlay.players_data[str(player_number)]` (offline) with no bounds/existence check. An out-of-range or stale `player_number` throws at runtime rather than degrading gracefully.

## Data touches

None (pure display).

## Shared state

Reads `GamePlay.online`, `GamePlay.players_data`, `GamePlay.interface_sound`; reads `Server.my_lobby.players`, `Server.player_id`.

## Findings

- **[Smell] — duplicated online/offline branching for player color/name lookup.** `set_player_name` (19–27) repeats the same `if GamePlay.online / else` pattern seen verbatim in [AttackingMenu.md](./AttackingMenu.md) (`attack_details`, lines 44–59) — the exact same two-branch lookup (`Server.my_lobby.players[...]` vs `GamePlay.players_data[...]`) is copy-pasted across at least two files instead of living in one place (e.g. a `GamePlay.get_player(number)` helper). Any future change to how player identity is resolved (e.g. adding a third data source) has to be hunted down and repeated in every call site. *Severity guess:* medium (maintainability / drift risk).

## Cross-references

Shares the online/offline player-lookup duplication with [AttackingMenu.md](./AttackingMenu.md). Depends on [game_play.md](../gameplay/game_play.md) and [Server.md](../server/Server.md) data shapes.
