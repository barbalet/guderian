# Guderian Order-Dice Migration Cycles 141-160

Rules reference: Warlord Games Bolt Action reference sheet, https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf

Cycles 141-160 move the Guderian consumer layer from activation-aware scoring into the persistence, debrief, and tutorial surfaces that players read after the order-dice loop resolves. The DZW engine remains the rules authority; these rows describe how Guderian stores, explains, and verifies those rules-owned states across all 35 unified battles.

## Cycle 141-145: Save-State Migration

- Added `GuderianOrderDiceSaveStateMigrationCatalog` with one row per unified battle.
- Field-command battles now have explicit order-dice state keys beside the existing `guderian.campaign.<battle>.completion.v1` completion key.
- Late-career battles reuse their existing late-career completion persistence keys while adding versioned order-dice activation state, order bag, and retained-order keys.
- Acceptance requires 35 battle rows, 105 unique order-dice state keys, 35 unique completion keys, and source coverage for 19 field-command plus 16 late-career battles.

## Cycle 146-150: Debrief Copy

- Added `GuderianOrderDiceDebriefCopyCatalog` with activation-first text for every battle.
- Debrief rows now explain score, activation pacing, save/persistence state, and retained order-dice state.
- Late-career rows keep the command caveat visible by stating that the scenario is not a direct field command and remains non-celebratory.

## Cycle 151-155: Tutorial Language

- Updated first-battle button coach copy to teach order-dice activations, order choice, Fire/Advance shooting, Run-order assault, activation windows, and retained order state.
- Updated contextual hints so the old phase model is a compatibility window rather than the primary rules explanation.
- Added `GuderianOrderDiceActivationFirstTutorialCatalog` to check the tutorial copy directly from `GuderianTutorialCatalog`.

## Cycle 156-160: Acceptance

- Added `GuderianOrderDiceMigrationCycle160AcceptanceCatalog`.
- The visible battle command panel now exposes save-state migration and activation-first debrief copy with stable source identifiers:
  - `order-dice-save-state-migration`
  - `activation-first-debrief-copy`
  - `activation-first-tutorial-language`
- The cycle-160 test verifies save rows, debrief rows, tutorial-language rows, and the cycle-140 dependency gate together.

## Follow-On

Cycles 161-180 should harden turn-end persistence, replay signatures, full 35-battle order-dice harness reporting, and stale phase-surface retirement in documentation and UI copy.
