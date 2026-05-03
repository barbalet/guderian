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
