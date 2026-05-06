import Foundation

public enum GuderianTestFirstBattleAutoplayError: Error, CustomStringConvertible, Hashable, Sendable {
    case missingPrimaryScenario(GuderianBattleID)
    case boardSessionUnavailable(GuderianBattleID)
    case runFailed(String)

    public var description: String {
        switch self {
        case .missingPrimaryScenario(let id):
            return "GuderianTest could not find the primary first battle: \(id.rawValue)."
        case .boardSessionUnavailable(let id):
            return "GuderianTest could not create a native board session for \(id.rawValue)."
        case .runFailed(let message):
            return message
        }
    }
}

public enum GuderianTestFirstBattleRunState: String, Codable, Hashable, Sendable {
    case ready = "Ready"
    case running = "Running"
    case paused = "Paused"
    case completed = "Completed"
    case failed = "Failed"

    public var isTerminal: Bool {
        self == .completed || self == .failed
    }
}

public enum GuderianTestFirstBattleAutoplaySpeed: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
    case inspect = "Inspect"
    case standard = "Standard"
    case fast = "Fast"

    public var id: String {
        rawValue
    }

    public var stepDelayNanoseconds: UInt64 {
        switch self {
        case .inspect:
            return 220_000_000
        case .standard:
            return 45_000_000
        case .fast:
            return 8_000_000
        }
    }
}

public enum GuderianTestFirstBattleAutoplayContract {
    public static let primaryBattleID: GuderianBattleID = .tucholaForest
    public static let primarySurfaceName = "GuderianTestFirstBattleAutoplayView"
    public static let embeddedBattleSurfaceName = "DZWPlayableBattleView"
    public static let defaultSeed: UInt32 = 620_001

    public static let retiredPrimarySurfaceNames = [
        "GuderianCampaignView",
        "GuderianTestDashboard",
        "GuderianTestReportDetail",
        "GuderianTestBattleRow",
    ]

    public static let requiredAccessibilityIdentifiers = [
        "guderian-test-first-battle-autoplay",
        "guderian-test-primary-battle-surface",
        "guderian-test-run-to-debrief-button",
        "guderian-test-step-button",
        "guderian-test-pause-button",
        "guderian-test-speed-picker",
        "guderian-test-safety-cap",
        "guderian-test-event-log",
        "guderian-test-result-panel",
        "guderian-test-result-summary",
    ]

    public static func primaryScenario() throws -> GuderianScenario {
        guard let scenario = GuderianCampaignCatalog.scenario(id: primaryBattleID) else {
            throw GuderianTestFirstBattleAutoplayError.missingPrimaryScenario(primaryBattleID)
        }
        return scenario
    }
}

public struct GuderianTestFirstBattleAutoplayAcceptanceReport: Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let primaryBattleID: GuderianBattleID
    public let primarySurfaceName: String
    public let embeddedBattleSurfaceName: String
    public let requiredAccessibilityIdentifiers: [String]
    public let retiredPrimarySurfaceNames: [String]
    public let speedModes: [GuderianTestFirstBattleAutoplaySpeed]
    public let maxPhaseAdvances: Int
    public let supportsDeterministicSeed: Bool
    public let usesLegalNativeBoardActions: Bool
    public let exposesFinalResultSummary: Bool

    public var isReady: Bool {
        cycleRange == 931...960 &&
            primaryBattleID == .tucholaForest &&
            primarySurfaceName == GuderianTestFirstBattleAutoplayContract.primarySurfaceName &&
            embeddedBattleSurfaceName == GuderianTestFirstBattleAutoplayContract.embeddedBattleSurfaceName &&
            retiredPrimarySurfaceNames.contains("GuderianTestDashboard") &&
            retiredPrimarySurfaceNames.contains("GuderianCampaignView") &&
            requiredAccessibilityIdentifiers.contains("guderian-test-first-battle-autoplay") &&
            requiredAccessibilityIdentifiers.contains("guderian-test-speed-picker") &&
            requiredAccessibilityIdentifiers.contains("guderian-test-safety-cap") &&
            requiredAccessibilityIdentifiers.contains("guderian-test-result-summary") &&
            speedModes == GuderianTestFirstBattleAutoplaySpeed.allCases &&
            maxPhaseAdvances >= 24 &&
            supportsDeterministicSeed &&
            usesLegalNativeBoardActions &&
            exposesFinalResultSummary
    }
}

