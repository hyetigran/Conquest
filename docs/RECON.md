# Recon — Conquest

> **Path note:** this audit and all per-file analyses in `docs/` were written against the pre-migration repo layout, where the Godot 3 project lived at the repo root (`Source/`, `Assets/`, `Images/`, `project.godot`, etc.). That original project has since been relocated, unmodified, to `legacy/` (e.g. `Source/Gameplay/Player/Player.gd` is now `legacy/Source/Gameplay/Player/Player.gd`) to free the repo root for the Godot 4 rewrite. Every file path cited below and in `docs/ui/`, `docs/gameplay/`, `docs/server/`, `docs/data/`, and `docs/BUGS-MITIGATIONS.md` should be read with a `legacy/` prefix.

## What it is

Conquest is a Risk-like territory-conquest strategy game built in **Godot 3** (GDScript), playable locally (same-device, hotseat) or over multiplayer via a companion server. A player claims countries on a world map, deploys troops, attacks neighboring territories, fortifies borders, and wins by eliminating opponents. The client also embeds its own networking layer (`Source/Server/`) that talks to a separate backend (documented at [Conquest-server](https://github.com/argosopentech/Conquest-server), out of scope for this audit — only the client-side networking code living in this repo is covered). A public instance runs at `conquestgame.online`.

## History & provenance

- Copyright (c) 2021 **Argos Open Tech**; MIT-licensed (also offered under CC0 per README).
- First commit: 2021-05-08 ("Initial commit", Argos Open Tech). Primary development by **Wamiq Ur Rehman** through May 2021 (map, gameplay base, state machine, players/queue).
- Later maintenance (2024, commits by P.J. Finlay / Argos Open Tech) is limited to README/link updates — no source changes in the recent history sampled. The engine (**Godot 3**, last stable ~2022, superseded by Godot 4 since March 2023) is itself aging; the README still instructs installing "Godot 3" specifically, so the project has not been ported to Godot 4.
- 124 commits total. No CI config, no test directory, no CONTRIBUTING doc found.

## Observed behavior

The app was **not run** during this audit (no Godot 3 installed in this environment — confirmed with the user, static/source-only audit). Behavior is inferred from the screenshots in `Images/` (referenced by the README) and from source:

- `MainMenu.png` — title screen, entry point (`Source/Main/Main.tscn` / `Main.gd`).
- `Lobby.png` — multiplayer lobby (host/join/search), backed by `Source/Gameplay/HUD/Lobby.gd`, `LobbySearchInstance.gd`, `HostGameMenu.gd`, `JoinGameMenu.gd`, `JoinCodeMenu.gd`.
- `Deploy.PNG`, `SomePlaced.PNG`, `AllPlaced.PNG` — the draft/placement phase where players deploy starting troops onto owned countries.
- `Attack.PNG`, `Move.PNG` — the attack and fortify/move phases.
- `GameStarted.PNG`, `Settings.PNG`, `QuitGame.PNG` — general session and options UI.

**Center of gravity:** the **player state machine** (`Source/Gameplay/StateMachine/PlayerStates/`: Draft → Placement → Attack → Fortify) drives turn structure, and the **country state machine** (`CountryStates/`: Active/Inactive/Selected) drives per-territory selection. `Game.gd` and `game_play.gd` (an autoload singleton) sit above both, orchestrating whose turn it is and which menu/HUD is visible. Everything else (40 HUD/menu scripts, the 42 country scenes, the two networking backends) hangs off this turn-and-selection core.

## Structure map

Entry point: `Source/Main/Main.tscn` (`run/main_scene` in `project.godot`) → `Main.gd`.
Autoloads (global singletons, always loaded): `GamePlay` (`Source/Gameplay/game_play.gd`), `Server` (`Source/Server/Server.gd`).

`project.godot`'s `_global_script_classes` block is Godot's own manifest of every class registered as a first-class type — used here as the Phase-1 manifest in place of a package.json equivalent. 40 `.gd` files, ~2,850 lines total, plus 72 `.tscn` scenes (43 of which are per-country instances, near-identical by design).

```
Source/
├── Main/              entry point: Main.gd (boots, calls Server.connect_to_server), Menu.gd (extends VMenu)
├── Menu/               generic reusable menu widgets: HMenu.gd, VMenu.gd (keyboard-navigable button lists)
├── Button/             SmartButton (Button.gd) — custom focus/hover button
├── Gameplay/
│   ├── game_play.gd     autoload singleton: current game/session state
│   ├── Game/Game.gd      per-match orchestration
│   ├── Player/Player.gd  a player's owned countries, troop counts, colors
│   ├── PlayersQueue/PlayersQueue.gd   turn order/queue
│   ├── Map/Country/Country.gd + Country.tscn (base template) + Countries/*.tscn (42 instances)
│   ├── StateMachine/
│   │   ├── state_machine.gd          generic FSM base
│   │   ├── PlayerStates/             PlayerState (base), DraftState, PlacementState, AttackState, FortifyState
│   │   └── CountryStates/            CountryState (base), ActiveState, InActiveState, SelectedState
│   └── HUD/              17 scripts: ActivePlayerHUD, AttackingMenu, DeployMenu, GameOverMenu, HostGameMenu,
│                          JoinCodeMenu, JoinGameMenu, Lobby, LobbySearchInstance, MessageInstance, MoveMenu,
│                          OptionsMenu, PlayerActivity, PlayerListInstance, QuitGameMenu, SameDeviceMenu, StartGameMenu
└── Server/              HighLevelServer.gd (Godot high-level multiplayer/NetworkedMultiplayerENet),
                          WebSocketsServer.gd (WebSocket transport), Server.gd (autoload façade choosing a backend)
```

Layering for the audit:
- **UI layer** (Phase 2): `Button/`, `Menu/`, `Main/`, `Gameplay/HUD/` — 22 files.
- **Business logic** (Phase 3): `Gameplay/game_play.gd`, `Game/`, `Player/`, `PlayersQueue/`, `Map/Country/Country.gd`, `StateMachine/**`, `Server/**` — 18 files.
- **Data** (Phase 4): the 42 `Countries/*.tscn` instances + `Country.tscn` base template (map topology/adjacency-by-scene-tree, troop/name fields), plus `project.godot` config (input map, autoloads, window settings).

## Dependencies

| Dependency | Version | Status |
|---|---|---|
| Godot Engine | 3.x (`config_version=4` project format; README pins "Godot 3-stable") | **EOL-adjacent** — Godot 4 released March 2023; Godot 3.x receives only critical fixes. No GDScript typed-syntax, no Godot 4 rendering/networking APIs available to this codebase. |
| `NetworkedMultiplayerENet` (`Source/Server/HighLevelServer.gd`) | Godot 3 built-in (ENet) | Removed/renamed in Godot 4 (→ `ENetMultiplayerPeer`) — a future engine upgrade forces a networking-layer rewrite, not a mechanical port. |
| WebSocket client (`Source/Server/WebSocketsServer.gd`) | Godot 3 built-in `WebSocketClient` | Also reworked in Godot 4 (→ `WebSocketPeer`). |

No package manager, no external GDScript addons detected (no `addons/` directory).

## Free findings

These surfaced during recon, before any per-file reading; each is carried into the Phase 7 catalog with a citation.

1. **Server address switch is source-only, and a stale comment misdescribes how it actually works (corrected after Phase 3 reading — see [Server.md](./server/Server.md)).** `Source/Server/Server.gd:4-6,34,40-41` — the shipped default is actually the **production** server (`SERVER_IP` defaults to `conquest_official_ws_address` = `"conquestgame.online"`); switching to local dev requires flipping a hardcoded (non-exported) `is_local = false` boolean and rebuilding — no environment variable or build flag. The trailing comment on line 4 (`#"conquestgame.online"`) describes an older comment-swapping mechanism that isn't what's actually in effect today, which is itself a minor smell.
2. **Two parallel networking backends; confirmed one is dead code.** `HighLevelServer.gd` (ENet) and `WebSocketsServer.gd` (WebSocket) both implement the same method names via duck-typing, no shared interface. Phase 3 confirmed: `Server.gd`'s `should_use_web_sockets_server` export defaults `true`, so `HighLevelServer.gd` is unreachable in the shipped project — see [Server.md](./server/Server.md).
3. **Engine EOL risk.** Godot 3 is not abandoned but is off the active-development track; the README's explicit pin to "Godot 3-stable" (not "3 or later") suggests the project cannot currently be opened/run in the actively maintained Godot 4 without a porting effort, particularly for the networking layer (see Dependencies).
4. **No automated tests, no CI.** Nothing under a `test/`-style path and no `.github/workflows`. Any regression protection is manual/visual (`Images/` screenshots serve as informal, stale documentation rather than test fixtures).
5. **`Afghanistan.tscn` looks anomalous but isn't (verified, not a bug).** Every other country scene (42 of 43) overrides two texture nodes (`Country`, `Border`) with country-specific art; `Afghanistan.tscn` alone has no such override (1 `ext_resource` vs. 3 in every sibling). Diffing against the base template `Country.tscn` shows *why*: the template's own default placeholder textures already point at `Afghanistan.png` (`Country.tscn:4-5`). So Afghanistan renders correctly by inheriting the base scene's default — but this is a fragile, silent coupling: if the base template's placeholder art is ever swapped (e.g. during an art pass), Afghanistan alone would silently break with no diff appearing in its own file. Flagged as a smell for Phase 4, not a live bug.

## Audit plan

- **Read cover-to-cover:** all 40 `.gd` files (UI, business logic, server) — the codebase is small enough (~2,850 lines) that full reads are tractable, per user's explicit request for a full audit.
- **Skim/template-analyze rather than read individually:** the 42 `Countries/*.tscn` instances — they are machine-generated-looking, near-identical instances of one base template (`Country.tscn`) differing only in name, group/continent tag, polygon collision shape, and two texture `ExtResource` paths. One will be read in full as the representative template; the rest are diffed programmatically for divergence (per finding #5 above) rather than read one-by-one.
- **Skip:** binary/import assets (`Assets/`, `Images/`, `.import` files) beyond confirming they're referenced, not embedded credentials or executable content.
