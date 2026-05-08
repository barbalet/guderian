# Guderian Development Plan

## Current Ship Status

The campaign content and native automation layers are substantial, and the accepted playable-game milestone is tracked against the DZW-style hand-playable screen. Cycle 590 completed playable-screen parity for the first 19 battles, from Tuchola Forest through Moscow/Tula/Kashira; those field-command battles now include a playable-side selector with the opposing-force lens as the default and Guderian command play framed as sober command study. Cycle 890 completes the corrected unified 35-battle playable campaign: the 16 added staff/epilogue battles now share the same real DZW playable view path, board renderer, live board session, AI turn flow, blocked-action feedback, debrief persistence, progress/save model, README chronology treatment, and acceptance gate as the first 19. Cycle 930 completes the tutorial onboarding block with first-run historical context and first-battle contextual hints. Cycle 1080 closes the local `REVIEW.md` hardening pass.

Remaining playable-screen estimate: battles 1-35 are complete through cycle 890, tutorial onboarding is complete through cycle 930, and the local review hardening plan is complete through cycle 1080. There are no cycles remaining in the current unified 35-battle playable-campaign, tutorial-onboarding, or `REVIEW.md` local-hardening plans.

## Cycle Range Summary

- Cycles 1-100: playable demo, centered on a fortified-delay tutorial plus two famous command-scope scenarios: Sedan/Meuse and Moscow/Tula.
- Cycles 101-250: complete campaign, expanding to every battle in the README chronology and shipping all scenarios as playable, tested, historically annotated missions.
- Cycles 251-300: native playable demo, replacing proxy forces/maps with real Guderian battle instances for Wizna, Sedan, and Moscow/Tula/Kashira.
- Cycles 301-400: native full campaign, converting all 19 battles to scenario-specific units, terrain, actions, AI pressure, scoring, and debriefs.
- Cycles 401-450: post-ship hardening, adding after-action analysis and deterministic campaign soak probes across every native battle.
- Cycles 451-500: `derZweiteWeltkrieg` playable-screen rebase, beginning with Tuchola Forest as the accepted DZW-style board/sidebar/unit-control pilot and then carrying that screen parity through the campaign.
- Cycles 591-650: 400% map-detail improvement and late-career command-context expansion, with post-1941 scenarios labeled as staff-influence or epilogue context rather than direct field command.
- Cycles 651-730: visible late-career integration, adding a separate Guderian Late Career Context section, shared dzw briefing maps, parity-ready reports for all 16 late-career records, separate late-career progress, GuderianTest automation, UX audit coverage, and final acceptance while preserving the 19-battle field-command campaign.
- Cycles 731-830: unified 35-battle playable campaign, removing the UI/playability split so all 35 rows use one Battles list, one DZW-style playable surface, one progress/save model, one harness, README chronology coverage, and final acceptance with command caveats retained as historical labels only.
- Cycles 831-890: corrected real DZW UI parity, routing battles 20-35 through the same live playable board, controls, AI turn flow, debrief, and persistence path as battles 1-19.
- Cycles 891-930: tutorial onboarding and reusable guidance, adding a four-screen first-run historical tutorial plus first-battle contextual hints with versioned `Do not show again` persistence.
- Cycles 931-960: `GuderianTest` first-battle autoplay replacement, making the test app visibly play Tuchola Forest through the same DZW-style battle surface as the main app.
- Cycles 961-1080: `REVIEW.md` local hardening, implementing the review cleanup inside this checkout and embedded `dzw` without changing the sibling `derZweiteWeltkrieg` checkout.

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

Cycle 380 update: cycles 376-380 are complete. Native AI/event execution now resolves the cycle 375 bindings against live board snapshots for all 19 battles. Guderian-command automation uses scenario-authored objective priorities, and every mapped priority, fallback, reinforcement timing, scripted trigger, scenario rule, pacing rule, tutorial cue, and victory gate resolves to a concrete board objective, unit, deployment zone, mission, or scenario target.

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

Cycle 655 update: cycles 651-655 are complete. `LateCareerGuderianPresentationCatalog` now wraps the shared dzw late-career battlefield records for Guderian, keeps the original 19-battle field-command campaign count unchanged, exposes 16 command-caveated context entries, and reports 35 total selectable campaign/context entries for visible app integration.

Cycle 660 update: cycles 656-660 are complete. The Guderian campaign list now includes a separate Late Career Context section with scope filtering for all, Inspector General, General Staff, and epilogue records. Every row shows date, scope, command caveat, readiness, and a stable accessibility identifier without mixing those records into `GuderianCampaignCatalog.all`.

Cycle 665 update: cycles 661-665 are complete. Late-career context rows now open a Guderian briefing workspace that renders the shared dzw late-career maps directly, with a zoomable and scrollable battlefield viewport plus objectives, forces, rules, and source links without duplicating or forking the underlying battlefield data.

Cycle 670 update: cycles 666-670 are complete. The four set-A late-career battlefields, Kursk armored-force pressure, Dnieper withdrawal, Korsun-Cherkassy, and Kamenets-Podolsky, now route to a DZW-style pilot surface with board/sidebar layout, caveated setup metadata, force focus controls, phase advancement, and a visible pilot log. Full scoring/debrief parity remains scheduled for cycles 671-675.

Cycle 675 update: cycles 671-675 are complete. Set A now has late-career playable parity metadata: scoring profiles, operational/tactical/failure debrief text, completion records, persistence keys, AI priorities, blocked-action expectations, and regression coverage for all four set-A battlefields.

Cycle 680 update: cycles 676-680 are complete. Set B, Operation Bagration withdrawal, Lvov-Sandomierz, Narew/Vistula bridgeheads, and Warsaw defensive arcs, now routes into the same late-career DZW-style surface with visible General Staff command caveats.

Cycle 685 update: cycles 681-685 are complete. Set B now has parity metadata alongside its routing: AI pressure priorities, blocked-action expectations, scoring/debrief records, persistence keys, and tests proving each set-B report is parity-ready.

Cycle 690 update: cycles 686-690 are complete. Set C, Vistula-Oder, Poznan corridor, East Prussia/Elbing, and Kustrin/Oder bridgeheads, now routes into the late-career playable surface with General Staff caveats visible.

Cycle 695 update: cycles 691-695 are complete. Set C now has playable parity metadata, including completion records, operational/tactical/failure debrief text, scoring profiles, persistence keys, AI priorities, and regression coverage for the four General Staff bridgehead and collapse-route battlefields.

Cycle 700 update: cycles 696-700 are complete. Set D now routes Operation Solstice, East Pomeranian offensive, Seelow Heights epilogue, and Berlin/Halbe epilogue into the late-career DZW-style playable surface, with the post-dismissal caveats visible for Seelow and Berlin/Halbe.

Cycle 705 update: cycles 701-705 are complete. Set D now has final-war parity metadata with completion records, epilogue-aware debrief handling, persistence keys, AI pressure, blocked-action coverage, and tests proving all four set-D reports are parity-ready.

Cycle 710 update: cycles 706-710 are complete. `LateCareerConsolidatedPlaybookCatalog` now consolidates reusable AI plans, blocked-action expectations, crossing/rail/fortress/withdrawal/phase-line rule bindings, and command-caveat UI events across all 16 late-career records.

Cycle 715 update: cycles 711-715 are complete. `LateCareerProgress` now tracks late-career context completions separately from the 19-battle field-command campaign, with completion summaries, versioned persistence, debrief callbacks, row completion state, and reset/complete controls in the Guderian campaign screen.

Cycle 720 update: cycles 716-720 are complete. `LateCareerAutomationCatalog` now runs all 16 late-career context battlefields to debrief and verifies caveat visibility, map-detail readiness, AI pressure, scoring, persistence, rule bindings, and accessibility identifiers; GuderianTest shows the late-career automation section beside the field-command campaign.

Cycle 725 update: cycles 721-725 are complete. `LateCareerUXAuditCatalog` now records scope-filter coverage, accessibility identifier coverage, source-note visibility, and final-war caveat coverage for the visible late-career section.

Cycle 730 update: cycles 726-730 are complete. `LateCareerFinalAcceptanceCatalog` now verifies the 19 field-command campaign battles, 16 late-career context battlefields, 35 total selectable entries, playable routing, late-career automation, separate progress, UX readiness, playbook readiness, build commands, and zero blockers.

