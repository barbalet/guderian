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

    func testCycle400AllBattlesAreNativePlayableWithShipReadinessNotes() throws {
        let reports = NativePlayabilityArchitectureCatalog.allReadinessReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)
        let nativePlayableIDs = Set(GuderianCampaignCatalog.demoIDs + PolishCampaignSystemCatalog.polishScenarioIDs + FranceCampaignSystemCatalog.franceScenarioIDs + EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs)
        let polishIDs = Set(PolishCampaignSystemCatalog.polishScenarioIDs)
        let franceIDs = Set(FranceCampaignSystemCatalog.franceScenarioIDs)
        let easternFrontIDs = Set(EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(nativePlayableIDs.count, GuderianCampaignCatalog.all.count)

        for report in reports {
            XCTAssertTrue(report.hasMinimumAuthoredInputs, "\(report.title): \(report.summary)")
            XCTAssertFalse(report.requiredHookIDs.contains("scenario-instance-loader"))
            XCTAssertTrue(report.notes.contains { $0.contains("scenario-specific terrain/objectives/mission target") })
            XCTAssertTrue(report.notes.contains { $0.contains("Cycle 375 native AI/event pass") })
            XCTAssertTrue(report.notes.contains { $0.contains("Cycle 380 native AI/event execution") })
            XCTAssertTrue(report.notes.contains { $0.contains("Cycle 390 balance/UX audit") })

            if nativePlayableIDs.contains(report.id) {
                XCTAssertEqual(report.status, .nativePlayable)
                XCTAssertFalse(report.requiredHookIDs.contains("scenario-mission-state"))
                XCTAssertFalse(report.requiredHookIDs.contains("scenario-event-triggers"))
                XCTAssertFalse(report.requiredHookIDs.contains("scenario-ai-controls"))
                XCTAssertTrue(report.requiredHookIDs.isEmpty, report.title)
                if easternFrontIDs.contains(report.id) {
                    XCTAssertTrue(report.notes.contains { $0.contains("Cycle 370 native Eastern Front pack") })
                } else if franceIDs.contains(report.id) {
                    XCTAssertTrue(report.notes.contains { $0.contains("Cycle 345 native France pack") })
                } else if polishIDs.contains(report.id) {
                    XCTAssertTrue(report.notes.contains { $0.contains("Cycle 325 native Poland pack") })
                } else {
                    XCTAssertTrue(report.notes.contains { $0.contains("Cycle 300 demo parity") })
                }
            }
        }

        let demoReports = reports.filter { GuderianCampaignCatalog.demoIDs.contains($0.id) }
        XCTAssertEqual(demoReports.count, GuderianCampaignCatalog.demoIDs.count)
        XCTAssertTrue(demoReports.allSatisfy { $0.notes.contains { $0.contains("cycles 291-300") } })

        let polishReports = reports.filter { polishIDs.contains($0.id) }
        XCTAssertEqual(polishReports.count, PolishCampaignSystemCatalog.polishScenarioIDs.count)
        XCTAssertTrue(polishReports.allSatisfy { $0.notes.contains { $0.contains("Cycle 325 native Poland pack") } })

        let franceReports = reports.filter { franceIDs.contains($0.id) }
        XCTAssertEqual(franceReports.count, FranceCampaignSystemCatalog.franceScenarioIDs.count)
        XCTAssertTrue(franceReports.allSatisfy { $0.notes.contains { $0.contains("Cycle 345 native France pack") } })

        let easternFrontReports = reports.filter { easternFrontIDs.contains($0.id) }
        XCTAssertEqual(easternFrontReports.count, EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs.count)
        XCTAssertTrue(easternFrontReports.allSatisfy { $0.notes.contains { $0.contains("Cycle 370 native Eastern Front pack") } })
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
        XCTAssertEqual(NativeScenarioLoader.boardHookCycleRange, 281...290)

        for scenario in GuderianCampaignCatalog.all {
            let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(100_000 + scenario.order))
            let loadedGame = try XCTUnwrap(loadout.makeGame(), "\(scenario.title) should create a native-loader skirmish bridge")

            XCTAssertEqual(loadout.scenario.id, scenario.id)
            XCTAssertFalse(loadout.usesForcePresetProxy)
            XCTAssertEqual(loadout.gameCreationMode, .nativeBlueprintSkirmishBridge)
            XCTAssertTrue(loadout.canCreateSkirmishBridge, scenario.title)
            XCTAssertTrue(loadout.canApplyScenarioBoardHook, scenario.title)
            XCTAssertFalse(loadout.playerEntries.isEmpty, "\(scenario.title) needs player army-list entries")
            XCTAssertFalse(loadout.opponentEntries.isEmpty, "\(scenario.title) needs opponent army-list entries")
            XCTAssertTrue(loadout.playerEntries.allSatisfy { $0.count > 0 })
            XCTAssertTrue(loadout.opponentEntries.allSatisfy { $0.count > 0 })
            XCTAssertTrue(loadout.warnings.contains { $0.id.contains("event-hook") })

            XCTAssertGreaterThan(Int(game_unit_count(loadedGame.handle)), 0)
            XCTAssertGreaterThan(Int(game_objective_count(loadedGame.handle)), 0)
            XCTAssertTrue(loadedGame.boardReport.isScenarioSpecific, "\(scenario.title) should apply a scenario board")
            XCTAssertEqual(game_mission_view(loadedGame.handle).target_score, Int32(loadout.blueprint.missionTargetScore))
            XCTAssertEqual(Int(game_objective_count(loadedGame.handle)), min(loadout.blueprint.objectives.count, NativeScenarioLoader.boardObjectiveCapacity))
            XCTAssertEqual(Int(game_zone_count(loadedGame.handle)), min(loadout.blueprint.terrain.filter { $0.kind != .objective && $0.kind != .airPressure }.isEmpty ? loadout.blueprint.terrain.count : loadout.blueprint.terrain.filter { $0.kind != .objective && $0.kind != .airPressure }.count, NativeScenarioLoader.boardTerrainZoneCapacity))
            XCTAssertGreaterThan(loadedGame.deploymentReport.attempted, 0, "\(scenario.title) should attempt scenario deployments")
            XCTAssertTrue(loadedGame.deploymentReport.placedAnyScenarioUnit, "\(scenario.title) should place at least one native blueprint unit")
        }
    }

    func testCycle290DemoNativeLoaderUsesScenarioBoardAndBlueprintPositions() throws {
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
            XCTAssertEqual(game_mission_view(loadedGame.handle).target_score, Int32(loadout.blueprint.missionTargetScore))
            XCTAssertEqual(String(cString: game_mission_view(loadedGame.handle).name), scenario.title)
            XCTAssertEqual(String(cString: game_objective_view(loadedGame.handle, 0).name), loadout.blueprint.objectives[0].name)
            XCTAssertGreaterThan(Int(game_zone_count(loadedGame.handle)), 0, "The guarded board/mission C hook should apply scenario terrain.")
        }
    }

    func testCycle290NativeBoardSessionExposesPlayableBoardControls() throws {
        XCTAssertEqual(NativeBoardSession.cycleRange, 281...290)

        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .sedan))
        let session = try XCTUnwrap(NativeBoardSession(scenario: scenario, seed: 19400513))
        let opening = session.snapshot()

        XCTAssertTrue(opening.isScenarioBoardPlayable)
        XCTAssertEqual(opening.scenarioID, .sedan)
        XCTAssertEqual(opening.mission.name, scenario.title)
        XCTAssertEqual(opening.mission.targetScore, NativeBattleInstanceCatalog.instance(for: scenario).victory.missionTargetScore)
        XCTAssertFalse(opening.zones.isEmpty)
        XCTAssertFalse(opening.objectives.isEmpty)
        XCTAssertFalse(opening.units.isEmpty)
        XCTAssertNotNil(opening.selectedUnit)
        XCTAssertNotNil(opening.selectedTarget)
        XCTAssertEqual(opening.phase, .movement)

        _ = session.moveSelectedUnitTowardNearestObjective(maxDistance: 2)
        let afterMove = session.snapshot()
        XCTAssertNotEqual(afterMove.lastAction.status, .idle)

        session.advancePhase()
        let shooting = session.snapshot()
        XCTAssertEqual(shooting.phase, .shooting)
        XCTAssertNotNil(shooting.selectedUnit)

        _ = session.shootSelectedTarget()
        let afterFire = session.snapshot()
        XCTAssertNotEqual(afterFire.lastAction.status, .idle)
        XCTAssertFalse(afterFire.logLines.isEmpty)
    }

    func testCycle300DemoParityCompletesDemoBattlesFromNativeBoardToDebrief() throws {
        XCTAssertEqual(NativeDemoParityRunner.cycleRange, 291...300)
        XCTAssertEqual(NativeDemoParityRunner.playableBattleIDs, GuderianCampaignCatalog.demoIDs)

        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let balance = ScenarioBalanceCatalog.profile(for: scenario)
            let completion = try NativeDemoParityRunner.runBattle(
                scenario,
                seed: UInt32(150_000 + scenario.order)
            )

            XCTAssertEqual(completion.id, id)
            XCTAssertEqual(completion.cycleStart, 291)
            XCTAssertEqual(completion.cycleEnd, 300)
            XCTAssertTrue(completion.completedFromNativeBoardToDebrief, scenario.title)
            XCTAssertTrue(completion.completedWithoutGenericProxies, scenario.title)
            XCTAssertEqual(completion.openingSnapshot.scenarioID, id)
            XCTAssertEqual(completion.openingSnapshot.mission.name, scenario.title)
            XCTAssertTrue(completion.openingSnapshot.isScenarioBoardPlayable)
            XCTAssertTrue(completion.finalSnapshot.isScenarioBoardPlayable)
            XCTAssertTrue(completion.openingSnapshot.deploymentReport.placedAnyScenarioUnit)
            XCTAssertEqual(completion.score, balance.maxPlayerScore)
            XCTAssertEqual(completion.score, completion.scoreAwards.filter(\.awarded).reduce(0) { $0 + $1.victoryPoints })
            XCTAssertTrue(balance.outcomeBands.contains { $0.grade == completion.victoryBand && $0.scoreRange.contains(completion.score) })
            XCTAssertEqual(completion.completionRecord.scenarioID, id)
            XCTAssertEqual(completion.completionRecord.score, completion.score)
            XCTAssertEqual(completion.completionRecord.victoryBand, completion.victoryBand)
            XCTAssertGreaterThan(completion.phaseAdvances, 0)
            XCTAssertFalse(completion.steps.isEmpty)
            XCTAssertTrue(completion.steps.contains { $0.phase == .movement })
            XCTAssertTrue(completion.steps.contains { $0.phase == .shooting })
            XCTAssertTrue(completion.steps.contains { $0.phase == .assault })
            XCTAssertTrue(completion.debriefSummary.contains("\(completion.score)/\(balance.maxPlayerScore) VP"))
        }
    }

    func testCycle300DemoParityCampaignProgressRecordsAllDemoCompletions() throws {
        let suite = try NativeDemoParityRunner.runDemoCampaign()

        XCTAssertEqual(suite.battleIDs, GuderianCampaignCatalog.demoIDs)
        XCTAssertEqual(suite.completions.map(\.id), GuderianCampaignCatalog.demoIDs)
        XCTAssertTrue(suite.completedAllDemoBattles)
        XCTAssertTrue(suite.summary.isComplete)
        XCTAssertEqual(suite.summary.completedScenarios, GuderianCampaignCatalog.demoIDs.count)
        XCTAssertEqual(suite.summary.remainingScenarioIDs, [])
        XCTAssertNil(suite.summary.nextScenarioID)
        XCTAssertEqual(suite.progress.completedCount, GuderianCampaignCatalog.demoIDs.count)
        XCTAssertTrue(suite.completions.allSatisfy { suite.progress.completionRecord(for: $0.id) == $0.completionRecord })
    }

    func testCycle310NativeBoardDiagnosticsRunEveryBattleThroughRealBoardActions() throws {
        XCTAssertEqual(NativeBoardDiagnosticsRunner.cycleRange, 301...310)

        let suite = NativeBoardDiagnosticsRunner.runCampaign()
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(suite.cycleStart, 301)
        XCTAssertEqual(suite.cycleEnd, 310)
        XCTAssertEqual(suite.reports.map(\.id), orderedIDs)
        XCTAssertEqual(suite.passedCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(suite.blockingFindingCount, 0)

        for diagnostic in suite.reports {
            XCTAssertTrue(diagnostic.openedNativeSession, diagnostic.title)
            XCTAssertTrue(diagnostic.passedRealBoardDiagnostics, "\(diagnostic.title): \(diagnostic.findings.map(\.detail).joined(separator: "\n"))")
            XCTAssertTrue(diagnostic.openingSnapshot?.isScenarioBoardPlayable == true, diagnostic.title)
            XCTAssertTrue(diagnostic.finalSnapshot?.isScenarioBoardPlayable == true, diagnostic.title)
            XCTAssertGreaterThan(diagnostic.legalActionsAttempted, 0, diagnostic.title)
            XCTAssertGreaterThan(diagnostic.legalActionsSucceeded, 0, diagnostic.title)
            XCTAssertGreaterThanOrEqual(diagnostic.phaseAdvances, 2, diagnostic.title)
            XCTAssertFalse(diagnostic.steps.isEmpty, diagnostic.title)
            XCTAssertTrue(diagnostic.steps.contains { $0.phase == .movement }, diagnostic.title)
            XCTAssertTrue(diagnostic.steps.contains { $0.phase == .shooting }, diagnostic.title)
            XCTAssertTrue(diagnostic.steps.contains { $0.phase == .assault }, diagnostic.title)
            XCTAssertFalse(diagnostic.findings.contains { $0.kind == .blockedPhase })
            XCTAssertFalse(diagnostic.findings.contains { $0.kind == .impossibleReinforcement })
            XCTAssertFalse(diagnostic.findings.contains { $0.kind == .unwinnableGate })
        }
    }

    func testCycle325NativePolandPackCoversFour1939BattlesAndCompletesThem() throws {
        XCTAssertEqual(NativePolandBattlefieldPackCatalog.cycleRange, 311...325)
        XCTAssertEqual(
            NativePolandBattlefieldPackCatalog.playableBattleIDs,
            [.tucholaForest, .wizna, .brzescLitewski, .kobryn]
        )

        let packs = NativePolandBattlefieldPackCatalog.allPacks
        XCTAssertEqual(packs.map(\.id), NativePolandBattlefieldPackCatalog.playableBattleIDs)
        XCTAssertTrue(packs.allSatisfy(\.isNativePolandPackReady))

        let tuchola = try XCTUnwrap(NativePolandBattlefieldPackCatalog.pack(for: .tucholaForest))
        XCTAssertTrue(tuchola.hasRule(.withdrawal))
        XCTAssertTrue(tuchola.hasRule(.demolition))
        XCTAssertTrue(tuchola.hasRule(.cavalryScreen))
        XCTAssertTrue(tuchola.hasRule(.antiTankLane))
        XCTAssertTrue(tuchola.objectiveKinds.contains(.withdraw))
        XCTAssertTrue(tuchola.playerMobilities.contains(.cavalry))

        let wizna = try XCTUnwrap(NativePolandBattlefieldPackCatalog.pack(for: .wizna))
        XCTAssertTrue(wizna.hasRule(.bunker))
        XCTAssertTrue(wizna.terrainKinds.contains(.bunker))
        XCTAssertTrue(wizna.terrainKinds.contains(.fortifiedLine))

        let brzesc = try XCTUnwrap(NativePolandBattlefieldPackCatalog.pack(for: .brzescLitewski))
        XCTAssertTrue(brzesc.hasRule(.railSupport))
        XCTAssertTrue(brzesc.hasRule(.fortressUrban))
        XCTAssertTrue(brzesc.hasRule(.obsoleteArmor))
        XCTAssertTrue(brzesc.playerMobilities.contains(.armoredTrain))
        XCTAssertTrue(brzesc.playerMobilities.contains(.armor))

        let kobryn = try XCTUnwrap(NativePolandBattlefieldPackCatalog.pack(for: .kobryn))
        XCTAssertTrue(kobryn.hasRule(.withdrawal))
        XCTAssertTrue(kobryn.hasRule(.roadblock))
        XCTAssertTrue(kobryn.objectiveKinds.contains(.withdraw))

        let campaign = try NativePolandPackRunner.runCampaign()
        XCTAssertTrue(campaign.completedAllPolishBattles)
        XCTAssertEqual(campaign.summary.completedScenarios, NativePolandBattlefieldPackCatalog.playableBattleIDs.count)
        XCTAssertTrue(campaign.completions.allSatisfy(\.completedFromNativePolandBattlefield))
        XCTAssertTrue(campaign.completions.allSatisfy { $0.completionRecord.score > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { $0.phaseAdvances > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { !$0.steps.isEmpty })
    }

    func testCycle345NativeFrancePackCoversFrance1940BattlesAndCompletesThem() throws {
        XCTAssertEqual(NativeFranceBattlefieldPackCatalog.cycleRange, 326...345)
        XCTAssertEqual(
            NativeFranceBattlefieldPackCatalog.playableBattleIDs,
            [.sedan, .stonne, .montcornet, .amiensAbbeville, .boulogne, .calais, .dunkirk, .fallRot]
        )

        let packs = NativeFranceBattlefieldPackCatalog.allPacks
        XCTAssertEqual(packs.map(\.id), NativeFranceBattlefieldPackCatalog.playableBattleIDs)
        XCTAssertTrue(packs.allSatisfy(\.isNativeFrancePackReady))

        let sedan = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .sedan))
        XCTAssertTrue(sedan.hasRule(.riverCrossing))
        XCTAssertTrue(sedan.hasRule(.bridgehead))
        XCTAssertTrue(sedan.hasRule(.airPressure))
        XCTAssertTrue(sedan.terrainKinds.contains(.river))
        XCTAssertTrue(sedan.terrainKinds.contains(.bridge))

        let stonne = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .stonne))
        XCTAssertTrue(stonne.hasRule(.heavyTankShock))
        XCTAssertTrue(stonne.terrainKinds.contains(.town))
        XCTAssertTrue(stonne.playerMobilities.contains(.armor))

        let montcornet = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .montcornet))
        XCTAssertTrue(montcornet.hasRule(.armoredRaid))
        XCTAssertTrue(montcornet.hasRule(.airPressure))
        XCTAssertTrue(montcornet.hasRule(.withdrawal))

        let amiens = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .amiensAbbeville))
        XCTAssertTrue(amiens.hasRule(.riverCrossing))
        XCTAssertTrue(amiens.hasRule(.channelDelay))

        let boulogne = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .boulogne))
        XCTAssertTrue(boulogne.hasRule(.evacuation))
        XCTAssertTrue(boulogne.hasRule(.navalSupport))
        XCTAssertTrue(boulogne.hasRule(.portDenial))

        let calais = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .calais))
        XCTAssertTrue(calais.hasRule(.siegeSupply))
        XCTAssertTrue(calais.hasRule(.channelDelay))

        let dunkirk = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .dunkirk))
        XCTAssertTrue(dunkirk.hasRule(.evacuation))
        XCTAssertTrue(dunkirk.hasRule(.channelDelay))

        let fallRot = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .fallRot))
        XCTAssertTrue(fallRot.hasRule(.fortressFallback))
        XCTAssertTrue(fallRot.hasRule(.withdrawal))

        let campaign = try NativeFrancePackRunner.runCampaign()
        XCTAssertTrue(campaign.completedAllFranceBattles)
        XCTAssertEqual(campaign.summary.completedScenarios, NativeFranceBattlefieldPackCatalog.playableBattleIDs.count)
        XCTAssertTrue(campaign.completions.allSatisfy(\.completedFromNativeFranceBattlefield))
        XCTAssertTrue(campaign.completions.allSatisfy { $0.completionRecord.score > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { $0.phaseAdvances > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { !$0.steps.isEmpty })
    }

    func testCycle350EasternFrontNativeFoundationCoversAll1941Battles() throws {
        XCTAssertEqual(NativeEasternFrontBattlefieldFoundationCatalog.cycleRange, 346...350)
        XCTAssertEqual(
            NativeEasternFrontBattlefieldFoundationCatalog.foundationBattleIDs,
            [.bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .mtsensk, .moscowTulaKashira]
        )

        let foundations = NativeEasternFrontBattlefieldFoundationCatalog.allFoundations
        XCTAssertEqual(foundations.map(\.id), NativeEasternFrontBattlefieldFoundationCatalog.foundationBattleIDs)
        XCTAssertTrue(foundations.allSatisfy(\.isNativeEasternFrontFoundationReady))

        for foundation in foundations {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: foundation.id))
            XCTAssertTrue(NativeEasternFrontBattlefieldFoundationCatalog.isFoundationReady(scenario), foundation.title)
            XCTAssertFalse(foundation.summary.isEmpty)
        }

        let bialystok = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .bialystokMinsk))
        XCTAssertTrue(bialystok.hasRule(.pocket))
        XCTAssertTrue(bialystok.hasRule(.breakout))
        XCTAssertTrue(bialystok.hasRule(.mechanizedCounterattack))

        let smolensk = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .smolensk))
        XCTAssertTrue(smolensk.hasRule(.riverCrossing))
        XCTAssertTrue(smolensk.hasRule(.logistics))
        XCTAssertTrue(smolensk.hasRule(.breakout))

        let roslavl = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .roslavlNovozybkov))
        XCTAssertTrue(roslavl.hasRule(.southwardTurn))

        let kiev = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .kiev))
        XCTAssertTrue(kiev.hasRule(.pincer))
        XCTAssertTrue(kiev.hasRule(.commandPost))
        XCTAssertTrue(kiev.hasRule(.pocket))

        let bryansk = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .bryansk))
        XCTAssertTrue(bryansk.hasRule(.logistics))
        XCTAssertTrue(bryansk.hasRule(.tulaDefense))

        let mtsensk = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .mtsensk))
        XCTAssertTrue(mtsensk.hasRule(.armorAmbush))
        XCTAssertTrue(mtsensk.hasRule(.t34KVShock))

        let moscow = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.hasRule(.winterFriction))
        XCTAssertTrue(moscow.hasRule(.tulaDefense))
    }

    func testCycle370NativeEasternFrontPackCovers1941BattlesAndCompletesThem() throws {
        XCTAssertEqual(NativeEasternFrontBattlefieldPackCatalog.cycleRange, 346...370)
        XCTAssertEqual(
            NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs,
            [.bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .mtsensk, .moscowTulaKashira]
        )

        let packs = NativeEasternFrontBattlefieldPackCatalog.allPacks
        XCTAssertEqual(packs.map(\.id), NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs)
        XCTAssertTrue(packs.allSatisfy(\.isNativeEasternFrontPackReady))
        XCTAssertTrue(packs.allSatisfy { $0.foundationCycleStart == 346 && $0.foundationCycleEnd == 350 })

        let bialystok = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .bialystokMinsk))
        XCTAssertTrue(bialystok.hasRule(.pocket))
        XCTAssertTrue(bialystok.hasRule(.breakout))
        XCTAssertTrue(bialystok.hasRule(.mechanizedCounterattack))

        let smolensk = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .smolensk))
        XCTAssertTrue(smolensk.hasRule(.riverCrossing))
        XCTAssertTrue(smolensk.hasRule(.logistics))
        XCTAssertTrue(smolensk.hasRule(.breakout))

        let kiev = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .kiev))
        XCTAssertTrue(kiev.hasRule(.pincer))
        XCTAssertTrue(kiev.hasRule(.commandPost))
        XCTAssertTrue(kiev.hasRule(.pocket))

        let mtsensk = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .mtsensk))
        XCTAssertTrue(mtsensk.hasRule(.armorAmbush))
        XCTAssertTrue(mtsensk.hasRule(.t34KVShock))

        let moscow = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.hasRule(.winterFriction))
        XCTAssertTrue(moscow.hasRule(.tulaDefense))
        XCTAssertTrue(moscow.hasRule(.counteroffensive))

        let campaign = try NativeEasternFrontPackRunner.runCampaign()
        XCTAssertTrue(campaign.completedAllEasternFrontBattles)
        XCTAssertEqual(campaign.summary.completedScenarios, NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs.count)
        XCTAssertTrue(campaign.completions.allSatisfy(\.completedFromNativeEasternFrontBattlefield))
        XCTAssertTrue(campaign.completions.allSatisfy { $0.completionRecord.score > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { $0.phaseAdvances > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { !$0.steps.isEmpty })
    }

    func testCycle375NativeAIEventPassCoversEveryBattle() throws {
        XCTAssertEqual(NativeAIEventPassCatalog.cycleRange, 371...375)

        let reports = NativeAIEventPassCatalog.allReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(reports.allSatisfy(\.isNativeAIEventPassReady))

        for report in reports {
            XCTAssertGreaterThan(report.aiOrderCount, 0, report.title)
            XCTAssertGreaterThan(report.targetPriorityCount, 0, report.title)
            XCTAssertGreaterThan(report.fallbackBehaviorCount, 0, report.title)
            XCTAssertGreaterThan(report.eventTriggerCount, 0, report.title)
            XCTAssertGreaterThan(report.deterministicSeedHint, 0, report.title)
            XCTAssertTrue(report.hasBinding(.germanPriority), report.title)
            XCTAssertTrue(report.hasBinding(.fallbackBehavior), report.title)
            XCTAssertTrue(report.hasBinding(.victoryGate), report.title)
            XCTAssertFalse(report.summary.isEmpty)
        }

        let sedan = try XCTUnwrap(NativeAIEventPassCatalog.report(for: .sedan))
        XCTAssertTrue(sedan.hasBinding(.reinforcementTiming))
        XCTAssertTrue(sedan.hasBinding(.scenarioRule))

        let moscow = try XCTUnwrap(NativeAIEventPassCatalog.report(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.hasBinding(.reinforcementTiming))
        XCTAssertTrue(moscow.hasBinding(.scenarioRule))
        XCTAssertGreaterThan(moscow.scenarioRuleEventCount, 0)
    }

    func testCycle380NativeAIEventExecutionOperatesOnBoardState() throws {
        XCTAssertEqual(NativeAIEventExecutionCatalog.cycleRange, 376...380)

        let reports = NativeAIEventExecutionCatalog.allReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(reports.allSatisfy(\.isNativeAIEventExecutionReady))

        for report in reports {
            XCTAssertEqual(report.passCycleStart, NativeAIEventPassCatalog.cycleRange.lowerBound, report.title)
            XCTAssertEqual(report.passCycleEnd, NativeAIEventPassCatalog.cycleRange.upperBound, report.title)
            XCTAssertTrue(report.openedBoardSession, report.title)
            XCTAssertTrue(report.scenarioBoardPlayable, report.title)
            XCTAssertGreaterThan(report.aiControlResolutionCount, 0, report.title)
            XCTAssertGreaterThan(report.fallbackResolutionCount, 0, report.title)
            XCTAssertGreaterThan(report.eventResolutionCount, 0, report.title)
            XCTAssertGreaterThan(report.victoryGateResolutionCount, 0, report.title)
            XCTAssertEqual(report.boardStateResolutionCount, report.resolutions.count, report.title)
            XCTAssertFalse(report.preferredObjectiveNames.isEmpty, report.title)
            XCTAssertFalse(report.summary.isEmpty)
            XCTAssertTrue(report.resolutions.allSatisfy(\.resolvedAgainstBoardState), report.title)
            XCTAssertTrue(report.resolutions.contains { $0.boardTargetKind == .objective || $0.boardTargetKind == .mission })
        }

        let sedan = try XCTUnwrap(NativeAIEventExecutionCatalog.report(for: .sedan))
        XCTAssertGreaterThan(sedan.reinforcementResolutionCount, 0)
        XCTAssertGreaterThan(sedan.scenarioRuleResolutionCount, 0)

        let moscow = try XCTUnwrap(NativeAIEventExecutionCatalog.report(for: .moscowTulaKashira))
        XCTAssertGreaterThan(moscow.reinforcementResolutionCount, 0)
        XCTAssertGreaterThan(moscow.scenarioRuleResolutionCount, 0)
    }

    func testCycle390NativeBalanceUXAuditCoversEveryBattle() throws {
        XCTAssertEqual(NativeBalanceUXAuditCatalog.cycleRange, 381...390)

        let reports = NativeBalanceUXAuditCatalog.allReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(reports.allSatisfy(\.isNativeBalanceUXReady))

        for report in reports {
            XCTAssertTrue(report.readableUnitDensity, report.title)
            XCTAssertTrue(report.playablePacingReady, report.title)
            XCTAssertTrue(report.playerAgencyReady, report.title)
            XCTAssertTrue(report.debriefReady, report.title)
            XCTAssertTrue(report.accessibilityReady, report.title)
            XCTAssertTrue(report.saveLoadReady, report.title)
            XCTAssertTrue(report.failureReportingReady, report.title)
            XCTAssertTrue(report.blockers.isEmpty, report.title)
            XCTAssertGreaterThan(report.nativeUnitCount, 0, report.title)
            XCTAssertGreaterThan(report.nativeObjectiveCount, 0, report.title)
            XCTAssertGreaterThan(report.nativeTerrainCount, 0, report.title)
            XCTAssertGreaterThanOrEqual(report.victoryBandCount, 3, report.title)
            XCTAssertGreaterThanOrEqual(report.maxPlayerScore, report.missionTargetScore, report.title)
            XCTAssertEqual(Set(report.signals.map(\.kind)).count, 7, report.title)
            XCTAssertTrue(report.signals.allSatisfy(\.ready), report.title)
            XCTAssertFalse(report.summary.isEmpty)
        }
    }

    func testCycle400NativeCampaignShipReportIsReady() throws {
        XCTAssertEqual(NativeCampaignShipReportCatalog.cycleRange, 391...400)

        let report = NativeCampaignShipReportCatalog.report()

        XCTAssertTrue(report.isNativeCampaignShipReady, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.scenarioCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.nativePlayableCount, report.scenarioCount)
        XCTAssertEqual(report.automationNonTerminalCount, report.scenarioCount)
        XCTAssertEqual(report.completedScenarioCount, report.scenarioCount)
        XCTAssertEqual(report.aiEventExecutionReadyCount, report.scenarioCount)
        XCTAssertEqual(report.balanceUXReadyCount, report.scenarioCount)
        XCTAssertTrue(report.metadataShipReady)
        XCTAssertTrue(report.blockers.isEmpty)
        XCTAssertTrue(report.gates.allSatisfy { $0.status == .passed })
        XCTAssertTrue(report.gates.contains { $0.id == "native-playable" })
        XCTAssertTrue(report.gates.contains { $0.id == "ai-events" })
        XCTAssertTrue(report.gates.contains { $0.id == "balance-ux" })
        XCTAssertTrue(report.buildCommands.contains("swift test"))
        XCTAssertTrue(report.buildCommands.contains { $0.contains("GuderianTest") })
        XCTAssertFalse(report.summary.isEmpty)
    }

    func testCycle425PostShipAnalysisCoversEveryBattle() throws {
        XCTAssertEqual(NativePostShipAnalysisCatalog.cycleRange, 401...425)

        let reports = NativePostShipAnalysisCatalog.allReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(reports.allSatisfy(\.isPostShipAnalysisReady))

        for report in reports {
            XCTAssertEqual(report.readinessStatus, .nativePlayable, report.title)
            XCTAssertTrue(report.aiEventExecutionReady, report.title)
            XCTAssertTrue(report.balanceUXReady, report.title)
            XCTAssertGreaterThanOrEqual(report.notes.count, 5, report.title)
            XCTAssertEqual(Set(report.notes.map(\.theme)).count, 5, report.title)
            XCTAssertFalse(report.tuningBacklog.isEmpty, report.title)
            XCTAssertFalse(report.summary.isEmpty)
        }
    }

    func testCycle450NativeCampaignSoakRunsDeterministicProbes() throws {
        XCTAssertEqual(NativeCampaignSoakRunner.cycleRange, 426...450)
        XCTAssertEqual(NativeCampaignSoakRunner.seedsPerBattle, 3)

        let suite = NativeCampaignSoakRunner.runCampaign()
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(suite.reports.map(\.id), orderedIDs)
        XCTAssertEqual(suite.reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(suite.stableBattleCount, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(suite.isCampaignSoakReady)

        for report in suite.reports {
            XCTAssertTrue(report.isSoakStable, report.title)
            XCTAssertEqual(report.probes.count, NativeCampaignSoakRunner.seedsPerBattle, report.title)
            XCTAssertEqual(Set(report.probes.map(\.seed)).count, NativeCampaignSoakRunner.seedsPerBattle, report.title)
            XCTAssertEqual(Set(report.probes.map(\.replaySignature)).count, NativeCampaignSoakRunner.seedsPerBattle, report.title)
            XCTAssertTrue(report.probes.allSatisfy(\.isStable), report.title)
            XCTAssertFalse(report.summary.isEmpty)
        }
    }

    func testCycle460TucholaForestSupportsDZWStylePlayableCommands() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let session = try XCTUnwrap(NativeBoardSession(scenario: scenario, seed: 19390901))
        let opening = session.snapshot()

        XCTAssertEqual(opening.scenarioID, .tucholaForest)
        XCTAssertEqual(opening.mission.name, scenario.title)
        XCTAssertTrue(opening.isScenarioBoardPlayable)
        XCTAssertGreaterThan(opening.zones.count, 0)
        XCTAssertGreaterThan(opening.objectives.count, 0)
        XCTAssertTrue(opening.units.contains { $0.owner == .player })
        XCTAssertTrue(opening.units.contains { $0.owner == .guderianAI })
        XCTAssertEqual(opening.phase, .movement)

        let selected = try XCTUnwrap(opening.selectedUnit)
        XCTAssertEqual(selected.owner, opening.activePlayer)
        XCTAssertTrue(selected.canMoveNow)

        let destination = NativeBattleCoordinate(
            x: min(selected.x + 1.25, 70),
            y: min(selected.y + 1.0, 46)
        )
        XCTAssertTrue(session.moveUnit(selected.id, to: destination), session.snapshot().lastAction.detail)

        let movedSnapshot = session.snapshot()
        let moved = try XCTUnwrap(movedSnapshot.units.first { $0.id == selected.id })
        XCTAssertNotEqual(moved.x, selected.x)
        XCTAssertNotEqual(moved.y, selected.y)

        XCTAssertTrue(session.rotateUnit(selected.id, to: selected.facingDegrees + 45), session.snapshot().lastAction.detail)
        _ = session.toggleCover(for: selected.id, enabled: true)
        _ = session.toggleHullDown(for: selected.id, enabled: true)

        session.selectNearestEnemyToSelectedUnit()
        XCTAssertNotNil(session.snapshot().selectedTarget)
        session.advancePhase()
        XCTAssertEqual(session.snapshot().phase, .shooting)
    }

    func testCycle480TucholaForestHasFidelityAndGermanAITurnTargets() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)

        XCTAssertEqual(instance.objectives.count, scenario.objectives.count)
        XCTAssertTrue(instance.objectives.contains { $0.name == "Pruszcz bridge / Pila-Mlyn bridge" && $0.kind == .deny })
        XCTAssertTrue(instance.objectives.contains { $0.name == "Bydgoszcz withdrawal" && $0.kind == .withdraw })
        XCTAssertTrue(instance.terrain.contains { $0.name == "East Prussia pincer" && $0.side == .guderianAI })
        XCTAssertTrue(instance.terrain.contains { $0.name == "XIX Corps spearhead" && $0.side == .guderianAI })
        XCTAssertTrue(instance.units.contains { $0.id == "tuchola-cavalry" && $0.mobility == .cavalry })
        XCTAssertTrue(instance.units.contains { $0.id == "tuchola-demolition-parties" && $0.mobility == .engineer })
        XCTAssertTrue(instance.units.contains { $0.id == "tuchola-3rd-panzer" && $0.mobility == .armor })

        let session = try XCTUnwrap(NativeBoardSession(scenario: scenario, seed: 19390901))
        let opening = session.snapshot()
        XCTAssertTrue(opening.units.contains { $0.name == "Polish 9th Infantry Division bridge guards" && $0.role.contains("Brda") })
        XCTAssertTrue(opening.units.contains { $0.name == "Pomeranian Cavalry Brigade screen" && $0.mobility == "Cavalry" })
        XCTAssertTrue(opening.units.contains { $0.name == "German 3rd Panzer Division spearhead" && $0.mobility == "Armor" })
        XCTAssertTrue(opening.objectives.contains { $0.name == "Pruszcz bridge / Pila-Mlyn bridge" })
        XCTAssertTrue(opening.objectives.contains { $0.name == "Bydgoszcz withdrawal" })

        var safety = 0
        while session.snapshot().activePlayer != .guderianAI && safety < 4 {
            session.advancePhase()
            safety += 1
        }

        let germanTurn = session.snapshot()
        XCTAssertEqual(germanTurn.activePlayer, .guderianAI)
        XCTAssertEqual(germanTurn.phase, .movement)
        let selectedAIUnit = try XCTUnwrap(germanTurn.selectedUnit)
        XCTAssertEqual(selectedAIUnit.owner, .guderianAI)

        XCTAssertTrue(
            session.moveSelectedUnitTowardPriorityObjective(
                named: ["Pruszcz bridge", "Pila-Mlyn bridge", "Chojnice road hub", "Bydgoszcz withdrawal"],
                maxDistance: 6
            ),
            session.snapshot().lastAction.detail
        )
        let afterAIMove = session.snapshot()
        let movedAIUnit = try XCTUnwrap(afterAIMove.units.first { $0.id == selectedAIUnit.id })
        XCTAssertTrue(movedAIUnit.x != selectedAIUnit.x || movedAIUnit.y != selectedAIUnit.y)
        XCTAssertTrue(
            ["Pruszcz bridge", "Pila-Mlyn bridge", "Chojnice road hub", "Bydgoszcz withdrawal"].contains { afterAIMove.lastAction.detail.contains($0) },
            afterAIMove.lastAction.detail
        )
    }

    func testCycle500DZWPlayableScreenHarnessAndRolloutPlanAreReady() throws {
        XCTAssertEqual(DZWPlayableScreenHarness.cycleRange, 486...490)
        XCTAssertEqual(PlayableBattleSurfaceCatalog.cycleRange, 491...500)

        let harness = try DZWPlayableScreenHarness.runTucholaFlow(seed: 19390901)
        XCTAssertEqual(harness.id, .tucholaForest)
        XCTAssertTrue(harness.completedAllStages, harness.blockers.joined(separator: "\n"))
        XCTAssertTrue(harness.blockers.isEmpty)
        XCTAssertEqual(harness.completedStages, DZWPlayableScreenHarnessStage.allCases)
        XCTAssertTrue(harness.openingSnapshot.isScenarioBoardPlayable)
        XCTAssertEqual(harness.completion.completionRecord.scenarioID, .tucholaForest)
        XCTAssertGreaterThan(harness.completion.completionRecord.score, 0)
        XCTAssertNotNil(harness.persistedProgress.completionRecord(for: .tucholaForest))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-screen"))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-board"))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-action-feedback"))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-debrief-panel"))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-persisted-result"))

        let plans = PlayableBattleSurfaceCatalog.allPlans
        XCTAssertEqual(plans.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(plans.map(\.id), GuderianCampaignCatalog.all.sorted { $0.order < $1.order }.map(\.id))
        XCTAssertEqual(PlayableBattleSurfaceCatalog.routedBattleIDs, [.tucholaForest])
        XCTAssertEqual(PlayableBattleSurfaceCatalog.nextRolloutIDs.first, .wizna)
        XCTAssertEqual(PlayableBattleSurfaceCatalog.nextRolloutIDs.count, GuderianCampaignCatalog.all.count - 1)

        let tucholaPlan = try XCTUnwrap(PlayableBattleSurfaceCatalog.plan(for: .tucholaForest))
        XCTAssertEqual(tucholaPlan.readiness, .pilotComplete)
        XCTAssertEqual(tucholaPlan.cycleWindow, 451...500)
        XCTAssertEqual(tucholaPlan.acceptanceGates, PlayableBattleAcceptanceGate.allCases)

        let wiznaPlan = try XCTUnwrap(PlayableBattleSurfaceCatalog.plan(for: .wizna))
        XCTAssertEqual(wiznaPlan.readiness, .nextRollout)
        XCTAssertEqual(wiznaPlan.cycleWindow, 501...505)

        let finalPlan = try XCTUnwrap(PlayableBattleSurfaceCatalog.plan(for: .moscowTulaKashira))
        XCTAssertEqual(finalPlan.cycleWindow, 586...590)
        XCTAssertTrue(plans.allSatisfy { !$0.notes.isEmpty })
        XCTAssertTrue(plans.allSatisfy { $0.hostSurfaceName == PlayableBattleSurfaceCatalog.hostSurfaceName })
    }

    func testGuderianTestAutomationRunsEveryBattleAndSurfacesDiagnostics() throws {
        let report = CampaignAutomationRunner.runCampaign()
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)
        let demoIDs = Set(GuderianCampaignCatalog.demoIDs)
        let polishIDs = Set(PolishCampaignSystemCatalog.polishScenarioIDs)
        let franceIDs = Set(FranceCampaignSystemCatalog.franceScenarioIDs)
        let easternFrontIDs = Set(EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs)
        let nativePlayableIDs = Set(GuderianCampaignCatalog.demoIDs + PolishCampaignSystemCatalog.polishScenarioIDs + FranceCampaignSystemCatalog.franceScenarioIDs + EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs)

        XCTAssertEqual(report.reports.map(\.id), orderedIDs)
        XCTAssertEqual(report.reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.completionSummary.completedScenarios, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(nativePlayableIDs.count, GuderianCampaignCatalog.all.count)
        XCTAssertGreaterThan(report.reports.reduce(0) { $0 + $1.actionsAttempted }, 0)
        XCTAssertGreaterThan(report.reports.reduce(0) { $0 + $1.phaseAdvances }, 0)

        for battle in report.reports {
            XCTAssertFalse(battle.status.isTerminalProblem, "\(battle.title): \(battle.issues.map(\.detail).joined(separator: "\n"))")
            XCTAssertGreaterThan(battle.engineUnitCount, 0, "\(battle.title) should load engine units")
            XCTAssertGreaterThan(battle.engineObjectiveCount, 0, "\(battle.title) should load engine objectives")
            XCTAssertFalse(battle.steps.isEmpty, "\(battle.title) should expose an automation timeline")
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Loader" })
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Board" })
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Board Diagnostics" })
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Playability" })
            XCTAssertTrue(battle.issues.contains { $0.stage == "Native Loader" && $0.kind == .warning })
            XCTAssertFalse(battle.playerArmy.isEmpty)
            XCTAssertFalse(battle.opponentArmy.isEmpty)
            XCTAssertTrue(battle.nativeBoardDiagnosticsPassed, battle.title)
            XCTAssertNotNil(battle.boardDiagnostic, battle.title)
            XCTAssertTrue(battle.boardDiagnostic?.passedRealBoardDiagnostics == true, battle.title)
            XCTAssertTrue(battle.nativeAIEventPassReady, battle.title)
            XCTAssertFalse(battle.nativeAIEventPassSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native AI/Event Pass" && $0.status == .passed })
            XCTAssertTrue(battle.nativeAIEventExecutionReady, battle.title)
            XCTAssertFalse(battle.nativeAIEventExecutionSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native AI/Event Execution" && $0.status == .passed })
            XCTAssertTrue(battle.nativeBalanceUXReady, battle.title)
            XCTAssertFalse(battle.nativeBalanceUXSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Balance/UX" && $0.status == .passed })
            XCTAssertTrue(battle.nativePostShipAnalysisReady, battle.title)
            XCTAssertFalse(battle.nativePostShipAnalysisSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Post-Ship Analysis" && $0.status == .passed })
            XCTAssertTrue(battle.nativeSoakReady, battle.title)
            XCTAssertFalse(battle.nativeSoakSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Campaign Soak" && $0.status == .passed })

            if demoIDs.contains(battle.id) {
                XCTAssertTrue(battle.nativeDemoBoardCompleted, battle.title)
                XCTAssertNotNil(battle.completionRecord, battle.title)
                XCTAssertFalse(battle.debriefSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native Demo" && $0.status == .passed })
            }

            if polishIDs.contains(battle.id) {
                XCTAssertTrue(battle.nativePolandPackCompleted, battle.title)
                XCTAssertNotNil(battle.completionRecord, battle.title)
                XCTAssertFalse(battle.nativePolandPackSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native Poland Pack" && $0.status == .passed })
            }

            if franceIDs.contains(battle.id) {
                XCTAssertTrue(battle.nativeFrancePackCompleted, battle.title)
                XCTAssertNotNil(battle.completionRecord, battle.title)
                XCTAssertFalse(battle.nativeFrancePackSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native France Pack" && $0.status == .passed })
            }

            if easternFrontIDs.contains(battle.id) {
                XCTAssertTrue(battle.easternFrontFoundationReady, battle.title)
                XCTAssertFalse(battle.easternFrontFoundationSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native Eastern Front Foundation" && $0.status == .passed })
                XCTAssertTrue(battle.nativeEasternFrontPackCompleted, battle.title)
                XCTAssertNotNil(battle.completionRecord, battle.title)
                XCTAssertFalse(battle.nativeEasternFrontPackSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native Eastern Front Pack" && $0.status == .passed })
            }

            if nativePlayableIDs.contains(battle.id) {
                XCTAssertFalse(battle.issues.contains { $0.stage == "Native Playability" && $0.kind == .warning }, battle.title)
            } else {
                XCTAssertFalse(battle.nativeDemoBoardCompleted, battle.title)
                XCTAssertFalse(battle.nativePolandPackCompleted, battle.title)
                XCTAssertFalse(battle.nativeFrancePackCompleted, battle.title)
                XCTAssertFalse(battle.nativeEasternFrontPackCompleted, battle.title)
                XCTAssertNil(battle.completionRecord, battle.title)
                XCTAssertTrue(battle.issues.contains { $0.stage == "Native Playability" && $0.kind == .warning })
            }
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
