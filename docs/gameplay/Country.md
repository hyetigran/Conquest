# Country.gd — Analysis

> Source: `Source/Gameplay/Map/Country/Country.gd` · 214 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

Registered global class `Country` (base `Area2D`) — the script on every one of the 42 country scenes (`Source/Gameplay/Map/Country/Countries/*.tscn`, all instancing the shared `Country.tscn` template — see [country-scenes.md](../data/country-scenes.md)). Handles per-country troop count, occupier, click/hover input, its own `CountryState` FSM (Active/Inactive/Selected — see [CountryState docs](./ActiveState.md)), and adjacency lookups.

## Lifecycle

`_ready()` → `setup()` (25–29): sets display name, enters the initial `ActiveState`, zeroes troops, and (deferred, so it runs after all sibling `Country` nodes exist) resolves this country's neighbor names into actual node references via `setup_bordering_countries()`.

## Surface (selected)

- `setup_bordering_countries()` (31–36) — populates `GamePlay.bordering_countries_nodes[name]` in place with resolved `Country` node references (see [game_play.md](./game_play.md) for the duplicated-dictionary finding this depends on).
- `_process` / `update()` — two separate per-frame-ish state-machine tick paths (see Findings — they are *not* equivalent).
- `_on_mouse_entered` / `_on_mouse_exited` / `_on_input_event` — hover/click handling, each independently re-checking turn ownership online.
- `country_clicked()` — delegates to `country_state.clicked(self)`.
- Troop mutators (`increment_troops`, `decrement_troops`, `add_troops`, `subtract_troops`, `set_troops`) and `set_occupier`, `change_state`, `play_active_click`/`play_selected_click` — all follow the same `net_call`/`Server.send_node_func_call` replication convention documented in [Player.md](./Player.md).
- `get_name()` / `space_pascal_case()` (78–93) — derives a human-readable display name ("Great Britain") from the PascalCase node name ("GreatBritain") by inserting spaces before capital letters.

## Permissions & validation

- **Checks present:** `_on_mouse_entered`, `_on_mouse_exited`, `_on_input_event`, and `update()` each independently re-implement the same three-line turn-ownership check (see Findings — duplication).
- **Checks missing:** `_process` (48–56) has the identical check **commented out** (lines 49–51) while still calling `country_state.update(self)` unconditionally every frame for every `Country` node on every client — see Findings.

## Data touches

None directly (reads/writes `GamePlay.bordering_countries_nodes` in place, and mutates its own fields).

## Shared state

Mutates `GamePlay.bordering_countries_nodes[name]` (31–36). Reads `GamePlay.online`, `GamePlay.game.active_player`. Reads `Server.my_lobby.players`, `Server.player_id`. Calls `Server.send_node_func_call` (9 call sites).

## Findings

- **[Bug] — `_process()` runs the country's state-machine tick every frame with its turn-ownership guard disabled, while a separately-named `update()` method (invoked explicitly from `PlacementState.gd:28`) carries the *same* guard, live.** Lines 48–63:
  ```gdscript
  func _process(delta):
  #	if GamePlay.game.active_player:
  #		if Server.my_lobby.players[int(GamePlay.game.active_player.name)].id != Server.player_id:
  #			return
  	if country_state.has_method("update"):
  		var state = country_state.update(self)
  		if state:
  			change_state(state)

  func update():
  	if GamePlay.online and GamePlay.game.active_player:
  		if Server.my_lobby.players[int(GamePlay.game.active_player.name)].id != Server.player_id:
  			return
  	var state = country_state.update(self)
  	if state:
  		change_state(state)
  ```
  `_process` is a Godot engine callback that fires automatically, every frame, for every `Country` node on every connected client — with the ownership check that would restrict state transitions to the active player's own client **commented out**. `update()` is a plain method with the *same* underlying `country_state.update(self)` call, correctly guarded — but it is not an engine callback; it only runs when something calls `country.update()` explicitly, which happens at exactly one site (`PlacementState.gd:28`). The practical effect: the guarded code path runs rarely and only during placement, while the unguarded path runs constantly, for every country, on every client, regardless of turn. Whether `CountryState.update()` implementations ([ActiveState.md](./ActiveState.md), [SelectedState.md](./SelectedState.md), [InActiveState.md](./InActiveState.md)) can actually cause an out-of-turn state change through this path is the deciding factor for real-world impact — flagged for Phase 6 deep dive once those three files are read. `_process` (48–56) vs. `update` (57–63). *Severity guess:* high pending Phase 6 confirmation (a live, always-running path with a security-relevant check disabled, next to a rarely-used path where the same check is enabled, is exactly the shape of a real out-of-turn-action bug).

  **Phase 6 deep-dive update (2026-07-18):** confirmed against [CountryState.md](./CountryState.md)/[ActiveState.md](./ActiveState.md)/[SelectedState.md](./SelectedState.md) — the disabled guard's practical blast radius is narrower than initially flagged. The only transition `country_state.update()` can trigger (`ActiveState.update()`'s branch, lines 13–22 there) is driven entirely by *globally shared* state (`GamePlay.game.active_player`, `country.occupier`, `country.troops`) that should already be identical across every connected client, not by anything specific to the executing client's own identity. So the missing guard doesn't let an out-of-turn client force a *different* outcome than the in-turn client would reach — every client's `_process` independently evaluates the same true/false condition and reaches the same conclusion. The real cost is that **every connected client**, not just the active player's, ends up calling `change_state()` → `Server.send_node_func_call()` for the same transition, all broadcasting the identical redundant RPC. Revised assessment: *medium* (wasteful redundant network traffic on every qualifying frame, not a correctness/security gap) rather than the *high* originally guessed pending this confirmation. The duplication-of-the-guard smell below remains the more actionable finding here.
- **[Smell] — the same three-line turn-ownership check is copy-pasted four times verbatim** (`update` 58–60, `_on_mouse_entered` 96–98, `_on_mouse_exited` 102–104, `_on_input_event` 108–110), with a fifth, commented-out copy in `_process` (49–51). Any future fix to this check (e.g., handling a null `active_player` more gracefully, or fixing an edge case) has to be applied in up to five places by hand. A single `func can_interact() -> bool` helper would remove the duplication and make the `_process` guard's absence far more visible as an outlier. *Severity guess:* medium (maintainability, and it's precisely this duplication that let the `_process` copy drift out of sync with the other four).

## Cross-references

Depends on [game_play.md](./game_play.md)'s adjacency dictionaries. The `_process`/`update()` guard asymmetry needs Phase 6 confirmation against [ActiveState.md](./ActiveState.md), [SelectedState.md](./SelectedState.md), [InActiveState.md](./InActiveState.md), and its one call site in [PlacementState.md](./PlacementState.md). Shares the `net_call` replication convention with [Player.md](./Player.md) — see that file for the systemic writeup.