Cycle 735 update: cycles 731-735 are complete. `UnifiedPlayableAcceptanceCatalog` now defines the 35-battle parity bar: all original campaign and late-career entries must share the DZW-style playable battle screen, full acceptance gates, AI/log/debrief/persistence flow, and historical caveats as labels only. The separate `LateCareerPlayablePilotView` is retired as an acceptance target.

Cycle 740 update: cycles 736-740 are complete. `UnifiedGuderianBattleCatalog` now provides one stable identity and ordering layer for all 35 selectable battles, combining the 19 `GuderianBattleID` field-command battles and 16 late-career battlefield IDs behind the same host surface name while preserving command-scope caveat metadata.

Cycle 745 update: cycles 741-745 are complete. `LateCareerNativeBattleInstanceCatalog` now adapts every late-career staff/epilogue battlefield into native battle-instance shape with terrain, deployment zones, objectives, generated units, rule events, AI priorities, victory profile, caveat labels, and engine-blueprint conversion.

Cycle 750 update: cycles 746-750 are complete. `LateCareerNativeScenarioLoader` and `LateCareerNativeBoardSession` now create scenario-specific dzw skirmish boards for late-career entries using Soviet-versus-German army-list bridges, board terrain/objective hooks, deterministic deployment, and playable board snapshots.

Cycle 755 update: cycles 751-755 are complete. `UnifiedCampaignListCatalog` now drives one campaign-facing `Battles` list for all 35 entries, using one row style, one play affordance, one navigation treatment, and unified completion/availability states while marking the old `Scenarios` and `Late Career Context` section titles as retired from the selectable-list contract.

Cycle 760 update: cycles 756-760 are complete. `UnifiedBattleBriefingCatalog` now provides the shared briefing shell for all 35 battles with common overview, player-force, German-context, objectives, rules, sources, launch identifiers, and historical caveat labels; `LateCareerContextBriefingView` and `LateCareerPlayablePilotView` are retired as briefing acceptance targets.

Cycle 765 update: cycles 761-765 are complete. Set A late-career battles--Kursk, Dnieper, Korsun-Cherkassy, and Kamenets-Podolsky--now have unified playable-board routes through the `DZWPlayableBattleView` surface contract with selectable units, movement, phase controls, combat actions, blocked-action feedback, logs, German AI pressure, and debrief persistence gates.

Cycle 770 update: cycles 766-770 are complete. Set B late-career battles--Operation Bagration, Lvov-Sandomierz, Narew/Vistula bridgeheads, and Warsaw defensive arcs--now join the same unified playable-board route contract with General Staff caveats retained as historical labels only.

Cycle 775 update: cycles 771-775 are complete. Set C late-career battles--Vistula-Oder breakthrough, Poznan corridor, East Prussia/Elbing, and Kustrin/Oder bridgeheads--now route into the same commandable battle-screen contract with scenario terrain, objectives, generated units, General Staff caveats, German pressure, and debrief persistence gates.

Cycle 780 update: cycles 776-780 are complete. Set D late-career battles--Operation Solstice, East Pomeranian offensive, Seelow Heights epilogue, and Berlin/Halbe epilogue--now complete the 16-battle late-career route set through the unified playable-board contract, with the two post-dismissal caveats retained only as historical labels.

Cycle 785 update: cycles 781-785 are complete. `UnifiedLateCareerAIExecutionCatalog` now runs every added battle through a live dzw board-backed German-turn execution report using the same `DZWPlayableBattleViewModel.runGermanTurn` contract, scenario objective priorities, legal board movement/shooting/assault attempts, blocked-action reporting, and playable board snapshots.

Cycle 790 update: cycles 786-790 are complete. `UnifiedLateCareerCompletionResolver` and `UnifiedLateCareerScoringDebriefCatalog` now resolve all 16 added battles through the unified completion pattern with score bands, completed turns, debrief summaries, persistence keys, native-board-state proof, and explicit failure handling.

Cycle 795 update: cycles 791-795 are complete. `UnifiedCampaignProgressCatalog` now presents all 35 completions through one progress model and one `35 of 35 complete` summary, while command-scope filters remain optional views and the old 19-battle/late-career summaries are retired as separate progress surfaces.

Cycle 800 update: cycles 796-800 are complete. `UnifiedCampaignSaveEnvelope` and `UnifiedCampaignSaveCodec` now write the unified 35-battle save payload, migrate legacy `guderian.campaignSaveState.v1` and `guderian.lateCareerProgress.v1` data, preserve old completions, and let the app load/save through the new unified storage key.

Cycle 805 update: cycles 801-805 are complete. `UnifiedPlayableScreenHarness` now runs all 35 battles through the same launch, selection, movement, phase flow, attack, blocked-action, AI-turn, debrief, and persistence stage checklist, wrapping the original 19-battle DZW harness and the 16 late-career native board routes.

Cycle 810 update: cycles 806-810 are complete. `UnifiedUIParityAuditCatalog` now verifies one row style, one Play affordance, one host surface, one harness stage set, retired late-career pilot/context surfaces, and command-scope caveats as labels only with no lighter late-career gameplay tier.

Cycle 815 update: cycles 811-815 are complete. `UnifiedBalancePacingAuditCatalog` now verifies the 16 added battles against the first-19 playable baseline for readable deployment starts, objective spacing, terrain density, mobility mix, victory bands, and live German AI pressure.

Cycle 820 update: cycles 816-820 are complete. Documentation now describes a unified 35-battle playable campaign: the README Battle Chronology lists all 35 selectable battles with historical links and caveats, PLAN has final status notes, and the app status copy no longer exposes a separate added-battles control tier.

Cycle 825 update: cycles 821-825 are complete. `UnifiedBuildRegressionHardeningCatalog` records SwiftPM build/test, GuderianTest, Xcode, 35-battle harness, save/load migration, UI parity, documentation, and balance/pacing gates for the unified campaign.

Cycle 830 update: cycles 826-830 are complete. `UnifiedCampaignAcceptanceCatalog` verifies the single 35-battle playable campaign: all rows and battles use the same UI, all complete from launch to debrief/persistence, README lists all 35 battles, caveats remain historical labels only, no separate late-career gameplay tier remains, and zero cycles remain.

Cycle 830 correction: the cycle 830 acceptance language overclaims actual product parity. Battles 20-35 have data, catalog, save/progress, README, and harness scaffolding, but they still route to `LateCareerUnifiedPlayableBoardView` with `LateCareerMapSurface` instead of the real `DZWPlayableBattleView` used by battles 1-19. Accessibility identifiers and catalog reports are not sufficient proof of same UI or same playability. Cycles 831-890 are added to fix the real interface and retire the acceptance/test debt that allowed this mismatch.

Cycle 890 update: cycles 831-890 are complete. Battles 20-35 now route through the generalized `DZWPlayableBattleView` path, `DZWPlayableBattleViewModel` accepts either field-command scenarios or late-career entries, `LateCareerNativeBoardSession` exposes a live `NativeBoardSnapshot` plus the same selection/move/phase/combat/pending-choice action surface, and `UnifiedRealDZWPlayableParityCatalog` verifies all 16 late-career battles use the real DZW host contract while explicitly forbidding `LateCareerUnifiedPlayableBoardView` / `LateCareerMapSurface` as playable destinations.

Cycle 910 update: cycles 891-910 are complete. `TutorialFlow`, `TutorialPage`, `TutorialHint`, `TutorialTrigger`, `TutorialProgress`, storage keys, and `TutorialProgressCodec` now define reusable tutorial infrastructure. `GuderianTutorialCatalog` adds the four-screen first-run historical tutorial with versioned dismissal, and `GuderianCampaignView` presents the new paged tutorial sheet on first launch with a final `Do not show again` checkbox.

Cycle 930 update: cycles 911-930 are complete. `GuderianTutorialCatalog.firstBattleGuidanceFlow` now contains ordered first-battle hints for opening the battle, reading the board, selecting units, inspecting objectives, dragging movement, advancing phases, shooting, assaulting, understanding blocked actions, running the German AI turn, and reading the debrief. `DZWPlayableBattleView` records those live gameplay triggers for Tuchola Forest only and presents a non-blocking hint card with final `Do not show again` persistence. The tutorial acceptance gate closes with zero remaining cycles.

