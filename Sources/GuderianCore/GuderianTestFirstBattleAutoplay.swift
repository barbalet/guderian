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
        "guderian-test-activation-count",
        "guderian-test-activation-safety-cap",
        "guderian-test-event-log",
        "guderian-test-result-panel",
        "guderian-test-result-summary",
    ]

    public static var sharedHistoricalAutoplayContract: HistoricalAutoplayContract {
        GuderianHistoricalAutoplayCatalog.firstBattleContract
    }

    public static func sharedHistoricalScenario() throws -> HistoricalBattleScenario<GuderianBattleID> {
        guard let scenario = GuderianHistoricalAutoplayCatalog.firstBattleScenario() else {
            throw GuderianTestFirstBattleAutoplayError.missingPrimaryScenario(primaryBattleID)
        }
        return scenario
    }

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
    public let maxActivationSteps: Int
    public let supportsDeterministicSeed: Bool
    public let usesLegalNativeBoardActions: Bool
    public let exposesFinalResultSummary: Bool
    public let countsOrderDiceActivations: Bool

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
            requiredAccessibilityIdentifiers.contains("guderian-test-activation-count") &&
            requiredAccessibilityIdentifiers.contains("guderian-test-activation-safety-cap") &&
            requiredAccessibilityIdentifiers.contains("guderian-test-result-summary") &&
            speedModes == GuderianTestFirstBattleAutoplaySpeed.allCases &&
            maxPhaseAdvances >= 24 &&
            maxActivationSteps >= maxPhaseAdvances &&
            supportsDeterministicSeed &&
            usesLegalNativeBoardActions &&
            exposesFinalResultSummary &&
            countsOrderDiceActivations
    }
}

public enum GuderianTestFirstBattleAutoplayAcceptanceCatalog {
    public static let cycleRange = 931...960

