# Guderian Development Plan

Cycle 0 update: README and this plan were created from a review of the root project, the included `dzw` engine directory, and Wikipedia research on Guderian's World War II field-command battles.

Cycle 30 update: cycles 1-30 are complete. The repository now has a root Swift package, a `GuderianCore` campaign/scenario data model, all 19 command-scope scenarios represented as metadata, demo IDs locked to Wizna/Sedan/Moscow-Tula-Kashira, a no-submodule-edit `dzw` proxy loader, a SwiftUI app shell with Metal device detection, and regression tests for catalog and loader behavior.

Cycle 60 update: cycles 31-60 are complete. The app now has campaign progress controls, an expanded briefing workspace, reusable historical map rendering, generated fallback maps for every scenario, custom Wizna/Sedan/Moscow map layouts, German AI posture metadata, Wizna tutorial steps, and Sedan force/setup triggers for river crossing, air pressure, engineers, panzer follow-up, artillery, and French counterattack timing.

Cycle 90 update: cycles 61-90 are complete. Sedan now has explicit score channels, pacing caps, reinforcement timing, and debrief bands; Moscow/Tula has winter road friction, Tula defensive-belt data, Soviet reserve armor, anti-tank guns, mobile winter reserves, German supply/exhaustion pressure, and balance tuning; the app briefing adds score/debrief sections, reinforcement summaries, and a filtered operation log; tests now cover all three demo scenario proxy loads, scoring, AI plans, reinforcements, and event-log categories.

Cycle 120 update: cycles 91-120 are complete. Packaging and demo hardening now include the Xcode macOS project, shared scheme, public-domain icon source ledger, README run guidance, and successful SwiftPM/Xcode build paths; the full-campaign expansion now has a content bundle facade, chronological/standalone campaign progression modes with completion records, reusable Polish 1939 system profiles, and a hand-authored Tuchola Forest data slice covering Brda crossings, Chojnice/Tuchola road hubs, Krojanty cavalry screening, Bydgoszcz withdrawal, German pincer pressure, balance, reinforcements, AI orders, operation-log entries, and regression coverage.

Cycle 150 update: cycles 121-150 are complete. Brzesc Litewski now has fortress/citadel, rail, armored-train, FT-17, fallback-gate, and German isolation data; Kobryn now has rearguard, 60th Reserve Infantry, roadblock, eastern-exit, cohesion-withdrawal, and motorized-fixation data; France 1940 systems now cover river crossings, Char B1 heavy-tank shock, armored raid doctrine, air-pressure timing, road/Channel objectives, and withdrawal rules; Stonne, Montcornet, and Amiens-Abbeville now have hand-authored maps, setup scripts, balance profiles, German AI orders, event-log coverage, proxy-loader notes, and regression tests.

Cycle 180 update: cycles 151-180 are complete. Boulogne now has harbor evacuation, Haute Ville, destroyer support, air pressure, and port demolition data; Calais now has layered perimeter, supply, citadel/docks, costly assault, and Dunkirk-time scoring data; Dunkirk now has explicit Guderian-adjacent command caveats, canal defense, beach evacuation capacity, rear-guard sacrifice, and air-pressure data; Fall Rot now has crossing denial, fortress-town stands, fuel/congestion pressure, Vosges retreat corridors, and Army Group C link-up data; Eastern Front 1941 systems now cover rifle armies, mechanized counterattacks, command posts, pockets, breakout routes, rail junctions, logistics, and winter friction; Bialystok-Minsk now has Bug/Neman crossing pressure, Bialystok/Novogrudok pockets, Minsk road/rail escape, Soviet command preservation, German pincer AI, balance profiles, proxy-loader coverage, and regression tests.

Cycle 210 update: cycles 181-210 are complete. Smolensk now has Dnieper/Dvina crossing delay, Yartsevo escape, reserve counterstroke, German supply-strain, pocket, balance, AI, and proxy-loader data; Roslavl-Novozybkov now has Bryansk Front spoiling-offensive, reconnaissance, supply-column raid, tank-preservation, intelligence-limit, southward-turn, and counterpressure data; Kiev now has northern-pincer pressure, Southwestern Front command evacuation, Dnieper/Desna delay, eastern corridor, pincer link-up, breakout, and pocket-reduction data; Bryansk now has Operation Typhoon surprise-axis, Bryansk/Orel/Tula road protection, 50th/13th/3rd Army pocket survival, rail-command preservation, autumn logistics friction, balance, AI, proxy-loader coverage, and regression tests.

Cycle 240 update: cycles 211-240 are complete. Mtsensk now has Katukov-style armor ambush data with T-34/KV shock, wooded ridge concealment, anti-tank screens, 1st Guards Rifle Corps support, 4th Panzer pressure, preservation scoring, AI adaptation, and proxy-loader coverage; Moscow/Tula/Kashira now extends from the Orel-Mtsensk-Tula road through Tula, Venev, Kashira, Belov/Getman mobile reserves, Mordves drive-back pressure, winter roads, German exhaustion, and counteroffensive timing; every campaign battle now has a historical overlay, AI refinement snapshot, balance audit, full-campaign smoke coverage, and regression tests.

Cycle 250 update: cycles 241-250 are complete. Release polish now includes a versioned campaign save envelope, app-level save/load controls, a full-campaign completion summary, ship-readiness reporting, credits, accessibility audit items, performance budgets, release checklist data, final documentation, and regression coverage for the completed campaign. The full-campaign ship pass now verifies all 19 scenarios as hand-authored, historically annotated, balance-audited, AI-snapshotted, and proxy-loadable without editing `dzw`.

Cycle 260 update: cycles 251-260 are complete. Native playability architecture now defines the boundary between reused `dzw` rules and Guderian-owned scenario instances, records the guarded `HEINZ_GUDERIAN_GAME` engine hooks needed for scenario-defined boards/missions, and adds readiness diagnostics showing every battle has authored inputs but still needs a native scenario-instance loader before it qualifies as playable.

Cycle 270 update: cycles 261-270 are complete. Guderian now has a native battle instance model for all 19 battles, including unit mobility/weapon roles, deployment zones, terrain, objectives, reinforcements, event triggers, AI profiles, victory profiles, and deterministic engine-blueprint conversion. Readiness has advanced from "native instance missing" to "native loader missing": the data payloads exist, but the guarded engine scenario loader is still the next block.

Cycle 280 update: cycles 271-280 are complete. The native scenario loader now consumes each Guderian battle instance, builds custom dzw army-list skirmish entries instead of fixed force presets, creates a playable C-engine skirmish bridge, and deploys engine units from the native blueprint positions. Readiness has advanced from "native loader missing" to "native board hook missing": unit rosters and deployment are no longer force-preset proxies, but dzw still needs the guarded scenario board/mission constructor for terrain, objectives, mission target score, and scripted events.

Cycle 290 update: cycles 281-290 are complete. The guarded `HEINZ_GUDERIAN_GAME` dzw board hook now applies Guderian scenario terrain zones, objective names/positions, and mission target scores to native skirmish games, and `NativeBoardSession` exposes a playable board shell with unit selection, movement, shooting diagnostics, pending-choice resolution, objective/terrain snapshots, phase advancement, and log display. Readiness has advanced from "native board hook missing" to "native board shell ready"; the remaining native demo work is board-flow polish, debrief mission state, scripted events/reinforcements, and scenario AI controls for cycle 300 parity.

Cycle 300 update: cycles 291-300 are complete. `NativeDemoParityRunner` now completes Wizna, Sedan, and Moscow/Tula/Kashira from native board sessions through legal board actions, phase advancement, scenario score awards, debrief summaries, and campaign completion records. The app exposes a native board debrief action for those demo battles, readiness marks the three demo battles as "native playable," and GuderianTest records native demo completions while the rest of the campaign remains at native board-shell readiness.

