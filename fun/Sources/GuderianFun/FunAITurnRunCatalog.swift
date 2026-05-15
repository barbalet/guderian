import Foundation
import GuderianCore

public struct FunBattleTurnRunSummary: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: String
    public let order: Int
    public let title: String
    public let runCount: Int
    public let completedTurns: [Int]
    public let movedDistances: [Double]
    public let blockedMovementPhases: [Int]
    public let averageTurns: Double
    public let averageMovedDistance: Double
    public let averageBlockedMovementPhases: Double
    public let blockers: [String]

    public init(
        id: String,
        battleID: String,
        order: Int,
        title: String,
        runCount: Int,
        completedTurns: [Int],
        movedDistances: [Double],
        blockedMovementPhases: [Int],
        averageTurns: Double,
        averageMovedDistance: Double,
        averageBlockedMovementPhases: Double,
        blockers: [String]
    ) {
        self.id = id
        self.battleID = battleID
        self.order = order
        self.title = title
        self.runCount = runCount
        self.completedTurns = completedTurns
        self.movedDistances = movedDistances
        self.blockedMovementPhases = blockedMovementPhases
        self.averageTurns = averageTurns
        self.averageMovedDistance = averageMovedDistance
        self.averageBlockedMovementPhases = averageBlockedMovementPhases
        self.blockers = blockers
    }
}

public enum FunAITurnRunCatalog {
    public static func averageTurns(runCount: Int = 4) throws -> [String: FunBattleTurnRunSummary] {
        guard runCount > 0 else {
            return [:]
        }

        let summaries = try UnifiedGuderianBattleCatalog.allEntries.map { entry in
            try summary(for: entry, runCount: runCount)
        }
        return Dictionary(uniqueKeysWithValues: summaries.map { ($0.battleID, $0) })
    }

    private static func summary(
        for entry: UnifiedGuderianBattleEntry,
        runCount: Int
    ) throws -> FunBattleTurnRunSummary {
        var completedTurns: [Int] = []
        var movedDistances: [Double] = []
        var blockedMovementPhases: [Int] = []
        var blockers: [String] = []

        for runIndex in 0..<runCount {
            let sample: FunBattleTurnSample
            switch entry.id.kind {
            case .fieldCommand:
                guard let id = entry.id.fieldCommandID else {
                    throw FunAITurnRunError.missingBattle(entry.id.rawValue)
                }
                sample = try fieldCommandSample(for: id, entry: entry, runIndex: runIndex)
            case .lateCareer:
                guard let id = entry.id.lateCareerID else {
                    throw FunAITurnRunError.missingBattle(entry.id.rawValue)
                }
                sample = try lateCareerSample(for: id, entry: entry, runIndex: runIndex)
            }

            completedTurns.append(sample.completedTurns)
            movedDistances.append(sample.movedDistance)
            blockedMovementPhases.append(sample.blockedMovementPhases)
            blockers.append(contentsOf: sample.blockers.map { "run \(runIndex + 1): \($0)" })
        }

        let averageTurns = average(completedTurns.map(Double.init))
        let averageMovedDistance = average(movedDistances)
        let averageBlockedMovementPhases = average(blockedMovementPhases.map(Double.init))
        let battleID = reportBattleID(for: entry)
        return FunBattleTurnRunSummary(
            id: "\(battleID)-ai-turns-\(runCount)",
            battleID: battleID,
            order: entry.order,
            title: entry.title,
            runCount: runCount,
            completedTurns: completedTurns,
            movedDistances: movedDistances,
            blockedMovementPhases: blockedMovementPhases,
            averageTurns: averageTurns,
            averageMovedDistance: averageMovedDistance,
            averageBlockedMovementPhases: averageBlockedMovementPhases,
            blockers: blockers
        )
    }

    private static func fieldCommandSample(
        for id: GuderianBattleID,
        entry: UnifiedGuderianBattleEntry,
        runIndex: Int
    ) throws -> FunBattleTurnSample {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            throw FunAITurnRunError.missingBattle(entry.id.rawValue)
        }

