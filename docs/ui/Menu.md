# Menu.gd — Analysis

> Source: `Source/Main/Menu.gd` · 57 lines · Layer: UI · Audited: 2026-07-18

## Purpose

`MainMenu` (extends `VMenu`, see [VMenu.md](./VMenu.md)) is the script behind the title screen's main button column: Play Online, Play Offline, Options, Quit, plus the offline-game-setup and quit-confirmation overlays.

## Lifecycle

`_ready()` (14–17) hides the three overlays (quit-confirm, start-game, options) so they don't briefly flash visible on scene load.

## Surface

- `play()` (23–26) — no-ops if `Server.connected` is false; otherwise shows the start-game overlay. Silent failure: no error/feedback is shown to the user if they click Play while disconnected.
- `options()` (28–29) — shows the options overlay.
- `quit()` / `quit_confirm()` / `quit_cancel()` (31–42) — quit confirmation flow; `quit()` disables unhandled input on `self` while the confirm dialog is up (line 34) so arrow keys don't leak through to the menu behind it.
- `_on_OptionsMenu_options_saved()` (44–45) — re-emits `options_saved` upward (to [Main.md](./Main.md)).
- `play_offline()` / `create_offline_game()` / `cancel_offline_game()` (47–57) — offline-game setup: sets `GamePlay.online = false`, sets `GamePlay.number_of_players` from a UI range control, and transitions the whole scene tree to `Game.tscn`.

## Permissions & validation

- **Checks present:** `play()` (24–25) checks connection state before allowing online play.
- **Checks missing:** `play()` gives no user-visible feedback on the disconnected-click no-op (just silently does nothing — a UX dead end, not a security gap). `create_offline_game()` (50–53) takes `players_range.value` at face value with no bounds check of its own; range enforcement is delegated entirely to whatever min/max is configured on the `PlayersRange` control in the `.tscn` (not verified in this pass — flagged for the data-layer pass).

## Data touches

None directly; triggers a full scene change (`get_tree().change_scene("res://Source/Gameplay/Game/Game.tscn")`, line 53).

## Shared state

Writes `GamePlay.online`, `GamePlay.number_of_players` (autoload `game_play.gd`). Reads `Server.connected` (autoload `Server.gd`).

## Findings

- **[Smell] — silent no-op on `play()` when disconnected.** A player clicking "Play Online" while the connection is down gets zero feedback (24–25) — no error label, no sound, nothing — the click simply does nothing. Combined with [Main.md](./Main.md)'s `server_not_connected()` disabling the button (`PlayOnline.disabled = true`), this path may be unreachable in practice (the button should already be disabled), which would make the guard in `play()` defensive dead code — but if the two states can ever desync (e.g. a race between the connection signal firing and the button's disabled flag updating), the user gets no explanation. *Severity guess:* low.
- **[Smell] — `create_offline_game()` trusts UI control value with no independent bounds check** (50–53). If `PlayersRange`'s min/max is ever misconfigured in the `.tscn` (e.g. allows 0 or 1 players), this code passes that straight into `GamePlay.number_of_players` and starts a game — no assertion that a game actually needs ≥2 players. *Severity guess:* low, pending confirmation of the range control's configured bounds and of what `Game.gd`/`PlayersQueue.gd` do with a degenerate player count.

## Cross-references

Base class [VMenu.md](./VMenu.md) (inherits the recursion-risk finding). Signals up to [Main.md](./Main.md). Sets state consumed by [game_play.md](../gameplay/game_play.md) and [Game.md](../gameplay/Game.md).
