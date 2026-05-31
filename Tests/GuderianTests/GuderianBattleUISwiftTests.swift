import DerZweiteWeltkriegHistorical
import Foundation
import GuderianCore
import SwiftUI
import Testing

@Suite("Guderian five-battle UI flow")
struct GuderianBattleUISwiftTests {
    @Test("Tuchola Forest UI flow completes from row selection through completion")
    func tucholaForestUIFlowCompletes() throws {
        let result = try runAndExpectComplete(.tucholaForest)
        #expect(result.plan.expectedPlayerLabel == "British")
        #expect(result.displayedText.contains { $0.contains("Brda") || $0.contains("Tuchola") })
    }

    @Test("Sedan UI flow completes from briefing through debrief")
    func sedanUIFlowCompletes() throws {
        let result = try runAndExpectComplete(.sedan)
        #expect(result.plan.expectedPlayerLabel == "British")
        #expect(result.displayedText.contains { $0.contains("bridge") || $0.contains("Bridge") })
    }

    @Test("Calais UI flow completes from siege setup through completion")
    func calaisUIFlowCompletes() throws {
        let result = try runAndExpectComplete(.calais)
        #expect(result.plan.expectedPlayerLabel == "British")
        #expect(result.displayedText.contains { $0.contains("Dunkirk") || $0.contains("port") })
    }

    @Test("Smolensk UI flow completes from pocket briefing through completion")
    func smolenskUIFlowCompletes() throws {
        let result = try runAndExpectComplete(.smolensk)
        #expect(result.plan.expectedPlayerLabel == "Soviet")
        #expect(result.displayedText.contains { $0.contains("Yartsevo") || $0.contains("pocket") })
    }

    @Test("Moscow/Tula/Kashira UI flow completes through final campaign battle completion")
    func moscowTulaKashiraUIFlowCompletes() throws {
        let result = try runAndExpectComplete(.moscowTulaKashira)
        #expect(result.plan.expectedPlayerLabel == "Soviet")
        #expect(result.displayedText.contains { $0.contains("Tula") || $0.contains("Kashira") })
    }

    @Test("All five UI battle flows complete as one campaign run")
    func fiveBattleCampaignUIFlowCompletesInTotal() throws {
        let suite = try BattleUIFlowRunner.runFiveBattleCampaignFlow()

        #expect(suite.battleIDs == BattleUIFlowRunner.fiveBattleScenarioIDs)
        #expect(suite.results.count == 5)
        #expect(suite.summary.isComplete)
        #expect(suite.summary.completedScenarios == 5)
        #expect(suite.summary.remainingScenarioIDs.isEmpty)
        #expect(suite.progress.isComplete(in: suite.battleIDs.compactMap(GuderianCampaignCatalog.scenario)))
        #expect(suite.totalScore == suite.summary.totalScore)
        #expect(Set(suite.results.map(\.id)) == Set(BattleUIFlowRunner.fiveBattleScenarioIDs))
        #expect(suite.results.allSatisfy { $0.completedAllStages })
        #expect(suite.results.allSatisfy { $0.engineUnitCount > 0 && $0.engineObjectiveCount > 0 })
    }

    @Test("Tuchola DZW-style playable screen drives commands, blocked feedback, AI, debrief, and persistence")
    func tucholaDZWStylePlayableScreenHarnessCompletes() throws {
        let result = try DZWPlayableScreenHarness.runTucholaFlow()

        #expect(result.completedAllStages)
        #expect(result.blockers.isEmpty)
        #expect(result.completedStages == DZWPlayableScreenHarnessStage.allCases)
        #expect(result.completion.completionRecord.scenarioID == .tucholaForest)
        #expect(result.persistedProgress.completionRecord(for: .tucholaForest) != nil)
        #expect(result.displayedAccessibilityIdentifiers.contains("battle-screen"))
        #expect(result.displayedAccessibilityIdentifiers.contains("battle-action-feedback"))
        #expect(result.displayedAccessibilityIdentifiers.contains("battle-debrief-panel"))
        #expect(result.displayedAccessibilityIdentifiers.contains("battle-persisted-result"))
    }

    @Test("Cycles 501-590 DZW-style playable screens complete the full campaign")
    func dzwStylePlayableScreensCompleteFullCampaign() throws {
        let results = try DZWPlayableScreenHarness.runCompletedParityFlowsThroughCycle590()

        #expect(results.map(\.id) == PlayableBattleSurfaceCatalog.completedBattleIDsThroughCycle590)
        #expect(results.count == GuderianCampaignCatalog.all.count)
        #expect(results.allSatisfy { $0.completedAllStages })
        #expect(results.allSatisfy { $0.blockers.isEmpty })
        #expect(results.allSatisfy { $0.completedStages == DZWPlayableScreenHarnessStage.allCases })
        #expect(results.allSatisfy { $0.displayedAccessibilityIdentifiers.contains("battle-screen") })
        #expect(results.allSatisfy { $0.displayedAccessibilityIdentifiers.contains("battle-board") })
        #expect(results.allSatisfy { $0.displayedAccessibilityIdentifiers.contains("german-turn-button") })
        #expect(results.allSatisfy { $0.displayedAccessibilityIdentifiers.contains("battle-debrief-panel") })
        #expect(results.allSatisfy { $0.persistedProgress.completionRecord(for: $0.id) != nil })
    }

