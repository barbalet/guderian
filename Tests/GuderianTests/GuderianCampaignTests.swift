import DerZweiteWeltkriegCore
@testable import GuderianCore
import XCTest

final class GuderianCampaignTests: XCTestCase {
    func testCampaignCatalogLocksNineteenCommandScopeScenarios() {
        XCTAssertEqual(GuderianCampaignCatalog.all.count, 19)
        XCTAssertEqual(GuderianCampaignCatalog.all.map(\.order), Array(1...19))
        XCTAssertEqual(Set(GuderianCampaignCatalog.all.map(\.id)).count, 19)
    }

    func testCampaignCatalogIsChronologicalWithinStableOrder() {
        let scenarios = GuderianCampaignCatalog.all

        for pair in zip(scenarios, scenarios.dropFirst()) {
            XCTAssertLessThan(pair.0.order, pair.1.order)
            XCTAssertLessThanOrEqual(pair.0.startDate, pair.1.startDate)
        }
    }

    func testEveryScenarioHasSourcesTerrainObjectivesAndOpposingForceRole() {
        for scenario in GuderianCampaignCatalog.all {
            XCTAssertFalse(scenario.sourceLinks.isEmpty, "\(scenario.title) needs at least one source")
            XCTAssertFalse(scenario.mapFeatures.isEmpty, "\(scenario.title) needs terrain features")
            XCTAssertFalse(scenario.objectives.isEmpty, "\(scenario.title) needs objectives")
            XCTAssertTrue(
                scenario.forces.contains { $0.side == "Player" },
                "\(scenario.title) needs a player force slot"
            )
            XCTAssertTrue(
                scenario.forces.contains { $0.side == "Guderian AI" },
                "\(scenario.title) needs a Guderian AI force slot"
            )
        }
    }

