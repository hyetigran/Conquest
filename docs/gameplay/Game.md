# Game.gd — Analysis

> Source: `Source/Gameplay/Game/Game.gd` · 153 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

Per-match orchestrator, instanced once per game (`Game.tscn`, reached from `Menu.create_offline_game()`, `Lobby.start_game()`, `GameoverMenu.play_again()`). Spawns player nodes, seeds initial troop counts, wires the quit/options overlays, and tracks match-wide counters (occupied countries, elimination count).

## Lifecycle

`_ready()` → `setup()` (26–32): `spawn_players()` → `set_initial_troops()` → `setup_hud()` → `setup_music()` → `setup_game()` (registers itself as `GamePlay.game`) → `connect_signals()`.

## Surface

- `spawn_players()` (34–42) — instances one `Player` per seat.
- `set_initial_troops()` (44–51) — Risk-standard troop allocation: `45 - 5*(players-1)`.
- `active_player_changed(...)` (75–84) — the turn-boundary hook: updates all countries' turn-state, checks the placement phase's completion, optionally auto-places.
- `auto_place_troops()` (86–94) — picks a uniformly random unowned/owned country by index and clicks it until a troop gets placed, used for "auto-place remaining troops" convenience.
- `increment_occupied_countries(net_call)` (147–152) — one of the few counters replicated over the network via the `net_call`/`Server.send_node_func_call` convention shared with [Player.md](./Player.md) and [Country.md](./Country.md).

## Permissions & validation

- **Checks missing:** none of this file's methods independently re-validate that a caller is authorized — it trusts callers (`Player`, `Country`, network dispatch) to have already checked turn ownership.

## Data touches

None (in-memory scene graph only).

## Shared state

Sets `GamePlay.game = self` (61) — the only way other files reach the live match. Reads `GamePlay.number_of_players`, `GamePlay.online`, `GamePlay.in_game_volume`. Reads `Server.my_lobby.players`, `Server.my_lobby.current_players`.

## Findings

- **[Bug] — `spawn_players()` reuses one variable, `current_players`, as both a player *count* (offline) and the entire players *Dictionary* (online), producing different loop semantics for the two branches and inheriting the upstream lobby-creation bug.** Lines 34–42:
  ```gdscript
  func spawn_players():
  	var current_players = GamePlay.number_of_players
  	if GamePlay.online:
  		current_players = Server.my_lobby.players
  	for i in current_players:
  		var p = player_scene.instance()
  		p.name = str(i)
  		players.add_child(p)
  	players.setup()
  ```
  Offline: `current_players` is an `int` (e.g. `2`), so `for i in current_players` iterates `0, 1` — spawns exactly `number_of_players` players, correct. Online: `current_players` is reassigned to `Server.my_lobby.players`, a **Dictionary** — `for i in <Dictionary>` iterates over its *keys*, not a count, so the number of `Player` nodes spawned equals however many keys that dictionary happens to have, not `Server.my_lobby.max_players`. This directly compounds [HostGameMenu.md](../ui/HostGameMenu.md)'s finding: the client-side lobby-creation code populates `players_list` with exactly one entry (keyed by the host's own `Server.player_id`) regardless of the requested player count, due to a loop bug there. If that malformed structure is what ends up in `Server.my_lobby.players` by the time a match starts, an online game would spawn **one `Player` node** no matter how many humans actually joined — every non-host player would have no corresponding `Player` node in the scene tree. Confirming the actual blast radius requires seeing what the companion server does with the client-supplied roster (out of this repo's scope), but the client-side logic here is unambiguously fragile: reusing one variable for two different types/semantics based on a boolean branch is itself a defect independent of whether the upstream bug is ever fixed. `spawn_players` (34–42). *Severity guess:* critical (core online multiplayer player-spawning), pending server-side confirmation of exact blast radius.
- **[Smell] — `auto_place_troops()`'s termination is a `while (not placed)` polling loop with no bound.** (86–94) Repeatedly picks a random country index (0–41) and calls `country_clicked()`, looping until *some* country's troop count increases. If every country is already fully owned/ineligible in a way `country_clicked()` can't act on (state-machine dependent, to confirm in [CountryState docs](../gameplay/ActiveState.md)), this is an infinite loop with no iteration cap or fallback — a hang rather than a crash. *Severity guess:* medium (latent, state-machine-dependent).

## Cross-references

Confirms and compounds [HostGameMenu.md](../ui/HostGameMenu.md)'s lobby-slot bug. Drives [Player.md](./Player.md) and [Country.md](./Country.md) via the shared `net_call`/replication convention (see [Player.md](./Player.md) Findings for the systemic writeup of that pattern).
