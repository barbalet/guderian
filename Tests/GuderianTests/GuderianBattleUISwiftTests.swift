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
