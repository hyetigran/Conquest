# SameDeviceMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/SameDeviceMenu.gd` · 2 lines · Layer: UI · Audited: 2026-07-18

## Purpose

Declared purpose (inferred from the scene, not the script): a "same device" hotseat/local-multiplayer game-setup screen — the `.tscn` lays out a "Game Setup" panel with a "Number of players?" `SpinBox` (min 2, max 6) and Cancel/Create buttons, visually parallel to `HostGameMenu`'s online equivalent.

## Lifecycle

None — the entire script body is `extends Control` with no other code.

## Surface

None. No methods exist.

## Findings

- **[Dead code / unfinished feature] — the scene's Cancel and Create buttons have no signal connections and no handlers exist to connect them to.** Confirmed by inspecting `SameDeviceMenu.tscn`: it contains a fully laid-out UI (label, `SpinBox` named `PlayersRange` with `min_value=2`, `max_value=6`, `value=2`, and `Cancel`/`Host` buttons inside an `HMenu` row) but **zero `[connection]` blocks** — nothing in the scene wires button presses to any method, and the attached script (`SameDeviceMenu.gd`) defines no methods at all for them to call even if they were wired. Additionally, **no other file in the project references `SameDeviceMenu.tscn` or `SameDeviceMenu.gd`** (confirmed via project-wide search) — this screen is not reachable from any menu, button, or scene transition anywhere in the codebase. This is a fully scaffolded, entirely disconnected, and entirely unreachable feature: local same-device multiplayer was planned (UI built, player-count range configured 2–6) and then abandoned before any wiring was added. *Severity guess:* low (dead/unreachable code — no runtime risk since it can't be entered — but represents real, uncompleted product scope that a rewrite team should either finish or explicitly drop rather than silently port).

## Cross-references

Structurally parallel to [HostGameMenu.md](./HostGameMenu.md) (same "Game Setup"-style panel, same `PlayersRange`-shaped control), which *is* fully wired — useful as a template if this feature is ever finished.