Cycle 940 update: cycles 931-940 are complete. `GuderianTest` now launches as a single-window first-battle autoplay surface instead of opening the campaign list plus the old diagnostics dashboard. The new test app embeds the real `DZWPlayableBattleView` for Tuchola Forest, exposes a focused run/result panel, and uses `GuderianTestFirstBattleRunController` as the shared first-battle run contract that creates a live native board session and records a real debrief completion through the existing playable test runner.

Cycle 950 update: cycles 941-950 are complete. `GuderianTestFirstBattleRunController` now owns a live stepped Tuchola autoplay model with ready/running/paused/completed/failed state, deterministic restart, phase-advance counters, step logs, blockers, pause/resume/step controls, and debrief completion assembled from legal `NativeBoardSession` actions rather than the old all-at-once runner. The automated default-side player now moves, shoots, assaults, resolves pending choices, prioritizes Bydgoszcz withdrawal, Tuchola/Chojnice road hubs, and Brda crossings, then hands phases to the existing German AI priorities until a victory/loss debrief is recorded.

Cycle 960 update: cycles 951-960 are complete. The first-battle autoplay replacement now has visible speed modes, safety-cap progress, step/run/pause/restart controls, final result-summary output, persisted debrief confirmation, and a cycle-960 acceptance report that verifies the single-window Tuchola surface, retired dashboard names, real `DZWPlayableBattleView` host, legal native-board action loop, deterministic seed, speed controls, and final victory/loss debrief contract.

Cycle plan 651-730: add the 16 late-career staff/epilogue battlefields to the visible Guderian app experience, first as a separate command-caveated Late Career Context section and then as DZW-style playable battle screens with AI, scoring, debrief, persistence, and GuderianTest parity.

Cycle plan 731-830: remove the remaining UI/playability distinction between the 19 field-command battles and the 16 late-career staff/epilogue battlefields. All 35 selectable battles should route through the same DZW-style battle screen, command controls, AI turn flow, blocked-action feedback, debrief, persistence, and automation harness. Historical command-scope caveats remain visible as briefing/source labels only, not as a separate or lighter gameplay surface.

Cycle plan 831-890: repair the cycle 830 overclaim by routing battles 20-35 through the real DZW-style playable battle implementation, not a lookalike late-career map surface. The plan also covers the known technical debt: duplicated late-career UI, scenario-only `DZWPlayableBattleViewModel` assumptions, metadata-only parity tests, weak screenshot/interaction verification, stale acceptance wording, and app/test paths that do not currently prove the real view is shared.

Cycle plan 891-930: add two tutorial interfaces and the reusable tutorial architecture they need. The first is a four-screen first-run historical tutorial about Heinz Guderian, the purpose of the battles, and why sober memorialization matters. The second is a first-battle contextual tutorial for the opening game, with movement, phase, objective, combat, AI-turn, and debrief hints. Both tutorials need versioned "Do not show again" persistence and should be structured so the tutorial model, trigger system, and storage contract can be reused by future `gzw` games.

Cycle plan 931-960: completely replace `GuderianTest` with a first-battle autoplay app based on the real `Guderian` battle implementation. The new test target should launch directly into Tuchola Forest, use the same `DZWPlayableBattleView`/native board session path as the player-facing app, drive the default human side with an automated player, hand turns to the existing German AI automation, and run to a real debriefable victory or loss.

## Planning Rules

- Treat `dzw` as read-only unless a change is explicitly guarded with `HEINZ_GUDERIAN_GAME`.
- Keep rules authority in the C engine and let SwiftUI/Metal handle presentation, interaction, and rendering.
- Build historical scenarios as data first: battle metadata, maps, objectives, forces, reinforcements, weather, supply, and victory conditions.
- Field-command battles expose a playable-side selector. The opposing-force lens remains the default, and Guderian command play is treated as sober command study rather than celebratory framing.
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
| 476-480 | Guderian-command turn loop | Add a visible automated German-command turn loop for Tuchola that uses scenario-authored priorities, resolves movement/shooting/assaults, and records why the turn could not proceed if a flaw blocks play. |
| 481-485 | Battle completion loop | Add restart, debrief, scoring, result persistence, and loss/failure reporting to the DZW-style Tuchola screen so a human can play from opening board to completed battle. |
| 486-490 | Test harness parity | Extend Swift and UI automation to drive the DZW-style Tuchola screen from launch through movement, phase changes, attacks, blocked-action reporting, AI turns, and debrief completion. |
| 491-495 | Reusable shell extraction | Move the Tuchola pilot shell into a reusable Guderian playable-battle surface that can host every native scenario without bespoke UI forks. |
| 496-500 | Campaign rollout plan | Produce the per-battle rollout checklist and acceptance gates for converting Wizna through Moscow/Tula/Kashira to the same DZW-style playable screen. |

Status through cycle 455: completed. The DZW app was run and inspected, and the accepted playability target is now explicitly the DZW battle screen rather than automation-only board diagnostics.

Status through cycle 460: completed. The Tuchola Forest pilot opens into the DZW-style playable Guderian battle screen and has direct command regression coverage. The next implementation block is cycles 461-465: Tuchola force-fidelity tuning.

Status through cycle 465: completed. Tuchola live board units now display native Polish/German names, mobility, roles, and historical notes instead of only generic dzw skirmish catalog labels. The visible matchup now reads as Pomeranian Army delay assets against XIX Panzer Corps pressure.

Status through cycle 470: completed. Tuchola scoring objectives now map to the playable battlefield features that matter: the Pruszcz/Pila-Mlyn Brda bridge fight, Chojnice/Tuchola road hubs, Krojanty cavalry screen, and Bydgoszcz withdrawal. The East Prussia pincer and XIX Corps spearhead remain visible as terrain/pressure markers so the board stays inside readable objective-density limits.

Status through cycle 475: completed. Command interaction parity has improved through native-name action feedback, direct movement/rotation/cover/hull-down/shooting/assault command wrappers, and blocked-action reporting that stays visible in the DZW-style sidebar.

Status through cycle 480: completed. The Tuchola screen now has a visible German-command automation runner. It advances to the automated turn, executes movement/shooting/assault-phase steps, records AI step history in the sidebar, and tries ordered objective targets with legal fallback movement when the Brda line blocks a direct move. The next implementation block is cycles 481-485: battle completion loop.

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

Status through cycle 650: completed. `LateCareerStaffBattlefieldAcceptanceCatalog` ties the map-detail and late-career expansion together: the 19 current battles remain playable-screen routed, all late-career records match the 16-candidate ledger, and every staff/epilogue battlefield is ready as command-caveated shared dzw data. The current 60-cycle expansion plan is complete; the next plan block is cycles 651-730 for visible late-career integration and playability.

Status through cycle 655: completed. `LateCareerGuderianPresentationCatalog` provides the Guderian-facing app catalog for the 16 late-career records while preserving the 19-battle field-command campaign as its own unchanged catalog.

Status through cycle 660: completed. The campaign view now exposes the separate Late Career Context section, including scope filters and command-caveated row labels for Inspector General, Army General Staff, and post-dismissal epilogue content.

Status through cycle 665: completed. Late-career briefing screens now reuse the shared dzw battlefield maps, objectives, forces, rules, and sources through a zoomable/scrollable Guderian map surface.

Status through cycle 670: completed. Set A late-career records route to the first DZW-style pilot surface with caveated setup metadata, force focus controls, phase controls, and log feedback; parity scoring and debrief work remains in the next cycle block.

Status through cycle 675: completed. `LateCareerPlayableSurfaceCatalog` now reports set-A scoring, debrief, persistence, AI priorities, and blocked-action expectations, and the late-career surface can record a parity debrief for those four battlefields.

Status through cycle 680: completed. Set B late-career records now route to the same DZW-style surface with General Staff caveats visible from the campaign row through the playable panel.

Status through cycle 685: completed. Set B now has parity-ready reports with AI pressure, blocked-action coverage, scoring, debrief, and persistence metadata.

Status through cycle 690: completed. Set C records now route to the late-career playable surface with caveats and AI pressure metadata.