Cycle 310 update: cycles 301-310 are complete. `NativeBoardDiagnosticsRunner` now upgrades GuderianTest from metadata/native-shell diagnostics to real board diagnostics for every campaign battle: it creates native sessions, validates scenario boards, executes legal movement/shooting/assault probes, advances phases, checks hostile target selection, validates reinforcement entry zones, and flags unwinnable mission/debrief gates.

Cycle 325 update: cycles 311-325 are complete. The native Poland 1939 pack now covers Tuchola Forest, Wizna, Brzesc Litewski, and Kobryn with scenario-specific native unit mobility, terrain/objective coverage, native Polish rule bindings for withdrawal, demolition, bunker defense, fortress/urban fighting, rail support, roadblocks, cavalry screens, anti-tank lanes, obsolete armor, and command friction, plus deterministic native board completions and campaign records.

Cycle 345 update: cycles 326-345 are complete. The native France 1940 pack now covers Sedan, Stonne, Montcornet, Amiens-Abbeville, Boulogne, Calais, Dunkirk, and Fall Rot with scenario-specific native unit mobility, terrain/objective coverage, native French/Allied rule bindings for river crossings, bridgeheads, Char B1 heavy-tank shock, armored raids, air pressure, counterattacks, withdrawal, evacuation, siege supply, port denial, naval support, Channel delay, and fortress fallback, plus deterministic native board completions and campaign records.

Cycle 350 update: cycles 346-350 are complete. The Eastern Front native foundation now covers Bialystok-Minsk, Smolensk, Roslavl-Novozybkov, Kiev, Bryansk, Mtsensk, and Moscow/Tula/Kashira with native rule bindings for pockets, breakout lanes, mechanized counterattacks, command posts, river crossings, logistics friction, southward-turn pressure, pincers, armor ambushes, T-34/KV shock, winter friction, Tula defense, and counteroffensive setup. The remaining Eastern Front pack work is native completion flow and debrief records for the 1941 battles outside the existing Moscow demo path.

Cycle 370 update: cycles 351-370 are complete. The native Eastern Front 1941 pack now covers Bialystok-Minsk, Smolensk, Roslavl-Novozybkov, Kiev, Bryansk, Mtsensk, and Moscow/Tula/Kashira with scenario-specific native unit mobility, terrain/objective coverage, rule bindings for pockets, breakout lanes, mechanized counterattacks, command posts, river crossings, logistics, southward-turn pressure, pincers, armor ambushes, T-34/KV shock, winter friction, Tula defense, and counteroffensive setup, plus deterministic native board completions and campaign records.

Cycle 375 update: cycles 371-375 are complete. The first AI/event pass now covers all 19 battles with native reports that bind deterministic German AI priorities, fallback behavior, scripted triggers, reinforcement timing, pacing rules, scenario-system events, tutorial cues, and victory gates to real native battle instances. This establishes full-campaign AI/event readiness while leaving deeper event execution and scenario AI control tuning for cycles 376-380.

Cycle 380 update: cycles 376-380 are complete. Native AI/event execution now resolves the cycle 375 bindings against live board snapshots for all 19 battles. Guderian AI movement uses scenario-authored objective priorities, and every mapped priority, fallback, reinforcement timing, scripted trigger, scenario rule, pacing rule, tutorial cue, and victory gate resolves to a concrete board objective, unit, deployment zone, mission, or scenario target.

Cycle 390 update: cycles 381-390 are complete. Native balance/UX audits now cover all 19 battles with checks for playable pacing bands, player-agency score coverage, readable unit/objective/terrain density, full battle-flow accessibility identifiers, save/load continuity, and failure/debrief reporting.

Cycle 400 update: cycles 391-400 are complete as an automation gate. All 19 battles create native board sessions, GuderianTest completes the campaign without failed or blocked diagnostics, AI/event execution and balance/UX readiness cover every battle, and the cycle 250 metadata baseline remains green. This did not yet satisfy the accepted hand-playable screen requirement.

Cycle 425 update: cycles 401-425 are complete. Post-ship after-action analysis now covers every battle with notes for player agency, AI pressure, event timing, historical framing, automation coverage, and scenario-specific tuning follow-ups.

Cycle 450 update: cycles 426-450 are complete. Deterministic native campaign soak probes now run three seeded board diagnostics per battle across all 19 battles, producing stable replay signatures with no blocking board findings.

Cycle 451 correction: `derZweiteWeltkrieg` was run and inspected as the product reference. Its accepted playability bar is the full battle screen with terrain, objectives, opposing units, direct unit selection, draggable movement, phase controls, combat actions, pending-choice resolution, and visible logs. Earlier cycle language overstated user playability by treating native automation and completion paths as equivalent to a DZW-style playable app screen.

Cycle 460 update: cycles 451-460 are complete. Tuchola Forest now opens into a DZW-style playable Guderian battle screen instead of the simplified native board panel. The pilot uses the native Tuchola board session, terrain zones, objectives, Polish and German units, selectable/draggable active units, rotation, cover/hull-down toggles, shooting/assault controls, pending-choice resolution, phase advancement, and battle-log feedback. Xcode now includes the playable-screen SwiftUI source, and tests cover direct Tuchola movement/commandability.

Cycle 500 update: cycles 481-500 are complete. The Tuchola Forest DZW-style pilot now supports restart, visible debrief, score/result persistence into campaign progress, failure/debrief error reporting, a screen-parity harness that drives launch, selection, movement, phase flow, attack, blocked-action feedback, German AI, debrief, and persistence, plus a reusable playable-battle surface catalog with acceptance gates and per-battle rollout windows for converting Wizna through Moscow/Tula/Kashira.

Cycle 545 update: cycles 501-545 are complete. The reusable DZW-style playable battle screen now routes battles 2-10, Wizna through Calais, from the battle-selection row into the same commandable board surface as Tuchola Forest. The generalized parity harness runs launch, selection, legal movement, phase flow, attack feedback, intentional blocked-action reporting, German AI movement, debrief, and campaign-progress persistence for all ten routed battles; GuderianTest now records playable-screen parity for those routed battles and surfaced a Boulogne harbor movement issue that was fixed by cycling legal active-unit movement probes around impassable terrain.

Cycle 590 update: cycles 546-590 are complete. The DZW-style playable battle screen now routes the full 19-battle campaign from Tuchola Forest through Moscow/Tula/Kashira. Battles 11-19, Dunkirk through Moscow/Tula/Kashira, use the same selectable, commandable, terrain-backed board, German AI turn runner, blocked-action reporting, debrief persistence, and GuderianTest playable-screen parity reporting as the earlier routed battles. The rollout catalog has no queued battles remaining.

Cycle 595 update: cycles 591-595 are complete. A shared dzw-side Guderian career-scope ledger now separates direct field-command scenarios from command-caveat scenarios and late-career staff/epilogue context. The current 19-battle campaign remains intact, Dunkirk is explicitly tagged as adjacent campaign pressure, Moscow/Tula/Kashira keeps an end-date caveat, and 15 future withdrawal/final-war battlefield candidates are cataloged as Inspector General, Army General Staff, or post-dismissal context rather than direct Guderian battle commands.

Cycle 600 update: cycles 596-600 are complete. Every current campaign battlefield now has a shared map-detail audit with counted total features, water, roads, railways, crossings, settlements, ground terrain, fortifications, objectives, deployment zones, pressure markers, annotations, line/marker balance, and coordinate-point density. Each battle has a locked four-times-current detail target and a required-additional-feature count, so cycles 601-625 can enrich maps against explicit per-battle gaps instead of subjective "more detail" notes.

Cycle 605 update: cycles 601-605 are complete. The shared Guderian map schema now has explicit geography kinds for canals, lakes, marshes, railways, fords, ferries, villages, urban districts, and phase lines, plus source-note metadata on maps, map elements, and deployment zones. Rendering, native battle conversion, native board terrain classification, readiness checks, and map-detail audits understand the expanded kinds while keeping existing battle data compatible.

