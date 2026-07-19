# Main.gd — Analysis

> Source: `Source/Main/Main.gd` · 65 lines · Layer: UI · Audited: 2026-07-18

## Purpose

`Main` is the script on the app's entry-point scene (`run/main_scene` in `project.godot` → `Source/Main/Main.tscn`). It's the very first thing that runs: it kicks off background music, initiates the connection to the multiplayer server, and wires the IP-entry UI on the title screen (server address field, connect/reset buttons, connected/disconnected status labels).

## Lifecycle

`_ready()` (9–11) → `connect_signals()` then `setup()`. `setup()` (20–23) calls `setup_music()`, `setup_server()` (populates the IP field and reflects current connection state), and `setup_mode()` (forces `GamePlay.online = true` unconditionally on every boot).

## Surface

- `_on_Connect_pressed(ip)` (41–47) — disconnects any existing connection, updates `Server.SERVER_IP`, reconnects.
- `_on_ResetIP_pressed()` (62–64) — resets the IP field to `Server.default_ip`.
- `server_connected()` / `server_not_connected()` (49–59) — toggle UI state (labels, enable/disable "Play Online" and the name field) based on connection status.
- `options_saved()` (38–39) — re-applies music volume after the options menu is closed (connected via `MainMenu`'s `options_saved` signal, not shown in this file).

## Permissions & validation

- **Checks present:** `_on_Connect_pressed` (42–43) guards against an empty IP string.
- **Checks missing:** no validation that the entered IP/hostname is well-formed before handing it to `Server.SERVER_IP` / `Server.connect_to_server()` (line 46–47) — malformed input is only discovered downstream, if at all, inside the networking layer (see [Server.md](../server/Server.md)).

## Data touches

None (no DB/file I/O) — all state is in-memory singletons.

## Shared state

- Reads/writes `GamePlay.main_menu_volume`, `GamePlay.online` (autoload `game_play.gd`).
- Reads/writes `Server.SERVER_IP`, `Server.connected`, `Server.default_ip`, calls `Server.connect_to_server()` / `Server.disconnect_server()` (autoload `Server.gd`).

## Findings

- **[Dead code] — unreachable statements after an early `return`.** `connect_signals()` (13–18):
  ```
  func connect_signals():
  	Server.connect("server_connected", self, "server_connected")
  	Server.connect("server_disconnected", self, "server_not_connected")
  	return
  	get_tree().connect("connected_to_server", self, "server_connected")
  	get_tree().connect("connection_failed", self, "server_not_connected")
  ```
  Lines 17–18 can never execute — the bare `return` on line 16 exits first. This looks like a deliberate but undocumented disabling of the built-in Godot `SceneTree` connection signals in favor of the custom `Server` autoload's signals, left in place as dead code instead of being deleted. A future maintainer skimming this file would reasonably believe both signal sources are wired up; only one is. `connect_signals` (13–18). *Severity guess:* low (dead code, but genuinely misleading to read).
- **[Smell] — `setup_mode()` unconditionally forces online mode on every app launch.** `setup_mode()` (35–36) sets `GamePlay.online = true` with no condition, every time `Main` loads — including, presumably, every time the player returns to the title screen after an offline game (`MainMenu.create_offline_game()` sets `GamePlay.online = false`, but re-entering `Main`'s scene resets it back to `true`). If `Main.tscn` can be re-entered mid-session this silently flips a global mode flag. Needs confirmation against `Game.gd`/scene-transition flow in Phase 3, cross-referenced with [Menu.md](./Menu.md)'s `create_offline_game`. *Severity guess:* low–medium pending Phase 3 confirmation.
- **[Smell] — no input sanitization on the server address field**, discussed above under Permissions & validation. *Severity guess:* low (single-player-adjacent risk; worst case is a failed connection, not observed to reach an injection-capable sink).

## Cross-references

Depends on [Server.md](../server/Server.md) (`connect_to_server`, `SERVER_IP`, `default_ip`) and [game_play.md](../gameplay/game_play.md) (`online`, `main_menu_volume`). Related to [Menu.md](./Menu.md) (`MainMenu.create_offline_game` also touches `GamePlay.online`).