Status through cycle 695: completed. Set C now has parity-ready scoring, debrief, persistence, AI pressure, and completion-report metadata.

Status through cycle 700: completed. Set D now routes to the caveated late-career DZW-style playable surface, including the post-dismissal epilogue records.

Status through cycle 705: completed. Set D now has final-war parity-ready reports with epilogue-aware debriefs, persistence, AI pressure, and blocked-action coverage.

Status through cycle 710: completed. The shared late-career playbook now consolidates AI priorities, blocked actions, command-caveat events, and reusable crossing, rail, fortress, withdrawal, and phase-line rule bindings across all 16 records.

Status through cycle 715: completed. Late-career context progress is now saved, loaded, summarized, reset, completed in bulk, and updated by debrief callbacks without changing the 19-battle field-command campaign progress.

Status through cycle 720: completed. GuderianTest now includes a late-career automation report and validates every context battlefield through caveats, map detail, AI pressure, scoring, persistence, rule bindings, accessibility identifiers, and debrief completion.

Status through cycle 725: completed. The late-career UX audit covers the scope filters, source-note visibility, accessibility identifiers, and final-war caveat wording needed for visible integration acceptance.

Status through cycle 730: completed. The final acceptance catalog verifies 35 selectable entries, full 19-battle campaign routing, all 16 late-career parity reports, automation, progress, UX, playbook readiness, build commands, and no blockers.

## Cycles 651-730: Visible Late-Career Integration And Playability

The cycle 650 work created detailed late-career staff/epilogue battlefield data, and cycles 651-730 now make those records visible in Guderian as a separate, explicitly caveated Late Career Context section with parity-ready playable reports, consolidated AI/rule bindings, separate progress tracking, full automation, UX polish, and acceptance. The original 19-battle field-command campaign remains intact and visually distinct from staff-influence and post-dismissal epilogue content.

| Cycles | Focus | Output |
| --- | --- | --- |
| 651-655 | Late-career app catalog | Add a Guderian-facing late-career presentation catalog that wraps the shared dzw battlefield records, preserves order, exposes command scope, and keeps the 19-battle campaign count unchanged. |
| 656-660 | Campaign UI section | Add a visible Late Career Context section to the Guderian app with row selection, command-caveat labels, scope filters, and clear separation from direct field-command battles. |
| 661-665 | Briefing and map surface | Reuse the detailed late-career maps, objectives, forces, source links, and rules in a Guderian briefing workspace with zoomable/scrollable map treatment and no duplicate data fork. |
| 666-670 | Set A playable pilot | Route Kursk, Dnieper, Korsun-Cherkassy, and Kamenets-Podolsky from the new section into the DZW-style playable surface with caveated setup metadata. |
| 671-675 | Set A parity | Add playable-screen parity, scoring hooks, debrief text, persistence records, and GuderianTest coverage for the four set-A battlefields. |
| 676-680 | Set B routing | Route Operation Bagration, Lvov-Sandomierz, Narew/Vistula bridgeheads, and Warsaw-area defensive arcs into the same late-career playable surface. |
| 681-685 | Set B parity | Add AI priorities, blocked-action expectations, scoring/debrief records, and GuderianTest coverage for the four set-B battlefields. |
| 686-690 | Set C routing | Route Vistula-Oder, Poznan corridor, East Prussia/Elbing, and Kustrin/Oder bridgeheads into the playable surface with General Staff caveats visible. |
| 691-695 | Set C parity | Add playable completion paths, AI pressure, scoring, debrief, persistence, and GuderianTest parity for the four set-C battlefields. |
| 696-700 | Set D routing | Route Operation Solstice, East Pomeranian offensive, Seelow Heights epilogue, and Berlin/Halbe epilogue with post-dismissal caveats visible for the epilogues. |
| 701-705 | Set D parity | Add playable completion paths, final-war AI pressure, epilogue debrief handling, persistence, and GuderianTest parity for the four set-D battlefields. |
| 706-710 | Late-career AI and rules | Consolidate reusable late-career AI priorities, crossing/rail/fortress/withdrawal rules, phase-line escalation, and command-caveat UI events across all 16 records. |
| 711-715 | Progress and debrief model | Extend campaign progress and completion summaries so late-career context completions are tracked separately from the 19-battle field-command campaign. |
| 716-720 | Automation and regression | Add full GuderianTest automation that opens the late-career section, runs every new battlefield to debrief, and verifies caveats, map detail, AI, scoring, and persistence. |
| 721-725 | UX polish and docs | Polish filters, accessibility labels, keyboard navigation, source-note display, final-war caveat wording, README guidance, and plan status notes. |
| 726-730 | Acceptance and builds | Run full SwiftPM and Xcode acceptance, verify the 19-battle campaign remains unchanged, verify all 16 late-career battlefields are visible and playable, and update ship-readiness reporting. |

Status through cycle 730: completed. Guderian shows 35 total selectable battle/context entries: 19 field-command campaign battles plus 16 visibly caveated late-career context battlefields, all with DZW-style playable-screen coverage, separate completion tracking, GuderianTest automation, UX audit coverage, and final acceptance reporting.

## Cycles 731-830: Unified 35-Battle Playable Campaign

The cycle 730 state still preserves a product distinction between the original 19 field-command campaign battles and the 16 late-career staff/epilogue battlefields. Cycles 731-830 remove that distinction from the playable UI. The target is one campaign-facing battle experience: every selectable entry opens the same DZW-style board, uses the same command affordances, supports the same AI/debrief/persistence loop, and is verified by the same playable-screen harness. The only retained difference is historical framing: Inspector General, Army General Staff, adjacent-pressure, and post-dismissal caveats stay visible in briefing/source context, but they must not create a separate gameplay tier.

| Cycles | Focus | Output |
| --- | --- | --- |
| 731-735 | Unified acceptance bar | Define the 35-battle parity requirement, retire the separate late-career pilot surface as an acceptance target, lock caveat placement to briefing/source labels, and document that all battles must share the same board, controls, AI, logs, blocked-action feedback, debrief, and persistence path. |
| 736-740 | Unified battle identity | Add a battle-selection identity that can address both `GuderianBattleID` campaign battles and late-career battlefield IDs without forcing two UI sections, two navigation paths, or two progress concepts at the playable-screen boundary. |
| 741-745 | Late-career board adapter | Convert `LateCareerStaffBattlefield` maps, objectives, forces, rules, source notes, and command-caveat metadata into the same native battle-instance shape used by the first 19 battles. |
| 746-750 | Late-career session loader | Add a `NativeBoardSession` creation path for late-career entries with deterministic seeds, board terrain, objectives, mission target score, deployment zones, unit ownership, and scenario metadata. |
| 751-755 | Unified campaign list | Replace the visible split between `Scenarios` and `Late Career Context` with one campaign list or one visually identical grouped list where all rows use the same play affordance, completion state, and navigation treatment. |
| 756-760 | Shared briefing shell | Move late-career entries into the same pre-battle briefing shell used by the 19 original battles, preserving caveats as concise historical labels while removing separate context-only copy and pilot-specific wording. |
| 761-765 | Set A board parity | Route Kursk, Dnieper, Korsun-Cherkassy, and Kamenets-Podolsky into `DZWPlayableBattleView` with selectable units, draggable movement, phase controls, combat actions, legal-action blocking, logs, AI pressure, and debrief persistence. |
| 766-770 | Set B board parity | Route Operation Bagration, Lvov-Sandomierz, Narew/Vistula bridgeheads, and Warsaw defensive arcs into the same battle screen with General Staff caveats retained only as historical context labels. |
| 771-775 | Set C board parity | Route Vistula-Oder, Poznan corridor, East Prussia/Elbing, and Kustrin/Oder bridgeheads into the same commandable battle screen with scenario-specific terrain, objectives, units, and German pressure. |
| 776-780 | Set D board parity | Route Operation Solstice, East Pomeranian offensive, Seelow Heights, and Berlin/Halbe into the same commandable battle screen, with post-dismissal epilogue caveats visible but not changing the UI tier. |
| 781-785 | Unified AI execution | Replace late-career metadata-only AI with live board AI execution that chooses priorities from scenario objectives, moves units through legal board actions, reports blocked moves, and uses the same German-turn runner as the first 19 battles. |
| 786-790 | Unified scoring and debrief | Convert late-career scoring/debrief records to the same completion resolver pattern used by the 19 battles, including score bands, completed turn, debrief text, persistence keys, and failure handling. |
| 791-795 | Progress unification | Present all 35 completions through one campaign progress summary, while preserving filters and historical scope labels as optional views rather than separate progress systems. |
| 796-800 | Save/load migration | Migrate existing separate campaign and late-career save payloads into a unified save envelope that can read old progress, write the new 35-battle progress model, and avoid losing prior completions. |
| 801-805 | Harness expansion | Expand `DZWPlayableScreenHarness` or a successor harness so every one of the 35 battles runs launch, selection, movement, phase flow, attack, blocked-action feedback, AI turn, debrief, and persistence through the same assertions. |
| 806-810 | UI parity audit | Add tests and visual/identifier audits proving there is no remaining pilot-only late-career surface, no separate lighter gameplay path, and no row-level affordance difference beyond historical caveat labels. |
| 811-815 | Balance and pacing pass | Tune late-career board starts, objective spacing, unit mobility, terrain density, victory bands, and AI pressure so the new 16 battles feel as playable and legible as the first 19. |
| 816-820 | Documentation cleanup | Update README, PLAN status notes, source/caveat language, and in-app labels to describe a unified 35-battle playable campaign. Expand the README Battle Chronology from 19 to all 35 selectable battles with the same historical-link treatment, dates, command-scope caveats, opposing-force notes, results, and scenario design notes used by the first 19 battles. |
| 821-825 | Build and regression hardening | Run SwiftPM, Xcode, GuderianTest, full 35-battle automation, save/load migration tests, and targeted UI checks; fix blockers surfaced by late-career board parity. |
| 826-830 | Unified campaign acceptance | Ship the acceptance gate for a single 35-battle playable campaign: all battles look and play through the same UI, all complete from board launch to debrief/persistence, README lists all 35 battles with historical links, caveats remain historical only, and no separate late-career gameplay tier remains. |

