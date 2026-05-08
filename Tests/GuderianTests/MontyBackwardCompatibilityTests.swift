import GuderianCore
import SwiftUI
import XCTest

private enum MontyBackwardCompatibilityReexportBattleID: String, Codable, Hashable, Sendable, HistoricalBattleID {
    case smoke
}

final class MontyBackwardCompatibilityTests: XCTestCase {
    @MainActor
    func testMontyBackwardcompatibilityHistoricalInterfacesRemainVisibleThroughGuderianCore() {
        let snapshot = HistoricalBoardSnapshot(
            battleID: MontyBackwardCompatibilityReexportBattleID.smoke,
            turnNumber: 1,
            activeSideID: "montgomery",
            phase: .movement,
            mission: HistoricalBoardMissionSnapshot(
                name: "Monty compatibility smoke",
                targetScore: 8,
                humanScore: 3,
                aiScore: 1
            ),
            units: [
                HistoricalBoardUnitSnapshot(
                    id: 1,
                    sideID: "montgomery",
                    name: "Monty smoke unit",
                    kind: "Infantry",
                    role: "Shared interface",
                    position: HistoricalBattleCoordinate(x: 40, y: 24),
                    facingDegrees: 180,
                    canMoveNow: true,
                    selected: true
                ),
                HistoricalBoardUnitSnapshot(
                    id: 2,
                    sideID: "opposition",
                    name: "Opposing smoke unit",
                    kind: "Armour",
                    role: "Shared target",
                    position: HistoricalBattleCoordinate(x: 58, y: 30),
                    facingDegrees: 0,
                    targeted: true
                ),
            ],
            zones: [
                HistoricalBoardZoneSnapshot(
                    id: 1,
                    name: "Ridge",
                    kind: .ridge,
                    origin: HistoricalBattleCoordinate(x: 18, y: 22),
                    width: 60,
                    height: 6,
                    blocksLineOfSight: true
                ),
            ],
            objectives: [
                HistoricalBoardObjectiveSnapshot(
                    id: 1,
                    name: "Hold ridge",
                    location: HistoricalBattleCoordinate(x: 52, y: 24),
                    radius: 5,
                    controllingSideID: "montgomery"
                ),
            ]
        )
        let contract = HistoricalAutoplayContract(
            primarySurfaceName: "MontyTestFirstBattleAutoplayView",
            requiredAccessibilityIdentifiers: [
                "monty-test-run-to-debrief-button",
                "monty-test-result-summary",
            ]
        )
        let debrief = HistoricalPlayableDebriefSummary(
            title: "Monty compatibility",
            summary: "Shared surface remained visible through GuderianCore.",
            scoreLine: "8 VP | Turn 2"
        )
        let view = HistoricalPlayableBattleView(
            battleTitle: "Monty compatibility smoke",
            selectedSideTitle: "Montgomery command",
            opposingSideTitle: "Opposing command",
            snapshot: snapshot,
            debrief: debrief
        )
        let audit = HistoricalBoardLayoutResolver.readabilityAudit(for: snapshot)

        XCTAssertEqual(HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName, "HistoricalPlayableBattleView")
        XCTAssertTrue(HistoricalPlayableSurfaceCatalog.hasPublicSwiftUIBattleSurface)
        XCTAssertEqual(contract.embeddedBattleSurfaceName, HistoricalPlayableSurfaceCatalog.sharedHostSurfaceName)
        XCTAssertTrue(contract.isFirstBattleAutoplayContract)
        XCTAssertTrue(HistoricalPlayableSurfaceCatalog.boardInteractionProfile.supportsGuderianStyleBoardCommands)
        XCTAssertTrue(HistoricalPlayableSurfaceCatalog.boardReadabilityProfile.preventsDenseAlwaysOnBoardText)
        XCTAssertTrue(HistoricalPlayableSurfaceCatalog.boardViewportProfile.isCriticalViewportReady)
        XCTAssertEqual(
            HistoricalBoardInteractionResolver.unitTapIntent(for: snapshot.units[0], in: snapshot),
            .selectUnit(1)
        )
        XCTAssertEqual(
            HistoricalBoardInteractionResolver.unitTapIntent(for: snapshot.units[1], in: snapshot),
            .selectTarget(2)
        )
        XCTAssertTrue(audit.passesCriticalReadabilityGate)
        XCTAssertTrue(String(describing: type(of: view)).contains("HistoricalPlayableBattleView"))
    }
}
