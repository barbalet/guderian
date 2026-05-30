# montyBackwardcompatibility

Monty imports Guderian's embedded DZW historical layer for its playable battle host. The `montyBackwardcompatibility` tests pin the public interfaces Monty needs so later Guderian or DZW refactors do not silently break Monty.

Run these tests before changing shared historical battle, launch, board-session, surface, readability, viewport, or autoplay contracts:

- From `guderian/dzw`: `swift test --filter MontyBackwardCompatibilityTests`
- From `guderian`: `swift test --filter MontyBackwardCompatibilityTests`

The DZW suite lives at `dzw/Tests/DerZweiteWeltkriegTests/MontyBackwardCompatibilityTests.swift`. It covers `HistoricalBattleScenario`, `HistoricalBattleLaunch`, `HistoricalBoardSnapshot`, `HistoricalBoardSession`, `HistoricalBoardInteractionResolver`, `HistoricalBoardLayoutResolver`, `HistoricalPlayableBattleView`, `HistoricalPlayableDebriefSummary`, `HistoricalAutoplayContract`, and `HistoricalAutoplayRunController`.

The top-level Guderian smoke test lives at `Tests/GuderianTests/MontyBackwardCompatibilityTests.swift`. It verifies that `GuderianCore` still re-exports the historical interfaces that Monty and MontyTest compile against.

## Order-Dice Handoff

Guderian cycle 181-200 adds the order-dice handoff that Monty should consume rather than reimplement. The stable surfaces are side selection and drawn-die ownership, explicit order-dice board-session commands, snapshot fields for orders/pins/retained orders/Down/Ambush/morale, compact command callbacks, activation-first AI/autoplay hooks, and debrief persistence keys for completion, activation state, order bag, and retained orders.

Keep the DZW rules engine as the rules authority. Monty should treat Guderian's `next-phase-button`, `advancePhase()`, and related phase names as compatibility shims only; new player-facing Monty UI should use order, activation, and turn-end language.

If a Guderian change intentionally breaks one of these tests, update Monty in the same change window or provide a compatibility adapter first. Do not delete the suite just because Guderian no longer calls a specific symbol locally; the tests document an external dependency from Monty back into the shared historical layer.