Status through cycle 810: completed. The unified acceptance bar, 35-battle identity catalog, native late-career board adapter/session loader, unified campaign list, shared briefing shell, all 16 late-career playable-board routes, live late-career German AI execution, unified scoring/debrief resolver, unified progress/save migration, full 35-battle harness, and UI parity audit are in place with regression coverage.

Status through cycle 815: completed. `UnifiedBalancePacingAuditCatalog` checks the 16 added battles for readable board starts, objective spacing, terrain density, mobility variety, victory bands, and live German AI pressure against the first-19 playable baseline.

Status through cycle 820: completed. The README Battle Chronology lists all 35 selectable battles with historical links, dates, command-scope caveats, opposing-force notes, results, and scenario design notes, and the app progress/status controls describe one unified 35-battle campaign rather than an added-battles tier.

Status through cycle 825: completed. `UnifiedBuildRegressionHardeningCatalog` captures the SwiftPM, GuderianTest, Xcode, 35-battle harness, save/load migration, UI parity, documentation, and balance/pacing regression gates.

Status through cycle 930: complete. The corrected real DZW UI parity work is done, and both tutorial interfaces are implemented: first-run historical onboarding plus first-battle contextual guidance with versioned dismissal and reusable tutorial acceptance.

## Cycles 831-890: Real DZW UI Parity And Debt Retirement

The cycle 830 correction narrows the acceptance bar: battles 20-35 must render in the actual DZW-style battle screen used by battles 1-19, or in a shared generalized successor whose view model and interaction controls are the same implementation. Matching accessibility identifiers, catalog flags, or static map surfaces do not count. The player-visible standard is the battle 1-19 experience: the proper board, terrain zones, objectives, selectable units, draggable movement, phase controls, shooting, assaults, pending choices, live log, German AI turn runner, debrief, and persistence.

Known technical debt covered by this block:

- Battles 20-35 route to `LateCareerUnifiedPlayableBoardView` / `LateCareerMapSurface`, not the real DZW board view.
- `DZWPlayableBattleViewModel` is scenario-centric and needs a battle-source abstraction that can load either `GuderianScenario` or late-career native loadouts.
- Late-career sessions are rebuilt through report helpers instead of being held as a live UI session.
- Tests assert identifiers/catalog readiness instead of proving the same view, renderer, board session, and interactions are used.
- Acceptance catalogs and README/PLAN language overstate UI parity and need corrected gates.
- GuderianTest needs to exercise battles 20-35 through the real shared playable view path, not only automation metadata.

| Cycles | Focus | Output |
| --- | --- | --- |
| 831-835 | Corrected acceptance bar | Replace cycle-830 parity wording with a hard requirement that battles 20-35 instantiate the same playable battle implementation as battles 1-19. Add failing tests that detect `LateCareerMapSurface`/`LateCareerUnifiedPlayableBoardView` usage for selectable battles. |
| 836-840 | Shared battle source model | Introduce a unified playable battle source/loadout abstraction that can represent original `GuderianScenario` battles and late-career native battles without branching into separate UI surfaces. |
| 841-845 | Late-career live board session bridge | Expose battles 20-35 through a live board-session API with persistent selected unit, selected target, movement, shooting, assault, pending-choice, phase, mission, log, and completion state instead of per-action regenerated reports. |
| 846-850 | Generalized DZW view model | Refactor `DZWPlayableBattleViewModel` so it consumes the shared battle source and live board session. Preserve battle 1-19 behavior while adding 20-35 as first-class inputs. |
| 851-855 | Shared board rendering parity | Render battles 20-35 through the same DZW board renderer, terrain overlay, unit markers, objective markers, selection affordances, drag gestures, active-unit sidebar, and action controls used by battles 1-19. |
| 856-860 | Route set A/B through real view | Route battles 20-27 into the generalized `DZWPlayableBattleView` path and remove their dependency on `LateCareerUnifiedPlayableBoardView` for playable launch. |
| 861-865 | Route set C/D through real view | Route battles 28-35 into the generalized `DZWPlayableBattleView` path, including post-dismissal caveat labels as briefing/source context only. |
| 866-870 | Remove duplicate playable surface | Delete or demote the late-career playable map surface to briefing-only usage. Ensure campaign navigation has one playable destination implementation for all 35 battles. |
| 871-875 | Real interaction regression | Add tests that drive battles 20-35 through unit selection, legal drag movement, phase advancement, shooting/assault attempts, pending-choice resolution, blocked-action feedback, German AI turn, debrief, and persistence using the shared view model. |
| 876-880 | Visual parity verification | Add screenshot or view-inspection checks that compare battle 20-35 screens against the battle 1-19 board/sidebar/control structure, proving the proper board is visible and not the late-career map surface. |
| 881-885 | GuderianTest and save/load hardening | Update GuderianTest to open representative battles from all 35 through the real shared UI path, then verify unified save/load migration and completions still work after the view-model refactor. |
| 886-890 | Final corrected acceptance | Ship a corrected final gate: all 35 battles use the same real playable UI implementation, the old metadata-only acceptance is retired, docs are corrected, tests/builds pass, and no known UI/playability technical debt remains. |

Status through cycle 890: complete. This block covers the known technical debt behind the 20-35 UI/playability mismatch: the scenario-only view model, the late-career-only playable surface, regenerated report helpers in place of a live UI session, metadata-only parity checks, stale acceptance wording, and the missing regression gate for the real shared DZW board path. No additional UI/playability debt is currently known from this pass; future cycles should only be needed for newly discovered engine limitations or visual polish beyond the shared DZW board contract.

## Cycles 891-930: Tutorial Onboarding And Reusable Guidance System

This block adds two player-facing tutorials while building the reusable tutorial layer that future `gzw` games can carry forward. The system should separate data from presentation: tutorial IDs, pages, hint triggers, dismissal state, copy, and analytics/test events live in a small shared model, while Guderian-specific history text and first-battle hints live in catalog data. The first-run tutorial appears the first time the app is launched unless its versioned dismissal flag is set. The first-battle tutorial appears only in the first battle flow and gives contextual help as the player reaches teachable moments. Both tutorials end with a checkbox labeled exactly `Do not show again`.

Technical requirements:

