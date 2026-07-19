# HMenu.gd — Analysis

> Source: `Source/Menu/HMenu.gd` · 62 lines · Layer: UI · Audited: 2026-07-18

## Purpose

`HMenu` (extends `HBoxContainer`) is a keyboard/gamepad-navigable horizontal row of buttons — the horizontal counterpart to `VMenu`. Used across most HUD menus (`StartGameMenu`, `AttackingMenu`, `MoveMenu`, `LobbySearchInstance`, `HostGameMenu`, `JoinGameMenu`, `DeployMenu`, `QuitGameMenu`, `GameOverMenu`, `Lobby`, `OptionsMenu`, `SameDeviceMenu`, `JoinCodeMenu`, and its own `HMenu.tscn` — confirmed via `.tscn` search, not dead code). It gives menus arrow-key navigation without relying on Godot's built-in focus-neighbor system.

## Lifecycle

`_ready()` → `setup()`: resets `index` to 0, wires every focusable child's `focus_entered` signal back to `move_index_on_focused_child` (so mouse/tab focus keeps `index` in sync), then grabs focus on the child at `index`.

## Surface

- `setup()` (9–13) — (re-)initializes the menu; can be called again after children are added/removed dynamically.
- `connect_child_signals()` (15–21) — connects `focus_entered` on every `Button`/`TextureButton`/`SmartButton` child.
- `move_index_on_focused_child(new_index)` (23–24) — signal handler, tracks external focus changes.
- `grab_focus_on_index_child()` (26–33) — focuses the child at `index`, or skips forward via `next()` if that child isn't focusable.
- `next()` / `previous()` (35–55) — arrow-key navigation, wrapping at the ends.
- `_unhandled_input(event)` (57–61) — routes the `next`/`previous` input actions (mapped to arrow keys in `project.godot`) to the methods above.

## Permissions & validation

N/A (UI navigation widget).

## Data touches

None.

## Shared state

None — purely local `index` state per instance.

## Findings

- **[Bug] — unbounded recursion / stack overflow if a menu has children but none are focusable buttons.** `next()` (35–44), `previous()` (46–55), and `grab_focus_on_index_child()` (26–33) form a mutual-recursion loop with no base case for "searched every child, found no button." If `get_child_count() > 0` but no child satisfies `is_a_button` (e.g. a menu row that's all `Label`/`Control` spacers, or every button is temporarily removed/hidden in a way that changes `get_children()`), pressing next/previous — or even initial `_ready()` → `grab_focus_on_index_child()` — recurses through every child, wraps around, and recurses again forever, since `index` cycles through the same non-button children indefinitely. This crashes the running game (GDScript stack overflow) rather than degrading gracefully. Not observed to trigger today (every current `HMenu`/`VMenu` instance seems to contain at least one button), but there's no structural guard against a future scene doing so. `function`s: `next` (35–44), `previous` (46–55), `grab_focus_on_index_child` (26–33). *Severity guess:* medium (latent — requires a specific scene composition to trigger, but the failure mode is a hard crash).
- **[Smell] — byte-for-byte duplicated with `VMenu.gd`.** Every line in this file (barring the base class `extends HBoxContainer` vs `extends VBoxContainer`) is identical to [VMenu.md](./VMenu.md). This is copy-paste: any future bug fix (e.g. the recursion issue above) has to be applied twice and will drift if someone forgets. A shared base class (or a Godot 4 port) should factor this into one `Menu` base extending `Container`. *Severity guess:* medium (maintainability).

## Cross-references

Shares 100% of its logic with [VMenu.md](./VMenu.md) — see that file for the identical implementation. Depends on [Button.md](./Button.md) for the `SmartButton` type check.