    @Test("GuderianTest playable test game uses AI for both sides and completes every scenario")
    func guderianTestPlayableGameCompletesFullCampaignWithBothAIs() throws {
        let suite = try PlayableTestGameRunner.runCampaign()

        #expect(suite.battleIDs == GuderianCampaignCatalog.all.map(\.id))
        #expect(suite.results.count == GuderianCampaignCatalog.all.count)
        #expect(suite.completedAllBattlesToEnd)
        #expect(suite.summary.completedScenarios == GuderianCampaignCatalog.all.count)
        #expect(suite.results.allSatisfy { $0.automatedSides.isSuperset(of: [.player, .guderianAI]) })
        #expect(suite.results.allSatisfy { $0.antiGuderianStepCount > 0 && $0.germanStepCount > 0 })
        #expect(suite.results.allSatisfy { !$0.opposingForcePlan.targetPriorities(for: .movement).isEmpty })
        #expect(suite.results.allSatisfy { $0.completion.completionRecord.scenarioID == $0.id })
    }

    @Test("Cycles 1081-1100 opposing-force AI has phase-aware army identities")
    func opposingForceAIPlansHavePhaseAwareArmyIdentities() throws {
        let tuchola = try #require(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let sedan = try #require(GuderianCampaignCatalog.scenario(id: .sedan))
        let calais = try #require(GuderianCampaignCatalog.scenario(id: .calais))
        let moscow = try #require(GuderianCampaignCatalog.scenario(id: .moscowTulaKashira))
        let tucholaPlan = OpposingForceAIPlanCatalog.plan(for: tuchola)
        let sedanPlan = OpposingForceAIPlanCatalog.plan(for: sedan)
        let calaisPlan = OpposingForceAIPlanCatalog.plan(for: calais)
        let moscowPlan = OpposingForceAIPlanCatalog.plan(for: moscow)
        let plans = [tucholaPlan, sedanPlan, calaisPlan, moscowPlan]

        #expect(tucholaPlan.armyFamily == .polish)
        #expect(sedanPlan.armyFamily == .french)
        #expect(calaisPlan.armyFamily == .alliedPortDefense)
        #expect(moscowPlan.armyFamily == .sovietWinter)
        #expect(Set(plans.map(\.armyFamily)).count == plans.count)
        #expect(plans.allSatisfy { $0.isExecutableByNativeAutoplay })
        #expect(plans.allSatisfy { !$0.targetPriorities(for: .movement).isEmpty })
        #expect(plans.allSatisfy { !$0.targetPriorities(for: .shooting).isEmpty })
        #expect(plans.allSatisfy { !$0.targetPriorities(for: .assault).isEmpty })
        #expect(tucholaPlan.targetPriorities(for: .movement).first == "Bydgoszcz withdrawal")
        #expect(tucholaPlan.targetPriorities(for: .shooting).first == "Chojnice-Tuchola road net")
        #expect(sedanPlan.targetPriorities(for: .movement).contains("Meuse crossings"))
        #expect(calaisPlan.targetPriorities(for: .movement).contains("Protect Dunkirk time"))
        #expect(moscowPlan.targetPriorities(for: .movement).contains("Guard Tula axis"))
        #expect(tucholaPlan.targetPriorities(for: .movement) != sedanPlan.targetPriorities(for: .movement))
        #expect(tucholaPlan.orders.map(\.kind) == [.movement, .shooting, .assault])
    }