- Add a reusable tutorial domain model, likely in `GuderianCore`, with `TutorialFlow`, `TutorialPage`, `TutorialHint`, `TutorialTrigger`, `TutorialDismissalPolicy`, `TutorialProgress`, and `TutorialStorageKey` concepts.
- Keep UI reusable in `GuderianApp`: a paged modal/sheet for historical tutorials and a non-blocking battle hint surface for contextual gameplay tips.
- Version dismissal state so future tutorial rewrites can opt into showing again only when intentionally bumped.
- Store tutorial preferences separately from campaign completion so a player can reset campaign progress without unexpectedly resetting tutorial choices, while still exposing debug/test reset hooks.
- Use `@AppStorage` or the existing save-envelope settings layer only behind an abstraction so future games can swap storage without changing tutorial UI.
- First-run historical tutorial must contain four screens, about 100 words each, covering Guderian's historical role, the default opposing-force perspective, the side-selected command-study caveat, the reason these battles are modeled, and why memorialization should be sober rather than celebratory.
- First-battle tutorial should target the first chronological battle and trigger hints for orientation, selected-side unit control, reading objectives, dragging movement, advancing phases, shooting/assault timing, resolving blocked actions, letting the opposing AI act, and debrief/persistence.
- Do not change `dzw` engine rules for tutorials. Tutorials are presentation/control guidance only.
- Tutorial UI must not obscure critical board controls on small windows; hints need dismissal/next behavior, keyboard accessibility, and stable identifiers for tests.
- GuderianTest and Swift tests must prove first-run gating, "Do not show again" persistence, first-battle trigger ordering, reset/debug behavior, and that tutorials do not affect battle completion.

| Cycles | Focus | Output |
| --- | --- | --- |
| 891-895 | Reusable tutorial model | Introduce the tutorial data model, versioned IDs, dismissal policies, trigger vocabulary, progress state, and storage abstraction. Define reusable keys for `firstRunHistory` and `firstBattleGuidance` without hard-coding UI state into campaign progress. |
| 896-900 | Historical tutorial content | Draft and catalog four first-run pages of about 100 words each. Cover Guderian's career, the default opposing-force role, side-selected command-study play, why the battles are modeled, and the importance of historical memorialization with sober language. Add copy-length and required-topic tests. |
| 901-905 | First-run tutorial UI | Build the paged first-run tutorial interface with title, page progress, back/next/finish controls, readable layout, accessibility identifiers, and a final-page `Do not show again` checkbox. Ensure it opens on first launch only when not dismissed. |
| 906-910 | First-run persistence and reset | Wire the first-run tutorial to the storage abstraction, versioned dismissal flag, app launch gate, debug reset hook, and tests for first launch, dismissed launch, and version-bump behavior. |
| 911-915 | First-battle hint catalog | Define the first-battle tutorial triggers and hint copy for orientation, selected-side unit control, objectives, movement, phase flow, blocked actions, shooting, assault, opposing AI turn, and debrief. Make hints data-driven so future games can replace content without rewriting the UI. |
| 916-920 | Battle tutorial integration | Integrate the hint coordinator into `DZWPlayableBattleView` for the first chronological battle only. Track live board events without altering legal actions, AI behavior, completion scoring, or the shared 35-battle UI parity path. |
| 921-925 | Battle tutorial UI and dismissal | Build the contextual hint surface with next/dismiss controls, placement that avoids board/control occlusion, keyboard accessibility, stable test identifiers, and a final `Do not show again` checkbox that suppresses future first-battle tutorial runs. |
| 926-930 | Reuse hardening and acceptance | Add reusable tutorial acceptance catalogs, GuderianTest coverage, save/settings regression checks, README/PLAN updates, and final gates proving both tutorials work, persist, reset, and leave normal battle play unaffected. |

Status through cycle 930: complete. The reusable tutorial model, first-run history copy, first-run tutorial sheet, first-battle hint catalog, live first-battle trigger integration, contextual hint UI, final `Do not show again` dismissal, README/PLAN updates, and acceptance tests are in place. No cycles remain for this tutorial block. No engine technical debt is expected from this pass because tutorials remain presentation/control guidance and do not alter `dzw` rules, AI behavior, scoring, debriefs, or campaign persistence.

## Cycles 931-960: GuderianTest First-Battle Autoplay Replacement

This block replaces the current `GuderianTest` campaign diagnostics dashboard with a real first-battle autoplay application. The new target should be based on the same Guderian code path that a player uses: Tuchola Forest opens through the real DZW-style battle surface, the native board session remains live, the battle advances through movement, shooting, assault, pending-choice resolution, German AI phases, debrief, and campaign completion handling, and the final screen clearly reports either a player victory band or a loss to Guderian's AI.

The replacement should not keep the old two-window dashboard as the primary test experience. Campaign-wide automation can survive only as lower-level regression helpers if still useful; the product-facing `GuderianTest` app should become a focused visual autoplay harness for the first chronological battle.

Technical requirements:

- `GuderianTest` launches a single window centered on Tuchola Forest, not the full campaign list plus a separate diagnostics report dashboard.
- The test app reuses the same `DZWPlayableBattleView`, `NativeBoardSession`, board renderer, controls, completion resolver, and persistence path used by `Guderian`.
- Any currently private battle-running state that `GuderianTest` needs should be extracted into reusable app/core types instead of copied into the test target.
- The automated human-side controller uses the default opposing-force lens, chooses legal active units, prioritizes Tuchola delay and withdrawal objectives, moves defensively or toward score targets, shoots nearest meaningful threats, resolves assaults/pending choices, and records blocked actions.
- The German side continues to use the existing German AI turn behavior and scenario priority targets.
- The battle must continue until the native mission winner, a debriefable completion state, or a documented safety failure. A normal run should produce a completion record that represents either victory or loss, not a synthetic pass marker.
- The UI should make the run observable: current turn/phase, active side, last action, step count, player/German action counts, score, winner, victory band, debrief text, and a concise event log.
- Tests must prove both sides received active phases, the real battle screen is used, a debrief/persistence record is produced, and the old dashboard is no longer the primary `GuderianTest` surface.

| Cycles | Focus | Output |
| --- | --- | --- |
| 931-935 | Replacement acceptance and app shell | Define the new `GuderianTest` contract, remove the old two-window campaign dashboard from the primary app flow, and create a single-window first-battle test shell that loads Tuchola Forest by default. Add failing acceptance tests that assert the old dashboard is not the launch surface. |
| 936-940 | Shared battle-run controller extraction | Extract the reusable session/action/debrief pieces currently embedded in `DZWPlayableBattleViewModel` into shared app/core types that both `Guderian` and `GuderianTest` can consume. Preserve the existing player-facing battle behavior while making the live run state observable to the test target. |
| 941-945 | First-battle run model | Build the `GuderianTest` run model around a live Tuchola `NativeBoardSession`, with published snapshot, run state, step log, counters, errors, score, winner, and completion display. Support start, pause, step, resume, restart, and deterministic seed control without bypassing legal board actions. |
| 946-950 | Automated human player | Implement the anti-Guderian automated human controller for movement, shooting, assault, and pending-choice phases. Its priorities should reflect Tuchola Forest: delay Brda crossings, contest Chojnice/Tuchola road hubs, protect withdrawal routes, preserve units when possible, and fall back to nearest legal objective when a priority move is blocked. |
| 951-955 | Full autoplay loop and result UI | Wire the automated human player and German AI into a continuous visible autoplay loop with speed controls, safety caps, live phase updates, recent-action log, and final result panel. The loop should stop on a real winner/debriefable state and show victory/loss, score, victory band, completed turn, and debrief summary. |
| 956-960 | Cleanup, tests, and acceptance | Remove or demote obsolete dashboard-only UI, update GuderianTest tests to exercise the real first-battle autoplay surface, verify debrief persistence and both-side participation, keep campaign-wide helpers only where regression tests still need them, update README/PLAN notes, and run SwiftPM/Xcode build and test gates. |

Status through cycle 950: completed. The replacement acceptance contract, single-window `GuderianTest` shell, public `DZWPlayableBattleView` entry point, first-battle stepped run controller, Tuchola native-session bootstrap, pause/resume/step state, automated human-player priorities, debrief persistence report, and regression tests for dashboard retirement plus both-side stepped autoplay are in place. The next implementation block is cycles 951-955: add the remaining visible autoplay polish, including speed control and tighter live result presentation.

