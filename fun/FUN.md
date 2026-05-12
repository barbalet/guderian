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

Fun does not mean making the subject light. Guderian's default play lens is resisting, delaying, escaping, or counterattacking Nazi German offensives. Field-command battles can also be played from Guderian's command side as sober command study, comparison, and systems learning. Fun here means the player feels agency, mastery, tension, discovery, and narrative payoff while the game remains historically sober.

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
- A player chooses Guderian's command to study operational pressure, while the UI and debrief keep the context non-celebratory.

### Aesthetics

Aesthetics are the player's felt experience:

- Challenge: mastering a battlefield under pressure.
- Narrative: understanding why a battle matters.
- Discovery: reading a new map and finding hidden routes or chokepoints.
- Expression: choosing a defensive style, withdrawal pattern, or counterattack plan.
- Competition: trying to outplay the automated opposing side and improve a score band.
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

- The default player fantasy remains resistance, delay, survival, evacuation, counterattack, or containment.
- If the player selects Guderian's command, the experience must read as command study and comparison, not admiration, conquest fantasy, or moral laundering.
- Guderian's command scope and late-career caveats remain visible.
- Scenario language should avoid glamorizing German offensives.
- German AI and German-side play can be tactically threatening without becoming aspirational.

Failure signs:

- Player-facing copy admires the attacker or treats German command play as heroic.
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

- `selected_side_integrity`: the selected side's goals, controls, feedback, and debrief all match the side the player chose.
- `resistance_fantasy_integrity`: default-side goals oppose, delay, or contain German operations.
- `command_study_caveat`: Guderian command play remains analytical and non-celebratory.
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
  Sources/
    GuderianFun/
      FunModel.swift
      FunMetric.swift
      FunDT.swift
      FunScenarioAudit.swift
      FunTelemetrySchema.swift
      FunOptimizationReport.swift
    GuderianFunReport/
      main.swift
  fixtures/
    fun-thresholds.json
    scenario-fun-baselines.json
