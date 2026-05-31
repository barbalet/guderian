import Foundation
import GuderianCore
import SwiftUI

@main
struct GuderianMacCatalystApp: App {
    var body: some Scene {
        WindowGroup {
            GuderianCatalystRootView()
        }
    }
}

private enum CatalystOverlay: String, CaseIterable, Identifiable {
    case battles
    case command
    case inspector
    case forces
    case log

    var id: String { rawValue }

    var title: String {
        switch self {
        case .battles:
            return "Battles"
        case .command:
            return "Command"
        case .inspector:
            return "Inspector"
        case .forces:
            return "Forces"
        case .log:
            return "Log"
        }
    }

    var systemImage: String {
        switch self {
        case .battles:
            return "list.bullet"
        case .command:
            return "slider.horizontal.3"
        case .inspector:
            return "scope"
        case .forces:
            return "person.3"
        case .log:
            return "list.bullet.rectangle"
        }
    }
}

private enum CatalystNativeSession {
    case field(GuderianScenario, NativeBoardSession)
    case late(LateCareerGuderianPresentation, LateCareerNativeBoardSession)

    var title: String {
        switch self {
        case .field(let scenario, _):
            return scenario.title
        case .late(let entry, _):
            return entry.title
        }
    }

    var entryID: UnifiedGuderianBattleID {
        switch self {
        case .field(let scenario, _):
            return .fieldCommand(scenario.id)
        case .late(let entry, _):
            return .lateCareer(entry.id)
        }
    }

    var targetTurnUpperBound: Int {
        switch self {
        case .field(let scenario, _):
            return ScenarioBalanceCatalog.profile(for: scenario).targetTurns.upperBound
        case .late(let entry, _):
            return LateCareerPlayableSurfaceCatalog.report(for: entry.id)?.scoringProfile.targetTurnUpperBound ?? 8
        }
    }

    func snapshot() -> NativeBoardSnapshot {
        switch self {
        case .field(_, let session):
            return session.snapshot()
        case .late(_, let session):
            return session.snapshot()
        }
    }

    func selectUnit(_ id: Int) {
        switch self {
        case .field(_, let session):
            session.selectUnit(id)
        case .late(_, let session):
            session.selectUnit(id)
        }
    }

    func selectTarget(_ id: Int) {
        switch self {
        case .field(_, let session):
            session.selectTarget(id)
        case .late(_, let session):
            session.selectTarget(id)
        }
    }

    func selectFirstActiveUnit() {
        switch self {
        case .field(_, let session):
            session.selectFirstActiveUnit()
        case .late(_, let session):
            session.selectFirstActiveUnit()
        }
    }

    func selectNearestEnemyToSelectedUnit() {
        switch self {
        case .field(_, let session):
            session.selectNearestEnemyToSelectedUnit()
        case .late(_, let session):
            session.selectNearestEnemyToSelectedUnit()
        }
    }

    @discardableResult
    func moveSelectedUnitTowardNearestObjective(maxDistance: Double = 4) -> Bool {
        switch self {
        case .field(_, let session):
            return session.moveSelectedUnitTowardNearestObjective(maxDistance: maxDistance)
        case .late(_, let session):
            return session.moveSelectedUnitTowardNearestObjective(maxDistance: maxDistance)
        }
    }

    @discardableResult
    func moveSelectedUnitTowardPriorityObjective(named names: [String], maxDistance: Double = 6) -> Bool {
        switch self {
        case .field(_, let session):
            return session.moveSelectedUnitTowardPriorityObjective(named: names, maxDistance: maxDistance)
        case .late(_, let session):
            return session.moveSelectedUnitTowardPriorityObjective(named: names, maxDistance: maxDistance)
        }
    }

    @discardableResult
    func moveUnit(_ id: Int, to point: NativeBattleCoordinate) -> Bool {
        switch self {
        case .field(_, let session):
            return session.moveUnit(id, to: point)
        case .late(_, let session):
            return session.moveUnit(id, to: point)
        }
    }

    @discardableResult
    func rotateUnit(_ id: Int, to facingDegrees: Double) -> Bool {
        switch self {
        case .field(_, let session):
            return session.rotateUnit(id, to: facingDegrees)
        case .late(_, let session):
            return session.rotateUnit(id, to: facingDegrees)
        }
    }

    @discardableResult
    func toggleCover(for id: Int, enabled: Bool) -> Bool {
        switch self {
        case .field(_, let session):
            return session.toggleCover(for: id, enabled: enabled)
        case .late(_, let session):
            return session.toggleCover(for: id, enabled: enabled)
        }
    }

    @discardableResult
    func toggleHullDown(for id: Int, enabled: Bool) -> Bool {
        switch self {
        case .field(_, let session):
            return session.toggleHullDown(for: id, enabled: enabled)
        case .late(_, let session):
            return session.toggleHullDown(for: id, enabled: enabled)
        }
    }

    @discardableResult
    func shootSelectedTarget() -> Bool {
        switch self {
        case .field(_, let session):
            return session.shootSelectedTarget()
        case .late(_, let session):
            return session.shootSelectedTarget()
        }
    }

    @discardableResult
    func shootUnit(_ attackerID: Int, targetID: Int) -> Bool {
        switch self {
        case .field(_, let session):
            return session.shootUnit(attackerID, targetID: targetID)
        case .late(_, let session):
            return session.shootUnit(attackerID, targetID: targetID)
        }
    }

    @discardableResult
    func assaultUnit(_ attackerID: Int, targetID: Int, advance: Bool) -> Bool {
        switch self {
        case .field(_, let session):
            return session.assaultUnit(attackerID, targetID: targetID, advance: advance)
        case .late(_, let session):
            return session.assaultUnit(attackerID, targetID: targetID, advance: advance)
        }
    }

    @discardableResult
    func resolveFirstPendingChoice() -> Bool {
        switch self {
        case .field(_, let session):
            return session.resolveFirstPendingChoice()
        case .late(_, let session):
            return session.resolveFirstPendingChoice()
        }
    }

    func advancePhase() {
        switch self {
        case .field(_, let session):
            session.advancePhase()
        case .late(_, let session):
            session.advancePhase()
        }
    }

    @discardableResult
    func prepareNextOrderDiceActivation() -> Bool {
        switch self {
        case .field(_, let session):
            return session.prepareNextOrderDiceActivation(preferredOwner: nil)
        case .late(_, let session):
            return session.prepareNextOrderDiceActivation()
        }
    }

    @discardableResult
    func issueOrder(_ order: HistoricalBoardOrder, to unitID: Int) -> Bool {
        switch self {
        case .field(_, let session):
            return session.issueOrder(order, to: unitID)
        case .late(_, let session):
            return session.issueOrder(order, to: unitID)
        }
    }

    func sideTitle(for player: NativeBoardPlayer) -> String {
        switch self {
        case .field(let scenario, _):
            return GuderianHistoricalSideSelectionResolver.sideTitle(for: player, in: scenario)
        case .late(let entry, _):
            return UnifiedGuderianBattleSideSelectionCatalog.sideTitle(for: player, in: entry)
        }
    }

    func targetPriorities(for player: NativeBoardPlayer, phase: NativeBoardPhase) -> [String] {
        switch self {
        case .field(let scenario, _):
            if player == .guderianAI {
                return ScenarioContentCatalog.bundle(for: scenario).aiPlan.targetPriorities(for: phase)
            }
            return OpposingForceAIPlanCatalog.plan(for: scenario).targetPriorities(for: phase)
        case .late(let entry, _):
            if player == .guderianAI {
                return LateCareerPlayableSurfaceCatalog.aiPlan(for: entry.id)?.priorityNames(for: phase) ?? []
            }
            return UnifiedGuderianBattleSideSelectionCatalog.objectivePriorityNames(for: player, in: entry)
        }
    }

    func guderianAIDecisionState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceAIDecisionState? {
        GuderianOrderDiceGuderianAIActivationPlanner.decision(
            snapshot: snapshot,
            battleID: entryID,
            priorityNames: targetPriorities(for: .guderianAI, phase: snapshot.phase)
        )
    }

