# Guderian Order-Dice Cycles 61-80

Rules reference: Warlord Games Bolt Action reference sheet,
`https://warlordgames.com/downloads/pdf/bolt_action_reference.pdf`.

Cycles 61-80 finish the first visible battle-surface conversion block and begin
activation-based Guderian-command AI. DZW still owns the rules. Guderian now
surfaces the combat facts already emitted by DZW snapshots so the single-window
board can explain why Fire, Advance, Run, vehicle damage, and close-quarters
actions succeed or fail.

## Cycles 61-65: Shooting UI

`GuderianOrderDiceShootingPresenter` converts selected-unit and selected-target
snapshot facts into a compact shooting panel:

- Fire and Advance shooting choices;
- target Down/Ambush reaction summary;
- to-hit modifier breakdown;
- pin markers added by fire;
- damage and morale summaries;
- battle-log result text.

The visible battle command panel exposes stable identifiers for the shooting
rows so later accessibility and screenshot cycles can lock them down.

## Cycles 66-70: Vehicle UI

DZW unit snapshots now expose current vehicle state that was already present in
the engine: crew shaken, crew stunned, immobilized, wrecked, and movement-blocking
wreck markers. Guderian also consumes armour facing, penetration modifiers,
vehicle damage class/result, smoke traits, and Down transitions caused by
Crew Stunned, Immobilized, or On Fire results.

## Cycles 71-75: Close Quarters UI

`GuderianOrderDiceCloseQuartersPresenter` reframes assault as a Run-order flow.
It reports charge allowance, target reaction, assault round results, loser
destruction, vehicle-specific close-quarters facts, and regroup output.

## Cycles 76-80: Guderian-Command AI

`GuderianOrderDiceGuderianAIActivationPlanner` chooses a Guderian-command unit,
order, objective/target, path, and failed-order-test fallback from the current
snapshot. The visible `Auto Step` runner now routes Guderian-command turns
through that order-dice planner before resolving the action.

## Acceptance

The cycle-80 acceptance catalog requires cycle-60 readiness plus the new
shooting, vehicle, close-quarters, and Guderian-command AI presenters. It also
checks the visible battle view for stable identifiers covering shooting choices,
target reactions, hit modifiers, pin/damage/morale summaries, vehicle damage,
wreck markers, assault resolution, regroup output, and AI order choice.

Next work moves to cycles 81-100: opposing-army order-dice AI, Ambush/Down/Rally
AI choices, pins/morale decision pressure, and target reactions.
