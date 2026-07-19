# System Patterns

## Target layers (Godot 4 rewrite)

Dependency order from `docs/MIGRATION-GODOT4.md`:

1. **Data** — one authoritative source per table (`CountryMapData`, `PlayerProfile` resources). No duplicated literals.
2. **Domain** — `Country`, `Player`, `PlayersQueue`, `Game`, state machines. **Zero network awareness.**
3. **Networking** — explicit `@rpc`-annotated entry points over `WebSocketMultiplayerPeer`. No string-keyed generic dispatch.
4. **Presentation** — HUD/menus; typed refs, no `get_owner().name` / parent-type inference.

## Cross-cutting rules

- State transitions: enums/constants, not bare strings.
- One permission/turn-lock check implementation per class — never copy-pasted.
- Static typing on all new function signatures.

## Legacy shape (reference only)

Center of gravity was player FSM + country FSM, with `Game.gd` / `game_play.gd` autoload above them. Networking lived in `legacy/Source/Server/` (WebSocket live; ENet dead). Do not port that replication design — rebuild per Arc 06+.

## Workflow patterns

- Branch per slice: `slice/<arc>-<story>-<slice>-<short-name>` off `main`.
- Implementer never merges own work to `main` — open PR; human squash-merges.
- Side quests → `docs/BACKLOG.md` only after Arc 10.
- Arc plans: `docs/arcs/ARC-NN-*.md` written just before that arc starts.
