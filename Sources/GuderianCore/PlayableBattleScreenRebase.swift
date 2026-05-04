import Foundation

public struct PlayableBattleCompletionSummary: Codable, Hashable, Sendable {
    public let sourceName: String
    public let completionRecord: CampaignCompletionRecord
    public let debriefSummary: String

    public init(
        sourceName: String,
        completionRecord: CampaignCompletionRecord,
        debriefSummary: String
    ) {
        self.sourceName = sourceName
        self.completionRecord = completionRecord
        self.debriefSummary = debriefSummary
    }
}

public enum PlayableBattleCompletionResolver {
    public static func completeBattle(from session: NativeBoardSession) throws -> PlayableBattleCompletionSummary {
        let id = session.loadout.scenario.id

        if NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs.contains(id) {
            let report = try NativeEasternFrontPackRunner.completeBattle(from: session)
            return PlayableBattleCompletionSummary(
                sourceName: "Native Eastern Front Pack",
                completionRecord: report.completionRecord,
                debriefSummary: report.debriefSummary
            )
        }

        if NativeFranceBattlefieldPackCatalog.playableBattleIDs.contains(id) {
            let report = try NativeFrancePackRunner.completeBattle(from: session)
            return PlayableBattleCompletionSummary(
                sourceName: "Native France Pack",
                completionRecord: report.completionRecord,
                debriefSummary: report.debriefSummary
            )
        }

        if NativePolandBattlefieldPackCatalog.playableBattleIDs.contains(id) {
            let report = try NativePolandPackRunner.completeBattle(from: session)
            return PlayableBattleCompletionSummary(
                sourceName: "Native Poland Pack",
                completionRecord: report.completionRecord,
                debriefSummary: report.debriefSummary
            )
        }

        let report = try NativeDemoParityRunner.completeBattle(from: session)
        return PlayableBattleCompletionSummary(
            sourceName: "Native Demo",
            completionRecord: report.completionRecord,
            debriefSummary: report.outcomeSummary
        )
    }
}

public enum DZWPlayableScreenHarnessStage: String, CaseIterable, Codable, Hashable, Sendable {
    case launch = "Launch"
    case selection = "Selection"
    case movement = "Movement"
    case phaseFlow = "Phase Flow"
    case attack = "Attack"
    case blockedAction = "Blocked Action"
    case aiTurn = "AI Turn"
    case debrief = "Debrief"
    case persistence = "Persistence"
}

public struct DZWPlayableScreenHarnessStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let stage: DZWPlayableScreenHarnessStage
    public let status: NativeBoardActionStatus
    public let detail: String
    public let accessibilityIdentifier: String

    public init(
        id: String,
        stage: DZWPlayableScreenHarnessStage,
        status: NativeBoardActionStatus,
        detail: String,
        accessibilityIdentifier: String
    ) {
        self.id = id
        self.stage = stage
        self.status = status
        self.detail = detail
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

public struct DZWPlayableScreenHarnessResult: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let openingSnapshot: NativeBoardSnapshot
    public let completion: PlayableBattleCompletionSummary
    public let steps: [DZWPlayableScreenHarnessStep]
    public let persistedProgress: CampaignProgress
    public let blockers: [String]

    public init(
        id: GuderianBattleID,
        title: String,
        openingSnapshot: NativeBoardSnapshot,
        completion: PlayableBattleCompletionSummary,
        steps: [DZWPlayableScreenHarnessStep],
        persistedProgress: CampaignProgress,
        blockers: [String]
    ) {
        self.id = id
        self.title = title
        self.openingSnapshot = openingSnapshot
        self.completion = completion
        self.steps = steps
        self.persistedProgress = persistedProgress
        self.blockers = blockers
    }

    public var completedStages: [DZWPlayableScreenHarnessStage] {
        DZWPlayableScreenHarnessStage.allCases.filter { stage in
            steps.contains { $0.stage == stage }
        }
    }

    public var completedAllStages: Bool {
        completedStages == DZWPlayableScreenHarnessStage.allCases && blockers.isEmpty
    }

    public var displayedAccessibilityIdentifiers: [String] {
        steps.map(\.accessibilityIdentifier)
    }
}

public enum DZWPlayableScreenHarness {
    public static let cycleRange = 486...490

