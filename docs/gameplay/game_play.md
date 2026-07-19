# game_play.gd — Analysis

> Source: `Source/Gameplay/game_play.gd` · 162 lines · Layer: business logic (autoload singleton `GamePlay`) · Audited: 2026-07-18

## Purpose

The global session-state singleton (`autoload GamePlay` in `project.godot`), alive for the entire app lifetime. Holds: the world-map adjacency graph (`bordering_countries`), per-continent country counts (for continent-bonus scoring), default player colors/names, user settings (volumes, sound toggles), the current game mode (`online`), player count, and a reference to the live `Game` instance once one exists.

## Lifecycle

`_ready()` → `setup()` → `setup_music()`: creates and starts a looping background-music `AudioStreamPlayer` at boot, before any menu is shown.

## Surface

- `set_music_volume(volume)` (160–161) — the only method; everything else is public data.
- Data: `bordering_countries` / `bordering_countries_nodes` (21–109), `total_countries_in_continents` (12–19), `colors` (4–11), `players_data_template` / `players_data` (120–146), settings fields (`main_menu_volume`, `in_game_volume`, `interface_sound`, `country_sound`, `online`, `number_of_players`), `game: Game` (111, set by `Game.setup_game()`).

## Permissions & validation

N/A — pure data/config singleton.

## Data touches

In-memory only; no persistence to disk (confirms the Phase-2 open question from [OptionsMenu.md](../ui/OptionsMenu.md) — volume/sound settings are **not saved between app launches**, they just live in this autoload for the process lifetime).

## Shared state

This *is* the shared state — read/written from nearly every other file in the codebase. Notable consumers: [Country.md](./Country.md) (`bordering_countries`, `bordering_countries_nodes`), every HUD file (`online`, `players_data`, sound toggles), [Player.md](./Player.md), [Server.md](../server/Server.md) (`players_data`, `players_data_template`).

## Findings

- **[Smell] — `bordering_countries` and `bordering_countries_nodes` are hand-duplicated, byte-identical 44-entry dictionaries.** Lines 21–64 and 66–109 list the exact same country-name adjacency lists twice. [Country.gd](./Country.md)'s `setup_bordering_countries()` (14–19) mutates `bordering_countries_nodes` in place, replacing each string entry with the actual `Country` node reference once resolved — so the *intent* of having two dicts (one of names, one that becomes node references) is legitimate, but hardcoding the same 42-country map twice means any adjacency correction (a country added/removed/re-bordered) has to be made in two places by hand, with zero enforcement that they stay in sync. A `bordering_countries_nodes = bordering_countries.duplicate(true)` at startup would remove the duplication and the drift risk entirely. Lines 21–109. *Severity guess:* medium (maintainability + correctness risk if they ever silently diverge — not observed to have diverged yet).
- **[Bug/Smell] — `players_data = players_data_template` (line 146) aliases the same `Dictionary` object rather than copying it.** GDScript `Dictionary` (and its nested per-player dictionaries, e.g. `players_data_template["0"]`) are reference types; a plain `=` doesn't clone them. As of this reading, nothing mutates fields *inside* `GamePlay.players_data` in place (all found usages are reads — confirmed via project-wide search) before [Server.gd](../server/Server.md) reassigns `GamePlay.players_data` outright (`Server.gd:104`, `Server.gd:198`), so this hasn't caused an observed corruption — but the aliasing is almost certainly accidental (the "_template" suffix implies "pristine defaults to restore from," which only works if it's never itself mutated), and any future code that does `GamePlay.players_data["0"].name = "X"` would permanently corrupt `players_data_template` too. Line 146. *Severity guess:* medium (latent — same reference-aliasing class of bug as [HostGameMenu.md](../ui/HostGameMenu.md)'s `players_list` bug).
- **[Dead code] — `var players = 3` (line 3) is never read anywhere in the codebase.** Its only reference anywhere is a commented-out line in [StartGameMenu.gd](../ui/StartGameMenu.md) (`#GamePlay.players = players.value`) — the actual player-count field that's live and used everywhere else is the separate `number_of_players` (line 119). `players` is vestigial from before that rename/refactor and was never removed. Line 3. *Severity guess:* low.

## Cross-references

Depends on / feeds: [Country.md](./Country.md) (adjacency), [Server.md](../server/Server.md) (`players_data` reassignment), [HostGameMenu.md](../ui/HostGameMenu.md) (same reference-aliasing bug class), [StartGameMenu.md](../ui/StartGameMenu.md) (dead `players` field).