    func opposingAIDecisionState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceOpposingAIDecisionState? {
        switch self {
        case .field(let scenario, _):
            return GuderianOrderDiceOpposingAIActivationPlanner.decision(
                snapshot: snapshot,
                battleID: entryID,
                plan: OpposingForceAIPlanCatalog.plan(for: scenario)
            )
        case .late(let entry, _):
            return GuderianOrderDiceOpposingAIActivationPlanner.decision(
                snapshot: snapshot,
                battleID: entryID,
                armyFamily: .lateWarSovietAllied,
                behaviorProfile: .mobileDelay,
                priorityNames: targetPriorities(for: .player, phase: snapshot.phase),
                strategicGoal: entry.visibleCommandCaveatLabel
            )
        }
    }

    func completeBattle() throws -> CatalystCompletion {
        switch self {
        case .field(_, let session):
            let summary = try PlayableBattleCompletionResolver.completeBattle(from: session)
            return CatalystCompletion(
                sourceName: summary.sourceName,
                victoryBand: summary.completionRecord.victoryBand.rawValue,
                score: summary.completionRecord.score,
                completedTurn: summary.completionRecord.completedTurn,
                detail: summary.debriefSummary
            )
        case .late(_, let session):
            guard let summary = UnifiedLateCareerCompletionResolver.completeBattle(from: session) else {
                throw CatalystBattleError.completionUnavailable
            }
            return CatalystCompletion(
                sourceName: summary.sourceName,
                victoryBand: summary.completionRecord.victoryBand.rawValue,
                score: summary.completionRecord.score,
                completedTurn: summary.completionRecord.completedTurn,
                detail: summary.debriefSummary
            )
        }
    }
}

private enum CatalystBattleError: Error, LocalizedError {
    case launchUnavailable
    case completionUnavailable

    var errorDescription: String? {
        switch self {
        case .launchUnavailable:
            return "Battle launch unavailable."
        case .completionUnavailable:
            return "Battle completion unavailable."
        }
    }
}

private struct CatalystCompletion: Equatable {
    let sourceName: String
    let victoryBand: String
    let score: Int
    let completedTurn: Int
    let detail: String
}

private struct CatalystBattleResult: Codable, Equatable {
    let entryKey: String
    let title: String
    let statusTitle: String
    let winner: NativeBoardPlayer?
    let winnerTitle: String
    let loser: NativeBoardPlayer?
    let loserTitle: String
    let scoreLine: String
    let completedTurn: Int
    let victoryBand: String?

    var hasWinner: Bool {
        winner != nil
    }

    var wallSummary: String {
        hasWinner ? "Most recent winner: \(winnerTitle)" : "Most recent result: no winner"
    }

    var wallDetail: String {
        if hasWinner {
            return "Loser: \(loserTitle) | \(scoreLine) | turn \(completedTurn)"
        }
        return "\(scoreLine) | turn \(completedTurn)"
    }
}

@MainActor
private final class GuderianCatalystBattleViewModel: ObservableObject {
    private static let latestResultsStorageKey = "guderian.catalyst.latestBattleResults.v1"

    @Published private(set) var entries: [UnifiedGuderianBattleEntry]
    @Published private(set) var selectedEntry: UnifiedGuderianBattleEntry?
    @Published private(set) var snapshot: NativeBoardSnapshot?
    @Published private(set) var completion: CatalystCompletion?
    @Published private(set) var errorMessage: String?
    @Published private(set) var latestResults: [String: CatalystBattleResult]

    private var session: CatalystNativeSession?
    private var restartCount = 0

    init() {
        entries = UnifiedGuderianBattleCatalog.allEntries.sorted { $0.order < $1.order }
        selectedEntry = nil
        snapshot = nil
        completion = nil
        errorMessage = nil
        latestResults = Self.loadLatestResults()
        if let first = entries.first {
            launch(first)
        }
    }

    var battleTitle: String {
        selectedEntry?.title ?? session?.title ?? "Guderian"
    }

    var humanPlayer: NativeBoardPlayer { .player }

    var aiPlayer: NativeBoardPlayer { .guderianAI }

    var isBattleOver: Bool {
        snapshot?.mission.winner != NativeBoardPlayer.none
    }

    var canIssueHumanOrders: Bool {
        guard let snapshot else {
            return false
        }
        return !isBattleOver && snapshot.orderDice.current?.owner == humanPlayer
    }

    var canResolveHumanActivation: Bool {
        guard let selectedUnit = snapshot?.selectedUnit, selectedUnit.owner == humanPlayer else {
            return canIssueHumanOrders
        }
        return canIssueHumanOrders ||
            (!isBattleOver && selectedUnit.currentOrder != nil && (selectedUnit.canMoveNow || selectedUnit.canShootNow || selectedUnit.canAssaultNow))
    }

    var canDrawOrderDie: Bool {
        guard let snapshot else {
            return false
        }
        return !isBattleOver && snapshot.orderDice.current == nil
    }

    var canRunAITurn: Bool {
        guard let snapshot else {
            return false
        }
        return !isBattleOver && snapshot.orderDice.current?.owner == aiPlayer
    }

    var completionLine: String? {
        guard let completion else {
            return nil
        }
        return "\(completion.victoryBand) | \(completion.score) VP | turn \(completion.completedTurn)"
    }

    var currentResult: CatalystBattleResult? {
        guard let entry = selectedEntry,
              let snapshot,
              completion != nil || snapshot.mission.winner != .none else {
            return nil
        }
        return makeBattleResult(for: entry, snapshot: snapshot, completion: completion)
    }

    func latestResult(for entry: UnifiedGuderianBattleEntry) -> CatalystBattleResult? {
        latestResults[Self.resultKey(for: entry.id)]
    }

    func launch(_ entry: UnifiedGuderianBattleEntry) {
        selectedEntry = entry
        completion = nil
        errorMessage = nil
        restartCount = 0
        makeSession(for: entry)
        refresh()
    }

    func restartBattle() {
        guard let entry = selectedEntry else {
            return
        }
        restartCount += 1
        completion = nil
        errorMessage = nil
        makeSession(for: entry)
        refresh()
    }

    func select(_ unit: NativeBoardUnitSnapshot) {
        guard let session, !isBattleOver else {
            return
        }
        if unit.owner == humanPlayer {
            session.selectUnit(unit.id)
            if canIssueHumanOrders || unit.currentOrder != nil {
                session.selectNearestEnemyToSelectedUnit()
            }
        } else {
            session.selectTarget(unit.id)
        }
        refresh()
    }

    func cycleReadyUnit(forward: Bool) {
        guard let snapshot, let session, canIssueHumanOrders else {
            return
        }
        let candidates = snapshot.units
            .filter {
                $0.owner == humanPlayer &&
                    !$0.destroyed &&
                    !$0.retainedOrder &&
                    $0.currentOrder == nil &&
                    !$0.availableOrders.isEmpty
            }
            .sorted { $0.id < $1.id }
        guard !candidates.isEmpty else {
            return
        }

        guard let selectedID = snapshot.selectedUnit?.id,
              let index = candidates.firstIndex(where: { $0.id == selectedID }) else {
            session.selectUnit(candidates[0].id)
            session.selectNearestEnemyToSelectedUnit()
            refresh()
            return
        }

        let offset = forward ? 1 : -1
        let nextIndex = (index + offset + candidates.count) % candidates.count
        session.selectUnit(candidates[nextIndex].id)
        session.selectNearestEnemyToSelectedUnit()
        refresh()
    }

    func selectNearestEnemy() {
        session?.selectNearestEnemyToSelectedUnit()
        refresh()
    }

