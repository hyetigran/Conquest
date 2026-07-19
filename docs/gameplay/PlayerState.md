# PlayerState.gd — Analysis

> Source: `Source/Gameplay/StateMachine/PlayerStates/PlayerState.gd` · 43 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

Base class for the four turn-phase states — [DraftState.md](./DraftState.md), [PlacementState.md](./PlacementState.md), [AttackState.md](./AttackState.md), [FortifyState.md](./FortifyState.md) — the sequence every player cycles through each turn (Placement only on the very first pass over the map; Draft/Attack/Fortify every turn after).

## Surface

All methods are no-op defaults, same pattern as [state_machine.md](./state_machine.md); `player_states` (5–10) is the shared lookup table subclasses use to construct transition targets.

## Findings

- **[Smell] — the abstract `player_attacked` signature's second parameter name doesn't match what's actually passed or what the override expects.** Line 33: `func player_attacked(player: Player, win_chance_percentage, troops: int, player_country: Country, opponent_country: Country):`. The real call site, [Player.gd](./Player.md) line 130 (`player_state.player_attacked(self, player_troop_count, opponent_troop_count, player_country, opponent_country)`), and the concrete override in [AttackState.md](./AttackState.md) (`func player_attacked(player: Player, player_troop_count: int, opponent_troop_count: int, ...)`), both agree the second argument is the *attacker's committed troop count*, not a `win_chance_percentage`. GDScript doesn't enforce override-signature matching, so this causes no runtime error — but the stale name strongly suggests the combat model was redesigned at some point (from a probability-based resolution to the literal three-dice-roll system seen in `AttackState.player_attacked`) without this base declaration being updated to match. Purely cosmetic today; flagged because it's the kind of drift that misleads anyone reading the base class as documentation. *Severity guess:* low.

## Cross-references

Base of [DraftState.md](./DraftState.md), [PlacementState.md](./PlacementState.md), [AttackState.md](./AttackState.md), [FortifyState.md](./FortifyState.md).
