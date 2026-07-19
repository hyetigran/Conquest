# Project Brief — Conquest

## What

Conquest is a Risk-like territory-conquest strategy game (claim countries, deploy troops, attack neighbors, fortify, eliminate opponents). Playable same-device (hotseat) or online multiplayer.

## Current goal

**Godot 3 → Godot 4 rewrite (Route D)** — audit-guided greenfield client in GDScript, with a redesigned networking layer. Spec: `docs/MIGRATION-GODOT4.md`. Options rationale: `docs/MIGRATION-OPTIONS.md`.

## Non-goals (until Arc 10 ships)

- New features / side quests (park in `docs/BACKLOG.md`)
- Fixing bugs in-place on Godot 3
- Porting the old hand-rolled `net_call` / `get_node_method_call` networking design

## Source of truth

| Concern | Location |
|---|---|
| Legacy Godot 3 game (frozen) | `legacy/` |
| Audit + bug catalog | `docs/RECON.md`, `docs/BUGS-MITIGATIONS.md`, `docs/ui/`, `docs/gameplay/`, `docs/server/`, `docs/data/` |
| Migration plan | `docs/MIGRATION-GODOT4.md`, `docs/arcs/` |
| Post-migration ideas | `docs/BACKLOG.md` |

Audit paths cite pre-migration layout; prefix with `legacy/` (e.g. `legacy/Source/...`).
