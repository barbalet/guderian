import Foundation
import GuderianCore
import Testing

@Suite("Guderian order-dice migration cycles 1-20")
struct GuderianOrderDiceMigrationTests {
    @Test("Cycles 1-5 audit covers every known phase-flow dependency category")
    func orderDiceAuditCoversLegacyPhaseDependencies() throws {
        let findings = GuderianOrderDiceAuditCatalog.findings
        let plan = try String(contentsOfFile: "PLAN.md", encoding: .utf8)
        let docs = try String(contentsOfFile: "docs/guderian_order_dice_cycle_001_020.md", encoding: .utf8)

        #expect(GuderianOrderDiceAuditCatalog.acceptanceReadyThroughCycle5)
        #expect(GuderianOrderDiceAuditCatalog.cycleRange == 1...5)
        #expect(findings.count >= 10)
        #expect(GuderianOrderDiceAuditCatalog.categoriesCovered == Set(GuderianOrderDiceAuditCategory.allCases))
        #expect(GuderianOrderDiceAuditCatalog.impactedTypeNames.contains("DZWPlayableBattleViewModel"))
        #expect(GuderianOrderDiceAuditCatalog.impactedTypeNames.contains("GuderianTestFirstBattleRunController"))
        #expect(GuderianOrderDiceAuditCatalog.impactedTypeNames.contains("LateCareerNativeBoardSession"))
        #expect(findings.allSatisfy { !$0.sourcePath.isEmpty && !$0.legacyAssumption.isEmpty })
        #expect(plan.contains("Cycles 1-20 complete"))
        #expect(docs.contains("Rules reference: Warlord Games Bolt Action reference sheet"))
    }

    @Test("Cycles 6-10 scenario impact map covers all 35 battles and both sides")
    func scenarioImpactMapCoversAllUnifiedBattles() throws {
        let rows = GuderianOrderDiceScenarioImpactCatalog.allRows
        let tuchola = try #require(GuderianOrderDiceScenarioImpactCatalog.row(for: .fieldCommand(.tucholaForest)))
        let moscow = try #require(GuderianOrderDiceScenarioImpactCatalog.row(for: .fieldCommand(.moscowTulaKashira)))
        let lateCareer = try #require(rows.first { $0.id.kind == .lateCareer })

        #expect(GuderianOrderDiceScenarioImpactCatalog.acceptanceReadyThroughCycle10)
        #expect(rows.count == 35)
        #expect(rows.map(\.order) == Array(1...35))
        #expect(Set(rows.map(\.id)).count == 35)
        #expect(rows.allSatisfy { $0.hasOrderDiceForBothSides })
        #expect(rows.allSatisfy { !$0.vehicleClasses.isEmpty })
        #expect(rows.allSatisfy { !$0.terrainCategories.isEmpty })
        #expect(tuchola.retainedOrderUse == .ambushLikely || tuchola.retainedOrderUse == .ambushAndDown)
        #expect(tuchola.terrainCategories.contains(.road))
        #expect(moscow.expectedPinPressure == .heavy || moscow.expectedPinPressure == .severe)
        #expect(moscow.vehicleClasses.contains(.heavyArmor))
        #expect(lateCareer.commandScope.requiresCommandCaveat)
        #expect(lateCareer.officerPresence == .commandCritical)
    }

    @Test("Cycles 11-15 compatibility shim maps legacy intent to DZW order contracts")
    func compatibilityShimIssuesOrderBeforeLegacyAction() throws {
        let session = try #require(NativeBoardSession(battleID: .tucholaForest, seed: 20_015))
        let opening = session.snapshot()
        let activeUnit = try #require(opening.units.first { $0.owner == opening.activePlayer && !$0.destroyed })

        #expect(GuderianOrderDiceCompatibilityShim.acceptanceReadyThroughCycle15)
        #expect(GuderianOrderDiceCompatibilityShim.dzwOrderContractReady)
        #expect(GuderianOrderDiceCompatibilityShim.requiredOrders == HistoricalBoardOrder.allCases)
        #expect(GuderianOrderDiceCompatibilityShim.preferredOrder(for: NativeBoardPhase.movement) == .advance)
        #expect(GuderianOrderDiceCompatibilityShim.preferredOrder(for: NativeBoardPhase.shooting) == .fire)
        #expect(GuderianOrderDiceCompatibilityShim.preferredOrder(for: NativeBoardPhase.assault) == .run)
        #expect(GuderianOrderDiceCompatibilityShim.requiredSnapshotFields.contains("pinCount"))
        #expect(GuderianOrderDiceCompatibilityShim.requiredSnapshotFields.contains("retainedOrder"))

        #expect(GuderianOrderDiceCompatibilityShim.issuePreferredOrderBeforeLegacyAction(
            in: session,
            unitID: activeUnit.id,
            phase: opening.phase
        ))
        let orderedUnit = try #require(session.snapshot().units.first { $0.id == activeUnit.id })
        #expect(orderedUnit.currentOrder == GuderianOrderDiceCompatibilityShim.preferredOrder(for: opening.phase))
    }

    @Test("Cycles 16-20 acceptance gates are installed and become blocking after the UI window")
    func acceptanceGatesCatchFuturePhaseSurfaceDebt() throws {
        let playableView = try String(
            contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift",
            encoding: .utf8
        )
        let catalystApp = try String(
            contentsOfFile: "Sources/GuderianMacCatalyst/GuderianMacCatalystApp.swift",
            encoding: .utf8
        )
        let autoplay = try String(
            contentsOfFile: "Sources/GuderianCore/GuderianTestFirstBattleAutoplay.swift",
            encoding: .utf8
        )
        let sources = [
            "Sources/GuderianApp/DZWPlayableBattleView.swift": playableView,
            "Sources/GuderianMacCatalyst/GuderianMacCatalystApp.swift": catalystApp,
            "Sources/GuderianCore/GuderianTestFirstBattleAutoplay.swift": autoplay,
        ]
        let cycle20Report = GuderianOrderDiceAcceptanceCatalog.report(
            sourceTextByPath: sources,
            evaluatedCycle: 20
        )
        let cycle75Report = GuderianOrderDiceAcceptanceCatalog.report(
            sourceTextByPath: sources,
            evaluatedCycle: 75
        )
        let macOSGate = try #require(cycle75Report.gateReports.first { $0.gate.id == "macos-playable-phase-buttons" })

        #expect(GuderianOrderDiceAcceptanceCatalog.acceptanceReadyThroughCycle20)
        #expect(cycle20Report.isReadyThroughCycle20)
        #expect(cycle20Report.blockers.isEmpty)
        #expect(cycle20Report.phaseSurfaceGateCount >= 3)
        #expect(cycle20Report.gateReports.allSatisfy { !$0.isBlocking })
        #expect(macOSGate.observedLegacyIdentifiers.isEmpty ? macOSGate.isSatisfied : macOSGate.isBlocking)
        #expect(GuderianOrderDiceAcceptanceCatalog.phaseSurfaceGates.allSatisfy { !$0.replacementContract.isEmpty })
    }
}