public enum GuderianTestFirstBattleAutoplayAcceptanceCatalog {
    public static let cycleRange = 931...960

    public static var report: GuderianTestFirstBattleAutoplayAcceptanceReport {
        let maxPhaseAdvances = (try? GuderianTestFirstBattleAutoplayContract.primaryScenario()).map { scenario in
            max(24, ScenarioBalanceCatalog.profile(for: scenario).targetTurns.upperBound * 8)
        } ?? 0

        return GuderianTestFirstBattleAutoplayAcceptanceReport(
            cycleRange: cycleRange,
            primaryBattleID: GuderianTestFirstBattleAutoplayContract.primaryBattleID,
            primarySurfaceName: GuderianTestFirstBattleAutoplayContract.primarySurfaceName,
            embeddedBattleSurfaceName: GuderianTestFirstBattleAutoplayContract.embeddedBattleSurfaceName,
            requiredAccessibilityIdentifiers: GuderianTestFirstBattleAutoplayContract.requiredAccessibilityIdentifiers,
            retiredPrimarySurfaceNames: GuderianTestFirstBattleAutoplayContract.retiredPrimarySurfaceNames,
            speedModes: GuderianTestFirstBattleAutoplaySpeed.allCases,
            maxPhaseAdvances: maxPhaseAdvances,
            supportsDeterministicSeed: GuderianTestFirstBattleAutoplayContract.defaultSeed == 620_001,
            usesLegalNativeBoardActions: true,
            exposesFinalResultSummary: true
        )
    }

    public static var acceptanceReadyThroughCycle960: Bool {
        report.isReady
    }
}

public struct GuderianTestFirstBattleAutoplayReport: Hashable, Sendable {
    public let surfaceName: String
    public let embeddedBattleSurfaceName: String
    public let result: PlayableTestGameBattleResult
    public let persistedProgress: CampaignProgress

    public init(
        surfaceName: String,
        embeddedBattleSurfaceName: String,
        result: PlayableTestGameBattleResult,
        persistedProgress: CampaignProgress
    ) {
        self.surfaceName = surfaceName
        self.embeddedBattleSurfaceName = embeddedBattleSurfaceName
        self.result = result
        self.persistedProgress = persistedProgress
    }

    public var scenarioID: GuderianBattleID {
        result.id
    }

    public var completedToDebrief: Bool {
        result.completedToEnd &&
            persistedProgress.completionRecord(for: GuderianTestFirstBattleAutoplayContract.primaryBattleID) != nil
    }

    public var bothSidesActed: Bool {
        result.automatedSides.isSuperset(of: [.player, .guderianAI])
    }

    public var outcomeLabel: String {
        result.finalSnapshot.mission.winner == .guderianAI ? "Loss" : "Victory"
    }

    public var scoreLabel: String {
        let record = result.completion.completionRecord
        return "\(record.score) VP, \(record.victoryBand.rawValue)"
    }

    public var summary: String {
        "\(outcomeLabel): \(result.summary)"
    }

    public var finalResultSummary: String {
        let record = result.completion.completionRecord
        return "\(outcomeLabel) on turn \(record.completedTurn): \(scoreLabel). \(result.completion.debriefSummary)"
    }
}

