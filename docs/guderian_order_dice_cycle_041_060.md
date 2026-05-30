# Guderian Order-Dice Cycles 41-60

Rules reference: Warlord Games Bolt Action reference sheet,
`https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

This slice connects side selection and the first visible battle controls to the
DZW order-dice contracts. DZW still owns the rules; Guderian now binds chosen
historical side to engine die ownership and exposes the order-dice vocabulary
that the compact macOS/Catalyst battle surface needs.

## Cycle 41-45: Historical Side Selection

`GuderianOrderDiceSideOwnershipCatalog` verifies all 35 battles from both side
choices. Choosing the opposing force binds the human to player one; choosing
Guderian's command binds the human to player two. The same report confirms both
sides receive order dice after session bootstrap.

## Cycle 46-50: Order UI Shell

`GuderianOrderDiceCommandPanelPresenter` provides the command-panel state used
by `DZWPlayableBattleView`: drawn side, human-control status, eligible units,
order picker options, order-test messaging, execution summary, and turn-end
status. The visible command panel now includes stable order-dice accessibility
identifiers.

## Cycle 51-55: Unit Inspector

`GuderianOrderDiceInspectorPresenter` turns unit snapshots into order-aware
inspector rows: pins, morale quality, current order, retained order, Down,
Ambush, Rally, officer/order-test summary, and FUBAR summary.

## Cycle 56-60: Movement UI

`GuderianOrderDiceMovementPreviewPresenter` exposes Advance, Run, current-order,
and reverse movement allowances, vehicle pivot budget, terrain movement classes,
and movement rejection text. Native and late-career snapshots now carry the DZW
movement fields needed by the UI without reimplementing movement rules.

Cycle 60 acceptance means side ownership, the first order panel, the order-aware
inspector, and order-specific movement previews are present. Shooting, vehicle
damage, and close-quarters UI conversion remain scheduled for cycles 61-75.
