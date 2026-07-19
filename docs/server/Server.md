# Server.gd — Analysis

> Source: `Source/Server/Server.gd` · 208 lines · Layer: business logic (autoload singleton `Server`) · Audited: 2026-07-18

## Purpose

The networking façade — an autoload that owns the lobby/session state (`my_lobby`, `player_id`, `connected`, etc.), exposes the game's entire client→server API (`create_lobby`, `join_lobby`, `send_message`, `start_game`, …), and picks/owns one of two interchangeable transport backends ([HighLevelServer.md](./HighLevelServer.md) or [WebSocketsServer.md](./WebSocketsServer.md)) to actually move bytes. It is also the receiving end of a generic remote-method-call mechanism used throughout [Player.md](../gameplay/Player.md), [Country.md](../gameplay/Country.md), etc. to replicate game-state mutations across clients.

## Lifecycle

`_ready()` (39–42): optionally overrides `SERVER_IP` to `local_ip`, then immediately calls `connect_to_server()` — the client starts dialing out before any menu is shown. `connect_to_server()` (44–52) instances whichever backend applies (see Findings), wires its connection signals, and hands it the target address.

## Surface

Session/lobby API surface (each guarded by `if not GamePlay.online: return`): `send_player_name`, `create_lobby`, `join_lobby`, `update_game_lobby`, `ask_for_active_lobbies`, `leave_lobby`, `kick_player_from_lobby`, `send_message`, `start_game`, plus the generic replication pair `send_node_func_call` / `get_node_method_call`.

## Permissions & validation

