# MessageInstance.gd — Analysis

> Source: `Source/Gameplay/HUD/MessageInstance.gd` · 6 lines · Layer: UI · Audited: 2026-07-18

## Purpose

A single chat-line row (system message or player message) inside `Lobby`'s chat box. Pure data holder — all population and styling logic lives in the caller ([Lobby.md](./Lobby.md): `write_server_message`, `got_message`).

## Surface

Three `onready` node references only (`color_rect`, `message_label`, `sender_label`); no methods.

## Findings

None — trivial, correctly-scoped file with no logic to audit beyond node wiring.

## Cross-references

Instantiated by [Lobby.md](./Lobby.md).