    func testDemoScenarioIDsMatchFirstThirtyCycleScope() throws {
        XCTAssertEqual(GuderianCampaignCatalog.demoIDs, [.wizna, .sedan, .moscowTulaKashira])

        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            XCTAssertTrue(scenario.isDemoScenario)
            XCTAssertEqual(scenario.status, .dzwProxyLoadable)
        }
    }

    func testScenarioLoaderCreatesDZWGameWithoutChangingSubmodule() throws {
        let loadout = DZWScenarioLoader.loadFirstDemoScenario(seed: 19390907)
        XCTAssertEqual(loadout.scenario.id, .wizna)
        XCTAssertEqual(loadout.playerArmyName, "British")
        XCTAssertEqual(loadout.opponentArmyName, "German")
        XCTAssertFalse(loadout.adapterNotes.isEmpty)

        let game = try XCTUnwrap(loadout.makeGame())
        defer { game_destroy(game) }

        XCTAssertEqual(game_player_army(game, TE_PLAYER_ONE), loadout.playerArmy)
        XCTAssertEqual(game_player_army(game, TE_PLAYER_TWO), loadout.opponentArmy)
        XCTAssertGreaterThan(Int(game_unit_count(game)), 0)
        XCTAssertGreaterThan(Int(game_objective_count(game)), 0)
    }

    func testEasternFrontScenarioLoaderUsesSovietOpposition() throws {
        let loadout = try XCTUnwrap(DZWScenarioLoader.load(.moscowTulaKashira, seed: 19411002))
        XCTAssertEqual(loadout.playerArmyName, "Soviet")
        XCTAssertEqual(loadout.opponentArmyName, "German")

        let game = try XCTUnwrap(loadout.makeGame())
        defer { game_destroy(game) }

        XCTAssertEqual(game_player_army(game, TE_PLAYER_ONE), TE_ARMY_SOVIET)
        XCTAssertEqual(game_player_army(game, TE_PLAYER_TWO), TE_ARMY_GERMAN)
    }

    func testEveryScenarioHasRenderableMapAndAIPlan() {
        for scenario in GuderianCampaignCatalog.all {
            let layout = ScenarioMapCatalog.layout(for: scenario)
            let aiPlan = GermanAIPlanCatalog.plan(for: scenario)

            XCTAssertEqual(layout.id, scenario.id)
            XCTAssertGreaterThan(layout.width, 0)
            XCTAssertGreaterThan(layout.height, 0)
            XCTAssertFalse(layout.elements.isEmpty, "\(scenario.title) needs map elements")
            XCTAssertEqual(layout.deploymentZones.count, 2, "\(scenario.title) needs both deployment zones")
            XCTAssertFalse(aiPlan.orders.isEmpty, "\(scenario.title) needs German AI orders")
            XCTAssertFalse(aiPlan.targetPriorities.isEmpty, "\(scenario.title) needs AI target priorities")
        }
    }

    func testWiznaTutorialLocksFortificationDelayFlow() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .wizna))
        let layout = ScenarioMapCatalog.layout(for: scenario)
        let setup = ScenarioSetupCatalog.setup(for: scenario)
        let aiPlan = GermanAIPlanCatalog.plan(for: scenario)

        XCTAssertTrue(layout.elements.contains { $0.kind == .bunker })
        XCTAssertTrue(layout.elements.contains { $0.kind == .fortifiedLine })
        XCTAssertGreaterThanOrEqual(setup.tutorialSteps.count, 4)
        XCTAssertTrue(setup.tutorialSteps.contains { $0.title.contains("bunkers") })
        XCTAssertTrue(setup.triggers.contains { $0.name.contains("Bombardment") })
        XCTAssertTrue(aiPlan.orders.contains { $0.kind == .artillery })
        XCTAssertTrue(setup.playerUnits.contains { $0.name.contains("anti-tank") })
    }

    func testSedanMapForcesAndTriggersCoverCrossingScenario() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .sedan))
        let layout = ScenarioMapCatalog.layout(for: scenario)
        let setup = ScenarioSetupCatalog.setup(for: scenario)
        let aiPlan = GermanAIPlanCatalog.plan(for: scenario)

        XCTAssertTrue(layout.elements.contains { $0.kind == .river && $0.name.contains("Meuse") })
        XCTAssertGreaterThanOrEqual(layout.elements.filter { $0.kind == .bridge }.count, 2)
        XCTAssertTrue(setup.playerUnits.contains { $0.name.contains("French artillery") })
        XCTAssertTrue(setup.guderianUnits.contains { $0.name.contains("engineers") })
        XCTAssertTrue(setup.guderianUnits.contains { $0.name.contains("panzer") })
        XCTAssertTrue(setup.triggers.contains { $0.name.contains("counterattack") })
        XCTAssertTrue(aiPlan.orders.contains { $0.kind == .reinforcement && $0.target.contains("Bridgehead") })
    }

    func testDemoBalanceProfilesExposeScoringPacingAndDebriefBands() throws {
        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let balance = ScenarioBalanceCatalog.profile(for: scenario)

            XCTAssertEqual(balance.id, id)
            XCTAssertGreaterThan(balance.maxPlayerScore, 0, "\(scenario.title) should expose player scoring")
            XCTAssertFalse(balance.scoreChannels.isEmpty, "\(scenario.title) needs score channels")
            XCTAssertFalse(balance.pacingRules.isEmpty, "\(scenario.title) needs pacing rules")
            XCTAssertFalse(balance.outcomeBands.isEmpty, "\(scenario.title) needs debrief bands")
            XCTAssertLessThanOrEqual(balance.targetTurns.lowerBound, balance.targetTurns.upperBound)
        }
    }

    func testSedanBalanceProtectsCounterattackAgency() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .sedan))
        let balance = ScenarioBalanceCatalog.profile(for: scenario)

        XCTAssertTrue(balance.scoreChannels.contains { $0.name.contains("Bridgehead delay") && $0.side == .player })
        XCTAssertTrue(balance.scoreChannels.contains { $0.name.contains("Counterattack damage") })
        XCTAssertTrue(balance.pacingRules.contains { $0.name.contains("Air-pressure cap") })
        XCTAssertTrue(balance.pacingRules.contains { $0.name.contains("Counterattack agency") })
        XCTAssertTrue(balance.reinforcements.contains { $0.unitName.contains("French reserve") && $0.side == .player })
        XCTAssertTrue(balance.reinforcements.contains { $0.unitName.contains("panzer") && $0.side == .guderianAI })
    }

    func testMoscowTulaScenarioHasWinterForcesExhaustionAndCounterattack() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .moscowTulaKashira))
        let layout = ScenarioMapCatalog.layout(for: scenario)
        let setup = ScenarioSetupCatalog.setup(for: scenario)
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let aiPlan = GermanAIPlanCatalog.plan(for: scenario)

        XCTAssertTrue(layout.elements.contains { $0.name.contains("Winter road choke") })
        XCTAssertTrue(layout.elements.contains { $0.name.contains("Tula defensive belt") })
        XCTAssertTrue(setup.playerUnits.contains { $0.name.contains("reserve armor") })
        XCTAssertTrue(setup.playerUnits.contains { $0.name.contains("anti-tank") })
        XCTAssertTrue(setup.guderianUnits.contains { $0.name.contains("supply") })
        XCTAssertTrue(setup.triggers.contains { $0.name.contains("exhaustion") })
        XCTAssertTrue(balance.scoreChannels.contains { $0.name.contains("German exhaustion") })
        XCTAssertTrue(balance.reinforcements.contains { $0.unitName.contains("Soviet reserve armor") })
        XCTAssertTrue(aiPlan.orders.contains { $0.id == "moscow-exhaustion" })
    }

    func testEventLogsCanBeFilteredByEveryCategoryForDemoScenarios() throws {
        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let entries = ScenarioEventLogCatalog.entries(for: scenario)
            let categories = Set(entries.map(\.category))

            XCTAssertFalse(entries.isEmpty)
            XCTAssertTrue(categories.contains(.briefing))
            XCTAssertTrue(categories.contains(.objectives))
            XCTAssertTrue(categories.contains(.forces))
            XCTAssertTrue(categories.contains(.aiPlan))
            XCTAssertTrue(categories.contains(.balance))
            XCTAssertTrue(categories.contains(.reinforcements), "\(scenario.title) should expose reinforcement timing")
        }
    }

    func testAllDemoScenariosCreateProxyGamesWithObjectives() throws {
        for id in GuderianCampaignCatalog.demoIDs {
            let loadout = try XCTUnwrap(DZWScenarioLoader.load(id, seed: UInt32(9_000 + id.rawValue.count)))
            let game = try XCTUnwrap(loadout.makeGame(), "\(loadout.scenario.title) should load through dzw proxy")
            defer { game_destroy(game) }

            XCTAssertEqual(game_player_army(game, TE_PLAYER_ONE), loadout.playerArmy)
            XCTAssertEqual(game_player_army(game, TE_PLAYER_TWO), loadout.opponentArmy)
            XCTAssertGreaterThan(Int(game_unit_count(game)), 0)
            XCTAssertGreaterThan(Int(game_objective_count(game)), 0)
        }
    }

    func testCampaignProgressMakesDemoScenariosAvailable() throws {
        var progress = CampaignProgress()

        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            XCTAssertTrue(progress.isAvailable(scenario), "\(scenario.title) should be playable in the demo shell")
        }

        let first = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        XCTAssertTrue(progress.isAvailable(first))
        progress.markCompleted(.tucholaForest)

        let second = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .wizna))
        XCTAssertTrue(progress.isCompleted(.tucholaForest))
        XCTAssertTrue(progress.isAvailable(second))

        progress.reset()
        XCTAssertEqual(progress.completedCount, 0)
    }

    func testCampaignProgressSupportsChronologicalAndStandaloneModes() throws {
        var progress = CampaignProgress()
        let tuchola = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let brzesc = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .brzescLitewski))

        XCTAssertTrue(progress.isAvailable(tuchola, in: .chronological))
        XCTAssertFalse(progress.isAvailable(brzesc, in: .chronological))
        XCTAssertEqual(progress.availableScenarios(in: .standalone).count, GuderianCampaignCatalog.all.count)

        let record = CampaignCompletionRecord(
            scenarioID: .tucholaForest,
            score: 10,
            victoryBand: .operational,
            completedTurn: 7,
            note: "Bridges blocked and withdrawal opened."
        )
        progress.recordCompletion(record)
        progress.markCompleted(.wizna)

        XCTAssertEqual(progress.completionRecord(for: .tucholaForest), record)
        XCTAssertTrue(progress.isAvailable(brzesc, in: .chronological))

        let snapshot = progress.snapshot(mode: .chronological)
        XCTAssertEqual(snapshot.nextScenarioID, .brzescLitewski)
        XCTAssertTrue(snapshot.availableScenarioIDs.contains(.brzescLitewski))
        XCTAssertEqual(snapshot.completedRecords, [record])
    }

    func testScenarioContentBundlesCollectHandAuthoredData() throws {
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.tucholaForest))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.brzescLitewski))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.amiensAbbeville))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.fallRot))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.bialystokMinsk))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.smolensk))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.bryansk))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.mtsensk))

        for id in ScenarioContentCatalog.handAuthoredScenarioIDs {
            let bundle = try XCTUnwrap(ScenarioContentCatalog.bundle(for: id))

            XCTAssertEqual(bundle.id, id)
            XCTAssertEqual(bundle.scenario.id, id)
            XCTAssertEqual(bundle.mapLayout.id, id)
            XCTAssertEqual(bundle.setup.id, id)
            XCTAssertEqual(bundle.aiPlan.id, id)
            XCTAssertEqual(bundle.balance.id, id)
            XCTAssertFalse(bundle.logEntries.isEmpty)
        }
    }

    func testPolishCampaignSystemsExposeReusableEarlyWarAssets() throws {
        XCTAssertEqual(
            PolishCampaignSystemCatalog.polishScenarioIDs,
            [.tucholaForest, .wizna, .brzescLitewski, .kobryn]
        )

        for id in PolishCampaignSystemCatalog.polishScenarioIDs {
            let profile = try XCTUnwrap(PolishCampaignSystemCatalog.profile(for: id))

            XCTAssertEqual(profile.id, id)
            XCTAssertFalse(profile.assets.isEmpty)
            XCTAssertFalse(profile.specialRules.isEmpty)
            XCTAssertFalse(profile.operationalProblem.isEmpty)
            XCTAssertFalse(profile.playerDoctrine.isEmpty)
        }

        let tuchola = try XCTUnwrap(PolishCampaignSystemCatalog.profile(for: .tucholaForest))
        XCTAssertTrue(tuchola.assets.contains { $0.kind == .cavalryBrigade && $0.name.contains("Pomeranian") })
        XCTAssertTrue(tuchola.assets.contains { $0.kind == .demolitionTeam && $0.name.contains("Brda") })
        XCTAssertTrue(tuchola.assets.contains { $0.kind == .withdrawalRoute && $0.name.contains("Bydgoszcz") })
        XCTAssertTrue(tuchola.assets.contains { $0.kind == .commandFriction })
        XCTAssertTrue(tuchola.specialRules.contains { $0.name.contains("Krojanty") })
    }

    func testPolandExpansionScenariosAreHandAuthoredAndProxyLoadable() throws {
        let brzesc = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .brzescLitewski))
        let kobryn = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .kobryn))
        let brzescBundle = ScenarioContentCatalog.bundle(for: brzesc)
        let kobrynBundle = ScenarioContentCatalog.bundle(for: kobryn)

        XCTAssertEqual(brzesc.status, .dzwProxyLoadable)
        XCTAssertEqual(kobryn.status, .dzwProxyLoadable)
        XCTAssertNotNil(PolishCampaignSystemCatalog.profile(for: brzesc))
        XCTAssertNotNil(PolishCampaignSystemCatalog.profile(for: kobryn))

        XCTAssertTrue(brzescBundle.mapLayout.elements.contains { $0.name.contains("Citadel") })
        XCTAssertTrue(brzescBundle.mapLayout.elements.contains { $0.name.contains("Armored train") })
        XCTAssertTrue(brzescBundle.setup.playerUnits.contains { $0.name.contains("Armored trains") })
        XCTAssertTrue(brzescBundle.setup.playerUnits.contains { $0.name.contains("FT-17") })
        XCTAssertTrue(brzescBundle.balance.scoreChannels.contains { $0.name.contains("Citadel") })
        XCTAssertTrue(brzescBundle.aiPlan.orders.contains { $0.id == "brzesc-citadel-ring" })

        XCTAssertTrue(kobrynBundle.mapLayout.elements.contains { $0.name.contains("Eastern exit") })
        XCTAssertTrue(kobrynBundle.setup.playerUnits.contains { $0.name.contains("60th Reserve") })
        XCTAssertTrue(kobrynBundle.setup.guderianUnits.contains { $0.name.contains("2nd Motorized") })
        XCTAssertTrue(kobrynBundle.balance.scoreChannels.contains { $0.name.contains("Cohesion") })
        XCTAssertTrue(kobrynBundle.aiPlan.orders.contains { $0.id == "kobryn-exit-threat" })
    }

    func testFranceCampaignSystemsExposeArmorAirAndChannelRules() throws {
        XCTAssertEqual(
            FranceCampaignSystemCatalog.franceScenarioIDs,
            [.sedan, .stonne, .montcornet, .amiensAbbeville, .boulogne, .calais, .dunkirk, .fallRot]
        )

        for id in FranceCampaignSystemCatalog.franceScenarioIDs {
            let profile = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: id))

            XCTAssertEqual(profile.id, id)
            XCTAssertFalse(profile.assets.isEmpty)
            XCTAssertFalse(profile.specialRules.isEmpty)
            XCTAssertFalse(profile.operationalProblem.isEmpty)
            XCTAssertFalse(profile.playerDoctrine.isEmpty)
        }

        let stonne = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .stonne))
        let montcornet = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .montcornet))
        let amiens = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .amiensAbbeville))
        let boulogne = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .boulogne))
        let calais = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .calais))
        let dunkirk = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .dunkirk))
        let fallRot = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .fallRot))

        XCTAssertTrue(stonne.assets.contains { $0.kind == .heavyTank && $0.name.contains("Char B1") })
        XCTAssertTrue(montcornet.assets.contains { $0.kind == .airPressure && $0.name.contains("Luftwaffe") })
        XCTAssertTrue(amiens.assets.contains { $0.kind == .riverCrossing && $0.name.contains("Somme") })
        XCTAssertTrue(amiens.specialRules.contains { $0.name.contains("Channel cut") })
        XCTAssertTrue(boulogne.assets.contains { $0.kind == .navalSupport && $0.name.contains("destroyer") })
        XCTAssertTrue(calais.assets.contains { $0.name.contains("Dunkirk time") })
        XCTAssertTrue(dunkirk.specialRules.contains { $0.name.contains("Command-scope caveat") })
        XCTAssertTrue(fallRot.assets.contains { $0.kind == .withdrawalRoute && $0.name.contains("Retreat") })
    }

    func testFranceExpansionScenariosAreHandAuthoredAndProxyLoadable() throws {
        for id in [GuderianBattleID.stonne, .montcornet, .amiensAbbeville, .boulogne, .calais, .dunkirk, .fallRot] {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let bundle = ScenarioContentCatalog.bundle(for: scenario)
            let loadout = try XCTUnwrap(DZWScenarioLoader.load(id, seed: UInt32(19400500 + scenario.order)))

            XCTAssertEqual(scenario.status, .dzwProxyLoadable)
            XCTAssertEqual(loadout.playerArmyName, "British")
            XCTAssertTrue(loadout.adapterNotes.contains { $0.contains("France 1940 campaign systems") })
            XCTAssertGreaterThanOrEqual(bundle.balance.maxPlayerScore, 8)
            XCTAssertFalse(bundle.setup.playerUnits.isEmpty)
            XCTAssertFalse(bundle.setup.guderianUnits.isEmpty)
            XCTAssertFalse(bundle.aiPlan.orders.isEmpty)
        }

        let stonne = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .stonne))
        XCTAssertTrue(stonne.mapLayout.elements.contains { $0.name.contains("Stonne") })
        XCTAssertTrue(stonne.setup.playerUnits.contains { $0.name.contains("Char B1") })
        XCTAssertTrue(stonne.balance.scoreChannels.contains { $0.name.contains("Heavy-tank") })

        let montcornet = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .montcornet))
        XCTAssertTrue(montcornet.mapLayout.elements.contains { $0.name.contains("German column") })
        XCTAssertTrue(montcornet.balance.reinforcements.contains { $0.unitName.contains("Luftwaffe") })

        let amiens = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .amiensAbbeville))
        XCTAssertTrue(amiens.mapLayout.elements.contains { $0.name.contains("Abbeville") })
        XCTAssertTrue(amiens.balance.scoreChannels.contains { $0.name.contains("Evacuation") })

        let boulogne = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .boulogne))
        XCTAssertTrue(boulogne.mapLayout.elements.contains { $0.name.contains("Harbor") })
        XCTAssertTrue(boulogne.setup.playerUnits.contains { $0.name.contains("destroyer") })
        XCTAssertTrue(boulogne.balance.scoreChannels.contains { $0.name.contains("Port denial") })

        let calais = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .calais))
        XCTAssertTrue(calais.setup.playerUnits.contains { $0.name.contains("supply") })
        XCTAssertTrue(calais.balance.scoreChannels.contains { $0.name.contains("Dunkirk time") })

        let dunkirk = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .dunkirk))
        XCTAssertTrue(dunkirk.setup.triggers.contains { $0.name.contains("Command-scope caveat") })
        XCTAssertTrue(dunkirk.balance.scoreChannels.contains { $0.name.contains("Evacuated") })

        let fallRot = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .fallRot))
        XCTAssertTrue(fallRot.mapLayout.elements.contains { $0.name.contains("Belfort") })
        XCTAssertTrue(fallRot.balance.reinforcements.contains { $0.unitName.contains("Army Group C") })
    }

    func testEasternFrontSystemsExposePocketBreakoutAndLogisticsRules() throws {
        XCTAssertEqual(
            EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs,
            [.bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .mtsensk, .moscowTulaKashira]
        )

        for id in EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs {
            let profile = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: id))

            XCTAssertEqual(profile.id, id)
            XCTAssertFalse(profile.assets.isEmpty)
            XCTAssertFalse(profile.specialRules.isEmpty)
            XCTAssertFalse(profile.operationalProblem.isEmpty)
            XCTAssertFalse(profile.playerDoctrine.isEmpty)
        }

        let bialystok = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .bialystokMinsk))
        XCTAssertTrue(bialystok.assets.contains { $0.kind == .pocket && $0.name.contains("pockets") })
        XCTAssertTrue(bialystok.assets.contains { $0.kind == .mechanizedCorps })
        XCTAssertTrue(bialystok.specialRules.contains { $0.name.contains("Double envelopment") })
        XCTAssertTrue(bialystok.specialRules.contains { $0.name.contains("Command preservation") })

        let smolensk = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .smolensk))
        XCTAssertTrue(smolensk.assets.contains { $0.kind == .riverCrossing && $0.name.contains("Dnieper") })
        XCTAssertTrue(smolensk.specialRules.contains { $0.name.contains("Logistics crisis") })

        let roslavl = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .roslavlNovozybkov))
        XCTAssertTrue(roslavl.assets.contains { $0.name.contains("southward-turn") || $0.name.contains("southward") })
        XCTAssertTrue(roslavl.specialRules.contains { $0.name.contains("Intelligence") })

        let kiev = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .kiev))
        XCTAssertTrue(kiev.assets.contains { $0.kind == .commandPost })
        XCTAssertTrue(kiev.specialRules.contains { $0.name.contains("Pincer link-up") })

        let bryansk = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .bryansk))
        XCTAssertTrue(bryansk.assets.contains { $0.name.contains("Tula") })
        XCTAssertTrue(bryansk.specialRules.contains { $0.name.contains("Unexpected axis") })

        let mtsensk = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .mtsensk))
        XCTAssertTrue(mtsensk.assets.contains { $0.kind == .armorAmbush && $0.name.contains("Katukov") })
        XCTAssertTrue(mtsensk.specialRules.contains { $0.name.contains("T-34") })

        let moscow = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.assets.contains { $0.name.contains("Venev") })
        XCTAssertTrue(moscow.specialRules.contains { $0.name.contains("Kashira") })
    }

    func testBialystokMinskIsHandAuthoredAndProxyLoadable() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .bialystokMinsk))
        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        let loadout = try XCTUnwrap(DZWScenarioLoader.load(.bialystokMinsk, seed: 19410622))

        XCTAssertEqual(scenario.status, .dzwProxyLoadable)
        XCTAssertEqual(loadout.playerArmyName, "Soviet")
        XCTAssertEqual(loadout.opponentArmyName, "German")
        XCTAssertTrue(loadout.adapterNotes.contains { $0.contains("Eastern Front campaign systems") })

        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("Minsk") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("2nd Panzer") })
        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("10th Army") })
        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("mechanized") })
        XCTAssertTrue(bundle.setup.guderianUnits.contains { $0.name.contains("2nd Panzer Group") })
        XCTAssertTrue(bundle.aiPlan.orders.contains { $0.id == "bialystok-pocket-close" })
        XCTAssertTrue(bundle.balance.scoreChannels.contains { $0.name.contains("Breakout") })
        XCTAssertTrue(bundle.balance.reinforcements.contains { $0.unitName.contains("Mechanized") && $0.side == .player })
    }

    func testCycle210EasternFrontScenariosAreHandAuthoredAndProxyLoadable() throws {
        for id in [GuderianBattleID.smolensk, .roslavlNovozybkov, .kiev, .bryansk] {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let bundle = ScenarioContentCatalog.bundle(for: scenario)
            let loadout = try XCTUnwrap(DZWScenarioLoader.load(id, seed: UInt32(19410000 + scenario.order)))

            XCTAssertEqual(scenario.status, .dzwProxyLoadable)
            XCTAssertEqual(loadout.playerArmyName, "Soviet")
            XCTAssertEqual(loadout.opponentArmyName, "German")
            XCTAssertTrue(loadout.adapterNotes.contains { $0.contains("Eastern Front campaign systems") })
            XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(id))
            XCTAssertNotNil(EasternFrontCampaignSystemCatalog.profile(for: id))
            XCTAssertGreaterThanOrEqual(bundle.balance.maxPlayerScore, 9)
            XCTAssertFalse(bundle.setup.playerUnits.isEmpty)
            XCTAssertFalse(bundle.setup.guderianUnits.isEmpty)
            XCTAssertFalse(bundle.aiPlan.orders.isEmpty)
            XCTAssertFalse(bundle.logEntries.isEmpty)
        }

        let smolensk = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .smolensk))
        XCTAssertTrue(smolensk.mapLayout.elements.contains { $0.name.contains("Yartsevo") })
        XCTAssertTrue(smolensk.setup.playerUnits.contains { $0.name.contains("reserve") })
        XCTAssertTrue(smolensk.aiPlan.orders.contains { $0.id == "smolensk-pocket-close" })
        XCTAssertTrue(smolensk.balance.scoreChannels.contains { $0.name.contains("supply strain") })

        let roslavl = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .roslavlNovozybkov))
        XCTAssertTrue(roslavl.mapLayout.elements.contains { $0.name.contains("Southward") || $0.name.contains("southward") })
        XCTAssertTrue(roslavl.setup.playerUnits.contains { $0.name.contains("reconnaissance") })
        XCTAssertTrue(roslavl.aiPlan.orders.contains { $0.id == "roslavl-counterpressure" })
        XCTAssertTrue(roslavl.balance.scoreChannels.contains { $0.name.contains("Column") })

        let kiev = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .kiev))
        XCTAssertTrue(kiev.mapLayout.elements.contains { $0.name.contains("command") || $0.name.contains("Command") })
        XCTAssertTrue(kiev.setup.playerUnits.contains { $0.name.contains("command") || $0.name.contains("Command") })
        XCTAssertTrue(kiev.aiPlan.orders.contains { $0.id == "kiev-linkup" })
        XCTAssertTrue(kiev.balance.scoreChannels.contains { $0.name.contains("Command evacuation") })

        let bryansk = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .bryansk))
        XCTAssertTrue(bryansk.mapLayout.elements.contains { $0.name.contains("Orel") })
        XCTAssertTrue(bryansk.setup.playerUnits.contains { $0.name.contains("50th Army") })
        XCTAssertTrue(bryansk.aiPlan.orders.contains { $0.id == "bryansk-pocket-close" })
        XCTAssertTrue(bryansk.balance.scoreChannels.contains { $0.name.contains("Tula road") })
    }

    func testCycle240MtsenskAndMoscowExpansionArePlayableDataSlices() throws {
        let mtsenskScenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .mtsensk))
        let mtsensk = ScenarioContentCatalog.bundle(for: mtsenskScenario)
        let mtsenskLoadout = try XCTUnwrap(DZWScenarioLoader.load(.mtsensk, seed: 19411004))

        XCTAssertEqual(mtsenskScenario.status, .dzwProxyLoadable)
        XCTAssertEqual(mtsenskLoadout.playerArmyName, "Soviet")
        XCTAssertTrue(mtsensk.mapLayout.elements.contains { $0.name.contains("Katukov") })
        XCTAssertTrue(mtsensk.mapLayout.elements.contains { $0.name.contains("Tula road") })
        XCTAssertTrue(mtsensk.setup.playerUnits.contains { $0.name.contains("4th Tank Brigade") })
        XCTAssertTrue(mtsensk.setup.guderianUnits.contains { $0.name.contains("4th Panzer") })
        XCTAssertTrue(mtsensk.setup.triggers.contains { $0.name.contains("T-34") })
        XCTAssertTrue(mtsensk.aiPlan.orders.contains { $0.id == "mtsensk-ambush-contact" })
        XCTAssertTrue(mtsensk.balance.scoreChannels.contains { $0.name.contains("German tank losses") })
        XCTAssertTrue(mtsensk.historicalOverlay.caveats.contains { $0.contains("Tank-loss claims") })

        let moscow = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.mapLayout.elements.contains { $0.name.contains("Venev") })
        XCTAssertTrue(moscow.mapLayout.elements.contains { $0.name.contains("Belov") })
        XCTAssertTrue(moscow.setup.playerUnits.contains { $0.name.contains("Belov") })
        XCTAssertTrue(moscow.setup.guderianUnits.contains { $0.name.contains("Venev") })
        XCTAssertTrue(moscow.aiPlan.orders.contains { $0.id == "moscow-venev-bypass" })
        XCTAssertTrue(moscow.balance.scoreChannels.contains { $0.name.contains("Mordves") })
        XCTAssertTrue(moscow.historicalOverlay.caveats.contains { $0.contains("southern pincer") })
    }

    func testHistoricalOverlaysCoverEveryScenario() throws {
        XCTAssertEqual(ScenarioHistoricalOverlayCatalog.allOverlays.count, GuderianCampaignCatalog.all.count)

        for scenario in GuderianCampaignCatalog.all {
            let overlay = ScenarioHistoricalOverlayCatalog.overlay(for: scenario)

            XCTAssertEqual(overlay.id, scenario.id)
            XCTAssertFalse(overlay.commanderContext.isEmpty)
            XCTAssertFalse(overlay.mapNote.isEmpty)
            XCTAssertFalse(overlay.outcomeSummary.isEmpty)
            XCTAssertFalse(overlay.caveats.isEmpty)
            XCTAssertEqual(overlay.sourceNotes.count, scenario.sourceLinks.count)
        }

        let dunkirk = try XCTUnwrap(ScenarioHistoricalOverlayCatalog.overlay(for: .dunkirk))
        XCTAssertTrue(dunkirk.caveats.contains { $0.contains("indirect") })
    }

    func testAIRefinementSnapshotsCoverEveryScenario() throws {
        XCTAssertEqual(GermanAIRefinementCatalog.allSnapshots.count, GuderianCampaignCatalog.all.count)

        for scenario in GuderianCampaignCatalog.all {
            let snapshot = GermanAIRefinementCatalog.snapshot(for: scenario)
            let plan = GermanAIPlanCatalog.plan(for: scenario)

            XCTAssertEqual(snapshot.id, scenario.id)
            XCTAssertEqual(Optional(snapshot.primaryOrderID), plan.orders.first?.id)
            XCTAssertEqual(snapshot.difficultyTiers, GermanAIDifficultyTier.allCases)
            XCTAssertGreaterThanOrEqual(snapshot.fallbackBehaviors.count, 3)
            XCTAssertGreaterThan(snapshot.deterministicSeedHint, 0)
        }

        let mtsensk = try XCTUnwrap(GermanAIRefinementCatalog.snapshot(for: .mtsensk))
        XCTAssertTrue(mtsensk.fallbackBehaviors.contains { $0.response.contains("mobile reserve") || $0.response.contains("security group") })
    }

    func testBalanceAuditAndFullCampaignSmokeCoverage() throws {
        XCTAssertEqual(ScenarioBalanceAuditCatalog.allAudits.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(ScenarioContentCatalog.handAuthoredScenarioIDs, Set(GuderianBattleID.allCases))

        for scenario in GuderianCampaignCatalog.all {
            let audit = ScenarioBalanceAuditCatalog.audit(for: scenario)
            let bundle = ScenarioContentCatalog.bundle(for: scenario)
            let loadout = try XCTUnwrap(DZWScenarioLoader.load(scenario.id, seed: UInt32(24_000 + scenario.order)))
            let game = try XCTUnwrap(loadout.makeGame(), "\(scenario.title) should create a proxy dzw game")
            defer { game_destroy(game) }

            XCTAssertEqual(scenario.status, .dzwProxyLoadable)
            XCTAssertEqual(audit.id, scenario.id)
            XCTAssertGreaterThanOrEqual(audit.victoryGradeCount, 3)
            XCTAssertGreaterThan(audit.maximumPlayerScore, 0)
            XCTAssertFalse(bundle.mapLayout.elements.isEmpty)
            XCTAssertFalse(bundle.setup.units.isEmpty)
            XCTAssertFalse(bundle.aiPlan.orders.isEmpty)
            XCTAssertFalse(bundle.balance.outcomeBands.isEmpty)
            XCTAssertFalse(bundle.logEntries.isEmpty)
            XCTAssertGreaterThan(Int(game_unit_count(game)), 0)
            XCTAssertGreaterThan(Int(game_objective_count(game)), 0)
        }
    }

    func testCycle250CampaignSaveStateRoundTripsProgressAndSelection() throws {
        var progress = CampaignProgress()
        let record = CampaignCompletionRecord(
            scenarioID: .tucholaForest,
            score: 12,
            victoryBand: .decisive,
            completedTurn: 6,
            note: "Release save/load regression."
        )
        progress.recordCompletion(record)

        let state = CampaignSaveState(
            selectedScenarioID: .sedan,
            playMode: .standalone,
            progress: progress,
            savedAt: Date(timeIntervalSince1970: 1_941)
        )
        let data = try CampaignSaveCodec.encode(state)
        let decoded = try CampaignSaveCodec.decode(data)

        XCTAssertEqual(decoded, state)
        XCTAssertEqual(CampaignSaveCodec.decodeIfCurrent(data), state)
        XCTAssertEqual(decoded.progress.completionRecord(for: .tucholaForest), record)
        XCTAssertEqual(decoded.selectedScenarioID, .sedan)
        XCTAssertEqual(decoded.playMode, .standalone)

        let stale = CampaignSaveState(
            selectedScenarioID: .wizna,
            playMode: .chronological,
            progress: progress,
            savedAt: Date(timeIntervalSince1970: 1_942),
            schemaVersion: 0
        )
        XCTAssertNil(CampaignSaveCodec.decodeIfCurrent(try CampaignSaveCodec.encode(stale)))
    }

    func testCycle250CampaignCompletionSummaryUnlocksFinalScreen() throws {
        var progress = CampaignProgress()
        var expectedScore = 0

        XCTAssertFalse(progress.completionSummary().isComplete)
        XCTAssertEqual(progress.completionSummary().nextScenarioID, .tucholaForest)

        for scenario in GuderianCampaignCatalog.all {
            let balance = ScenarioBalanceCatalog.profile(for: scenario)
            expectedScore += balance.maxPlayerScore
            progress.recordCompletion(
                CampaignCompletionRecord(
                    scenarioID: scenario.id,
                    score: balance.maxPlayerScore,
                    victoryBand: .operational,
                    completedTurn: balance.targetTurns.upperBound,
                    note: "Cycle 250 full-campaign completion regression."
                )
            )
        }

        let summary = progress.completionSummary()
        XCTAssertTrue(summary.isComplete)
        XCTAssertTrue(progress.isComplete())
        XCTAssertEqual(summary.completedScenarios, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(summary.remainingScenarioIDs, [])
        XCTAssertNil(summary.nextScenarioID)
        XCTAssertEqual(summary.totalScore, expectedScore)
        XCTAssertEqual(summary.victoryBands[.operational], GuderianCampaignCatalog.all.count)
        XCTAssertEqual(summary.completionTitle, "Full Campaign Complete")
    }

    func testCycle250FullCampaignShipReportIsReadyCreditedAndBudgeted() throws {
        let report = FullCampaignShipReportCatalog.report()

        XCTAssertTrue(report.isShipReady, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.cycleRange, 241...250)
        XCTAssertEqual(report.scenarioCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.proxyLoadableCount, report.scenarioCount)
        XCTAssertEqual(report.handAuthoredCount, report.scenarioCount)
        XCTAssertEqual(report.historicalOverlayCount, report.scenarioCount)
        XCTAssertEqual(report.aiSnapshotCount, report.scenarioCount)
        XCTAssertEqual(report.balanceAuditCount, report.scenarioCount)
        XCTAssertTrue(report.blockers.isEmpty)
        XCTAssertTrue(report.releaseChecklist.allSatisfy { $0.status == .passed })
        XCTAssertTrue(report.releaseChecklist.contains { $0.id == "save-load" })
        XCTAssertTrue(report.releaseChecklist.contains { $0.id == "completion" })
        XCTAssertTrue(report.credits.contains { $0.id == "engine" && $0.sourcePathOrURL == "dzw/" })
        XCTAssertTrue(report.credits.contains { $0.id == "icon" && $0.sourcePathOrURL.contains("AppIconSource") })
        XCTAssertGreaterThanOrEqual(report.accessibilityItems.count, 4)
        XCTAssertGreaterThanOrEqual(report.performanceBudgets.count, 4)
        XCTAssertTrue(report.performanceBudgets.allSatisfy(\.isPassing))
        XCTAssertTrue(report.buildCommands.contains("swift test"))
        XCTAssertTrue(report.buildCommands.contains { $0.contains("xcodebuild") })
    }

    func testCycle260NativePlayabilityArchitectureDefinesGuardedDZWBoundary() throws {
        let architecture = NativePlayabilityArchitectureCatalog.architecture

        XCTAssertEqual(architecture.cycleRange, 251...260)
        XCTAssertEqual(architecture.guardMacro, "HEINZ_GUDERIAN_GAME")
        XCTAssertEqual(architecture.guardMacro, NativePlayabilityArchitectureCatalog.guardMacro)
        XCTAssertEqual(architecture.demoPlayableTargetCycle, 300)
        XCTAssertEqual(architecture.fullCampaignPlayableTargetCycle, 400)
        XCTAssertFalse(architecture.dzwEditsRequiredDuringArchitectureCycle)

        let reusedIDs = Set(architecture.reusedEngineSystems.map(\.id))
        XCTAssertTrue(reusedIDs.isSuperset(of: ["turn-phases", "movement-rules", "combat-rules", "objective-scoring", "snapshots"]))
        XCTAssertTrue(architecture.reusedEngineSystems.allSatisfy { $0.owner == .dzwEngine })

        let guderianOwnedIDs = Set(architecture.guderianOwnedSystems.map(\.id))
        XCTAssertTrue(guderianOwnedIDs.isSuperset(of: ["scenario-instance-data", "historical-campaign-flow", "battle-board-ui", "campaign-automation"]))
        XCTAssertTrue(architecture.guderianOwnedSystems.contains { $0.owner == .guderianCore })
        XCTAssertTrue(architecture.guderianOwnedSystems.contains { $0.owner == .guderianApp })
        XCTAssertTrue(architecture.guderianOwnedSystems.contains { $0.owner == .guderianTest })

        let hooks = Dictionary(uniqueKeysWithValues: architecture.requiredEngineHooks.map { ($0.id, $0) })
        XCTAssertEqual(Set(hooks.keys), ["scenario-instance-loader", "scenario-mission-state", "scenario-event-triggers", "scenario-ai-controls"])
        XCTAssertEqual(hooks["scenario-instance-loader"]?.firstNeededCycles, 271...280)
        XCTAssertEqual(hooks["scenario-mission-state"]?.firstNeededCycles, 271...300)
        XCTAssertTrue(architecture.requiredEngineHooks.allSatisfy { $0.guardMacro == "HEINZ_GUDERIAN_GAME" })
        XCTAssertTrue(architecture.requiredEngineHooks.allSatisfy { $0.owner == .dzwEngine })
    }

    func testCycle280EveryBattleHasNativeLoaderButStillNeedsBoardHook() throws {
        let reports = NativePlayabilityArchitectureCatalog.allReadinessReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)

        for report in reports {
            XCTAssertTrue(report.hasMinimumAuthoredInputs, "\(report.title): \(report.summary)")
            XCTAssertEqual(report.status, .nativeBoardHookMissing)
            XCTAssertTrue(report.requiredHookIDs.contains("scenario-instance-loader"))
            XCTAssertTrue(report.notes.contains { $0.contains("skirmish bridge") })
            XCTAssertTrue(report.notes.contains { $0.contains("remaining guarded engine hook") })
        }

        let demoReports = reports.filter { GuderianCampaignCatalog.demoIDs.contains($0.id) }
        XCTAssertEqual(demoReports.count, GuderianCampaignCatalog.demoIDs.count)
        XCTAssertTrue(demoReports.allSatisfy { $0.notes.contains { $0.contains("cycle 300") } })
    }

    func testCycle270NativeBattleInstancesConvertEveryScenarioIntoEngineBlueprints() throws {
        XCTAssertEqual(NativeBattleInstanceCatalog.modelCycleRange, 261...270)

        let instances = NativeBattleInstanceCatalog.allInstances
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(instances.map(\.id), orderedIDs)
        XCTAssertEqual(instances.count, GuderianCampaignCatalog.all.count)

        for instance in instances {
            let bundle = try XCTUnwrap(ScenarioContentCatalog.bundle(for: instance.id))
            let deploymentZoneIDs = Set(instance.deploymentZones.map(\.id))
            let blueprint = instance.engineBlueprint(seed: UInt32(90_000 + instance.order))

            XCTAssertTrue(instance.isModeledForNativeGameplay, instance.title)
            XCTAssertTrue(instance.requiresNativeScenarioLoader)
            XCTAssertEqual(instance.units.count, bundle.setup.units.count)
            XCTAssertEqual(instance.terrain.count, bundle.mapLayout.elements.count)
            XCTAssertEqual(instance.objectives.count, bundle.scenario.objectives.count)
            XCTAssertEqual(instance.reinforcements.count, bundle.balance.reinforcements.count)
            XCTAssertGreaterThanOrEqual(instance.events.count, bundle.setup.triggers.count + bundle.balance.reinforcements.count + bundle.balance.pacingRules.count)
            XCTAssertTrue(instance.units.allSatisfy { deploymentZoneIDs.contains($0.deploymentZoneID) })
            XCTAssertTrue(instance.units.allSatisfy { !$0.weapons.isEmpty })
            XCTAssertTrue(instance.objectives.allSatisfy { $0.position.x >= 0 && $0.position.x <= instance.frame.width })
            XCTAssertTrue(instance.objectives.allSatisfy { $0.position.y >= 0 && $0.position.y <= instance.frame.height })

            XCTAssertTrue(blueprint.isCompleteForScenarioLoader, instance.title)
            XCTAssertEqual(blueprint.units.count, instance.units.count)
            XCTAssertEqual(blueprint.objectives.count, instance.objectives.count)
            XCTAssertEqual(blueprint.terrain.count, instance.terrain.count)
            XCTAssertEqual(blueprint.missionTargetScore, instance.victory.missionTargetScore)
            XCTAssertTrue(blueprint.units.allSatisfy { $0.x >= 0 && $0.x <= blueprint.engineBoardFrame.width })
            XCTAssertTrue(blueprint.units.allSatisfy { $0.y >= 0 && $0.y <= blueprint.engineBoardFrame.height })
            XCTAssertTrue(blueprint.objectives.allSatisfy { $0.victoryPoints > 0 })
        }
    }

    func testCycle270DemoInstancesExposePlayableClassesAndScenarioEvents() throws {
        let wizna = try XCTUnwrap(NativeBattleInstanceCatalog.instance(for: .wizna))
        XCTAssertTrue(wizna.terrain.contains { $0.kind == .bunker })
        XCTAssertTrue(wizna.units.contains { unit in unit.weapons.contains { $0.role == .antiTank } })
        XCTAssertTrue(wizna.events.contains { $0.kind == .tutorial })

        let sedan = try XCTUnwrap(NativeBattleInstanceCatalog.instance(for: .sedan))
        XCTAssertTrue(sedan.terrain.contains { $0.kind == .river })
        XCTAssertTrue(sedan.terrain.contains { $0.kind == .bridge })
        XCTAssertTrue(sedan.units.contains { $0.mobility == .engineer })
        XCTAssertTrue(sedan.units.contains { unit in unit.weapons.contains { $0.role == .airSupport } })
        XCTAssertTrue(sedan.events.contains { $0.kind == .reinforcement })

        let moscow = try XCTUnwrap(NativeBattleInstanceCatalog.instance(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.terrain.contains { $0.name.contains("Tula") })
        XCTAssertTrue(moscow.units.contains { $0.side == .player && $0.mobility == .armor })
        XCTAssertTrue(moscow.events.contains { $0.kind == .reinforcement })
        XCTAssertTrue(moscow.victory.targetTurns.upperBound >= 7)
    }

    func testCycle280NativeScenarioLoaderCreatesSkirmishBridgeForEveryBattle() throws {
        XCTAssertEqual(NativeScenarioLoader.cycleRange, 271...280)

        for scenario in GuderianCampaignCatalog.all {
            let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(100_000 + scenario.order))
            let loadedGame = try XCTUnwrap(loadout.makeGame(), "\(scenario.title) should create a native-loader skirmish bridge")

            XCTAssertEqual(loadout.scenario.id, scenario.id)
            XCTAssertFalse(loadout.usesForcePresetProxy)
            XCTAssertEqual(loadout.gameCreationMode, .nativeBlueprintSkirmishBridge)
            XCTAssertTrue(loadout.canCreateSkirmishBridge, scenario.title)
            XCTAssertFalse(loadout.playerEntries.isEmpty, "\(scenario.title) needs player army-list entries")
            XCTAssertFalse(loadout.opponentEntries.isEmpty, "\(scenario.title) needs opponent army-list entries")
            XCTAssertTrue(loadout.playerEntries.allSatisfy { $0.count > 0 })
            XCTAssertTrue(loadout.opponentEntries.allSatisfy { $0.count > 0 })
            XCTAssertTrue(loadout.warnings.contains { $0.id.contains("board-hook") })

            XCTAssertGreaterThan(Int(game_unit_count(loadedGame.handle)), 0)
            XCTAssertGreaterThan(Int(game_objective_count(loadedGame.handle)), 0)
            XCTAssertGreaterThan(loadedGame.deploymentReport.attempted, 0, "\(scenario.title) should attempt scenario deployments")
            XCTAssertTrue(loadedGame.deploymentReport.placedAnyScenarioUnit, "\(scenario.title) should place at least one native blueprint unit")
        }
    }

    func testCycle280DemoNativeLoaderUsesScenarioBlueprintPositions() throws {
        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(110_000 + scenario.order))
            let loadedGame = try XCTUnwrap(loadout.makeGame())
            let firstPlayerSpawn = try XCTUnwrap(loadout.blueprint.units.first { $0.side == .player })
            let playerUnit = try XCTUnwrap((0..<Int(game_unit_count(loadedGame.handle))).lazy
                .map { game_unit_view(loadedGame.handle, Int32($0)) }
                .first { $0.owner == TE_PLAYER_ONE && !$0.embarked })

            XCTAssertLessThanOrEqual(abs(Double(playerUnit.x) - firstPlayerSpawn.x), 8.5, scenario.title)
            XCTAssertLessThanOrEqual(abs(Double(playerUnit.y) - firstPlayerSpawn.y), 8.5, scenario.title)
            XCTAssertNotEqual(game_mission_view(loadedGame.handle).target_score, Int32(loadout.blueprint.missionTargetScore), "The guarded board/mission C hook should still be visible as pending.")
        }
    }

    func testGuderianTestAutomationRunsEveryBattleAndSurfacesDiagnostics() throws {
        let report = CampaignAutomationRunner.runCampaign()
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(report.reports.map(\.id), orderedIDs)
        XCTAssertEqual(report.reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.completionSummary.completedScenarios, GuderianCampaignCatalog.all.count)
        XCTAssertGreaterThan(report.reports.reduce(0) { $0 + $1.actionsAttempted }, 0)
        XCTAssertGreaterThan(report.reports.reduce(0) { $0 + $1.phaseAdvances }, 0)

        for battle in report.reports {
            XCTAssertFalse(battle.status.isTerminalProblem, "\(battle.title): \(battle.issues.map(\.detail).joined(separator: "\n"))")
            XCTAssertGreaterThan(battle.engineUnitCount, 0, "\(battle.title) should load engine units")
            XCTAssertGreaterThan(battle.engineObjectiveCount, 0, "\(battle.title) should load engine objectives")
            XCTAssertFalse(battle.steps.isEmpty, "\(battle.title) should expose an automation timeline")
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Loader" })
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Playability" })
            XCTAssertTrue(battle.issues.contains { $0.stage == "Native Playability" && $0.kind == .warning })
            XCTAssertTrue(battle.issues.contains { $0.stage == "Native Loader" && $0.kind == .warning })
            XCTAssertFalse(battle.playerArmy.isEmpty)
            XCTAssertFalse(battle.opponentArmy.isEmpty)
        }
    }

    func testTucholaForestIsFirstFullCampaignPlayableDataSlice() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        let loadout = try XCTUnwrap(DZWScenarioLoader.load(.tucholaForest, seed: 19390901))

        XCTAssertEqual(scenario.status, .dzwProxyLoadable)
        XCTAssertGreaterThanOrEqual(scenario.sourceLinks.count, 3)
        XCTAssertEqual(loadout.playerArmyName, "British")
        XCTAssertEqual(loadout.opponentArmyName, "German")
        XCTAssertTrue(loadout.adapterNotes.contains { $0.contains("Polish campaign systems") })

        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.kind == .river && $0.name.contains("Brda") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.kind == .forest && $0.name.contains("Tuchola") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("Chojnice") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("Krojanty") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("Bydgoszcz") })

        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("9th Infantry") })
        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("Cavalry") })
        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("demolition") })
        XCTAssertTrue(bundle.setup.guderianUnits.contains { $0.name.contains("engineers") })
        XCTAssertTrue(bundle.setup.triggers.contains { $0.name.contains("Pincer") })

        XCTAssertTrue(bundle.aiPlan.orders.contains { $0.id == "tuchola-pincer" })
        XCTAssertTrue(bundle.balance.scoreChannels.contains { $0.name.contains("Brda") })
        XCTAssertTrue(bundle.balance.scoreChannels.contains { $0.name.contains("Withdraw") })
        XCTAssertTrue(bundle.balance.reinforcements.contains { $0.unitName.contains("27th Infantry") && $0.side == .player })
        XCTAssertTrue(bundle.balance.reinforcements.contains { $0.unitName.contains("pincer") && $0.side == .guderianAI })
    }
}