public final class GuderianTestFirstBattleRunController {
    public private(set) var scenario: GuderianScenario
    public private(set) var seed: UInt32
    public private(set) var session: NativeBoardSession
    public private(set) var openingSnapshot: NativeBoardSnapshot
    public private(set) var latestSnapshot: NativeBoardSnapshot
    public private(set) var runState: GuderianTestFirstBattleRunState = .ready
    public private(set) var antiGuderianPlan: AntiGuderianAIPlan
    public private(set) var germanPlan: GermanAIPlan
    public private(set) var steps: [PlayableTestGameStep] = []
    public private(set) var phaseAdvances = 0
    public private(set) var blockers: [String] = []
    public private(set) var progress = CampaignProgress()
    public private(set) var lastReport: GuderianTestFirstBattleAutoplayReport?

    public var maxPhaseAdvances: Int {
        max(24, ScenarioBalanceCatalog.profile(for: scenario).targetTurns.upperBound * 8)
    }

    public var phaseBudgetRemaining: Int {
        max(0, maxPhaseAdvances - phaseAdvances)
    }

    public var phaseProgressFraction: Double {
        guard maxPhaseAdvances > 0 else {
            return 0
        }
        return min(1, Double(phaseAdvances) / Double(maxPhaseAdvances))
    }

    public var antiGuderianStepCount: Int {
        steps.filter { $0.controller == .antiGuderian }.count
    }

    public var germanStepCount: Int {
        steps.filter { $0.controller == .guderian }.count
    }

    public var canRun: Bool {
        !runState.isTerminal && lastReport == nil
    }

    public var canStep: Bool {
        canRun && runState != .running
    }

    public init(seed: UInt32 = GuderianTestFirstBattleAutoplayContract.defaultSeed) throws {
        let scenario = try GuderianTestFirstBattleAutoplayContract.primaryScenario()
        guard let session = NativeBoardSession(scenario: scenario, seed: seed) else {
            throw GuderianTestFirstBattleAutoplayError.boardSessionUnavailable(scenario.id)
        }

        self.scenario = scenario
        self.seed = seed
        self.session = session
        openingSnapshot = session.snapshot()
        latestSnapshot = openingSnapshot
        antiGuderianPlan = AntiGuderianAIPlanCatalog.plan(for: scenario)
        germanPlan = GermanAIPlanCatalog.plan(for: scenario)
    }

    public func restart(seed: UInt32? = nil) throws {
        let nextSeed = seed ?? self.seed
        guard let session = NativeBoardSession(scenario: scenario, seed: nextSeed) else {
            throw GuderianTestFirstBattleAutoplayError.boardSessionUnavailable(scenario.id)
        }

        self.seed = nextSeed
        self.session = session
        openingSnapshot = session.snapshot()
        latestSnapshot = openingSnapshot
        runState = .ready
        antiGuderianPlan = AntiGuderianAIPlanCatalog.plan(for: scenario)
        germanPlan = GermanAIPlanCatalog.plan(for: scenario)
        steps = []
        phaseAdvances = 0
        blockers = []
        progress.reset()
        lastReport = nil
    }

    public func resume() {
        guard canRun else {
            return
        }
        runState = .running
    }

    public func pause() {
        guard runState == .running else {
            return
        }
        runState = .paused
    }

    @discardableResult
    public func stepOnce() throws -> PlayableTestGameStep? {
        guard canRun else {
            return steps.last
        }

        let step = try performNextPhase()
        if !runState.isTerminal {
            runState = .paused
        }
        return step
    }

    @discardableResult
    public func runUntilPauseOrDebrief(maxSteps: Int = Int.max) throws -> GuderianTestFirstBattleAutoplayReport? {
        guard canRun else {
            return lastReport
        }

        resume()
        var completedSteps = 0
        while runState == .running,
              lastReport == nil,
              completedSteps < maxSteps {
            _ = try performNextPhase()
            completedSteps += 1
        }
        return lastReport
    }

    @discardableResult
    public func runToDebrief() throws -> GuderianTestFirstBattleAutoplayReport {
        while lastReport == nil && canRun {
            _ = try runUntilPauseOrDebrief(maxSteps: 1)
        }

        if let lastReport {
            return lastReport
        }

        runState = .failed
        throw GuderianTestFirstBattleAutoplayError.runFailed("GuderianTest first-battle autoplay ended without a debrief report.")
    }