    @Test("Cycles 1101-1120 opposing-force AI acceptance covers Soviet, late-war, and Guderian-side regression")
    func opposingForceAIAcceptanceCoversSovietLateWarAndGuderianSideRegression() throws {
        let report = OpposingForceAIAcceptanceCatalog.report

        #expect(report.blockers.isEmpty)
        #expect(report.isReady)
        #expect(report.cycleStart == 1101)
        #expect(report.cycleEnd == 1120)
        #expect(report.fieldCommandBattleCount == 19)
        #expect(report.lateCareerBattleCount == 16)
        #expect(report.requiredArmyFamiliesCovered)
        #expect(report.allFieldCommandGuderianSideRunsReachDebrief)
        #expect(report.visibleReasoningReady)
        #expect(report.uniqueFieldCommandBehaviorSignatureCount == 19)
        #expect(report.uniqueLateCareerBehaviorSignatureCount >= 8)

        let soviet1941 = report.fieldCommandAudits.filter { $0.armyFamily == .soviet1941 }
        #expect(soviet1941.count == 6)
        #expect(soviet1941.allSatisfy { $0.hasPhaseAwarePriorities })
        #expect(soviet1941.allSatisfy { $0.hasVisibleReasoning })

        let bialystok = try #require(report.fieldCommandAudits.first { $0.id == .bialystokMinsk })
        let smolensk = try #require(report.fieldCommandAudits.first { $0.id == .smolensk })
        let roslavl = try #require(report.fieldCommandAudits.first { $0.id == .roslavlNovozybkov })
        let kiev = try #require(report.fieldCommandAudits.first { $0.id == .kiev })
        let bryansk = try #require(report.fieldCommandAudits.first { $0.id == .bryansk })
        let mtsensk = try #require(report.fieldCommandAudits.first { $0.id == .mtsensk })

        #expect(bialystok.movementPriorityNames.first == "Open breakout lanes")
        #expect(smolensk.movementPriorityNames.first == "Yartsevo escape lane")
        #expect(roslavl.behaviorProfile == .counterattack)
        #expect(roslavl.shootingPriorityNames.first == "Soviet tank raid point")
        #expect(kiev.movementPriorityNames.contains("Evacuate command assets"))
        #expect(bryansk.shootingPriorityNames.first == "Autumn road friction")
        #expect(mtsensk.shootingPriorityNames.first == "Katukov tank ambush")

        #expect(report.lateCareerAudits.allSatisfy { $0.armyFamily == .lateWarSovietAllied })
        #expect(Set(report.lateCareerAudits.map(\.behaviorProfile)).count >= 3)
        #expect(report.lateCareerAudits.allSatisfy { $0.isReady })
    }

    @Test("Cycles 931-940 GuderianTest launches the first-battle autoplay contract")
    func guderianTestFirstBattleAutoplayContractReplacesDashboard() throws {
        let scenario = try GuderianTestFirstBattleAutoplayContract.primaryScenario()

        #expect(scenario.id == .tucholaForest)
        #expect(GuderianTestFirstBattleAutoplayContract.primarySurfaceName == "GuderianTestFirstBattleAutoplayView")
        #expect(GuderianTestFirstBattleAutoplayContract.embeddedBattleSurfaceName == "DZWPlayableBattleView")
        #expect(GuderianTestFirstBattleAutoplayContract.retiredPrimarySurfaceNames.contains("GuderianTestDashboard"))
        #expect(GuderianTestFirstBattleAutoplayContract.retiredPrimarySurfaceNames.contains("GuderianCampaignView"))
        #expect(GuderianTestFirstBattleAutoplayContract.requiredAccessibilityIdentifiers.contains("guderian-test-first-battle-autoplay"))
        #expect(GuderianTestFirstBattleAutoplayContract.requiredAccessibilityIdentifiers.contains("guderian-test-primary-battle-surface"))
        #expect(GuderianTestFirstBattleAutoplayContract.requiredAccessibilityIdentifiers.contains("guderian-test-step-button"))
        #expect(GuderianTestFirstBattleAutoplayContract.requiredAccessibilityIdentifiers.contains("guderian-test-pause-button"))
        #expect(GuderianTestFirstBattleAutoplayContract.requiredAccessibilityIdentifiers.contains("guderian-test-speed-picker"))
        #expect(GuderianTestFirstBattleAutoplayContract.requiredAccessibilityIdentifiers.contains("guderian-test-safety-cap"))
        #expect(GuderianTestFirstBattleAutoplayContract.requiredAccessibilityIdentifiers.contains("guderian-test-event-log"))
        #expect(GuderianTestFirstBattleAutoplayContract.requiredAccessibilityIdentifiers.contains("guderian-test-result-summary"))
    }

