# SelectedState.gd — Analysis

> Source: `Source/Gameplay/StateMachine/CountryStates/SelectedState.gd` · 48 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The "currently clicked/highlighted" country state — the country the player has designated as the source of an attack or fortify move.

## Surface

- `clicked(country)` (21–30) — the core selection-resolution logic: if the active player is attacking, every bordering country *not* owned by this country's occupier is pushed into `InActiveState` (marking valid attack targets — inverted naming: "in_active" here functions as "now selectable as an attack target," reusing the same state class as the generic "not interactive" default elsewhere, which is a naming/semantic overload worth noting) and this country becomes `active`; if fortifying, delegates straight to `active_player.country_clicked(country)`.

## Findings

- **[Smell] — `CountryState`'s `in_active` state is overloaded with two different meanings depending on context.** In [InActiveState.md](./InActiveState.md)/[ActiveState.md](./ActiveState.md), "in_active" means "not currently interactive." Here, `clicked()` (25–27) pushes bordering enemy countries into `in_active` specifically to *enable* clicking them as attack targets (per `ActiveState.clicked()`, being in `active` is what makes a country's `country_clicked` delegate actually run — so this looks backwards at first read: attackable *targets* are set to `in_active`, and the attacking *source* is set to `active`). This is very likely intentional (attack targets are selected via a different UI path than "active, clickable-by-me" countries), but the same state name serving two different UI purposes without a comment explaining the distinction makes this file (and its siblings) unusually easy to misread. *Severity guess:* low (readability/documentation, not a functional defect as far as this reading can determine — flagged for Phase 6 confirmation against [AttackState.md](./AttackState.md)'s consumption of these transitions).

## Cross-references

Uses `GamePlay.bordering_countries_nodes` correctly (contrast with [InActiveState.md](./InActiveState.md)'s bug, which used the wrong dictionary for the same kind of neighbor lookup).
