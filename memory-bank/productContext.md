# Product Context

## Why it exists

Open-source Risk-style strategy game by Argos Open Tech (MIT / CC0). Public instance: [conquestgame.online](http://conquestgame.online). Companion server: [Conquest-server](https://github.com/argosopentech/Conquest-server).

## How it should work

1. **Entry** — main menu → same-device or online lobby (host/join/search).
2. **Match** — players own territories on a world map (42 countries, 6 continents).
3. **Turn loop** — Draft → Placement → Attack → Fortify (player state machine).
4. **Territory UI** — Active / Inactive / Selected (country state machine).
5. **Win** — eliminate all opponents.

## UX goals for the rewrite

- Workflow-faithful: same screens, map, rules, and turn flow as the audited game.
- Bugs fixed by construction (especially critical/high networking findings), not reproduced.
- Preserve desktop + HTML5/browser export.
- Offline hotseat playable before any multiplayer code (Arc 05 milestone).

## Fidelity vs. freedom

Small rule deviations only where a fix is cleaner (e.g. draft bonus formula F-019). No wholesale redesign of gameplay while migrating.