    public static var report: GuderianTestFirstBattleAutoplayAcceptanceReport {
        let maxPhaseAdvances = (try? GuderianTestFirstBattleAutoplayContract.primaryScenario()).map { scenario in
            let liveUnitCount = NativeBoardSession(scenario: scenario, seed: GuderianTestFirstBattleAutoplayContract.defaultSeed)?
                .snapshot()
                .units
                .filter { !$0.destroyed }
                .count ?? 8
            return max(48, ScenarioBalanceCatalog.profile(for: scenario).targetTurns.upperBound * max(24, liveUnitCount * 3))
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
            maxActivationSteps: maxPhaseAdvances,
            supportsDeterministicSeed: GuderianTestFirstBattleAutoplayContract.defaultSeed == 620_001,
            usesLegalNativeBoardActions: true,
            exposesFinalResultSummary: true,
            countsOrderDiceActivations: true
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
    public private(set) var activationSteps = 0
    public private(set) var blockers: [String] = []
    public private(set) var progress = CampaignProgress()
    public private(set) var lastReport: GuderianTestFirstBattleAutoplayReport?

    public var maxPhaseAdvances: Int {
        maxActivationSteps
    }

    public var maxActivationSteps: Int {
        max(
            48,
            ScenarioBalanceCatalog.profile(for: scenario).targetTurns.upperBound * max(24, openingSnapshot.units.filter { !$0.destroyed }.count * 3)
        )
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

    public var activationBudgetRemaining: Int {
        max(0, maxActivationSteps - activationSteps)
    }

    public var activationProgressFraction: Double {
        guard maxActivationSteps > 0 else {
            return 0
        }
        return min(1, Double(activationSteps) / Double(maxActivationSteps))
    }

    public var antiGuderianStepCount: Int {
        steps.filter { $0.controller == .antiGuderian }.count
    }

    public var germanStepCount: Int {
        steps.filter { $0.controller == .guderian }.count
    }

    public var opposingForcePlan: OpposingForceAIPlan {
        antiGuderianPlan
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
        antiGuderianPlan = OpposingForceAIPlanCatalog.plan(for: scenario)
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
        antiGuderianPlan = OpposingForceAIPlanCatalog.plan(for: scenario)
        germanPlan = GermanAIPlanCatalog.plan(for: scenario)
        steps = []
        phaseAdvances = 0
        activationSteps = 0
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

        let preferredOwner = activationSteps == 0 ? latestSnapshot.activePlayer : nil
        guard session.prepareNextOrderDiceActivation(preferredOwner: preferredOwner) else {
            appendBlocker("\(scenario.title) could not draw the next order die for activation \(activationSteps + 1).")
            runState = .failed
            return nil
        }
        let activationSnapshot = session.snapshot()
        let step = performActiveAIPhase(before: activationSnapshot, stepIndex: steps.count)
        steps.append(step)
        drainPendingChoices()
        resolveLingeringOrderDiceEffects()
        session.advancePhase()
        phaseAdvances += 1
        activationSteps += 1
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
        let hitPhaseGuard = activationSteps >= maxActivationSteps
        let reachedTurnLimit = latestSnapshot.turnNumber > balance.targetTurns.upperBound
        let hasWinner = latestSnapshot.mission.winner != .none

        guard hitPhaseGuard || reachedTurnLimit || hasWinner else {
            return nil
        }

        if hitPhaseGuard {
            appendBlocker("\(scenario.title) hit the \(maxActivationSteps)-activation autoplay guard before debrief.")
        }
        let automatedSides = Set(steps.map(\.activePlayer))
        if !automatedSides.contains(.player) {
            appendBlocker("Default-side automation did not receive an active phase.")
        }
        if !automatedSides.contains(.guderianAI) {
            appendBlocker("Guderian-command automation did not receive an active phase.")
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

        let target = priorityTarget(for: snapshot)
        let reason = priorityInstruction(for: snapshot)
        guard let unit = activationUnit(in: snapshot) else {
            return PlayableTestGameStep(
                id: "\(snapshot.scenarioID.rawValue)-guderian-test-step-\(stepIndex)",
                turnNumber: snapshot.turnNumber,
                activePlayer: snapshot.activePlayer,
                controller: controller,
                phase: snapshot.phase,
                status: .blocked,
                title: "\(controller.rawValue) activation",
                detail: "No legal order-dice activation was available for priority target \(target). Reason: \(reason)"
            )
        }

        session.selectUnit(unit.id)
        session.selectNearestEnemyToSelectedUnit()
        let order = activationOrder(for: unit, phase: snapshot.phase)
        let issued = session.issueOrder(order, to: unit.id)
        _ = issued ? session.resolveOrderTestIfNeeded(for: unit.id) : false
        let afterOrder = session.snapshot().units.first { $0.id == unit.id } ?? unit
        let action = resolveActivationAction(order: afterOrder.currentOrder ?? order, originalOrder: order, unit: afterOrder, snapshot: snapshot)
        status = issued && action.succeeded ? .succeeded : .blocked
        title = "\(controller.rawValue) \(order.rawValue) activation"
        detail = issued ?
            "\(unit.name) received \(order.rawValue); \(action.detail) Reason: \(reason)" :
            "\(unit.name) could not receive \(order.rawValue) for priority target \(target). Reason: \(reason)"

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

    private func resolveLingeringOrderDiceEffects() {
        let snapshot = session.snapshot()
        for unit in snapshot.units where !unit.destroyed && unit.currentOrder != nil {
            _ = session.resolveOrderTestIfNeeded(for: unit.id)
            if unit.currentOrder == .rally {
                _ = session.resolveRallyOrder(for: unit.id)
            }
        }
        drainPendingChoices()
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

    private func activationUnit(in snapshot: NativeBoardSnapshot) -> NativeBoardUnitSnapshot? {
        snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed && !$0.retainedOrder && $0.currentOrder == nil }
            .sorted { activationScore($0, phase: snapshot.phase) > activationScore($1, phase: snapshot.phase) }
            .first
    }

    private func activationScore(_ unit: NativeBoardUnitSnapshot, phase: NativeBoardPhase) -> Int {
        var score = 100 - unit.pinCount
        if unit.pinCount >= 2 { score += 8 }
        if unit.kind == "Artillery" || unit.kind == "Gun" { score += phase == .shooting ? 10 : 2 }
        if unit.kind == "Vehicle" || unit.kind == "Assault gun" { score += phase == .movement ? 8 : 4 }
        if unit.inCover || unit.hullDown { score += 2 }
        return score
    }

    private func activationOrder(
        for unit: NativeBoardUnitSnapshot,
        phase: NativeBoardPhase
    ) -> HistoricalBoardOrder {
        let options = unit.availableOrders.isEmpty ? HistoricalBoardOrder.allCases : unit.availableOrders
        if unit.pinCount >= 2, options.contains(.rally) {
            return .rally
        }
        switch phase {
        case .shooting where options.contains(.fire):
            return .fire
        case .assault where options.contains(.run):
            return .run
        case .movement:
            if (unit.kind == "Artillery" || unit.kind == "Gun"), options.contains(.fire) {
                return .fire
            }
            if (unit.kind == "Vehicle" || unit.kind == "Assault gun"), options.contains(.run) {
                return .run
            }
            if options.contains(.advance) {
                return .advance
            }
        default:
            break
        }
        if options.contains(.advance) { return .advance }
        if options.contains(.fire) { return .fire }
        return options.first ?? .down
    }

    private func resolveActivationAction(
        order: HistoricalBoardOrder,
        originalOrder: HistoricalBoardOrder,
        unit: NativeBoardUnitSnapshot,
        snapshot: NativeBoardSnapshot
    ) -> (succeeded: Bool, detail: String) {
        switch order {
        case .advance, .run:
            let maxDistance = order == .run ? max(unit.runMoveAllowance, movementDistance(for: unit, controller: aiController(for: snapshot.activePlayer))) : max(unit.advanceMoveAllowance, movementDistance(for: unit, controller: aiController(for: snapshot.activePlayer)))
            let moved = session.moveSelectedUnitTowardPriorityObjective(named: phasePriorityNames(for: snapshot.activePlayer, phase: snapshot.phase), maxDistance: maxDistance) ||
                session.moveSelectedUnitTowardNearestObjective(maxDistance: maxDistance)
            return (
                moved,
                moved ?
                    "1 active units moved toward priority target \(priorityTarget(for: snapshot)), with nearest legal objective as fallback." :
                    "No legal movement was available for priority target \(priorityTarget(for: snapshot)); fallback to nearest legal objective also failed."
            )
        case .fire:
            session.selectNearestEnemyToSelectedUnit()
            let fired = session.shootSelectedTarget()
            drainPendingChoices()
            return (
                fired,
                fired ?
                    "1 active units fired at nearest enemies to protect priority target \(priorityTarget(for: snapshot))." :
                    "No legal shots were available while protecting priority target \(priorityTarget(for: snapshot))."
            )
        case .rally:
            let rallied = session.resolveRallyOrder(for: unit.id)
            return (rallied || originalOrder == .rally, rallied ? "\(unit.name) rallied and removed pin pressure." : "\(unit.name) held the Rally order after order-test resolution.")
        case .ambush:
            return (true, "\(unit.name) retained Ambush for opportunity fire.")
        case .down:
            return (true, "\(unit.name) went Down to reduce incoming fire.")
        }
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
            guard session.resolveFirstPendingChoice() else {
                return
            }
        }
    }

    private func movementPriorityNames(for activePlayer: NativeBoardPlayer) -> [String] {
        phasePriorityNames(for: activePlayer, phase: .movement)
    }

    private func phasePriorityNames(
        for activePlayer: NativeBoardPlayer,
        phase: NativeBoardPhase
    ) -> [String] {
        if activePlayer == .guderianAI {
            return germanPlan.targetPriorities(for: phase)
        }

        if scenario.id == .tucholaForest && phase == .movement {
            return uniqueNonEmpty([
                "Bydgoszcz withdrawal",
                "Tuchola",
                "Chojnice",
                "Pila-Mlyn bridge",
                "Pruszcz bridge",
            ] + antiGuderianPlan.targetPriorities(for: phase))
        }

        return antiGuderianPlan.targetPriorities(for: phase)
    }

    private func priorityTarget(for snapshot: NativeBoardSnapshot) -> String {
        phasePriorityNames(for: snapshot.activePlayer, phase: snapshot.phase).first ?? "nearest legal objective"
    }

    private func priorityInstruction(for snapshot: NativeBoardSnapshot) -> String {
        if snapshot.activePlayer == .guderianAI {
            return germanPlan.orders.first { $0.kind.nativeBoardPhase == snapshot.phase }?.instruction ??
                germanPlan.strategicGoal
        }

        return antiGuderianPlan.orders.first { $0.kind.nativeBoardPhase == snapshot.phase }?.instruction ??
            antiGuderianPlan.strategicGoal
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
