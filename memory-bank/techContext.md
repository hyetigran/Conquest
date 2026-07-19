# Tech Context

## Stack

| Concern | Choice |
|---|---|
| Engine | Godot **4.7.1** (stable) — CLI: `/Applications/Godot.app/Contents/MacOS/Godot` |
| Language | GDScript (typed) |
| Tests | GUT (Godot Unit Test), headless |
| CI | GitHub Actions (planned Arc 01) |
| Multiplayer transport | `WebSocketMultiplayerPeer` (HTML5-compatible) |
| Map data | `CountryMapData` Resource (`.tres`) — not dual dictionaries |

## Repo layout (today)

```
legacy/          # Frozen Godot 3 project (do not edit for migration work)
docs/            # Audit, migration spec, arc plans, backlog
memory-bank/     # Agent session context (this folder)
.cursor/rules/   # Project Cursor rules
```

Root `project.godot` / `Source/` / `addons/` — **not created yet** (Arc 01).

## Constraints

- Solo / Claude-assisted; no hard deadline.
- Server protocol redesign is **in scope** (separate Conquest-server repo).
- Prefer free/built-in tooling.
- Conventional Commits; PR workflow to `main`.

## Useful docs

- `docs/RECON.md` — structure, dependencies, free findings
- `docs/BUGS-MITIGATIONS.md` — 49 findings (3 critical, 3 high, …)
- `docs/MIGRATION-GODOT4.md` — architecture, roadmap, workflow
- `docs/arcs/ARC-01-foundation.md` — current arc plan
