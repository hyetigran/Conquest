# PlayerListInstance.gd — Analysis

> Source: `Source/Gameplay/HUD/PlayerListInstance.gd` · 10 lines · Layer: UI · Audited: 2026-07-18

## Purpose

A single row in the `Lobby` roster list — player color swatch, name, and a host-only Kick button.

## Surface

- `_on_Kick_pressed()` (9–10) — `Server.kick_player_from_lobby(Server.my_lobby.code, int(name))`.

## Findings

- **[Bug/Smell] — player identity for the Kick action is recovered by parsing the Godot scene-tree `Node.name` property, which the engine silently mutates to enforce sibling-name uniqueness.** `_on_Kick_pressed` (10): `int(name)` reads this node's own built-in `.name`, which [Lobby.md](./Lobby.md) sets via `player_instance.set_name(str(Server.my_lobby.players[i].id))` (`Lobby.gd:54`). Godot automatically appends a disambiguating suffix (e.g. renaming a second sibling node to `"1234 2"`) whenever `set_name()` is given a value that collides with an existing sibling — a built-in engine safety feature that this code relies on *not* triggering. If two players' `id` values were ever equal, or a duplicate roster rebuild race left an old row not yet freed when a new one with the same name is added (`instance_player_list()` frees old rows and adds new ones without necessarily waiting a frame — not independently confirmed to be safe), the second node's name would be silently mangled, and `int(name)` here would parse garbage or throw, sending a wrong/invalid id to `kick_player_from_lobby`. Using the Node's own identity field to carry application data (rather than a dedicated `var player_id: int` on the instance, set alongside `name_label.text` in `Lobby.gd`) is the root cause — it works only as long as nothing else about node-naming ever collides. `_on_Kick_pressed` (10); root cause in [Lobby.md](./Lobby.md) `instance_player_list` (54). *Severity guess:* medium (real correctness risk if ids ever collide or during rebuild races, low observed likelihood today).

## Cross-references

Populated by [Lobby.md](./Lobby.md)'s `instance_player_list`.
