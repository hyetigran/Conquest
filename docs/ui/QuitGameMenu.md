# QuitGameMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/QuitGameMenu.gd` · 12 lines · Layer: UI · Audited: 2026-07-18

## Purpose

The in-game "quit to main menu" confirmation overlay — leaves the online lobby (if applicable) and returns to the title screen.

## Surface

- `cancel()` (5–7) — hides self and the parent overlay.
- `quit_game()` (9–12) — if in a live online game, tells the server to leave the lobby; always transitions to `Main.tscn`.

## Findings

- **[Smell] — same fragile owner-name string check seen elsewhere.** `quit_game()` (10): `if get_owner().name == "Game" and GamePlay.online:` — third occurrence of the `get_owner().name == "Game"` pattern (see [OptionsMenu.md](./OptionsMenu.md) `set_name_edit`), each an independent, un-refactored copy relying on the scene node happening to be named exactly `"Game"`. A rename silently disables the "tell the server I'm leaving" call, leaving the player's session dangling server-side (the client navigates away regardless, per line 12, but the server never learns the player left) — a real correctness gap if it fires, not just a UI cosmetic issue like the other two occurrences. `quit_game` (10). *Severity guess:* medium.

## Cross-references

Recurrence of the pattern flagged in [OptionsMenu.md](./OptionsMenu.md) (`set_name_edit`) and (fragile-parent-type variant) [StartGameMenu.md](./StartGameMenu.md)/[OptionsMenu.md](./OptionsMenu.md) `cancel`/`save`.
