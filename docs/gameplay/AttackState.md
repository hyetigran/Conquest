# AttackState.gd — Analysis

> Source: `Source/Gameplay/StateMachine/PlayerStates/AttackState.gd` · 183 lines · Layer: business logic · Audited: 2026-07-18

## Purpose

The largest and most rule-dense state file — governs which of the player's countries can attack (must have >1 troop and an enemy neighbor), the country-selection flow for choosing an attack source/target, and the dice-based combat resolution itself, including elimination and (on a successful conquest) the follow-up "move troops into the new territory" step.

## Surface

- `push_countries_in_attack_state` (12–23) — on entering this phase, deactivates (`in_active`) every owned country that has only 1 troop or no attackable neighbor.
- `select_country` / `unselect_country` (146–158) — highlight/un-highlight the chosen attacker and its attackable neighbors, using the correctly node-resolved `GamePlay.bordering_countries_nodes` (contrast with [InActiveState.md](./InActiveState.md)'s bug, which used the wrong dictionary for the equivalent lookup).
- `country_clicked` (38–48) — click routing: first click selects an attacker, a second click on an owned country re-selects, a second click on an enemy country opens the `AttackingMenu`.
- `player_attacked` (53–144) — the combat resolution: three dice each side (capped, see Findings), casualty accounting, activity/log messages, conquest handling (occupier swap, elimination check, `move_menu` follow-up), and re-deactivating a source country reduced to 1 troop.
- `update(player)` (28–33) — a `yield`-based cleanup for a selected country that's dropped to 1 troop mid-frame (see Findings).

## Permissions & validation

N/A beyond the turn-lock checks already covered in [Player.md](./Player.md)/[Country.md](./Country.md).

## Data touches

None.

## Shared state

Reads `GamePlay.bordering_countries_nodes`, `GamePlay.online`, `GamePlay.players_data`; reads `Server.my_lobby.players`.

## Findings

- **[Smell] — combat always resolves exactly 3 dice per side regardless of how many troops the UI lets the player commit, with no indication to the player that committing more has no effect.** `player_attacked` (61–77): `var ROLL_SIZE = 3`, and the roll loop only ever produces `ROLL_SIZE` (3) dice, gated by `if i < player_troop_count`/`if i < opponent_troop_count` — so any troop count above 3 on either side has *zero* additional effect on the outcome (a 4th, 5th, ... committed troop never gets a die). Meanwhile [AttackingMenu.md](../ui/AttackingMenu.md)'s slider lets the attacker choose *any* value up to `player_country.troops - 1` (not capped at 3), and the defender's dice count (`opponent_troop_count = opponent_country.troops`, [AttackingMenu.gd](../ui/AttackingMenu.md) `count_troops`) is the defender's *entire* troop count, not capped to a smaller defense-side number — every value above 3 on both sides is silently ignored by the fixed `ROLL_SIZE`. This may be an intentional simplification of Risk's normal 3-attacker/2-defender dice-cap rule, but as implemented there's no UI feedback that choosing, say, 8 troops behaves identically to choosing 3 — a player has no way to learn this except by noticing combat outcomes don't scale with their slider choice. `player_attacked` (61–77); UI side in [AttackingMenu.md](../ui/AttackingMenu.md). *Severity guess:* medium (a real, playable-and-observable balance/UX gap, not a crash).
- **[Smell] — dead/duplicated code in the activity-message assembly.** Lines 102–114 compute the "attack failed" activity message twice in a row (102–105, then again 106–107, byte-identical to the online branch) with no behavioral difference, and lines 113–114 are a commented-out near-duplicate of the immediately-preceding "succeeded" message (109–110). None of this changes behavior (the redundant assignment is simply overwritten/inert), but it's the kind of leftover-edit debris that makes this already-dense method harder to trust on a read-through — a reviewer has to confirm the duplicate blocks really are identical rather than assume they diverge. `player_attacked` (102–114). *Severity guess:* low.
- **[Smell] — `update()`'s single-country cleanup uses a per-call `yield`, which can stack redundant, overlapping coroutines under render load.** Lines 28–33: called every frame from [Player.md](./Player.md)'s `_process`; if `selected_country.troops == 1`, it calls `change_country_state("in_active")` (triggering a network replication call per [Country.md](./Country.md)'s convention) and then `yield`s one idle frame before nulling `selected_country`. Because `selected_country` isn't cleared until *after* the yield resumes, and `update()` runs again on the very next frame (before that yield necessarily resumes, depending on engine scheduling), the same "troops == 1" condition can be detected — and `change_country_state("in_active")` re-invoked, with its network call — more than once for the same country before `selected_country` finally becomes null. Not observed to cause incorrect final state (the transition is idempotent), but it does mean redundant network replication traffic for what should be a one-time transition. `update` (28–33). *Severity guess:* low (inefficiency, not incorrectness).

## Cross-references

Uses `bordering_countries_nodes` correctly, contrasting with [InActiveState.md](./InActiveState.md)'s bug. Feeds [Player.md](./Player.md) (`eliminate`, `occupy_country`, `leave_country`) and [game_play.md](./game_play.md) (via the two-sources-of-truth player-color/data lookups repeated here, same pattern as [DraftState.md](./DraftState.md)).