Cycle 610 update: cycles 606-610 are complete. `ScenarioMapGeographyPipelineCatalog` now creates a repeatable geography cross-check record for every current battle, with modern map visual-guide links, scenario-source references, feature anchors inferred from existing map-feature intent, hand-authored abstract-coordinate workflow steps, and map-level source notes appended to the current layouts. The pipeline keeps modern geography as visual guidance while making future 400% map enrichment reviewable through source notes and audit reruns.

Cycle 615 update: cycles 611-615 are complete. The Poland 1939 battle maps now hit the cycle-600 four-times feature baseline for Tuchola Forest, Wizna, Brzesc Litewski, and Kobryn. Each map has denser hand-authored geography for rivers, marshes, roads, railways, crossings, named villages or districts, fallback routes, and phase lines while preserving the existing playable objective anchors and deployment flow.

Cycle 620 update: cycles 616-620 are complete. The France 1940 battle maps now hit the cycle-600 four-times feature baseline for Sedan, Stonne, Montcornet, Amiens-Abbeville, Boulogne, Calais, Dunkirk, and Fall Rot. The shared dzw layouts now include denser Meuse, Somme, Channel coast, harbor, canal, fortress, road, rail, crossing, urban, ridge, marsh, evacuation, and phase-line geography while preserving the native playable objective anchors used by Guderian and GuderianTest.

Cycle 625 update: cycles 621-625 are complete. The 1941 Eastern Front battle maps now hit the cycle-600 four-times feature baseline for Bialystok-Minsk, Smolensk, Roslavl-Novozybkov, Kiev, Bryansk, Mtsensk, and Moscow/Tula/Kashira. The shared dzw layouts now include denser river systems, rail corridors, road nets, pocket exits, forest belts, settlement districts, ambush terrain, winter lanes, crossings, marshes, and phase lines while preserving native playable objective anchors.

Cycle 630 update: cycles 626-630 are complete. Late-career set A now has shared dzw staff-context battlefield data for Kursk armored-force pressure, Dnieper withdrawal and bridgeheads, Korsun-Cherkassy, and Kamenets-Podolsky. These are not added as direct Guderian field-command campaign IDs; each links to the career-scope ledger as Inspector General influence, carries an explicit command caveat, and includes map geography, objectives, forces, and rules for future playable integration.

Cycle 635 update: cycles 631-635 are complete. Late-career set B now adds Operation Bagration withdrawal, Lvov-Sandomierz, Narew/Vistula bridgeheads, and the missing Warsaw-area defensive arcs as shared dzw General Staff context battlefields. Each record has detailed water/road/rail/crossing/settlement/terrain maps, objectives for the anti-Guderian player, German pressure objectives, rules, forces, source links, and a visible command caveat.

Cycle 640 update: cycles 636-640 are complete. Late-career set C now adds Vistula-Oder, Poznan corridor and encirclement, East Prussia/Elbing cutoff, and Kustrin/Oder bridgeheads as General Staff context battlefields. The maps emphasize fortress cities, bridgeheads, lagoon/coastal exits, Oder/Warta/Vistula crossings, withdrawal roads, and rail corridors without adding these as direct field-command campaign IDs.

Cycle 645 update: cycles 641-645 are complete. Late-career set D now adds Operation Solstice, East Pomeranian offensive, Seelow Heights epilogue, and Berlin/Halbe epilogue. Seelow and Berlin/Halbe are explicitly post-dismissal context, and every set-D battlefield exposes a visible "not a Guderian field command" caveat label for future UI surfacing and regression tests.

Cycle 650 update: cycles 646-650 are complete. `LateCareerStaffBattlefieldAcceptanceCatalog` now verifies that the current 19-battle campaign remains routed to the DZW-style playable screen, current enriched maps satisfy the acceptance detail categories, all 16 late-career battlefield records match the career ledger, every new battlefield is command-caveated, and the post-dismissal epilogues remain separated from General Staff context.

## Planning Rules

- Treat `dzw` as read-only unless a change is explicitly guarded with `HEINZ_GUDERIAN_GAME`.
- Keep rules authority in the C engine and let SwiftUI/Metal handle presentation, interaction, and rendering.
- Build historical scenarios as data first: battle metadata, maps, objectives, forces, reinforcements, weather, supply, and victory conditions.
- The player always opposes Guderian's command.
- Use Wikipedia as the initial source shelf, then add stronger specialist sources later where design detail requires it.
- Every playable battle needs a historical note, source links, scenario objectives, force roster, balance pass, and regression coverage.

## Current Engine Baseline

The included `dzw` engine already supports the spine needed by this project: nation rosters, objective missions, turn phases, movement, shooting, artillery, vehicles, transports, mounted fire arcs, smoke, hull-down, morale, assault, scoring, SwiftUI snapshots, and test coverage. Guderian development should therefore start as a campaign/scenario layer before touching core rules.

## Demo Scope

The first 100 cycles target a playable demo with:

- A Guderian-branded macOS app shell.
- Historical campaign selection and briefing screens.
- Tutorial scenario: Wizna fortified delay.
- Famous Western Front scenario: Sedan / Meuse crossing.
- Famous Eastern Front scenario: Moscow southern approach, focused on Tula/Kashira.
- Opposing-force player role, basic AI for Guderian's formations, and deterministic scenario tests.

## Full Campaign Scope

Cycles 101-250 expand the demo into all command-scope battles:

- Tuchola Forest
- Wizna
- Brzesc Litewski
- Kobryn
- Sedan
- Stonne / Sedan bridgehead flank
- Montcornet
- Amiens-Abbeville / Channel coast race
- Boulogne
- Calais
- Dunkirk perimeter pressure
- Fall Rot / Swiss-border drive
- Bialystok-Minsk
- Smolensk
- Roslavl-Novozybkov
- Kiev
- Bryansk
- Mtsensk
- Moscow / Tula / Kashira

## Cycles 1-100: Playable Demo

| Cycles | Focus | Output |
| --- | --- | --- |
| 1-5 | Repository and engine lock | Confirm `dzw` integration path, document read-only boundary, identify Guderian app target needs. |
| 6-10 | Historical data lock | Freeze the first battle ledger, source links, campaign inclusion rules, and demo battle choices. |
| 11-15 | App bootstrap | Create the Guderian macOS target/project wiring around SwiftUI, Metal-ready rendering, and C bridge access. |
| 16-20 | Product identity | Add app name, bundle identifiers, launch copy, icon source plan, and non-celebratory historical tone rules. |
| 21-25 | Scenario data model | Define battle IDs, dates, maps, terrain tags, force slots, weather, supply, objectives, and source-note fields. |
| 26-30 | Scenario loader | Load one scenario from data into existing `dzw` mission/objective/force structures with guarded hooks if needed. |
| 31-35 | Campaign shell | Add scenario picker, briefing panel, source notes, and opposing-force framing. |
| 36-40 | Map presentation | Build reusable historical map layout with roads, rivers, towns, fortifications, objectives, and deployment zones. |
| 41-45 | AI posture layer | Add scenario-specific German attack plans using `dzw` movement/shooting/assault commands. |
| 46-50 | Wizna tutorial | Implement bunkers, fortified line objectives, Polish defenders, German pressure, delay scoring, and tutorial flow. |
| 51-55 | Sedan map | Implement Meuse river, bridge sites, Sedan approaches, artillery positions, air-pressure events, and bridgehead goals. |
| 56-60 | Sedan forces | Add French defenders, German panzer/motorized assault groups, artillery, engineers, and counterattack triggers. |
| 61-65 | Sedan balance | Tune victory conditions around delay, bridge denial, counterattack damage, and survivable early-game pacing. |
| 66-70 | Moscow/Tula map | Implement winter terrain, roads, Tula defensive belt, Kashira approach, supply friction, and frozen movement modifiers. |
| 71-75 | Moscow/Tula forces | Add Soviet defenders, armor counterattack assets, German panzer spearheads, attrition, reinforcements, and morale checks. |
| 76-80 | Moscow/Tula balance | Tune German exhaustion, Soviet timing, city defense, counterattack scoring, and historical outcome pressure. |
| 81-85 | UI polish | Add campaign progress, scenario result summaries, battle log filtering, accessible controls, and briefing/debrief screens. |
| 86-90 | Tests | Add deterministic tests for scenario loading, objectives, AI plans, reinforcements, scoring, and three demo scenarios. |
| 91-95 | Packaging | Add app icon pipeline, credits/source ledger, README run guidance, and demo release checklist. |
| 96-100 | Demo hardening | Run build/test passes, fix scenario bugs, tune UX, and tag the playable demo milestone. |

