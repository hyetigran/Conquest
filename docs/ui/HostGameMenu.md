# HostGameMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/HostGameMenu.gd` · 45 lines · Layer: UI · Audited: 2026-07-18

## Purpose

The "create a lobby" screen — lets the host set a lobby name, max player count, and optional password, then asks the `Server` singleton to create it.

## Lifecycle

`_ready()` (10–11) wires `Server`'s `lobby_created_signal` to a local handler. No `setup()`/default-population step — fields start with whatever the `.tscn` has as defaults.

## Surface

- `_on_Host_pressed()` (19–44) — builds a `lobby_data` dictionary and calls `Server.create_lobby(lobby_data)`.
- `lobby_created(lobby_data)` (13–14) — on success, transitions to `Lobby.tscn`.
- `_on_Cancel_pressed()` (16–17) — back to the main menu.

## Permissions & validation

- **Checks missing:** no validation of `lobby_name.text` (empty name allowed), no validation that `lobby_players.value` is within a sane range (e.g. ≥2) before sending to the server — same missing-bounds-check pattern as `Menu.gd`'s `create_offline_game`. Password field (`lobby_pass`) has no length/character restriction client-side.

## Data touches

| Operation | Target | Where | R/W |
|---|---|---|---|
| Build lobby request | `Server.create_lobby(lobby_data)` (network call, out of this file's scope) | `_on_Host_pressed` (44) | Write |

## Shared state

Calls `Server.create_lobby()`; reads `Server.player_id`.

## Findings

- **[Bug] — the pre-populated player slots loop always writes to the same dictionary key, so `players_list` ends up with exactly one entry regardless of `max_players`.** Lines 32–33:
  ```gdscript
  for i in range(lobby_players.value):
      players_list[Server.player_id] = player_dictionary
  ```
  The loop variable `i` is never used as (or to derive) the dictionary key — every iteration overwrites `players_list[Server.player_id]`. If the intent was to reserve `lobby_players.value` player slots up front (a common lobby-system pattern: pre-size the roster, fill slots as players join), this code doesn't do that: after the loop, `players_list` contains a single key (`Server.player_id`) no matter whether `lobby_players.value` is 2 or 6. Whether this is masked by server-side logic (i.e., the server ignores the client-supplied `players` map and builds its own) needs confirmation — but as written, the *lobby_data* dictionary sent to `Server.create_lobby()` (line 44) does not reflect the requested player count. `_on_Host_pressed` (32–33). *Severity guess:* high (core lobby-creation data is wrong at the one place it's constructed), pending server-side confirmation of blast radius.
- **[Smell] — `player_dictionary` is a single `Dictionary` literal reused by reference, not copied, across (intended) iterations.** Lines 25–30 declare `player_dictionary` once, outside the loop; GDScript `Dictionary` is a reference type, so even if the key bug above were fixed (e.g. `players_list[i] = player_dictionary`), every "slot" in `players_list` would alias the *same* underlying dictionary object — mutating one player's entry later (setting `id`/`name`/`color` on join) would mutate every slot simultaneously. A correct fix needs `player_dictionary.duplicate()` per slot, not just a different key. Lines 25–33. *Severity guess:* high (latent — only manifests once the key bug above is fixed and multiple slots are actually populated, but it's the kind of bug that reappears immediately after a naive fix).

## Cross-references

Needs confirmation against the server's lobby-creation handling (out of this client repo's scope per `Source/Server/` being a client-side façade only — see [Server.md](../server/Server.md)) to determine whether the malformed `players_list` payload is actually consumed or ignored server-side.
