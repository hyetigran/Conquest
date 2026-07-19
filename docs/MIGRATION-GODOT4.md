# Migration Spec — Conquest (Godot 3/GDScript) → Godot 4/GDScript

> Route chosen in [MIGRATION-OPTIONS.md](./MIGRATION-OPTIONS.md) (Route D). Specification derived from the audit in `docs/ui/`, `docs/gameplay/`, `docs/server/`, `docs/data/` and the catalog in [BUGS-MITIGATIONS.md](./BUGS-MITIGATIONS.md).

## Target architecture

Same four-layer shape the audit already found in the original (`docs/RECON.md`'s structure map) — the domain layer isn't being redesigned, the networking layer is. Layers, in dependency order:

1. **Data** — map/adjacency graph, continent totals, player-profile defaults. **Rule: exactly one authoritative source per table, no hand-duplicated literals.** *Why:* F-011 (duplicated 42-country adjacency dict), F-012 (aliased `players_data`/`players_data_template`), F-013 (two divergent player-color tables) — three separate instances of the same "two copies of one table" failure mode in the original.
2. **Domain** — `Country`, `Player`, `PlayersQueue`, `Game`, and the `CountryState`/`PlayerState` FSM families. **Rule: this layer has zero network awareness.** No `net_call` parameters, no `if GamePlay.online: Server.send_node_func_call(...)` calls anywhere in `Country.gd`/`Player.gd`/etc. *Why:* this is the single biggest structural change from the original, where F-016 documented ~27 sites where domain mutators also carried replication logic, and where that entanglement directly caused F-005 (inconsistent sync) and contributed to F-002 (spawn-count confusion). Domain code becomes replicable *because* the networking layer wraps it, not because each method remembers to call out to `Server`.
3. **Networking** — a small, explicit set of `@rpc`-annotated entry points (Godot 4's native multiplayer API: `@rpc("authority")`, `@rpc("any_peer")`, `MultiplayerSynchronizer` for simple state, explicit RPCs for actions) that call into the domain layer. **Rule: no generic "call this method by string name" dispatcher exists anywhere.** Every network-reachable action is a named, annotated method with a fixed signature, enumerable by reading the RPC annotations in the codebase. *Why:* directly designs out F-003 (the original's `get_node_method_call` accepted arbitrary node path + method name + parameter with no allow-list) and removes the possibility of F-016 recurring, since Godot enforces the replication contract at the language level instead of relying on a remembered convention.
4. **Presentation** — HUD/menu scenes, unchanged in spirit from the original (same screens, same flow), rebuilt to reference domain objects directly rather than through string-based lookups. **Rule: no `get_owner().name == "..."` or `get_parent() is SomeType` context inference; pass explicit typed references/flags.** *Why:* F-014, F-015 (both fragile-inference patterns found independently in `OptionsMenu.gd`, `QuitGameMenu.gd`, `StartGameMenu.gd`).

Additional cross-cutting rules:

- **State-machine transitions are enums, not bare strings.** *Why:* F-025 (`MoveMenu`'s unvalidated `"Attack"`/`"Fortify"` string), and the broader naming-drift pattern (F-035) where one concept had three different string identifiers across three files.
- **One permission/turn-lock check, one implementation.** Any "is it this client's turn to act on this object" check lives in exactly one function per relevant class, called everywhere needed — never copy-pasted. *Why:* F-008 (the original had the same three-line check pasted five times, one of which silently went stale/disabled).
- **Static typing on all new function signatures** (`func foo(x: int) -> void:`), which Godot 4's GDScript supports more completely than Godot 3's. *Why:* the InActiveState.gd crash (F-001) was a shadowed-variable-hides-wrong-type bug that a type checker would have caught immediately.

## Stack

| Concern | Original (Godot 3) | Replacement (Godot 4) | Why |
|---|---|---|---|
| Language/runtime | GDScript, Godot 3.x | GDScript, Godot 4.x (latest stable) | Same language — matches the team's only demonstrated skill (100% GDScript in the original repo); Godot 4 is the actively maintained engine line (resolves F-049). |
| Client networking | Hand-rolled `net_call` convention over `NetworkedMultiplayerENet` (dead in practice, F-033) or `WebSocketClient` (live) | Godot 4's `MultiplayerAPI` / `SceneMultiplayer`, transported over `WebSocketMultiplayerPeer` (keeps the browser/HTML5-compatible transport the constraints require) | Kills F-003, F-005, F-016 at the root — replication becomes a language-level annotation, not a remembered pattern. |
| Server / lobby protocol | Custom message-dispatch protocol in the separate `Conquest-server` repo, mirrored by `Server.gd`'s `send_data_to_server`/`get_node_method_call` | Redesigned protocol co-developed with the server repo (in scope per the constraints interview): an explicit, enumerated command set for lobby operations (create/join/leave/kick/chat/start) plus the `@rpc` surface above for in-match state — exact server-side implementation choice deferred to Arc 08, once the client-side contract (Arc 06) is stable | The old protocol's client-side receiver (`get_node_method_call`) was the F-003 finding; redesigning it is only possible because the server is in scope. |
| Map/adjacency data | Two duplicated 42-entry `Dictionary` literals in `game_play.gd` (F-011) | One `CountryMapData` `Resource` (`.tres`), loaded once; node references resolved via a lookup helper, never a second hardcoded copy | Removes the drift risk entirely — there's no second literal to fall out of sync. |
| Player profile/color data | `GamePlay.colors` + `GamePlay.players_data`/`players_data_template`, aliased and divergent (F-012, F-013) | One `PlayerProfile` resource per seat (name, color), a single source read everywhere | Removes both the aliasing bug and the two-color-tables bug in one structural change. |
| Test framework | None (F-048) | GUT (Godot Unit Test) for unit + integration tests; headless `godot --check-only`/export smoke run in CI | Establishes the regression safety net the original never had — the merge gate (below) depends on it existing from Arc 01. |
| Export targets | Desktop + HTML5 (confirmed via `Server.gd`'s `OS.get_name() == "HTML5"` check) | Desktop + HTML5, Godot 4 export templates | Preserves the deployment constraint explicitly confirmed with the user. |

## Standards

- **Coding conventions:** static types on all new function signatures and exported vars; no bare-string dispatch for states/modes (enums or constants only); no boolean "did this call come from the network" parameters on domain methods (that responsibility moves entirely to the networking layer, per the architecture rules above); comments only where a non-obvious constraint or workaround needs explaining, matching this project's existing (good) practice of otherwise-comment-free code.
- **Test strategy & merge gate:** every slice includes GUT unit tests for the domain logic it touches — in particular, every arc that ports a `CountryState`/`PlayerState` file must include a regression test for that file's specific F-00x finding(s) so the exact bug class can't silently return. The data layer (Arc 02) gets an automated adjacency-symmetry + continent-count check (promoting the one-off Phase 4 audit script in `docs/data/country-scenes.md` into a permanent test, not a one-time manual check). Integration tests cover state-machine transition sequences and (from Arc 07 onward) a two-headless-peer multiplayer smoke test. Merge gate: unit + integration green, plus a headless export smoke-check, before any slice is presented for human review.
- **Commit conventions:** Conventional Commits; squash-merge to protected `main`; no direct commits to `main` by the implementer (human always merges — see Workflow).

## Findings map

| Finding ID(s) | Severity | Designed out by | How |
|---|---|---|---|
| F-001 | Critical | Arc 03 | `InActiveState.gd` rewritten with the correct node-resolved adjacency lookup and a non-colliding loop variable name; static typing on the loop variable would have caught the shadowing at edit time. Regression test added. |
| F-002 | Critical | Arc 07 | Online player spawn count is read from one explicit, authoritative integer (never from iterating a roster `Dictionary`) — the type confusion that caused this can't recur because the new networking layer doesn't reuse one variable for two different shapes. |
| F-003 | Critical | Arc 06 | Generic `get_node_method_call`-style dispatch is deleted outright; replaced by a fixed, enumerable set of `@rpc`-annotated methods with no arbitrary node-path/method-name arguments. |
| F-004 | High | Arc 08 | Lobby-roster construction is rewritten server-side against the new protocol; the client no longer pre-builds a player-slot dictionary by hand, removing the aliased/overwritten-key bug's entire code path. |
| F-005 | High | Arc 07 | Reinforcement rolls and all other in-match state become either server-authoritative or explicitly `@rpc`-declared — the old "some mutators sync, some silently don't" asymmetry is structurally impossible once replication is declared per-method instead of remembered per-call-site. |
| F-006 | High | Arc 04 | `Player.eliminate()`'s notification call moves out of the (now-deleted) network-branch conditional entirely — it fires unconditionally on elimination, in every mode, by construction of the domain layer having no network awareness. |

Medium/low findings map at category level (each still gets an individual line item in its arc's planning file when that arc starts):

| Category | Finding IDs | Arc |
|---|---|---|
| Data duplication / two-sources-of-truth | F-011, F-012, F-013 | 02 |
| Duplicated logic (non-data) | F-009, F-010, F-031 | 05 |
| Copy-pasted permission/guard checks | F-007, F-008 | 03 |
| Fragile string/name-based coupling | F-014, F-015, F-021, F-022 | 05 |
| Template/scene coupling | F-024 | 03 |
| Networking-layer bugs specific to the old protocol | F-017, F-018 | 08 (F-017), 06 (F-018 — moot once the transport layer is rewritten, but tracked) |
| Game logic / balance | F-019, F-020, F-023, F-042, F-043, F-044 | 04 |
| Dead code / unfinished features | F-027, F-028, F-029, F-030, F-033, F-037, F-038, F-039, F-040, F-041 | 09 |
| Naming/readability drift | F-035, F-036 | 03, 04 (fixed in the file each touches) |
| Missing validation | F-032, F-045, F-046 | 05, 08 |
| Process / dependencies | F-048, F-049 | 01 (both — test infra stood up, engine upgrade itself resolves the EOL forcing function) |

## Roadmap

| Arc | Focus | Depends on | Effort (range) | Demonstrable outcome |
|---|---|---|---|---|
| 01 | Foundation — Godot 4 project skeleton, run the built-in 3→4 converter as a first pass over syntax-only files, wire up GUT + headless CI smoke check | — | 1–2 weeks | Empty-but-running Godot 4 project with green CI on a trivial test |
| 02 | Data layer — single-source `CountryMapData` resource + `PlayerProfile` data, automated adjacency-symmetry test | 01 | 1 week | Data layer loads and passes its own integrity test standalone (no UI yet) |
| 03 | Country & Map domain — `Country.gd` + `CountryState` family ported and fixed (F-001, F-007, F-008, F-024), 42 country scenes re-verified against Arc 02's data layer | 02 | 2–3 weeks | Map renders, countries are clickable and highlight correctly, in a bare test scene |
| 04 | Player & turn domain — `Player.gd`, `PlayersQueue.gd`, `PlayerState` family ported with network-awareness stripped out and F-006/F-019/F-020/F-042/F-043/F-044 fixed | 03 | 2–3 weeks | Full turn cycle (Draft→Placement→Attack→Fortify) runs correctly for simulated players in a test harness, no UI yet |
| 05 | Offline game loop — `Main.gd`, `Menu.gd`, all 17 HUD scripts assembled into a playable match; decide and act on `SameDeviceMenu`'s fate (F-027); fix remaining UI-layer findings (F-009, F-010, F-014, F-015, F-021, F-022, F-031, F-032, F-045, F-046) | 04 | 3–4 weeks | **A complete offline hotseat match is playable start to finish in Godot 4 — the first fully demonstrable milestone, with zero networking code written yet.** |
| 06 | Networking foundation (client) — design and implement the `@rpc`-annotated client-side networking layer over `WebSocketMultiplayerPeer`, replacing `Source/Server/` entirely (F-003, F-018) | 05 | 2–3 weeks | Two local client instances can connect to a stub/dev server and exchange a trivial synced value |
| 07 | Multiplayer domain integration — wire Arc 04/05's domain layer to Arc 06's networking layer; fix F-002, F-005 as part of this wiring | 06 | 2–3 weeks | A full match is playable between two local client instances against a dev server |
| 08 | Lobby & server — redesign and implement the companion `Conquest-server` protocol (create/join/leave/kick/chat/start) matching Arc 06/07's client contract; fix F-004, F-017 | 07 | 3–4 weeks | Two players can find each other via a real lobby (not a dev stub) and start a match |
| 09 | Polish & remaining findings — sweep remaining dead code (F-028, F-029, F-030, F-033, F-037, F-038, F-039, F-040, F-041), naming drift, and anything not naturally resolved above | 08 | 1–2 weeks | Bug catalog fully struck through or explicitly deferred with reasons |
| 10 | Hardening & release — desktop + HTML5 export verified, full regression pass against the original catalog, README/docs updated for Godot 4 | 01–09 | 1–2 weeks | Exported, playable builds (desktop + browser) ready to replace the Godot 3 version |

**Total estimate: 18–27 weeks (≈4.5–6.5 months)**, assuming a solo developer working part-time/hobby-pace with Claude Code assistance and no hard deadline — the same assumption stated in the constraints interview. Arc 08 is the widest-range arc since it spans two repositories and a protocol co-design; it's also the arc most likely to reveal the plan was wrong (per the slice-loop's reflection rule) once real client↔server round-trips are attempted.

## Workflow

Slice loop per `references/slice-loop.md`:

- Branch per slice, off `main`, every time: `slice/<arc>-<story>-<slice>-<short-name>` (e.g. `slice/03-country-state-01-fix-inactive-crash`). No slice/task/ticket is ever worked directly on `main`.
- Each slice: implementation + GUT tests + doc updates together, ≤ ~500 lines of meaningful diff.
- Full gate (unit + integration + headless smoke) before any slice is presented.
- **The implementer never commits to `main` and never merges its own work.** Once the branch passes its gate, push it and open a pull request against `main` (`gh pr create`) — the PR description covers what changed, which findings/stories it advances, and the gate results (the same content the slice-loop's "present" step calls for, now as the PR body instead of only a terminal diff). The human reviews the PR (on GitHub or locally) and merges it (squash, Conventional Commits message) — that merge is the only way anything reaches `main`. Branch protection on `main` should ultimately enforce this (PR required, no direct pushes), not just convention.
- One append-only entry per slice in `docs/DEV-LOG.md` (`assets/DEV-LOG-TEMPLATE.md` shape); when a slice resolves a catalog finding, that finding gets struck through in `docs/BUGS-MITIGATIONS.md` with a reference to the resolving slice.
- Each arc gets its planning file `docs/arcs/ARC-NN-NAME.md` written just before that arc starts (not all ten upfront), and a `arc-NN-complete` tag plus a short dev-log retro when it finishes.
- Side quests (new features beyond what's in this spec) go to [BACKLOG.md](./BACKLOG.md), never into an in-flight slice — they wait until Arc 10 ships.