Status through cycle 30: completed. No `dzw` files were modified; the first loadable scenario uses inherited `dzw` force presets as temporary proxies until Polish, French, and fuller Soviet/German scenario data are added.

Status through cycle 60: completed. No `dzw` files were modified; cycles 31-60 are implemented as Guderian-owned Swift/Core metadata and UI surfaces, with proxy loading still isolated behind `DZWScenarioLoader`.

Status through cycle 90: completed. No `dzw` files were modified; cycles 61-90 remain data/UI/test work in the root package, with the inherited engine still used only through the proxy loader.

Status through cycle 100: completed. The Xcode macOS project, shared scheme, app icon asset catalog, public-domain portrait source ledger, and README run guidance are in place; demo build/test checks pass through SwiftPM and Xcode without editing `dzw`.

## Cycles 101-250: Complete Campaign

| Cycles | Focus | Output |
| --- | --- | --- |
| 101-105 | Data split | Move Guderian scenario data into maintainable tables/files separate from inherited `dzw` fixtures. |
| 106-110 | Campaign progression | Add chronological campaign flow, unlock states, completed battle records, and replayable standalone scenarios. |
| 111-115 | Polish campaign systems | Add Polish early-war rosters, bunker/fortress assets, armored trains, old tanks, cavalry, and withdrawal objectives. |
| 116-120 | Tuchola Forest | Implement forest/corridor breakthrough map, Polish delay objectives, road chokepoints, and German mechanized pressure. |
| 121-125 | Brzesc Litewski | Implement fortress/urban battle with armored trains, FT-17 assets, fallback routes, and German encirclement pressure. |
| 126-130 | Kobryn | Implement inconclusive rearguard battle with evacuation scoring, town defense, and force-preservation goals. |
| 131-135 | France campaign systems | Add French 1940 roster depth, Char B1 bis behavior, river-crossing pressure, air attack events, and port evacuation logic. |
| 136-140 | Stonne | Implement village/heights battle with heavy-tank shock, contested objectives, and German bridgehead-risk scoring. |
| 141-145 | Montcornet | Implement de Gaulle counterattack scenario with armored raid goals, limited support, and timed withdrawal scoring. |
| 146-150 | Amiens-Abbeville | Implement mobile bridge/road defense interlude where the player buys time against the Channel coast dash. |
| 151-155 | Boulogne | Implement port defense, evacuation points, naval support abstractions, demolitions, and German urban assault plan. |
| 156-160 | Calais | Implement siege battle with time-based strategic victory, layered defenses, supply pressure, and costly German attacks. |
| 161-165 | Dunkirk pressure | Implement evacuation-perimeter scenario with careful caveat about Guderian's direct command scope. |
| 166-170 | Fall Rot | Implement late-France drive missions around Aisne, Marne-Rhine Canal, Langres, Belfort, and Epinal as linked operations. |
| 171-175 | Eastern Front systems | Add Soviet 1941 rosters, T-34/KV armor, rasputitsa/winter modifiers, pocket breakout scoring, and logistics friction. |
| 176-180 | Bialystok-Minsk | Implement encirclement-survival campaign with Soviet breakout paths, command preservation, and German pincer AI. |
| 181-185 | Smolensk phase 1 | Implement Dnieper crossing and Smolensk pocket setup with river lines, reserves, and escape-lane objectives. |
| 186-190 | Smolensk phase 2 | Add Soviet counteroffensive variants, German supply strain, and delay-based strategic scoring. |
| 191-195 | Roslavl-Novozybkov | Implement Soviet spoiling offensive against Guderian's southward turn with tank attrition and intelligence limits. |
| 196-200 | Kiev phase 1 | Implement northern pincer pressure, Soviet Southwestern Front defense, and command evacuation priorities. |
| 201-205 | Kiev phase 2 | Add pocket closure, breakout operations, German/Soviet reinforcement timing, and campaign consequence scoring. |
| 206-210 | Bryansk | Implement Operation Typhoon southern approach with encirclement pockets, Tula road protection, and delay scoring. |
| 211-215 | Mtsensk | Implement Katukov-style armor ambush scenario with T-34/KV surprise, terrain cover, and German tank-loss goals. |
| 216-220 | Moscow expansion | Extend demo Tula/Kashira into full Moscow southern-pincer chain with winter counteroffensive variants. |
| 221-225 | Historical overlays | Add per-battle source notes, maps, commander context, outcome summaries, and scenario-specific historical caveats. |
| 226-230 | AI refinement | Add per-battle German plans, fallback behaviors, target priorities, difficulty tiers, and deterministic AI snapshots. |
| 231-235 | Balance pass | Tune every battle for player agency, historical pressure, multiple victory grades, and avoiding unwinnable-feeling starts. |
| 236-240 | Regression suite | Add full-campaign scenario loading tests, snapshot tests, scoring tests, AI-turn tests, and smoke tests for every battle. |
| 241-245 | Release polish | Finalize icon, credits, accessibility, performance, save/load, campaign completion screen, and documentation. |
| 246-250 | Full campaign ship | Run full build/test/review cycle, fix release blockers, tag complete campaign milestone, and update README/PLAN status. |

Status through cycle 120: completed. Scenario data remains Guderian-owned and separate from inherited `dzw` fixtures through `ScenarioContentCatalog`; chronological and standalone progression paths are available; Polish campaign system profiles now cover Tuchola Forest, Wizna, Brzesc Litewski, and Kobryn; Tuchola Forest is the first hand-authored full-campaign scenario beyond the demo set and is loadable through the existing proxy adapter while waiting for a native Polish C roster.

Status through cycle 150: completed. The Poland 1939 expansion now includes Brzesc Litewski and Kobryn as hand-authored, proxy-loadable scenarios; the France 1940 expansion has reusable campaign-system profiles for Sedan, Stonne, Montcornet, and Amiens-Abbeville; Stonne, Montcornet, and Amiens-Abbeville are now the first non-demo France scenarios with dedicated map/setup/balance/AI data. No `dzw` files were modified.

Status through cycle 180: completed. The Channel-port and Fall Rot block is implemented as Guderian-owned content; Eastern Front systems are in place for the 1941 scenarios; Bialystok-Minsk is the first hand-authored Eastern Front full-campaign scenario beyond the Moscow/Tula demo. All new scenarios remain proxy-loadable through `DZWScenarioLoader`, and no `dzw` files were modified.

Status through cycle 210: completed. The mid-1941 Eastern Front block now covers Smolensk, Roslavl-Novozybkov, Kiev, and Bryansk as Guderian-owned data with maps, setup scripts, AI plans, balance profiles, event logs, system profiles, source-backed campaign metadata, and proxy loader support. All scenarios in cycles 181-210 remain outside `dzw`; the inherited engine is still used only through `DZWScenarioLoader`.

Status through cycle 240: completed. The final 1941 scope block now covers Mtsensk and the expanded Moscow southern-pincer chain as Guderian-owned data with maps, setup scripts, Eastern Front system profiles, German AI plans, balance profiles, historical overlays, balance audits, event logs, and regression coverage. All 19 campaign scenarios are now hand-authored, proxy-loadable slices with smoke-tested game creation; no `dzw` files were modified.

