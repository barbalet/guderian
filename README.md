# guderian

`guderian` is a macOS World War II wargame project about opposing Heinz Guderian's field commands. The player is always the force resisting, delaying, escaping, or counterattacking Guderian's formations rather than commanding them.

The intended stack is a macOS game using SwiftUI, Metal, and a C rules core. The project is based on the included `dzw` (`derZweiteWeltkrieg`) engine, which should be treated as read-only unless a Guderian-specific hook is guarded by:

```c
#define HEINZ_GUDERIAN_GAME
```

That define should exist only in the Guderian Xcode project so upstream `dzw` development is not affected.

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

Cycle 0 update: initial repository review, `dzw` engine review, and Wikipedia battle-scope research completed on 2026-05-03.

Cycle 30 update: the root Swift package, `GuderianCore` campaign data model, 19-scenario metadata catalog, `dzw` proxy scenario loader, SwiftUI/Metal-ready `GuderianApp` shell, and catalog/loader tests are in place.

Cycle 60 update: campaign progress, briefing workspace, map renderer, custom Wizna/Sedan/Moscow layouts, German AI plans, Wizna tutorial flow, and Sedan crossing/force triggers are in place without modifying `dzw`.

Cycle 90 update: Sedan and Moscow/Tula balance profiles, reinforcement timing, scoring/debrief bands, filtered operation logs, Moscow winter setup data, and expanded demo regression tests are in place.

Cycle 120 update: packaging/demo hardening, the Xcode macOS project, public-domain icon provenance, content bundle catalog, chronological/standalone progression modes, reusable Polish 1939 campaign systems, and the hand-authored Tuchola Forest playable data slice are in place.

Cycle 150 update: Brzesc Litewski, Kobryn, France 1940 systems, Stonne, Montcornet, and Amiens-Abbeville now have hand-authored maps, setup scripts, balance profiles, German AI orders, proxy-loader coverage, and regression tests without modifying `dzw`.

Cycle 180 update: Boulogne, Calais, Dunkirk, Fall Rot, Eastern Front 1941 systems, and Bialystok-Minsk now have hand-authored map/setup/balance/AI content, system profiles, proxy-loader coverage, and regression tests while `dzw` remains untouched.

Cycle 210 update: Smolensk, Roslavl-Novozybkov, Kiev, and Bryansk now have hand-authored Eastern Front maps, setup scripts, German AI plans, balance profiles, expanded system profiles, proxy-loader coverage, and regression tests while `dzw` remains untouched.

Cycle 240 update: Mtsensk is now a hand-authored, proxy-loadable armored ambush scenario; Moscow/Tula/Kashira now covers the full southern-pincer chain through Venev, Kashira, and Mordves; every campaign battle now has a historical overlay, AI refinement snapshot, balance audit, proxy-loader smoke coverage, and regression tests while `dzw` remains untouched.

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

## App Identity

The app icon uses a face-focused crop of the public-domain Wikimedia Commons portrait documented in `Resources/AppIconSource/README.md`. The crop is intentionally limited to historical subject identification.

## Contact

Contact `barbalet at gmail dot com` if you have questions, feedback, or would like to collaborate.
