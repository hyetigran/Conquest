# Active Context

## Current focus

**Arc 01 — Foundation** (`docs/arcs/ARC-01-foundation.md`). Repo root is cleared for the Godot 4 project; original game lives in `legacy/`.

## Recent changes

- Legacy audit + Route D migration plan landed in `docs/`.
- Godot 3 tree moved to `legacy/` (unmodified).
- Post-migration backlog started (`docs/BACKLOG.md` — Middle Earth map idea).
- Slice workflow tightened: branch + PR required for every slice (no direct `main` commits by implementer).
- Memory Bank + `.cursor/rules/memory-bank.mdc` added.

## Next steps (Arc 01 slices)

1. **01-01** — `git tag godot3-original`; scaffold root `project.godot` (name, 1280×720, input map, empty autoloads). Gate: headless `--quit` exits 0.
2. **01-02** — Run 3→4 converter on a scratch copy of legacy Source/Assets; commit raw output to root (unreviewed first pass).
3. **01-03** — Vendor GUT into `addons/gut/`.
4. **01-04** — Trivial GUT smoke test.
5. **01-05** — GitHub Actions headless GUT workflow (Godot 4.7.1).

## Active decisions

- Godot 4 project at **repo root** (not nested `godot4/`). `legacy/` is the freeze.
- Route D: greenfield audit-guided rewrite; converter is a first pass only.
- Open: GUT acquisition (network clone vs. manual drop-in) for Slice 01-03.

## Do not

- Edit `legacy/` for migration work.
- Mix backlog features into Arc 01–10 slices.
- Port `net_call` / unrestricted `get_node_method_call` into the new stack.