Status through cycle 960: completed. `GuderianTest` is now a focused first-battle autoplay app rather than the old campaign diagnostics dashboard. It launches Tuchola Forest through the real `DZWPlayableBattleView`, runs a deterministic legal-action native board loop for the anti-Guderian player and German AI, exposes observable speed/safety/log/result controls, records a real debriefable victory or loss, persists the completion, and has no remaining cycles in this replacement block.

Acceptance for cycle 960: `GuderianTest` is no longer a campaign diagnostics dashboard. It is a first-battle autoplay app that uses the same playable battle implementation as `Guderian`, visibly plays Tuchola Forest through legal board phases with an automated human opponent and German AI, and ends with a real debriefable victory or loss record.

## Cycles 961-1080: REVIEW.md Local Hardening

This block implements every item in `REVIEW.md` as local Guderian hardening. The work is intentionally scoped to the `guderian` checkout and its embedded `dzw` package. Do not make matching edits in the sibling `derZweiteWeltkrieg` checkout during this block; upstreaming or back-porting can be planned separately after the local Guderian version is complete and verified.

The goal is not only to make the review comments disappear, but to retire the underlying maintenance risks: duplicated engine constants, production acceptance gates, repeated terrain classification logic, stringly typed IDs and stages, stale save keys, weak persistence coverage, manual window coordination fragility, and unclear ownership boundaries between Guderian-specific scenario data and reusable `dzw` engine/app code.

Technical requirements:

- Keep all edits local to `/Users/barbalet/github/guderian`, including `/Users/barbalet/github/guderian/dzw` where engine/app package changes are needed.
- Preserve the current 35-battle playable surface, GuderianTest autoplay behavior, save compatibility, and tutorial dismissal behavior while refactoring.
- Move cycle-gate and acceptance readiness assertions out of production catalog bodies and into test-only helpers or tests.
- Use typed models where the review identifies stringly typed IDs or stages, but keep Codable compatibility through explicit migration or compatibility initializers where saved data may exist.
- Prefer small, reviewable refactors for mechanical cleanups; isolate architectural changes so each one has tests and a clear fallback path.
- Treat `HEINZ_GUDERIAN_GAME` and the `DerZweiteWeltkriegGuderian` ownership boundary as local integration contracts during this block, not as upstream API commitments.
- Add or update tests for changed contracts, especially campaign progress persistence, tutorial progression, automation stage typing, board dimensions, and battle UI routing.
- Run SwiftPM and Xcode build/test gates at the end of the block and record any intentionally deferred upstream work separately.

| Cycles | Focus | Output |
| --- | --- | --- |
| 961-965 | Review inventory and local scope gate | Convert the 30 `REVIEW.md` items into a tracked local checklist, identify owning modules/files, add a test-only acceptance scaffold for review completion, and document that this block does not modify the sibling `derZweiteWeltkrieg` checkout. |
| 966-970 | Board dimensions and engine define documentation | Expose the C board dimensions through the public C header or a thin Swift boundary, replace duplicated Swift literals in `GameController` and Guderian battle views, and document the local `HEINZ_GUDERIAN_GAME` hook plus guarded symbols. |
| 971-975 | Scenario map classification cleanup | Replace repeated `ScenarioMapElementKind` predicate switches with static membership sets, resolve the `.marsh` water/ground overlap with a documented canonical category, and add tests proving terrain classification behavior. |
| 976-980 | Static catalog caching | Convert `UnifiedGuderianBattleCatalog.allEntries`, field-command/late-career entry lists, `ScenarioContentCatalog.allBundles`, and similar compile-time catalogs to cached `static let` storage where safe. Add regression tests for ordering and count stability. |
| 981-985 | Tutorial model deduplication | Introduce shared `TutorialContent` behavior for pages and hints, remove duplicate word/topic logic, and preserve copy-length/required-topic tests for both first-run and first-battle tutorials. |
| 986-990 | Tutorial flow and hint ID cleanup | Remove `firstBattleGuidanceFlowStub`, replace practical string-keyed tutorial/hint IDs with typed IDs or typed builders, and keep persistence keys stable through explicit raw values. |
| 991-995 | Acceptance gates move to tests | Move `acceptanceReadyThroughCycle...`, `cycleRange` gate checks, and review-only validation out of production enum bodies into test target helpers. Keep production catalogs focused on shipping data and behavior. |
| 996-1000 | Presentation constants and filter titles | Name hardcoded battlefield/map colors in palette constants or assets, replace the `LateCareerScopeFilter.title` switch with a raw-value or lookup approach, and extract `ScenarioMapView` grid dimensions to named constants. |
| 1001-1005 | Playable board session API cleanup | Remove the `playableBoardSnapshot()` rename wrapper by aligning the protocol with `snapshot()` or adding a useful default implementation, and adjust field-command and late-career sessions without changing battle behavior. |
| 1006-1010 | Late-career lookup and tutorial event state | Replace `LateCareerPlayableSet.set(for:)` linear scans with a cached dictionary, deduplicate `TutorialHintCoordinator.triggeredHintIDs` and event tracking, and preserve active-hint ordering tests. |
| 1011-1015 | Unified battle ID typed storage | Refactor `UnifiedGuderianBattleID` so field-command IDs retain `GuderianBattleID` typed storage while late-career IDs keep string-backed storage. Preserve `Codable`, `Hashable`, navigation identity, and saved route compatibility. |
| 1016-1020 | Campaign save key consolidation | Add a one-time migration path from the v1 campaign save key to the unified v2 save key, remove stale active use of the v1 key after migration, and test legacy, unified, and empty-save launches. |
| 1021-1025 | Campaign progress persistence tests | Add focused unit tests for `CampaignProgress`, `LateCareerProgress`, unified progress wrapping, encode/decode round trips, battle ordering, completion summaries, and edge cases around missing or future scenario IDs. |
| 1026-1030 | Automation stage typing | Add a `CampaignAutomationStage` enum for `CampaignAutomationStep` and `CampaignAutomationIssue`, provide compatibility for existing string stage data, and update automation/report tests to use exhaustive typed stages. |
| 1031-1035 | `@discardableResult` and runner diagnostics | Reduce unnecessary `@discardableResult` use where callers should observe failures, and add explicit assertions or warnings in automation and AI runners when expected actions return `false`. |
| 1036-1040 | `GameController` sendability and state audit | Add appropriate `Sendable` conformance or isolation annotations to `GameController`, then audit published setup/loaded/selection state for values that can be derived safely from C snapshots without breaking SwiftUI updates. |
| 1041-1045 | `GameController` state reduction | Introduce a smaller setup/selection state model or derived accessors for player army IDs, force indices, selected unit, and selected target where practical. Add tests or UI regression coverage around setup, skirmish launch, and reload reconciliation. |
| 1046-1050 | Local module boundary decision | Clarify whether `DerZweiteWeltkriegGuderian` remains embedded in local `dzw` as a Guderian content module or whether selected data should move into top-level `GuderianCore`. Implement the local decision with package comments and import cleanup. |
| 1051-1055 | Guderian-specific module ownership cleanup | If the cycle-1050 decision moves content, migrate the chosen scenario data/APIs and update package dependencies. If it formalizes the existing boundary, add documentation and tests proving reusable `dzw` code is not silently depending on Guderian-only app state. |
| 1056-1060 | German AI plan honesty or execution bridge | Decide whether `GermanAIPlan` should become executable input or be renamed to `GermanAIBriefing`. Prefer the smallest truthful change unless executable behavior is ready; update catalogs, runners, UI copy, and tests accordingly. |
| 1061-1065 | Scenario map renderable visibility and file hygiene | Make `ScenarioMapRenderable` public/co-located where its conforming types live or move the abstraction into `GuderianCore`, add a short rationale for `GuderianCore.swift` re-exports or remove them, and rename `BattlefieldWorkspace.swift` to match `BattlefieldViewport`. |
| 1066-1070 | Debug logging and window coordinator hardening | Guard `logDZWWindowSnapshot` with `#if DEBUG`, then reduce fragility in `BattleShellWindowCoordinator` and the Guderian playable panel coordinator with clearer identity/state handling or a SwiftUI-native routing step where feasible. |
| 1071-1075 | Window routing architecture follow-through | Complete the practical window/panel cleanup chosen in cycles 1066-1070, preserving battle panel behavior, sidebars, logs, inspectors, and small-window tutorial placement. Add UI or coordinator tests where available. |
| 1076-1080 | Final review closure | Re-run the full `REVIEW.md` checklist, update README/PLAN notes, run SwiftPM tests and Xcode build/test gates, verify no sibling `derZweiteWeltkrieg` files changed, and record any future upstream/back-port recommendation outside this local block. |

