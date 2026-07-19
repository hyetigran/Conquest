# CountryState.gd — Analysis

> Source: `Source/Gameplay/StateMachine/CountryStates/CountryState.gd` · 89 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

Base class for the three concrete country states ([ActiveState.md](./ActiveState.md), [InActiveState.md](./InActiveState.md), [SelectedState.md](./SelectedState.md)). Owns the shared visual logic — country sprite/border coloring based on occupier, hover, selection, and active/inactive dimming — plus a `country_states` lookup table used by every subclass to instantiate sibling states.

## Surface

- `set_country_color(country)` (44–51) / `set_border_color(country)` (53–73) — the shared rendering logic every subclass calls (via `.set_country_color(country)` GDScript "super call" syntax).
- `dim_border_color` / `dim_country_color` (75–83) — apply each state's `hover_multiplier`/`color_multiplier` to the sprite/border tint.
- `country_states` (12–16) — preloaded script references to the three concrete states, `.new()`'d by subclasses to produce transition targets.

## Findings

- **[Smell] — two independently-maintained sources of truth for a player's color, kept in sync only by matching values, not by shared reference.** `set_country_color` (44–51): online path reads `Server.my_lobby.players[...]["color"]`; offline path reads `GamePlay.colors[str(int(country.occupier.name) + 1)]` — a *different* dictionary than the `GamePlay.players_data[...].color` lookup used everywhere else offline ([ActivePlayerHUD.md](../ui/ActivePlayerHUD.md), [AttackingMenu.md](../ui/AttackingMenu.md)). `GamePlay.colors` (keyed `"1"`–`"6"`) and `GamePlay.players_data_template` (keyed `"0"`–`"5"`, offset by one) currently happen to assign the *same* Color values in the *same* order, so the `+1` index conversion here produces a result that matches `players_data`'s color for the same player today — but only by construction. There is no runtime path today that customizes a player's color independently of these two hardcoded tables (confirmed via project-wide search — no writes to `players_data[...].color` exist), so this hasn't yet produced an observable mismatch, but the two tables could trivially drift (e.g., a future "pick your color" feature that only updates `players_data`) and this file would keep painting countries from the stale `GamePlay.colors` table instead. `set_country_color` (44–51). *Severity guess:* medium (latent — a real visual-consistency bug waiting for a currently-nonexistent feature to trigger it).

## Cross-references

The color-lookup duplication is the same *class* of two-sources-of-truth issue as [game_play.md](./game_play.md)'s duplicated adjacency dictionaries. Subclassed by [ActiveState.md](./ActiveState.md), [InActiveState.md](./InActiveState.md), [SelectedState.md](./SelectedState.md).
