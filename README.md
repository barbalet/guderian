# guderian

`guderian` is a macOS World War II wargame project about opposing Heinz Guderian's field commands. The player is always the force resisting, delaying, escaping, or counterattacking Guderian's formations rather than commanding them.

The intended stack is a macOS game using SwiftUI, Metal, and a C rules core. The project is based on the included `dzw` (`derZweiteWeltkrieg`) engine, which should be treated as read-only unless a Guderian-specific hook is guarded by:

```c
#define HEINZ_GUDERIAN_GAME
```

That define is enabled only for the Guderian workspace/package path so upstream `dzw` development is not affected.

## Included Engine Review

The `dzw` directory is a complete playable World War II skirmish engine and app:

- C rules engine: `dzw/Sources/DerZweiteWeltkriegCore`
- SwiftUI shell: `dzw/Sources/DerZweiteWeltkriegApp`
- Swift tests: `dzw/Tests/DerZweiteWeltkriegTests`
- Existing engine roadmap and rules notes: `dzw/docs/wwii_development_roadmap.md`, `dzw/docs/engine_strategy.md`
- Existing data ledgers: `dzw/docs/wwii_demo_scope.md`, `dzw/docs/wwii_unit_profiles.md`, `dzw/docs/wwii_weapon_taxonomy.md`, `dzw/docs/wwii_armor_profiles.md`, `dzw/docs/wwii_battlefield_profiles.md`

Useful inherited scope from `dzw`:

- Allies/Axis nation selection for British, American, Australian, Soviet, German, and Italian forces.
- Objective missions, turn phases, movement, shooting, morale, pinning, assaults, artillery, transports, mounted fire arcs, vehicle damage, hull-down, smoke, and victory scoring.
- A SwiftUI setup/board/sidebar flow backed by C snapshots, which is a good fit for adding historical scenarios without duplicating rules in the UI.

Guderian-specific work should mostly add campaign data, scenario maps, app identity, opponent AI, and historical presentation around this engine. Engine changes should be rare, guarded, and documented.

## Historical Scope