Status through cycle 980: completed. The `REVIEW.md` local-hardening checklist now tracks all 30 review items in the test target with local-only ownership and target cycles. The C engine exposes `game_board_width()` and `game_board_height()`, and both the embedded `dzw` app controller and Guderian playable battle view read those values instead of duplicating `72x48` literals. The README documents the current `HEINZ_GUDERIAN_GAME` guarded symbols. `ScenarioMapElementKind` now uses static feature sets, with `.marsh` canonicalized as difficult ground rather than a waterway. Unified battle entries, late-career presentation entries, and scenario content bundles are cached static data with regression coverage for ordering, counts, and bundle lookup. `swift test` passes after these changes.

Status through cycle 1000: completed. Tutorial pages and hints now share the `TutorialContent` protocol for word counts and required-topic checks. The redundant `firstBattleGuidanceFlowStub` is removed, and first-battle hint IDs now come from typed `FirstBattleGuidanceHintID` cases while preserving their existing raw string values for persistence. The review-targeted `acceptanceReadyThroughCycle740`, `acceptanceReadyThroughCycle910`, `acceptanceReadyThroughCycle930`, and tutorial acceptance report logic have moved out of production code and into the test target. The battlefield and scenario-map background colors are named in `GuderianAppPalette`, `LateCareerScopeFilter.title` now derives from user-readable raw values, and `ScenarioMapView` uses named grid constants. `swift test` passes after these changes.

Status through cycle 1020: completed. The shared playable-board protocol now uses `snapshot()` directly, `LateCareerNativeBoardSession` exposes the full `NativeBoardSnapshot` through that same name, and its old late-career summary shape is renamed to `lateCareerSnapshot()`. `LateCareerPlayableSet.set(for:)` now uses a cached lookup table. `TutorialHintCoordinator.triggeredHintIDs` is derived from recorded events, with decode compatibility for older stored triggered-ID data. `UnifiedGuderianBattleID` now stores field-command cases as typed `GuderianBattleID` values and keeps late-career cases string-backed while preserving the existing Codable shape. `GuderianCampaignView` no longer writes the legacy v1 campaign save key; it migrates legacy data through the unified v2 envelope and clears the stale key after successful migration. Review-local tests cover the API cleanup, lookup index, derived tutorial state, typed IDs, and legacy save migration. `swift test` passes after these changes.

Status through cycle 1040: completed. Focused persistence tests now cover `CampaignProgress`, `LateCareerProgress`, unified progress wrapping, encode/decode round trips, completion summaries, empty unified-save launches, and future/unknown ID rejection. `CampaignAutomationStep.stage` and `CampaignAutomationIssue.stage` now use the typed `CampaignAutomationStage` model, including dynamic turn-phase stages and legacy string decoding for saved/report payload compatibility. The playable-test AI runner no longer marks no-op "No legal..." actions as succeeded, campaign automation phase probes surface zero-action phases as warnings, and the visible battle view records/logs failed board actions instead of silently discarding result values. `GameController` is explicitly `@unchecked Sendable` under its `@MainActor` isolation and now groups loaded army/force state into a small `GameControllerLoadedForceState` snapshot while preserving existing computed accessors. `swift test` passes after these changes.

Status through cycle 1060: completed. `GameController` now groups setup army/force IDs and board selection IDs into `GameControllerSetupSelectionState` and `GameControllerBoardSelectionState`, with compatibility accessors preserving the existing SwiftUI bindings and setup/skirmish flows. The local module boundary decision is formalized: `DerZweiteWeltkriegGuderian` remains the embedded local Guderian content module, documented in the embedded package manifest and backed by `GuderianModuleBoundaryContract`; tests verify the reusable `DerZweiteWeltkriegCore` sources do not import Guderian content or app targets. `GermanAIPlan` now declares `executionMode`, decodes older payloads without that key, and exposes phase-specific `targetPriorities(for:)` so the native autoplay runners consume the plan as executable target-priority input rather than treating it as narrative-only copy. The campaign UI also surfaces the execution mode in the AI plan panel. Review-local tests cover the controller state snapshots, module boundary, reusable-core import hygiene, and executable German AI plan contract. `swift test` passes after these changes.

Status through cycle 1080: completed. `ScenarioMapRenderable` is now a public `GuderianCore` protocol with co-located conformances for field-command and late-career map models, while `ScenarioMapView` only renders that contract. `GuderianCore.swift` now documents its deliberate re-export role, and `BattlefieldWorkspace.swift` has been renamed to `BattlefieldViewport.swift` with the Xcode project reference updated. `logDZWWindowSnapshot` is compiled only for debug builds, and both battle panel coordinators now use stable `NSUserInterfaceItemIdentifier` values plus the existing panel-to-window map instead of a parallel `ObjectIdentifier` lookup table. The final review-local tests verify file hygiene, public map renderability, debug-only diagnostics, hardened panel routing, README/PLAN closure notes, and all 30 checklist items. The `REVIEW.md` local hardening block is complete through cycle 1080; future work is limited to optional upstream/back-port planning for the sibling `derZweiteWeltkrieg` repository.

Acceptance for cycle 1080: every numbered item in `REVIEW.md` has either been implemented locally in `guderian`/embedded `dzw` or closed with an explicit code comment/test-backed rationale inside this block. The sibling `derZweiteWeltkrieg` checkout remains untouched by the implementation work, the 35-battle playable campaign and `GuderianTest` autoplay behavior still pass their gates, and the local `dzw` version is cleaner, more typed, and easier to maintain.

## Acceptance Criteria

- `dzw` remains cleanly updatable because Guderian-specific engine hooks are guarded or externalized.
- The demo ships with Wizna, Sedan, and Moscow/Tula playable from briefing to debrief.
- The full campaign ships with every battle in the README chronology playable.
- The README Battle Chronology lists all 35 selectable battles with historical links, dates, command-scope labels/caveats, opposing-force notes, results, and scenario design notes.
- Every battle has source links, scenario notes, force data, objectives, balance status, and test coverage.
- Existing and future maps hit the 400% detail-improvement target through denser sourceable geography rather than decorative markers.
- Late-career battlefields after Guderian's 1941 dismissal are framed as Inspector General, Army General Staff, or post-dismissal context unless direct field command is proven.
- All 35 selectable Guderian battles use the same visual and interactive playable-battle UI implementation; command-scope caveats may appear as historical labels, but they must not create a separate or reduced playability mode.
- For battles 20-35, acceptance requires the real `DZWPlayableBattleView` path or a shared generalized successor with the same board renderer, view model, controls, gestures, session state, and interaction behavior as battles 1-19. `LateCareerMapSurface`, matching accessibility identifiers, catalog flags, and metadata-only harnesses do not satisfy playable UI parity.
- Visual parity tests must prove battles 20-35 show the proper board/sidebar/control structure, not a briefing map or late-career-only surface.
- The first-run historical tutorial appears on initial launch, contains four approximately 100-word screens, ends with `Do not show again`, and stays dismissed on later launches when that checkbox is selected.
- The first-battle tutorial provides contextual movement, strategy, phase, combat, AI-turn, blocked-action, and debrief hints during the first game, ends with `Do not show again`, and stays dismissed for future first-battle runs when selected.
- Tutorial models, trigger definitions, dismissal policies, and storage contracts are reusable enough for future `gzw` games to adopt without carrying Guderian-specific copy.
- The app clearly frames the default opposing-force lens and optional Guderian command-study lens with sober historical context.
- "Playable" means a DZW-style hand-playable Guderian battle screen with scenario-specific units, terrain, objectives, legal actions, scoring, AI pressure, blocked-action reporting, logs, and debriefs; proxy-loadable metadata or automation-only completion no longer satisfies the playable milestone.
