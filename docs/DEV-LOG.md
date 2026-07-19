# Dev Log — Conquest Godot 4 Rewrite

> Append-only. One entry per slice; one retro per completed arc. Never edit past entries.

---

## 2026-07-19 — Slice 01-scaffold-01: Tag and scaffold

- **Changed:** Tagged `godot3-original` at the `legacy/` move commit and pushed it. Created a root-level Godot 4 `project.godot` (name, viewport/stretch, full input map, physics/rendering settings) ported from the audited original — no source code copied yet, no autoloads yet.
- **Findings resolved:** none (Arc 01 is pure scaffolding, per the migration spec's findings map).
- **Gate:** smoke ✔ — `Godot --headless --path . -s <one-off SceneTree script>` loads `project.godot`, confirms `config/name == "Conquest"`, exits 0. The originally planned gate (`--quit` with no main scene) does not work — see "Learned" below.
- **Learned:** `Godot --headless --path . --quit` hangs indefinitely (doesn't exit) when the project has no main scene defined — it prints an error but never reaches `--quit`'s exit path. Any slice before Arc 05 (which gives the project its first real main scene) needs a `-s <script>`-based gate instead of bare `--quit`. Amended in `docs/arcs/ARC-01-foundation.md`. Also: hand-typing Godot 4 `InputEventKey.keycode` values from the Godot 3 project's scancodes is error-prone (the two engines use different numeric bases for special keys); resolving them via the engine's own `KEY_*` constants in a one-off setup script is more reliable and was used here.

---

## 2026-07-19 — Slice 01-scaffold-02: Converter first pass

- **Changed:** Ran Godot's built-in `--convert-3to4` against a scratch copy of `legacy/`'s Source/Assets (never touching `legacy/` itself), then copied only the converted `Source/` and `Assets/` directories into the repo root — not the converter's own `project.godot`, which would have overwritten Slice 01-01's hand-authored one.
- **Findings resolved:** none (as expected — this is raw converter output, not a reviewed port).
- **Gate:** smoke ✔ — 219/219 files converted with 0 failures; root project reopens headless (via the `-s <script>` pattern, no main scene yet) with no fatal engine-level error.
- **Learned:** confirmed directly, not just predicted, that the converter preserves behavioral bugs while modernizing syntax — spot-checked `InActiveState.gd` post-conversion and found F-001's shadowed-loop-variable crash still present verbatim, alongside a correctly modernized `super.enter(country)` call. This is exactly the risk [MIGRATION-OPTIONS.md](../MIGRATION-OPTIONS.md) flagged for Route C: useful for the ~35 mechanical files, no substitute for the audit-guided review Arc 02+ still has to do on every file, especially the ones the catalog actually flagged.

---

## 2026-07-19 — Slice 01-gut-03: Install GUT

- **Changed:** Shallow-cloned GUT v9.7.1 (MIT-licensed, Godot-4-targeted) and vendored `addons/gut/` into the repo; enabled it in `project.godot`. Ran `Godot --headless --path . --import` (required before GUT's classes resolve) and committed the resulting `.gd.uid` files and refreshed asset `.import` metadata as a natural side effect.
- **Findings resolved:** none.
- **Gate:** smoke ✔ — `Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` runs cleanly, reports GUT `9.7.1`, and correctly errors only on the not-yet-created `tests/` directory (expected — Slice 01-04's job).
- **Learned:** network fetch (`git clone` of a GitHub repo) works fine in this environment — the open question from the arc plan is resolved. GUT's CLI runner needs an import pass to have happened at least once (`--import`) before its classes are resolvable; that pass is also a free extra confirmation of Slice 01-02's converted assets (all 219 files re-imported cleanly under Godot 4). Confirmed `legacy/`'s own `project.godot` acts as a project boundary — Godot's whole-tree `--import` did not descend into or modify anything under `legacy/`, even though nothing explicitly told it to skip that directory.

---

## 2026-07-19 — Slice 01-gut-04: First smoke test

- **Changed:** Added `tests/unit/test_project_settings.gd` (two trivial `ProjectSettings` assertions) and a root-level `.gutconfig.json` so the CLI runner needs zero flags — `Godot --headless --path . -s addons/gut/gut_cmdln.gd` is now the whole command, which is what Slice 01-05's CI will invoke.
- **Findings resolved:** none.
- **Gate:** smoke ✔ — verified both directions this time: exit 0 with the real suite (2/2 passing), exit 1 with a deliberately-broken scratch assertion (never committed).
- **Learned (two verification mistakes worth flagging for future slices, not GUT bugs):** (1) `-gdir` doesn't recurse by default — needs `-ginclude_subdirs` / `"include_subdirs": true`, or tests placed in subdirectories are silently skipped ("Nothing was run", no error). (2) Checking `$?` after piping Godot's output through `tail` captures `tail`'s exit code, not Godot's — this produced a false "exit 0" for what was actually a failing test run. Redoing the check by redirecting to a file and reading `$?` directly caught the mistake. Both are exactly the kind of thing that would make a CI gate silently useless rather than red — flagged in `docs/arcs/ARC-01-foundation.md` so Slice 01-05 doesn't repeat either one.

---

## 2026-07-19 — Slice 01-gut-05: GitHub Actions CI

- **Changed:** Added `.github/workflows/godot-tests.yml` (pinned Godot 4.7.1, cached download, import-then-test). Added the resulting `gut` check as a `required_status_checks` context on `main`'s branch protection (`strict: true`) — a workflow existing isn't the same as it blocking a merge, so this was necessary, not optional polish.
- **Findings resolved:** none directly; completes the test/CI infrastructure that F-048 flagged as entirely absent in the legacy project.
- **Gate:** verified with three live CI runs on PR #6, checked via `gh run view --json conclusion` (not by reading colored terminal text): pass → fail (deliberately-broken scratch test) → pass (reverted). Confirmed `required_status_checks.contexts` now contains `"gut"` via the branch protection API.
- **Learned:** the exact Godot release asset filename (`Godot_v4.7.1-stable_linux.x86_64.zip`) was confirmed via `gh api repos/godotengine/godot/releases/tags/4.7.1-stable` rather than guessed — worth doing this check before writing any CI download step, since a wrong guess would have cost a full failed-run debug cycle to discover. Also repeated (and this time avoided) the exact `tail`-pipe exit-code mistake documented in Slice 01-gut-04 — worth having written it down, since it would have been easy to make again under a different guise (`gh run watch | tail`).

---

## Arc 01 retro: Foundation (tag `arc-01-complete`)

- **What went as planned:** the story/slice breakdown held up — 5 slices, each independently mergeable, each with its own verified gate. The `legacy/`-freeze decision (made mid-Arc-01 at the user's request, superseding the original nested-`godot4/`-subdirectory plan) turned out to be robust under real operations, not just in theory: two separate whole-tree Godot operations (`--convert-3to4`'s scratch run never touched it by construction; `--import`'s live run against the real repo didn't touch it because of the nested-`project.godot` boundary) both left it untouched.
- **What didn't go as planned:** three of five slices' original gate descriptions turned out to be wrong or incomplete once actually executed — `--quit` hangs with no main scene (01-01), GUT needs an import pass first and `-gdir` doesn't recurse (01-03/01-04), and the arc plan hadn't originally called for making the CI check *required*, only for it to exist (01-05). None of these were planning failures in the "the plan was based on a wrong understanding of the domain" sense the slice-loop worries about — they were all "the plan was based on a wrong assumption about tool behavior, discovered by actually running the tool" — which is exactly what executing a plan (rather than just writing one) is for.
- **What changes for Arc 02:** treat every gate description in an arc plan as a hypothesis to verify, not a fact to assume — this arc's pattern of "plan says X, actual tool behavior is X-with-a-caveat" held for 3 of 5 slices, so Arc 02 (data layer) should expect the same ratio rather than assuming Arc 01 was unusually rocky. Also: keep using structured `gh`/API output (`--json`, `gh api`) instead of parsing colored terminal text or trusting exit codes after a pipe — both verification mistakes this arc made were exactly this class of error.

---

---