Status through cycle 250: completed. The complete campaign milestone is reached. Save/load, credits, accessibility, performance, completion summary, release checklist, ship-readiness report, final docs, SwiftPM tests, SwiftPM build, and Xcode project build are part of the release gate; no `dzw` files were modified.

## Native Playability Gap

Cycle 250 completed the historical campaign shell: every scenario is hand-authored, annotated, balance-audited, AI-snapshotted, and proxy-loadable through the inherited `dzw` demo rules. It did not yet make Guderian a full playable battlefield game at the same level as DerZweiteWeltkrieg; cycles 251-400 close that native playability gap.

The native Guderian playability milestone means each campaign battle must launch into an interactive board with scenario-specific units, deployment zones, terrain, objectives, victory logic, reinforcements, event triggers, AI behavior, battle logs, and debriefs. `DZWScenarioLoader` remains useful as a rules bridge, while native Guderian scenario instances now provide the campaign-specific battlefields and automation gates.

## Cycles 251-400: Native Playable Guderian

| Cycles | Focus | Output |
| --- | --- | --- |
| 251-260 | Playability architecture | Decide the boundary between reused dzw engine rules and Guderian-specific scenario instancing; define guarded `HEINZ_GUDERIAN_GAME` hooks only where the C engine needs scenario-defined boards, rosters, or missions. |
| 261-270 | Battle instance model | Add Guderian-owned playable unit, weapon, transport, terrain, objective, deployment, event, and reinforcement data models that can be converted into engine-ready battle instances. |
| 271-280 | Engine scenario loader | Replace force-preset proxy loading with a native loader that creates a dzw game from Guderian scenario data: map zones, objectives, unit rosters, starting positions, mission score, and scripted triggers. |
| 281-290 | Board shell | Build a Guderian board view equivalent to DerZweiteWeltkrieg's playable board: unit selection, movement, range/target inspection, objective control, phase controls, action errors, pending choices, and log display. |
| 291-300 | Demo parity battles | Make Wizna, Sedan, and Moscow/Tula/Kashira playable from campaign row to board, through turns, scoring, debrief, and completion records without using generic proxy maps or generic proxy forces. |
| 301-310 | GuderianTest upgrade | Move `GuderianTest` from metadata/proxy diagnostics to real board diagnostics: launch every battle instance, execute legal board actions, flag blocked phases, invalid targets, impossible reinforcements, and unwinnable gates. |
| 311-325 | Poland native pack | Implement native Polish 1939 units, terrain, objectives, and battlefields for Tuchola Forest, Wizna, Brzesc Litewski, and Kobryn, including withdrawal and fortress/urban rules. |
| 326-345 | France native pack | Implement native France 1940 units and battlefields for Sedan, Stonne, Montcornet, Amiens-Abbeville, Boulogne, Calais, Dunkirk, and Fall Rot, including river crossings, heavy tanks, evacuation, siege, and air-pressure systems. |
| 346-370 | Eastern Front native pack | Implement native 1941 Soviet/German units and battlefields for Bialystok-Minsk, Smolensk, Roslavl-Novozybkov, Kiev, Bryansk, Mtsensk, and Moscow/Tula/Kashira, including pockets, breakout lanes, T-34/KV shock, logistics, and winter friction. |
| 371-380 | AI and event pass | Add battle-specific German AI priorities, fallback behavior, reinforcement timing, event triggers, and deterministic AI snapshots that operate on real board state rather than metadata. |
| 381-390 | Balance and UX pass | Tune every battle for playable pacing, agency, victory bands, readable unit density, accessible controls, save/load continuity, and clear failure/debrief reporting. |
| 391-400 | Native campaign ship | Run full SwiftPM/Xcode builds, full GuderianTest campaign automation, manual smoke passes, docs updates, and release-blocker fixes; tag the milestone where all 19 battles are playable as real Guderian battlefields. |

Native playable demo target: cycle 300. At that point the three demo battles should be playable like DerZweiteWeltkrieg, but the rest of the campaign may still be in conversion.

Native full-campaign automation target: cycle 400. At that point all 19 campaign battles should launch into native Guderian board sessions with scenario-specific units, terrain, actions, AI pressure, scoring, and debrief diagnostics. Status: achieved for automation, reopened for accepted hand-playable screen parity.

## Cycles 401-450: Post-Ship Automation Hardening

| Cycles | Focus | Output |
| --- | --- | --- |
| 401-425 | After-action analysis | Add per-battle post-ship analysis for player agency, AI pressure, event timing, historical framing, automation coverage, and scenario-specific tuning follow-ups. |
| 426-450 | Deterministic soak | Run seeded native board diagnostics across the full campaign, record replay signatures, and flag unstable actions, blocked phases, impossible reinforcements, or unwinnable gates. |

Status through cycle 260: completed. The native playability boundary is now represented in code and tests; `GuderianTest` surfaces a native-playability warning for each battle while it still runs the inherited proxy loader. No `dzw` files were modified. The next implementation block is cycles 261-270: Guderian-owned playable battle instance models.

Status through cycle 270: completed. Every campaign battle converts from the authored scenario bundle into a native Guderian battle instance and an engine-ready blueprint with scenario-specific units, terrain, objectives, events, AI, and victory data. No `dzw` files were modified. The next implementation block is cycles 271-280: the guarded scenario-defined game creation hook that consumes these blueprints instead of proxy force presets.

Status through cycle 280: completed. `NativeScenarioLoader` is now the primary automation load path and replaces fixed force-preset proxy loading with scenario-derived army-list skirmishes and blueprint deployment. No `dzw` files were modified. The next implementation block is cycles 281-290: the Guderian board shell, plus the remaining guarded C hook for scenario-defined terrain/objectives/mission state.

Status through cycle 290: completed. `dzw` now contains a guarded Guderian scenario-board hook and the root app includes a native board shell on each scenario briefing. All 19 battles launch through scenario-derived rosters, terrain/objectives, mission targets, and deployment positions; automation records `Native Board` diagnostics. The next implementation block is cycles 291-300: demo parity for Wizna, Sedan, and Moscow/Tula/Kashira from campaign row to board, scoring, debrief, and completion records.

Status through cycle 300: completed. The native playable demo target is reached for Wizna, Sedan, and Moscow/Tula/Kashira without generic proxy maps or generic proxy forces. Each demo battle now has native board playback, score/debrief output, and completion records; no additional `dzw` edits were needed in cycles 291-300. The next implementation block is cycles 301-310: upgrade GuderianTest from broad metadata/native-shell diagnostics into real board diagnostics for every battle instance, including blocked phases, invalid targets, impossible reinforcements, and unwinnable gates.

Status through cycle 310: completed. GuderianTest now runs a real board diagnostic pass for all 19 battles and records findings for blocked phases, invalid targets, impossible reinforcements, and unwinnable gates. The next implementation block is cycles 311-325: native Polish 1939 battlefield pack coverage for Tuchola Forest, Wizna, Brzesc Litewski, and Kobryn.

Status through cycle 325: completed. The Poland native pack is implemented and the four Polish 1939 battles are marked native-board ready through Guderian-owned board sessions, rule bindings, score/debrief flow, and completion records. No new `dzw` edits were needed in cycles 301-325. The next implementation block is cycles 326-345: the France 1940 native pack for Sedan, Stonne, Montcornet, Amiens-Abbeville, Boulogne, Calais, Dunkirk, and Fall Rot.

Status through cycle 345: completed. The France native pack is implemented and the eight France 1940 battles are marked native-board ready through Guderian-owned board sessions, rule bindings, score/debrief flow, and completion records. The app debrief control now completes demo, Poland, and France native pack battles from the board, and GuderianTest records native France completions. The next implementation block is cycles 346-370: the Eastern Front native pack.

