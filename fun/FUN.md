# Fun

This directory owns Guderian's explicit "fun" design model. The goal is to make player enjoyment testable, discussable, and optimizable without reducing the game to empty reward loops or distorting its historical subject matter.

Future source code related to measuring, cataloging, simulating, or optimizing fun should live under `fun/` unless it must be integrated into the app or engine. Production code may consume fun metadata later, but the concept, vocabulary, acceptance gates, and analysis tools begin here.

## Source Basis

This document is grounded in Wikipedia's treatment of:

- [Fun](https://en.wikipedia.org/wiki/Fun): pleasure, enjoyment, amusement, time perception, challenge, novelty, learning, and stress-buffering.
- [Play](https://en.wikipedia.org/wiki/Play_(activity)): intrinsically motivated activity that can be relaxed or intensely focused, often separated from ordinary life by rules, time, and space.
- [Game design](https://en.wikipedia.org/wiki/Game_design): the shaping of mechanics, systems, rules, gameplay, and player experience.
- [Flow](https://en.wikipedia.org/wiki/Flow_(psychology)): full absorption, clear goals, immediate feedback, and balance between challenge and skill.
- [Self-determination theory](https://en.wikipedia.org/wiki/Self-determination_theory): autonomy, competence, and relatedness as basic psychological needs.
- [MDA framework](https://en.wikipedia.org/wiki/MDA_framework): mechanics create dynamics, and dynamics create player-facing aesthetics such as challenge, narrative, discovery, expression, and competition.

## Working Definition

For Guderian, fun is:

> The player's voluntary, absorbed, and meaningful enjoyment of difficult historical decisions, produced by readable rules, consequential choices, responsive feedback, learnable systems, and ethically grounded scenario drama.

Fun does not mean making the subject light. Guderian is about resisting, delaying, escaping, or counterattacking Nazi German offensives. Fun here means the player feels agency, mastery, tension, discovery, and narrative payoff while the game remains historically sober.

## Core Principle

Guderian should optimize for "hard pleasure": the satisfaction of understanding a dangerous battlefield, making a tense choice, seeing why it mattered, and wanting to try one more turn or one more scenario.

The game is fun when the player thinks:

- "I understand what is happening."
- "I have several plausible choices."
- "The board responded to my decision."
- "The outcome was fair, even if it hurt."
- "I learned something about this scenario."
- "I can do better next time."

## MDA Translation For Guderian

### Mechanics

Mechanics are the concrete rules and actions:

- Movement, terrain cost, facing, cover, line of sight, shooting, assault, phase advancement, objective scoring, debriefs, saves, tutorials, AI priorities, and scenario events.

### Dynamics

Dynamics are what happens when those mechanics interact:

- A Polish unit retreats toward Bydgoszcz while a German spearhead pressures the Brda crossings.
- A Soviet tank ambush delays a road axis but risks being pinned before withdrawal.
- A port defense trades casualties for evacuation time.
- A player gives up terrain to preserve scoring units.

### Aesthetics

Aesthetics are the player's felt experience:

- Challenge: mastering a battlefield under pressure.
- Narrative: understanding why a battle matters.
- Discovery: reading a new map and finding hidden routes or chokepoints.
- Expression: choosing a defensive style, withdrawal pattern, or counterattack plan.
- Competition: trying to outplay the German AI and improve a score band.
- Sensation: a readable, tactile board with distinct units, terrain, and logs.
- Submission: wanting another turn because the campaign loop is coherent.
- Fellowship: discussing strategies, history, issues, and scenario outcomes with other players.

## Necessary Conditions For Fun

### 1. Voluntary Engagement

The player must feel invited rather than coerced.

Design requirements:

- Tutorials must be dismissible and resettable.
- Historical notes must be available without blocking every action.
- The first playable decision should arrive quickly.
- The player must be able to restart, save, load, and inspect without feeling trapped.

Failure signs:

- Long explanation before meaningful input.
- Mandatory reading that repeats after dismissal.
- Early battle actions that are technically legal but strategically meaningless.

### 2. Clear Goals

The player must know what "good play" means in each scenario.

Design requirements:

- Every battle needs visible primary, secondary, and survival objectives.
- Scoring should explain why the player won, lost, or achieved a partial result.
- Objective labels must be visible in the board, sidebar, briefing, and debrief.
- Scenario-specific victory logic must match the historical fantasy: delay, hold, withdraw, evacuate, counterattack, seal a pocket, or preserve force.

Failure signs:

- The player only learns the real objective after losing.
- The best tactic contradicts the briefing.
- Objectives are named historically but not mechanically actionable.

### 3. Immediate And Useful Feedback

The player must see the effect of actions.

Design requirements:

- Legal actions should produce visible board changes, log entries, score changes, or state changes.
- Blocked actions must explain the rule, phase, target, or terrain reason.
- AI turns must show intent and result, not just silently mutate board state.
- Combat should communicate hit, miss, pin, damage, morale, cover, and consequence.

Failure signs:

- "Nothing happened" after clicking a control.
- The log records events too abstractly to teach the player.
- AI pressure feels arbitrary because priorities are hidden.

### 4. Challenge-Skill Balance

The game should keep players near the flow channel: not bored, not helpless.

Design requirements:

- Tutorial and early battles should teach one new pressure at a time.
- Later battles should combine pressures the player has already learned.
- Difficulty should arise from tradeoffs, timing, terrain, and AI pressure, not opaque rules.
- Every scenario should contain at least one recoverable mistake path.

Failure signs:

- A new player loses before understanding the action vocabulary.
- An experienced player solves a scenario with one obvious tactic.
- The AI wins because of hidden advantages rather than visible pressure.

### 5. Meaningful Autonomy

The player must be able to cause outcomes.

Design requirements:

- Each phase should offer multiple valid actions with different tradeoffs.
- Objectives should be achievable through more than one route or posture.
- "Complete scenario" debug actions must stay out of normal player-facing flow.
- The game should reward player-selected priorities, not just checklist execution.

Failure signs:

- There is only one rational move.
- The game plays itself while the player watches.
- The player cannot tell which outcome came from their decision.

### 6. Competence And Mastery

The player should get better by learning the system.

Design requirements:

- Repeated play should reveal better timing, target selection, withdrawal routes, and objective sequencing.
- Debriefs should identify what the player did well and what can improve.
- Rules should be learnable from consistent feedback.
- Scenario progression should recycle concepts in richer combinations.

Failure signs:

- Losses feel random.
- Victory depends on memorizing hidden scripts.
- The player cannot explain why a better run scored better.

### 7. Novelty And Discovery

Fun often comes from breaking routine and learning new patterns.

Design requirements:

- Every battle needs distinct terrain identity, force mix, objectives, and tempo.
- New battle maps should introduce new tactical questions, not just new labels.
- Late-career caveat battles must still offer fresh play, even when framed as context rather than direct field command.
- Surprise should be readable after the fact, not unfair.

Failure signs:

- Consecutive battles feel like the same board with renamed objectives.
- New units behave indistinguishably.
- The player cannot discover better routes or timings.

### 8. Ethical Historical Framing

Enjoyment must not become celebration of Nazi command.

Design requirements:

- Player fantasy remains resistance, delay, survival, evacuation, counterattack, or containment.
- Guderian's command scope and late-career caveats remain visible.
- Scenario language should avoid glamorizing German offensives.
- German AI can be tactically threatening without becoming aspirational.

Failure signs:

- Player-facing copy admires the attacker.
- Caveats disappear in late-career scenarios.
- The game rewards harm without context or consequence.

### 9. Readable Battlefield State

The player cannot enjoy decisions they cannot parse.

Design requirements:

- Units, terrain, objectives, phase, selected unit, selected target, and pending decisions must be visually distinct.
- Text must not overlap board information.
- Dense maps should support zoom, inspection, and panel separation.
- Board state should be understandable within a few seconds after a phase change.

Failure signs:

- The player must hunt for the active unit.
- Objective markers are hidden under counters.
- Panel state and board state disagree.

### 10. Pacing And Rhythm

Fun needs cadence: tension, action, feedback, release.

Design requirements:

- Each battle should open with a clear threat and a near-term decision.
- Turns should alternate between player planning and visible enemy pressure.
- Long battles need mid-scenario events or changing priorities.
- Debrief should arrive soon after the battle is decided.

Failure signs:

- Too many quiet turns.
- Too many simultaneous crises without hierarchy.
- The scenario ends long after the meaningful result is obvious.

### 11. Fair Consequence

Pain is fun when it is legible and earned.

Design requirements:

- Casualties, failed withdrawals, lost objectives, and pinned units should trace back to visible causes.
- Risky choices should advertise risk before commitment.
- Partial success should matter, especially in delay and evacuation scenarios.
- Failure should suggest a new plan.

Failure signs:

- The game punishes a player for rules not explained.
- A single early mistake invalidates a long scenario.
- Debrief says "loss" but not "why".

### 12. Replayability

The game should invite return.

Design requirements:

- Score bands should encourage improvement.
- Scenario seeds or AI priorities may vary within historically plausible bounds.
- Multiple objectives should make alternate strategies viable.
- Debrief should preserve a memory of the player's specific run.

Failure signs:

- The second playthrough is identical.
- Optimal play is static and obvious.
- Scoring has no granularity.

### 13. Friction Control

Interface friction must not masquerade as difficulty.

Design requirements:

- Click targets must be reliable.
- The player must be able to undo harmless inspection, but not necessarily committed actions.
- Phase controls must be discoverable and named.
- Save/load and restart must preserve confidence.

Failure signs:

- The hard part is selecting a unit, not deciding what to do.
- The player accidentally advances a phase.
- Important buttons are disabled without explanation.

### 14. Relatedness And Community

Even a single-player game can become more fun when it is discussable.

Design requirements:

- Battle outcomes should be easy to summarize.
- Scenario titles, objectives, and score bands should create shared vocabulary.
- README, issues, Discord, and release notes should invite feedback.
- Future fun analytics should support playtest notes and user reports.

Failure signs:

- Players cannot explain what happened.
- Feedback lacks categories.
- The game has no stable language for "this was fun" or "this was frustrating".

## Fun Optimization Conditions

Every gameplay change should be reviewed against these conditions:

1. Does it increase meaningful choice?
2. Does it preserve historical sobriety?
3. Does it improve goal clarity?
4. Does it provide faster or clearer feedback?
5. Does it maintain challenge-skill balance?
6. Does it make the board easier to read?
7. Does it reduce interface friction?
8. Does it create a learnable pattern?
9. Does it add scenario identity or novelty?
10. Does it improve debrief, memory, or replayability?

Changes that improve realism but reduce all ten conditions should be treated as suspect. Changes that improve short-term convenience but reduce consequence, challenge, or historical meaning should also be treated as suspect.

## Fun Metrics

These are candidate metrics for future code under `fun/`.

### Clarity Metrics

- `objective_visibility`: percentage of objectives visible in briefing, board, sidebar, and debrief.
- `blocked_action_explanation_rate`: percentage of blocked actions with player-readable reasons.
- `active_unit_discovery_time`: time or action count required to identify the active unit.
- `phase_state_agreement`: whether board, controls, log, and sidebar report the same phase.

### Agency Metrics

- `legal_choice_count`: number of meaningful legal actions per phase.
- `decision_diversity`: number of distinct viable plans per scenario.
- `player_causality_trace`: whether outcome records link score changes to player actions.
- `recovery_route_count`: number of plausible ways to recover from a mistake.

### Flow Metrics

- `first_decision_time`: time from launch to first meaningful player decision.
- `feedback_latency`: time from action to visible response.
- `challenge_pressure_band`: whether AI pressure stays within intended score/turn range.
- `quiet_turn_ratio`: turns with no material decision or event.

### Mastery Metrics

- `skill_signal_count`: number of mechanics a player can improve at.
- `debrief_learning_points`: number of actionable lessons in the debrief.
- `replay_delta`: expected score improvement between first and later play.
- `rule_consistency_failures`: times similar actions produce unexplained different outcomes.

### Novelty Metrics

- `scenario_identity_score`: distinct terrain, force, objective, and tempo features.
- `new_pattern_count`: new tactical patterns introduced by scenario.
- `surprise_explainability`: whether unexpected events become understandable afterward.
- `map_route_variety`: number of viable routes, chokepoints, or withdrawal lanes.

### Ethical Framing Metrics

- `resistance_fantasy_integrity`: player goals oppose, delay, or contain German operations.
- `command_caveat_visibility`: late-career and indirect-command caveats are visible.
- `non_celebratory_language`: copy avoids heroic framing of Nazi command.
- `historical_context_presence`: scenario notes explain why the event matters.

## Fun Review Checklist

Before shipping a gameplay change:

- The player can state the goal.
- The player has at least two meaningful choices.
- The player gets immediate feedback.
- The player can understand blocked actions.
- The AI pressure is visible and fair.
- The scenario teaches or tests a recognizable skill.
- The battle has a distinct identity.
- The debrief explains the result.
- The interface does not create avoidable friction.
- The historical framing remains sober.

## Proposed Future Source Layout

When implementation begins, keep fun-related analysis code here:

```text
fun/
  FUN.md
  FunModel.swift
  FunMetric.swift
  FunScenarioAudit.swift
  FunTelemetrySchema.swift
  FunOptimizationReport.swift
  fixtures/
    fun-thresholds.json
    scenario-fun-baselines.json
```

Potential responsibilities:

- `FunModel.swift`: definitions for fun dimensions, weights, and acceptance gates.
- `FunMetric.swift`: measurable values and scoring helpers.
- `FunScenarioAudit.swift`: scenario-level checks against the conditions above.
- `FunTelemetrySchema.swift`: optional schema for player/session observations.
- `FunOptimizationReport.swift`: aggregate reports for release readiness.

If SwiftPM should compile these later, `Package.swift` must explicitly include `fun/` as a target or move compiled pieces into `Sources/` while keeping this directory as the conceptual owner.

## Fun Score Model

Avoid a single magic number as the only truth. Use a score as a signal, not a verdict.

Suggested dimensions:

| Dimension | Weight | Meaning |
| --- | ---: | --- |
| Clarity | 15 | Goals, state, controls, and feedback are understandable. |
| Agency | 15 | Player choices meaningfully affect outcomes. |
| Challenge | 15 | Difficulty matches expected player skill and supports flow. |
| Mastery | 15 | Repeated play teaches useful patterns. |
| Novelty | 10 | Scenarios avoid routine and invite discovery. |
| Consequence | 10 | Outcomes are fair, legible, and emotionally meaningful. |
| Pacing | 10 | Turns have rhythm, tension, and release. |
| Ethical Frame | 10 | The game remains historically sober and anti-celebratory. |

An acceptable battle should score at least 75 overall, with no dimension below 60. A battle below 60 in Ethical Frame is a release blocker regardless of total score.

## Guderian-Specific Fun Pillars

### The Board Is The Toy

The board must invite touching: selecting, moving, inspecting, zooming, and understanding. If the player does not enjoy manipulating the board, no amount of historical metadata will save the experience.

### The Enemy Must Feel Intentional

German AI pressure should feel like a plan the player can read and resist. It should not feel like random movement or hidden dice.

### The Best Stories Are Partial Successes

Guderian is often about delay under impossible odds. A good loss with preserved units, delayed crossings, or completed evacuations can be more fun than a binary win.

### History Must Produce Decisions

Historical detail is valuable when it changes what the player does. A bridge, rail hub, river, pocket, port, or evacuation lane should be playable, not decorative.

### Learning Is The Reward

The player should leave a battle with a new tactical idea: where to delay, when to withdraw, what to target, how to preserve force, or how to turn terrain into time.

## Anti-Fun Patterns

Avoid these:

- Hidden rules that decide outcomes.
- Decorative history that never affects play.
- Overlong setup before player agency.
- Disabled controls without explanation.
- Dense board text that competes with counters.
- AI that moves without visible intent.
- Single-solution scenarios.
- Pure attrition without tactical rhythm.
- Victory bands that ignore player style.
- Celebratory framing of German operations.

## Design North Star

When in doubt, optimize for this moment:

> The player sees a dangerous battlefield, understands the immediate threat, chooses a risky but plausible response, watches the board react, learns something, and wants to try the next turn.

That is Guderian's fun.