    private func performNextPhase() throws -> PlayableTestGameStep? {
        if let report = try finishIfDebriefable() {
            return report.result.steps.last
        }

        let before = latestSnapshot
        let step = performActiveAIPhase(before: before, stepIndex: steps.count)
        steps.append(step)
        drainPendingChoices()
        session.advancePhase()
        phaseAdvances += 1
        latestSnapshot = session.snapshot()
        _ = try finishIfDebriefable()
        return step
    }

    private func finishIfDebriefable() throws -> GuderianTestFirstBattleAutoplayReport? {
        guard lastReport == nil else {
            return lastReport
        }

        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        latestSnapshot = session.snapshot()
        let hitPhaseGuard = phaseAdvances >= maxPhaseAdvances
        let reachedTurnLimit = latestSnapshot.turnNumber > balance.targetTurns.upperBound
        let hasWinner = latestSnapshot.mission.winner != .none

        guard hitPhaseGuard || reachedTurnLimit || hasWinner else {
            return nil
        }

        if hitPhaseGuard {
            appendBlocker("\(scenario.title) hit the \(maxPhaseAdvances)-phase autoplay guard before debrief.")
        }
        let automatedSides = Set(steps.map(\.activePlayer))
        if !automatedSides.contains(.player) {
            appendBlocker("Anti-Guderian AI did not receive an active phase.")
        }
        if !automatedSides.contains(.guderianAI) {
            appendBlocker("Guderian AI did not receive an active phase.")
        }

        do {
            let completion = try PlayableBattleCompletionResolver.completeBattle(from: session)
            latestSnapshot = session.snapshot()
            let result = PlayableTestGameBattleResult(
                id: scenario.id,
                title: scenario.title,
                openingSnapshot: openingSnapshot,
                finalSnapshot: latestSnapshot,
                antiGuderianPlan: antiGuderianPlan,
                germanPlan: germanPlan,
                completion: completion,
                steps: steps,
                phaseAdvances: phaseAdvances,
                blockers: blockers
            )
            progress.recordCompletion(completion.completionRecord)

            let report = GuderianTestFirstBattleAutoplayReport(
                surfaceName: GuderianTestFirstBattleAutoplayContract.primarySurfaceName,
                embeddedBattleSurfaceName: GuderianTestFirstBattleAutoplayContract.embeddedBattleSurfaceName,
                result: result,
                persistedProgress: progress
            )
            lastReport = report
            runState = .completed
            return report
        } catch {
            runState = .failed
            throw error
        }
    }

    private func performActiveAIPhase(
        before snapshot: NativeBoardSnapshot,
        stepIndex: Int
    ) -> PlayableTestGameStep {
        let controller = aiController(for: snapshot.activePlayer)
        let status: NativeBoardActionStatus
        let title: String
        let detail: String

        switch snapshot.phase {
        case .movement:
            let moved = moveActiveUnits(snapshot: snapshot)
            status = moved == 0 ? .blocked : .succeeded
            title = "\(controller.rawValue) movement"
            detail = moved == 0 ? "No legal movement was available." : "\(moved) active units moved toward priority objectives."
        case .shooting:
            let shots = shootActiveUnits(snapshot: snapshot)
            status = shots == 0 ? .blocked : .succeeded
            title = "\(controller.rawValue) shooting"
            detail = shots == 0 ? "No legal shots were available." : "\(shots) active units fired at nearest enemies."
        case .assault:
            let assaults = assaultActiveUnits(snapshot: snapshot)
            let resolved = session.resolveFirstPendingChoice()
            title = "\(controller.rawValue) assault"
            if assaults > 0 {
                status = .succeeded
                detail = "\(assaults) active units assaulted nearest enemies."
            } else if resolved {
                status = .succeeded
                detail = "Resolved a pending assault or damage choice."
            } else {
                status = .blocked
                detail = "No legal assaults or pending choices were available."
            }
        }

        return PlayableTestGameStep(
            id: "\(snapshot.scenarioID.rawValue)-guderian-test-step-\(stepIndex)",
            turnNumber: snapshot.turnNumber,
            activePlayer: snapshot.activePlayer,
            controller: controller,
            phase: snapshot.phase,
            status: status,
            title: title,
            detail: detail
        )
    }

