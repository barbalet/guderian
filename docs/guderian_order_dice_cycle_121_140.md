# Guderian Order-Dice Cycles 121-140

Rules reference: Warlord Games Bolt Action reference sheet,
`https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

Cycles 121-140 extend the activation-step migration beyond the 19 direct
field-command battles. The late-career staff, withdrawal, collapse, and
epilogue records now have order-dice tuning rows, and every one of the 35
unified battle entries has an activation-aware scoring row.

## Cycles 121-125: Late-Career Tuning

`GuderianOrderDiceLateCareerTuningCatalog` adds all 16 late-career records with
target turn ranges, target activation bands, command-caveat tuning, movement
tuning, combat tuning, scoring tuning, and AI tuning. These rows keep the
non-field-command caveat visible while still allowing selected-side study play
through the shared board.

## Cycles 126-130: Field-Command Scoring

`GuderianOrderDiceActivationScoringCatalog` adds activation-aware scoring rows
for the 19 field-command battles. Each row keeps the existing VP structure but
adds a fast-activation threshold, over-budget activation threshold, bonus, and
penalty.

## Cycles 131-135: Late-Career Scoring

The same scoring catalog covers all 16 late-career rows and binds each row to
its existing late-career persistence key. This keeps progress records stable
while making the score model aware of activation pacing.

## Cycles 136-140: Visible Acceptance

The battle command panel now shows late-career order-dice tuning and
activation-aware score pacing. The cycle-140 acceptance report requires the
cycle-120 gates, 16 late-career tuning rows, 35 activation scoring rows, and the
visible source identifiers for late-career tuning and score pacing.

Next work moves to cycles 141-160: order-dice save-state migration, debrief
copy updates, and tutorial language for activation-first play.
