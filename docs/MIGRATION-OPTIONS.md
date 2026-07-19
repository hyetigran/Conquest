# Migration Options — Conquest

> Built from `docs/BUGS-MITIGATIONS.md` (49 findings: 3 critical, 3 high, 20 medium, 23 low) and the 40-file per-file audit in `docs/ui/`, `docs/gameplay/`, `docs/server/`, `docs/data/`.

## Findings tally & problem shape

The catalog doesn't describe a codebase that's rotten throughout — it describes one **sound domain layer sitting on a broken networking layer, running on an aging engine whose networking APIs no longer exist in the next major version.**

Evidence for that split, not just an opinion:

- **Domain logic (map, turn state machine, combat, adjacency) is basically sound.** The data-layer check in `docs/data/country-scenes.md` found the 42-country adjacency graph fully symmetric and continent totals exactly matching scene data — hand-authored data with zero integrity errors. The state-machine bugs found (F-001 `InActiveState.gd`, F-019 `DraftState.gd`'s bonus formula) are real but *local, one-file, mechanically fixable* bugs, not evidence of a broken design.
- **The networking/replication layer is where the design itself is the problem.** F-016 (a hand-rolled `net_call` replication convention copy-pasted ~27 times with no enforcement), F-003 (an unrestricted node/method/arg RPC dispatcher with no allow-list — critical, security-relevant), F-002/F-004 (a lobby-roster bug that likely breaks online player spawning), and F-005 (an unsynced random troop roll) are all in `Source/Server/` and the `net_call` sites across `Player.gd`/`Country.gd`. That's where 2 of 3 criticals, 2 of 3 highs, and a large share of the mediums cluster.
- **The engine itself is a forcing function, not just a nice-to-have.** Godot 3 is off the actively-maintained track; `NetworkedMultiplayerENet` and `WebSocketClient` (the exact two backends `Source/Server/` wraps) are renamed/reworked APIs in Godot 4. Any engine upgrade is *already* a networking-layer rewrite, whether or not the cataloged bugs are fixed at the same time.

That shape argues for a rewrite whose boundary follows the fault line already visible in the audit: **carry the domain layer forward with its cataloged bugs fixed, rebuild the networking/replication layer natively** rather than porting its current shape. It argues against both extremes — a pure "fix in place, stay on Godot 3" route (ignores the forcing function), and a full ground-up rewrite discarding the domain layer too (throws away code that's demonstrably fine).

## Constraints

From the interview:

- **Driver / rewrite appetite:** port to Godot 4 — same engine family and language (GDScript), but explicitly understood to require rewriting `Source/Server/`'s networking, not just a version bump.
- **Server:** the companion server (`Conquest-server`, separate repo, live at `conquestgame.online`) is **in scope** — the wire protocol itself can be redesigned as part of this migration. This removes "must stay byte-compatible with a live production server" as a hard constraint, which is what makes rebuilding the networking layer (rather than porting it) actually viable.
- **Team:** solo/small, working with Claude Code, no hard deadline. The existing codebase is 100% GDScript with no C#/other-language files — no evidence of existing C# skill on this team. Favors an incremental slice-loop over a big-bang rewrite, and favors staying in the team's existing language unless a specific finding demands otherwise.
- **Fidelity:** workflow-faithful, bugs fixed — same game (map, rules, turn flow, lobby/multiplayer), but the critical/high findings and the architectural issues (F-003, F-016) get designed out rather than reproduced. Open to small rule deviations only where a fix is genuinely cleaner (e.g. F-019's bonus formula), not wholesale redesign.
- **Deployment:** Web/HTML5 export must be preserved — `Server.gd`'s `is_running_on_the_web()` check confirms the current game already ships to browsers, not just desktop.
- **Tooling cost:** not explicitly capped, but the team is small/solo with no budget mentioned — free/built-in tooling is strongly preferred over commercial translators.

## Routes

### Route A — Keep & remediate on Godot 3

Fix the cataloged findings in place; no engine upgrade. **Effort: 1–3 weeks** (mostly the 3 critical + 3 high + the more mechanical mediums; assumes the systemic `net_call` finding, F-016, is *documented* as accepted debt rather than restructured, since restructuring it properly is most of the engine-upgrade effort anyway). **Findings handling:** designs out F-001, F-006, F-017, F-018 cheaply (small local fixes); F-002/F-004/F-005 fixable without an engine change; **F-003 and F-016 are architecturally rooted and only partially fixable without the replication rewrite this route avoids** — an allow-list can be bolted onto `get_node_method_call` but the underlying hand-rolled convention stays. **Biggest weakness:** doesn't touch the forcing function at all — the moment a Godot 4 upgrade becomes unavoidable (asset store support, editor features, Godot 3 stops receiving even critical fixes), this route's work on `Source/Server/` gets thrown away and redone.

### Route B — Incremental / strangler (new Godot 4 client+server alongside the old)

Stand up a new Godot 4 client and redesigned server side by side with the current Godot 3 client + `Conquest-server`; cut individual features (lobby, then match, then full game) over as they're ready; retire the old pair once parity is reached. **Effort: 3–5 months** (longest of any route — running two engine-version codebases and two server protocols simultaneously has real coexistence tax, and Godot doesn't support running 3.x and 4.x logic in one project, so "strangling" here means two fully separate projects with a manual cutover, not code-level interleaving). **Findings handling:** designs out everything the greenfield routes do, eventually — same target architecture as Route D, just reached via a longer, dual-maintenance path. **Biggest weakness:** the coexistence cost is disproportionate for a solo/no-deadline hobby project with no active user base that needs zero-downtime migration — this pattern earns its cost on systems with real, can't-interrupt traffic, which a "public instance, no urgent deadline" indie game is not.

### Route C — Automated translation (Godot's built-in 3→4 converter) + cleanup

Godot 4 ships an official project-conversion tool that mechanically handles most GDScript 3→4 syntax renames (e.g. `onready var` → `@onready var`, signal/connect syntax, some API renames). Run it, then manually rewrite the networking layer (the converter does not, and cannot, redesign `NetworkedMultiplayerENet`/`WebSocketClient` usage into Godot 4's multiplayer API) and fix the catalog. **Effort: 3–5 weeks** (fast to "compiles and runs" for ~35 of 40 files; the `Source/Server/` rewrite is the same work as every other route since no tool automates that part). **Findings handling:** inherits every cataloged bug into the converted output by design (a mechanical converter preserves behavior, bugs included) — the catalog still has to be worked through by hand afterward, so this route doesn't reduce that work, only the syntax-porting work around it. **Tooling cost:** free (built into the Godot 4 editor) — no licensing concern here, unlike commercial translators for other ecosystems. **Biggest weakness:** the time saved is concentrated in the *files that were already going to be quick to port by hand* (small HUD scripts, simple menus); the files that actually need care — `Player.gd`, `Country.gd`, the `StateMachine` family, all of `Source/Server/` — get little benefit from the converter and are exactly where this audit's findings live, so the saved time doesn't line up well with the risk.

### Route D — Greenfield rewrite in Godot 4 / GDScript, audit-guided (recommended candidate)

Rebuild file-by-file in Godot 4, using this audit as the spec: port the domain layer (map, state machines, HUD) deliberately rather than mechanically, fixing cataloged findings as each file is rebuilt; replace the entire `Source/Server/` layer with Godot 4's native high-level multiplayer API (`MultiplayerSynchronizer`, RPC annotations with explicit permission modes) instead of the hand-rolled `net_call` convention — directly designing out F-003 and F-016 at the root, not patching around them. **Effort: 2–4 months** at a sustainable solo/Claude-Code-assisted pace, sliced into small, reviewable increments (per the slice-loop in Phase 9+) — no big-bang cutover required since there's no live-traffic constraint to force one. **Findings handling:** designs out all 3 criticals and all 3 highs by construction (the new replication layer can't reproduce F-003's unrestricted dispatch or F-005's asymmetric sync because it isn't built the same way); most mediums (duplication, fragile string-based coupling) get fixed as a natural side effect of writing each file fresh against the audit's notes instead of copy-pasting the old shape. **Biggest weakness:** highest supervised-effort route that isn't Route B/F — every file needs a human-reviewed slice, and "no hard deadline" can let scope drift if side-quests (new features) sneak in before the port is done (the slice-loop's "side quests come dead last" rule exists specifically for this).

### Route E — Greenfield in Godot 4, GDScript UI/gameplay + C# networking layer

Same as Route D, but the new replication layer is written in C# (Godot 4 has first-class C# support) to get compile-time typing around the RPC surface that F-003 flags as an untyped, string-keyed dispatch risk. **Effort: 3–5 months** (adds a second language's build tooling, testing setup, and GDScript↔C# interop surface on top of Route D's work). **Findings handling:** same as Route D for the domain layer; arguably *more* thoroughly designs out F-003 (a typed C# RPC contract is harder to misuse than a string-keyed GDScript one) but Route D's Godot 4 GDScript RPC annotations already close most of that gap without a second language. **Biggest weakness:** the team has no existing C# code in this repo and no stated C# skill — introducing a second language's tooling for a solo/no-deadline team is effort spent on infrastructure rather than on the findings themselves, for a marginal security improvement over Route D's GDScript-native RPC annotations.

### Route F — Full rewrite outside Godot (e.g., TypeScript/web stack or Unity/C#)

Abandon the Godot engine and asset pipeline entirely; rebuild the game, map, and networking in a different stack. **Effort: 6–12+ months** (re-authoring 42 country hitboxes/art pipeline, rebuilding every menu/HUD control from scratch in a different UI paradigm, and the networking layer, with zero reuse of the current `.tscn` scene data). **Findings handling:** designs out everything, same as Route D/E, but at several times the cost for no additional fidelity or bug-fixing benefit — the catalog's findings are about code structure and networking design, not about anything Godot-specific being wrong. **Biggest weakness:** discards a working, audited-as-basically-sound domain layer and an entire asset pipeline (`Assets/`, 42 country scenes, fonts, audio) for no reason the audit or the constraints actually supply — there's no stated dissatisfaction with Godot itself, only with its version and the networking code.

## Scoreboard

| Constraint | A — Keep & remediate | B — Strangler | C — Auto-convert + cleanup | D — Greenfield Godot 4/GDScript | E — Greenfield + C# net | F — Non-Godot rewrite |
|---|---|---|---|---|---|---|
| Fits "no hard deadline, solo+Claude Code" team | ✔ least effort | ✘ dual-maintenance tax mismatched to team size | ✔ fast | ✔ slice-loop friendly | ~ adds a language to learn | ✘ far beyond team capacity/timeline |
| Designs out the 3 criticals + 3 highs | ✘ F-003/F-016 stay structural | ✔ eventually | ✘ inherits all bugs, incl. criticals | ✔ by construction | ✔ by construction, marginal gain over D | ✔ by construction |
| Matches team's existing skill (GDScript only) | ✔ | ✔ | ✔ | ✔ | ✘ no existing C# in repo | ✘ new stack entirely |
| Preserves Web/HTML5 export | ✔ unchanged | ~ two exports to maintain during transition | ✔ Godot 4 supports HTML5 export | ✔ Godot 4 supports HTML5 export | ✔ same as D | ~ depends entirely on chosen stack |
| Tooling cost | free | free | free (built into Godot 4) | free | free | possibly licensed engine/tools |
| Addresses the engine-EOL forcing function (F-049) | ✘ not at all | ✔ | ✔ | ✔ | ✔ | ✔ (trades one forcing function for a new stack's own) |
| Reuses sound domain-layer work (adjacency data, state machines, art) | ✔ fully | ✔ fully | ✔ fully (mechanically) | ✔ fully (deliberately re-authored) | ✔ fully | ✘ discarded |
| Risk of scope creep / side-quests derailing it | low (small scope) | medium | low | medium (flagged as the route's own weakness) | medium-high | high |

## Recommendation

**Route D — greenfield rewrite in Godot 4 / GDScript, audit-guided**, using this catalog as the spec and Godot 4's native multiplayer API (RPC annotations, `MultiplayerSynchronizer`) to replace `Source/Server/`'s hand-rolled `net_call` convention rather than port it.

The trade-off reasoning, plainly: this codebase's problems aren't spread evenly — they're concentrated in a networking layer that an engine upgrade *has to touch anyway* (Godot 4 removed the exact two APIs `Source/Server/` wraps), while the domain layer (map data, state machines, HUD) checks out as sound. That means the "cheap" route (A) doesn't actually avoid the networking rewrite, it just avoids doing it *well* — and the "thorough" routes beyond D (E, F) spend real effort on infrastructure (a second language, a whole new engine) that neither the findings nor the stated constraints ask for. Route C's free tooling is genuinely worth using *within* Route D for the ~35 files that are simple mechanical ports (menus, HUD scripts) — but it shouldn't be trusted for the files where this audit found the actual bugs, since a mechanical converter preserves behavior, bugs included, by design. Route D is the route whose weakness — supervised, multi-month effort with real discipline needed to keep side-quests out — is one this team explicitly said they can live with (no hard deadline, solo + Claude Code, workflow-fidelity over speed).

**Practical refinement to Route D:** treat Godot's built-in 3→4 converter as a *first-pass tool*, not the plan — run it, then treat every file it touches as still needing the same audit-guided review the rest of the port gets, exactly as this audit's per-file docs already specify what to fix.

Next: `docs/MIGRATION-GODOT4.md` (Phase 8.5) — target architecture, the new networking design, coding/test standards, and the arc/story/slice roadmap mapping every critical/high finding to the arc that designs it out.