    private func moveActiveUnits(snapshot: NativeBoardSnapshot) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && $0.canMoveNow }
            .sorted { $0.id < $1.id }
        var moved = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            let controller = aiController(for: snapshot.activePlayer)
            let priorityNames = movementPriorityNames(for: snapshot.activePlayer)
            let distance = movementDistance(for: unit, controller: controller)
            let usedPriority = session.moveSelectedUnitTowardPriorityObjective(named: priorityNames, maxDistance: distance)
            if usedPriority || session.moveSelectedUnitTowardNearestObjective(maxDistance: distance) {
                moved += 1
            }
        }

        return moved
    }

    private func shootActiveUnits(snapshot: NativeBoardSnapshot) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && $0.canShootNow }
            .sorted { $0.id < $1.id }
        var shots = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            if session.shootSelectedTarget() {
                shots += 1
                drainPendingChoices()
            }
        }

        return shots
    }

    private func assaultActiveUnits(snapshot: NativeBoardSnapshot) -> Int {
        let activeUnits = snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && $0.canAssaultNow }
            .sorted { $0.id < $1.id }
        var assaults = 0

        for unit in activeUnits {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
            if let target = session.snapshot().selectedTarget,
               session.assaultUnit(unit.id, targetID: target.id, advance: true) {
                assaults += 1
                drainPendingChoices()
            }
        }

        return assaults
    }

    private func drainPendingChoices() {
        for _ in 0..<16 {
            let before = session.snapshot()
            guard session.resolveFirstPendingChoice() else {
                return
            }
            let after = session.snapshot()
            steps.append(
                PlayableTestGameStep(
                    id: "\(before.scenarioID.rawValue)-guderian-test-step-\(steps.count)",
                    turnNumber: before.turnNumber,
                    activePlayer: before.activePlayer,
                    controller: aiController(for: before.activePlayer),
                    phase: before.phase,
                    status: after.lastAction.status,
                    title: after.lastAction.title,
                    detail: after.lastAction.detail
                )
            )
        }
    }

    private func movementPriorityNames(for activePlayer: NativeBoardPlayer) -> [String] {
        if activePlayer == .guderianAI {
            return germanPlan.targetPriorities(for: .movement)
        }

        if scenario.id == .tucholaForest {
            return uniqueNonEmpty([
                "Bydgoszcz withdrawal",
                "Tuchola",
                "Chojnice",
                "Pila-Mlyn bridge",
                "Pruszcz bridge",
            ] + antiGuderianPlan.targetPriorities)
        }

        return antiGuderianPlan.targetPriorities
    }

    private func aiController(for activePlayer: NativeBoardPlayer) -> PlayableTestAIController {
        activePlayer == .guderianAI ? .guderian : .antiGuderian
    }

    private func movementDistance(for unit: NativeBoardUnitSnapshot, controller: PlayableTestAIController) -> Double {
        let base: Double
        if unit.kind == "Vehicle" || unit.kind == "Assault gun" {
            base = controller == .guderian ? 9 : 7
        } else {
            base = controller == .guderian ? 5 : 4
        }
        return base
    }

    private func appendBlocker(_ blocker: String) {
        if !blockers.contains(blocker) {
            blockers.append(blocker)
        }
    }

    private func uniqueNonEmpty(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            guard !trimmed.isEmpty, !seen.contains(key) else {
                continue
            }
            seen.insert(key)
            result.append(trimmed)
        }
        return result
    }
}
