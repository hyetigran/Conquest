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
