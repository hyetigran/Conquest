# Lobby.gd — Analysis

> Source: `Source/Gameplay/HUD/Lobby.gd` · 118 lines · Layer: UI · Audited: 2026-07-18

## Purpose

The multiplayer waiting-room screen: shows lobby name/code/password, the current player roster (host controls, kick buttons), a chat box, and (host-only) the Start Game button. The most stateful/networked HUD file in the UI layer.

## Lifecycle

`_ready()` (19–23): checks for a "previous messages" carry-over state (e.g. arriving here immediately after a kick/update rather than a fresh join), connects signals, builds the initial roster UI, and records the chat scrollbar's starting `max_value` for the auto-scroll-to-bottom heuristic.

## Surface

- `setup_lobby_ui()` / `instance_player_list()` (41–68) — full roster rebuild: name/code/player-count labels, one `PlayerListInstance` per player, host-only controls (kick buttons, Start Game) shown/hidden per viewer.
- `kicked_from_lobby(reason)` (70–72) — bounced back to the main menu.
- `write_server_message` / `got_message` (74–86) — append chat rows (system vs. player-authored).
- `scroll_chat_box()` (88–91) — auto-scroll-to-bottom when new content grows the scrollable range.
- `lobby_updated(lobby_data, reason)` (93–98) — the umbrella handler for any roster change (join/leave/kick), re-renders the roster and posts a system chat line.
- `_on_Send_pressed()` / `_on_Message_text_entered()` (104–112) — chat send.
- `_on_StartGame_pressed()` / `start_game()` (114–118) — host-only match start.

## Permissions & validation

- **Checks present:** `instance_player_list()` (58–65) gates kick-button/start-button visibility on whether *this* client's player entry has `"host": true` — a UI-level permission check. Note this is UI-only: nothing in this file stops a modified/malicious client from calling `Server.start_game()` or a kick RPC directly if the server doesn't independently re-check host status server-side (out of scope for this client-only audit, but flagged as a question for the companion server repo).
- **Checks missing:** `_on_Send_pressed()` (104–108) sends chat messages with no length limit, profanity filter, or empty-message guard — an empty `message_edit.text` is sent as-is.

## Data touches

Purely reactive to `Server` signal payloads; no local persistence.

## Shared state

Connects to `Server`'s `lobby_updated_signal`, `kicked_from_lobby_signal`, `got_message`, `game_started_signal`. Reads/writes `Server.lobby_data`, `Server.reason`, `Server.my_lobby`, `Server.player_number`, `Server.player_id`.

## Findings

- **[Smell] — the lobby/message "code" used for sending chat and starting the game is parsed from a UI label's text, not the underlying model value.** `_on_Send_pressed` (105): `var code = int(code_label.text)`; `_on_StartGame_pressed` (115): `Server.start_game(int(code_label.text))`. Both re-derive the lobby code from `code_label.text`, which was itself set from `Server.my_lobby.code` purely for display (line 43). The live model value (`Server.my_lobby.code`) is already available and used directly elsewhere in this same file (line 43) — there's no reason to round-trip through the label. If the label's display format ever changes (e.g., "Code: 1234" instead of "1234"), both chat-sending and starting the game break simultaneously, silently (int() parse of non-numeric prefix truncates/fails). `_on_Send_pressed` (105), `_on_StartGame_pressed` (115). *Severity guess:* medium — a cosmetic-looking change to the label would break two unrelated networking actions.
- **[Smell] — no guard against sending an empty chat message.** `_on_Send_pressed` (104–109) — pressing Send (or hitting Enter) with an empty `message_edit.text` still calls `Server.send_message(code, "", sender)`. *Severity guess:* low.
- **[Smell] — host-permission UI gating is duplicated per-row inside a loop rather than computed once.** `instance_player_list()` (48–68): the "am I the host" check (`!Server.my_lobby.players[Server.player_id]["host"]`, line 62) doesn't depend on the loop variable `i` at all, yet it's re-evaluated on every iteration of the `for i in Server.my_lobby.players` loop — functionally harmless (idempotent), but it reads as if it *should* vary per-row, making the method harder to follow than a version that computed `var i_am_host = ...` once before the loop. *Severity guess:* low (readability only).

## Cross-references

Same code-from-label-text issue as [LobbySearchInstance.md](./LobbySearchInstance.md). Instances [PlayerListInstance.md](./PlayerListInstance.md) and [MessageInstance.md](./MessageInstance.md).
