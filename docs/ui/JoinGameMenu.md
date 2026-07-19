# JoinGameMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/JoinGameMenu.gd` · 79 lines · Layer: UI · Audited: 2026-07-18

## Purpose

The lobby-browser screen: lists active lobbies (via `LobbySearchInstance` rows), lets the player refresh the list, join by code, or click a row to join directly.

## Lifecycle

`_ready()` (12–20) hides the error label and join-code sub-menu, wires four `Server` signals, and immediately triggers a refresh (`_on_Refresh_pressed()`).

## Surface

- `_on_Refresh_pressed()` → `Server.ask_for_active_lobbies()`.
- `got_active_lobbies(lobbies)` → `instance_lobby_search_scenes(lobbies)` (34–49) — rebuilds the list of `LobbySearchInstance` rows from scratch each refresh.
- `joining_lobby()` / `disable_buttons()` / `enable_buttons()` (50–67) — disables all join affordances while a join request is in flight; re-enabled only on failure (`failed_to_join_lobby`), not explicitly on success (success navigates away via `joined_lobby`, so re-enabling would be moot — consistent).
- `failed_to_join_lobby(reason)` (69–72) — shows the server-supplied error text verbatim.

## Permissions & validation

- **Checks missing:** `failed_to_join_lobby` (69–72) displays `reason` directly as label text with no sanitization — if the server ever returns attacker-controlled or unexpectedly formatted text (e.g. from a lobby name reflected back in an error), it's rendered as-is. In Godot 3 `Label.text` isn't HTML/BBCode by default, so this isn't an XSS-style vector, but it is unvalidated server input rendered without any length/content check — a very long or control-character-laden string could visually break the label.

## Data touches

Rebuilds `lobbies_list`'s children from the `lobbies: Dictionary` payload delivered via the `got_active_lobbies_signal`.

## Shared state

Connects to and reacts to `Server`'s signals: `got_active_lobbies_signal`, `failed_to_join_lobby_signal`, `lobby_updated_signal`.

## Findings

- **[Smell] — password field visibility is inferred from truthiness, conflating "no password" with "falsy password value."** `instance_lobby_search_scenes` (46–48): `if not lobbies[lobby_code].pass:` — if a lobby's password were ever the empty string vs. `null` vs. the literal string `"0"`, GDScript truthiness treats empty string and `null` as falsy but a non-empty string like `"0"` as truthy, so this works correctly for realistic password values; flagged only because it relies on GDScript's dynamic truthiness rather than an explicit `has_password` boolean field, making the contract implicit. *Severity guess:* low.
- **[Smell] — full rebuild-from-scratch on every refresh.** `instance_lobby_search_scenes` (34–49) frees every existing `LobbySearchInstance` and re-instances all of them on every refresh click, rather than diffing. Not a bug, but on a lobby list with many entries this creates avoidable churn (and briefly empties the list, which could look like a flicker) each time. *Severity guess:* low (performance/UX polish, not correctness).

## Cross-references

Instances [LobbySearchInstance.md](./LobbySearchInstance.md) rows and embeds [JoinCodeMenu.md](./JoinCodeMenu.md).
