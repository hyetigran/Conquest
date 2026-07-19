# VMenu.gd — Analysis

> Source: `Source/Menu/VMenu.gd` · 62 lines · Layer: UI · Audited: 2026-07-18

## Purpose

`VMenu` (extends `VBoxContainer`) is the vertical counterpart to `HMenu` — a keyboard/gamepad-navigable column of buttons. `MainMenu` (`Source/Main/Menu.gd`) extends it directly, making it the base of the game's title screen; it's also used standalone in at least one other scene (2 direct `.tscn` instances found, plus the `MainMenu` subclass).

## Lifecycle

Identical to `HMenu`: `_ready()` → `setup()` resets `index`, connects child focus signals, grabs initial focus.

## Surface

Line-for-line identical surface to `HMenu.gd`: `setup()`, `connect_child_signals()`, `move_index_on_focused_child()`, `grab_focus_on_index_child()`, `next()`, `previous()`, `_unhandled_input()`.

## Permissions & validation

N/A.

## Data touches

None.

## Shared state

None (local `index`).

## Findings

- **[Bug] — same unbounded-recursion risk as `HMenu.gd`.** `next()`/`previous()`/`grab_focus_on_index_child()` (35–55, 26–33) have no base case when a container has children but none are buttons — see [HMenu.md](./HMenu.md) for the full mechanism. Because `MainMenu` (the title screen) extends this class directly, a future edit to the main menu's overlay structure that leaves a focus-less `VMenu` reachable would crash the game on the very first screen. *Severity guess:* medium.
- **[Smell] — byte-for-byte duplicated with `HMenu.gd`.** Same finding as [HMenu.md](./HMenu.md): this is a copy-pasted implementation differing only in the declared base container type. *Severity guess:* medium.

## Cross-references

Duplicate of [HMenu.md](./HMenu.md). Subclassed by `Source/Main/Menu.gd` (`MainMenu`) — see [Main-Menu.md](./Main-Menu.md).