    func moveSelectedTowardObjective() {
        guard canResolveHumanActivation else {
            errorMessage = "Draw a die and assign an order before moving."
            return
        }
        let priorities = snapshot.flatMap { snapshot in
            session?.targetPriorities(for: snapshot.selectedUnit?.owner ?? humanPlayer, phase: snapshot.phase)
        } ?? []
        if !priorities.isEmpty {
            _ = session?.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: 6)
        } else {
            _ = session?.moveSelectedUnitTowardNearestObjective(maxDistance: 5)
        }
        refresh()
    }

    func move(_ unit: NativeBoardUnitSnapshot, to boardPoint: NativeBattleCoordinate) {
        guard canResolveHumanActivation, unit.owner == humanPlayer else {
            return
        }
        _ = session?.moveUnit(unit.id, to: boardPoint)
        refresh()
    }

    func rotateSelected(by degrees: Double) {
        guard canResolveHumanActivation, let selected = snapshot?.selectedUnit, selected.owner == humanPlayer else {
            return
        }
        _ = session?.rotateUnit(selected.id, to: selected.facingDegrees + degrees)
        refresh()
    }

    func toggleCover(_ enabled: Bool) {
        guard canResolveHumanActivation, let selected = snapshot?.selectedUnit, selected.owner == humanPlayer else {
            return
        }
        _ = session?.toggleCover(for: selected.id, enabled: enabled)
        refresh()
    }

    func toggleHullDown(_ enabled: Bool) {
        guard canResolveHumanActivation, let selected = snapshot?.selectedUnit, selected.owner == humanPlayer else {
            return
        }
        _ = session?.toggleHullDown(for: selected.id, enabled: enabled)
        refresh()
    }

    func shootSelectedTarget() {
        guard canResolveHumanActivation else {
            errorMessage = "Assign an order before firing."
            return
        }
        _ = session?.shootSelectedTarget()
        refresh()
    }

    func assaultSelected(advance: Bool) {
        guard canResolveHumanActivation,
              let selected = snapshot?.selectedUnit,
              let target = snapshot?.selectedTarget else {
            return
        }
        _ = session?.assaultUnit(selected.id, targetID: target.id, advance: advance)
        refresh()
    }

    func resolvePendingChoice() {
        guard canResolveHumanActivation else {
            errorMessage = "Draw a die and assign an order before resolving."
            return
        }
        _ = session?.resolveFirstPendingChoice()
        refresh()
    }

    func issueOrder(_ order: HistoricalBoardOrder) {
        guard canIssueHumanOrders,
              let selectedUnit = snapshot?.selectedUnit,
              selectedUnit.owner == humanPlayer else {
            errorMessage = "Draw a \(sideTitle(for: humanPlayer)) die and select one of your units before issuing an order."
            return
        }
        let issued = session?.issueOrder(order, to: selectedUnit.id) ?? false
        errorMessage = issued ? nil : session?.snapshot().lastAction.detail
        refresh()
    }

    func advancePhase() {
        if snapshot?.orderDice.rulesetActive == true {
            drawOrderDie()
            return
        }
        session?.advancePhase()
        refresh()
    }

    func drawOrderDie() {
        guard canDrawOrderDie else {
            errorMessage = "Assign the current order die before reaching into the bag again."
            return
        }
        guard session?.prepareNextOrderDiceActivation() == true else {
            errorMessage = session?.snapshot().lastAction.detail ?? "Order die draw blocked."
            refresh()
            return
        }
        errorMessage = nil
        refresh()
    }

    func runAutomatedActiveStep() {
        guard let session, var snapshot, !isBattleOver else {
            return
        }

        if snapshot.orderDice.rulesetActive {
            if snapshot.orderDice.current == nil {
                guard session.prepareNextOrderDiceActivation() else {
                    errorMessage = session.snapshot().lastAction.detail
                    refresh()
                    return
                }
                refresh()
                guard let refreshed = self.snapshot else {
                    return
                }
                snapshot = refreshed
            }

            let actionSucceeded = runOrderDiceAutomatedActivation(snapshot: snapshot, session: session)
            errorMessage = actionSucceeded ? nil : session.snapshot().lastAction.detail
            refresh()
            return
        }

        session.selectFirstActiveUnit()
        session.selectNearestEnemyToSelectedUnit()
        let priorities = session.targetPriorities(for: snapshot.activePlayer, phase: snapshot.phase)
        switch snapshot.phase {
        case .movement:
            if priorities.isEmpty {
                _ = session.moveSelectedUnitTowardNearestObjective(maxDistance: 5)
            } else {
                _ = session.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: snapshot.activePlayer == .guderianAI ? 6 : 5)
            }
        case .shooting:
            _ = session.shootSelectedTarget()
        case .assault:
            if !(session.resolveFirstPendingChoice()) {
                if let current = session.snapshot().selectedUnit,
                   let target = session.snapshot().selectedTarget {
                    _ = session.assaultUnit(current.id, targetID: target.id, advance: true)
                }
            }
        }
        session.advancePhase()
        refresh()
    }

    func runAITurn() {
        guard !isBattleOver, let snapshot else {
            return
        }

        if snapshot.orderDice.rulesetActive {
            var safety = 0
            while isBattleOver == false && safety < 16 {
                if self.snapshot?.orderDice.current == nil {
                    drawOrderDie()
                }
                guard self.snapshot?.orderDice.current?.owner == aiPlayer else {
                    return
                }
                runAutomatedActiveStep()
                safety += 1
            }
            return
        }

        var safety = 0
        while self.snapshot?.activePlayer != aiPlayer && isBattleOver == false && safety < 4 {
            advancePhase()
            safety += 1
        }

        while self.snapshot?.activePlayer == aiPlayer && isBattleOver == false && safety < 16 {
            runAutomatedActiveStep()
            safety += 1
        }
    }

    private func runOrderDiceAutomatedActivation(
        snapshot: NativeBoardSnapshot,
        session: CatalystNativeSession
    ) -> Bool {
        let owner = snapshot.orderDice.current?.owner ?? snapshot.activePlayer
        if owner == .guderianAI,
           let decision = session.guderianAIDecisionState(for: snapshot) {
            return runGuderianOrderDiceActivation(decision: decision, snapshot: snapshot, session: session)
        }
        if owner == .player,
           let decision = session.opposingAIDecisionState(for: snapshot) {
            return runOpposingOrderDiceActivation(decision: decision, snapshot: snapshot, session: session)
        }
        return runFallbackOrderDiceActivation(owner: owner, snapshot: snapshot, session: session)
    }

    private func runGuderianOrderDiceActivation(
        decision: GuderianOrderDiceAIDecisionState,
        snapshot: NativeBoardSnapshot,
        session: CatalystNativeSession
    ) -> Bool {
        session.selectUnit(decision.chosenUnitID)
        session.selectNearestEnemyToSelectedUnit()
        let orderIssued = session.issueOrder(decision.chosenOrder, to: decision.chosenUnitID)
        let priorities = session.targetPriorities(for: .guderianAI, phase: snapshot.phase)
        let actionSucceeded = resolveAutomatedOrder(
            decision.chosenOrder,
            priorities: priorities,
            moveDistance: 6,
            runDistance: 9,
            session: session
        )
        return orderIssued || actionSucceeded
    }

    private func runOpposingOrderDiceActivation(
        decision: GuderianOrderDiceOpposingAIDecisionState,
        snapshot: NativeBoardSnapshot,
        session: CatalystNativeSession
    ) -> Bool {
        session.selectUnit(decision.chosenUnitID)
        session.selectNearestEnemyToSelectedUnit()
        let orderIssued = session.issueOrder(decision.chosenOrder, to: decision.chosenUnitID)
        let priorities = session.targetPriorities(for: .player, phase: snapshot.phase)
        let actionSucceeded = resolveAutomatedOrder(
            decision.chosenOrder,
            priorities: priorities,
            moveDistance: 5,
            runDistance: 8,
            session: session
        )
        return orderIssued || actionSucceeded
    }

    private func runFallbackOrderDiceActivation(
        owner: NativeBoardPlayer,
        snapshot: NativeBoardSnapshot,
        session: CatalystNativeSession
    ) -> Bool {
        guard let unit = snapshot.units
            .filter({
                $0.owner == owner &&
                    !$0.destroyed &&
                    !$0.retainedOrder &&
                    $0.currentOrder == nil &&
                    !$0.availableOrders.isEmpty
            })
            .sorted(by: { $0.id < $1.id })
            .first else {
            return false
        }
        let order = Self.fallbackOrder(for: unit)
        session.selectUnit(unit.id)
        session.selectNearestEnemyToSelectedUnit()
        let orderIssued = session.issueOrder(order, to: unit.id)
        let priorities = session.targetPriorities(for: owner, phase: snapshot.phase)
        let actionSucceeded = resolveAutomatedOrder(
            order,
            priorities: priorities,
            moveDistance: owner == .guderianAI ? 6 : 5,
            runDistance: owner == .guderianAI ? 9 : 8,
            session: session
        )
        return orderIssued || actionSucceeded
    }

    private func resolveAutomatedOrder(
        _ order: HistoricalBoardOrder,
        priorities: [String],
        moveDistance: Double,
        runDistance: Double,
        session: CatalystNativeSession
    ) -> Bool {
        switch order {
        case .advance:
            return session.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: moveDistance) ||
                session.moveSelectedUnitTowardNearestObjective(maxDistance: moveDistance)
        case .run:
            return session.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: runDistance) ||
                session.moveSelectedUnitTowardNearestObjective(maxDistance: runDistance)
        case .fire:
            session.selectNearestEnemyToSelectedUnit()
            return session.shootSelectedTarget()
        case .ambush, .rally, .down:
            return false
        }
    }

    private static func fallbackOrder(for unit: NativeBoardUnitSnapshot) -> HistoricalBoardOrder {
        if unit.availableOrders.contains(.fire) {
            return .fire
        }
        if unit.availableOrders.contains(.advance) {
            return .advance
        }
        if unit.availableOrders.contains(.run) {
            return .run
        }
        return unit.availableOrders.first ?? .down
    }

    func playToEnd() {
        guard let session else {
            return
        }
        let maxPhases = max(24, session.targetTurnUpperBound * 8)
        var phaseCount = 0
        while let snapshot,
              snapshot.turnNumber <= session.targetTurnUpperBound,
              snapshot.mission.winner == .none,
              phaseCount < maxPhases {
            runAutomatedActiveStep()
            phaseCount += 1
        }
        completeBattle()
    }

    func completeBattle() {
        guard let session else {
            errorMessage = CatalystBattleError.completionUnavailable.localizedDescription
            return
        }
        do {
            completion = try session.completeBattle()
            errorMessage = nil
        } catch {
            completion = nil
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    func sideTitle(for player: NativeBoardPlayer) -> String {
        session?.sideTitle(for: player) ?? player.rawValue
    }

    private func makeSession(for entry: UnifiedGuderianBattleEntry) {
        let seed = UInt32(920_000 + entry.order + restartCount * 97)
        if let id = entry.id.fieldCommandID,
           let scenario = GuderianCampaignCatalog.scenario(id: id),
           let launch = try? GuderianHistoricalSideSelectionResolver.makeLaunch(
            for: scenario,
            chosenHumanSideID: GuderianHistoricalSideSelectionResolver.defaultHumanSideID,
            seed: seed
           ),
           let nativeSession = NativeBoardSession(scenario: scenario, seed: seed, launch: launch) {
            _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: nativeSession)
            session = .field(scenario, nativeSession)
            return
        }

        if let id = entry.id.lateCareerID,
           let presentation = LateCareerGuderianPresentationCatalog.entry(for: id),
           let nativeSession = LateCareerNativeBoardSession(battlefieldID: id, seed: seed) {
            _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: nativeSession)
            session = .late(presentation, nativeSession)
            return
        }

        session = nil
        errorMessage = CatalystBattleError.launchUnavailable.localizedDescription
    }

    private func refresh() {
        snapshot = session?.snapshot()
        recordCurrentResultIfAvailable()
    }

    private func recordCurrentResultIfAvailable() {
        guard let entry = selectedEntry,
              let snapshot,
              completion != nil || snapshot.mission.winner != .none else {
            return
        }

        let result = makeBattleResult(for: entry, snapshot: snapshot, completion: completion)
        if latestResults[result.entryKey] == result {
            return
        }

        var updated = latestResults
        updated[result.entryKey] = result
        latestResults = updated
        persistLatestResults()
    }

    private func makeBattleResult(
        for entry: UnifiedGuderianBattleEntry,
        snapshot: NativeBoardSnapshot,
        completion: CatalystCompletion?
    ) -> CatalystBattleResult {
        let engineWinner = snapshot.mission.winner == .none ? nil : snapshot.mission.winner
        let scoreWinner: NativeBoardPlayer?
        if snapshot.mission.playerScore > snapshot.mission.opponentScore {
            scoreWinner = .player
        } else if snapshot.mission.opponentScore > snapshot.mission.playerScore {
            scoreWinner = .guderianAI
        } else {
            scoreWinner = nil
        }

        let winner = engineWinner ?? (completion == nil ? nil : scoreWinner)
        let loser = winner.flatMap(Self.loser(for:))
        let statusTitle: String
        if engineWinner != nil {
            statusTitle = "Final result"
        } else if winner != nil {
            statusTitle = "Score decision"
        } else {
            statusTitle = "No winner recorded"
        }

        return CatalystBattleResult(
            entryKey: Self.resultKey(for: entry.id),
            title: entry.title,
            statusTitle: statusTitle,
            winner: winner,
            winnerTitle: winner.map(sideTitle(for:)) ?? "Not recorded",
            loser: loser,
            loserTitle: loser.map(sideTitle(for:)) ?? "Not recorded",
            scoreLine: "\(sideTitle(for: .player)) \(snapshot.mission.playerScore) - \(snapshot.mission.opponentScore) \(sideTitle(for: .guderianAI))",
            completedTurn: completion?.completedTurn ?? snapshot.turnNumber,
            victoryBand: completion?.victoryBand
        )
    }

    private static func loser(for winner: NativeBoardPlayer) -> NativeBoardPlayer? {
        switch winner {
        case .player:
            return .guderianAI
        case .guderianAI:
            return .player
        case .none:
            return nil
        }
    }

    private static func resultKey(for id: UnifiedGuderianBattleID) -> String {
        "\(id.kind.rawValue):\(id.rawValue)"
    }

    private static func loadLatestResults() -> [String: CatalystBattleResult] {
        guard let data = UserDefaults.standard.data(forKey: latestResultsStorageKey),
              let decoded = try? JSONDecoder().decode([String: CatalystBattleResult].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func persistLatestResults() {
        guard let data = try? JSONEncoder().encode(latestResults) else {
            return
        }
        UserDefaults.standard.set(data, forKey: Self.latestResultsStorageKey)
    }
}

private struct GuderianCatalystRootView: View {
    @StateObject private var model = GuderianCatalystBattleViewModel()
    @State private var overlay: CatalystOverlay?
    @State private var zoom: CGFloat = 1
    @State private var assaultAdvance = true

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let snapshot = model.snapshot {
                    CatalystBattleMapView(
                        snapshot: snapshot,
                        zoom: zoom,
                        contentInsets: mapContentInsets(in: proxy.size),
                        humanPlayer: model.humanPlayer,
                        canIssueHumanOrders: model.canIssueHumanOrders,
                        sideTitle: model.sideTitle(for:),
                        onSelect: model.select(_:),
                        onMove: model.move(_:to:)
                    )
                    .ignoresSafeArea()

                    topHUD(snapshot, in: proxy.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .zIndex(10)

                    diceBagHUD(snapshot, in: proxy.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .zIndex(11)

                    if overlay == nil {
                        bottomDock(in: proxy.size)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }

                    if let overlay {
                        overlayPanel(overlay, in: proxy.size)
                            .transition(.move(edge: overlay == .battles ? .leading : .trailing).combined(with: .opacity))
                            .zIndex(20)
                    }
                } else {
                    CatalystUnavailableView(message: model.errorMessage ?? "Battle board unavailable")
                }
            }
            .background(CatalystPalette.background)
            .animation(.snappy(duration: 0.22), value: overlay?.id)
        }
    }

    private func mapContentInsets(in size: CGSize) -> EdgeInsets {
        let top = min(150, max(112, size.height * 0.09))
        let bottom = min(120, max(82, size.height * 0.06))
        return EdgeInsets(top: top, leading: 0, bottom: bottom, trailing: 0)
    }

    private func topHUD(_ snapshot: NativeBoardSnapshot, in size: CGSize) -> some View {
        let maxWidth = min(760, max(260, size.width - 24))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.battleTitle)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("\(snapshot.mission.name) | Turn \(snapshot.turnNumber) | \(model.sideTitle(for: snapshot.activePlayer)) | \(snapshot.phase.rawValue)")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text("\(model.sideTitle(for: .player)) \(snapshot.mission.playerScore) - \(snapshot.mission.opponentScore) \(model.sideTitle(for: .guderianAI))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.82))
                    HStack(spacing: 6) {
                        sideStatusPill(
                            title: "You control",
                            value: model.sideTitle(for: model.humanPlayer),
                            color: CatalystBattleMapView.unitColor(model.humanPlayer),
                            systemImage: "shield.fill"
                        )
                        sideStatusPill(
                            title: snapshot.activePlayer == model.humanPlayer ? "Your move" : "Active",
                            value: model.sideTitle(for: snapshot.activePlayer),
                            color: CatalystBattleMapView.unitColor(snapshot.activePlayer),
                            systemImage: snapshot.activePlayer == model.humanPlayer ? "arrow.up.right.circle.fill" : "clock.fill"
                        )
                    }
                }

                Spacer(minLength: 10)

                if let result = model.currentResult {
                    Label(result.statusTitle, systemImage: result.hasWinner ? "flag.checkered" : "questionmark.diamond")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(result.hasWinner ? .green : .orange)
                        .lineLimit(1)
                }
            }

            if let result = model.currentResult {
                resultStrip(result)
            } else if snapshot.mission.winner != .none {
                Label("\(model.sideTitle(for: snapshot.mission.winner)) has reached the scenario result.", systemImage: "flag.checkered")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: maxWidth, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
        .padding(12)
        .accessibilityIdentifier("catalyst-battle-hud")
    }

    private func diceBagHUD(_ snapshot: NativeBoardSnapshot, in size: CGSize) -> some View {
        let currentOwner = snapshot.orderDice.current?.owner
        let currentTitle = currentOwner.map(model.sideTitle(for:)) ?? "No die drawn"
        let activationUnits = activationUnits(for: currentOwner, in: snapshot)
        let movementUnits = activationUnits.filter { unit in
            unit.availableOrders.contains(.advance) ||
                unit.availableOrders.contains(.run) ||
                unit.advanceMoveAllowance > 0 ||
                unit.runMoveAllowance > 0
        }
        let reactionUnits = reactionUnits(against: currentOwner, in: snapshot)
        let width = min(460, max(280, size.width - 24))

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Label("Dice Bag", systemImage: "die.face.5.fill")
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(Color(red: 0.07, green: 0.07, blue: 0.06))
                Text("Current: \(currentTitle)")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color(red: 0.07, green: 0.07, blue: 0.06))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button {
                    model.drawOrderDie()
                } label: {
                    Label(currentOwner == nil ? "Reach Into Bag" : "Die Active", systemImage: "hand.draw.fill")
                        .lineLimit(1)
                }
                .buttonStyle(.borderedProminent)
                .tint(CatalystPalette.commandBlue)
                .disabled(!model.canDrawOrderDie)
                .accessibilityIdentifier("catalyst-opening-order-dice-bag-draw-button")
            }

            Text("Can order: \(Self.unitList(activationUnits.map(\.name), empty: "reach into the bag first"))")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color(red: 0.07, green: 0.07, blue: 0.06))
                .lineLimit(1)
                .accessibilityIdentifier("catalyst-opening-order-dice-activation-units")
            Text("Move: \(Self.unitList(movementUnits.map(\.name), empty: "none yet")) | React: \(Self.unitList(reactionUnits.map(Self.reactionLabel(for:)), empty: "none retained"))")
                .font(.caption2.monospaced())
                .foregroundStyle(Color(red: 0.18, green: 0.18, blue: 0.16))
                .lineLimit(1)
                .accessibilityIdentifier("catalyst-opening-order-dice-move-reaction-units")
        }
        .padding(12)
        .frame(width: width, alignment: .leading)
        .background(Color.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 16, x: 0, y: 8)
        .padding(12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("catalyst-opening-order-dice-bag-panel")
    }

    private func sideStatusPill(title: String, value: String, color: Color, systemImage: String) -> some View {
        Label {
            Text("\(title): \(value)")
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.86), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Color.white.opacity(0.36), lineWidth: 1)
        }
    }

    private func resultStrip(_ result: CatalystBattleResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .overlay(Color.white.opacity(0.20))
            HStack(alignment: .top, spacing: 12) {
                resultColumn(
                    title: "Winner",
                    value: result.winnerTitle,
                    systemImage: result.hasWinner ? "flag.checkered" : "questionmark.diamond",
                    color: result.hasWinner ? .green : .orange
                )
                resultColumn(
                    title: "Loser",
                    value: result.loserTitle,
                    systemImage: "xmark.circle",
                    color: result.hasWinner ? .white.opacity(0.88) : .secondary
                )
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(result.victoryBand ?? result.statusTitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(result.scoreLine) | turn \(result.completedTurn)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private func resultColumn(title: String, value: String, systemImage: String, color: Color) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.66))
                Text(value)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(color)
        }
    }

    private func activationUnits(
        for owner: NativeBoardPlayer?,
        in snapshot: NativeBoardSnapshot
    ) -> [NativeBoardUnitSnapshot] {
        guard let owner else {
            return []
        }
        return snapshot.units
            .filter { unit in
                unit.owner == owner &&
                    !unit.destroyed &&
                    !unit.retainedOrder &&
                    unit.currentOrder == nil &&
                    !unit.availableOrders.isEmpty
            }
            .sorted { $0.id < $1.id }
    }

    private func reactionUnits(
        against owner: NativeBoardPlayer?,
        in snapshot: NativeBoardSnapshot
    ) -> [NativeBoardUnitSnapshot] {
        guard let owner else {
            return []
        }
        return snapshot.units
            .filter { unit in
                unit.owner != owner &&
                    unit.owner != .none &&
                    !unit.destroyed &&
                    (unit.downOrderActive || unit.ambushOrderActive)
            }
            .sorted { lhs, rhs in
                if lhs.ambushOrderActive != rhs.ambushOrderActive {
                    return lhs.ambushOrderActive && !rhs.ambushOrderActive
                }
                return lhs.id < rhs.id
            }
    }

    private static func reactionLabel(for unit: NativeBoardUnitSnapshot) -> String {
        if unit.ambushOrderActive {
            return "\(unit.name) Ambush"
        }
        if unit.downOrderActive {
            return "\(unit.name) Down"
        }
        return unit.name
    }

    private static func unitList(_ names: [String], empty: String) -> String {
        let visible = names.prefix(4)
        guard !visible.isEmpty else {
            return empty
        }
        let suffix = names.count > visible.count ? " +\(names.count - visible.count)" : ""
        return visible.joined(separator: ", ") + suffix
    }

    private func bottomDock(in size: CGSize) -> some View {
        let availableWidth = max(260, size.width - 24)
        let compact = availableWidth < 620
        return HStack(spacing: 8) {
            overlayButton(.battles)
            overlayButton(.command)
            overlayButton(.inspector)
            overlayButton(.forces)
            overlayButton(.log)

            Divider()
                .frame(height: 26)
                .overlay(Color.white.opacity(0.36))

            dockIconButton(systemImage: "minus.magnifyingglass", help: "Zoom out") {
                zoom = max(0.65, zoom - 0.15)
            }

            if !compact {
                Slider(value: $zoom, in: 0.65...2.1)
                    .tint(CatalystPalette.gold)
                    .frame(width: 126)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(CatalystPalette.dockButtonBackground, in: Capsule())
                    .accessibilityIdentifier("catalyst-zoom-slider")
            }

            dockIconButton(systemImage: "plus.magnifyingglass", help: "Zoom in") {
                zoom = min(2.1, zoom + 0.15)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(CatalystPalette.dockForeground)
        .padding(10)
        .frame(maxWidth: min(availableWidth, compact ? 430 : 640))
        .background(CatalystPalette.dockBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 18, x: 0, y: 8)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .accessibilityIdentifier("catalyst-command-dock")
    }

    private func overlayButton(_ panel: CatalystOverlay) -> some View {
        let active = overlay == panel
        return Button {
            overlay = active ? nil : panel
        } label: {
            Image(systemName: panel.systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(active ? Color.white : CatalystPalette.dockForeground)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(active ? CatalystPalette.commandRed : CatalystPalette.dockButtonBackground)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(active ? CatalystPalette.commandRed.opacity(0.95) : Color.white.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .help(panel.title)
        .accessibilityLabel(panel.title)
    }

    private func dockIconButton(systemImage: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 44, height: 44)
                .background(CatalystPalette.dockButtonBackground, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }

    private func overlayPanel(_ panel: CatalystOverlay, in size: CGSize) -> some View {
        let width = min(panel == .battles ? 390 : 360, max(260, size.width - 28))
        let maxHeight = min(560, max(280, size.height - 132))
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(panel.title, systemImage: panel.systemImage)
                    .font(.headline)
                Spacer()
                Button {
                    overlay = nil
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }

            Divider()

            ScrollView {
                switch panel {
                case .battles:
                    battleListPanel
                case .command:
                    commandPanel
                case .inspector:
                    inspectorPanel
                case .forces:
                    forcesPanel
                case .log:
                    logPanel
                }
            }
        }
        .padding(12)
        .frame(width: width, alignment: .topLeading)
        .frame(maxHeight: maxHeight, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
        .padding(12)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: panel == .battles ? .topLeading : .topTrailing
        )
        .accessibilityIdentifier("catalyst-\(panel.rawValue)-panel")
    }

    private var battleListPanel: some View {
        LazyVStack(alignment: .leading, spacing: 6) {
            ForEach(model.entries) { entry in
                Button {
                    model.launch(entry)
                    overlay = .command
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(entry.order)")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .frame(width: 30, alignment: .trailing)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text("\(entry.dateLabel) | \(entry.id.kind.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let result = model.latestResult(for: entry) {
                                Label(result.wallSummary, systemImage: result.hasWinner ? "flag.checkered" : "questionmark.diamond")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(result.hasWinner ? .green : .orange)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                Text(result.wallDetail)
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        if model.selectedEntry?.id == entry.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(CatalystPalette.gold)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(model.selectedEntry?.id == entry.id ? CatalystPalette.gold.opacity(0.20) : Color.white.opacity(0.04))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var commandPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let snapshot = model.snapshot {
                if snapshot.orderDice.rulesetActive {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Label("Dice Bag", systemImage: "die.face.5.fill")
                                .font(.subheadline.weight(.black))
                            Spacer(minLength: 8)
                            commandButton("Draw", "hand.draw.fill") {
                                model.drawOrderDie()
                            }
                            .disabled(!model.canDrawOrderDie)
                            .accessibilityIdentifier("catalyst-command-draw-die-button")
                        }
                        Text("Current die: \(snapshot.orderDice.current.map { model.sideTitle(for: $0.owner) } ?? "Reach into the bag")")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Select a listed unit, assign one order, then resolve that order on the map.")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)

                        if let selected = snapshot.selectedUnit, selected.owner == model.humanPlayer {
                            let orderOptions = selected.availableOrders.isEmpty ? HistoricalBoardOrder.allCases : selected.availableOrders
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 94), spacing: 8)], spacing: 8) {
                                ForEach(orderOptions, id: \.self) { order in
                                    commandButton(order.rawValue, Self.orderIcon(for: order)) {
                                        model.issueOrder(order)
                                    }
                                    .disabled(!model.canIssueHumanOrders || selected.currentOrder != nil)
                                }
                            }
                            .accessibilityIdentifier("catalyst-command-order-picker")
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityIdentifier("catalyst-command-dice-bag-controls")
                }

                HStack(spacing: 8) {
                    commandButton("Move", "arrow.up.right") {
                        model.moveSelectedTowardObjective()
                        overlay = nil
                    }
                    .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer || snapshot.selectedUnit?.canMoveNow != true)

                    commandButton("Fire", "scope") {
                        model.shootSelectedTarget()
                        overlay = nil
                    }
                    .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer || snapshot.selectedUnit?.canShootNow != true || snapshot.selectedTarget == nil)
                }

                HStack(spacing: 8) {
                    commandButton("Assault", "figure.run") {
                        model.assaultSelected(advance: assaultAdvance)
                        overlay = nil
                    }
                    .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer || snapshot.selectedUnit?.canAssaultNow != true || snapshot.selectedTarget == nil)

                    commandButton("Resolve", "checkmark.circle") {
                        model.resolvePendingChoice()
                        overlay = nil
                    }
                    .disabled(!model.canResolveHumanActivation)
                }

                HStack(spacing: 8) {
                    commandButton("Prev", "chevron.left") {
                        model.cycleReadyUnit(forward: false)
                    }
                    .disabled(!model.canIssueHumanOrders)

                    commandButton("Next", "chevron.right") {
                        model.cycleReadyUnit(forward: true)
                    }
                    .disabled(!model.canIssueHumanOrders)

                    commandButton("Target", "target") {
                        model.selectNearestEnemy()
                    }
                    .disabled(!model.canResolveHumanActivation)
                }

                HStack(spacing: 8) {
                    commandButton("Draw", "die.face.5.fill") {
                        model.drawOrderDie()
                        overlay = nil
                    }
                    .disabled(!model.canDrawOrderDie)

                    commandButton("AI", "forward.frame") {
                        model.runAITurn()
                        overlay = nil
                    }
                    .disabled(model.isBattleOver || (snapshot.orderDice.rulesetActive && !model.canRunAITurn && !model.canDrawOrderDie))

                    commandButton("Auto", "play.fill") {
                        model.runAutomatedActiveStep()
                        overlay = nil
                    }
                    .disabled(model.isBattleOver)
                }

                Toggle("Assault follow-up", isOn: $assaultAdvance)
                    .font(.caption.weight(.semibold))

                HStack(spacing: 8) {
                    Toggle("Cover", isOn: Binding(
                        get: { snapshot.selectedUnit?.inCover ?? false },
                        set: { model.toggleCover($0) }
                    ))
                    .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer)

                    Toggle("Hull-down", isOn: Binding(
                        get: { snapshot.selectedUnit?.hullDown ?? false },
                        set: { model.toggleHullDown($0) }
                    ))
                    .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer)
                }
                .font(.caption.weight(.semibold))

                HStack(spacing: 8) {
                    commandButton("Rotate", "rotate.right") {
                        model.rotateSelected(by: 45)
                    }
                    .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer)

                    commandButton("Debrief", "flag.checkered") {
                        model.completeBattle()
                    }
                    .disabled(model.completionLine != nil)

                    commandButton("Restart", "arrow.counterclockwise") {
                        model.restartBattle()
                    }
                }

                commandButton("Play To End", "forward.end.alt") {
                    model.playToEnd()
                    overlay = .inspector
                }
                .disabled(model.completionLine != nil)

                if let selected = snapshot.selectedUnit {
                    CatalystSelectedUnitSummary(unit: selected, sideTitle: model.sideTitle(for:))
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(CatalystPalette.commandBlue)
    }

    private func commandButton(
        _ title: String,
        _ systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
        }
    }

    private static func orderIcon(for order: HistoricalBoardOrder) -> String {
        switch order {
        case .fire:
            return "scope"
        case .advance:
            return "arrow.up.right"
        case .run:
            return "figure.run"
        case .ambush:
            return "eye"
        case .rally:
            return "flag"
        case .down:
            return "arrow.down.circle"
        }
    }

    private var inspectorPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let snapshot = model.snapshot {
                metricGrid(snapshot)

                if let selected = snapshot.selectedUnit {
                    CatalystSelectedUnitSummary(unit: selected, sideTitle: model.sideTitle(for:))
                }

                if let target = snapshot.selectedTarget {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Target", systemImage: "scope")
                            .font(.caption.weight(.bold))
                        Text(target.name)
                            .font(.headline)
                        Text("\(model.sideTitle(for: target.owner)) | \(target.roleLine)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label(snapshot.lastAction.title, systemImage: snapshot.lastAction.status == .blocked ? "exclamationmark.triangle" : "checkmark.circle")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(snapshot.lastAction.status == .blocked ? .orange : .secondary)
                    Text(snapshot.lastAction.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let result = model.currentResult {
                    resultDetail(result)
                } else if let line = model.completionLine {
                    Label(line, systemImage: "flag.checkered")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }

                if let completion = model.completion {
                    Text(completion.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let error = model.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func resultDetail(_ result: CatalystBattleResult) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(result.statusTitle, systemImage: result.hasWinner ? "flag.checkered" : "questionmark.diamond")
                .font(.caption.weight(.bold))
                .foregroundStyle(result.hasWinner ? .green : .orange)
            Text("Winner: \(result.winnerTitle)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(result.hasWinner ? .green : .secondary)
            Text("Loser: \(result.loserTitle)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(result.hasWinner ? .primary : .secondary)
            Text("\(result.scoreLine) | turn \(result.completedTurn)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            if let victoryBand = result.victoryBand {
                Text(victoryBand)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func metricGrid(_ snapshot: NativeBoardSnapshot) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
            GridRow {
                Text("Turn")
                Text("\(snapshot.turnNumber)")
                    .monospacedDigit()
            }
            GridRow {
                Text("Phase")
                Text(snapshot.phase.rawValue)
            }
            GridRow {
                Text("Active")
                Text(model.sideTitle(for: snapshot.activePlayer))
            }
            GridRow {
                Text("Score")
                Text("\(snapshot.mission.playerScore)-\(snapshot.mission.opponentScore) / \(snapshot.mission.targetScore)")
                    .monospacedDigit()
            }
        }
        .font(.caption)
    }

    private var forcesPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let snapshot = model.snapshot {
                forceSection(
                    title: model.sideTitle(for: .player),
                    units: snapshot.units.filter { $0.owner == .player }
                )
                forceSection(
                    title: model.sideTitle(for: .guderianAI),
                    units: snapshot.units.filter { $0.owner == .guderianAI }
                )
            }
        }
    }

    private func forceSection(title: String, units: [NativeBoardUnitSnapshot]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.bold))
            ForEach(units) { unit in
                HStack(spacing: 8) {
                    Image(systemName: CatalystBattleMapView.unitSymbol(unit))
                        .frame(width: 18)
                        .foregroundStyle(CatalystBattleMapView.unitColor(unit.owner))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(unit.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text("\(unit.roleLine) | \(unit.totalWoundsRemaining) wounds")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if unit.destroyed {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 3)
            }
        }
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let snapshot = model.snapshot {
                ForEach(snapshot.logLines.suffix(12), id: \.self) { line in
                    Text(line)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct CatalystBattleMapView: View {
    let snapshot: NativeBoardSnapshot
    let zoom: CGFloat
    let contentInsets: EdgeInsets
    let humanPlayer: NativeBoardPlayer
    let canIssueHumanOrders: Bool
    let sideTitle: (NativeBoardPlayer) -> String
    let onSelect: (NativeBoardUnitSnapshot) -> Void
    let onMove: (NativeBoardUnitSnapshot, NativeBattleCoordinate) -> Void

    private static let boardWidth = CGFloat(game_board_width())
    private static let boardHeight = CGFloat(game_board_height())
    private static let pointsPerBoardUnit: CGFloat = 22

    @State private var dragPreview: [Int: CGPoint] = [:]

    var body: some View {
        GeometryReader { proxy in
            let availableSize = CGSize(
                width: max(320, proxy.size.width - contentInsets.leading - contentInsets.trailing),
                height: max(240, proxy.size.height - contentInsets.top - contentInsets.bottom)
            )
            let fittedSize = fittedBoardSize(in: availableSize)
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.52, green: 0.50, blue: 0.35),
                                    Color(red: 0.31, green: 0.32, blue: 0.24),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    boardGrid(in: fittedSize)

                    ForEach(snapshot.zones) { zone in
                        terrainZone(zone, in: fittedSize)
                    }

                    ForEach(snapshot.objectives) { objective in
                        objectiveMarker(objective, in: fittedSize)
                    }

                    targetLink(in: fittedSize)

                    ForEach(snapshot.units) { unit in
                        unitToken(unit, in: fittedSize)
                    }
                }
                .frame(width: fittedSize.width, height: fittedSize.height)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
                .padding(28)
                .padding(.top, contentInsets.top)
                .padding(.bottom, contentInsets.bottom)
                .frame(minWidth: proxy.size.width, minHeight: proxy.size.height, alignment: .topLeading)
            }
            .background(CatalystPalette.background)
        }
        .accessibilityIdentifier("catalyst-battle-map")
    }

    private func fittedBoardSize(in _: CGSize) -> CGSize {
        let base = CGSize(
            width: Self.boardWidth * Self.pointsPerBoardUnit,
            height: Self.boardHeight * Self.pointsPerBoardUnit
        )
        return CGSize(width: base.width * zoom, height: base.height * zoom)
    }

    private func boardGrid(in size: CGSize) -> some View {
        Path { path in
            for column in 0...Int(Self.boardWidth) {
                let x = size.width * CGFloat(column) / Self.boardWidth
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for row in 0...Int(Self.boardHeight) {
                let y = size.height * CGFloat(row) / Self.boardHeight
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color.black.opacity(0.18), lineWidth: 1)
    }

    private func terrainZone(_ zone: NativeBoardZoneSnapshot, in size: CGSize) -> some View {
        let rect = boardRect(zone, in: size)
        let fill = terrainFill(for: zone)

        return RoundedRectangle(cornerRadius: 8)
            .fill(fill)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .overlay(alignment: .topLeading) {
                Text(zone.name)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.68)))
                    .padding(8)
                    .position(x: rect.minX + 54, y: rect.minY + 18)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        Color.white.opacity(0.18),
                        style: StrokeStyle(lineWidth: 1, dash: zone.blocksLineOfSight ? [6, 4] : [])
                    )
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            )
            .accessibilityLabel(zone.name)
    }

    private func objectiveMarker(_ objective: NativeBoardObjectiveSnapshot, in size: CGSize) -> some View {
        let position = boardPoint(CGPoint(x: objective.x, y: objective.y), in: size)
        let boardScale = size.width / Self.boardWidth
        let radius = CGFloat(objective.radius) * boardScale
        let markerColor = objectiveColor(
            objective.controller,
            contested: objective.playerPresence > 0 && objective.opponentPresence > 0
        )

        return ZStack {
            Circle()
                .stroke(markerColor.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .frame(width: radius * 2, height: radius * 2)

            Circle()
                .fill(markerColor)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(objective.id)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(.white)
                )

            Text(objective.name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.7)))
                .offset(y: radius + 14)
        }
        .position(position)
        .accessibilityLabel(objective.name)
    }

    @ViewBuilder
    private func unitToken(_ unit: NativeBoardUnitSnapshot, in size: CGSize) -> some View {
        let gamePoint = dragPreview[unit.id] ?? CGPoint(x: unit.x, y: unit.y)
        let position = boardPoint(gamePoint, in: size)
        let radius = tokenRadius(for: unit, in: size)
        let isSelected = unit.selected || unit.targeted
        let ownerColor = Self.unitColor(unit.owner)
        let isFriendly = unit.owner == humanPlayer
        let canMove = canPreviewMove(unit)
        let canFire = canPreviewFire(unit)
        let canAssault = canPreviewAssault(unit)
        let readiness = readinessBadge(canMove: canMove, canFire: canFire, canAssault: canAssault)
        let selectionStroke = isSelected ? Color.white.opacity(0.98) : Color.white.opacity(0.35)

        ZStack {
            if let readiness {
                Circle()
                    .stroke(
                        readiness.color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [7, 5])
                    )
                    .frame(width: radius * 2.85, height: radius * 2.85)
                    .shadow(color: readiness.color.opacity(0.46), radius: 10, x: 0, y: 0)
            } else if isFriendly && !unit.destroyed {
                Circle()
                    .stroke(Color.white.opacity(0.42), lineWidth: 1.5)
                    .frame(width: radius * 2.65, height: radius * 2.65)
            }

            if unit.kind == "Vehicle" || unit.kind == "Assault gun" {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ownerColor)
                    .frame(width: radius * 2.4, height: radius * 1.6)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectionStroke, lineWidth: isSelected ? 3.5 : 1)
                    }
            } else {
                Circle()
                    .fill(ownerColor)
                    .frame(width: radius * 2, height: radius * 2)
                    .overlay {
                        Circle()
                            .stroke(selectionStroke, lineWidth: isSelected ? 3.5 : 1)
                    }
            }

            VStack(spacing: 2) {
                Text(tokenName(for: unit))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .frame(width: radius * 2.2)
                    .lineLimit(2)
                Text("\(unit.totalWoundsRemaining)")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white)
            }

            if unit.kind == "Vehicle" || unit.kind == "Assault gun" {
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: radius * 0.15, height: radius * 0.9)
                    .offset(y: -radius * 1.05)
                    .rotationEffect(.degrees(unit.facingDegrees))
            }

            if let readiness {
                Image(systemName: readiness.systemImage)
                    .font(.system(size: max(11, radius * 0.48), weight: .black))
                    .foregroundStyle(.black)
                    .padding(4)
                    .background(readiness.color, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.55), lineWidth: 1)
                    }
                    .offset(x: radius * 0.95, y: -radius * 0.95)
            }
        }
        .position(position)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 6)
        .shadow(color: isSelected ? ownerColor.opacity(0.45) : .clear, radius: 12, x: 0, y: 0)
        .opacity(unit.destroyed ? 0.35 : 1)
        .onTapGesture {
            onSelect(unit)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard canPreviewMove(unit) else {
                        return
                    }
                    onSelect(unit)
                    dragPreview[unit.id] = gameCoordinates(for: value.location, in: size)
                }
                .onEnded { value in
                    guard canPreviewMove(unit) else {
                        dragPreview[unit.id] = nil
                        return
                    }
                    let point = gameCoordinates(for: value.location, in: size)
                    dragPreview[unit.id] = nil
                    onMove(unit, NativeBattleCoordinate(x: Double(point.x), y: Double(point.y)))
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(unit.name), \(sideTitle(unit.owner))")
    }

    @ViewBuilder
    private func targetLink(in size: CGSize) -> some View {
        if (snapshot.phase == .shooting || snapshot.phase == .assault),
           let selected = snapshot.selectedUnit,
           let target = snapshot.selectedTarget {
            let start = boardPoint(CGPoint(x: selected.x, y: selected.y), in: size)
            let end = boardPoint(CGPoint(x: target.x, y: target.y), in: size)
            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(targetLinkColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 6]))
            .shadow(color: targetLinkColor.opacity(0.42), radius: 8, x: 0, y: 0)
            .opacity(0.88)
        }
    }

    private func boardRect(_ zone: NativeBoardZoneSnapshot, in size: CGSize) -> CGRect {
        let origin = boardPoint(CGPoint(x: zone.x, y: zone.y), in: size)
        let width = size.width * CGFloat(zone.width) / Self.boardWidth
        let height = size.height * CGFloat(zone.height) / Self.boardHeight
        return CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }

    private func boardPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width * point.x / Self.boardWidth,
            y: size.height * point.y / Self.boardHeight
        )
    }

    private func gameCoordinates(for point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(0, point.x / size.width * Self.boardWidth), Self.boardWidth),
            y: min(max(0, point.y / size.height * Self.boardHeight), Self.boardHeight)
        )
    }

    private func canPreviewMove(_ unit: NativeBoardUnitSnapshot) -> Bool {
        canIssueHumanOrders &&
            snapshot.phase == .movement &&
            snapshot.activePlayer == unit.owner &&
            unit.owner == humanPlayer &&
            unit.canMoveNow &&
            !unit.destroyed
    }

    private func canPreviewFire(_ unit: NativeBoardUnitSnapshot) -> Bool {
        canIssueHumanOrders &&
            snapshot.phase == .shooting &&
            unit.owner == humanPlayer &&
            unit.canShootNow &&
            !unit.destroyed
    }

    private func canPreviewAssault(_ unit: NativeBoardUnitSnapshot) -> Bool {
        canIssueHumanOrders &&
            snapshot.phase == .assault &&
            unit.owner == humanPlayer &&
            unit.canAssaultNow &&
            !unit.destroyed
    }

    private var targetLinkColor: Color {
        switch snapshot.phase {
        case .shooting:
            return CatalystPalette.fireRed
        case .assault:
            return CatalystPalette.assaultOrange
        default:
            return CatalystPalette.gold
        }
    }

    private func readinessBadge(canMove: Bool, canFire: Bool, canAssault: Bool) -> (systemImage: String, color: Color)? {
        if canMove {
            return ("arrow.up.right", CatalystPalette.gold)
        }
        if canFire {
            return ("scope", CatalystPalette.fireRed)
        }
        if canAssault {
            return ("figure.run", CatalystPalette.assaultOrange)
        }
        return nil
    }

    private func tokenRadius(for unit: NativeBoardUnitSnapshot, in size: CGSize) -> CGFloat {
        let base: CGFloat = unit.kind == "Vehicle" || unit.kind == "Assault gun" ? 20 : 18
        return max(base, size.width / 46)
    }

    private func tokenName(for unit: NativeBoardUnitSnapshot) -> String {
        unit.name
            .replacingOccurrences(of: "German ", with: "")
            .replacingOccurrences(of: "British ", with: "")
            .replacingOccurrences(of: "Polish ", with: "")
            .split(separator: " ")
            .prefix(2)
            .joined(separator: " ")
    }

    private func terrainFill(for zone: NativeBoardZoneSnapshot) -> Color {
        switch zone.kind {
        case "Difficult":
            return Color(red: 0.36, green: 0.27, blue: 0.18).opacity(0.65)
        case "Impassable":
            return Color(red: 0.28, green: 0.15, blue: 0.16).opacity(0.8)
        default:
            return Color(red: 0.55, green: 0.56, blue: 0.46).opacity(0.45)
        }
    }

    static func unitColor(_ player: NativeBoardPlayer) -> Color {
        switch player {
        case .player:
            return Color(red: 0.13, green: 0.32, blue: 0.67)
        case .guderianAI:
            return Color(red: 0.63, green: 0.23, blue: 0.16)
        case .none:
            return Color(red: 0.55, green: 0.56, blue: 0.46)
        }
    }

    private func objectiveColor(_ controller: NativeBoardPlayer, contested: Bool) -> Color {
        if contested {
            return .orange
        }
        switch controller {
        case .player:
            return Color(red: 0.13, green: 0.32, blue: 0.67)
        case .guderianAI:
            return Color(red: 0.63, green: 0.23, blue: 0.16)
        case .none:
            return Color(red: 0.93, green: 0.89, blue: 0.72)
        }
    }

    static func unitSymbol(_ unit: NativeBoardUnitSnapshot) -> String {
        switch unit.kind {
        case "Vehicle":
            return "truck.box"
        case "Assault gun":
            return "shield.lefthalf.filled"
        default:
            return "figure.stand"
        }
    }
}