Status through cycle 350: completed. The first five cycles of the Eastern Front native pack are implemented as a native foundation for all seven 1941 battles. GuderianTest records Eastern Front foundation readiness while only Moscow/Tula/Kashira has the earlier native-board demo-completion path. The next implementation block is cycles 351-370: Eastern Front native completion records and debrief flow for Bialystok-Minsk, Smolensk, Roslavl-Novozybkov, Kiev, Bryansk, and Mtsensk.

Status through cycle 370: completed. The Eastern Front native pack is implemented and all seven 1941 battles are marked native-board ready through Guderian-owned board sessions, rule bindings, score/debrief flow, and completion records. At this point all 19 campaign battles have native completion paths. The next implementation block is cycles 371-380: battle-specific AI and event pass.

Status through cycle 375: completed. The first half of the AI/event pass is implemented as full-campaign readiness mapping for German AI priorities, fallbacks, reinforcements, scripted triggers, scenario rules, pacing, tutorial cues, and victory gates. GuderianTest records AI/event readiness for every battle. The next implementation block is cycles 376-380: deeper event execution and scenario AI control tuning on real board state.

Status through cycle 380: completed. The AI/event pass now executes against real board snapshots for every battle, and GuderianTest records the board-state execution readiness. Scenario AI movement now favors authored objective priorities instead of only nearest-objective movement. The next implementation block is cycles 381-390: balance and UX readiness.

Status through cycle 390: completed. Balance/UX readiness now covers every battle for pacing, agency, density, accessibility identifiers, save/load continuity, and debrief/failure reporting. The next implementation block is cycles 391-400: native campaign ship verification.

Status through cycle 400: completed as an automation gate. All 19 battles have native board sessions with completion records, GuderianTest automation completes the campaign, AI/event execution and balance/UX checks are ready, and the metadata release baseline remains green. The next implementation block is cycles 401-425: post-ship after-action analysis.

Status through cycle 425: completed. Post-ship analysis now covers every battle with agency, AI pressure, event timing, historical-context, automation-coverage, and tuning-follow-up notes. The next implementation block is cycles 426-450: deterministic native campaign soak.

Status through cycle 450: completed. The campaign now runs deterministic soak probes across all 19 native battles with three seeded diagnostics per battle, stable replay signatures, and no blocking board findings.

## Cycles 451-500: DZW Playable Screen Rebase

These cycles correct the product milestone: a battle counts as playable only when it launches into a DZW-style board/sidebar screen with commandable opposing units, terrain, objectives, legal actions, phase flow, feedback, and a human-readable battle log.

| Cycles | Focus | Output |
| --- | --- | --- |
| 451-455 | DZW reference audit | Run `derZweiteWeltkrieg`, inspect its setup-to-battle flow, document the required battle shell, board, sidebar, unit token, action, phase, and accessibility contracts for Guderian. |
| 456-460 | Tuchola pilot screen | Route Tuchola Forest directly into the DZW-style playable shell with terrain zones, objectives, opposing units, draggable movement, selection, rotation, cover/hull-down toggles, shooting/assault controls, pending-choice resolution, and phase/log feedback. |
| 461-465 | Tuchola force fidelity | Tune the Polish and German Tuchola units so the board reads as Pomeranian Army delay versus XIX Panzer Corps pressure, with cavalry, anti-tank, demolition, motorized infantry, armor, engineer, and pincer-pressure roles visible in play. |
| 466-470 | Terrain and objective fidelity | Make the Tuchola board terrain communicate Brda crossings, forest road chokepoints, Chojnice/Tuchola hubs, Krojanty screen, Pruszcz/Pila-Mlyn bridges, Bydgoszcz withdrawal, and East Prussia pincer pressure through rules-backed zones/objectives. |
| 471-475 | Command interaction parity | Match the DZW feel for selecting, moving, rotating, targeting, firing, assaulting, resolving pending choices, and reading blocked-action feedback from the battle screen without needing the old briefing panel. |
| 476-480 | Guderian AI turn loop | Add a visible automated German turn loop for Tuchola that uses scenario-authored priorities, resolves movement/shooting/assaults, and records why the turn could not proceed if a flaw blocks play. |
| 481-485 | Battle completion loop | Add restart, debrief, scoring, result persistence, and loss/failure reporting to the DZW-style Tuchola screen so a human can play from opening board to completed battle. |
| 486-490 | Test harness parity | Extend Swift and UI automation to drive the DZW-style Tuchola screen from launch through movement, phase changes, attacks, blocked-action reporting, AI turns, and debrief completion. |
| 491-495 | Reusable shell extraction | Move the Tuchola pilot shell into a reusable Guderian playable-battle surface that can host every native scenario without bespoke UI forks. |
| 496-500 | Campaign rollout plan | Produce the per-battle rollout checklist and acceptance gates for converting Wizna through Moscow/Tula/Kashira to the same DZW-style playable screen. |

Status through cycle 455: completed. The DZW app was run and inspected, and the accepted playability target is now explicitly the DZW battle screen rather than automation-only board diagnostics.

Status through cycle 460: completed. The Tuchola Forest pilot opens into the DZW-style playable Guderian battle screen and has direct command regression coverage. The next implementation block is cycles 461-465: Tuchola force-fidelity tuning.

Status through cycle 465: completed. Tuchola live board units now display native Polish/German names, mobility, roles, and historical notes instead of only generic dzw skirmish catalog labels. The visible matchup now reads as Pomeranian Army delay assets against XIX Panzer Corps pressure.

Status through cycle 470: completed. Tuchola scoring objectives now map to the playable battlefield features that matter: the Pruszcz/Pila-Mlyn Brda bridge fight, Chojnice/Tuchola road hubs, Krojanty cavalry screen, and Bydgoszcz withdrawal. The East Prussia pincer and XIX Corps spearhead remain visible as terrain/pressure markers so the board stays inside readable objective-density limits.

Status through cycle 475: completed. Command interaction parity has improved through native-name action feedback, direct movement/rotation/cover/hull-down/shooting/assault command wrappers, and blocked-action reporting that stays visible in the DZW-style sidebar.

Status through cycle 480: completed. The Tuchola screen now has a visible German AI turn runner. It advances to the Guderian AI turn, executes movement/shooting/assault-phase steps, records AI step history in the sidebar, and tries ordered objective targets with legal fallback movement when the Brda line blocks a direct move. The next implementation block is cycles 481-485: battle completion loop.

Status through cycle 485: completed. The DZW-style Tuchola screen now has a battle completion loop: restart, debrief, scoring, local failure/error reporting, and campaign-progress persistence through the same playable screen rather than the old briefing board panel.

Status through cycle 490: completed. Test harness parity now covers the DZW-style Tuchola screen from launch through selection, movement, phase flow, attack attempts, blocked-action feedback, German AI movement, debrief, and persisted completion. The harness records the same accessibility identifiers used by the live screen.

Status through cycle 495: completed. The Tuchola pilot has been extracted behind a reusable playable-battle surface contract. The Guderian app now routes playable-screen scenarios through the catalog rather than hard-coding a one-off Tuchola branch, and each non-routed battle exposes its rollout state in the briefing workspace.

Status through cycle 500: completed. The campaign rollout checklist is now defined for every battle. Tuchola Forest is the completed pilot for cycles 451-500; Wizna is the next DZW-style screen conversion window for cycles 501-505; the remaining battles queue in five-cycle windows through Moscow/Tula/Kashira at cycles 586-590. The current 451-500 correction plan has no documented cycles remaining.

## Cycles 501-590: Battles 2-19 Playable-Screen Estimate

Battle 1, Tuchola Forest, is the completed DZW-style playable-screen pilot through cycle 500. The remaining campaign battles 2-19 are estimated at 18 battles x 5 cycles each, or 90 cycles total, to complete the same battle-selection-to-playable-screen flow with commandable units, terrain features, opposing AI pressure, blocked-action reporting, scoring, debrief, and screen-parity coverage.

