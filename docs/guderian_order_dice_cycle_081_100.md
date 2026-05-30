# Guderian Order-Dice Cycles 81-100

Rules reference: Warlord Games Bolt Action reference sheet,
`https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

Cycles 81-100 convert the AI layer from phase-shaped scripts toward order-dice
activations. DZW remains the rules authority; Guderian now chooses units,
orders, target/objective paths, standing-order posture, morale response, and
target reactions from DZW snapshots.

## Cycles 81-85: Opposing-Army AI

`GuderianOrderDiceOpposingAIActivationPlanner` turns the existing
`OpposingForceAIPlan` army-family data into order-dice activation decisions.
It covers all 35 unified battles, including Polish, French, Allied port-defense,
Soviet 1941, Soviet winter, and late-war Soviet/Allied families.

Each decision records:

- drawn side;
- army family and behavior profile;
- chosen unit and order;
- objective or target;
- path summary;
- failed-order-test handling;
- visible reasoning.

## Cycles 86-90: Ambush, Down, Rally

`GuderianOrderDiceStandingOrderPlanner` makes deterministic standing-order
choices. High pin pressure selects Rally, retained Ambush stays held for
opportunity fire, exposed pinned units can go Down, and ready units consume the
die for movement or fire.

## Cycles 91-95: Pins And Morale

`GuderianOrderDicePinsMoraleAIPlanner` scores morale quality, pin thresholds,
officer support, Rally priority, and FUBAR risk. The decision text keeps the
order-test fallback visible so automated play can explain why a unit rallied,
went Down, or risked an activation.

## Cycles 96-100: Target Reactions

`GuderianOrderDiceTargetReactionAIPlanner` chooses between holding, going Down,
or using an Ambush opportunity. The deterministic coverage includes both
human-vs-AI and AI-vs-human directions so either selected side can face the same
reaction vocabulary.

## Acceptance

The cycle-100 acceptance catalog requires cycle-80 readiness plus the opposing
AI, standing-order, pins/morale, and target-reaction planners. The visible battle
view now exposes the opposing AI family, order choice, standing-order reason,
morale risk, and target-reaction summary through stable identifiers.

Next work moves to cycles 101-120: autoplay activation stepping, Poland and
France tuning, and wider pin/morale movement/combat balance.