private struct CatalystSelectedUnitSummary: View {
    let unit: NativeBoardUnitSnapshot
    let sideTitle: (NativeBoardPlayer) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(unit.name, systemImage: CatalystBattleMapView.unitSymbol(unit))
                .font(.subheadline.weight(.bold))
            Text("\(sideTitle(unit.owner)) | \(unit.roleLine)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(readinessLine)
                .font(.caption.weight(.bold))
                .foregroundStyle(unit.canMoveNow ? CatalystPalette.gold : .secondary)
            Text("Wounds \(unit.totalWoundsRemaining) | \(unit.inCover ? "Cover" : "Open") | \(unit.hullDown ? "Hull-down" : "Exposed")")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            if !unit.historicalNote.isEmpty {
                Text(unit.historicalNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
    }

    private var readinessLine: String {
        if unit.destroyed {
            return "Destroyed"
        }
        if unit.canMoveNow {
            return "Can move now"
        }
        if unit.canShootNow {
            return "Can fire now"
        }
        if unit.canAssaultNow {
            return "Can assault now"
        }
        return "Waiting for phase"
    }
}

private struct CatalystUnavailableView: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("Guderian")
                .font(.title.bold())
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private enum CatalystPalette {
    static let background = Color(red: 0.09, green: 0.11, blue: 0.10)
    static let mapBase = Color(red: 0.58, green: 0.61, blue: 0.45)
    static let gold = Color(red: 0.92, green: 0.71, blue: 0.32)
    static let commandRed = Color(red: 0.68, green: 0.08, blue: 0.06)
    static let fireRed = Color(red: 0.95, green: 0.32, blue: 0.22)
    static let assaultOrange = Color(red: 0.96, green: 0.50, blue: 0.18)
    static let commandBlue = Color(red: 0.12, green: 0.31, blue: 0.62)
    static let dockBackground = Color(red: 0.07, green: 0.08, blue: 0.08).opacity(0.94)
    static let dockButtonBackground = Color.white.opacity(0.14)
    static let dockForeground = Color.white.opacity(0.94)
}
