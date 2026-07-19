# OptionsMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/OptionsMenu.gd` · 78 lines · Layer: UI · Audited: 2026-07-18

## Purpose

The settings overlay, reachable from both the main menu and in-game: volume sliders, interface/country sound toggles, and the player's display name (editable only from the main menu, not mid-game).

## Lifecycle

`_ready()` → `setup()` (18–27): pulls current values from `GamePlay`/`Server` singletons into local fields, pushes them into the UI controls, and conditionally locks the name field.

## Surface

- `set_name_edit()` (29–31) — disables name editing if this instance's owner scene is named `"Game"` (mid-match), i.e., name changes are only allowed from the main menu.
- `cancel()` / `save()` (52–66) — `save()` commits local fields back into `GamePlay`/`Server` and, if the name changed, tells the server (`Server.send_player_name()`).
- Slider/checkbox change handlers (68–79) — update local fields only; nothing is persisted until `save()`.

## Permissions & validation

- **Checks present:** `set_name_edit` (29–31) blocks name edits mid-game by checking `get_owner().name == "Game"`.
- **Checks missing:** `save()` (63–65) sends the new name to the server if it differs from `Server.player_name`, but never validates the name client-side (length, emptiness, disallowed characters) before sending — validation, if any, is entirely the server's problem. No check on `cancel()`/`save()` that `get_parent()` is actually the expected `ColorRect` overlay wrapper vs. this being a structural assumption that silently breaks the buttons if the scene hierarchy changes.

## Data touches

None directly (delegates persistence to the `GamePlay`/`Server` singletons — this file has no save-to-disk logic itself; whether *those* singletons persist to disk is a Phase 3 question).

## Shared state

Reads/writes `GamePlay.main_menu_volume`, `GamePlay.in_game_volume`, `GamePlay.interface_sound`, `GamePlay.country_sound`; reads/writes `Server.player_name`; calls `Server.send_player_name()`; reads `Server.connected`.

## Findings

- **[Smell] — fragile type-based coupling to identify context instead of an explicit flag.** `set_name_edit()` (29–31): `if get_owner().name == "Game"` infers "we're in a live match" from the *node name* of whatever scene owns this control. Node names are easy to change accidentally in the editor (a rename doesn't trigger any compiler error) and this check would then silently stop firing — mid-game players would regain the ability to edit their name with no error anywhere. An explicit boolean passed in (or read from `GamePlay`) would make this robust to renames. `set_name_edit` (29–31). *Severity guess:* medium.
- **[Smell] — same fragile-parent-type pattern in `cancel()`/`save()`.** (52–58) `if get_parent() is ColorRect:` is used as a proxy for "am I inside the expected overlay wrapper." If the options menu is ever reparented under a different container type (also a `ColorRect`-derived or different overlay class), the hide-on-cancel/save behavior silently stops working — the settings would appear to save (values do get written to `GamePlay`/`Server`) but the overlay would stay open with no explanation. *Severity guess:* medium.
- **[Smell] — volume offset math (`50 + value` / `value - 50`) is unexplained and unbounded.** `setup_volume()` (33–35) and `save()` (59–60): volumes are stored in `GamePlay` as a signed value centered on 0 and displayed as `50 + value`, with no clamping in either direction. If a slider's min/max in the `.tscn` isn't exactly 0–100 (not verified in this pass), the stored `GamePlay` value could exceed the expected ±50 range without any code here catching it. *Severity guess:* low, pending the data-layer check of the slider's configured range.

## Cross-references

Depends on [game_play.md](../gameplay/game_play.md) and [Server.md](../server/Server.md) for the fields it reads/writes.
