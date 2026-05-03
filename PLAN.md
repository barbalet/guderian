# Guderian Development Plan

Cycle 0 update: README and this plan were created from a review of the root project, the included `dzw` engine directory, and Wikipedia research on Guderian's World War II field-command battles.

Cycle 30 update: cycles 1-30 are complete. The repository now has a root Swift package, a `GuderianCore` campaign/scenario data model, all 19 command-scope scenarios represented as metadata, demo IDs locked to Wizna/Sedan/Moscow-Tula-Kashira, a no-submodule-edit `dzw` proxy loader, a SwiftUI app shell with Metal device detection, and regression tests for catalog and loader behavior.

Cycle 60 update: cycles 31-60 are complete. The app now has campaign progress controls, an expanded briefing workspace, reusable historical map rendering, generated fallback maps for every scenario, custom Wizna/Sedan/Moscow map layouts, German AI posture metadata, Wizna tutorial steps, and Sedan force/setup triggers for river crossing, air pressure, engineers, panzer follow-up, artillery, and French counterattack timing.

Cycle 90 update: cycles 61-90 are complete. Sedan now has explicit score channels, pacing caps, reinforcement timing, and debrief bands; Moscow/Tula has winter road friction, Tula defensive-belt data, Soviet reserve armor, anti-tank guns, mobile winter reserves, German supply/exhaustion pressure, and balance tuning; the app briefing adds score/debrief sections, reinforcement summaries, and a filtered operation log; tests now cover all three demo scenario proxy loads, scoring, AI plans, reinforcements, and event-log categories.

Cycle 120 update: cycles 91-120 are complete. Packaging and demo hardening now include the Xcode macOS project, shared scheme, public-domain icon source ledger, README run guidance, and successful SwiftPM/Xcode build paths; the full-campaign expansion now has a content bundle facade, chronological/standalone campaign progression modes with completion records, reusable Polish 1939 system profiles, and a hand-authored Tuchola Forest data slice covering Brda crossings, Chojnice/Tuchola road hubs, Krojanty cavalry screening, Bydgoszcz withdrawal, German pincer pressure, balance, reinforcements, AI orders, operation-log entries, and regression coverage.

Cycle 150 update: cycles 121-150 are complete. Brzesc Litewski now has fortress/citadel, rail, armored-train, FT-17, fallback-gate, and German isolation data; Kobryn now has rearguard, 60th Reserve Infantry, roadblock, eastern-exit, cohesion-withdrawal, and motorized-fixation data; France 1940 systems now cover river crossings, Char B1 heavy-tank shock, armored raid doctrine, air-pressure timing, road/Channel objectives, and withdrawal rules; Stonne, Montcornet, and Amiens-Abbeville now have hand-authored maps, setup scripts, balance profiles, German AI orders, event-log coverage, proxy-loader notes, and regression tests.

Cycle 180 update: cycles 151-180 are complete. Boulogne now has harbor evacuation, Haute Ville, destroyer support, air pressure, and port demolition data; Calais now has layered perimeter, supply, citadel/docks, costly assault, and Dunkirk-time scoring data; Dunkirk now has explicit Guderian-adjacent command caveats, canal defense, beach evacuation capacity, rear-guard sacrifice, and air-pressure data; Fall Rot now has crossing denial, fortress-town stands, fuel/congestion pressure, Vosges retreat corridors, and Army Group C link-up data; Eastern Front 1941 systems now cover rifle armies, mechanized counterattacks, command posts, pockets, breakout routes, rail junctions, logistics, and winter friction; Bialystok-Minsk now has Bug/Neman crossing pressure, Bialystok/Novogrudok pockets, Minsk road/rail escape, Soviet command preservation, German pincer AI, balance profiles, proxy-loader coverage, and regression tests.

Cycle 210 update: cycles 181-210 are complete. Smolensk now has Dnieper/Dvina crossing delay, Yartsevo escape, reserve counterstroke, German supply-strain, pocket, balance, AI, and proxy-loader data; Roslavl-Novozybkov now has Bryansk Front spoiling-offensive, reconnaissance, supply-column raid, tank-preservation, intelligence-limit, southward-turn, and counterpressure data; Kiev now has northern-pincer pressure, Southwestern Front command evacuation, Dnieper/Desna delay, eastern corridor, pincer link-up, breakout, and pocket-reduction data; Bryansk now has Operation Typhoon surprise-axis, Bryansk/Orel/Tula road protection, 50th/13th/3rd Army pocket survival, rail-command preservation, autumn logistics friction, balance, AI, proxy-loader coverage, and regression tests.

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

## Acceptance Criteria

- `dzw` remains cleanly updatable because Guderian-specific engine hooks are guarded or externalized.
- The demo ships with Wizna, Sedan, and Moscow/Tula playable from briefing to debrief.
- The full campaign ships with every battle in the README chronology playable.
- Every battle has source links, scenario notes, force data, objectives, balance status, and test coverage.
- The app clearly frames the player as opposing Guderian and treats the historical subject with sober context.
