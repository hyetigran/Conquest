# Player.gd — Analysis

> Source: `Source/Gameplay/Player/Player.gd` · 282 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The largest and most central gameplay file — one instance per seat in a match. Owns a player's territory list, troop/reinforcement counters, turn-state (`player_state`, an instance of the `PlayerState` FSM — see [PlayerState.md](./PlayerState.md)), and the four HUD overlays (`deploy_menu`, `attacking_menu`, `move_menu`, `gameover_menu`). Nearly every player action in the game funnels through this file.

## Lifecycle

`_ready()` → `setup()` (37–42): deactivates, rolls starting reinforcements, wires HUD overlay signals, enters the initial `PlacementState`, connects `turn_completed`.

## Surface (selected)

- `occupy_country` / `leave_country` (+ `_by_path` network-dispatch variants) — territory bookkeeping, including per-continent occupied-count tracking used for continent bonuses.
- `troops_moved`, `player_attacked`, `go_pressed`, `troops_deployed`, `country_clicked` — all delegate to `player_state`'s matching method and, if it returns a new state, call `change_state`.
- `change_state(state, net_call)` (208–221) — the FSM transition: exits old state, frees it, enters new state, and (if locally initiated) replicates the transition by name via `Server.send_node_func_call`.
- A large family of counter mutators — `set_initial_troops`, `increment_initial_troops`, `decrement_initial_troops`, `set_reinforcement`, `increment_reinforcement`, `decrement_reinforcement`, `add_reinforcements` — all following the same `net_call`-guarded replication convention (see Findings).
- `eliminate(net_call)` (261–272) — marks the player eliminated.
- `_input`/`_process` — per-frame turn-lock re-checks and the FSM's `update()` tick.

## Permissions & validation

- **Checks present:** `go_pressed` (134–136) and `_input` (230–233) both re-check, before acting, that (online) `Server.my_lobby.players[int(name)].id == Server.player_id` — i.e., a client only acts on the `Player` node representing its own local identity, not on other clients' player nodes it also has instantiated locally. This is the client-side half of turn/identity enforcement (server-side enforcement, if any, is out of scope).
- **Checks missing:** `_process` (251–259) ticks `player_state.update(self)` on *every* `Player` node every frame with **no such identity/turn guard** — contrast with `_input` and `go_pressed`, which do check. A commented-out copy of the check exists right above it (255–256: `#	if Server.my_lobby.players[int(name)].id != Server.player_id: #		return`), meaning the guard was written and then deliberately disabled for this specific call path. Whether `PlayerState.update()` implementations are safe to run unconditionally for non-local players (i.e., they're read-only/no-op unless certain other conditions hold) determines whether this is exploitable; needs Phase 6 cross-check against [PlayerState.md](./PlayerState.md) and subclasses. `_process` (251–259). *Severity guess:* medium-high pending that check.

## Data touches

None (in-memory scene graph + the manual replication calls below).

## Shared state

Reads `GamePlay.online`, `GamePlay.players_data`, `GamePlay.total_countries_in_continents`. Reads `Server.my_lobby`, `Server.player_id`. Calls `Server.send_node_func_call` extensively (16 call sites).

## Findings

- **[Architecture smell] — a hand-rolled RPC/replication convention, repeated ~16 times in this file alone, with no enforcement that new mutators follow it correctly.** Every state-mutating method takes a trailing `net_call=false` parameter; the pattern is: perform the mutation → `if net_call: return` (stop here if this call *arrived* from the network, to avoid re-broadcasting) → otherwise, if online, call `Server.send_node_func_call(get_path(), "<this method name>", args...)` to push the mutation to peers. There is no shared helper, decorator, or base-class mechanism enforcing this — it's copy-pasted by hand into every method, with the method's own name passed as a string literal (`"occupy_country_by_path"`, `"turn_complete"`, etc. — see next finding). Any new mutator a future contributor adds that *forgets* this boilerplate will work fine locally and silently desync every other client. This is a systemic design fragility, not a single bug. *Severity guess:* medium (design-level; the risk is future changes, not necessarily current behavior).
- **[Bug] — several reinforcement-related mutators have their replication call commented out, while sibling methods for the same concept *are* replicated — an inconsistency, not a deliberate design choice.** `setup_reinforcements()` (52–56): rolls `randi() % 10 + 3` — **a random value** — and the line `#Server.send_node_func_call(...)` is commented out, so each client independently re-rolls its own random reinforcement count for the same `Player` node with no shared seed or server authority. In online play, different clients will disagree about how many reinforcements a player starts with. Likewise `set_reinforcement()` (181–186) and `increment_reinforcement()` (188–193) have their replication line commented out, while the sibling `decrement_reinforcement()` (195–201) and `add_reinforcements()` (223–228) **do** call `Server.send_node_func_call`. There's no comment or explanation for why some reinforcement mutators sync and others don't — it reads as an oversight (or an incomplete change) rather than intent. Lines 52–56, 181–186, 188–193 (disabled) vs. 195–201, 223–228 (enabled). *Severity guess:* high for `setup_reinforcements` specifically (random + unsynced = guaranteed multiplayer desync of a core resource every match), medium for the other two (deterministic desync only if client and server/other-peers' *inputs* to these calls ever diverge, which is plausible given they're called from state-machine logic that itself reacts to per-client events).
- **[Bug] — `eliminate()`'s side effect (posting the "X has been eliminated" activity message) only happens on the *receiving* end of the network call, never on the client that originates the elimination — and never at all offline.** Lines 261–272:
  ```gdscript
  func eliminate(net_call=false):
  	eliminated = true
  	if net_call:
  		var player_name
  		...
  		set_activity(player_name + " has been eliminated!")
  		return
  	if not GamePlay.online: return
  	Server.send_node_func_call(get_path(), "eliminate")
  ```
  Every other mutator in this file follows "do the mutation, exit early via `if net_call: return` with *no* extra work, otherwise (locally-initiated) replicate." This method inverts that: the notification-worthy side effect (`set_activity(...)`) is placed *inside* the `net_call` branch — i.e., it only runs when this call arrived *from* the network (so only other clients see the toast) — and the locally-initiated path (`net_call == false`, the client where the elimination actually happened) does nothing but flip the flag and forward the message onward. In **offline mode**, `net_call` is always `false` on the only call this ever gets, so `set_activity` never runs at all — offline players are never told a player was eliminated. `eliminate` (261–272). *Severity guess:* high (a concretely wrong, easily reproducible behavior gap: play any offline game to a player elimination and observe no notification).

## Cross-references

Compounds [Game.md](./Game.md)'s `spawn_players()` finding (both are online player-roster issues). The `net_call` replication convention is the same one used in [Country.md](./Country.md) and [PlayersQueue.md](./PlayersQueue.md) — see those for the pattern's other instances. `_process`'s disabled guard should be cross-checked against [PlayerState.md](./PlayerState.md) in Phase 6.
