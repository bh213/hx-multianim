# Targeting Controllers — Unified Controller-Based Targeting

## Goal

Replace ad-hoc targeting logic scattered across screen overrides (`onMouseMove`, `onMouseClick`, `onKey`) with clean, reusable `UIController` implementations that get pushed onto the controller stack. This covers:

- Arrow-to-target (reactor burn → grid hex, card → hex)
- Card selection from hand (exhaust, discard N, return to hand)
- Card drag-to-play (currently in UICardHandHelper)

## Current State (What's Wrong)

FtlCardsScreen handles all targeting by overriding `onMouseMove`/`onMouseClick`/`onKey` with interleaved if/else chains:

- `onMouseMove` (~line 3218): manually checks `reactorModule.isInTargetingMode()`, branches on exhaust vs grid, hardcodes arrow origin offsets, manually forwards mouse to card hand
- `onMouseClick` (~line 3254): manual `consumeJustStarted()` hack, branches on exhaust vs grid, manual hit-testing
- `onScreenEvent` (~line 3327): blanket-suppresses all events during reactor targeting
- `onKey` (~line 3313): manual Escape→cancel check

Adding new targeting modes (e.g. "select 2 cards to discard") means more spaghetti in these overrides.

## Architecture Decision: Use exitResponse

Fill this out please

