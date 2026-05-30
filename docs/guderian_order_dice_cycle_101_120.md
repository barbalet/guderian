# Guderian Order-Dice Cycles 101-120

Rules reference: Warlord Games Bolt Action reference sheet,
`https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

Cycles 101-120 move the field-command harnesses from phase-sized automation
toward order-dice activation stepping, then add the first balance tuning pass
for Poland, France, and the Eastern Front. DZW still owns the rules; Guderian
now treats each automated step as one selected unit receiving one order.

## Cycles 101-105: Autoplay Harness

`GuderianTestFirstBattleRunController` now records explicit activation counts,
activation budget remaining, and activation progress while preserving the
existing pause, resume, speed, and safety-cap controls. `PlayableTestGameRunner`
uses the same activation vocabulary in battle summaries.

The DZW Swift bridge now lets order-dice movement, shooting, and assault follow
the assigned order rather than re-checking the old phase-only gates.

## Cycles 106-110: Poland Tuning

`GuderianOrderDiceFieldScenarioTuningCatalog` adds tuning rows for Tuchola
Forest, Wizna, Brzesc Litewski, and Kobryn. These rows emphasize order-dice
pacing, pins/Rally/Down, rough terrain, road movement, and early-war armour and
infantry weapon effects.

## Cycles 111-115: France Tuning

The France rows cover Sedan through Fall Rot with specific emphasis on river
crossings, French counterattacks, Char B1 shock, port defense, evacuation
pressure, and air/artillery pinning.

## Cycles 116-120: Eastern Front Tuning

The Eastern Front rows cover Bialystok-Minsk through Moscow/Tula/Kashira with
Soviet counterattacks, pocket breakout, T-34/KV armour, logistics friction,
winter movement, and morale pressure.

## Acceptance

The cycle-120 acceptance report requires cycle-100 readiness, activation-step
autoplay, all 19 field-command tuning rows, and visible source identifiers for
activation counts and theater tuning panels.

Next work moves to cycles 121-140: late-career tuning, scoring/pacing, and save
migration for order-dice battle state.