    public static func runTucholaFlow(seed: UInt32 = 19390901) throws -> DZWPlayableScreenHarnessResult {
        guard let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
              let session = NativeBoardSession(scenario: scenario, seed: seed)
        else {
            throw NativeDemoParityError.boardSessionUnavailable(.tucholaForest)
        }

        var steps: [DZWPlayableScreenHarnessStep] = []
        var blockers: [String] = []
        let opening = session.snapshot()

        record(
            .launch,
            snapshot: opening,
            id: "battle-screen",
            detail: opening.isScenarioBoardPlayable ? "Tuchola opened on a rules-backed DZW-style board." : "Tuchola board was not scenario playable.",
            into: &steps
        )
        if !opening.isScenarioBoardPlayable {
            blockers.append("Opening board is not scenario playable.")
        }

        session.selectFirstActiveUnit()
        session.selectNearestEnemyToSelectedUnit()
        let selected = session.snapshot()
        record(.selection, snapshot: selected, id: "battle-sidebar-scroll", detail: selected.selectedUnit?.name ?? "No selected unit.", into: &steps)
        if selected.selectedUnit == nil {
            blockers.append("No active player unit could be selected.")
        }

        if let unit = selected.selectedUnit {
            let moved = session.moveUnit(
                unit.id,
                to: NativeBattleCoordinate(x: min(unit.x + 1.0, 70), y: min(unit.y + 0.75, 46))
            )
            let movement = session.snapshot()
            record(.movement, snapshot: movement, id: "battle-board", detail: movement.lastAction.detail, into: &steps)
            if !moved {
                blockers.append("Legal opening movement was blocked: \(movement.lastAction.detail)")
            }
        }

        session.advancePhase()
        let shooting = session.snapshot()
        record(.phaseFlow, snapshot: shooting, id: "next-phase-button", detail: shooting.lastAction.detail, into: &steps)
        if shooting.phase != .shooting {
            blockers.append("Phase flow did not advance to shooting.")
        }

        session.selectNearestEnemyToSelectedUnit()
        _ = session.shootSelectedTarget()
        let attack = session.snapshot()
        record(.attack, snapshot: attack, id: "shoot-target-button", detail: attack.lastAction.detail, into: &steps)

        _ = session.moveSelectedUnitTowardNearestObjective()
        let blocked = session.snapshot()
        record(.blockedAction, snapshot: blocked, id: "battle-action-feedback", detail: blocked.lastAction.detail, into: &steps)
        if blocked.lastAction.status != .blocked {
            blockers.append("Blocked-action reporting did not surface a blocked move during shooting.")
        }

        var safety = 0
        while session.snapshot().activePlayer != .guderianAI && safety < 4 {
            session.advancePhase()
            safety += 1
        }

        let aiTurn = session.snapshot()
        let movedAI = session.moveSelectedUnitTowardPriorityObjective(
            named: ScenarioContentCatalog.bundle(for: scenario).aiPlan.targetPriorities,
            maxDistance: 6
        )
        let aiAfter = session.snapshot()
        record(.aiTurn, snapshot: aiAfter, id: "german-turn-button", detail: aiAfter.lastAction.detail, into: &steps)
        if aiTurn.activePlayer != .guderianAI || !movedAI {
            blockers.append("German AI turn did not execute a priority move: \(aiAfter.lastAction.detail)")
        }

        let completion = try PlayableBattleCompletionResolver.completeBattle(from: session)
        let debriefSnapshot = session.snapshot()
        record(.debrief, snapshot: debriefSnapshot, id: "battle-debrief-panel", detail: completion.debriefSummary, into: &steps)

        var progress = CampaignProgress()
        progress.recordCompletion(completion.completionRecord)
        let persisted = progress.completionRecord(for: .tucholaForest) != nil
        record(
            .persistence,
            snapshot: debriefSnapshot,
            id: "battle-persisted-result",
            detail: persisted ? "Tuchola completion persisted to campaign progress." : "Tuchola completion was not persisted.",
            into: &steps
        )
        if !persisted {
            blockers.append("Completion record was not persisted.")
        }

        return DZWPlayableScreenHarnessResult(
            id: scenario.id,
            title: scenario.title,
            openingSnapshot: opening,
            completion: completion,
            steps: steps,
            persistedProgress: progress,
            blockers: blockers
        )
    }

