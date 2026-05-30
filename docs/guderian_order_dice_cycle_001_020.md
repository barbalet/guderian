# Guderian Order-Dice Cycles 1-20

Rules reference: Warlord Games Bolt Action reference sheet,
`https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This note records the first Guderian-side migration slice after the embedded
`dzw` engine completed its 200-cycle order-dice conversion. The engine remains
the rules authority. Guderian now consumes the new order, pin, morale, retained
order, and snapshot contracts without creating a parallel rules layer.

## Cycle 1-5: Contract Audit

`GuderianOrderDiceAuditCatalog` tracks the visible Guderian surfaces that still
assume global movement, shooting, and assault phases:

- `DZWPlayableBattleViewModel` and its board-session protocol;
- `GuderianTestFirstBattleRunController`;
- `PlayableTestGameRunner`;
- `NativeBoardSession` and `LateCareerNativeBoardSession`;
- `GuderianMacCatalystBattleModel`;
- tutorial and briefing copy that still teaches phases.

Each finding names the source path, the legacy assumption, the disposition, and
the future cycle window that owns the conversion.

## Cycle 6-10: Scenario Impact Map

`GuderianOrderDiceScenarioImpactCatalog` creates one impact row for every
selectable battle:

- 19 field-command battles from `NativeBattleInstanceCatalog`;
- 16 late-career battles from `LateCareerNativeBattleInstanceCatalog`;
- both-side order-dice counts from modeled units;
- unit-quality, pin-pressure, officer-presence, vehicle-class, terrain-category,
  and retained-order expectations.

The map is deliberately high level. It is the acceptance inventory for later
unit-quality assignment, AI conversion, and balance tuning rather than the final
balance pass.

## Cycle 11-15: Compile Shims

`GuderianOrderDiceCompatibilityShim` keeps Guderian compiling against the DZW
order API while old UI/action paths are retired in later cycles. It maps legacy
phase intent to order-dice orders:

- movement intent -> `Advance`;
- shooting intent -> `Fire`;
- assault intent -> `Run`.

It also verifies that DZW exposes the six order values and the snapshot fields
Guderian needs for pins, morale, retained orders, Down, and Ambush.

## Cycle 16-20: Acceptance Gates

`GuderianOrderDiceAcceptanceCatalog` installs retirement gates for stale phase
surfaces. The gates are non-blocking for cycle 20, but they become blocking at
the UI and autoplay conversion windows if identifiers such as phase labels,
next-phase buttons, German-turn buttons, or phase-budget counters remain.

Cycle 20 acceptance means the migration inventory, impact map, shims, and future
failure gates exist. It does not mean the player-facing UI has already been
converted to the order panel; that starts in cycles 46-75.
