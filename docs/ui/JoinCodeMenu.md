# JoinCodeMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/JoinCodeMenu.gd` · 13 lines · Layer: UI · Audited: 2026-07-18

## Purpose

A small overlay (child of `JoinGameMenu`) letting a player join a lobby by typing its numeric code and password directly, as an alternative to browsing the active-lobbies list.

## Surface

- `_on_Cancel_pressed()` — hides self.
- `_on_Join_pressed()` (11–13) — parses the code field as an int, calls `Server.join_lobby(code, pass)`, emits `joining_lobby`.

## Permissions & validation

- **Checks missing:** `int(code_edit.text)` (line 12) on a non-numeric or empty string silently yields `0` in GDScript rather than raising — there is no check that the user actually typed a valid-looking code before submitting. A blank field submits a join request for lobby `0` instead of being rejected client-side with a message like "enter a code."

## Data touches

`Server.join_lobby(code, pass)` — network call (out of this file's scope).

## Shared state

None beyond the call above.

## Findings

- **[Smell] — no client-side validation before parsing user input as an integer; malformed input silently becomes `0`.** `_on_Join_pressed` (11–13). Same root pattern recurs in [LobbySearchInstance.md](./LobbySearchInstance.md) and (for a different field) in [Lobby.md](./Lobby.md)'s `_on_Send_pressed`/`_on_StartGame_pressed`. *Severity guess:* low (UX papercut — a bad request just fails server-side instead of being caught earlier — assuming the server itself validates, unverified in this client-only audit).

## Cross-references

Same `int(text)`-without-validation pattern as [LobbySearchInstance.md](./LobbySearchInstance.md).
