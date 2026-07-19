# HighLevelServer.gd — Analysis

> Source: `Source/Server/HighLevelServer.gd` · 60 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

One of two interchangeable network transports [Server.md](./Server.md) can select — wraps Godot 3's built-in `NetworkedMultiplayerENet` (UDP-based, ENet protocol) high-level multiplayer API. Per [Server.md](./Server.md)'s findings, this backend is **not currently reachable** in the shipped project (the `should_use_web_sockets_server` export defaults `true`), making this entire file dead code today.

## Surface

Mirrors [WebSocketsServer.md](./WebSocketsServer.md)'s method names exactly (`connect_to_server`, `connect_server_signals`, `connected_to_server`, `disconnected_from_server`, `process_method_info`, `send_data_to_server`, `disconnect_from_server`, `disconnect_server_signals`) with no shared base class or interface between them — [Server.gd](./Server.md) relies purely on both scripts happening to implement the same method names (GDScript duck-typing).

## Findings

- **[Dead code] — the entire file is unreachable in the shipped configuration.** See [Server.md](./Server.md)'s finding on `should_use_web_sockets_server`. Not itself a defect, but worth flagging plainly: this is ~60 lines (plus its accompanying `.tscn`) of maintenance surface with zero current exercise, and it depends on a Godot 3 API (`NetworkedMultiplayerENet`) that doesn't exist in Godot 4 (renamed to `ENetMultiplayerPeer` with a different API shape per the [RECON.md](../RECON.md) Dependencies table) — so a future engine upgrade would need to either port or delete this file with no way to verify correctness against current behavior (it was never being exercised to begin with). *Severity guess:* low (no runtime risk; a migration-planning note).
- **[Smell] — `disconnect_server_signals()`'s guard correctly matches its own `connect_server_signals()`'s target method, unlike the equivalent method in the *live* backend.** (55–59) `get_tree().is_connected("connected_to_server", self, "connected_to_server")` correctly mirrors what `connect_server_signals()` (20–24) actually connects. Noted here only for contrast — see [WebSocketsServer.md](./WebSocketsServer.md)'s finding, where the equivalent guard in the backend that's *actually in use* is broken.

## Cross-references

Duck-typed sibling of [WebSocketsServer.md](./WebSocketsServer.md) (see that file for the live backend's broken disconnect guard). Selected (or rather, not selected) by [Server.md](./Server.md).