    @Test("Cycles 41-60 Guderian exposes first-battle autoplay through shared historical contracts")
    func guderianTestSharedHistoricalAutoplayAdapterIsReady() throws {
        let historicalScenario = try GuderianTestFirstBattleAutoplayContract.sharedHistoricalScenario()
        let contract = GuderianTestFirstBattleAutoplayContract.sharedHistoricalAutoplayContract
        let report = GuderianHistoricalAutoplayCatalog.rewriteReport
        let nativeScenario = try #require(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let configuration = GuderianHistoricalAutoplayCatalog.configuration(for: nativeScenario)

        #expect(report.isReady)
        #expect(historicalScenario.id == .tucholaForest)
        #expect(historicalScenario.hasTwoPlayableSides)
        #expect(historicalScenario.sideOptions.map(\.id) == [
            GuderianHistoricalSideID.guderianCommand,
            GuderianHistoricalSideID.opposingForce,
        ])
        #expect(contract.embeddedBattleSurfaceName == HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName)
        #expect(contract.retiredEmbeddedSurfaceNames.contains("DZWPlayableBattleView"))
        #expect(contract.isFirstBattleAutoplayContract)
        #expect(configuration.seed == GuderianHistoricalAutoplayCatalog.defaultSeed)
        #expect(configuration.sidePlans.count == 2)
        #expect(GuderianTestFirstBattleAutoplayContract.embeddedBattleSurfaceName == "DZWPlayableBattleView")
    }

    @Test("Guderian side selection can bind the human player to either historical side")
    func guderianPlayableSideSelectionCanChooseGuderianCommand() throws {
        let scenario = try #require(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let opposingLaunch = try GuderianHistoricalSideSelectionResolver.makeLaunch(
            for: scenario,
            chosenHumanSideID: GuderianHistoricalSideID.opposingForce,
            seed: 620_001
        )
        let guderianLaunch = try GuderianHistoricalSideSelectionResolver.makeLaunch(
            for: scenario,
            chosenHumanSideID: GuderianHistoricalSideID.guderianCommand,
            seed: 620_002
        )
        let session = try #require(NativeBoardSession(scenario: scenario, launch: guderianLaunch))

        #expect(opposingLaunch.humanBinding?.enginePlayerSlot == .playerOne)
        #expect(guderianLaunch.humanBinding?.enginePlayerSlot == .playerTwo)
        #expect(guderianLaunch.aiBinding?.enginePlayerSlot == .playerOne)
        #expect(session.humanPlayer == .guderianAI)
        #expect(session.aiPlayer == .player)
        #expect(GuderianHistoricalSideSelectionResolver.sideTitle(for: session.humanPlayer, in: scenario) == "Guderian's command")
    }

    @Test("Guderian battle selection can render the shared side control for either playable side")
    @MainActor
    func guderianBattleSelectionUsesSharedSidePickerControl() throws {
        let scenario = try #require(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let historicalScenario = GuderianHistoricalScenarioAdapter.scenario(for: scenario)
        let picker = HistoricalBattleSidePicker(
            scenario: historicalScenario,
            selectedSideID: .constant(GuderianHistoricalSideID.guderianCommand),
            accessibilityIdentifier: HistoricalBattleSidePickerDefaults.accessibilityIdentifier,
            optionAccessibilityIDPrefix: "guderian-side-option"
        )

        #expect(historicalScenario.sideOptions.map(\.id) == [
            GuderianHistoricalSideID.guderianCommand,
            GuderianHistoricalSideID.opposingForce,
        ])
        #expect(historicalScenario.sideOption(id: GuderianHistoricalSideID.guderianCommand)?.title == "Guderian's command")
        #expect(historicalScenario.sideOption(id: GuderianHistoricalSideID.opposingForce)?.title == "Polish corridor defenders")
        #expect(String(describing: type(of: picker)).contains("HistoricalBattleSidePicker"))
    }

    @Test("Late-career campaign rows expose the same two playable army choices")
    func guderianLateCareerRowsExposeEitherArmySelection() throws {
        let entry = try #require(LateCareerGuderianPresentationCatalog.allEntries.first)
        let sideOptions = UnifiedGuderianBattleSideSelectionCatalog.sideOptions(for: entry)
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/GuderianCampaignView.swift",
            encoding: .utf8
        )
        let battleView = try String(
            contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift",
            encoding: .utf8
        )

        #expect(sideOptions.map(\.id) == [
            GuderianHistoricalSideID.guderianCommand,
            GuderianHistoricalSideID.opposingForce,
        ])
        #expect(sideOptions.first?.title == "Guderian's command")
        #expect(sideOptions.last?.title != "Opposing army")
        #expect(sideOptions.last?.title == UnifiedGuderianBattleSideSelectionCatalog.opposingForceName(for: entry))
        #expect(source.contains("selectedLateCareerSideIDsByBattle"))
        #expect(source.contains("lateCareerSideSelectionBinding(for: entry)"))
        #expect(source.contains("DZWPlayableBattleView("))
        #expect(source.contains("chosenSideID: effectiveSelectedSideID"))
        #expect(battleView.contains("case lateCareer(LateCareerGuderianPresentation, chosenSideID: String)"))
        #expect(battleView.contains("UnifiedGuderianBattleSideSelectionCatalog.nativePlayer(for: chosenSideID)"))
    }

    @Test("Guderian battle selection keeps the side control outside the launch button")
    func guderianBattleSelectionSideControlIsSeparateFromNavigationLink() throws {
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/GuderianCampaignView.swift",
            encoding: .utf8
        )
        let rowFunction = try #require(source.range(of: "private func unifiedBattleSelectionRow"))
        let nextFunction = try #require(source.range(of: "private func fieldCommandScenario"))
        let rowSource = String(source[rowFunction.lowerBound..<nextFunction.lowerBound])
        let launchButton = try #require(rowSource.range(of: "Button {"))
        let sidePicker = try #require(rowSource.range(of: "HistoricalBattleSidePicker"))

        #expect(launchButton.upperBound < sidePicker.lowerBound)
        #expect(rowSource.contains("launchBattle(row)"))
        #expect(rowSource.contains("UnifiedCampaignBattleRow(row: row)"))
        #expect(!rowSource.contains("simultaneousGesture"))
        #expect(rowSource.contains("battle-selection-side-picker-\\(row.id.rawValue)"))
    }

    @Test("Guderian side selection keeps completed battle rows launchable")
    func guderianBattleSelectionUpdatesActiveBattleState() throws {
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/GuderianCampaignView.swift",
            encoding: .utf8
        )
        let bindingFunction = try #require(source.range(of: "private func sideSelectionBinding"))
        let nextFunction = try #require(source.range(of: "private var scenarioListSection"))
        let bindingSource = String(source[bindingFunction.lowerBound..<nextFunction.lowerBound])

        #expect(!bindingSource.contains("selectedSideID = newSideID"))
        #expect(bindingSource.contains("selectedSideID(for: scenario)"))
        #expect(source.contains("historicalScenario.sideOptions.first?.id ?? GuderianHistoricalSideSelectionResolver.defaultHumanSideID"))
        #expect(bindingSource.contains("selectedBattleID = .fieldCommand(scenario.id)"))
        #expect(bindingSource.contains("selectedID = scenario.id"))
        #expect(bindingSource.contains("selectedSideIDsByBattle[scenario.id] = newSideID"))
        #expect(!bindingSource.contains("GuderianHistoricalSideSelectionMemory.encodedSelections"))
    }

    @Test("Guderian list-side controls do not share one global selected-side fallback")
    func guderianBattleSelectionSideControlIsPerBattleOnly() throws {
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/GuderianCampaignView.swift",
            encoding: .utf8
        )

        #expect(!source.contains("guderian.campaign.selected-side.v1"))
        #expect(!source.contains("selectedSideID = newSideID"))
        #expect(!source.contains("fallbackSideID: selectedSideID"))
        #expect(!source.contains("selectedPlayableSideByBattle"))
        #expect(!source.contains("@AppStorage(GuderianCampaignStorageKeys.selectedPlayableSide"))
        #expect(source.contains("@State private var selectedSideIDsByBattle: [GuderianBattleID: String] = [:]"))
    }

    @Test("Guderian campaign treats every battle as playable")
    func guderianCampaignTreatsEveryBattleAsPlayable() throws {
        let appSource = try String(
            contentsOfFile: "Sources/GuderianApp/GuderianCampaignView.swift",
            encoding: .utf8
        )
        let coreSource = try String(
            contentsOfFile: "Sources/GuderianCore/UnifiedGuderianBattleCatalog.swift",
            encoding: .utf8
        )

        #expect(appSource.contains("Text(\"\\(unifiedRows.count) open battles | choose either side\")"))
        #expect(!appSource.contains(".disabled(!row.isAvailable)"))
        #expect(!appSource.contains("guard row.isAvailable else"))
        #expect(!appSource.contains("Picker(\"Play mode\""))
        #expect(coreSource.contains("availability = .available"))
        #expect(!coreSource.contains("progress.isAvailable(scenario, in: playMode) ? .available : .locked"))
    }

    @Test("Guderian row launch includes selected side so same-battle side swaps reopen")
    func guderianBattleLaunchIncludesSelectedSide() throws {
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/GuderianCampaignView.swift",
            encoding: .utf8
        )

        #expect(source.contains("private struct UnifiedCampaignBattleLaunch"))
        #expect(source.contains("NavigationStack(path: $navigationPath)"))
        #expect(source.contains("@State private var navigationPath = NavigationPath()"))
        #expect(source.contains("@State private var launchSequence = 0"))
        #expect(source.contains("launchBattle(row)"))
        #expect(source.contains("private func battleLaunch(for row: UnifiedCampaignListRow) -> UnifiedCampaignBattleLaunch"))
        #expect(source.contains("selectedSideID: selectedSideID(for: row)"))
        #expect(source.contains("launchSequence: launchSequence"))
        #expect(source.contains("navigationPath.append(battleLaunch(for: row))"))
        #expect(source.contains("launchSideID: selectedSideID"))
        #expect(source.contains(".id(\"\\(scenario.id.rawValue)-\\(activePlayableSideID)\")"))
    }

    @Test("Guderian main screen exposes executable row navigation from row to playable battle")
    func guderianMainScreenSelectionHasExecutableNavigationContract() throws {
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/GuderianCampaignView.swift",
            encoding: .utf8
        )

        #expect(source.contains(".accessibilityIdentifier(\"campaign-screen\")"))
        #expect(source.contains(".navigationDestination(for: UnifiedCampaignBattleLaunch.self)"))
        #expect(source.contains("Button {"))
        #expect(source.contains("launchBattle(row)"))
        #expect(source.contains(".accessibilityIdentifier(row.navigationAccessibilityIdentifier)"))
        #expect(source.contains(".accessibilityIdentifier(\"battle-back-to-campaign-button\")"))
        #expect(source.contains("DZWPlayableBattleView("))
        #expect(source.contains("--guderian-ui-test-disable-tutorials"))
    }

    @Test("Guderian side changes defer the heavy battle reload behind the fast picker update")
    func guderianSideSelectionDefersPlayableBattleReload() throws {
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/GuderianCampaignView.swift",
            encoding: .utf8
        )

        #expect(source.contains("@State private var displayedSideID"))
        #expect(source.contains("@State private var activeBattleSideID"))
        #expect(source.contains("displayedSideID = newSideID"))
        #expect(source.contains("schedulePlayableSideReload(newSideID)"))
        #expect(source.contains("await Task.yield()"))
        #expect(source.contains("chosenSideID: activePlayableSideID"))
        #expect(source.contains(".allowsHitTesting(!isPreparingSideSwitch)"))
        #expect(source.contains("battle-side-switch-preparing"))
    }

    @Test("Either-side gameplay copy does not claim the player always opposes Guderian")
    func guderianEitherSideCopyReplacesOldOppositionOnlyParadigm() throws {
        let readme = try String(contentsOfFile: "README.md", encoding: .utf8)
        let tutorial = try String(
            contentsOfFile: "Sources/GuderianCore/TutorialOnboarding.swift",
            encoding: .utf8
        )
        let campaignData = try String(
            contentsOfFile: "dzw/Sources/DerZweiteWeltkriegGuderian/GuderianCampaign.swift",
            encoding: .utf8
        )
        let campaignView = try String(
            contentsOfFile: "Sources/GuderianApp/GuderianCampaignView.swift",
            encoding: .utf8
        )
        let combined = "\(readme)\n\(tutorial)\n\(campaignData)\n\(campaignView)"

        #expect(combined.contains("playable-side selector"))
        #expect(combined.contains("side selector"))
        #expect(combined.contains("Guderian's command"))
        #expect(combined.contains("selected side"))
        #expect(!combined.localizedCaseInsensitiveContains("player is always"))
        #expect(!combined.localizedCaseInsensitiveContains("The player commands the opposing forces resisting Guderian's formations, not the formations themselves"))
        #expect(!combined.contains("force(\"Player\""))
        #expect(!combined.contains("force(\"Guderian AI\""))
        #expect(!campaignView.contains(".side.rawValue"))
    }

    @Test("Selected-side battle controls are gated to the human side")
    func guderianPlayableBattleCommandsAreSelectedSideAware() throws {
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift",
            encoding: .utf8
        )

        #expect(source.contains("var canIssueHumanOrders"))
        #expect(source.contains("snapshot.orderDice.current?.owner == humanPlayer"))
        #expect(source.contains("unit.owner == humanPlayer"))
        #expect(source.contains("selectedUnit.owner == humanPlayer"))
        #expect(source.contains("selected-side study mode"))
        #expect(!source.contains("You command the force resisting Guderian's formation"))
    }

    @Test("Playable battle exposes the order-dice bag as the turn driver")
    func guderianPlayableBattleExposesOrderDiceBagGameplay() throws {
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift",
            encoding: .utf8
        )

        #expect(source.contains("order-dice-bag-panel"))
        #expect(source.contains("order-dice-bag-draw-button"))
        #expect(source.contains("order-dice-current-die"))
        #expect(source.contains("order-dice-selected-side-dice"))
        #expect(source.contains("order-dice-reach-activation-units"))
        #expect(source.contains("order-dice-reach-move-units"))
        #expect(source.contains("order-dice-reach-reaction-units"))
        #expect(source.contains("activationUnits(for:"))
        #expect(source.contains("reactionUnits(against:"))
        #expect(source.contains("func drawOrderDie()"))
        #expect(source.contains("prepareNextOrderDiceActivation()"))
        #expect(source.contains("GuderianOrderDiceSessionBootstrap.enableOrderDice"))
        #expect(source.contains("canResolveHumanActivation"))
        #expect(source.contains("Label(\"Draw Die\""))
        #expect(!source.contains("Label(\"Next Window\""))
    }

    @Test("First battle tutorial explains gameplay elements through hover coach dialogs")
    func guderianFirstBattleTutorialCoversGameplayElementHoverAnchors() throws {
        let battleView = try String(
            contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift",
            encoding: .utf8
        )
        let tutorial = try String(
            contentsOfFile: "Sources/GuderianCore/TutorialOnboarding.swift",
            encoding: .utf8
        )

        #expect(tutorial.contains("firstBattleButtonCoach-boardUnitMovement"))
        #expect(tutorial.contains("firstBattleButtonCoach-boardEnemyTargeting"))
        #expect(tutorial.contains("firstBattleButtonCoach-boardObjective"))
        #expect(tutorial.contains("firstBattleButtonCoach-boardTerrain"))
        #expect(tutorial.contains("firstBattleButtonCoach-actionFeedback"))
        #expect(battleView.contains(".onHover"))
        #expect(battleView.contains(".phaseStatus"))
        #expect(battleView.contains(".boardUnitMovement"))
        #expect(battleView.contains(".boardEnemyTargeting"))
        #expect(battleView.contains(".boardObjective"))
        #expect(battleView.contains(".boardTerrain"))
        #expect(battleView.contains(".actionFeedback"))
        #expect(battleView.contains("unit.owner == model.humanPlayer ? .boardUnitMovement : .boardEnemyTargeting"))
        #expect(battleView.contains("first-battle-movement-ghost"))
        #expect(battleView.contains("first-battle-targeting-ghost"))
        #expect(tutorial.contains("low-alpha ghost"))
        #expect(tutorial.contains("low-alpha reticle"))
    }

    @Test("Guderian-side replay opens on a controllable human turn after the AI handoff")
    func guderianPlayableBattlePreparesSelectedHumanOpeningTurn() throws {
        let source = try String(
            contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift",
            encoding: .utf8
        )

        #expect(source.contains("func prepareOpeningHumanTurnIfNeeded() async"))
        #expect(source.contains("snapshot.activePlayer != humanPlayer"))
        #expect(source.contains("runAITurnToHumanControl(context: \"opening-handoff\")"))
        #expect(source.contains(".task(id: model.openingTurnPreparationGeneration)"))
        #expect(source.contains("openingTurnPreparationGeneration += 1"))
        #expect(source.contains("battle-opening-turn-preparing"))
    }

    @Test("Cycles 931-940 GuderianTest first-battle controller reaches a real debrief")
    func guderianTestFirstBattleAutoplayControllerCompletesTuchola() throws {
        let controller = try GuderianTestFirstBattleRunController()
        let report = try controller.runToDebrief()

        #expect(report.scenarioID == .tucholaForest)
        #expect(report.surfaceName == GuderianTestFirstBattleAutoplayContract.primarySurfaceName)
        #expect(report.embeddedBattleSurfaceName == "DZWPlayableBattleView")
        #expect(report.completedToDebrief)
        #expect(report.bothSidesActed)
        #expect(report.result.antiGuderianStepCount > 0)
        #expect(report.result.germanStepCount > 0)
        #expect(report.persistedProgress.completionRecord(for: .tucholaForest) != nil)
        #expect(report.result.completion.completionRecord.scenarioID == .tucholaForest)
    }

    @Test("Cycles 941-950 GuderianTest first-battle controller exposes live stepped autoplay")
    func guderianTestFirstBattleAutoplayControllerStepsLiveSession() throws {
        let controller = try GuderianTestFirstBattleRunController()
        let opening = controller.latestSnapshot

        #expect(controller.runState == .ready)
        #expect(controller.steps.isEmpty)
        #expect(controller.phaseAdvances == 0)
        #expect(controller.canStep)

        let firstStep = try controller.stepOnce()

        #expect(firstStep?.activePlayer == opening.activePlayer)
        #expect(firstStep?.controller == .antiGuderian)
        #expect(controller.runState == .paused)
        #expect(controller.phaseAdvances == 1)
        #expect(controller.steps.count >= 1)
        #expect(controller.latestSnapshot.phase != opening.phase || controller.latestSnapshot.turnNumber != opening.turnNumber)
    }

    @Test("Cycles 941-950 GuderianTest live movement changes displayed unit positions")
    func guderianTestFirstBattleAutoplayControllerMovesUnitsInLiveSession() throws {
        let controller = try GuderianTestFirstBattleRunController()
        var beforeMovement = controller.latestSnapshot
        var movementStep: PlayableTestGameStep?

        for _ in 0..<6 {
            beforeMovement = controller.latestSnapshot
            let step = try controller.stepOnce()
            if step?.phase == .movement {
                movementStep = step
                break
            }
        }

        let afterMovement = controller.latestSnapshot
        let movedUnits = afterMovement.units.filter { unit in
            guard let before = beforeMovement.units.first(where: { $0.id == unit.id }) else {
                return false
            }
            return abs(before.x - unit.x) > 0.01 || abs(before.y - unit.y) > 0.01
        }

        #expect(movementStep?.status == .succeeded)
        #expect(movementStep?.detail.contains("active units moved") == true)
        #expect(!movedUnits.isEmpty)
        #expect(afterMovement.lastAction.detail != beforeMovement.lastAction.detail)
    }

    @Test("Cycles 941-950 GuderianTest automated human player hands turns to German AI")
    func guderianTestFirstBattleAutoplayControllerRunsBothSidesByLegalSteps() throws {
        let controller = try GuderianTestFirstBattleRunController()

        for _ in 0..<8 where controller.germanStepCount == 0 {
            _ = try controller.stepOnce()
        }

        #expect(controller.antiGuderianStepCount > 0)
        #expect(controller.germanStepCount > 0)
        #expect(controller.steps.contains { $0.activePlayer == .player && $0.controller == .antiGuderian })
        #expect(controller.steps.contains { $0.activePlayer == .guderianAI && $0.controller == .guderian })
        #expect(controller.steps.allSatisfy { $0.status == .succeeded || $0.status == .blocked })
        #expect(controller.phaseAdvances > 0)
    }

    @Test("Cycles 941-950 GuderianTest run state supports pause resume and completes from stepped model")
    func guderianTestFirstBattleAutoplayControllerPauseResumeCompletes() throws {
        let controller = try GuderianTestFirstBattleRunController()

        controller.resume()
        #expect(controller.runState == .running)
        controller.pause()
        #expect(controller.runState == .paused)

        _ = try controller.runUntilPauseOrDebrief(maxSteps: 2)
        #expect(controller.runState == .running || controller.runState == .completed)
        #expect(controller.phaseAdvances >= 2 || controller.runState == .completed)
        controller.pause()
        #expect(controller.runState == .paused || controller.runState == .completed)

        let report = try controller.runToDebrief()
        #expect(controller.runState == .completed)
        #expect(report.completedToDebrief)
        #expect(report.result.steps == controller.steps)
        #expect(report.result.phaseAdvances == controller.phaseAdvances)
        #expect(report.result.steps.contains { $0.id.contains("guderian-test-step") })
        #expect(report.result.blockers.isEmpty)
    }

    @Test("Cycles 951-960 GuderianTest exposes speed safety and final acceptance")
    func guderianTestFirstBattleAutoplayAcceptanceClosesReplacement() throws {
        let acceptance = GuderianTestFirstBattleAutoplayAcceptanceCatalog.report
        let controller = try GuderianTestFirstBattleRunController()
        let report = try controller.runToDebrief()

        #expect(acceptance.isReady)
        #expect(GuderianTestFirstBattleAutoplayAcceptanceCatalog.acceptanceReadyThroughCycle960)
        #expect(acceptance.speedModes == [.inspect, .standard, .fast])
        #expect(acceptance.maxPhaseAdvances == controller.maxPhaseAdvances)
        #expect(controller.phaseProgressFraction <= 1)
        #expect(controller.phaseBudgetRemaining >= 0)
        #expect(report.finalResultSummary.contains(report.outcomeLabel))
        #expect(report.finalResultSummary.contains(report.scoreLabel))
        #expect(report.result.phaseAdvances <= controller.maxPhaseAdvances)
        #expect(report.completedToDebrief)
        #expect(report.bothSidesActed)
    }

    private func runAndExpectComplete(_ id: GuderianBattleID) throws -> BattleUIFlowResult {
        let result = try BattleUIFlowRunner.runFullBattleFlow(for: id)
        let requiredStages = BattleUIFlowStage.allCases
        let requiredIdentifiers = [
            "ui-flow-\(id.rawValue)-row",
            "ui-flow-\(id.rawValue)-briefing",
            "ui-flow-\(id.rawValue)-map",
            "ui-flow-\(id.rawValue)-setup",
            "ui-flow-\(id.rawValue)-objectives",
            "ui-flow-\(id.rawValue)-engine",
            "ui-flow-\(id.rawValue)-start",
            "ui-flow-\(id.rawValue)-debrief",
            "ui-flow-\(id.rawValue)-completion",
        ]

        #expect(result.id == id)
        #expect(result.completedAllStages)
        #expect(result.plan.visitedStages == requiredStages)
        #expect(result.completionRecord.scenarioID == id)
        #expect(result.completionRecord.score > 0)
        #expect(result.completionRecord.completedTurn > 0)
        #expect(result.engineUnitCount > 0)
        #expect(result.engineObjectiveCount > 0)
        #expect(result.plan.expectedOpponentLabel == "German")
        #expect(result.displayedAccessibilityIdentifiers.count == result.plan.steps.count)
        #expect(requiredIdentifiers.allSatisfy(result.displayedAccessibilityIdentifiers.contains))
        #expect(result.displayedAccessibilityIdentifiers.contains { $0.hasPrefix("ui-flow-\(id.rawValue)-turn-") })
        #expect(!result.displayedText.contains { $0.isEmpty })

        return result
    }
}
