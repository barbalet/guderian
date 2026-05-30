# Guderian Order-Dice Cycles 21-40

Rules reference: Warlord Games Bolt Action reference sheet,
`https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This slice turns the cycle 1-20 inventory into Guderian-facing contracts for the
first playable data migration. DZW still owns the rules. Guderian now assigns
scenario quality, boots sessions into order-dice mode, maps eligibility reasons,
and classifies setup data for order-specific movement.

## Cycle 21-25: Unit Quality Assignment

`GuderianOrderDiceUnitQualityCatalog` assigns repository-level morale quality to
every modeled unit in all 35 battles. The force families now covered are Polish,
French, BEF, Belgian/Dutch, Soviet 1941, Soviet winter, German early-war, German
Eastern Front, late-war German, and late-career generated forces.

The assignment is intentionally scenario-aware: fortified Polish defenders,
French armor, artillery, and command-control assets, Soviet winter reserves,
German armored/engineer formations, and late-war generated forces no longer
collapse into one generic Regular bucket.

## Cycle 26-30: Order Dice Per Side

`GuderianOrderDiceSessionBootstrap` switches field-command and late-career board
sessions to the DZW `Order Dice` ruleset and rebuilds the dice cup. Its report
checks that the player and Guderian sides receive dice matching DZW's eligible
unit predicate, with replay signatures available for deterministic tests.

## Cycle 31-35: Eligibility Mapping

`GuderianOrderDiceEligibilityMapper` translates DZW eligibility strings and
Guderian command-caveat context into UI-facing categories:

- command caveat;
- no drawn die or wrong-side die;
- destroyed, embarked, retained-order, and already-ordered units;
- pinned order-test pressure;
- immobilized or crew-stunned vehicles;
- falling-back and locked close-quarters states.

This gives the later order UI vocabulary that can explain why a unit cannot act
without reimplementing engine rules.

## Cycle 36-40: Scenario Setup Migration

`GuderianOrderDiceSetupMigrationCatalog` classifies terrain, deployment,
objectives, and scripted events into order-dice movement and order-intent
contracts. Roads become Run-friendly, forests/ridges/marshes become
Advance-only pressure, buildings and fortifications get cover/entry semantics,
and objective/event kinds map to Advance, Fire, Run, Ambush, Rally, or Down.

Cycle 40 acceptance means all 35 battles have quality, side-cup, eligibility,
and setup-migration contracts. The visible order panel still begins in cycles
46-75.
