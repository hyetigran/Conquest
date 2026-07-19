# PlayersQueue.gd — Analysis

> Source: `Source/Gameplay/PlayersQueue/PlayersQueue.gd` · 42 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

Turn-order manager — a thin round-robin scheduler over the `Player` child nodes, skipping eliminated players.

## Lifecycle

`_ready()` → `setup()`: connects every child's `turn_completed` signal back to `next_turn`, then kicks off `play_first_turn()`.

## Surface

- `next_turn(net_call)` (26–41) — advances `active_index`, wrapping and skipping eliminated players, activates the new player, emits `active_player_changed`, and (if this is the authoritative/local call, not a replicated one) forwards the turn advance to other clients via `Server.send_node_func_call`.

## Permissions & validation

- **Checks missing:** no check that at least one non-eliminated player exists before the `while active_player.eliminated:` loop (31–35) — see Findings.

## Data touches

None.

## Shared state

Emits `active_player_changed` (consumed by [Game.md](./Game.md)'s `active_player_changed`). Reads `GamePlay.online`.

## Findings

- **[Bug] — `next_turn()`'s eliminated-player skip loop can spin forever if every player is eliminated.** Lines 31–35:
  ```gdscript
  while active_player.eliminated:
  	active_index += 1
  	if active_index >= get_child_count():
  		active_index = 0
  	active_player = get_child(active_index)
  ```
  There's no check for "all players eliminated" before entering this loop, and no iteration cap — if `all_eliminated()` (defined on [Game.gd](./Game.md), not called from here) isn't guaranteed to end the match *before* `next_turn()` fires again, this becomes an infinite loop with no player ever satisfying `not eliminated`. Whether the game-over transition reliably happens before the last elimination's next `next_turn()` call is a cross-file question — depends on exactly when `Player.eliminate()` fires relative to `turn_completed`. `next_turn` (26–41). *Severity guess:* high (hang risk at the natural end-of-match moment — precisely when this code is most likely to run), pending Phase 6 confirmation of call ordering against [Player.md](./Player.md)'s elimination flow.

  **Phase 6 deep-dive update (2026-07-18):** confirmed against [AttackState.md](./AttackState.md)'s `player_attacked` (elimination happens at lines 115–127 there). In the normal single-winner game flow, eliminations only ever remove *losing* players — the player who lands the eliminating attack is, by construction, never eliminated themselves, so at most `N-1` of `N` players can ever have `eliminated == true` simultaneously; at least one (the eventual winner) always satisfies `not eliminated`, so this `while` loop is guaranteed to terminate within `get_child_count()` iterations in that path. `Game.all_eliminated()` itself is only consulted from inside `AttackState.player_attacked` (to trigger the game-over overlay) and is never checked by `PlayersQueue.next_turn()` before it runs — so the *missing guard* is real and this remains a defensive-programming gap, not merely a stylistic one, but reaching a state where **every** player (including whoever would otherwise be "last one standing") is simultaneously `eliminated` isn't reachable through the elimination path this codebase actually implements. Revised assessment: *low* (a real gap, worth closing defensively before any rule change that could introduce simultaneous/mutual eliminations, but not exploitable through any currently-implemented game flow) rather than the *high* originally guessed pending this confirmation.

## Cross-references

Consumed by [Game.md](./Game.md). Feeds turn-completion signals from [Player.md](./Player.md) (`turn_completed`). The infinite-loop risk should be checked against [Player.md](./Player.md)'s `eliminate()`/game-over flow in Phase 6.
