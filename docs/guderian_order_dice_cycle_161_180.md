# Guderian Order-Dice Migration Cycles 161-180

Rules reference: Warlord Games Bolt Action reference sheet, https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf

Cycles 161-180 harden the Guderian consumer layer around DZW's order-dice loop. The app still does not duplicate rules. It now records how every unified battle persists turn-end state, produces deterministic replay signatures, reports harness coverage, audits activation pacing, and retires phase-first player copy from the visible battle surface.

## Cycle 161-165: Turn-End Persistence

- Added `GuderianOrderDiceTurnEndPersistenceCatalog` with one row per unified battle.
- Each row binds the completion key, activation-state key, order-bag key, and retained-order key into a four-part turn-end write set.
- Turn-end policy now explicitly preserves legal Ambush/Down retained orders and removes destroyed-unit dice before the next cup rebuild.

## Cycle 166-170: Full Harness And Replay Signatures

- Added `GuderianOrderDiceFullBattleHarnessCatalog` for all 35 unified battles.
- Every row records selected-side activation coverage, automated opposing-side activation coverage, turn-end persistence, debrief coverage, and a deterministic `guderian.orderDice.replay...` signature.
- The report distinguishes the 19 field-command battles and the 16 late-career command-caveat battles without creating separate rules paths.

## Cycle 171-175: Activation Balance Audit

- Added `GuderianOrderDiceBalanceAuditCatalog`.
- Each battle now has a pacing summary tied to target turns, target activations, replay signature, and improvement levers.
- The improvement levers focus on movement pacing, Rally/Down defensive choices, and Ambush/target interaction when a battle resolves too quickly or too quietly.

## Cycle 176-180: Stale Phase-Surface Retirement

- Added `GuderianOrderDicePhaseSurfaceRetirementCatalog` and `GuderianOrderDiceMigrationCycle180AcceptanceCatalog`.
- The visible battle button now says `Next Window` instead of `Next Phase`, while the existing `next-phase-button` identifier remains as a compatibility hook.
- The battle panel exposes stable identifiers for the new cycle block:
  - `order-dice-turn-end-persistence`
  - `order-dice-replay-signature`
  - `order-dice-full-harness-report`
  - `stale-phase-surface-retirement`

## Follow-On

Cycles 181-200 should publish the Monty-facing API handoff, run the build/test matrix, remove or quarantine remaining old-phase shims from default paths, and close the order-dice migration acceptance report.
