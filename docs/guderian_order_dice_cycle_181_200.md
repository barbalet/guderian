# Guderian Order-Dice Migration Cycles 181-200

Rules reference: Warlord Games Bolt Action reference sheet, https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf

Cycles 181-200 close the Guderian consumer-layer adaptation to DZW's order-dice rules. DZW remains the rules authority; Guderian now publishes the downstream handoff, build matrix, cleanup status, limitations, and final acceptance evidence for Monty and other consumers.

## Cycle 181-185: Monty API Handoff

`GuderianOrderDiceMontyAPIHandoffCatalog` publishes the six Guderian-facing surfaces Monty can consume:

- Side selection and drawn-die ownership.
- Order-dice board session commands.
- Snapshot fields for orders, pins, retained orders, Down, Ambush, morale, and activation state.
- Compact command callbacks and blocked-action feedback.
- AI/autoplay decisions with deterministic seeds and activation safety caps.
- Debrief persistence for completion, activation state, order bag, and retained orders.

## Cycle 186-190: Build Matrix

`GuderianOrderDiceBuildMatrixCatalog` records the final matrix entries:

- Guderian `swift build`.
- Guderian cycle-200 acceptance test.
- Guderian Monty compatibility test.
- DZW `swift build`.
- DZW `swift test`.
- Xcode scheme build when local tooling is available.

The current local pass ran the fast Guderian build and targeted final acceptance test. The remaining matrix entries are documented downstream checks to run before a release tag or Monty integration window.

## Cycle 191-195: Migration Cleanup

`GuderianOrderDiceMigrationCleanupCatalog` quarantines remaining legacy phase symbols:

- Visible `Next Phase` copy is retired from the DZW playable battle surface.
- `next-phase-button` remains as a compatibility identifier.
- `advancePhase()` remains as a compatibility wrapper.
- `maxPhaseAdvances` remains a quarantined test-safety name until downstream automation can rename with a compatibility adapter.
- `NativeBoardPhase` remains DZW compatibility state while order choice drives default behavior.

## Cycle 196-200: Acceptance Closeout

`GuderianOrderDiceMigrationCycle200AcceptanceCatalog` closes the plan by requiring:

- Cycle-180 evidence present.
- Monty API handoff ready.
- Build matrix documented.
- Migration cleanup ready.
- README, PLAN, Monty notes, and this document updated.
- Zero Remaining Cycles recorded in `PLAN.md`.

## Known Limitations

- Compatibility identifiers such as `next-phase-button` remain for downstream UI automation.
- Some legacy safety names, especially `maxPhaseAdvances`, remain until Monty/GuderianTest can move together.
- Full DZW `swift test`, DZW `swift build`, and Xcode scheme verification are documented release checks when not run in the current local pass.

## Zero Remaining Cycles

There are zero remaining Guderian order-dice migration cycles in the 1-200 adaptation plan. Future work should be tracked as normal bugs, UX polish, balance tuning, Monty integration, or release hardening rather than more migration cycles.
