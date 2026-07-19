# GameOverMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/GameOverMenu.gd` · 37 lines · Layer: UI · Audited: 2026-07-18

## Purpose

`GameoverMenu` — shown when a match ends; displays the winner's name and auto-returns to the main menu (offline) or lobby (online) after a 5-second countdown, or immediately via manual buttons.

## Lifecycle

`_ready()` (10–13) sets the initial countdown text. `_on_GameoverMenu_visibility_changed()` (35–37) starts the countdown `timer` only when the node becomes visible — the actual trigger for the whole countdown flow lives in the `.tscn`'s signal wiring, not in `_ready()`.

## Surface

- `set_player_name(player_name)` (15–16) — sets the winner display.
- `play_again()` (18–19) / `main_menu()` (21–22) — manual navigation, bypassing the timer.
- `_on_Timer_timeout()` (24–33) — decrements `time`, updates the label text, and navigates away at `time == 0`.

## Permissions & validation

N/A.

## Data touches

None.

## Shared state

Reads `GamePlay.online`.

## Findings

- **[Smell] — countdown starting value is duplicated as a magic number in two places that can silently drift.** `_ready()` (11, 13) hardcodes the string `"Back to menu in 5(s)"` / `"...lobby in 5(s)"`, while the actual countdown state lives in `var time = 5` (line 8). If someone changes the countdown duration by editing `time`'s initial value (an obvious, isolated-looking edit), the `_ready()` strings still say "5" until the first `_on_Timer_timeout()` tick corrects it a second later — a cosmetic but real display bug for one tick. `_ready()` (10–13) vs `time` (line 8). *Severity guess:* low.
- **[Smell] — inconsistent post-game destination logic between the timeout path and the manual buttons.** `_on_Timer_timeout()` (29–33) sends online players to `Lobby.tscn` and offline players to `Main.tscn`, but the manual `play_again()` (18–19) always goes to `Game.tscn` regardless of online/offline, and `main_menu()` (21–22) always goes to `Main.tscn` regardless of online/offline — so an online player who manually clicks "Main Menu" lands on the title screen (bypassing the lobby they were just in) while the same online player who waits out the timer lands back in the lobby. Whether this divergence is intentional (manual = leave the whole session vs timeout = stay in matchmaking) isn't stated anywhere; worth confirming against expected product behavior. *Severity guess:* medium (a real behavioral inconsistency, not just cosmetic).

## Cross-references

None outside `GamePlay.online`.