The five-cycle estimate assumes the reusable playable-battle surface from cycles 491-495 remains the common shell. Each battle packet is therefore scoped to scenario-specific unit, terrain, objective, AI, debrief, and test fidelity rather than rebuilding the engine or UI.

| Battle | Cycles | Focus |
| --- | --- | --- |
| 2. Wizna | 501-505 | Bunkers, fortified line, Polish anti-tank and artillery delay, overwhelming German pressure, tutorial-safe debrief. |
| 3. Brzesc Litewski | 506-510 | Fortress and citadel sectors, armored train support, obsolete armor, fallback routes, fortress-combat feedback. |
| 4. Kobryn | 511-515 | Rearguard defense, town roadblocks, withdrawal lanes, German pursuit pressure, escape scoring. |
| 5. Sedan | 516-520 | Meuse crossings, bridgeheads, engineers, air and artillery pressure, panzer exploitation. |
| 6. Stonne | 521-525 | Village and heights fighting, Char B1 counterattack pressure, armor attrition, contested control scoring. |
| 7. Montcornet | 526-530 | French armored raid, mobile German response, Luftwaffe pressure, timed withdrawal and disruption scoring. |
| 8. Amiens-Abbeville | 531-535 | Somme bridge defense, mobile blocking positions, Channel-race pressure, corridor denial. |
| 9. Boulogne | 536-540 | Port and harbor terrain, evacuation timing, naval support markers, demolition and perimeter defense. |
| 10. Calais | 541-545 | Perimeter, citadel, and dock sectors, siege pressure, supply strain, Dunkirk-time scoring. |
| 11. Dunkirk | 546-550 | Evacuation perimeter, canals, rearguard lines, German command caveat, evacuation-preservation scoring. |
| 12. Fall Rot | 551-555 | Aisne, Marne, and Rhine crossing pressure, fortress-town stands, retreat corridors, collapse timing. |
| 13. Bialystok-Minsk | 556-560 | Encirclement pockets, breakout lanes, pincer pressure, Minsk road and rail objectives. |
| 14. Smolensk | 561-565 | Dnieper and Dvina crossings, pocket escape, reserve counterstroke, stretched German timetable. |
| 15. Roslavl-Novozybkov | 566-570 | Spoiling offensive, reconnaissance friction, supply-column raids, operational delay scoring. |
| 16. Kiev | 571-575 | Northern pincer pressure, Dnieper and Desna delay lines, command evacuation, breakout preservation. |
| 17. Bryansk | 576-580 | Typhoon southern approach, encirclement pockets, Orel-Tula road pressure, autumn friction. |
| 18. Mtsensk | 581-585 | T-34 and KV ambushes, wooded ridges, anti-tank screens, German armor-loss scoring. |
| 19. Moscow/Tula/Kashira | 586-590 | Winter roads, Tula defense, Venev and Kashira pressure, German exhaustion and Soviet counteroffensive setup. |

The repeating five-cycle packet for each battle is:

1. Launch route, battle-selection wiring, and board framing.
2. Scenario-specific unit labels, roles, starting positions, and commandability.
3. Terrain, objective, scoring, and legal-action tuning.
4. German AI turn behavior, blocked-action diagnostics, failure reporting, and debrief output.
5. Screen-parity tests, GuderianTest coverage, documentation update, and manual-play notes.

Risk buffer: larger Eastern Front battles, especially Kiev, Smolensk, and Moscow/Tula/Kashira, may need one additional 10-cycle hardening block after cycle 590 if hand play exposes unit-density, AI-stall, or readability problems. The baseline documented estimate remains 90 cycles for battles 2-19.

Status through cycle 505: completed. Wizna now routes from the battle row into the DZW-style playable screen with fortified-line units, bunker objectives, German pressure, debrief persistence, and screen-parity coverage.

Status through cycle 510: completed. Brzesc Litewski now routes through the playable screen with fortress/citadel terrain, rail and armored-train context, fallback objectives, native completion, and GuderianTest parity reporting.

Status through cycle 515: completed. Kobryn now routes through the playable screen with rearguard units, roadblock/withdrawal objectives, German pursuit pressure, blocked-action feedback, and debrief persistence.

Status through cycle 520: completed. Sedan now routes through the playable screen with Meuse crossings, bridgehead/engineer pressure, German AI movement, completion scoring, and parity automation.

Status through cycle 525: completed. Stonne now routes through the playable screen with village/heights terrain, Char B1 counterattack pressure, armor-attrition objectives, and debrief persistence.

Status through cycle 530: completed. Montcornet now routes through the playable screen with French armored raid units, mobile German response, Luftwaffe pressure, timed withdrawal scoring, and screen-parity coverage.

Status through cycle 535: completed. Amiens-Abbeville now routes through the playable screen with Somme bridge terrain, mobile blocking positions, Channel-race objectives, German AI pressure, and GuderianTest reporting.

Status through cycle 540: completed. Boulogne now routes through the playable screen with harbor/port terrain, evacuation and demolition objectives, naval support context, and hardened active-unit movement probing around impassable harbor geometry.

Status through cycle 545: completed. Calais now routes through the playable screen with perimeter/citadel/docks objectives, siege pressure, supply and Dunkirk-time scoring, debrief persistence, and parity automation.

Status through cycle 550: completed. Dunkirk now routes through the playable screen with evacuation perimeter terrain, canals, rearguard lines, Guderian-command caveat framing, German pressure, debrief persistence, and parity automation.

Status through cycle 555: completed. Fall Rot now routes through the playable screen with Aisne/Marne/Rhine crossing pressure, fortress-town stands, retreat corridors, collapse timing, German AI movement, and screen-parity reporting.

Status through cycle 560: completed. Bialystok-Minsk now routes through the playable screen with encirclement pockets, breakout lanes, pincer pressure, Minsk road/rail objectives, completion scoring, and GuderianTest parity coverage.

Status through cycle 565: completed. Smolensk now routes through the playable screen with Dnieper/Dvina crossings, pocket escape, reserve counterstroke pressure, stretched German timetable, debrief persistence, and parity automation.

Status through cycle 570: completed. Roslavl-Novozybkov now routes through the playable screen with spoiling-offensive pressure, reconnaissance friction, supply-column raids, German AI objectives, and blocked-action reporting.

Status through cycle 575: completed. Kiev now routes through the playable screen with northern pincer pressure, Dnieper/Desna delay lines, command evacuation, breakout preservation, debrief persistence, and GuderianTest coverage.

Status through cycle 580: completed. Bryansk now routes through the playable screen with Operation Typhoon southern approach, pocket pressure, Orel-Tula road objectives, autumn friction, German AI movement, and parity reporting.

Status through cycle 585: completed. Mtsensk now routes through the playable screen with T-34/KV ambush pressure, wooded ridges, anti-tank screens, German armor-loss scoring, debrief persistence, and parity automation.

Status through cycle 590: completed. Moscow/Tula/Kashira now routes through the playable screen with winter roads, Tula defense, Venev/Kashira pressure, German exhaustion, Soviet counteroffensive setup, and full campaign parity automation. The DZW-style playable-screen rollout has completed battles 1-19; there are no documented battle-parity cycles remaining.

## Cycles 591-650: Map Detail And Late-Career Expansion

The cycle 590 campaign is playable, but the battle maps are still too abstract for the requested 400% geography/detail improvement, and the chronology stops at Guderian's 1941 field-command career. Cycles 591-650 add a sourceable map-detail pipeline, richer map schema, substantially denser geography for the existing 19 battles, and command-context battlefields for the 1943-1945 withdrawal and final-war period. Late-career additions must be labeled carefully: after Guderian's December 1941 dismissal from field command, scenarios are staff-influence or post-dismissal context unless a source proves direct battlefield command.

