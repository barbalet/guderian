import GuderianCore
@testable import GuderianFun
import XCTest

final class FunScenarioAuditTests: XCTestCase {
    func testFunDimensionWeightsMatchDocumentedModel() {
        XCTAssertEqual(FunDimension.allCases.map(\.weight).reduce(0, +), 100)
        XCTAssertEqual(FunDimension.clarity.weight, 15)
        XCTAssertEqual(FunDimension.agency.weight, 15)
        XCTAssertEqual(FunDimension.challenge.weight, 15)
        XCTAssertEqual(FunDimension.mastery.weight, 15)
        XCTAssertEqual(FunDimension.novelty.weight, 10)
        XCTAssertEqual(FunDimension.consequence.weight, 10)
        XCTAssertEqual(FunDimension.pacing.weight, 10)
        XCTAssertEqual(FunDimension.ethicalFrame.weight, 10)
    }

    func testStaticFunAuditCoversAllUnifiedScenarios() throws {
        let report = try FunOptimizationReport.generate(runUnifiedHarness: false)

        XCTAssertEqual(report.scenarioCount, 35)
        XCTAssertEqual(report.kindSummaries.map(\.scenarioCount), [19, 16])
        XCTAssertGreaterThanOrEqual(report.averageOverallScore, Double(FunThresholds.guderianDefault.acceptableOverallScore))
        XCTAssertEqual(report.blockerCount, 0, report.audits.flatMap(\.blockerGates).map(\.detail).joined(separator: "\n"))
        XCTAssertEqual(report.passingScenarioCount, report.scenarioCount)
    }

    func testEthicalFrameGateIsExplicitlyProtected() throws {
        let report = try FunOptimizationReport.generate(runUnifiedHarness: false)
        let ethicalScores = report.audits.map { $0.score(for: .ethicalFrame) }

        XCTAssertEqual(ethicalScores.count, 35)
        XCTAssertGreaterThanOrEqual(ethicalScores.min() ?? 0, FunThresholds.guderianDefault.ethicalFrameBlockerScore)
        XCTAssertTrue(report.audits.allSatisfy { audit in
            audit.dimensionScores.contains { $0.dimension == .ethicalFrame }
        })
    }

    func testLiveRunSummaryCanLiftScenarioEvidenceWithoutChangingThresholds() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let staticAudit = FunScenarioAuditCatalog.audit(for: scenario)
        let liveAudit = FunScenarioAuditCatalog.audit(
            for: scenario,
            runSummary: FunScenarioRunSummary(
                id: "field:tucholaForest",
                status: .passed,
                stepCount: 9,
                blockerCount: 0,
                completionPersistenceKey: "guderian.campaign.tucholaForest.completion.v1",
                detail: "Tuchola completed all unified playable stages."
            )
        )

        XCTAssertGreaterThanOrEqual(liveAudit.score(for: .clarity), staticAudit.score(for: .clarity))
        XCTAssertGreaterThanOrEqual(liveAudit.score(for: .agency), staticAudit.score(for: .agency))
        XCTAssertTrue(liveAudit.passedFunGates)
    }

    func testFunDTReconstructsEveryBattleAsTemporalDifference() throws {
        let reconstructions = FunDTCatalog.reconstructAllBattles()

        XCTAssertEqual(reconstructions.count, 35)
        XCTAssertEqual(reconstructions.map(\.order), Array(1...35))
        XCTAssertEqual(reconstructions.first?.title, "Battle of Tuchola Forest")
        XCTAssertTrue(reconstructions.allSatisfy { 0...100 ~= $0.funDTScore })
        XCTAssertTrue(reconstructions.allSatisfy { $0.axisDeltas.count == FunDTAxis.allCases.count })
        XCTAssertTrue(reconstructions.dropFirst().allSatisfy { !$0.strongestDeltaAxisLabels.isEmpty })
    }

    func testFunDTShowsTheLateCareerTransitionAsADistinctTemporalBreak() throws {
        let reconstructions = FunDTCatalog.reconstructAllBattles()
        let firstLateCareer = try XCTUnwrap(reconstructions.first { $0.id == "late:kursk-armored-force-pressure" })

        XCTAssertEqual(firstLateCareer.previousBattleTitle, "Moscow Southern Approach")
        XCTAssertGreaterThanOrEqual(firstLateCareer.immediateDifferenceScore, 70)
        XCTAssertTrue(firstLateCareer.strongestDeltaAxisLabels.contains(FunDTAxis.commandScope.rawValue))
        XCTAssertTrue(firstLateCareer.reconstructionSummary.localizedCaseInsensitiveContains("cumulative novelty"))
    }

    func testOptimizationReportCarriesFunDTTimeline() throws {
        let report = try FunOptimizationReport.generate(runUnifiedHarness: false)

        XCTAssertEqual(report.funDTReport.reconstructions.count, report.scenarioCount)
        XCTAssertGreaterThan(report.averageFunDTScore, 40)
        XCTAssertTrue(report.markdownSummary().contains("## funDT Timeline"))
    }

    func testBattleSideReportCoversEveryBattleAndBothSides() throws {
        let report = try FunBattleSideReportCatalog.generate(runUnifiedHarness: false)

        XCTAssertEqual(report.rows.count, 70)
        XCTAssertEqual(Set(report.rows.map(\.battleID)).count, 35)
        for battleID in Set(report.rows.map(\.battleID)) {
            let sideIDs = Set(report.rows.filter { $0.battleID == battleID }.map(\.sideID))
            XCTAssertEqual(sideIDs, Set([GuderianHistoricalSideID.opposingForce, GuderianHistoricalSideID.guderianCommand]))
        }
        XCTAssertTrue(report.rows.allSatisfy { 0...100 ~= $0.funScore })
        XCTAssertTrue(report.rows.allSatisfy { 0...100 ~= $0.funDTScore })
        XCTAssertTrue(report.turnSummaries.isEmpty)
        XCTAssertTrue(report.rows.allSatisfy { $0.averageAITurns == nil && $0.aiTurnSamples.isEmpty })
        XCTAssertTrue(report.rows.allSatisfy { $0.averageAIMovedDistance == nil && $0.aiMovedDistanceSamples.isEmpty })
        XCTAssertTrue(report.rows.allSatisfy { $0.averageBlockedMovementPhases == nil && $0.blockedMovementPhaseSamples.isEmpty })
        XCTAssertTrue(report.rows.allSatisfy { !$0.strongestDTAxes.isEmpty })
        XCTAssertTrue(report.markdownAppendix().contains("## Battle Fun And funDT Appendix"))
    }
}