Wikipedia was used as the initial open research shelf for [Heinz Guderian](https://en.wikipedia.org/wiki/Heinz_Guderian)'s World War II field-command battles. The playable campaign should prioritize battles where Guderian commanded XIX Army Corps, Panzergruppe Guderian, 2nd Panzer Group, or 2nd Panzer Army. Later staff positions, including Inspector General of Armoured Troops and acting Chief of the Army General Staff, are historical context rather than direct battlefield command scenarios.

The game should avoid celebratory framing. Guderian was a senior Nazi German commander; the player-facing fantasy is resistance against his offensives, and the historical notes should acknowledge the wider criminal context of the Wehrmacht where relevant.

## Battle Chronology

| Order | Date | Battle / Operation | Guderian Command | Opposing Force For Player | Result | Scenario Design Notes |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1-5 Sep 1939 | [Battle of Tuchola Forest](https://en.wikipedia.org/wiki/Battle_of_Tuchola_Forest) | XIX Panzer Corps under 4th Army | Polish Pomeranian Army elements in the Polish Corridor | German victory | First full-campaign expansion scenario. Player blocks Brda crossings, disrupts Chojnice-Tuchola pursuit, uses Krojanty cavalry screening, and withdraws assets toward Bydgoszcz before encirclement. |
| 2 | 7-10 Sep 1939 | [Battle of Wizna](https://en.wikipedia.org/wiki/Battle_of_Wizna) | XIX Panzer Corps; Guderian listed with Ferdinand Schaal | Polish fortified line under Wladyslaw Raginis and Stanislaw Brykalski | German victory | Compact tutorial battle. Player holds bunkers, anti-tank guns, and machine-gun positions against overwhelming German armor and artillery. |
| 3 | 14-17 Sep 1939 | [Battle of Brzesc Litewski](https://en.wikipedia.org/wiki/Battle_of_Brze%C5%9B%C4%87_Litewski) | XIX Panzer Corps, including 10th Panzer, 3rd Panzer, and 20th Infantry Division | Polish Brzesc defense group under Konstanty Plisowski | German victory | Fortress/urban delay. Player uses old FT-17 tanks, armored trains, artillery, and fallback routes to slow mechanized assault. |
| 4 | 14-18 Sep 1939 | [Battle of Kobryn](https://en.wikipedia.org/wiki/Battle_of_Kobry%C5%84) | XIX Panzer Corps, primarily 2nd Motorized Infantry Division | Polish Operational Group Polesie / 60th Reserve Infantry Division under Adam Epler | Inconclusive | Rearguard battle. Player scores by preserving force cohesion, blocking routes, and escaping before encirclement. |
| 5 | 12-17 May 1940 | [Battle of Sedan](https://en.wikipedia.org/wiki/Battle_of_Sedan_%281940%29) | XIX Army Corps under Panzergruppe Kleist | French 2nd Army sector with British air support | German victory | First demo centerpiece. Player defends the Meuse crossing, bridge approaches, artillery positions, and counterattack routes under air pressure. |
| 6 | 15-17 May 1940 | Stonne / Sedan bridgehead flank actions, documented in [Battle of Sedan](https://en.wikipedia.org/wiki/Battle_of_Sedan_%281940%29) and [XIX Army Corps](https://en.wikipedia.org/wiki/XIX_Army_Corps) | XIX Army Corps, especially 10th Panzer and Grossdeutschland | French armor and infantry around Stonne heights | German bridgehead secured | Heavy-tank counterattack scenario. Player uses Char B1 bis shock, village cover, and hill control to threaten the bridgehead. |
| 7 | 17-19 May 1940 | [Battle of Montcornet](https://en.wikipedia.org/wiki/Battle_of_Montcornet) | Guderian listed with Luftwaffe support; German 1st Panzer Division in sector | French 4e Division cuirassee under Charles de Gaulle | French tactical victory / withdrawal after air pressure | Armored counterattack. Player gets strong tanks but limited support and must raid German columns before disengaging. |
| 8 | 20 May 1940 | Channel coast race through Amiens-Abbeville, documented in [XIX Army Corps](https://en.wikipedia.org/wiki/XIX_Army_Corps) | XIX Army Corps | French/British blocking forces on Somme approaches | German breakthrough to Channel | Mobile operational interlude. Player buys evacuation time by holding bridges, towns, and road junctions. |
| 9 | 22-25 May 1940 | [Battle of Boulogne](https://en.wikipedia.org/wiki/Battle_of_Boulogne) | XIX Corps under Guderian; 2nd Panzer Division attack | French, British, Belgian port defenders | German victory | Port defense. Player protects harbor evacuation, Haute Ville, destroyer fire windows, RAF/naval support, and demolition teams while German armor closes in. |
| 10 | 22-26 May 1940 | [Siege of Calais](https://en.wikipedia.org/wiki/Siege_of_Calais_%281940%29) | XIX Corps sector; 10th Panzer Division under Ferdinand Schaal | British, French, Belgian defenders | German victory | High-value delay. Player holds layered defenses, supply points, citadel/docks, and Dunkirk-time scoring rather than expecting to retain the port. |
| 11 | 26 May-4 Jun 1940 | [Battle of Dunkirk](https://en.wikipedia.org/wiki/Battle_of_Dunkirk) | Guderian-adjacent campaign pressure after Channel port drive | British, French, Belgian, Dutch evacuation perimeter | Allied evacuation / German operational success in France | Supplemental scenario with explicit command-scope caveat. Player conducts canal defense, rear-guard sacrifice, beach-capacity management, and evacuation scoring. |
| 12 | 10-22 Jun 1940 | [Fall Rot](https://en.wikipedia.org/wiki/Fall_Rot) / Panzergruppe Guderian drive toward the Swiss border, also documented in [XIX Army Corps](https://en.wikipedia.org/wiki/XIX_Army_Corps) | Panzergruppe Guderian | French defenders around Aisne, Marne-Rhine Canal, Langres, Belfort, and Epinal | German victory | Late-France campaign chain. Player stages bridge demolitions, fortress-town stands, fuel/congestion denial, and Vosges retreat-corridor preservation. |
| 13 | 22 Jun-9 Jul 1941 | [Battle of Bialystok-Minsk](https://en.wikipedia.org/wiki/Battle_of_Bia%C5%82ystok%E2%80%93Minsk) | 2nd Panzer Group as Army Group Centre's southern pincer | Soviet Western Front formations | German victory | Encirclement survival. Player fights breakout lanes, mechanized counterattack delays, Minsk road/rail preservation, command evacuation, and pocket attrition. |
| 14 | 10 Jul-10 Sep 1941 | [Battle of Smolensk](https://en.wikipedia.org/wiki/Battle_of_Smolensk_%281941%29) | 2nd Panzer Group with Hoth's northern pincer | Soviet 16th, 19th, 20th, and reserve armies around Smolensk | German victory, but German advance slowed | Major Eastern Front module. Player holds Dnieper/Dvina crossings, counterattacks pincer shoulders, forces German logistics strain, and opens Yartsevo escape lanes from the pocket. |
| 15 | 30 Aug-12 Sep 1941 | [Roslavl-Novozybkov offensive](https://en.wikipedia.org/wiki/Roslavl%E2%80%93Novozybkov_offensive) | 2nd Panzer Group turned south toward Kiev with German 2nd Army support | Soviet Bryansk Front under Andrey Yeryomenko | German victory | Soviet spoiling offensive. Player reveals German intent, raids supply columns, damages southward-turn tempo, and withdraws tank groups before counterpressure closes lanes. |
| 16 | 7 Jul-26 Sep 1941 | [Battle of Kiev](https://en.wikipedia.org/wiki/Battle_of_Kiev_%281941%29) | 2nd Panzer Group northern pincer with Kleist's 1st Panzer Group | Soviet Southwestern Front | German victory and major encirclement | Large pocket campaign. Player delays northern pincer closure, keeps eastern corridors contested, evacuates command assets, and stages breakout operations before pocket reduction. |
| 17 | 30 Sep-21 Oct 1941 | [Battle of Bryansk](https://en.wikipedia.org/wiki/Battle_of_Bryansk_%281941%29) | 2nd Panzer Group / 2nd Panzer Army during Operation Typhoon | Soviet Bryansk Front, including 50th, 13th, and 3rd Armies | German victory | Operation Typhoon southern approach. Player keeps pocketed armies active, preserves Bryansk rail command, protects the Orel-Tula road, and forces autumn logistics checks. |
| 18 | 4-11 Oct 1941 | Mtsensk fighting, supported by [Mikhail Katukov](https://en.wikipedia.org/wiki/Mikhail_Katukov), [German T-34/KV encounter](https://en.wikipedia.org/wiki/German_encounter_of_Soviet_T-34_and_KV_tanks), [4th Panzer Division](https://en.wikipedia.org/wiki/4th_Panzer_Division), [1st Guards Special Rifle Corps](https://en.wikipedia.org/wiki/1st_Guards_Special_Rifle_Corps), and [Battle of Moscow](https://en.wikipedia.org/wiki/Battle_of_Moscow) context | Guderian's Panzergruppe 2 sector, including 4th Panzer Division pressure | Soviet 4th Tank Brigade, 1st Guards Rifle Corps, and supporting anti-tank/artillery detachments | Soviet delaying success | Playable armored showcase. Player uses Katukov-style T-34/KV ambushes, anti-tank screens, wooded ridge cover, and staged withdrawals to blunt the Orel-Mtsensk-Tula road advance. |
| 19 | 2 Oct 1941-7 Jan 1942 | [Battle of Moscow](https://en.wikipedia.org/wiki/Battle_of_Moscow), focused on the Orel-Mtsensk-Tula-Venev-Kashira southern pincer and [2nd Panzer Army](https://en.wikipedia.org/wiki/2nd_Panzer_Army) | 2nd Panzer Army under Guderian | Soviet forces defending Tula, Kashira, Mordves, and southern approaches to Moscow | Soviet victory | Expanded final demo/full-campaign climax. Player balances winter roads, Tula city defense, Venev/Kashira bypass denial, mobile reserves, German exhaustion, and counteroffensive timing. |

## Development Plan

The detailed development plan is tracked in [PLAN.md](PLAN.md). The short version:

- Cycles 1-100: playable demo, centered on a fortified-delay tutorial plus two famous command-scope scenarios: Sedan/Meuse and Moscow/Tula.
- Cycles 101-250: complete campaign, expanding to every battle listed above and shipping all scenarios as playable, tested, historically annotated missions.
- Cycles 251-300: native playable demo, replacing proxy forces/maps with real Guderian battle instances for Wizna, Sedan, and Moscow/Tula/Kashira.
- Cycles 301-400: native full campaign, converting all 19 battles to scenario-specific units, terrain, actions, AI pressure, scoring, and debriefs.
- Cycles 401-450: post-ship hardening, adding after-action analysis and deterministic campaign soak probes across every native battle.
- Cycles 451-500: `derZweiteWeltkrieg` playable-screen rebase, beginning with Tuchola Forest as the accepted DZW-style board/sidebar/unit-control pilot and then carrying that screen parity through the campaign.
- Cycles 591-650: 400% map-detail improvement and late-career command-context expansion, with post-1941 scenarios labeled as staff-influence or epilogue context rather than direct field command.
- Cycles 651-730: visible late-career integration, adding a separate Guderian Late Career Context section, shared dzw briefing maps, parity-ready reports for all 16 late-career records, separate late-career progress, GuderianTest automation, UX audit coverage, and final acceptance while preserving the 19-battle field-command campaign.

Cycle 451 correction: after running `derZweiteWeltkrieg`, the accepted playability bar is the actual DZW battle screen: terrain board, objectives, opposing units, direct unit selection, draggable movement, phase/action controls, pending-choice handling, and a visible combat log. Earlier cycle 400/450 reports proved native data, diagnostics, and automation stability, but they overstated product playability because the Guderian app still surfaced a simplified board instead of the full DZW-style playable screen.

Cycle 0 update: initial repository review, `dzw` engine review, and Wikipedia battle-scope research completed on 2026-05-03.

Cycle 30 update: the root Swift package, `GuderianCore` campaign data model, 19-scenario metadata catalog, `dzw` proxy scenario loader, SwiftUI/Metal-ready `GuderianApp` shell, and catalog/loader tests are in place.

Cycle 60 update: campaign progress, briefing workspace, map renderer, custom Wizna/Sedan/Moscow layouts, German AI plans, Wizna tutorial flow, and Sedan crossing/force triggers are in place without modifying `dzw`.

Cycle 90 update: Sedan and Moscow/Tula balance profiles, reinforcement timing, scoring/debrief bands, filtered operation logs, Moscow winter setup data, and expanded demo regression tests are in place.

Cycle 120 update: packaging/demo hardening, the Xcode macOS project, public-domain icon provenance, content bundle catalog, chronological/standalone progression modes, reusable Polish 1939 campaign systems, and the hand-authored Tuchola Forest playable data slice are in place.

Cycle 150 update: Brzesc Litewski, Kobryn, France 1940 systems, Stonne, Montcornet, and Amiens-Abbeville now have hand-authored maps, setup scripts, balance profiles, German AI orders, proxy-loader coverage, and regression tests without modifying `dzw`.

Cycle 180 update: Boulogne, Calais, Dunkirk, Fall Rot, Eastern Front 1941 systems, and Bialystok-Minsk now have hand-authored map/setup/balance/AI content, system profiles, proxy-loader coverage, and regression tests while `dzw` remains untouched.

Cycle 210 update: Smolensk, Roslavl-Novozybkov, Kiev, and Bryansk now have hand-authored Eastern Front maps, setup scripts, German AI plans, balance profiles, expanded system profiles, proxy-loader coverage, and regression tests while `dzw` remains untouched.

Cycle 240 update: Mtsensk is now a hand-authored, proxy-loadable armored ambush scenario; Moscow/Tula/Kashira now covers the full southern-pincer chain through Venev, Kashira, and Mordves; every campaign battle now has a historical overlay, AI refinement snapshot, balance audit, proxy-loader smoke coverage, and regression tests while `dzw` remains untouched.

Cycle 250 update: the complete campaign milestone is in place. Release polish now includes versioned campaign save/load state, a full-campaign completion summary, ship-readiness reporting, credits, accessibility and performance audit data, final regression coverage, and verified SwiftPM/Xcode build paths while `dzw` remains untouched.

Cycle 260 update: native playability architecture is now in place. Guderian owns the scenario-instance data, campaign flow, board shell, and full-campaign automation; `dzw` remains the guarded rules engine for turns, movement, combat, objectives, and snapshots. The demo target is cycle 300, and the full native campaign target is cycle 400.

Cycle 270 update: every battle now converts into a native Guderian battle instance with units, weapon roles, deployment zones, terrain, objectives, reinforcements, event triggers, AI profiles, victory data, and an engine-blueprint payload. The remaining blocker is the guarded native loader that turns those blueprints into executable board games.

Cycle 280 update: the native scenario loader now builds custom dzw army-list skirmishes from Guderian battle blueprints and deploys units to scenario-derived positions, so automation no longer depends on fixed force presets. The remaining blocker is the guarded scenario board/mission hook for custom terrain, objectives, mission target score, and scripted events.

Cycle 290 update: the guarded dzw board hook now applies Guderian terrain zones, objective names/positions, and mission target scores to native skirmish games. The Guderian app also has a native board shell with unit selection, movement, fire diagnostics, pending-choice resolution, objective/terrain snapshots, phase controls, and log display. Demo parity still targets cycle 300 for Wizna, Sedan, and Moscow/Tula/Kashira debrief/scoring flow.

Cycle 300 update: the native playable demo milestone is in place. Wizna, Sedan, and Moscow/Tula/Kashira now complete from native board sessions through deterministic turn playback, scenario score awards, debrief summaries, and campaign completion records without generic proxy maps or generic proxy forces. The Guderian app exposes demo debrief completion from the native board, and GuderianTest records native demo completions while the other battles remain native board-shell conversions.

Cycle 310 update: GuderianTest now runs real native-board diagnostics for all 19 battles. Each scenario launches a native board session, executes legal movement/shooting/assault-phase probes, advances phases, checks target validity, validates reinforcement entry zones, and flags unwinnable mission/debrief gates.

Cycle 325 update: the native Poland 1939 pack is in place for Tuchola Forest, Wizna, Brzesc Litewski, and Kobryn. These battles now expose native Polish unit/mobility coverage, 1939 terrain/objective coverage, withdrawal, demolition, bunker, fortress/urban, rail-support, roadblock, cavalry-screen, anti-tank-lane, obsolete-armor, and command-friction rule bindings, plus native board completion records and debriefs.

Cycle 345 update: the native France 1940 pack is in place for Sedan, Stonne, Montcornet, Amiens-Abbeville, Boulogne, Calais, Dunkirk, and Fall Rot. These battles now expose native 1940 unit/mobility coverage, river-crossing, bridgehead, heavy-tank, armored-raid, air-pressure, evacuation, siege-supply, port-denial, naval-support, Channel-delay, withdrawal, and fortress-fallback rule bindings, plus native board completion records and debriefs.

Cycle 350 update: the Eastern Front 1941 native foundation is in place for Bialystok-Minsk, Smolensk, Roslavl-Novozybkov, Kiev, Bryansk, Mtsensk, and Moscow/Tula/Kashira. The 1941 battles now expose native foundation mappings for pockets, breakout lanes, mechanized counterattacks, command posts, river crossings, logistics friction, southward-turn pressure, pincers, armor ambushes, T-34/KV shock, winter friction, Tula defense, and counteroffensive rules.

Cycle 370 update: the native Eastern Front 1941 pack is complete. Bialystok-Minsk, Smolensk, Roslavl-Novozybkov, Kiev, Bryansk, Mtsensk, and Moscow/Tula/Kashira now complete from native board sessions through deterministic playback, scenario score awards, debrief summaries, and campaign completion records.

Cycle 375 update: the first AI/event pass is in place across all 19 battles. Native reports now map deterministic German AI priorities, fallback behavior, scripted events, reinforcement timing, pacing, scenario rules, tutorial cues, and victory gates against real native battle instances.

Cycle 380 update: native AI/event execution is now resolved against live board snapshots for all 19 battles. Guderian AI movement uses scenario-authored objective priorities, and each mapped priority, fallback, event, reinforcement timing, scenario rule, pacing cue, tutorial cue, and victory gate resolves to a board target.

Cycle 390 update: native balance and UX audits now cover every battle. The audits verify pacing bands, player-agency score coverage, readable unit/objective/terrain density, full battle-flow accessibility identifiers, save/load continuity, and failure/debrief reporting.

Cycle 400 update: the native automation gate is green. The report verifies all 19 battles as native board sessions with completion records, full GuderianTest automation completion, cycle 380 AI/event execution readiness, cycle 390 balance/UX readiness, and the earlier cycle 250 metadata baseline. It is not the final user-playability gate.

Cycle 425 update: post-ship after-action analysis now covers every battle with agency, AI pressure, event timing, historical-context, automation-coverage notes, and tuning follow-ups.

Cycle 450 update: deterministic native campaign soak probes now run three seeded board diagnostics per battle across the full 19-battle campaign, with stable replay signatures and no blocking findings.

Cycle 460 update: the Tuchola Forest row now opens a DZW-style playable battle shell directly in Guderian. The screen uses the native Tuchola board session with terrain zones, objectives, Polish and German units, unit selection, draggable movement, rotation, cover/hull-down toggles, shooting/assault controls, pending-choice resolution, phase advancement, and battle-log feedback. This is the first accepted playable-screen pilot; the remaining battles still need the same UI parity pass.

Cycle 480 update: Tuchola Forest now has the first fidelity pass on the DZW-style screen. Native Polish/German unit names, roles, mobility, and historical notes are shown on the live board; scoring objectives now map to the Brda bridges, Chojnice/Tuchola road hubs, Krojanty, and Bydgoszcz withdrawal while terrain markers carry the East Prussia pincer and XIX Corps spearhead; and the German AI turn runner visibly advances through prioritized objectives while falling back from blocked Brda movement lines.

Cycle 500 update: the Tuchola Forest DZW-style playable-screen pilot now runs from opening board to restart/debrief/scored completion with campaign-progress persistence and failure/debrief error reporting. A dedicated screen-parity harness drives launch, selection, movement, phase flow, attack attempts, blocked-action feedback, German AI, debrief, and persistence, and the reusable playable-battle surface catalog now defines acceptance gates and rollout windows for converting the rest of the campaign.

Cycle 545 update: battles 2-10, Wizna through Calais, now route from the battle-selection row into the shared DZW-style playable screen. The generalized parity harness completes launch, selection, legal movement, phase flow, attack feedback, blocked-action reporting, German AI, debrief, and persistence for all ten routed battles, and GuderianTest records playable-screen parity for those routed battles.

Cycle 590 update: the full 19-battle campaign now routes into the shared DZW-style playable screen. Dunkirk through Moscow/Tula/Kashira complete the same parity path as the earlier battles: terrain-backed board, selectable units, legal movement, phase flow, combat feedback, blocked-action reporting, German AI, debrief persistence, and GuderianTest playable-screen reporting.

Cycle 595 update: the new career-scope ledger is in place for the map/detail expansion. The current 19 battles are classified by command relationship, Dunkirk is explicitly marked as adjacent campaign pressure, Moscow/Tula/Kashira carries an end-date caveat, and 15 late-career withdrawal/final-war candidates are cataloged only as Inspector General, Army General Staff, or post-dismissal context.

Cycle 600 update: map-detail auditing is now in place for all 19 existing battlefields. The audit measures total map features, water, roads, railways, crossings, settlements, terrain, fortifications, objectives, deployment zones, pressure markers, annotations, line/marker balance, and coordinate density, then assigns a four-times-current target for each battle.

Cycle 605 update: the map schema now supports canals, lakes, marshes, railways, fords, ferries, villages, urban districts, phase lines, and source-note metadata on maps, features, and deployment zones. These types are wired through rendering, native battle conversion, board terrain classification, readiness checks, and map-detail auditing.

Cycle 610 update: the geography pipeline now creates cross-check records for every current battle. Each record includes a modern map visual guide, scenario-source references, feature anchors inferred from the scenario's map-feature intent, hand-authored abstract-coordinate workflow steps, and source notes that are appended to the current layouts before the 400% enrichment passes begin.

Cycle 615 update: the Poland 1939 map enrichment pass is complete for Tuchola Forest, Wizna, Brzesc Litewski, and Kobryn. Those four maps now meet the cycle-600 four-times feature baseline with denser rivers, marshes, roads, railways, crossings, named villages or urban districts, fallback routes, and phase lines while preserving the playable battle flow.

Cycle 620 update: the France 1940 map enrichment pass is complete for Sedan, Stonne, Montcornet, Amiens-Abbeville, Boulogne, Calais, Dunkirk, and Fall Rot. These eight maps now meet the cycle-600 four-times feature baseline with denser Meuse, Somme, Channel coast, harbor, canal, fortress, road, rail, crossing, urban, ridge, marsh, evacuation, withdrawal, and phase-line geography in the shared dzw layouts used by both Guderian and GuderianTest.

Cycle 625 update: the 1941 Eastern Front map enrichment pass is complete for Bialystok-Minsk, Smolensk, Roslavl-Novozybkov, Kiev, Bryansk, Mtsensk, and Moscow/Tula/Kashira. These seven maps now meet the cycle-600 four-times feature baseline with denser river systems, rail corridors, road nets, pocket exits, forest belts, named settlements, urban districts, armor ambush terrain, winter lanes, crossings, marshes, and phase lines in the shared dzw layouts.

Cycle 630 update: late-career set A is now concrete shared dzw staff-context data. Kursk armored-force pressure, Dnieper withdrawal and bridgeheads, Korsun-Cherkassy, and Kamenets-Podolsky have command-caveated battlefield records with maps, objectives, forces, and rules, but they remain outside the direct 19-battle Guderian field-command campaign until later integration.

Cycle 635 update: late-career set B now covers 1944 withdrawal and bridgehead crises: Operation Bagration, Lvov-Sandomierz, Narew/Vistula bridgeheads, and the Warsaw-area defensive arcs. Each is shared dzw General Staff context data with detailed maps, objectives, forces, rules, and visible command caveats.

Cycle 640 update: late-career set C now covers the 1945 collapse route through Vistula-Oder, Poznan, East Prussia/Elbing, and Kustrin/Oder bridgeheads. These battlefields add river, rail, fortress, lagoon, bridgehead, and withdrawal geography while remaining outside the direct field-command campaign.

Cycle 645 update: late-career set D now covers Operation Solstice, East Pomeranian offensive, Seelow Heights epilogue, and Berlin/Halbe epilogue. The final two are explicitly post-dismissal context, and every record exposes a visible "not a Guderian field command" caveat for UI and tests.

Cycle 650 update: the cycle 591-650 expansion is complete. The current 19-battle campaign remains fully routed to the DZW-style playable screen, the enriched maps remain acceptance-ready, and all 16 late-career staff/epilogue battlefields are linked to the shared dzw career ledger with command caveats.

Cycle 655 update: cycles 651-655 are complete. `LateCareerGuderianPresentationCatalog` now wraps the 16 shared dzw late-career battlefield records for Guderian while keeping `GuderianCampaignCatalog.all` locked to the original 19 field-command battles.

Cycle 660 update: cycles 656-660 are complete. The Guderian campaign screen now shows a separate Late Career Context section with scope filters and row-level command caveats for Inspector General, General Staff, and post-dismissal epilogue records.

Cycle 665 update: cycles 661-665 are complete. Late-career context rows now open briefing screens with zoomable/scrollable maps, objectives, forces, rules, and sources reused directly from the shared dzw late-career battlefield data.

Cycle 670 update: cycles 666-670 are complete. The four set-A late-career battlefields now route to a DZW-style pilot surface with board/sidebar layout, caveated setup metadata, force focus controls, phase advancement, and pilot log feedback.

Cycle 675 update: cycles 671-675 are complete. Set A now has playable parity metadata: scoring profiles, debrief text, late-career completion records, persistence keys, AI priorities, blocked-action expectations, and regression coverage.

Cycle 680 update: cycles 676-680 are complete. Set B now routes Operation Bagration withdrawal, Lvov-Sandomierz, Narew/Vistula bridgeheads, and Warsaw defensive arcs into the same late-career DZW-style surface with General Staff caveats visible.

Cycle 685 update: cycles 681-685 are complete. Set B now has AI priorities, blocked-action expectations, scoring/debrief records, persistence keys, and tests proving parity readiness for all four set-B battlefields.

Cycle 690 update: cycles 686-690 are complete. Set C now routes Vistula-Oder, Poznan corridor, East Prussia/Elbing, and Kustrin/Oder bridgeheads into the caveated late-career playable surface.

Cycle 695 update: cycles 691-695 are complete. Set C now has playable parity metadata with scoring profiles, debrief text, late-career completion records, persistence keys, AI priorities, blocked-action expectations, and regression coverage.

Cycle 700 update: cycles 696-700 are complete. Set D now routes Operation Solstice, East Pomeranian offensive, Seelow Heights epilogue, and Berlin/Halbe epilogue into the late-career DZW-style surface with post-dismissal caveats visible.

Cycle 705 update: cycles 701-705 are complete. Set D now has final-war parity metadata with epilogue-aware debrief handling, persistence keys, completion records, AI pressure, blocked actions, and regression coverage.

Cycle 710 update: cycles 706-710 are complete. `LateCareerConsolidatedPlaybookCatalog` now consolidates AI priorities, blocked-action expectations, command-caveat events, and reusable crossing, rail, fortress, withdrawal, and phase-line rule bindings across all 16 late-career records.

Cycle 715 update: cycles 711-715 are complete. Late-career context completions now have their own progress model, persistence codec, completion summary, row state, and debrief callback path separate from the 19-battle field-command campaign.

Cycle 720 update: cycles 716-720 are complete. GuderianTest now surfaces late-career automation alongside the field-command campaign and verifies all 16 context battlefields through caveat visibility, map detail, AI pressure, scoring, persistence, rule bindings, and debrief completion.

Cycle 725 update: cycles 721-725 are complete. The late-career UX audit now covers scope filters, accessibility identifiers, source-note display, and explicit final-war caveat visibility.

Cycle 730 update: cycles 726-730 are complete. The final acceptance report verifies 19 field-command battles, 16 late-career context battlefields, 35 total selectable entries, full playable routing, late-career automation, separate progress tracking, UX readiness, and build commands.

## Run

Build and test from the repository root:

```bash
swift test
swift build
```

Run the initial Guderian scenario workspace:

```bash
swift run GuderianApp
```

Or open `Guderian.xcodeproj` in Xcode and run the shared `Guderian` macOS scheme.

## Homebrew

The v1.0.0 Homebrew submission assets are prepared as a cask because Guderian ships as a macOS app bundle. Build the GitHub Release zip with:

```bash
scripts/package-homebrew-release.sh 1.0.0
```

Then upload `dist/Guderian-1.0.0.zip` to the GitHub release at `https://github.com/barbalet/guderian/releases/tag/v1.0.0`. The cask lives at `Casks/g/guderian.rb`, and the full release checklist is in `docs/homebrew.md`.

## Ship Status

The campaign content and native automation layers are substantial, and the accepted playable-game milestone is now tracked against the DZW-style hand-playable screen. Cycle 590 completes playable-screen parity for all 19 battles, from Tuchola Forest through Moscow/Tula/Kashira, with debrief, persistence, screen-parity automation, reusable surface routing, and GuderianTest reporting. Cycle 730 completes the late-career expansion as 16 separate command-caveated context entries with parity-ready play reports, separate progress tracking, GuderianTest automation, UX audit coverage, and final acceptance reporting.

Remaining playable-screen estimate: battles 1-19 are complete through cycle 590. Map-detail auditing, schema expansion, geography cross-checking, Poland map enrichment, France map enrichment, Eastern Front map enrichment, late-career staff/epilogue sets A-D, visible integration, separate late-career progress, automation, UX polish, and acceptance are complete through cycle 730. There are no cycles remaining in the current 80-cycle visible late-career integration plan.

## App Identity

The app icon uses a face-focused crop of the public-domain Wikimedia Commons portrait documented in `Resources/AppIconSource/README.md`. The crop is intentionally limited to historical subject identification.

## Contact

Contact `barbalet at gmail dot com` if you have questions, feedback, or would like to collaborate.
