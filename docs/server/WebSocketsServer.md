# WebSocketsServer.gd — Analysis

> Source: `Source/Server/WebSocketsServer.gd` · 70 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The **actually-used** network transport (per [Server.md](./Server.md)'s finding that `should_use_web_sockets_server` defaults `true`) — wraps Godot 3's built-in `WebSocketClient`. Polled every frame (`_process`) rather than event-driven, since Godot 3's WebSocket API requires manual polling.

## Lifecycle

`_ready()` disables `_process` until a connection attempt succeeds (`connect_to_server` re-enables it, line 19); every frame thereafter, `_process` calls `client.poll()` (53–54) to drive the underlying connection state machine and dispatch queued signals.

## Surface

Mirrors [HighLevelServer.md](./HighLevelServer.md)'s method names (see that file). `received_data_from_server` (39–42) pulls one variant-encoded message per call via `client.get_peer(1).get_var()`.

## Findings

- **[Bug] — `disconnect_server_signals()`'s guard checks for a connection to a method name, `"_closed"`, that is never used anywhere in this file — so the guard condition is always true, and the function's actual disconnect calls never execute.** Lines 64–70:
  ```gdscript
  func disconnect_server_signals():
  	if !client.is_connected("connection_closed", self, "_closed"):
  		return
  	client.disconnect("connection_closed", self, "disconnected_from_server")
  	client.disconnect("connection_error", self, "disconnected_from_server")
  	client.disconnect("connection_established", self, "connected_to_server")
  	client.disconnect("data_received", self, "received_data_from_server")
  ```
  `connect_server_signals()` (23–29) connects `"connection_closed"` to the method `disconnected_from_server`, never to a method called `_closed` — no method by that name exists anywhere in this file. So `client.is_connected("connection_closed", self, "_closed")` checks for a connection that was never made, always returns `false`, and the guard's `if !false_thing: return` — i.e. `if true: return` — fires unconditionally on line 66, before any of the four real `disconnect(...)` calls on lines 67–70 ever run. The correct guard should check `is_connected("connection_closed", self, "disconnected_from_server")`, matching what's actually wired up (and matching the pattern used correctly in the sibling `HighLevelServer.gd`'s equivalent method — see [HighLevelServer.md](./HighLevelServer.md)). Practical impact is currently limited because [Server.gd](./Server.md)'s `disconnect_server()` immediately `queue_free()`s the whole `WebSocketsServer` node right after calling this (so the connections get torn down implicitly along with the object, via Godot's own node cleanup) rather than because this function does its job — but the function is, as written, entirely inert: it never disconnects anything, ever, regardless of connection state. This looks like a rename that was applied everywhere except this one string literal (the method used to plausibly be called `_closed` and was renamed to `disconnected_from_server`, missing this one reference). `disconnect_server_signals` (64–70). *Severity guess:* medium (dead code masquerading as working cleanup logic, in the transport backend that's actually live — currently masked by how the caller happens to free the node immediately afterward; would become a real signal-connection leak if this backend were ever changed to persist/reuse a `WebSocketsServer` instance across reconnects instead of re-instancing one per attempt).

## Cross-references

Contrast with [HighLevelServer.md](./HighLevelServer.md)'s correctly-written equivalent guard — strong evidence this is a copy-then-drift bug, not an intentional difference. Instanced and torn down by [Server.md](./Server.md)'s `connect_to_server`/`disconnect_server`.