```

Potential responsibilities:

- `FunModel.swift`: definitions for fun dimensions, weights, and acceptance gates.
- `FunMetric.swift`: measurable values and scoring helpers.
- `FunDT.swift`: a perpendicular temporal-difference model for how each battle changes novelty, texture, and motif continuity over campaign time.
- `FunScenarioAudit.swift`: scenario-level checks against the conditions above.
- `FunTelemetrySchema.swift`: optional schema for player/session observations.
- `FunOptimizationReport.swift`: aggregate reports for release readiness.
- `GuderianFunReport/main.swift`: command-line report runner. Use `swift run GuderianFunReport --compare` to compare static catalog scoring with live unified scenario harness scoring.

SwiftPM compiles these through `Package.swift` as `GuderianFun` and `GuderianFunReport` while this directory remains the conceptual owner.

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

## funDT Model

`funDT` means fun difference over time. It is not a ninth fun dimension and should not be averaged into the core fun score. It is a perpendicular campaign-shape metric: the player is more likely to stay curious when each battle changes enough of the tactical grammar to feel fresh while preserving enough motif continuity to remain learnable.

The metric reconstructs every battle as a feature vector across eight temporal axes:

| Axis | Meaning |
| --- | --- |
| Chronology | Date, theater, and late-career placement. |
| Command Scope | Direct command, adjacent caveat, staff influence, or post-dismissal context. |
| Player Posture | Delay, defense, withdrawal, counterattack, breakout, evacuation, ambush, or staff-pressure pattern. |
| Terrain System | Roads, rivers, railways, crossings, settlements, fortifications, pressure markers, and ground terrain. |
| Objective System | The verbs and objects of score pressure: hold, withdraw, preserve, evacuate, bridge, port, pocket, command, supply, etc. |
| Pressure System | AI, pacing, artillery, air, pincer, engineer, supply, winter, mine, or blocked-action pressure. |
| Force System | The armies and force textures the player reads. |
| Tempo | Short, medium, or long target-turn cadence. |

`funDT` combines immediate difference from the previous battle, cumulative novelty against earlier battles, rolling difference across the recent campaign window, and motif continuity. High `funDT` means the battle changes the campaign's texture; low `funDT` means it risks feeling like a repeated pattern unless the core fun score compensates with exceptional execution.

## Guderian-Specific Fun Pillars

### The Board Is The Toy

The board must invite touching: selecting, moving, inspecting, zooming, and understanding. If the player does not enjoy manipulating the board, no amount of historical metadata will save the experience.

### The Enemy Must Feel Intentional

Opposing-side AI pressure should feel like a plan the player can read and answer. It should not feel like random movement or hidden dice.

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

## Battle Fun And funDT Appendix

This appendix is generated from `FunBattleSideReportCatalog.generate()`. `Fun` is the side-adjusted weighted score from the catalog audit. `funDT` is the side-specific temporal-difference reconstruction: it asks how much this side's posture, command lens, objectives, pressure, force texture, and continuity change over campaign time. Scores are signals for tuning, not final truth.

### Highest Fun
- 1. Battle of Tuchola Forest / Polish corridor defenders: 96.3 fun; weakest Pacing 93.
- 11. Dunkirk Perimeter Pressure / Dunkirk perimeter forces: 96.3 fun; weakest Pacing 93.
- 19. Moscow Southern Approach / Soviet Tula, Kashira, Belov/Getman reserve, and winter counteroffensive defenders: 96.3 fun; weakest Pacing 93.
- 13. Battle of Bialystok-Minsk / Soviet Western Front detachments: 96.2 fun; weakest Pacing 93.
- 14. Battle of Smolensk / Soviet Smolensk defenders and reserve armies: 96.2 fun; weakest Pacing 93.

### Lowest Fun
- 2. Battle of Wizna / Guderian's command: 89.1 fun; improve make command-study caveats and objectives more visible.
- 2. Battle of Wizna / Polish Wizna defenders: 90.8 fun; improve make first-turn objectives and feedback more explicit.
- 7. Battle of Montcornet / Guderian's command: 92.3 fun; improve tie command-study outcomes to sober tradeoffs and non-celebratory debriefs.
- 3. Battle of Brzesc Litewski / Guderian's command: 92.8 fun; improve make command-study caveats and objectives more visible.
- 4. Battle of Kobryn / Guderian's command: 92.8 fun; improve make command-study caveats and objectives more visible.

### Highest funDT
- 1. Battle of Tuchola Forest / Guderian's command: 86.2 funDT; strongest axes Chronology, Command Scope, Force System.
- 1. Battle of Tuchola Forest / Polish corridor defenders: 86.2 funDT; strongest axes Chronology, Command Scope, Force System.
- 20. Kursk Armored Force Pressure / Soviet Central and Voronezh Front defenders: 70.8 funDT; strongest axes Chronology, Objective System, Force System.
- 20. Kursk Armored Force Pressure / Guderian's command: 70.1 funDT; strongest axes Chronology, Player Posture, Objective System.
- 13. Battle of Bialystok-Minsk / Guderian's command: 62.8 funDT; strongest axes Chronology, Tempo, Objective System.

### Lowest funDT
- 10. Siege of Calais / Calais garrison: 32.8 funDT; add/change score partial success through preservation, delay, escape, or counterattack effects.
- 32. East Pomeranian Offensive / Guderian's command: 33.0 funDT; add/change add mid-battle events or changing priorities before the outcome is obvious.
- 33. Kustrin and Oder Bridgeheads / Guderian's command: 33.0 funDT; add/change add mid-battle events or changing priorities before the outcome is obvious.
- 32. East Pomeranian Offensive / Soviet and Polish coastal clearing forces: 33.2 funDT; add/change add mid-battle events or changing priorities before the outcome is obvious.
- 33. Kustrin and Oder Bridgeheads / Soviet Oder bridgehead forces: 33.3 funDT; add/change add mid-battle events or changing priorities before the outcome is obvious.

### Per Battle / Per Side Data

| # | Battle | Side | Fun | funDT | Weakest | Strongest funDT axes | Improvement focus |
| ---: | --- | --- | ---: | ---: | --- | --- | --- |
| 1 | Battle of Tuchola Forest | Polish corridor defenders | 96.3 | 86.2 | Pacing 93 | Chronology, Command Scope, Force System | add mid-battle events or changing priorities before the outcome is obvious |
| 1 | Battle of Tuchola Forest | Guderian's command | 94.5 | 86.2 | Ethical Frame 88 | Chronology, Command Scope, Force System | strengthen non-celebratory framing and visible command caveats |
| 2 | Battle of Wizna | Polish Wizna defenders | 90.8 | 43.8 | Clarity 86 | Objective System, Tempo, Pressure System | make first-turn objectives and feedback more explicit |
| 2 | Battle of Wizna | Guderian's command | 89.1 | 45.6 | Clarity 86 | Objective System, Tempo, Pressure System | make command-study caveats and objectives more visible |
| 3 | Battle of Brzesc Litewski | Brzesc defense group | 94.5 | 38.7 | Clarity 86 | Objective System, Tempo, Pressure System | make first-turn objectives and feedback more explicit |
| 3 | Battle of Brzesc Litewski | Guderian's command | 92.8 | 45.3 | Clarity 86 | Objective System, Player Posture, Tempo | make command-study caveats and objectives more visible |
| 4 | Battle of Kobryn | Operational Group Polesie | 94.5 | 44.2 | Clarity 86 | Objective System, Tempo, Force System | make first-turn objectives and feedback more explicit |
| 4 | Battle of Kobryn | Guderian's command | 92.8 | 44.4 | Clarity 86 | Objective System, Player Posture, Tempo | make command-study caveats and objectives more visible |
| 5 | Battle of Sedan | French Sedan sector defenders | 95.0 | 54.8 | Clarity 91 | Chronology, Objective System, Force System | make first-turn objectives and feedback more explicit |
| 5 | Battle of Sedan | Guderian's command | 93.2 | 57.1 | Consequence 86 | Chronology, Objective System, Player Posture | tie command-study outcomes to sober tradeoffs and non-celebratory debriefs |
| 6 | Stonne Heights | French Char B1 bis counterattack force | 96.0 | 45.3 | Novelty 92 | Objective System, Tempo, Force System | change terrain use, objective verbs, or force mix versus nearby battles |
| 6 | Stonne Heights | Guderian's command | 94.2 | 49.6 | Ethical Frame 88 | Objective System, Tempo, Player Posture | strengthen non-celebratory framing and visible command caveats |
| 7 | Battle of Montcornet | 4e Division cuirassee | 94.0 | 42.3 | Clarity 90 | Objective System, Tempo, Player Posture | make first-turn objectives and feedback more explicit |
| 7 | Battle of Montcornet | Guderian's command | 92.3 | 47.6 | Consequence 86 | Objective System, Tempo, Force System | tie command-study outcomes to sober tradeoffs and non-celebratory debriefs |
| 8 | Amiens-Abbeville Channel Race | Allied blocking detachments | 95.6 | 39.1 | Consequence 91 | Objective System, Tempo, Force System | score partial success through preservation, delay, escape, or counterattack effects |
| 8 | Amiens-Abbeville Channel Race | Guderian's command | 93.8 | 42.0 | Consequence 86 | Objective System, Player Posture, Tempo | tie command-study outcomes to sober tradeoffs and non-celebratory debriefs |
| 9 | Battle of Boulogne | Boulogne garrison | 95.0 | 37.9 | Clarity 90 | Objective System, Pressure System, Force System | make first-turn objectives and feedback more explicit |
| 9 | Battle of Boulogne | Guderian's command | 93.2 | 41.6 | Consequence 86 | Objective System, Pressure System, Force System | tie command-study outcomes to sober tradeoffs and non-celebratory debriefs |
| 10 | Siege of Calais | Calais garrison | 95.7 | 32.8 | Consequence 91 | Tempo, Objective System, Pressure System | score partial success through preservation, delay, escape, or counterattack effects |
| 10 | Siege of Calais | Guderian's command | 93.9 | 34.6 | Consequence 86 | Tempo, Objective System, Pressure System | tie command-study outcomes to sober tradeoffs and non-celebratory debriefs |
| 11 | Dunkirk Perimeter Pressure | Dunkirk perimeter forces | 96.3 | 40.6 | Pacing 93 | Tempo, Command Scope, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 11 | Dunkirk Perimeter Pressure | Guderian's command | 94.4 | 43.6 | Ethical Frame 88 | Tempo, Command Scope, Objective System | strengthen non-celebratory framing and visible command caveats |
| 12 | Fall Rot Swiss-Border Drive | French late-campaign defenders | 95.7 | 44.3 | Consequence 91 | Tempo, Objective System, Force System | score partial success through preservation, delay, escape, or counterattack effects |
| 12 | Fall Rot Swiss-Border Drive | Guderian's command | 93.9 | 50.1 | Consequence 86 | Tempo, Objective System, Force System | tie command-study outcomes to sober tradeoffs and non-celebratory debriefs |
| 13 | Battle of Bialystok-Minsk | Soviet Western Front detachments | 96.2 | 60.3 | Pacing 93 | Chronology, Objective System, Tempo | add mid-battle events or changing priorities before the outcome is obvious |
| 13 | Battle of Bialystok-Minsk | Guderian's command | 94.4 | 62.8 | Ethical Frame 88 | Chronology, Tempo, Objective System | strengthen non-celebratory framing and visible command caveats |
| 14 | Battle of Smolensk | Soviet Smolensk defenders and reserve armies | 96.2 | 48.6 | Pacing 93 | Objective System, Tempo, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 14 | Battle of Smolensk | Guderian's command | 94.4 | 49.5 | Ethical Frame 88 | Objective System, Tempo, Player Posture | strengthen non-celebratory framing and visible command caveats |
| 15 | Roslavl-Novozybkov Offensive | Bryansk Front counterattack force | 96.2 | 47.8 | Pacing 93 | Objective System, Tempo, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 15 | Roslavl-Novozybkov Offensive | Guderian's command | 94.4 | 51.5 | Ethical Frame 88 | Objective System, Tempo, Player Posture | strengthen non-celebratory framing and visible command caveats |
| 16 | Battle of Kiev | Soviet Southwestern Front | 96.2 | 42.1 | Pacing 93 | Objective System, Tempo, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 16 | Battle of Kiev | Guderian's command | 94.4 | 46.5 | Ethical Frame 88 | Objective System, Tempo, Player Posture | strengthen non-celebratory framing and visible command caveats |
| 17 | Battle of Bryansk | Bryansk Front detachments | 96.2 | 35.0 | Pacing 93 | Objective System, Tempo, Pressure System | add mid-battle events or changing priorities before the outcome is obvious |
| 17 | Battle of Bryansk | Guderian's command | 94.4 | 37.7 | Ethical Frame 88 | Tempo, Objective System, Player Posture | strengthen non-celebratory framing and visible command caveats |
| 18 | Mtsensk Armored Ambush | Katukov's 4th Tank Brigade and 1st Guards Rifle Corps screen | 96.2 | 41.3 | Pacing 93 | Tempo, Force System, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 18 | Mtsensk Armored Ambush | Guderian's command | 94.4 | 43.3 | Ethical Frame 88 | Tempo, Player Posture, Force System | strengthen non-celebratory framing and visible command caveats |
| 19 | Moscow Southern Approach | Soviet Tula, Kashira, Belov/Getman reserve, and winter counteroffensive defenders | 96.3 | 46.2 | Pacing 93 | Tempo, Objective System, Force System | add mid-battle events or changing priorities before the outcome is obvious |
| 19 | Moscow Southern Approach | Guderian's command | 94.5 | 48.7 | Ethical Frame 88 | Tempo, Player Posture, Objective System | strengthen non-celebratory framing and visible command caveats |
| 20 | Kursk Armored Force Pressure | Soviet Central and Voronezh Front defenders | 95.9 | 70.8 | Pacing 87 | Chronology, Objective System, Force System | add mid-battle events or changing priorities before the outcome is obvious |
| 20 | Kursk Armored Force Pressure | Guderian's command | 94.5 | 70.1 | Pacing 87 | Chronology, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 21 | Dnieper Withdrawal and Bridgeheads | Soviet Front crossing detachments | 95.9 | 58.6 | Pacing 87 | Player Posture, Tempo, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 21 | Dnieper Withdrawal and Bridgeheads | Guderian's command | 94.5 | 57.4 | Pacing 87 | Objective System, Tempo, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 22 | Korsun-Cherkassy Pocket | Soviet blocking and cavalry-mechanized groups | 95.9 | 56.6 | Pacing 87 | Player Posture, Objective System, Tempo | add mid-battle events or changing priorities before the outcome is obvious |
| 22 | Korsun-Cherkassy Pocket | Guderian's command | 94.5 | 54.4 | Pacing 87 | Objective System, Tempo, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 23 | Kamenets-Podolsky Pocket | Soviet mobile groups | 95.9 | 48.0 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 23 | Kamenets-Podolsky Pocket | Guderian's command | 94.5 | 45.7 | Pacing 87 | Tempo, Objective System, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 24 | Operation Bagration Withdrawal Crisis | Soviet Front breakthrough groups | 95.9 | 52.0 | Pacing 87 | Force System, Tempo, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 24 | Operation Bagration Withdrawal Crisis | Guderian's command | 94.5 | 50.0 | Pacing 87 | Tempo, Force System, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 25 | Lvov-Sandomierz Breakthrough | Soviet breakthrough and bridgehead forces | 95.5 | 42.9 | Pacing 87 | Tempo, Objective System, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 25 | Lvov-Sandomierz Breakthrough | Guderian's command | 94.2 | 41.7 | Pacing 87 | Tempo, Objective System, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 26 | Narew and Vistula Bridgeheads | Soviet bridgehead defenders and engineers | 95.9 | 35.4 | Pacing 87 | Tempo, Objective System, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 26 | Narew and Vistula Bridgeheads | Guderian's command | 94.5 | 35.0 | Pacing 87 | Tempo, Objective System, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 27 | Warsaw-Area Defensive Arcs | Soviet and Polish-aligned Warsaw approach groups | 95.5 | 35.4 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 27 | Warsaw-Area Defensive Arcs | Guderian's command | 94.2 | 34.9 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 28 | Vistula-Oder Breakthrough | Soviet breakthrough and pursuit forces | 95.5 | 37.4 | Pacing 87 | Tempo, Chronology, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 28 | Vistula-Oder Breakthrough | Guderian's command | 94.2 | 37.1 | Pacing 87 | Tempo, Chronology, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 29 | Poznan Corridor and Encirclement | Soviet assault and bypass groups | 95.5 | 34.9 | Pacing 87 | Tempo, Objective System, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 29 | Poznan Corridor and Encirclement | Guderian's command | 94.2 | 34.3 | Pacing 87 | Tempo, Objective System, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 30 | East Prussia and Elbing Cutoff | Soviet northern-front and coastal cutoff forces | 95.9 | 33.7 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 30 | East Prussia and Elbing Cutoff | Guderian's command | 94.5 | 33.5 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 31 | Operation Solstice at Stargard | Soviet blocking and counterattack groups | 95.9 | 33.9 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 31 | Operation Solstice at Stargard | Guderian's command | 94.5 | 34.1 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 32 | East Pomeranian Offensive | Soviet and Polish coastal clearing forces | 95.5 | 33.2 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 32 | East Pomeranian Offensive | Guderian's command | 94.2 | 33.0 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 33 | Kustrin and Oder Bridgeheads | Soviet Oder bridgehead forces | 95.5 | 33.3 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 33 | Kustrin and Oder Bridgeheads | Guderian's command | 94.2 | 33.0 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 34 | Seelow Heights Epilogue | Soviet assault armies | 95.5 | 37.3 | Pacing 87 | Tempo, Chronology, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 34 | Seelow Heights Epilogue | Guderian's command | 94.2 | 36.4 | Pacing 87 | Tempo, Chronology, Player Posture | add mid-battle events or changing priorities before the outcome is obvious |
| 35 | Berlin and Halbe Epilogue | Soviet, Polish, and Allied-aligned final assault groups | 95.5 | 36.3 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |
| 35 | Berlin and Halbe Epilogue | Guderian's command | 94.2 | 34.7 | Pacing 87 | Tempo, Player Posture, Objective System | add mid-battle events or changing priorities before the outcome is obvious |

### Improvement Themes

- Raise low-fun rows by strengthening their weakest scored dimension first: for this catalog that usually means richer consequence/debrief language, more side-specific agency, or clearer command-study caveats.
- Raise low-funDT rows by changing the temporal grammar rather than merely adding content: alter objective verbs, pressure triggers, force texture, or map-use rhythm compared with the previous three battles.
- Late-career staff-context battles need the most funDT help because many share Soviet pressure, German defensive context, medium tempo, and command-caveat structure. They benefit from sharper asymmetry: mines versus bridgeheads, fortress reduction versus pursuit, urban compression versus operational breakout, supply collapse versus relief attempts.
- Guderian-command rows stay fun when they remain explicit command study. Their safest improvements are better comparative objectives, visible caveat labels, non-celebratory debriefs, and AI/player parity, not heroic copy or conquest rewards.
- Opposing-force rows gain fun when partial success is more granular: preserved units, delayed crossings, denied exits, exhausted supply, and readable counterattack timing should all show up in score channels and debriefs.
