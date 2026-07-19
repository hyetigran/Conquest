# Progress

## Status

**Phase: pre–Arc 01 implementation.** Audit and migration planning are done. Godot 4 scaffold not started.

## What works

- Full legacy-code audit (40 `.gd` files + data layer) under `docs/`.
- Bug catalog: `docs/BUGS-MITIGATIONS.md` (49 findings).
- Migration options scored; Route D selected.
- Migration spec + Arc 01 plan written.
- `legacy/` freeze of original Godot 3 project.
- Memory Bank operational for agent continuity.

## What's left (high level)

| Arc | Focus | Status |
|---|---|---|
| 01 | Foundation (project, converter pass, GUT, CI) | **Next** |
| 02 | Data layer (`CountryMapData`, `PlayerProfile`) | Pending |
| 03 | Country & map domain (+ F-001 etc.) | Pending |
| 04 | Player & turn domain | Pending |
| 05 | Offline game loop (first playable milestone) | Pending |
| 06–08 | Networking, multiplayer, lobby/server | Pending |
| 09–10 | Polish, exports, release | Pending |

Full roadmap: `docs/MIGRATION-GODOT4.md`.

## Known issues / blockers

- No root Godot 4 project yet — cannot run or test the rewrite.
- GUT fetch method for Slice 01-03 still open.
- README still documents Godot 3 install (update in Arc 10 / when root project exists).

## Backlog (post–Arc 10)

- Middle Earth (LOTR) map — `docs/BACKLOG.md`
