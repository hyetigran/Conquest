# PlayerActivity.gd — Analysis

> Source: `Source/Gameplay/HUD/PlayerActivity.gd` · 23 lines · Layer: UI · Audited: 2026-07-18

## Purpose

A transient toast/notification widget ("Player X attacked Country Y", presumably) that displays an activity message, auto-resizes to fit the text, and self-destructs after 3 seconds.

## Lifecycle

`_ready()` (9–12) — `yield`s on a 3-second timer, then emits `queue_freed` and calls `queue_free()` on itself. This is the entire lifecycle: no way to extend, cancel, or pause the countdown once instanced.

## Surface

- `set_activity(activity)` (14–19) — sets the label text and grows `rect_size`/`rect_min_size` by the resulting size delta (so the container reflows to fit longer messages).
- `get_activity()` (21–22) — trivial getter.

## Findings

- **[Smell] — no way to update an already-displayed activity without producing an unbounded-growth bug.** `set_activity()` (14–19) computes `activity_size_difference` relative to the *current* label size and *adds* it to `rect_size` — if `set_activity()` is ever called more than once on the same instance (e.g. a caller reuses one `PlayerActivity` node for a rapid sequence of updates instead of spawning a new one each time), `rect_size` accumulates every delta rather than being recomputed from scratch, and repeated calls with the same short text would still add zero (fine) but calls that oscillate between a short and long message would leave the box permanently oversized. Whether callers actually call `set_activity` more than once per instance needs confirming in Phase 3 ([Game.md](../gameplay/Game.md)/[Player.md](../gameplay/Player.md)); if each `PlayerActivity` is truly single-use (matching the `queue_free`-after-3s design), this is inert. *Severity guess:* low, pending confirmation.
- **[Smell] — fixed 3-second lifetime with no cancellation path.** (10) If the node is freed by something else (e.g. a scene change during the yield) before the timer fires, `emit_signal("queue_freed")` on a freed/freeing node could error; not confirmed to occur, flagged as a latent risk of the yield-based pattern. *Severity guess:* low.

## Cross-references

None found yet — its instantiation site is in the business-logic layer (Phase 3), to be confirmed.