| Cycles | Focus | Output |
| --- | --- | --- |
| 591-595 | Historical scope reset | Add a career-scope ledger that separates direct field-command battles, adjacent campaign-pressure scenarios, Inspector General influence, Army General Staff influence, and post-dismissal epilogues. |
| 596-600 | Map-detail audit | Measure each current map's terrain, water, road, rail, bridge, settlement, objective, and deployment density; set per-battle 400% detail targets. |
| 601-605 | Map schema upgrade | Extend map elements for canals, lakes, marsh, rail, fords, ferries, named villages, ridges, urban districts, phase lines, and source-note metadata. |
| 606-610 | Geography pipeline | Create a repeatable geography cross-check process using modern map references as visual guides, while storing hand-authored abstract coordinates and source notes in code. |
| 611-615 | Poland map enrichment | Rework Tuchola Forest, Wizna, Brzesc Litewski, and Kobryn with denser water, rail, road, village, bridge, forest, marsh, and fallback-route detail. |
| 616-620 | France map enrichment | Rework Sedan through Fall Rot with denser Meuse/Somme/coast/canal/fortress/road/urban geography and clearer evacuation/crossing terrain. |
| 621-625 | 1941 East map enrichment | Rework Bialystok-Minsk through Moscow/Tula/Kashira with denser rivers, rail hubs, pocket exits, forest belts, road axes, winter lanes, and named settlements. |
| 626-630 | Late-career set A | Add 1943-early 1944 staff-context battlefields such as Kursk armored-force pressure, Dnieper withdrawal, Korsun-Cherkassy, and Kamenets-Podolsky. |
| 631-635 | Late-career set B | Add 1944 withdrawal/crisis battlefields such as Bagration, Lvov-Sandomierz, Narew/Vistula bridgeheads, and Warsaw-area defensive arcs. |
| 636-640 | 1945 collapse set A | Add Vistula-Oder, Poznan corridor, East Prussia/Elbing, and Kustrin/Oder bridgehead scenarios as General Staff context. |
| 641-645 | 1945 collapse set B | Add Operation Solstice, East Pomeranian offensive, Seelow Heights epilogue, and Berlin/Halbe epilogue where command caveats are visible in UI and tests. |
| 646-650 | Integration and acceptance | Run GuderianTest through old and new battles, verify map-detail targets, command caveats, playable-screen routing, AI, debriefs, docs, and full SwiftPM/Xcode builds. |

Status through cycle 595: completed. `GuderianCareerScopeCatalog` covers all current campaign scenarios and initially cataloged 15 late-career expansion candidates. Tests assert that current direct-command scenarios remain separated from Dunkirk's command caveat and that all 1943-1945 candidates require staff-influence or post-dismissal framing.

Status through cycle 600: completed. `ScenarioMapDetailAuditCatalog` now reports the baseline map density and four-times-current detail target for all 19 existing battles. The current campaign needs enrichment across every map, and the audit records category gaps for water, roads, railways, crossings, settlements, terrain, fortifications, objectives, pressure markers, and annotations before schema expansion begins.

Status through cycle 605: completed. `ScenarioMapElementKind` and `NativeBattleTerrainKind` now support the richer geography needed for map enrichment, and `ScenarioMapSourceNote` gives future map features source-facing context. Tests verify the expanded schema and the audit's ability to count the new geography and source-note metadata.

Status through cycle 610: completed. `ScenarioMapGeographyPipelineCatalog` now covers all 19 current battles with modern map visual-guide references, scenario-source references, inferred feature anchors, required audit categories, and a fixed cross-check workflow that translates visual geography into hand-authored abstract coordinates. Current map layouts now carry scenario-level source notes generated from the pipeline so future enrichment can attach detailed feature notes without creating a separate Guderian-only process.

Status through cycle 615: completed. The Poland map enrichment pass expands Tuchola Forest to at least 56 baseline-counted features, Wizna to at least 36, Brzesc Litewski to at least 44, and Kobryn to at least 40. The enriched maps include explicit railways, marsh and water geography, multiple crossings, named villages and urban districts, forest or ridge terrain, fallback roads, and phase lines; tests verify the category coverage and 400% baseline threshold in both dzw and Guderian.

Status through cycle 620: completed. The France map enrichment pass expands Sedan to at least 40 baseline-counted features, Stonne to at least 36, Montcornet to at least 36, Amiens-Abbeville to at least 40, Boulogne to at least 40, Calais to at least 40, Dunkirk to at least 44, and Fall Rot to at least 40. The enriched maps include explicit railways, canals where applicable, water geography, multiple crossings, named villages and urban districts, ridges or fortress terrain, evacuation and withdrawal routes, and phase lines; tests verify the category coverage and 400% baseline threshold in both dzw and Guderian.

Status through cycle 625: completed. The Eastern Front map enrichment pass expands Bialystok-Minsk to at least 44 baseline-counted features, Smolensk to at least 52, Roslavl-Novozybkov to at least 48, Kiev to at least 48, Bryansk to at least 52, Mtsensk to at least 52, and Moscow/Tula/Kashira to exactly the current 64-feature map budget. The enriched maps include explicit railways, multiple river systems, named settlements and urban districts, crossings, forests, ridges, marshes, pocket and breakout exits, armor ambush terrain, winter movement lanes, and phase lines; tests verify category coverage and the 400% baseline threshold in both dzw and Guderian.

Status through cycle 630: completed. `LateCareerStaffBattlefieldSetACatalog` now turns the first four late-career expansion candidates into concrete staff-context battlefields with source links, command caveats, player/opposition forces, objective sets, rules, deployment zones, and detailed maps. The main 19-battle playable campaign remains stable while the 1943-early 1944 withdrawal arc becomes testable as non-direct-command expansion data.

Status through cycle 635: completed. `LateCareerStaffBattlefieldSetBCatalog` covers the 1944 withdrawal and Warsaw-area defensive arc block as Army General Staff context, including the newly added `warsaw-defensive-arcs` career-ledger candidate needed to make the plan's set-B scope complete.

Status through cycle 640: completed. `LateCareerStaffBattlefieldSetCCatalog` covers Vistula-Oder, Poznan, East Prussia/Elbing, and Kustrin/Oder bridgeheads with detailed General Staff context maps and command-caveated rules.

Status through cycle 645: completed. `LateCareerStaffBattlefieldSetDCatalog` covers Operation Solstice, East Pomeranian offensive, Seelow Heights, and Berlin/Halbe, with Seelow and Berlin/Halbe held as post-dismissal epilogues and caveat labels visible in testable data.

Status through cycle 650: completed. `LateCareerStaffBattlefieldAcceptanceCatalog` ties the map-detail and late-career expansion together: the 19 current battles remain playable-screen routed, all late-career records match the 16-candidate ledger, and every staff/epilogue battlefield is ready as command-caveated shared dzw data. The current 60-cycle expansion plan has no documented cycles remaining.

## Acceptance Criteria

- `dzw` remains cleanly updatable because Guderian-specific engine hooks are guarded or externalized.
- The demo ships with Wizna, Sedan, and Moscow/Tula playable from briefing to debrief.
- The full campaign ships with every battle in the README chronology playable.
- Every battle has source links, scenario notes, force data, objectives, balance status, and test coverage.
- Existing and future maps hit the 400% detail-improvement target through denser sourceable geography rather than decorative markers.
- Late-career battlefields after Guderian's 1941 dismissal are framed as Inspector General, Army General Staff, or post-dismissal context unless direct field command is proven.
- The app clearly frames the player as opposing Guderian and treats the historical subject with sober context.
- "Playable" means a DZW-style hand-playable Guderian battle screen with scenario-specific units, terrain, objectives, legal actions, scoring, AI pressure, blocked-action reporting, logs, and debriefs; proxy-loadable metadata or automation-only completion no longer satisfies the playable milestone.
