# MoveMenu.gd — Analysis

> Source: `Source/Gameplay/HUD/MoveMenu.gd` · 51 lines · Layer: UI · Audited: 2026-07-18

## Purpose

Shared overlay for both the post-attack "move troops into conquered territory" step and the Fortify phase's "move troops between owned, connected countries" — distinguished by a `state` string parameter (`"Attack"` or `"Fortify"`).

## Lifecycle

`_ready()` calls `move_troops()` with no args (all defaults null/""), same placeholder-then-real-call pattern as the other overlays.

## Surface

- `move_troops(c1, c2, state)` (19–34) — configures source/destination labels and the troop-count slider; toggles a margin spacer and the Cancel button based on `state`.
- `cancel()` (36–38) / `move()` (40–44) — dismiss / emit `moved`.
- `value_changed(value)` (46–50) — duplicated pluralization logic (see [DeployMenu.md](./DeployMenu.md)).

## Permissions & validation

- **Checks missing:** `state` is compared against the literal strings `"Attack"`/`"Fortify"` (lines 20, 23) with no `elif`/`else` fallback — a caller passing any other value (typo, e.g. `"attack"` lowercase, or a future third state) silently leaves `left_margin`/`cancel_button` in whatever visibility they were already in, with no warning. String-based state dispatch instead of using the existing `PlayerState`/`CountryState` class hierarchy (see [PlayerState.md](../gameplay/PlayerState.md)) means this coupling is invisible to the type system and easy to typo.
- No check that `c1.troops >= 2` before `troops_range.max_value = c1.troops - 1` (line 29) — same class of missing guard as `AttackingMenu`.

## Data touches

None.

## Shared state

`GamePlay.game.active_player.overlay` via `cancel()`.

## Findings

- **[Smell] — state passed as a bare string with no validation or shared constant.** (19–25) A typo'd or renamed state string silently no-ops the margin/cancel-button toggle instead of raising an error, and the two valid values aren't defined anywhere as constants — they're free-floating literals that must match whatever `AttackState`/`FortifyState` happen to pass (to be confirmed in Phase 3). *Severity guess:* medium.
- **[Smell] — duplicated pluralization logic**, same as [DeployMenu.md](./DeployMenu.md) and [AttackingMenu.md](./AttackingMenu.md). *Severity guess:* low.

## Cross-references

Depends on whatever calls `move_troops` with `"Attack"`/`"Fortify"` — likely [AttackState.md](../gameplay/AttackState.md) and [FortifyState.md](../gameplay/FortifyState.md) (to confirm). Shares pluralization duplication with [DeployMenu.md](./DeployMenu.md), [AttackingMenu.md](./AttackingMenu.md).
