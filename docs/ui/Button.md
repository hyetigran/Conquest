# Button.gd — Analysis

> Source: `Source/Button/Button.gd` · 14 lines · Layer: UI · Audited: 2026-07-18

## Purpose

`SmartButton` (registered globally in `project.godot`'s `_global_script_classes`) is a thin `Button` subclass that adds sound feedback. It's the base button type used throughout every menu (`HMenu`/`VMenu` explicitly type-check for it alongside vanilla `Button`/`TextureButton`), so its behavior — or lack thereof — is shared by every clickable control in the game.

## Lifecycle

No `_ready()`. Two `onready` audio player references are grabbed from child nodes (`Pressed`, `Focused`) at scene instantiation. `button_pressed()` and `focus_entered()` are invoked by the engine on the corresponding built-in `Button` signals/overrides.

## Surface

- `button_pressed()` (lines 8–10) — plays `pressed_audio` if `GamePlay.interface_sound` is true.
- `focus_entered()` (lines 12–14) — no-op (`pass`); the actual sound-playing line is commented out.

## Permissions & validation

N/A — pure UI widget, no data access.

## Data touches

None.

## Shared state

Reads `GamePlay.interface_sound` (autoload singleton, `Source/Gameplay/game_play.gd`) — the only external coupling.

## Findings

- **[Dead code] — `focused_audio` is wired up but never plays.** `onready var focused_audio = $Focused` (line 6) loads a child node solely for `focus_entered()` (lines 12–14) to *not* use it: the call is commented out and replaced with `pass`. Every `SmartButton` instance pays the cost of resolving a `$Focused` child node reference for a feature that's effectively disabled. Either the sound was intentionally cut (in which case the node lookup and commented line should be deleted) or a focus-sound feature was half-implemented and forgotten. *Severity guess:* low.
- **[Smell] — no check that `pressed_audio`/`focused_audio` child nodes actually exist.** If a `SmartButton`-derived scene omits the `Pressed` or `Focused` child (easy to do when copy-pasting scenes), `onready var pressed_audio = $Focused` fails at scene load with a null/error, since Godot 3's `$Node` shorthand raises on a missing path. No guard exists. *Severity guess:* low (not observed to occur in the 40+ scenes checked, but nothing prevents a future one from doing so).

## Cross-references

Used as a base class check inside [HMenu.md](./HMenu.md) and [VMenu.md](./VMenu.md) (`is_a_button` checks for `child is SmartButton`).
