import GuderianCore
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
        #expect(suite.results.allSatisfy { !$0.antiGuderianPlan.targetPriorities.isEmpty })
        #expect(suite.results.allSatisfy { $0.completion.completionRecord.scenarioID == $0.id })
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