    private static func record(
        _ stage: DZWPlayableScreenHarnessStage,
        snapshot: NativeBoardSnapshot,
        id accessibilityIdentifier: String,
        detail: String,
        into steps: inout [DZWPlayableScreenHarnessStep]
    ) {
        steps.append(
            DZWPlayableScreenHarnessStep(
                id: "\(snapshot.scenarioID.rawValue)-dzw-screen-\(stage.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))",
                stage: stage,
                status: snapshot.lastAction.status,
                detail: detail,
                accessibilityIdentifier: accessibilityIdentifier
            )
        )
    }
}

public enum PlayableBattleScreenReadiness: String, Codable, Hashable, Sendable {
    case pilotComplete = "Pilot complete"
    case nextRollout = "Next rollout"
    case queued = "Queued"
}

public enum PlayableBattleAcceptanceGate: String, CaseIterable, Codable, Hashable, Sendable {
    case boardLaunch = "DZW-style board launch"
    case scenarioUnits = "Scenario units"
    case terrainObjectives = "Terrain and objectives"
    case commandActions = "Command actions"
    case aiTurn = "Guderian AI turn"
    case blockedReporting = "Blocked-action reporting"
    case debriefPersistence = "Debrief and persistence"
    case automatedHarness = "Automated harness"
}

public struct PlayableBattleRolloutPlan: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let battleTitle: String
    public let order: Int
    public let readiness: PlayableBattleScreenReadiness
    public let cycleWindow: ClosedRange<Int>
    public let hostSurfaceName: String
    public let acceptanceGates: [PlayableBattleAcceptanceGate]
    public let notes: [String]

    public init(
        id: GuderianBattleID,
        battleTitle: String,
        order: Int,
        readiness: PlayableBattleScreenReadiness,
        cycleWindow: ClosedRange<Int>,
        hostSurfaceName: String,
        acceptanceGates: [PlayableBattleAcceptanceGate],
        notes: [String]
    ) {
        self.id = id
        self.battleTitle = battleTitle
        self.order = order
        self.readiness = readiness
        self.cycleWindow = cycleWindow
        self.hostSurfaceName = hostSurfaceName
        self.acceptanceGates = acceptanceGates
        self.notes = notes
    }

    public var cycleLabel: String {
        "Cycles \(cycleWindow.lowerBound)-\(cycleWindow.upperBound)"
    }
}

public enum PlayableBattleSurfaceCatalog {
    public static let cycleRange = 491...500
    public static let routedBattleIDs: [GuderianBattleID] = [.tucholaForest]
    public static let hostSurfaceName = "DZWPlayableBattleView"
    public static let acceptanceGates = PlayableBattleAcceptanceGate.allCases

    public static var allPlans: [PlayableBattleRolloutPlan] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(plan)
    }

    public static var nextRolloutIDs: [GuderianBattleID] {
        allPlans
            .filter { $0.readiness != .pilotComplete }
            .map(\.id)
    }

    public static func plan(for id: GuderianBattleID) -> PlayableBattleRolloutPlan? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return plan(for: scenario)
    }

    public static func isRoutedToPlayableScreen(_ id: GuderianBattleID) -> Bool {
        routedBattleIDs.contains(id)
    }

    private static func plan(for scenario: GuderianScenario) -> PlayableBattleRolloutPlan {
        let readiness: PlayableBattleScreenReadiness
        let cycleWindow: ClosedRange<Int>

        if scenario.id == .tucholaForest {
            readiness = .pilotComplete
            cycleWindow = 451...500
        } else if scenario.id == .wizna {
            readiness = .nextRollout
            cycleWindow = 501...505
        } else {
            readiness = .queued
            let offset = max(0, scenario.order - 2)
            let start = 501 + (offset * 5)
            cycleWindow = start...(start + 4)
        }

        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        return PlayableBattleRolloutPlan(
            id: scenario.id,
            battleTitle: scenario.title,
            order: scenario.order,
            readiness: readiness,
            cycleWindow: cycleWindow,
            hostSurfaceName: hostSurfaceName,
            acceptanceGates: acceptanceGates,
            notes: [
                "Use \(bundle.mapLayout.title) terrain and deployment data without bespoke UI forks.",
                "Keep \(bundle.aiPlan.postureName) as the visible German AI pressure model.",
                "Persist a CampaignCompletionRecord through the DZW-style debrief panel.",
            ]
        )
    }
}
