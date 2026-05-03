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
            [.bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .moscowTulaKashira]
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
