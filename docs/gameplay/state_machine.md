# state_machine.gd — Analysis

> Source: `Source/Gameplay/StateMachine/state_machine.gd` · 17 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The generic FSM base class (`StateMachine`, global class), subclassed by both `PlayerState` and `CountryState` hierarchies. Defines the four lifecycle hooks every concrete state overrides: `enter`, `handle_input`, `update`, `exit`.

## Surface

All four methods are no-ops (`pass`) by default — this file exists purely to establish the shared interface/contract.

## Findings

- **[Smell] — dead, broken debug-print comments.** Line 7: `#print("New state: ", get_class())`; line 17: `#print("Previous state: ", get_class().)` — the second one has a stray trailing `.` after `get_class()`, meaning it wouldn't even parse if uncommented as-is. Harmless as dead code, but a small signal that this file was debugged-then-abandoned rather than cleaned up. *Severity guess:* low.

## Cross-references

Base of [CountryState.md](./CountryState.md) and [PlayerState.md](./PlayerState.md).