- **Checks present:** every public method gates on `GamePlay.online` — a client-side mode check, not a security boundary.
- **Checks missing:** `get_node_method_call` (176–186) takes a server-supplied `node_path`, `method` name, and `parameter`, and executes them directly — `get_node(node_path).call(method, true)` / `.call_deferred(method, parameter, true)` — with **no allow-list of permitted methods, no check on what `node_path` resolves to, and no validation of `parameter`'s shape.** This is a generic "invoke a method by name with these args" RPC dispatcher; its safety depends entirely on the (out-of-scope, separate-repo) server only ever forwarding trusted, well-formed calls. If the companion server ever relays player-authored data into this path unchecked (e.g., a chat/relay bug, or a compromised/malicious peer whose messages the server passes through), a peer could cause another client to invoke a method on a node elsewhere in that client's local scene tree — not just the intended `Player`/`Country` mutators. This client repo has no defense of its own against that scenario; it fully trusts whatever arrives labeled as a node/method/parameter tuple. `get_node_method_call` (176–186). *Severity guess:* critical if the server-side trust boundary is ever weaker than "only the authoritative server itself originates these calls" (unverified — the companion server lives in a separate repo, out of this audit's scope, but this is exactly the shape of vulnerability a security review of the full stack must check first).

**Phase 6 deep-dive refinement (2026-07-18):** two bounding factors narrow (but don't eliminate) the practical exploit surface. First, `node_path` is resolved via `get_node(node_path)`/`has_node(node_path)` called on the `Server` autoload — `Player.get_path()`/`Country.get_path()` (the only producers of legitimate `node_path` values in this codebase) return *absolute* paths from the scene root, and Godot resolves absolute `NodePath`s the same way regardless of which node `get_node()` is called on, so a malicious path isn't confined to `Server`'s own children — it can address any node reachable from the tree root, e.g. any live `Player` or `Country` instance. Second, `.call(method, true)` / `.call_deferred(method, parameter, true)` pass a fixed number of arguments, so only methods whose arity matches (one trailing bool, or one value + one trailing bool) are callable this way without Godot raising an argument-count error — in practice this still covers the large majority of this codebase's `net_call`-convention mutators (troop counts, occupier, elimination, turn/state transitions — dozens of methods across [Player.md](../gameplay/Player.md), [Country.md](../gameplay/Country.md), [Game.md](../gameplay/Game.md), [PlayersQueue.md](../gameplay/PlayersQueue.md)), so "arbitrary code execution" is better scoped as "arbitrary invocation of this game's own state-mutating methods, on any node, with attacker-influenced arguments" — still capable of corrupting a victim's local game state (eliminating them, zeroing their troops, forcing a state change) if the trust boundary is ever crossed, just not an unbounded RCE primitive.

## Data touches

No local persistence — `my_lobby`, `active_lobbies`, `player_id`, etc. all live in memory for the process lifetime, sourced entirely from server responses.

## Shared state

Writes `GamePlay.players_data` (twice — see Findings). Read by nearly every HUD file ([Lobby.md](../ui/Lobby.md), [JoinGameMenu.md](../ui/JoinGameMenu.md), etc.) and by [Player.md](../gameplay/Player.md)/[Country.md](../gameplay/Country.md) for turn-ownership checks.

## Findings

- **[Bug] — `game_lobby_created` emits the wrong variable: a stale/likely-null class field instead of the just-received lobby data.** Lines 88–92:
  ```gdscript
  func game_lobby_created(data):
  	if not GamePlay.online: return
  	my_lobby = data["lobby_data"]
  	player_number = data["player_number"]
  	emit_signal("lobby_created_signal", lobby_data)
  ```
  The freshly-arrived lobby payload is assigned to `my_lobby` (90), but the signal on line 92 emits `lobby_data` — the *class-level* field declared at line 15 (`var lobby_data = null`), which is unrelated: it's used elsewhere ([Lobby.gd](../ui/Lobby.md) `check_for_previous_messages`) to carry a *different* kind of state (a pending lobby-update to replay after a kick/rejoin) and is `null` at this point in the normal host-a-new-lobby flow. The correct value to emit is almost certainly `my_lobby` (or `data["lobby_data"]` directly). This currently has **no observable effect** because the only listener, [HostGameMenu.gd](../ui/HostGameMenu.md)'s `lobby_created(lobby_data)`, ignores its parameter entirely and just changes scene — but any future handler that reads the emitted value would silently receive `null` instead of the new lobby's data. `game_lobby_created` (88–92). *Severity guess:* medium (latent — currently masked by the one consumer not using the payload).
- **[Bug] — the default networking backend is selected by an exported boolean that defaults to WebSockets, making the ENet-based `HighLevelServer` backend effectively dead code in the shipped project, while itself resolving the recon-stage "which backend is live" question.** `connect_to_server` (44–52): `if is_running_on_the_web() or should_use_web_sockets_server: server = web_sockets_server.instance() else: server = high_level_server.instance()`, and `should_use_web_sockets_server` (line 32) defaults to `true`. Since nothing in this repo ever sets it to `false`, [HighLevelServer.md](./HighLevelServer.md) (the `NetworkedMultiplayerENet`-based path, and the one whose default port `1909` matches `SERVER_PORT`) is only reachable by a developer manually flipping this exported checkbox in the Godot editor and re-exporting — it ships unused. Confirms and resolves RECON.md free finding #2. *Severity guess:* low as a defect (nothing is broken), but noted because it means half of the networking layer (`HighLevelServer.gd`, 61 lines) is maintenance burden with zero current usage, and because it will be the wrong reference implementation to copy from if this project is ever ported past Godot 3 (`NetworkedMultiplayerENet` doesn't exist in Godot 4 — see RECON.md Dependencies — whereas the live WebSocket path has its own, separate porting need).
- **[Smell] — `local_ip`'s trailing comment is stale relative to how the local/production switch actually works now.** Line 4: `var local_ip = "127.0.0.1" #"conquestgame.online"`. Reading this line alone suggests toggling between local and production requires commenting/uncommenting the string literal — but that's not how it works: `SERVER_IP` (line 6) already defaults to the production address (`conquest_official_ws_address`, line 5) unconditionally, and only `_ready()`'s `if is_local: SERVER_IP = local_ip` (line 40) switches it to local — where `is_local` (line 34) is itself a hardcoded `false` with no exposed toggle (not `export var`, unlike `should_use_web_sockets_server` just above it). So switching to local dev mode today requires editing *and rebuilding* source in two ways depending on which line a developer notices first — the stale comment on line 4 documents a mechanism (comment-swapping a string) that isn't the one actually in effect (the `is_local` boolean). *Severity guess:* low (developer-experience confusion, not a runtime defect) — supersedes and corrects RECON.md free finding #1's characterization (the shipped default is production, not localhost; the friction is in *reaching* local mode, not in accidentally shipping local mode).

## Cross-references

Selects between [HighLevelServer.md](./HighLevelServer.md) and [WebSocketsServer.md](./WebSocketsServer.md) via duck-typing (no shared interface/base class — see [WebSocketsServer.md](./WebSocketsServer.md) for the risk this creates). Feeds the `players_data` aliasing risk documented in [game_play.md](../gameplay/game_play.md). The `get_node_method_call` trust boundary is the single most important item to hand to a security review of the full client+server stack.