        let result = try PlayableTestGameRunner.runBattle(
            for: id,
            seed: deterministicSeed(order: entry.order, runIndex: runIndex)
        )
        let targetTurns = ScenarioBalanceCatalog.profile(for: scenario).targetTurns.upperBound
        return FunBattleTurnSample(
            completedTurns: completedTurns(from: result.finalSnapshot.turnNumber, targetUpperBound: targetTurns),
            movedDistance: result.totalMovementDistance,
            blockedMovementPhases: result.blockedMovementPhases,
            blockers: result.blockers
        )
    }

    private static func lateCareerSample(
        for id: String,
        entry: UnifiedGuderianBattleEntry,
        runIndex: Int
    ) throws -> FunBattleTurnSample {
        guard let session = LateCareerNativeBoardSession(
            battlefieldID: id,
            seed: deterministicSeed(order: entry.order, runIndex: runIndex)
        ) else {
            throw FunAITurnRunError.sessionUnavailable(id)
        }
        guard let presentation = LateCareerGuderianPresentationCatalog.entry(for: id) else {
            throw FunAITurnRunError.missingBattle(id)
        }

        let report = LateCareerPlayableSurfaceCatalog.report(for: id)
        let targetTurns = report?.scoringProfile.targetTurnUpperBound ?? 10
        let maxPhaseAdvances = max(24, targetTurns * 8)
        let guderianPriorities = report?.aiPlan.priorities.map(\.targetName) ??
            UnifiedGuderianBattleSideSelectionCatalog.objectivePriorityNames(for: .guderianAI, in: presentation)
        let playerPriorities = UnifiedGuderianBattleSideSelectionCatalog.objectivePriorityNames(for: .player, in: presentation)
        var phaseAdvances = 0
        var actionCount = 0
        var movedDistance = 0.0
        var blockedMovementPhases = 0
        var activeSides: Set<NativeBoardPlayer> = []
        var current = session.snapshot()
        var blockers: [String] = current.isScenarioBoardPlayable ? [] : ["opening board is not scenario-playable"]

        while current.turnNumber <= targetTurns &&
            current.mission.winner == .none &&
            phaseAdvances < maxPhaseAdvances {
            activeSides.insert(current.activePlayer)
            let priorities = current.activePlayer == .guderianAI ? guderianPriorities : playerPriorities
            let telemetry = runActiveLateCareerAIPhase(
                battleID: id,
                in: session,
                snapshot: current,
                priorityNames: priorities
            )
            actionCount += telemetry.actionCount
            movedDistance += telemetry.movedDistance
            blockedMovementPhases += telemetry.blockedMovementPhaseCount
            drainPendingChoices(in: session)
            session.advancePhase()
            phaseAdvances += 1
            current = session.snapshot()
        }

        if phaseAdvances >= maxPhaseAdvances {
            blockers.append("\(entry.title) hit the \(maxPhaseAdvances)-phase autoplay guard before debrief.")
        }
        if !activeSides.contains(.player) {
            blockers.append("Default-side automation did not receive an active phase.")
        }
        if !activeSides.contains(.guderianAI) {
            blockers.append("Guderian-command automation did not receive an active phase.")
        }
        if actionCount == 0 {
            blockers.append("AI autoplay produced no legal movement, shooting, assault, or pending-choice action.")
        }

        return FunBattleTurnSample(
            completedTurns: completedTurns(from: current.turnNumber, targetUpperBound: targetTurns),
            movedDistance: movedDistance,
            blockedMovementPhases: blockedMovementPhases,
            blockers: blockers
        )
    }

    private static func runActiveLateCareerAIPhase(
        battleID: String,
        in session: LateCareerNativeBoardSession,
        snapshot: NativeBoardSnapshot,
        priorityNames: [String]
    ) -> FunAIPhaseTelemetry {
        switch snapshot.phase {
        case .movement:
            return moveActiveLateCareerUnits(
                battleID: battleID,
                in: session,
                snapshot: snapshot,
                priorityNames: priorityNames
            )
        case .shooting:
            return FunAIPhaseTelemetry(actionCount: shootActiveLateCareerUnits(in: session, snapshot: snapshot))
        case .assault:
            let assaults = assaultActiveLateCareerUnits(in: session, snapshot: snapshot)
            return FunAIPhaseTelemetry(actionCount: assaults + (session.resolveFirstPendingChoice() ? 1 : 0))
        }
    }

    private static func moveActiveLateCareerUnits(
        battleID: String,
        in session: LateCareerNativeBoardSession,
        snapshot: NativeBoardSnapshot,
        priorityNames: [String]
    ) -> FunAIPhaseTelemetry {
        let units = activeUnits(in: snapshot).filter(\.canMoveNow)
        var moved = 0
        var movedDistance = 0.0

        for unit in units {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            let maxDistance = movementDistance(
                for: unit,
                activePlayer: snapshot.activePlayer,
                battleID: battleID,
                turnNumber: snapshot.turnNumber
            )
            let usedPriority = session.moveSelectedUnitTowardPriorityObjective(
                named: priorityNames,
                maxDistance: maxDistance
            )
            if usedPriority ||
                session.moveSelectedUnitTowardNearestObjective(maxDistance: maxDistance) {
                moved += 1
                if let after = session.snapshot().units.first(where: { $0.id == unit.id }) {
                    movedDistance += hypot(after.x - unit.x, after.y - unit.y)
                }
            }
        }

        return FunAIPhaseTelemetry(
            actionCount: moved,
            movedDistance: movedDistance,
            blockedMovementPhaseCount: moved == 0 ? 1 : 0
        )
    }

    private static func shootActiveLateCareerUnits(
        in session: LateCareerNativeBoardSession,
        snapshot: NativeBoardSnapshot
    ) -> Int {
        let units = activeUnits(in: snapshot).filter(\.canShootNow)
        var shots = 0

        for unit in units {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            if session.shootSelectedTarget() {
                shots += 1
                drainPendingChoices(in: session)
            }
        }

        return shots
    }

    private static func assaultActiveLateCareerUnits(
        in session: LateCareerNativeBoardSession,
        snapshot: NativeBoardSnapshot
    ) -> Int {
        let units = activeUnits(in: snapshot).filter(\.canAssaultNow)
        var assaults = 0

        for unit in units {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            if let target = session.snapshot().selectedTarget,
               session.assaultUnit(unit.id, targetID: target.id, advance: true) {
                assaults += 1
                drainPendingChoices(in: session)
            }
        }

        return assaults
    }

    private static func activeUnits(in snapshot: NativeBoardSnapshot) -> [NativeBoardUnitSnapshot] {
        snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed }
            .sorted { $0.id < $1.id }
    }

    private static func drainPendingChoices(in session: LateCareerNativeBoardSession) {
        for _ in 0..<16 {
            guard session.resolveFirstPendingChoice() else {
                return
            }
        }
    }

    private static func movementDistance(
        for unit: NativeBoardUnitSnapshot,
        activePlayer: NativeBoardPlayer,
        battleID: String,
        turnNumber: Int
    ) -> Double {
        let base: Double
        if unit.kind == "Vehicle" || unit.kind == "Assault gun" {
            base = activePlayer == .guderianAI ? 9 : 7
        } else {
            base = activePlayer == .guderianAI ? 5 : 4
        }
        return max(3, base - movementFriction(for: battleID, activePlayer: activePlayer, turnNumber: turnNumber))
    }

    private static func movementFriction(
        for battleID: String,
        activePlayer: NativeBoardPlayer,
        turnNumber: Int
    ) -> Double {
        switch battleID {
        case "kamenets-podolsky-pocket":
            return turnNumber <= 4 ? 1 : 0
        case "kursk-armored-force-pressure":
            return activePlayer == .guderianAI && turnNumber <= 3 ? 1 : 0
        default:
            return 0
        }
    }

    private static func completedTurns(from finalTurn: Int, targetUpperBound: Int) -> Int {
        min(max(1, finalTurn), max(1, targetUpperBound))
    }

    private static func reportBattleID(for entry: UnifiedGuderianBattleEntry) -> String {
        switch entry.id.kind {
        case .fieldCommand:
            return "field:\(entry.id.rawValue)"
        case .lateCareer:
            return "late:\(entry.id.rawValue)"
        }
    }

    private static func deterministicSeed(order: Int, runIndex: Int) -> UInt32 {
        UInt32(1_040_000 + order * 100 + runIndex)
    }

    private static func average(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
}

private struct FunBattleTurnSample: Hashable, Sendable {
    let completedTurns: Int
    let movedDistance: Double
    let blockedMovementPhases: Int
    let blockers: [String]
}

private struct FunAIPhaseTelemetry: Hashable, Sendable {
    let actionCount: Int
    let movedDistance: Double
    let blockedMovementPhaseCount: Int

    init(actionCount: Int, movedDistance: Double = 0, blockedMovementPhaseCount: Int = 0) {
        self.actionCount = actionCount
        self.movedDistance = movedDistance
        self.blockedMovementPhaseCount = blockedMovementPhaseCount
    }
}

private enum FunAITurnRunError: Error, CustomStringConvertible {
    case missingBattle(String)
    case sessionUnavailable(String)

    var description: String {
        switch self {
        case .missingBattle(let id):
            return "Missing battle \(id) while generating AI turn averages."
        case .sessionUnavailable(let id):
            return "Unable to create native board session for \(id)."
        }
    }
}
