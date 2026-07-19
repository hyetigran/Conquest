# LobbySearchInstance.gd — Analysis

> Source: `Source/Gameplay/HUD/LobbySearchInstance.gd` · 21 lines · Layer: UI · Audited: 2026-07-18

## Purpose

A single row in the lobby-browser list (`JoinGameMenu`) — shows a lobby's code/name/player-count and a password field, with a Join button.

## Surface

- `_on_Join_pressed()` (13–15) — parses `code_label.text` as int, calls `Server.join_lobby(code, pass)`, emits `joining`.
- `disable_join_button()` / `enable_join_button()` — toggled by the parent `JoinGameMenu` while a join is in flight.

## Findings

- **[Smell] — join code is parsed from the *displayed label text*, not from the underlying lobby-data model.** `_on_Join_pressed` (14): `int(code_label.text)`. The label's text is set by the parent (`JoinGameMenu.instance_lobby_search_scenes`, line 43: `lobby_instance.code_label.text = str(lobbies[lobby_code].code)`) purely for display — deriving the join request from that same string round-trips through `str()`/`int()` instead of keeping the original `int` code value on the instance (e.g. as a `var code: int`). If the label's format is ever changed for display purposes (padding, a "#" prefix, localization), this silently breaks the join action along with it, since display and data are the same field. Same root issue recurs in [Lobby.md](./Lobby.md) (`_on_Send_pressed`, `_on_StartGame_pressed`, which parse `code_label.text` for the *current* lobby too). *Severity guess:* medium (a plausible, easy-to-introduce future regression: any change purely intended as cosmetic (e.g. "Lobby #1234") breaks joining/sending/starting).

## Cross-references

Same code-from-label-text pattern as [Lobby.md](./Lobby.md) and [JoinCodeMenu.md](./JoinCodeMenu.md) (which at least parses a dedicated input field, not a display label — lower risk).
