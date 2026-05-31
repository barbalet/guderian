import GuderianCore
import AppKit
import OSLog
import SwiftUI

private let dzwPlayableLog = Logger(subsystem: "com.barbalet.guderian", category: "DZWPlayableBattle")

#if DEBUG
@MainActor
private func logDZWWindowSnapshot(_ context: String) {
    let windows = NSApp.windows.map { window in
        let title = window.title.isEmpty ? "<untitled>" : window.title
        let visibility = window.isVisible ? "visible" : "hidden"
        let keyState = window.isKeyWindow ? "key" : "not-key"
        let frame = "\(Int(window.frame.minX)),\(Int(window.frame.minY)) \(Int(window.frame.width))x\(Int(window.frame.height))"
        return "#\(window.windowNumber) \(title) \(visibility) \(keyState) \(frame)"
    }.joined(separator: " | ")

    dzwPlayableLog.info("Window snapshot [\(context, privacy: .public)] count=\(NSApp.windows.count, privacy: .public) windows=\(windows, privacy: .public)")
}
#else
@MainActor
private func logDZWWindowSnapshot(_ context: String) {}
#endif

private protocol DZWPlayableBoardSession: AnyObject {
    func snapshot() -> NativeBoardSnapshot
    func selectUnit(_ id: Int)
    func selectTarget(_ id: Int)
    func selectFirstActiveUnit()
    func selectNearestEnemyToSelectedUnit()
    func moveSelectedUnitTowardNearestObjective(maxDistance: Double) -> Bool
    func moveSelectedUnitTowardPriorityObjective(named priorityNames: [String], maxDistance: Double) -> Bool
    func moveUnit(_ id: Int, to point: NativeBattleCoordinate) -> Bool
    func rotateUnit(_ id: Int, to facingDegrees: Double) -> Bool
    func toggleCover(for id: Int, enabled: Bool) -> Bool
    func toggleHullDown(for id: Int, enabled: Bool) -> Bool
    func shootUnit(_ attackerID: Int, targetID: Int) -> Bool
    func assaultUnit(_ attackerID: Int, targetID: Int, advance: Bool) -> Bool
    func issueOrder(_ order: HistoricalBoardOrder, to unitID: Int) -> Bool
    func prepareNextOrderDiceActivation() -> Bool
    func shootSelectedTarget() -> Bool
    func resolveFirstPendingChoice() -> Bool
    func advancePhase()
}

extension NativeBoardSession: DZWPlayableBoardSession {
    func prepareNextOrderDiceActivation() -> Bool {
        prepareNextOrderDiceActivation(preferredOwner: nil)
    }
}
extension LateCareerNativeBoardSession: DZWPlayableBoardSession {}

private enum DZWPlayableCompletionRecord {
    case fieldCommand(CampaignCompletionRecord)
    case lateCareer(LateCareerCompletionRecord)
}

private struct DZWPlayableBattleCompletionDisplay {
    let sourceName: String
    let score: Int
    let victoryBandLabel: String
    let completedTurn: Int
    let debriefSummary: String
    let record: DZWPlayableCompletionRecord

    init(fieldCommand summary: PlayableBattleCompletionSummary) {
        sourceName = summary.sourceName
        score = summary.completionRecord.score
        victoryBandLabel = summary.completionRecord.victoryBand.rawValue
        completedTurn = summary.completionRecord.completedTurn
        debriefSummary = summary.debriefSummary
        record = .fieldCommand(summary.completionRecord)
    }

    init(
        sourceName: String,
        completionRecord: CampaignCompletionRecord,
        debriefSummary: String
    ) {
        self.sourceName = sourceName
        score = completionRecord.score
        victoryBandLabel = completionRecord.victoryBand.rawValue
        completedTurn = completionRecord.completedTurn
        self.debriefSummary = debriefSummary
        record = .fieldCommand(completionRecord)
    }

    init(lateCareer summary: UnifiedLateCareerPlayableCompletionSummary) {
        sourceName = summary.sourceName
        score = summary.completionRecord.score
        victoryBandLabel = summary.completionRecord.victoryBand.rawValue
        completedTurn = summary.completionRecord.completedTurn
        debriefSummary = summary.debriefSummary
        record = .lateCareer(summary.completionRecord)
    }

    init(
        sourceName: String,
        completionRecord: LateCareerCompletionRecord,
        debriefSummary: String
    ) {
        self.sourceName = sourceName
        score = completionRecord.score
        victoryBandLabel = completionRecord.victoryBand.rawValue
        completedTurn = completionRecord.completedTurn
        self.debriefSummary = debriefSummary
        record = .lateCareer(completionRecord)
    }
}

private struct DZWPlayableOrderDiceSideBag: Identifiable {
    let id: NativeBoardPlayer
    let title: String
    let isHumanControlled: Bool
    let isCurrent: Bool
    let remaining: Int
    let spent: Int
    let retained: Int
}

private struct DZWPlayableOrderDiceBagState {
    let currentSideTitle: String
    let canDrawOrderDie: Bool
    let drawButtonTitle: String
    let instruction: String
    let remainingTotal: Int
    let spentTotal: Int
    let retainedTotal: Int
    let sides: [DZWPlayableOrderDiceSideBag]
}

private enum DZWPlayableBattleSource {
    case fieldCommand(GuderianScenario, chosenSideID: String)
    case lateCareer(LateCareerGuderianPresentation, chosenSideID: String)

    var boardTitle: String {
        "\(battleTitle) Operations Map"
    }

    var battleTitle: String {
        switch self {
        case .fieldCommand(let scenario, _):
            return scenario.title
        case .lateCareer(let entry, _):
            return entry.title
        }
    }

    var battleID: UnifiedGuderianBattleID {
        switch self {
        case .fieldCommand(let scenario, _):
            return .fieldCommand(scenario.id)
        case .lateCareer(let entry, _):
            return .lateCareer(entry.id)
        }
    }

    var nativeScenarioLabel: String {
        switch self {
        case .fieldCommand:
            return "\(battleTitle) native scenario"
        case .lateCareer(_, _):
            return "\(battleTitle) unified native scenario"
        }
    }

    var matchupText: String {
        switch self {
        case .fieldCommand(let scenario, let chosenSideID):
            let seed = Self.fieldCommandSeed(for: scenario, restartCount: 0)
            if let selection = try? GuderianHistoricalSideSelectionResolver.resolvedSelection(
                for: scenario,
                chosenHumanSideID: chosenSideID,
                seed: seed
            ) {
                return "\(selection.selectedSideTitle) vs \(selection.opposingSideTitle)"
            }
            return "\(scenario.playerForceSummary) vs \(scenario.guderianCommand)"
        case .lateCareer(let entry, let chosenSideID):
            return "\(UnifiedGuderianBattleSideSelectionCatalog.selectedSideTitle(for: chosenSideID, in: entry)) vs \(UnifiedGuderianBattleSideSelectionCatalog.opposingSideTitle(to: chosenSideID, in: entry))"
        }
    }

    var humanPlayer: NativeBoardPlayer {
        switch self {
        case .fieldCommand(_, let chosenSideID):
            return GuderianHistoricalSideSelectionResolver.nativePlayer(for: chosenSideID) ?? .player
        case .lateCareer(_, let chosenSideID):
            return UnifiedGuderianBattleSideSelectionCatalog.nativePlayer(for: chosenSideID) ?? .player
        }
    }

    var aiPlayer: NativeBoardPlayer {
        switch humanPlayer {
        case .guderianAI:
            return .player
        default:
            return .guderianAI
        }
    }

    var aiTurnButtonTitle: String {
        "AI Turn"
    }

    func sideTitle(for player: NativeBoardPlayer) -> String {
        switch self {
        case .fieldCommand(let scenario, _):
            return GuderianHistoricalSideSelectionResolver.sideTitle(for: player, in: scenario)
        case .lateCareer(let entry, _):
            return UnifiedGuderianBattleSideSelectionCatalog.sideTitle(for: player, in: entry)
        }
    }

    func aiTargetPriorities(
        for player: NativeBoardPlayer,
        phase: NativeBoardPhase = .movement
    ) -> [String] {
        switch self {
        case .fieldCommand(let scenario, _):
            if player == .guderianAI {
                return ScenarioContentCatalog.bundle(for: scenario).aiPlan.targetPriorities(for: phase)
            }
            return OpposingForceAIPlanCatalog.plan(for: scenario).targetPriorities(for: phase)
        case .lateCareer(let entry, _):
            if player == .guderianAI {
                return LateCareerPlayableSurfaceCatalog.aiPlan(for: entry.id)?.priorityNames(for: phase) ?? []
            }
            return UnifiedGuderianBattleSideSelectionCatalog.objectivePriorityNames(for: player, in: entry)
        }
    }

    func aiPostureName(for player: NativeBoardPlayer) -> String {
        switch self {
        case .fieldCommand(let scenario, _):
            if player == .guderianAI {
                return ScenarioContentCatalog.bundle(for: scenario).aiPlan.postureName
            }
            return OpposingForceAIPlanCatalog.plan(for: scenario).postureName
        case .lateCareer(let entry, _):
            if player == .guderianAI {
                return "Unified German AI"
            }
            return "\(UnifiedGuderianBattleSideSelectionCatalog.opposingForceName(for: entry)) AI"
        }
    }

    var targetTurnUpperBound: Int {
        switch self {
        case .fieldCommand(let scenario, _):
            return ScenarioBalanceCatalog.profile(for: scenario).targetTurns.upperBound
        case .lateCareer(let entry, _):
            return LateCareerPlayableSurfaceCatalog.report(for: entry.id)?.scoringProfile.targetTurnUpperBound ?? 8
        }
    }

    func makeSession(restartCount: Int) -> DZWPlayableBoardSession? {
        switch self {
        case .fieldCommand(let scenario, let chosenSideID):
            let seed = Self.fieldCommandSeed(for: scenario, restartCount: restartCount)
            let launch = try? GuderianHistoricalSideSelectionResolver.makeLaunch(
                for: scenario,
                chosenHumanSideID: chosenSideID,
                seed: seed
            )
            guard let session = NativeBoardSession(scenario: scenario, seed: seed, launch: launch) else {
                return nil
            }
            _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
            return session
        case .lateCareer(let entry, _):
            guard let session = LateCareerNativeBoardSession(
                battlefieldID: entry.id,
                seed: UInt32(890_000 + entry.order + restartCount * 97)
            ) else {
                return nil
            }
            _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
            return session
        }
    }

    private static func fieldCommandSeed(for scenario: GuderianScenario, restartCount: Int) -> UInt32 {
        UInt32(510_000 + scenario.order + restartCount * 97)
    }
}

@MainActor
private final class DZWPlayableBattleViewModel: ObservableObject {
    static let boardWidth = CGFloat(game_board_width())
    static let boardHeight = CGFloat(game_board_height())

    @Published private(set) var snapshot: NativeBoardSnapshot?
    @Published private(set) var lastError: String = ""
    @Published private(set) var completion: DZWPlayableBattleCompletionDisplay?
    @Published private(set) var debriefError: String?
    @Published private(set) var aiTurnEvents: [String]
    @Published private(set) var playableTestGameResult: PlayableTestGameBattleResult?
    @Published private(set) var latestTutorialTrigger: TutorialTrigger?
    @Published private(set) var tutorialEventCount = 0
    @Published private(set) var isPreparingHumanTurn = false
    @Published private(set) var openingTurnPreparationGeneration = 0

    let source: DZWPlayableBattleSource
    private var session: DZWPlayableBoardSession?
    private let guderianTestController: GuderianTestFirstBattleRunController?
    private var restartCount = 0
    private var didPrepareOpeningHumanTurn = false

    init(
        scenario: GuderianScenario,
        chosenSideID: String = GuderianHistoricalSideSelectionResolver.defaultHumanSideID,
        guderianTestController: GuderianTestFirstBattleRunController? = nil
    ) {
        let resolvedSideID = guderianTestController?.session.launch.chosenHumanSideID ?? chosenSideID
        self.source = .fieldCommand(scenario, chosenSideID: resolvedSideID)
        self.guderianTestController = guderianTestController
        aiTurnEvents = [
            "\(source.sideTitle(for: source.aiPlayer)) AI ready: \(source.aiPostureName(for: source.aiPlayer)) will pressure \(Self.prioritySummary(source.aiTargetPriorities(for: source.aiPlayer)))."
        ]
        if let guderianTestController {
            session = guderianTestController.session
            syncFromGuderianTestController(context: "initial")
        } else {
            session = source.makeSession(restartCount: restartCount)
            refresh()
        }
        dzwPlayableLog.info("Battle model initialized source=fieldCommand battle=\(scenario.id.rawValue, privacy: .public) title=\(scenario.title, privacy: .public) session=\(self.session == nil ? "missing" : "ready", privacy: .public) externalGuderianTestController=\(guderianTestController != nil, privacy: .public)")
    }

    init(
        lateCareerEntry: LateCareerGuderianPresentation,
        chosenSideID: String = GuderianHistoricalSideSelectionResolver.defaultHumanSideID
    ) {
        self.source = .lateCareer(lateCareerEntry, chosenSideID: chosenSideID)
        guderianTestController = nil
        aiTurnEvents = [
            "\(source.sideTitle(for: source.aiPlayer)) AI ready: \(source.aiPostureName(for: source.aiPlayer)) will pressure \(Self.prioritySummary(source.aiTargetPriorities(for: source.aiPlayer)))."
        ]
        session = source.makeSession(restartCount: restartCount)
        refresh()
        dzwPlayableLog.info("Battle model initialized source=lateCareer battle=\(lateCareerEntry.id, privacy: .public) title=\(lateCareerEntry.title, privacy: .public) session=\(self.session == nil ? "missing" : "ready", privacy: .public)")
    }

    var selectedUnit: NativeBoardUnitSnapshot? {
        snapshot?.selectedUnit
    }

    var selectedTarget: NativeBoardUnitSnapshot? {
        snapshot?.selectedTarget
    }

    var isBattleOver: Bool {
        snapshot?.mission.winner != NativeBoardPlayer.none
    }

    var humanPlayer: NativeBoardPlayer {
        source.humanPlayer
    }

    var aiPlayer: NativeBoardPlayer {
        source.aiPlayer
    }

    var humanSideTitle: String {
        source.sideTitle(for: humanPlayer)
    }

    var aiSideTitle: String {
        source.sideTitle(for: aiPlayer)
    }

    var aiTurnSectionTitle: String {
        "\(aiSideTitle) AI"
    }

    var canIssueHumanOrders: Bool {
        guard let snapshot else {
            return false
        }
        return !isBattleOver && snapshot.orderDice.current?.owner == humanPlayer
    }

    var canResolveHumanActivation: Bool {
        guard let selectedUnit, selectedUnit.owner == humanPlayer else {
            return canIssueHumanOrders
        }
        return canIssueHumanOrders ||
            (!isBattleOver && selectedUnit.currentOrder != nil && (selectedUnit.canMoveNow || selectedUnit.canShootNow || selectedUnit.canAssaultNow))
    }

    var canDrawOrderDie: Bool {
        guard let snapshot, !isBattleOver else {
            return false
        }
        return snapshot.orderDice.current == nil
    }

    var hasCompletion: Bool {
        completion != nil
    }

    var isFirstBattleTutorialEligible: Bool {
        switch source {
        case .fieldCommand(let scenario, _):
            return scenario.id == .tucholaForest
        case .lateCareer(_, _):
            return false
        }
    }

    var title: String {
        source.boardTitle
    }

    var nativeScenarioLabel: String {
        source.nativeScenarioLabel
    }

    var matchupText: String {
        source.matchupText
    }

    var aiTurnButtonTitle: String {
        source.aiTurnButtonTitle
    }

    func sideTitle(for player: NativeBoardPlayer) -> String {
        source.sideTitle(for: player)
    }

    func orderDiceBagState(for snapshot: NativeBoardSnapshot) -> DZWPlayableOrderDiceBagState {
        let currentOwner = snapshot.orderDice.current?.owner
        let currentSideTitle = currentOwner.map(sideTitle(for:)) ?? "No die drawn"
        let instruction: String
        if currentOwner == humanPlayer {
            instruction = "\(humanSideTitle) die drawn: select one of your ready units, issue an order, then resolve its action."
        } else if currentOwner == aiPlayer {
            instruction = "\(aiSideTitle) die drawn: use Auto Step to resolve the opposing activation."
        } else {
            instruction = "Draw from the bag to decide which side activates next."
        }
        return DZWPlayableOrderDiceBagState(
            currentSideTitle: currentSideTitle,
            canDrawOrderDie: canDrawOrderDie,
            drawButtonTitle: currentOwner == nil ? "Draw From Bag" : "Die Active",
            instruction: instruction,
            remainingTotal: snapshot.orderDice.remaining.count,
            spentTotal: snapshot.orderDice.spent.count,
            retainedTotal: snapshot.orderDice.retained.count,
            sides: [humanPlayer, aiPlayer].map { player in
                DZWPlayableOrderDiceSideBag(
                    id: player,
                    title: sideTitle(for: player),
                    isHumanControlled: player == humanPlayer,
                    isCurrent: currentOwner == player,
                    remaining: snapshot.orderDice.remainingCount(for: player),
                    spent: snapshot.orderDice.spentCount(for: player),
                    retained: snapshot.orderDice.retainedCount(for: player)
                )
            }
        )
    }

    var activeUnits: [NativeBoardUnitSnapshot] {
        guard let snapshot, canIssueHumanOrders else {
            return []
        }
        return snapshot.units
            .filter { $0.owner == humanPlayer && !$0.destroyed }
            .sorted { $0.id < $1.id }
    }

    func select(_ unit: NativeBoardUnitSnapshot) {
        guard let snapshot, !isBattleOver else {
            dzwPlayableLog.info("Select ignored battleOver=\(self.isBattleOver, privacy: .public) hasSnapshot=\(self.snapshot != nil, privacy: .public)")
            return
        }
        if unit.owner == humanPlayer {
            session?.selectUnit(unit.id)
            if canIssueHumanOrders || unit.currentOrder != nil {
                session?.selectNearestEnemyToSelectedUnit()
            }
        } else {
            session?.selectTarget(unit.id)
        }
        refresh()
        dzwPlayableLog.info("Unit selection owner=\(unit.owner.rawValue, privacy: .public) unitID=\(unit.id, privacy: .public) activePlayer=\(snapshot.activePlayer.rawValue, privacy: .public)")
        recordTutorialTrigger(.unitSelection)
    }

    func cycleActiveUnit(forward: Bool) {
        let candidates = activeUnits
        guard !candidates.isEmpty else {
            return
        }
        guard let selectedID = selectedUnit?.id,
              let currentIndex = candidates.firstIndex(where: { $0.id == selectedID })
        else {
            session?.selectUnit(candidates[0].id)
            session?.selectNearestEnemyToSelectedUnit()
            refresh()
            recordTutorialTrigger(.unitSelection)
            return
        }

        let offset = forward ? 1 : -1
        let nextIndex = (currentIndex + offset + candidates.count) % candidates.count
        session?.selectUnit(candidates[nextIndex].id)
        session?.selectNearestEnemyToSelectedUnit()
        refresh()
        recordTutorialTrigger(.unitSelection)
    }

    func clearSelection() {
        guard let snapshot, canIssueHumanOrders else {
            return
        }
        if let first = snapshot.units.first(where: { $0.owner == humanPlayer && !$0.destroyed }) {
            session?.selectUnit(first.id)
            session?.selectNearestEnemyToSelectedUnit()
        }
        refresh()
        recordTutorialTrigger(.unitSelection)
    }

    func selectNearestEnemy() {
        guard canIssueHumanOrders else {
            recordTutorialTrigger(.blockedAction)
            return
        }
        session?.selectNearestEnemyToSelectedUnit()
        refresh()
    }

    func canManipulate(_ unit: NativeBoardUnitSnapshot) -> Bool {
        guard !isBattleOver else {
            return false
        }
        return canResolveHumanActivation &&
            unit.owner == humanPlayer &&
            unit.canMoveNow &&
            !unit.destroyed
    }

    func moveUnit(id: Int, to point: CGPoint) {
        guard canResolveHumanActivation else {
            dzwPlayableLog.info("Move ignored because no human activation is ready to resolve.")
            recordTutorialTrigger(.blockedAction)
            return
        }
        let coordinate = NativeBattleCoordinate(
            x: min(max(Double(point.x), 1), Double(Self.boardWidth - 1)),
            y: min(max(Double(point.y), 1), Double(Self.boardHeight - 1))
        )
        let moved = session?.moveUnit(id, to: coordinate) ?? false
        refresh()
        dzwPlayableLog.info("Move requested unitID=\(id, privacy: .public) x=\(coordinate.x, privacy: .public) y=\(coordinate.y, privacy: .public) moved=\(moved, privacy: .public)")
        recordTutorialTrigger(moved ? .movementDrag : .blockedAction)
    }

    func rotateSelected(by degrees: Double) {
        guard canResolveHumanActivation, let selectedUnit, selectedUnit.owner == humanPlayer else {
            recordTutorialTrigger(.blockedAction)
            return
        }
        let rotated = session?.rotateUnit(selectedUnit.id, to: selectedUnit.facingDegrees + degrees) ?? false
        logBoardActionFailure(rotated, action: "Rotate selected unit")
        refresh()
    }

    func toggleCover(_ enabled: Bool) {
        guard canResolveHumanActivation, let selectedUnit, selectedUnit.owner == humanPlayer else {
            recordTutorialTrigger(.blockedAction)
            return
        }
        let toggled = session?.toggleCover(for: selectedUnit.id, enabled: enabled) ?? false
        logBoardActionFailure(toggled, action: "Toggle cover")
        refresh()
    }

    func toggleHullDown(_ enabled: Bool) {
        guard canResolveHumanActivation, let selectedUnit, selectedUnit.owner == humanPlayer else {
            recordTutorialTrigger(.blockedAction)
            return
        }
        let toggled = session?.toggleHullDown(for: selectedUnit.id, enabled: enabled) ?? false
        logBoardActionFailure(toggled, action: "Toggle hull down")
        refresh()
    }

    func shootSelected() {
        guard canResolveHumanActivation, let selectedUnit, selectedUnit.owner == humanPlayer, let selectedTarget else {
            recordTutorialTrigger(.blockedAction)
            return
        }
        let fired = session?.shootUnit(selectedUnit.id, targetID: selectedTarget.id) ?? false
        refresh()
        dzwPlayableLog.info("Shoot requested attacker=\(selectedUnit.id, privacy: .public) target=\(selectedTarget.id, privacy: .public) fired=\(fired, privacy: .public)")
        recordTutorialTrigger(fired ? .shooting : .blockedAction)
    }

    func assaultSelected(advance: Bool) {
        guard canResolveHumanActivation, let selectedUnit, selectedUnit.owner == humanPlayer, let selectedTarget else {
            recordTutorialTrigger(.blockedAction)
            return
        }
        let assaulted = session?.assaultUnit(selectedUnit.id, targetID: selectedTarget.id, advance: advance) ?? false
        refresh()
        dzwPlayableLog.info("Assault requested attacker=\(selectedUnit.id, privacy: .public) target=\(selectedTarget.id, privacy: .public) advance=\(advance, privacy: .public) assaulted=\(assaulted, privacy: .public)")
        recordTutorialTrigger(assaulted ? .assault : .blockedAction)
    }

    func drawOrderDie() {
        if runGuderianTestControllerStep(context: "visible-order-dice-draw") {
            return
        }

        guard canDrawOrderDie else {
            lastError = "The current order die must be assigned before drawing again."
            recordTutorialTrigger(.blockedAction)
            return
        }

        let drew = session?.prepareNextOrderDiceActivation() ?? false
        refresh()
        if let owner = snapshot?.orderDice.current?.owner {
            recordAIEvent("Order die drawn for \(sideTitle(for: owner)).")
            if owner == aiPlayer {
                recordTutorialTrigger(.germanAITurn)
            } else {
                recordTutorialTrigger(.unitSelection)
            }
        } else if !drew {
            recordAIEvent("Order die draw blocked: \(lastError).")
            recordTutorialTrigger(.blockedAction)
        }
        dzwPlayableLog.info("Order die draw requested drew=\(drew, privacy: .public) owner=\(self.snapshot?.orderDice.current?.owner.rawValue ?? "none", privacy: .public)")
    }

    func issueOrder(_ order: HistoricalBoardOrder) {
        guard canIssueHumanOrders, let selectedUnit, selectedUnit.owner == humanPlayer else {
            lastError = "Draw a \(humanSideTitle) die before issuing an order."
            recordTutorialTrigger(.blockedAction)
            return
        }
        let issued = session?.issueOrder(order, to: selectedUnit.id) ?? false
        refresh()
        dzwPlayableLog.info("Order requested unitID=\(selectedUnit.id, privacy: .public) order=\(order.rawValue, privacy: .public) issued=\(issued, privacy: .public)")
        recordTutorialTrigger(issued ? .unitSelection : .blockedAction)
    }

    func resolvePendingChoice() {
        guard canResolveHumanActivation else {
            recordTutorialTrigger(.blockedAction)
            return
        }
        let resolved = session?.resolveFirstPendingChoice() ?? false
        logBoardActionFailure(resolved, action: "Resolve pending choice")
        refresh()
        dzwPlayableLog.info("Resolve pending choice requested.")
    }

    func advancePhase() {
        if runGuderianTestControllerStep(context: "visible-next-phase") {
            return
        }

        if snapshot?.orderDice.rulesetActive == true {
            drawOrderDie()
            return
        }

        guard canIssueHumanOrders else {
            dzwPlayableLog.info("Phase advance ignored because active side is not human-controlled.")
            recordTutorialTrigger(.blockedAction)
            return
        }
        session?.advancePhase()
        refresh()
        dzwPlayableLog.info("Phase advanced activePlayer=\(self.snapshot?.activePlayer.rawValue ?? "none", privacy: .public) phase=\(self.snapshot?.phase.rawValue ?? "none", privacy: .public) turn=\(self.snapshot?.turnNumber ?? -1, privacy: .public)")
        recordTutorialTrigger(.phaseAdvance)
        if snapshot?.activePlayer == source.aiPlayer {
            recordTutorialTrigger(.germanAITurn)
        }
    }

    func prepareOpeningHumanTurnIfNeeded() async {
        guard guderianTestController == nil else {
            return
        }
        guard !didPrepareOpeningHumanTurn else {
            return
        }
        guard let snapshot, !isBattleOver else {
            didPrepareOpeningHumanTurn = true
            return
        }
        guard snapshot.activePlayer != humanPlayer else {
            didPrepareOpeningHumanTurn = true
            return
        }

        didPrepareOpeningHumanTurn = true
        isPreparingHumanTurn = true
        dzwPlayableLog.info("Opening AI handoff scheduled humanPlayer=\(self.humanPlayer.rawValue, privacy: .public) activePlayer=\(snapshot.activePlayer.rawValue, privacy: .public)")
        await Task.yield()

        guard !Task.isCancelled else {
            isPreparingHumanTurn = false
            return
        }

        runAITurnToHumanControl(context: "opening-handoff")
        isPreparingHumanTurn = false
    }

    func runAutomatedActiveStep() {
        if runGuderianTestControllerStep(context: "visible-auto-step") {
            return
        }

        guard var snapshot, !isBattleOver else {
            dzwPlayableLog.info("Automated active step ignored battleOver=\(self.isBattleOver, privacy: .public) hasSnapshot=\(self.snapshot != nil, privacy: .public)")
            return
        }

        if snapshot.orderDice.rulesetActive && snapshot.orderDice.current == nil {
            let drew = session?.prepareNextOrderDiceActivation() ?? false
            refresh()
            guard drew, let refreshed = self.snapshot else {
                recordAIEvent("Automated step could not draw an order die: \(lastError).")
                return
            }
            snapshot = refreshed
        }

        let before = "\(snapshot.activePlayer.rawValue) \(snapshot.phase.rawValue)"
        dzwPlayableLog.info("Automated active step started state=\(before, privacy: .public) turn=\(snapshot.turnNumber, privacy: .public)")
        let actionSucceeded: Bool
        if snapshot.activePlayer == .guderianAI,
           let decision = guderianAIDecisionState(for: snapshot) {
            actionSucceeded = runGuderianOrderDiceActivation(decision: decision, snapshot: snapshot)
        } else if snapshot.activePlayer == .player,
                  let decision = opposingAIDecisionState(for: snapshot) {
            actionSucceeded = runOpposingOrderDiceActivation(decision: decision, snapshot: snapshot)
        } else {
            switch snapshot.phase {
            case .movement:
                let priorities = source.aiTargetPriorities(for: snapshot.activePlayer, phase: snapshot.phase)
                if !priorities.isEmpty {
                    let distance = snapshot.activePlayer == .guderianAI ? 6.0 : 5.0
                    actionSucceeded = session?.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: distance) ?? false
                } else {
                    actionSucceeded = session?.moveSelectedUnitTowardNearestObjective(maxDistance: 4) ?? false
                }
            case .shooting:
                session?.selectNearestEnemyToSelectedUnit()
                actionSucceeded = session?.shootSelectedTarget() ?? false
            case .assault:
                actionSucceeded = session?.resolveFirstPendingChoice() ?? false
            }
        }
        let actionDetail = session?.snapshot().lastAction.detail ?? "No action resolved."
        if !actionSucceeded {
            recordAIEvent("\(before): blocked or unavailable action - \(actionDetail)")
        }
        if snapshot.orderDice.rulesetActive {
            refresh()
        } else {
            session?.advancePhase()
            refresh()
        }
        recordAIEvent("\(before): \(actionDetail)")
    }

    private func runGuderianOrderDiceActivation(
        decision: GuderianOrderDiceAIDecisionState,
        snapshot: NativeBoardSnapshot
    ) -> Bool {
        session?.selectUnit(decision.chosenUnitID)
        session?.selectNearestEnemyToSelectedUnit()
        let orderIssued = session?.issueOrder(decision.chosenOrder, to: decision.chosenUnitID) ?? false
        let priorities = source.aiTargetPriorities(for: .guderianAI, phase: snapshot.phase)
        let actionSucceeded: Bool
        switch decision.chosenOrder {
        case .advance:
            actionSucceeded = session?.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: 6) ??
                session?.moveSelectedUnitTowardNearestObjective(maxDistance: 6) ?? false
        case .run:
            if snapshot.phase == .assault {
                session?.selectNearestEnemyToSelectedUnit()
                if let targetID = session?.snapshot().selectedTarget?.id {
                    actionSucceeded = session?.assaultUnit(decision.chosenUnitID, targetID: targetID, advance: true) ?? false
                } else {
                    actionSucceeded = false
                }
            } else {
                actionSucceeded = session?.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: 9) ??
                    session?.moveSelectedUnitTowardNearestObjective(maxDistance: 9) ?? false
            }
        case .fire:
            session?.selectNearestEnemyToSelectedUnit()
            actionSucceeded = session?.shootSelectedTarget() ?? false
        case .ambush, .rally, .down:
            actionSucceeded = orderIssued
        }
        recordAIEvent("Order-dice AI chose \(decision.chosenUnitName): \(decision.chosenOrder.rawValue) toward \(decision.objectiveOrTargetName).")
        return orderIssued || actionSucceeded
    }

    private func runOpposingOrderDiceActivation(
        decision: GuderianOrderDiceOpposingAIDecisionState,
        snapshot: NativeBoardSnapshot
    ) -> Bool {
        session?.selectUnit(decision.chosenUnitID)
        session?.selectNearestEnemyToSelectedUnit()
        let orderIssued = session?.issueOrder(decision.chosenOrder, to: decision.chosenUnitID) ?? false
        let priorities = source.aiTargetPriorities(for: .player, phase: snapshot.phase)
        let actionSucceeded: Bool
        switch decision.chosenOrder {
        case .advance:
            actionSucceeded = session?.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: 5) ??
                session?.moveSelectedUnitTowardNearestObjective(maxDistance: 5) ?? false
        case .run:
            if snapshot.phase == .assault {
                session?.selectNearestEnemyToSelectedUnit()
                if let targetID = session?.snapshot().selectedTarget?.id {
                    actionSucceeded = session?.assaultUnit(decision.chosenUnitID, targetID: targetID, advance: true) ?? false
                } else {
                    actionSucceeded = false
                }
            } else {
                actionSucceeded = session?.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: 8) ??
                    session?.moveSelectedUnitTowardNearestObjective(maxDistance: 8) ?? false
            }
        case .fire:
            session?.selectNearestEnemyToSelectedUnit()
            actionSucceeded = session?.shootSelectedTarget() ?? false
        case .ambush, .rally, .down:
            actionSucceeded = orderIssued
        }
        recordAIEvent("Opposing order-dice AI chose \(decision.chosenUnitName): \(decision.chosenOrder.rawValue) toward \(decision.objectiveOrTargetName).")
        return orderIssued || actionSucceeded
    }

    func runGermanTurn() {
        if let guderianTestController {
            do {
                _ = try guderianTestController.runUntilPauseOrDebrief(maxSteps: 6)
                syncFromGuderianTestController(context: "visible-german-turn")
                dzwPlayableLog.info("Visible AI turn routed through external GuderianTest controller.")
            } catch {
                debriefError = "\(error)"
                dzwPlayableLog.error("Visible AI turn failed through external GuderianTest controller error=\(String(describing: error), privacy: .public)")
            }
            return
        }

        recordTutorialTrigger(.germanAITurn)
        runAITurnToHumanControl(context: "manual-ai-turn")
    }

    private func runAITurnToHumanControl(context: String) {
        guard !isBattleOver else {
            dzwPlayableLog.info("AI turn ignored because battle is over context=\(context, privacy: .public)")
            return
        }

        if snapshot?.orderDice.rulesetActive == true {
            runOrderDiceAutomationToHumanControl(context: context)
            return
        }

        let aiPlayer = source.aiPlayer
        let aiLabel = source.sideTitle(for: aiPlayer)
        dzwPlayableLog.info("AI turn runner started context=\(context, privacy: .public) aiPlayer=\(aiPlayer.rawValue, privacy: .public)")
        recordAIEvent("\(aiLabel) AI turn runner started.")
        var safety = 0
        while snapshot?.activePlayer != aiPlayer && isBattleOver == false && safety < 4 {
            session?.advancePhase()
            refresh()
            safety += 1
        }

        while snapshot?.activePlayer == aiPlayer && isBattleOver == false && safety < 10 {
            runAutomatedActiveStep()
            safety += 1
        }

        if snapshot?.activePlayer == aiPlayer {
            recordAIEvent("\(aiLabel) AI turn paused: action loop hit its safety cap.")
            dzwPlayableLog.info("AI turn paused at safety cap context=\(context, privacy: .public) activePlayer=\(self.snapshot?.activePlayer.rawValue ?? "none", privacy: .public) phase=\(self.snapshot?.phase.rawValue ?? "none", privacy: .public)")
        } else {
            recordAIEvent("\(aiLabel) AI turn complete: control returned to \(snapshot.map { self.source.sideTitle(for: $0.activePlayer) } ?? "the player").")
            dzwPlayableLog.info("AI turn complete context=\(context, privacy: .public) activePlayer=\(self.snapshot?.activePlayer.rawValue ?? "none", privacy: .public) phase=\(self.snapshot?.phase.rawValue ?? "none", privacy: .public)")
        }
    }

    private func runOrderDiceAutomationToHumanControl(context: String) {
        let aiLabel = source.sideTitle(for: aiPlayer)
        dzwPlayableLog.info("Order-dice AI turn runner started context=\(context, privacy: .public) aiPlayer=\(self.aiPlayer.rawValue, privacy: .public)")
        recordAIEvent("\(aiLabel) order-dice runner started.")

        var safety = 0
        while isBattleOver == false && safety < 20 {
            if snapshot?.orderDice.current?.owner == humanPlayer {
                recordAIEvent("Order die drawn for \(humanSideTitle): control returned to the player.")
                return
            }

            if snapshot?.orderDice.current == nil {
                let drew = session?.prepareNextOrderDiceActivation() ?? false
                refresh()
                guard drew else {
                    recordAIEvent("Order-dice runner paused: \(lastError).")
                    return
                }
                if snapshot?.orderDice.current?.owner == humanPlayer {
                    recordAIEvent("Order die drawn for \(humanSideTitle): control returned to the player.")
                    return
                }
            }

            runAutomatedActiveStep()
            safety += 1
        }

        recordAIEvent("\(aiLabel) order-dice runner paused: action loop hit its safety cap.")
        dzwPlayableLog.info("Order-dice AI runner paused context=\(context, privacy: .public) currentOwner=\(self.snapshot?.orderDice.current?.owner.rawValue ?? "none", privacy: .public)")
    }

    func restartBattle() {
        if let guderianTestController {
            do {
                try guderianTestController.restart()
                syncFromGuderianTestController(context: "restart")
                dzwPlayableLog.info("External GuderianTest battle restarted through visible board controls.")
            } catch {
                debriefError = "\(error)"
                dzwPlayableLog.error("External GuderianTest battle restart failed error=\(String(describing: error), privacy: .public)")
            }
            return
        }

        restartCount += 1
        didPrepareOpeningHumanTurn = false
        session = source.makeSession(restartCount: restartCount)
        completion = nil
        debriefError = nil
        playableTestGameResult = nil
        aiTurnEvents = [
            "Battle restarted: \(source.sideTitle(for: source.aiPlayer)) AI ready for \(source.battleTitle)."
        ]
        refresh()
        openingTurnPreparationGeneration += 1
        dzwPlayableLog.info("Battle restarted title=\(self.source.battleTitle, privacy: .public) restartCount=\(self.restartCount, privacy: .public) session=\(self.session == nil ? "missing" : "ready", privacy: .public)")
    }

    func recordTutorialTrigger(_ trigger: TutorialTrigger) {
        latestTutorialTrigger = trigger
        tutorialEventCount += 1
        dzwPlayableLog.info("Model tutorial trigger recorded trigger=\(trigger.rawValue, privacy: .public) eventCount=\(self.tutorialEventCount, privacy: .public)")
    }

    func playBattleToEnd() -> DZWPlayableCompletionRecord? {
        if let guderianTestController {
            do {
                let report = try guderianTestController.runToDebrief()
                syncFromGuderianTestController(context: "visible-play-to-end")
                dzwPlayableLog.info("Visible play-to-end routed through external GuderianTest controller.")
                return .fieldCommand(report.result.completion.completionRecord)
            } catch {
                debriefError = "\(error)"
                syncFromGuderianTestController(context: "visible-play-to-end-error")
                dzwPlayableLog.error("Visible play-to-end failed through external GuderianTest controller error=\(String(describing: error), privacy: .public)")
                return nil
            }
        }

        guard let session else {
            debriefError = "Board session unavailable."
            dzwPlayableLog.error("Play-to-end failed because board session is unavailable.")
            return nil
        }

        dzwPlayableLog.info("Play-to-end requested source=\(self.source.battleTitle, privacy: .public)")
        switch source {
        case .fieldCommand(let scenario, _):
            guard let nativeSession = session as? NativeBoardSession else {
                debriefError = "Field-command board session unavailable."
                dzwPlayableLog.error("Play-to-end failed because field-command session cast failed.")
                return nil
            }
            do {
                let result = try PlayableTestGameRunner.runBattle(from: nativeSession)
                let display = fieldCommandDisplay(from: result.completion, scenario: scenario)
                playableTestGameResult = result
                completion = display
                debriefError = nil
                refresh()
                recordTutorialTrigger(.debrief)
                recordAIEvent("Playable test game completed: \(result.antiGuderianStepCount) default-side automation steps, \(result.germanStepCount) Guderian-command automation steps.")
                dzwPlayableLog.info("Play-to-end completed antiGuderianSteps=\(result.antiGuderianStepCount, privacy: .public) germanSteps=\(result.germanStepCount, privacy: .public) score=\(display.score, privacy: .public) band=\(display.victoryBandLabel, privacy: .public)")
                return display.record
            } catch {
                completion = nil
                playableTestGameResult = nil
                debriefError = "\(error)"
                refresh()
                dzwPlayableLog.error("Play-to-end failed error=\(String(describing: error), privacy: .public)")
                return nil
            }
        case .lateCareer(_, _):
            playableTestGameResult = nil
            runSharedAutoplayToDebrief()
            let record = completeBattle()
            if record != nil {
                recordTutorialTrigger(.debrief)
            }
            dzwPlayableLog.info("Late-career play-to-end finished record=\(record == nil ? "none" : "available", privacy: .public)")
            return record
        }
    }

    func completeBattle() -> DZWPlayableCompletionRecord? {
        if let guderianTestController {
            if let report = guderianTestController.lastReport {
                syncFromGuderianTestController(context: "visible-debrief-existing")
                return .fieldCommand(report.result.completion.completionRecord)
            }
            return playBattleToEnd()
        }

        guard let session else {
            debriefError = "Board session unavailable."
            dzwPlayableLog.error("Complete battle failed because board session is unavailable.")
            return nil
        }

        dzwPlayableLog.info("Complete battle requested source=\(self.source.battleTitle, privacy: .public)")
        switch source {
        case .fieldCommand(let scenario, _):
            guard let nativeSession = session as? NativeBoardSession else {
                debriefError = "Field-command board session unavailable."
                dzwPlayableLog.error("Complete battle failed because field-command session cast failed.")
                return nil
            }
            do {
                let result = try PlayableBattleCompletionResolver.completeBattle(from: nativeSession)
                let display = fieldCommandDisplay(from: result, scenario: scenario)
                completion = display
                playableTestGameResult = nil
                debriefError = nil
                refresh()
                recordTutorialTrigger(.debrief)
                recordAIEvent("Debrief recorded: \(display.score) VP, \(display.victoryBandLabel).")
                dzwPlayableLog.info("Complete battle recorded score=\(display.score, privacy: .public) band=\(display.victoryBandLabel, privacy: .public)")
                return display.record
            } catch {
                completion = nil
                debriefError = "\(error)"
                refresh()
                dzwPlayableLog.error("Complete battle failed error=\(String(describing: error), privacy: .public)")
                return nil
            }
        case .lateCareer(_, _):
            guard let lateCareerSession = session as? LateCareerNativeBoardSession,
                  let result = UnifiedLateCareerCompletionResolver.completeBattle(from: lateCareerSession) else {
                completion = nil
                debriefError = "Late-career debrief is unavailable for \(source.battleTitle)."
                refresh()
                dzwPlayableLog.error("Complete battle failed because late-career debrief is unavailable title=\(self.source.battleTitle, privacy: .public)")
                return nil
            }
            let display = lateCareerDisplay(from: result)
            completion = display
            playableTestGameResult = nil
            debriefError = nil
            refresh()
            recordTutorialTrigger(.debrief)
            recordAIEvent("Debrief recorded: \(display.score) VP, \(display.victoryBandLabel).")
            dzwPlayableLog.info("Late-career complete battle recorded score=\(display.score, privacy: .public) band=\(display.victoryBandLabel, privacy: .public)")
            return display.record
        }
    }

    private func lateCareerDisplay(
        from summary: UnifiedLateCareerPlayableCompletionSummary
    ) -> DZWPlayableBattleCompletionDisplay {
        guard humanPlayer == .guderianAI,
              let report = LateCareerPlayableSurfaceCatalog.report(for: summary.completionRecord.battlefieldID) else {
            return DZWPlayableBattleCompletionDisplay(lateCareer: summary)
        }

        let maxScore = report.scoringProfile.maxPlayerScore
        let opposingScore = summary.completionRecord.score
        let selectedScore = min(maxScore, max(0, maxScore - opposingScore))
        let selectedBand = summary.scoreBands
            .sorted { $0.minimumScore > $1.minimumScore }
            .first { selectedScore >= $0.minimumScore }?.victoryBand ??
            summary.completionRecord.victoryBand
        let note = "Completed as \(humanSideTitle) in selected-side study mode. Opposing-force campaign score was \(opposingScore)/\(maxScore); this debrief inverts it so the saved result matches the side you chose."
        let record = LateCareerCompletionRecord(
            battlefieldID: summary.completionRecord.battlefieldID,
            score: selectedScore,
            victoryBand: selectedBand,
            completedTurn: summary.completionRecord.completedTurn,
            persistenceKey: summary.completionRecord.persistenceKey,
            note: note
        )
        let debrief = "\(humanSideTitle) completed \(source.battleTitle) on turn \(record.completedTurn) with \(selectedScore)/\(maxScore) VP. This is a sober command-study result, not celebratory framing; the original opposing-force score was \(opposingScore)."
        return DZWPlayableBattleCompletionDisplay(
            sourceName: "\(summary.sourceName) | \(humanSideTitle) study mode",
            completionRecord: record,
            debriefSummary: debrief
        )
    }

    private func fieldCommandDisplay(
        from summary: PlayableBattleCompletionSummary,
        scenario: GuderianScenario
    ) -> DZWPlayableBattleCompletionDisplay {
        guard humanPlayer == .guderianAI else {
            return DZWPlayableBattleCompletionDisplay(fieldCommand: summary)
        }

        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let opposingScore = summary.completionRecord.score
        let selectedScore = min(balance.maxPlayerScore, max(0, balance.maxPlayerScore - opposingScore))
        let selectedBand = Self.outcomeBand(for: selectedScore, balance: balance)
        let note = "Completed as \(humanSideTitle) in selected-side study mode. Opposing-force campaign score was \(opposingScore)/\(balance.maxPlayerScore); this debrief inverts it so the saved result matches the side you chose."
        let record = CampaignCompletionRecord(
            scenarioID: summary.completionRecord.scenarioID,
            score: selectedScore,
            victoryBand: selectedBand,
            completedTurn: summary.completionRecord.completedTurn,
            note: note
        )
        let debrief = "\(humanSideTitle) completed \(scenario.title) on turn \(record.completedTurn) with \(selectedScore)/\(balance.maxPlayerScore) VP. This is a sober command-study result, not celebratory framing; the original opposing-force score was \(opposingScore)."
        return DZWPlayableBattleCompletionDisplay(
            sourceName: "\(summary.sourceName) | \(humanSideTitle) study mode",
            completionRecord: record,
            debriefSummary: debrief
        )
    }

    private static func outcomeBand(for score: Int, balance: ScenarioBalanceProfile) -> VictoryBand {
        if let exact = balance.outcomeBands.first(where: { $0.scoreRange.contains(score) }) {
            return exact.grade
        }
        return balance.outcomeBands
            .sorted { $0.scoreRange.lowerBound < $1.scoreRange.lowerBound }
            .last { score >= $0.scoreRange.lowerBound }?.grade ?? .historicalPressure
    }

    private func refresh() {
        snapshot = session?.snapshot()
        lastError = snapshot?.lastAction.detail ?? "Board session unavailable."
    }

    private func logBoardActionFailure(_ succeeded: Bool, action: String) {
        guard !succeeded else {
            return
        }
        let detail = session?.snapshot().lastAction.detail ?? "Board session unavailable."
        dzwPlayableLog.warning("\(action, privacy: .public) returned false detail=\(detail, privacy: .public)")
    }

    @discardableResult
    private func runGuderianTestControllerStep(context: String) -> Bool {
        guard let guderianTestController else {
            return false
        }

        do {
            _ = try guderianTestController.stepOnce()
            syncFromGuderianTestController(context: context)
            dzwPlayableLog.info("Visible board action routed through external GuderianTest controller context=\(context, privacy: .public)")
        } catch {
            debriefError = "\(error)"
            dzwPlayableLog.error("Visible board action failed through external GuderianTest controller context=\(context, privacy: .public) error=\(String(describing: error), privacy: .public)")
        }
        return true
    }

    func syncFromGuderianTestController(context: String) {
        guard let guderianTestController else {
            return
        }

        session = guderianTestController.session
        snapshot = guderianTestController.latestSnapshot
        lastError = guderianTestController.latestSnapshot.lastAction.detail
        if let report = guderianTestController.lastReport {
            completion = DZWPlayableBattleCompletionDisplay(fieldCommand: report.result.completion)
            playableTestGameResult = report.result
            debriefError = nil
        } else {
            completion = nil
            playableTestGameResult = nil
            if guderianTestController.runState != .failed {
                debriefError = nil
            }
        }

        aiTurnEvents = Self.guderianTestEvents(from: guderianTestController)
        dzwPlayableLog.info("Visible board synced from GuderianTest controller context=\(context, privacy: .public) state=\(guderianTestController.runState.rawValue, privacy: .public) steps=\(guderianTestController.steps.count, privacy: .public) phaseAdvances=\(guderianTestController.phaseAdvances, privacy: .public) turn=\(guderianTestController.latestSnapshot.turnNumber, privacy: .public) phase=\(guderianTestController.latestSnapshot.phase.rawValue, privacy: .public) action=\(guderianTestController.latestSnapshot.lastAction.detail, privacy: .public)")
    }

    private static func guderianTestEvents(from controller: GuderianTestFirstBattleRunController) -> [String] {
        let recent = controller.steps.suffix(8).map { step in
            "\(step.turnNumber) \(step.activePlayer.rawValue) \(step.phase.rawValue): \(step.detail)"
        }

        if recent.isEmpty {
            return [
                "GuderianTest live controller ready: visible board shares the autoplay session."
            ]
        }

        return Array(recent)
    }

    private func runSharedAutoplayToDebrief() {
        let maxPhaseAdvances = max(24, source.targetTurnUpperBound * 8)
        var phaseAdvances = 0

        while let snapshot,
              snapshot.turnNumber <= source.targetTurnUpperBound,
              snapshot.mission.winner == .none,
              phaseAdvances < maxPhaseAdvances {
            runAutomatedActiveStep()
            phaseAdvances += 1
        }

        recordAIEvent("Playable test game completed through \(phaseAdvances) shared board phases.")
        dzwPlayableLog.info("Shared autoplay ended phaseAdvances=\(phaseAdvances, privacy: .public) winner=\(self.snapshot?.mission.winner.rawValue ?? "none", privacy: .public) turn=\(self.snapshot?.turnNumber ?? -1, privacy: .public)")
    }

    private func recordAIEvent(_ message: String) {
        aiTurnEvents.append(message)
        if aiTurnEvents.count > 8 {
            aiTurnEvents.removeFirst(aiTurnEvents.count - 8)
        }
        dzwPlayableLog.info("AI event: \(message, privacy: .public)")
    }

    private static func prioritySummary(_ priorities: [String]) -> String {
        let visiblePriorities = priorities.prefix(3)
        guard !visiblePriorities.isEmpty else {
            return "the scenario objectives"
        }
        return visiblePriorities.joined(separator: ", ")
    }

    func commandPanelState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceCommandPanelState {
        GuderianOrderDiceCommandPanelPresenter.state(
            snapshot: snapshot,
            humanPlayer: humanPlayer,
            humanSideTitle: humanSideTitle,
            activeSideTitle: sideTitle(for: snapshot.activePlayer)
        )
    }

    func inspectorState(for unit: NativeBoardUnitSnapshot) -> GuderianOrderDiceInspectorState {
        GuderianOrderDiceInspectorPresenter.state(for: unit)
    }

    func movementPreviewState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceMovementPreviewState? {
        GuderianOrderDiceMovementPreviewPresenter.state(snapshot: snapshot, battleID: source.battleID)
    }

    func shootingState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceShootingState? {
        GuderianOrderDiceShootingPresenter.state(snapshot: snapshot)
    }

    func vehicleState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceVehicleState? {
        GuderianOrderDiceVehiclePresenter.state(snapshot: snapshot)
    }

    func closeQuartersState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceCloseQuartersState? {
        GuderianOrderDiceCloseQuartersPresenter.state(snapshot: snapshot)
    }

    func guderianAIDecisionState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceAIDecisionState? {
        GuderianOrderDiceGuderianAIActivationPlanner.decision(
            snapshot: snapshot,
            battleID: source.battleID,
            priorityNames: source.aiTargetPriorities(for: .guderianAI, phase: snapshot.phase)
        )
    }

    func opposingAIDecisionState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceOpposingAIDecisionState? {
        switch source {
        case .fieldCommand(let scenario, _):
            return GuderianOrderDiceOpposingAIActivationPlanner.decision(
                snapshot: snapshot,
                battleID: source.battleID,
                plan: OpposingForceAIPlanCatalog.plan(for: scenario)
            )
        case .lateCareer(let entry, _):
            return GuderianOrderDiceOpposingAIActivationPlanner.decision(
                snapshot: snapshot,
                battleID: source.battleID,
                armyFamily: .lateWarSovietAllied,
                behaviorProfile: .mobileDelay,
                priorityNames: source.aiTargetPriorities(for: .player, phase: snapshot.phase),
                strategicGoal: entry.visibleCommandCaveatLabel
            )
        }
    }

    func standingOrderDecisionState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceStandingOrderDecision? {
        snapshot.selectedUnit.map { GuderianOrderDiceStandingOrderPlanner.recommendation(for: $0, phase: snapshot.phase) }
    }

    func pinsMoraleAIState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDicePinsMoraleAIState? {
        snapshot.selectedUnit.map(GuderianOrderDicePinsMoraleAIPlanner.state(for:))
    }

    func targetReactionAIState(for snapshot: NativeBoardSnapshot) -> GuderianOrderDiceTargetReactionDecisionState? {
        guard let attacker = snapshot.selectedUnit,
              let target = snapshot.selectedTarget else {
            return nil
        }
        return GuderianOrderDiceTargetReactionAIPlanner.decision(
            attacker: attacker,
            target: target,
            incomingAction: attacker.currentOrder ?? .fire
        )
    }

    func scenarioTuningState() -> GuderianOrderDiceScenarioTuningRow? {
        GuderianOrderDiceFieldScenarioTuningCatalog.row(for: source.battleID)
    }

    func lateCareerTuningState() -> GuderianOrderDiceLateCareerTuningRow? {
        GuderianOrderDiceLateCareerTuningCatalog.row(for: source.battleID)
    }

    func activationScoringState() -> GuderianOrderDiceActivationScoringRow? {
        GuderianOrderDiceActivationScoringCatalog.row(for: source.battleID)
    }

    func orderDiceSaveStateMigration() -> GuderianOrderDiceSaveStateMigrationRow? {
        GuderianOrderDiceSaveStateMigrationCatalog.row(for: source.battleID)
    }

    func orderDiceDebriefCopyState() -> GuderianOrderDiceDebriefCopyRow? {
        GuderianOrderDiceDebriefCopyCatalog.row(for: source.battleID)
    }

    func orderDiceTurnEndPersistenceState() -> GuderianOrderDiceTurnEndPersistenceRow? {
        GuderianOrderDiceTurnEndPersistenceCatalog.row(for: source.battleID)
    }

    func orderDiceFullHarnessState() -> GuderianOrderDiceFullBattleHarnessRow? {
        GuderianOrderDiceFullBattleHarnessCatalog.row(for: source.battleID)
    }

    func orderDiceBalanceAuditState() -> GuderianOrderDiceBalanceAuditRow? {
        GuderianOrderDiceBalanceAuditCatalog.row(for: source.battleID)
    }

    func orderDiceMontyHandoffSummary() -> String {
        GuderianOrderDiceMontyAPIHandoffCatalog.summary
    }

    func orderDiceBuildMatrixSummary() -> String {
        GuderianOrderDiceBuildMatrixCatalog.summary
    }

    func orderDiceMigrationCleanupSummary() -> String {
        GuderianOrderDiceMigrationCleanupCatalog.allRows
            .map { "\($0.legacySymbol): \($0.disposition.rawValue)" }
            .joined(separator: " | ")
    }
}

private enum DZWPlayableBattlePanel: String, CaseIterable, Identifiable {
    case command
    case inspector
    case forces
    case log

    var id: Self { self }

    var title: String {
        switch self {
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

    var windowIdentifier: NSUserInterfaceItemIdentifier {
        NSUserInterfaceItemIdentifier("com.barbalet.guderian.dzwPlayableBattle.\(rawValue)")
    }
}

@MainActor
private final class DZWPlayableBattleWindowCoordinator: NSObject, ObservableObject, NSWindowDelegate {
    @Published private(set) var visiblePanels: Set<DZWPlayableBattlePanel> = []

    private var windows: [DZWPlayableBattlePanel: NSWindow] = [:]

    func showDefaults(
        model: DZWPlayableBattleViewModel,
        assaultAdvance: Binding<Bool>,
        firstBattleButtonCoachProgress: Binding<FirstBattleButtonCoachProgress>,
        firstBattleButtonCoachCompleted: Binding<Bool>,
        showsFirstBattleButtonCoach: Bool,
        onCompletion: @escaping (DZWPlayableCompletionRecord) -> Void
    ) {
        dzwPlayableLog.info("Showing default battle panels currentVisible=\(self.visiblePanels.map(\.rawValue).sorted().joined(separator: ","), privacy: .public)")
        for panel in [DZWPlayableBattlePanel.command, .inspector] {
            show(
                panel,
                model: model,
                assaultAdvance: assaultAdvance,
                firstBattleButtonCoachProgress: firstBattleButtonCoachProgress,
                firstBattleButtonCoachCompleted: firstBattleButtonCoachCompleted,
                showsFirstBattleButtonCoach: showsFirstBattleButtonCoach,
                onCompletion: onCompletion
            )
        }
        dzwPlayableLog.info("Default battle panels shown visible=\(self.visiblePanels.map(\.rawValue).sorted().joined(separator: ","), privacy: .public)")
        logDZWWindowSnapshot("dzw-panel-defaults")
    }

    func toggle(
        _ panel: DZWPlayableBattlePanel,
        model: DZWPlayableBattleViewModel,
        assaultAdvance: Binding<Bool>,
        firstBattleButtonCoachProgress: Binding<FirstBattleButtonCoachProgress>,
        firstBattleButtonCoachCompleted: Binding<Bool>,
        showsFirstBattleButtonCoach: Bool,
        onCompletion: @escaping (DZWPlayableCompletionRecord) -> Void
    ) {
        dzwPlayableLog.info("Panel toggle requested panel=\(panel.rawValue, privacy: .public) wasVisible=\(self.visiblePanels.contains(panel), privacy: .public)")
        if visiblePanels.contains(panel) {
            hide(panel)
        } else {
            show(
                panel,
                model: model,
                assaultAdvance: assaultAdvance,
                firstBattleButtonCoachProgress: firstBattleButtonCoachProgress,
                firstBattleButtonCoachCompleted: firstBattleButtonCoachCompleted,
                showsFirstBattleButtonCoach: showsFirstBattleButtonCoach,
                onCompletion: onCompletion
            )
        }
    }

    func show(
        _ panel: DZWPlayableBattlePanel,
        model: DZWPlayableBattleViewModel,
        assaultAdvance: Binding<Bool>,
        firstBattleButtonCoachProgress: Binding<FirstBattleButtonCoachProgress>,
        firstBattleButtonCoachCompleted: Binding<Bool>,
        showsFirstBattleButtonCoach: Bool,
        onCompletion: @escaping (DZWPlayableCompletionRecord) -> Void
    ) {
        let reusedWindow = windows[panel] != nil
        let window = windows[panel] ?? makeWindow(for: panel)
        window.contentViewController = NSHostingController(
            rootView: DZWPlayableBattlePanelWindow(
                panel: panel,
                model: model,
                assaultAdvance: assaultAdvance,
                firstBattleButtonCoachProgress: firstBattleButtonCoachProgress,
                firstBattleButtonCoachCompleted: firstBattleButtonCoachCompleted,
                showsFirstBattleButtonCoach: showsFirstBattleButtonCoach,
                onCompletion: onCompletion
            )
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        visiblePanels.insert(panel)
        dzwPlayableLog.info("Panel shown panel=\(panel.rawValue, privacy: .public) reusedWindow=\(reusedWindow, privacy: .public) windowNumber=\(window.windowNumber, privacy: .public) frame=\(NSStringFromRect(window.frame), privacy: .public) visible=\(self.visiblePanels.map(\.rawValue).sorted().joined(separator: ","), privacy: .public)")
    }

    func hide(_ panel: DZWPlayableBattlePanel) {
        windows[panel]?.orderOut(nil)
        visiblePanels.remove(panel)
        dzwPlayableLog.info("Panel hidden panel=\(panel.rawValue, privacy: .public) visible=\(self.visiblePanels.map(\.rawValue).sorted().joined(separator: ","), privacy: .public)")
        logDZWWindowSnapshot("dzw-panel-hide-\(panel.rawValue)")
    }

    func closeAll() {
        dzwPlayableLog.info("Closing all battle panels count=\(self.windows.count, privacy: .public) visible=\(self.visiblePanels.map(\.rawValue).sorted().joined(separator: ","), privacy: .public)")
        for window in windows.values {
            window.delegate = nil
            window.close()
        }
        windows.removeAll()
        visiblePanels.removeAll()
        logDZWWindowSnapshot("dzw-panel-close-all")
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let panel = panel(for: window) else {
            dzwPlayableLog.info("Panel windowWillClose received for unknown window identifier=\(notification.object.debugDescription, privacy: .public)")
            return
        }
        visiblePanels.remove(panel)
        dzwPlayableLog.info("Panel window will close panel=\(panel.rawValue, privacy: .public) windowNumber=\(window.windowNumber, privacy: .public) visible=\(self.visiblePanels.map(\.rawValue).sorted().joined(separator: ","), privacy: .public)")
    }

    private func makeWindow(for panel: DZWPlayableBattlePanel) -> NSWindow {
        let window = NSWindow(
            contentRect: defaultFrame(for: panel),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Guderian \(panel.title)"
        window.identifier = panel.windowIdentifier
        window.minSize = panel.minimumSize
        window.isReleasedWhenClosed = false
        window.delegate = self
        windows[panel] = window
        dzwPlayableLog.info("Panel window created panel=\(panel.rawValue, privacy: .public) title=\(window.title, privacy: .public) frame=\(NSStringFromRect(window.frame), privacy: .public)")
        return window
    }

    private func panel(for window: NSWindow) -> DZWPlayableBattlePanel? {
        windows.first { _, storedWindow in storedWindow === window }?.key
    }

    private func defaultFrame(for panel: DZWPlayableBattlePanel) -> CGRect {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 80, y: 80, width: 1440, height: 900)
        let size = panel.defaultSize
        let origin: CGPoint
        switch panel {
        case .command:
            origin = CGPoint(x: screen.minX + 36, y: screen.maxY - size.height - 72)
        case .inspector:
            origin = CGPoint(x: screen.maxX - size.width - 44, y: screen.maxY - size.height - 88)
        case .forces:
            origin = CGPoint(x: screen.maxX - size.width - 72, y: screen.minY + 68)
        case .log:
            origin = CGPoint(x: screen.minX + 64, y: screen.minY + 74)
        }
        return CGRect(origin: origin, size: size)
    }
}

private extension DZWPlayableBattlePanel {
    var defaultSize: CGSize {
        switch self {
        case .command:
            return CGSize(width: 780, height: 700)
        case .inspector:
            return CGSize(width: 320, height: 540)
        case .forces:
            return CGSize(width: 360, height: 560)
        case .log:
            return CGSize(width: 380, height: 460)
        }
    }

    var minimumSize: CGSize {
        switch self {
        case .command:
            return CGSize(width: 600, height: 420)
        case .inspector:
            return CGSize(width: 300, height: 360)
        case .forces:
            return CGSize(width: 320, height: 360)
        case .log:
            return CGSize(width: 320, height: 300)
        }
    }

    var scrollIdentifier: String {
        switch self {
        case .command:
            return "battle-sidebar-scroll"
        case .inspector:
            return "battle-inspector-scroll"
        case .forces:
            return "battle-forces-scroll"
        case .log:
            return "battle-log-scroll"
        }
    }

    var buttonCoachID: FirstBattleButtonCoachID {
        switch self {
        case .command:
            return .commandPanel
        case .inspector:
            return .inspectorPanel
        case .forces:
            return .forcesPanel
        case .log:
            return .logPanel
        }
    }
}

private enum FirstBattleButtonCoachPopoverPlacement {
    case above
    case below

    var anchor: PopoverAttachmentAnchor {
        .rect(.bounds)
    }

    var arrowEdge: Edge {
        switch self {
        case .above:
            return .bottom
        case .below:
            return .top
        }
    }
}

private struct FirstBattleButtonCoachFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if !next.isEmpty {
            value = next
        }
    }
}

private struct FirstBattleButtonCoachWindowReader: NSViewRepresentable {
    @Binding var windowSize: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        updateWindowSize(from: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        updateWindowSize(from: nsView)
    }

    private func updateWindowSize(from view: NSView) {
        let sizeBinding = $windowSize
        DispatchQueue.main.async {
            guard let window = view.window else {
                return
            }
            let size = window.contentView?.bounds.size ?? window.frame.size
            if sizeBinding.wrappedValue != size {
                sizeBinding.wrappedValue = size
            }
        }
    }
}

private struct FirstBattleButtonCoachDialog: View {
    let tip: FirstBattleButtonCoachTip

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(tip.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
            Text(tip.body)
                .font(.system(size: 12, weight: .medium))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 270, alignment: .leading)
        .foregroundStyle(Color(red: 0.14, green: 0.10, blue: 0.07))
        .background(Color(red: 0.98, green: 0.96, blue: 0.88))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(tip.accessibilityIdentifier)
    }
}

private struct FirstBattleButtonCoachModifier: ViewModifier {
    let id: FirstBattleButtonCoachID
    let showsCoach: Bool
    let progress: FirstBattleButtonCoachProgress
    let completedFirstGame: Bool

    @State private var isAnchorHovering = false
    @State private var isDialogHovering = false
    @State private var isPopoverPresented = false
    @State private var hoverRevision = 0
    @State private var buttonFrame: CGRect = .zero
    @State private var windowSize: CGSize = .zero

    private let dialogHeightEstimate: CGFloat = 120
    private let edgePadding: CGFloat = 20
    private let presentationDelay: Duration = .milliseconds(180)
    private let dismissalDelay: Duration = .milliseconds(650)

    private var tip: FirstBattleButtonCoachTip? {
        GuderianTutorialCatalog.firstBattleButtonCoachTip(for: id)
    }

    private var canPresent: Bool {
        showsCoach &&
            completedFirstGame == false &&
            progress.shouldPresent(id) &&
            tip != nil
    }

    private var placement: FirstBattleButtonCoachPopoverPlacement {
        let size = windowSize == .zero
            ? (NSScreen.main?.visibleFrame.size ?? CGSize(width: 1440, height: 900))
            : windowSize
        let availableAbove = buttonFrame.minY - edgePadding
        let availableBelow = size.height - buttonFrame.maxY - edgePadding

        if availableAbove >= dialogHeightEstimate || availableAbove >= availableBelow {
            return .above
        }
        return .below
    }

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: FirstBattleButtonCoachFrameKey.self,
                                value: proxy.frame(in: .global)
                            )
                    }
                    FirstBattleButtonCoachWindowReader(windowSize: $windowSize)
                        .frame(width: 0, height: 0)
                }
            )
            .onPreferenceChange(FirstBattleButtonCoachFrameKey.self) { frame in
                buttonFrame = frame
            }
            .onHover { hovering in
                setAnchorHovering(hovering)
            }
            .onChange(of: canPresent) { _, canPresent in
                if !canPresent {
                    dismissImmediately()
                }
            }
            .popover(
                isPresented: Binding(
                    get: { isPopoverPresented && canPresent },
                    set: { presented in
                        if presented {
                            presentAfterHoverSettles()
                        } else {
                            dismissImmediately()
                        }
                    }
                ),
                attachmentAnchor: placement.anchor,
                arrowEdge: placement.arrowEdge
            ) {
                if let tip {
                    FirstBattleButtonCoachDialog(tip: tip)
                        .onHover { hovering in
                            setDialogHovering(hovering)
                        }
                }
            }
    }

    private var isHoveringCoachSurface: Bool {
        isAnchorHovering || isDialogHovering
    }

    private func setAnchorHovering(_ hovering: Bool) {
        guard canPresent else {
            dismissImmediately()
            return
        }

        isAnchorHovering = hovering
        if hovering {
            presentAfterHoverSettles()
        } else {
            dismissAfterGracePeriod()
        }
    }

    private func setDialogHovering(_ hovering: Bool) {
        guard canPresent else {
            dismissImmediately()
            return
        }

        isDialogHovering = hovering
        if hovering {
            presentImmediately()
        } else {
            dismissAfterGracePeriod()
        }
    }

    private func presentAfterHoverSettles() {
        hoverRevision += 1
        let revision = hoverRevision

        Task { @MainActor in
            do {
                try await Task.sleep(for: presentationDelay)
            } catch {
                return
            }
            guard hoverRevision == revision,
                  canPresent,
                  isHoveringCoachSurface else {
                return
            }
            isPopoverPresented = true
        }
    }

    private func presentImmediately() {
        hoverRevision += 1
        isPopoverPresented = true
    }

    private func dismissAfterGracePeriod() {
        hoverRevision += 1
        let revision = hoverRevision

        Task { @MainActor in
            do {
                try await Task.sleep(for: dismissalDelay)
            } catch {
                return
            }
            guard hoverRevision == revision,
                  !isHoveringCoachSurface else {
                return
            }
            isPopoverPresented = false
        }
    }

    private func dismissImmediately() {
        hoverRevision += 1
        isAnchorHovering = false
        isDialogHovering = false
        isPopoverPresented = false
    }
}

private extension View {
    func firstBattleButtonCoach(
        _ id: FirstBattleButtonCoachID,
        showsCoach: Bool,
        progress: FirstBattleButtonCoachProgress,
        completedFirstGame: Bool
    ) -> some View {
        modifier(FirstBattleButtonCoachModifier(
            id: id,
            showsCoach: showsCoach,
            progress: progress,
            completedFirstGame: completedFirstGame
        ))
    }
}

private struct DZWPlayableBattlePanelWindow: View {
    let panel: DZWPlayableBattlePanel
    @ObservedObject var model: DZWPlayableBattleViewModel
    @Binding var assaultAdvance: Bool
    @Binding var firstBattleButtonCoachProgress: FirstBattleButtonCoachProgress
    @Binding var firstBattleButtonCoachCompleted: Bool
    let showsFirstBattleButtonCoach: Bool
    let onCompletion: (DZWPlayableCompletionRecord) -> Void

    private var buttonCoachShows: Bool {
        showsFirstBattleButtonCoach && !firstBattleButtonCoachCompleted
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            if let snapshot = model.snapshot {
                VStack(alignment: .leading, spacing: 14) {
                    content(snapshot)
                }
                .foregroundStyle(Color(red: 0.15, green: 0.12, blue: 0.08))
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ContentUnavailableView(
                    "Battle board unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(model.lastError)
                )
                .padding(18)
            }
        }
        .accessibilityIdentifier(panel.scrollIdentifier)
        .frame(minWidth: panel.minimumSize.width, minHeight: panel.minimumSize.height)
        .background(Color(red: 0.96, green: 0.93, blue: 0.84))
    }

    private func markButtonCoachUsed(_ id: FirstBattleButtonCoachID) {
        firstBattleButtonCoachProgress.recordUse(id)
    }

    private func completeFirstBattleButtonCoach() {
        guard showsFirstBattleButtonCoach else {
            return
        }
        firstBattleButtonCoachProgress.completeFirstGame()
        firstBattleButtonCoachCompleted = true
    }

    private func recordCompletion(_ record: DZWPlayableCompletionRecord) {
        completeFirstBattleButtonCoach()
        onCompletion(record)
    }

    @ViewBuilder
    private func content(_ snapshot: NativeBoardSnapshot) -> some View {
        switch panel {
        case .command:
            header(snapshot)
            orderPanelSection(snapshot)
            movementPreviewSection(snapshot)
            shootingSection(snapshot)
            vehicleStatusSection(snapshot)
            closeQuartersSection(snapshot)
            guderianAISection(snapshot)
            opposingAISection(snapshot)
            orderDiceTuningSection()
            actionsSection(snapshot)
            resultSection(snapshot)
        case .inspector:
            selectionSection(snapshot)
            objectivesSection(snapshot)
        case .forces:
            armiesSection(snapshot)
            aiTurnSection()
        case .log:
            logSection(snapshot)
        }
    }

    private func header(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .accessibilityIdentifier("battle-title")
                Text(model.nativeScenarioLabel)
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.55, green: 0.39, blue: 0.12))
                Text("Turn \(snapshot.turnNumber) | \(snapshot.orderDice.current.map { model.sideTitle(for: $0.owner) } ?? "No die drawn") | \(snapshot.phase.rawValue)")
                    .font(.headline)
                    .accessibilityIdentifier("battle-phase-label")
                    .firstBattleButtonCoach(
                        .phaseStatus,
                        showsCoach: buttonCoachShows,
                        progress: firstBattleButtonCoachProgress,
                        completedFirstGame: firstBattleButtonCoachCompleted
                    )
                Text("\(snapshot.mission.name) | \(model.sideTitle(for: .player)) \(snapshot.mission.playerScore) - \(snapshot.mission.opponentScore) \(model.sideTitle(for: .guderianAI))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.55, green: 0.39, blue: 0.12))
                Text(snapshot.mission.winner == .none ? "Native battle in progress" : "\(model.sideTitle(for: snapshot.mission.winner)) controls the scenario")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    markButtonCoachUsed(.autoStep)
                    model.runAutomatedActiveStep()
                } label: {
                    Label("Auto Step", systemImage: "play.fill")
                }
                .disabled(model.isBattleOver)
                .firstBattleButtonCoach(
                    .autoStep,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.germanTurn)
                    model.runGermanTurn()
                } label: {
                    Label(model.aiTurnButtonTitle, systemImage: "forward.frame.fill")
                }
                .disabled(model.isBattleOver)
                .accessibilityIdentifier("german-turn-button")
                .firstBattleButtonCoach(
                    .germanTurn,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.playToEnd)
                    if let record = model.playBattleToEnd() {
                        recordCompletion(record)
                    }
                } label: {
                    Label("Play To End", systemImage: "forward.end.alt.fill")
                }
                .disabled(model.hasCompletion)
                .accessibilityIdentifier("play-to-end-button")
                .firstBattleButtonCoach(
                    .playToEnd,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.nextPhase)
                    model.drawOrderDie()
                } label: {
                    Label("Draw Die", systemImage: "die.face.5.fill")
                }
                .disabled(!model.canDrawOrderDie)
                .accessibilityIdentifier("next-phase-button")
                .firstBattleButtonCoach(
                    .nextPhase,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.debrief)
                    if let record = model.completeBattle() {
                        recordCompletion(record)
                    }
                } label: {
                    Label("Debrief", systemImage: "flag.checkered")
                }
                .disabled(model.hasCompletion)
                .accessibilityIdentifier("battle-debrief-button")
                .firstBattleButtonCoach(
                    .debrief,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.restart)
                    model.restartBattle()
                } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                }
                .accessibilityIdentifier("battle-restart-button")
                .firstBattleButtonCoach(
                    .restart,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.45)))
    }

    private func selectionSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selection")
                .font(.headline)
            if let selected = snapshot.selectedUnit {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selected.name)
                        .font(.title3.weight(.bold))
                    Text("\(model.sideTitle(for: selected.owner)) | \(selected.roleLine)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Wounds \(selected.totalWoundsRemaining) | \(selected.inCover ? "Cover" : "Open") | \(selected.hullDown ? "Hull-down" : "Exposed")")
                        .font(.caption.monospaced())
                    orderInspectorSummary(for: selected)
                    Text(selected.historicalNote.isEmpty ? "Engine unit: \(selected.engineName)" : selected.historicalNote)
                        .font(.caption.monospaced())
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("battle-selected-unit-summary")
                .firstBattleButtonCoach(
                    selected.owner == model.humanPlayer ? .boardUnitMovement : .boardEnemyTargeting,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            } else {
                Text("No unit selected")
                    .foregroundStyle(.secondary)
            }

            if let target = snapshot.selectedTarget {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Target", systemImage: "scope")
                        .font(.caption.weight(.bold))
                    Text(target.name)
                        .font(.subheadline.weight(.bold))
                    Text("\(model.sideTitle(for: target.owner)) | \(target.roleLine)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.35)))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("battle-selected-target-summary")
                .firstBattleButtonCoach(
                    .boardEnemyTargeting,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            } else {
                Text("No target selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("battle-selected-target-summary")
                    .firstBattleButtonCoach(
                        .boardEnemyTargeting,
                        showsCoach: buttonCoachShows,
                        progress: firstBattleButtonCoachProgress,
                        completedFirstGame: firstBattleButtonCoachCompleted
                    )
            }

            HStack {
                Button("Prev Ready") {
                    markButtonCoachUsed(.previousReady)
                    model.cycleActiveUnit(forward: false)
                }
                .accessibilityIdentifier("prev-ready-button")
                .firstBattleButtonCoach(
                    .previousReady,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                Button("Next Ready") {
                    markButtonCoachUsed(.nextReady)
                    model.cycleActiveUnit(forward: true)
                }
                .accessibilityIdentifier("next-ready-button")
                .firstBattleButtonCoach(
                    .nextReady,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .disabled(!model.canIssueHumanOrders)
            HStack {
                Button("Nearest Enemy") {
                    markButtonCoachUsed(.nearestEnemy)
                    model.selectNearestEnemy()
                }
                .accessibilityIdentifier("nearest-enemy-button")
                .firstBattleButtonCoach(
                    .nearestEnemy,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                Button("Clear") {
                    markButtonCoachUsed(.clearSelection)
                    model.clearSelection()
                }
                .accessibilityIdentifier("clear-selection-button")
                .firstBattleButtonCoach(
                    .clearSelection,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .disabled(!model.canIssueHumanOrders)
        }
        .buttonStyle(.bordered)
    }

    private func orderPanelSection(_ snapshot: NativeBoardSnapshot) -> some View {
        let state = model.commandPanelState(for: snapshot)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Order Dice")
                .font(.headline)
            orderDiceBagSection(snapshot)
            Text("Drawn side: \(state.drawnSideTitle)")
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("order-drawn-side")
            Text(state.canHumanControlDrawnDie ? "\(state.humanSideTitle) can act from this draw." : "Waiting for a \(state.humanSideTitle) die.")
                .font(.caption.weight(.semibold))
                .foregroundStyle(state.canHumanControlDrawnDie ? .green : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Eligible units")
                    .font(.caption.weight(.bold))
                ForEach(Array(state.eligibleUnitNames.prefix(5).enumerated()), id: \.offset) { _, name in
                    Text(name)
                        .font(.caption2.monospaced())
                        .lineLimit(1)
                }
            }
            .accessibilityIdentifier("order-eligible-units-list")

            if let selectedName = state.selectedUnitName {
                Text("Selected order unit: \(selectedName)")
                    .font(.caption.weight(.semibold))
            }

            HStack(spacing: 6) {
                ForEach(state.orderPickerOptions, id: \.self) { order in
                    Button {
                        model.issueOrder(order)
                    } label: {
                        Text(order.rawValue)
                    }
                    .disabled(!state.canHumanControlDrawnDie || snapshot.selectedUnit?.owner != model.humanPlayer)
                    .accessibilityIdentifier("order-picker-\(order.rawValue.lowercased())")
                }
            }
            .accessibilityIdentifier("order-picker")

            Text(state.orderTestResultSummary)
                .font(.caption)
                .accessibilityIdentifier("order-test-result")
            Text(state.actionExecutionSummary)
                .font(.caption)
                .accessibilityIdentifier("order-action-execution")
            Text(state.turnEndStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("order-turn-end-status")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.45)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("order-dice-command-panel")
        .buttonStyle(.bordered)
    }

    private func orderDiceBagSection(_ snapshot: NativeBoardSnapshot) -> some View {
        let bag = model.orderDiceBagState(for: snapshot)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Label("Dice Bag", systemImage: "die.face.5.fill")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Button {
                    model.drawOrderDie()
                } label: {
                    Label(bag.drawButtonTitle, systemImage: "hand.draw.fill")
                }
                .disabled(!bag.canDrawOrderDie)
                .accessibilityIdentifier("order-dice-bag-draw-button")
            }

            Text("Current die: \(bag.currentSideTitle)")
                .font(.caption.weight(.semibold))
                .accessibilityIdentifier("order-dice-current-die")
            Text(bag.instruction)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(bag.sides) { side in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(side.id == .guderianAI ? Color(red: 0.72, green: 0.22, blue: 0.16) : Color(red: 0.14, green: 0.33, blue: 0.73))
                                .frame(width: 10, height: 10)
                            Text(side.title)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            if side.isCurrent {
                                Text("drawn")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Color(red: 0.48, green: 0.08, blue: 0.06))
                            }
                        }
                        Text("Bag \(side.remaining) | Spent \(side.spent) | Held \(side.retained)")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .padding(7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(side.isCurrent ? Color.white.opacity(0.72) : Color.white.opacity(0.34)))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(side.isCurrent ? Color(red: 0.48, green: 0.08, blue: 0.06) : Color.black.opacity(0.08), lineWidth: side.isCurrent ? 2 : 1))
                    .accessibilityIdentifier(side.isHumanControlled ? "order-dice-selected-side-dice" : "order-dice-opposing-side-dice")
                }
            }

            Text("Remaining \(bag.remainingTotal) | Spent \(bag.spentTotal) | Retained \(bag.retainedTotal)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("order-dice-spent-dice")
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.38)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("order-dice-bag-panel")
    }

    private func movementPreviewSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Movement")
                .font(.headline)
            if let preview = model.movementPreviewState(for: snapshot) {
                Text("Advance \(Self.distance(preview.advanceMoveAllowance))")
                    .font(.caption.monospaced())
                    .accessibilityIdentifier("advance-move-preview")
                Text("Run \(Self.distance(preview.runMoveAllowance))")
                    .font(.caption.monospaced())
                    .accessibilityIdentifier("run-move-preview")
                Text("Current order allowance \(Self.distance(preview.currentOrderMoveAllowance))")
                    .font(.caption.monospaced())
                Text("Reverse \(Self.distance(preview.reverseMoveAllowance))\(preview.canReverseNow ? "" : " unavailable")")
                    .font(.caption.monospaced())
                Text("Pivot \(preview.pivotCountUsed)/\(preview.pivotBudget)")
                    .font(.caption.monospaced())
                    .accessibilityIdentifier("vehicle-pivot-budget")
                Text(preview.movementRejectionReason.isEmpty ? "No movement rejection currently shown." : preview.movementRejectionReason)
                    .font(.caption)
                    .foregroundStyle(preview.movementRejectionReason.isEmpty ? Color.secondary : Color.orange)
                    .accessibilityIdentifier("movement-rejection-reason")
                Text(preview.roadRoughObstacleMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Select a unit to preview Advance and Run movement.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.38)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("order-movement-preview")
    }

    private func shootingSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shooting")
                .font(.headline)
            if let state = model.shootingState(for: snapshot) {
                Text(state.fireChoiceSummary)
                    .font(.caption)
                    .accessibilityIdentifier("fire-shooting-choice")
                Text(state.advanceChoiceSummary)
                    .font(.caption)
                    .accessibilityIdentifier("advance-shooting-choice")
                Text(state.targetReactionSummary)
                    .font(.caption)
                    .accessibilityIdentifier("target-reaction-summary")
                Text(state.hitModifierBreakdown)
                    .font(.caption.monospaced())
                    .accessibilityIdentifier("hit-modifier-breakdown")
                Text(state.pinEffectSummary)
                    .font(.caption)
                    .accessibilityIdentifier("pin-effect-summary")
                Text("\(state.damageSummary) \(state.moraleSummary)")
                    .font(.caption)
                    .accessibilityIdentifier("damage-morale-summary")
                Text(state.battleLogSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("shooting-log-summary")
            } else {
                Text("Select a unit to inspect Fire and Advance shooting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.38)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("order-shooting-panel")
    }

    private func vehicleStatusSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vehicle")
                .font(.headline)
            if let state = model.vehicleState(for: snapshot) {
                Text(state.armourFacingSummary)
                    .font(.caption.monospaced())
                    .accessibilityIdentifier("vehicle-armour-facing")
                Text(state.penetrationModifierSummary)
                    .font(.caption.monospaced())
                    .accessibilityIdentifier("vehicle-penetration-modifiers")
                Text(state.damageStateSummary)
                    .font(.caption)
                    .accessibilityIdentifier("vehicle-damage-state")
                Text(state.wreckMarkerSummary)
                    .font(.caption)
                    .accessibilityIdentifier("vehicle-wreck-marker")
                Text(state.downTransitionSummary)
                    .font(.caption)
                    .accessibilityIdentifier("vehicle-down-transition")
            } else {
                Text("No vehicle or assault-gun counter is visible in this battle.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.38)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("vehicle-status-panel")
    }

    private func closeQuartersSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Close Quarters")
                .font(.headline)
            if let state = model.closeQuartersState(for: snapshot) {
                Text(state.runOrderAssaultSummary)
                    .font(.caption)
                    .accessibilityIdentifier("run-order-assault-flow")
                Text(state.targetReactionSummary)
                    .font(.caption)
                    .accessibilityIdentifier("assault-target-reaction")
                Text(state.roundResultsSummary)
                    .font(.caption)
                    .accessibilityIdentifier("assault-round-results")
                Text(state.loserDestructionSummary)
                    .font(.caption)
                    .accessibilityIdentifier("assault-loser-destruction")
                Text(state.regroupLogSummary)
                    .font(.caption)
                    .accessibilityIdentifier("assault-regroup-log")
            } else {
                Text("Select a unit to inspect Run-order assault flow.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.38)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("close-quarters-panel")
    }

    private func guderianAISection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Guderian AI")
                .font(.headline)
            if let state = model.guderianAIDecisionState(for: snapshot) {
                Text("Drawn unit: \(state.chosenUnitName)")
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier("ai-drawn-die-unit")
                Text("Order: \(state.chosenOrder.rawValue)")
                    .font(.caption)
                    .accessibilityIdentifier("ai-order-choice")
                Text("Target: \(state.objectiveOrTargetName)")
                    .font(.caption)
                    .accessibilityIdentifier("ai-objective-target")
                Text(state.pathSummary)
                    .font(.caption)
                    .accessibilityIdentifier("ai-path-summary")
                Text(state.failedOrderTestPlan)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("ai-failed-order-test-handling")
            } else {
                Text("No Guderian-command order-dice activation is currently available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.38)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("guderian-order-ai-panel")
    }

    private func opposingAISection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Opposing AI")
                .font(.headline)
            if let state = model.opposingAIDecisionState(for: snapshot) {
                Text("\(state.armyFamily.rawValue) | \(state.behaviorProfile.rawValue)")
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier("opposing-ai-army-family")
                Text("Order: \(state.chosenOrder.rawValue) by \(state.chosenUnitName)")
                    .font(.caption)
                    .accessibilityIdentifier("opposing-ai-order-choice")
                Text(state.pathSummary)
                    .font(.caption)
                Text(model.standingOrderDecisionState(for: snapshot)?.reason ?? state.orderPrioritySummary)
                    .font(.caption)
                    .accessibilityIdentifier("opposing-ai-standing-order")
                Text(model.pinsMoraleAIState(for: snapshot)?.riskSummary ?? state.failedOrderTestPlan)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("opposing-ai-morale-risk")
                Text(model.targetReactionAIState(for: snapshot)?.opportunitySummary ?? "Target reaction AI is waiting for a selected attacker and target.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("target-reaction-ai-summary")
            } else {
                Text("No opposing-force order-dice activation is currently available.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.38)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("opposing-order-ai-panel")
    }

    private func orderDiceTuningSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scenario Tuning")
                .font(.headline)
            if let row = model.scenarioTuningState() {
                Text(row.theater.rawValue)
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier(tuningIdentifier(for: row.theater))
                Text("Turns \(row.targetTurnRange.lowerBound)-\(row.targetTurnRange.upperBound) | Activations \(row.targetActivationRange.lowerBound)-\(row.targetActivationRange.upperBound)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("order-dice-activation-tuning")
                Text(row.pinMoraleTuning)
                    .font(.caption)
                    .accessibilityIdentifier("order-dice-pin-morale-tuning")
                Text(row.movementTuning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("order-dice-movement-tuning")
                Text(row.combatTuning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("order-dice-combat-tuning")
            } else if let row = model.lateCareerTuningState() {
                Text("\(row.set.rawValue) | \(row.scope.rawValue)")
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier("late-career-order-dice-tuning")
                Text("Turns \(row.targetTurnRange.lowerBound)-\(row.targetTurnRange.upperBound) | Activations \(row.targetActivationRange.lowerBound)-\(row.targetActivationRange.upperBound)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("order-dice-activation-tuning")
                Text(row.caveatTuning)
                    .font(.caption)
                    .accessibilityIdentifier("order-dice-command-caveat-tuning")
                Text(row.movementTuning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("order-dice-movement-tuning")
                Text(row.combatTuning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("order-dice-combat-tuning")
            } else {
                Text("Late-career tuning enters in cycles 121-125.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let scoring = model.activationScoringState() {
                Divider()
                Text("Score Pacing")
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier("activation-aware-score-panel")
                Text(scoring.scoringSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("order-dice-score-pacing-tuning")
            }
            if let saveState = model.orderDiceSaveStateMigration() {
                Divider()
                Text("Save State")
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier("order-dice-save-state-migration")
                Text(saveState.migrationNote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(saveState.legacyCompatibilityNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let debriefCopy = model.orderDiceDebriefCopyState() {
                Divider()
                Text("Debrief Copy")
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier("activation-first-debrief-copy")
                Text(debriefCopy.activationSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(debriefCopy.persistenceSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let turnEnd = model.orderDiceTurnEndPersistenceState() {
                Divider()
                Text("Turn End")
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier("order-dice-turn-end-persistence")
                Text(turnEnd.turnEndSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(turnEnd.retainedOrderPolicy)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if let harness = model.orderDiceFullHarnessState() {
                Divider()
                Text("Replay")
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier("order-dice-replay-signature")
                Text(harness.replaySignature)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text(harness.harnessSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("order-dice-full-harness-report")
            }
            if let audit = model.orderDiceBalanceAuditState() {
                Divider()
                Text("Phase Retirement")
                    .font(.caption.weight(.semibold))
                    .accessibilityIdentifier("stale-phase-surface-retirement")
                Text(audit.pacingSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(audit.improvementLevers.joined(separator: " "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Text("Monty Handoff")
                .font(.caption.weight(.semibold))
                .accessibilityIdentifier("monty-order-dice-api-handoff")
            Text(model.orderDiceMontyHandoffSummary())
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            Text("Build Matrix")
                .font(.caption.weight(.semibold))
                .accessibilityIdentifier("order-dice-build-matrix")
            Text(model.orderDiceBuildMatrixSummary())
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            Text("Cleanup")
                .font(.caption.weight(.semibold))
                .accessibilityIdentifier("legacy-phase-compatibility-quarantine")
            Text(model.orderDiceMigrationCleanupSummary())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("Final acceptance closes the order-dice migration with zero remaining Guderian cycles.")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("order-dice-final-acceptance")
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.38)))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("order-dice-scenario-tuning-panel")
    }

    private func tuningIdentifier(for theater: GuderianOrderDiceScenarioTuningTheater) -> String {
        switch theater {
        case .poland:
            return "poland-order-dice-tuning"
        case .france:
            return "france-order-dice-tuning"
        case .easternFront:
            return "eastern-front-order-dice-tuning"
        }
    }

    private func orderInspectorSummary(for unit: NativeBoardUnitSnapshot) -> some View {
        let state = model.inspectorState(for: unit)
        return VStack(alignment: .leading, spacing: 2) {
            Text("Order \(state.currentOrderLabel) | \(state.moraleQuality) | Pins \(state.pinCount)")
                .font(.caption.monospaced())
            Text("\(state.actedState) | \(state.downDetails) | \(state.ambushDetails)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
            Text(state.fubarSummary)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("order-inspector-summary")
    }

    private static func distance(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func actionsSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions")
                .font(.headline)

            HStack {
                Button {
                    markButtonCoachUsed(.rotateLeft)
                    model.rotateSelected(by: -45)
                } label: {
                    Label("Rotate -45", systemImage: "rotate.left")
                }
                .accessibilityIdentifier("rotate-left-button")
                .firstBattleButtonCoach(
                    .rotateLeft,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                Button {
                    markButtonCoachUsed(.rotateRight)
                    model.rotateSelected(by: 45)
                } label: {
                    Label("Rotate +45", systemImage: "rotate.right")
                }
                .accessibilityIdentifier("rotate-right-button")
                .firstBattleButtonCoach(
                    .rotateRight,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer)

            HStack {
                Toggle("Manual Cover", isOn: Binding(
                    get: { snapshot.selectedUnit?.inCover ?? false },
                    set: {
                        markButtonCoachUsed(.manualCover)
                        model.toggleCover($0)
                    }
                ))
                .firstBattleButtonCoach(
                    .manualCover,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                Toggle("Hull Down", isOn: Binding(
                    get: { snapshot.selectedUnit?.hullDown ?? false },
                    set: {
                        markButtonCoachUsed(.hullDown)
                        model.toggleHullDown($0)
                    }
                ))
                .firstBattleButtonCoach(
                    .hullDown,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .font(.caption.weight(.semibold))
            .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer)

            Button {
                markButtonCoachUsed(.shootTarget)
                model.shootSelected()
            } label: {
                Label("Shoot Target", systemImage: "scope")
            }
            .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer || snapshot.selectedUnit?.canShootNow != true || snapshot.selectedTarget == nil)
            .accessibilityIdentifier("shoot-target-button")
            .firstBattleButtonCoach(
                .shootTarget,
                showsCoach: buttonCoachShows,
                progress: firstBattleButtonCoachProgress,
                completedFirstGame: firstBattleButtonCoachCompleted
            )

            Toggle("Assault follow-up advances", isOn: Binding(
                get: { assaultAdvance },
                set: {
                    markButtonCoachUsed(.assaultFollowUp)
                    assaultAdvance = $0
                }
            ))
                .font(.caption.weight(.semibold))
                .firstBattleButtonCoach(
                    .assaultFollowUp,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                .disabled(!model.canResolveHumanActivation)

            Button {
                markButtonCoachUsed(.assaultTarget)
                model.assaultSelected(advance: assaultAdvance)
            } label: {
                Label("Assault Target", systemImage: "figure.run")
            }
            .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer || snapshot.selectedUnit?.canAssaultNow != true || snapshot.selectedTarget == nil)
            .accessibilityIdentifier("assault-target-button")
            .firstBattleButtonCoach(
                .assaultTarget,
                showsCoach: buttonCoachShows,
                progress: firstBattleButtonCoachProgress,
                completedFirstGame: firstBattleButtonCoachCompleted
            )

            Button {
                markButtonCoachUsed(.resolvePending)
                model.resolvePendingChoice()
            } label: {
                Label("Resolve Pending", systemImage: "checkmark.circle")
            }
            .disabled(!model.canResolveHumanActivation)
            .accessibilityIdentifier("resolve-pending-button")
            .firstBattleButtonCoach(
                .resolvePending,
                showsCoach: buttonCoachShows,
                progress: firstBattleButtonCoachProgress,
                completedFirstGame: firstBattleButtonCoachCompleted
            )

            Label(snapshot.lastAction.detail, systemImage: snapshot.lastAction.status == .blocked ? "exclamationmark.triangle" : "checkmark.circle")
                .font(.caption)
                .foregroundStyle(snapshot.lastAction.status == .blocked ? .orange : .secondary)
                .accessibilityIdentifier("battle-action-feedback")
                .firstBattleButtonCoach(
                    .actionFeedback,
                    showsCoach: buttonCoachShows,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
        }
        .buttonStyle(.bordered)
    }

    private func resultSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Result")
                .font(.headline)

            if let completion = model.completion {
                Label(completion.victoryBandLabel, systemImage: "rosette")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
                Text("\(completion.score) VP | turn \(completion.completedTurn)")
                    .font(.caption.monospaced())
                Text(completion.sourceName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let playableTestGameResult = model.playableTestGameResult {
                    Text("\(playableTestGameResult.antiGuderianStepCount) default-side steps | \(playableTestGameResult.germanStepCount) Guderian-command steps")
                        .font(.caption.monospaced())
                        .foregroundStyle(playableTestGameResult.completedToEnd ? .green : .orange)
                    Text(playableTestGameResult.summary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Text(completion.debriefSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
                Text("Persisted to campaign progress.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("battle-persisted-result")
            } else if let debriefError = model.debriefError {
                Label(debriefError, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if snapshot.mission.winner != .none {
                Label("\(model.sideTitle(for: snapshot.mission.winner)) has reached the scenario result.", systemImage: "flag.checkered")
                    .font(.caption)
                    .foregroundStyle(snapshot.mission.winner == model.humanPlayer ? .green : .orange)
            } else {
                Text("No debrief recorded yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.45)))
        .accessibilityIdentifier("battle-debrief-panel")
    }

    private func objectivesSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Objectives")
                .font(.headline)
            ForEach(snapshot.objectives) { objective in
                VStack(alignment: .leading, spacing: 2) {
                    Text(objective.name)
                        .font(.subheadline.weight(.bold))
                    Text("\(model.sideTitle(for: objective.controller)) | \(objective.playerPresence)-\(objective.opponentPresence)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.45)))
            }
        }
        .onAppear {
            model.recordTutorialTrigger(.objectiveInspection)
        }
    }

    private func armiesSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Matchup")
                .font(.headline)
            Text("Selected side: \(model.humanSideTitle). Opposing automation: \(model.aiSideTitle). Both forces use the same rules-backed board state.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach([NativeBoardPlayer.player, NativeBoardPlayer.guderianAI], id: \.self) { owner in
                let units = snapshot.units.filter { $0.owner == owner }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(model.sideTitle(for: owner))\(owner == model.humanPlayer ? " (you)" : " (AI)")")
                        .font(.subheadline.weight(.bold))
                    ForEach(units.prefix(8)) { unit in
                        Text("\(unit.name) | \(unit.role) | \(unit.totalWoundsRemaining) wounds")
                            .font(.caption.monospaced())
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.16), lineWidth: 1))
            }
        }
    }

    private func aiTurnSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.aiTurnSectionTitle)
                .font(.headline)
            ForEach(Array(model.aiTurnEvents.enumerated()), id: \.offset) { _, event in
                Text(event)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
    }

    private func logSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Battle Log")
                .font(.headline)
            ForEach(Array(snapshot.logLines.suffix(8).enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
    }
}

private struct FirstBattleTutorialHintView: View {
    let hint: TutorialHint
    let flow: TutorialFlow
    let isFinalHint: Bool
    @Binding var doNotShowAgain: Bool
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(hint.title)
                        .font(.headline.weight(.bold))
                        .accessibilityIdentifier("first-battle-tutorial-title")
                    Text("Hint \(hint.order) of \(flow.hints.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("first-battle-tutorial-progress")
                }
                Spacer()
                Button {
                    onSkip()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Hide tutorial hint")
                .accessibilityIdentifier("first-battle-tutorial-skip-button")
            }

            Text(hint.body)
                .font(.callout)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(hint.accessibilityIdentifier)

            if isFinalHint {
                Toggle(flow.doNotShowAgainLabel, isOn: $doNotShowAgain)
                    .toggleStyle(.checkbox)
                    .accessibilityIdentifier("first-battle-tutorial-do-not-show-again")
            }

            HStack {
                Spacer()
                Button {
                    onNext()
                } label: {
                    Label(isFinalHint ? "Finish" : "Next", systemImage: isFinalHint ? "checkmark" : "chevron.right")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(isFinalHint ? "first-battle-tutorial-finish-button" : "first-battle-tutorial-next-button")
            }
        }
        .padding(14)
        .frame(width: 360)
        .foregroundStyle(Color(red: 0.15, green: 0.12, blue: 0.08))
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.98, green: 0.96, blue: 0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.16), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("first-battle-tutorial-hint")
        .onAppear {
            dzwPlayableLog.info("First-battle tutorial hint appeared hint=\(hint.accessibilityIdentifier, privacy: .public) isFinal=\(isFinalHint, privacy: .public) doNotShowAgain=\(doNotShowAgain, privacy: .public)")
            logDZWWindowSnapshot("first-battle-tutorial-hint-appear")
        }
        .onDisappear {
            dzwPlayableLog.info("First-battle tutorial hint disappeared hint=\(hint.accessibilityIdentifier, privacy: .public)")
            logDZWWindowSnapshot("first-battle-tutorial-hint-disappear")
        }
    }
}

public struct DZWPlayableBattleView: View {
    @StateObject private var model: DZWPlayableBattleViewModel
    @StateObject private var panelWindows = DZWPlayableBattleWindowCoordinator()
    @State private var dragPreview: [Int: CGPoint] = [:]
    @State private var assaultAdvance = true
    @State private var battlefieldZoom: CGFloat = 1
    @State private var firstBattleTutorial = TutorialHintCoordinator()
    @State private var firstBattleTutorialDoNotShowAgain = false
    @State private var firstBattleButtonCoachProgress = FirstBattleButtonCoachProgress()
    @AppStorage("guderian.tutorial.firstBattleGuidance.v1.dismissed") private var firstBattleGuidanceDismissed = false
    @AppStorage("guderian.tutorial.firstBattleButtonCoach.v1.completed") private var firstBattleButtonCoachCompleted = false
    private let onCompletion: (DZWPlayableCompletionRecord) -> Void
    private let showsDefaultPanels: Bool
    private let showsTutorials: Bool
    private let isGuderianTestBacked: Bool
    private let guderianTestSyncToken: Int

    public init(
        scenario: GuderianScenario,
        chosenSideID: String = GuderianHistoricalSideSelectionResolver.defaultHumanSideID,
        showsDefaultPanels: Bool = true,
        showsTutorials: Bool = true,
        guderianTestController: GuderianTestFirstBattleRunController? = nil,
        guderianTestSyncToken: Int = 0,
        onCompletion: @escaping (CampaignCompletionRecord) -> Void = { _ in }
    ) {
        _model = StateObject(wrappedValue: DZWPlayableBattleViewModel(
            scenario: scenario,
            chosenSideID: chosenSideID,
            guderianTestController: guderianTestController
        ))
        self.showsDefaultPanels = showsDefaultPanels
        self.showsTutorials = showsTutorials
        isGuderianTestBacked = guderianTestController != nil
        self.guderianTestSyncToken = guderianTestSyncToken
        self.onCompletion = { record in
            if case .fieldCommand(let completionRecord) = record {
                onCompletion(completionRecord)
            }
        }
    }

    public init(
        lateCareerEntry: LateCareerGuderianPresentation,
        chosenSideID: String = GuderianHistoricalSideSelectionResolver.defaultHumanSideID,
        showsDefaultPanels: Bool = true,
        showsTutorials: Bool = true,
        onCompletion: @escaping (LateCareerCompletionRecord) -> Void = { _ in }
    ) {
        _model = StateObject(wrappedValue: DZWPlayableBattleViewModel(
            lateCareerEntry: lateCareerEntry,
            chosenSideID: chosenSideID
        ))
        self.showsDefaultPanels = showsDefaultPanels
        self.showsTutorials = showsTutorials
        isGuderianTestBacked = false
        guderianTestSyncToken = 0
        self.onCompletion = { record in
            if case .lateCareer(let completionRecord) = record {
                onCompletion(completionRecord)
            }
        }
    }

    public var body: some View {
        if let snapshot = model.snapshot {
            ZStack(alignment: .topLeading) {
                BattlefieldViewport(
                    zoom: $battlefieldZoom,
                    boardWidth: DZWPlayableBattleViewModel.boardWidth,
                    boardHeight: DZWPlayableBattleViewModel.boardHeight
                ) {
                    board(snapshot)
                }

                VStack {
                    battlefieldToolbar
                    Spacer()
                }
                .padding(18)
                .zIndex(10)

                if model.isPreparingHumanTurn {
                    VStack {
                        HStack {
                            Spacer()
                            openingTurnPreparationBadge
                        }
                        Spacer()
                    }
                    .padding(18)
                    .transition(.opacity)
                    .zIndex(15)
                }

                if let hint = activeFirstBattleHint {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            FirstBattleTutorialHintView(
                                hint: hint,
                                flow: firstBattleTutorialFlow,
                                isFinalHint: firstBattleTutorialFlow.isLastHint(hint),
                                doNotShowAgain: $firstBattleTutorialDoNotShowAgain,
                                onNext: advanceFirstBattleTutorial,
                                onSkip: skipFirstBattleTutorialHint
                            )
                        }
                    }
                    .padding(20)
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
            .background(GuderianAppPalette.battlefieldBackground)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("battle-screen")
            .onAppear {
                resetFirstBattleButtonCoachForUITestingIfNeeded()
                model.syncFromGuderianTestController(context: "on-appear")
                dzwPlayableLog.info("Battle view appeared title=\(model.title, privacy: .public) tutorialEligible=\(model.isFirstBattleTutorialEligible, privacy: .public) firstBattleDismissed=\(firstBattleGuidanceDismissed, privacy: .public) showsDefaultPanels=\(showsDefaultPanels, privacy: .public) showsTutorials=\(showsTutorials, privacy: .public)")
                logDZWWindowSnapshot("dzw-battle-on-appear-before-panels")
                if showsDefaultPanels {
                    panelWindows.showDefaults(
                        model: model,
                        assaultAdvance: $assaultAdvance,
                        firstBattleButtonCoachProgress: $firstBattleButtonCoachProgress,
                        firstBattleButtonCoachCompleted: $firstBattleButtonCoachCompleted,
                        showsFirstBattleButtonCoach: showsFirstBattleButtonCoach,
                        onCompletion: onCompletion
                    )
                    dzwPlayableLog.info("Battle view default panels requested visible=\(panelWindows.visiblePanels.map(\.rawValue).sorted().joined(separator: ","), privacy: .public)")
                } else {
                    dzwPlayableLog.info("Battle view default panels suppressed by automation presentation options.")
                }
                recordFirstBattleTutorialTrigger(.battleOpened)
                recordFirstBattleTutorialTrigger(.boardVisible)
                logDZWWindowSnapshot("dzw-battle-on-appear-after-panels")
            }
            .task(id: model.openingTurnPreparationGeneration) {
                await model.prepareOpeningHumanTurnIfNeeded()
            }
            .onChange(of: model.tutorialEventCount) { _, _ in
                if let trigger = model.latestTutorialTrigger {
                    dzwPlayableLog.info("Battle view observed tutorial trigger event trigger=\(trigger.rawValue, privacy: .public) count=\(model.tutorialEventCount, privacy: .public)")
                    recordFirstBattleTutorialTrigger(trigger)
                }
            }
            .onChange(of: model.hasCompletion) { _, hasCompletion in
                if hasCompletion {
                    completeFirstBattleButtonCoach()
                }
            }
            .onChange(of: guderianTestSyncToken) { _, syncToken in
                model.syncFromGuderianTestController(context: "guderian-test-sync-\(syncToken)")
            }
            .onDisappear {
                dzwPlayableLog.info("Battle view disappeared title=\(model.title, privacy: .public) visiblePanels=\(panelWindows.visiblePanels.map(\.rawValue).sorted().joined(separator: ","), privacy: .public)")
                logDZWWindowSnapshot("dzw-battle-on-disappear-before-close")
                panelWindows.closeAll()
                logDZWWindowSnapshot("dzw-battle-on-disappear-after-close")
            }
        } else {
            ContentUnavailableView(
                "Battle board unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(model.lastError)
            )
        }
    }

    private var firstBattleTutorialFlow: TutorialFlow {
        GuderianTutorialCatalog.firstBattleGuidanceFlow
    }

    private var showsFirstBattleButtonCoach: Bool {
        showsTutorials &&
            !isGuderianTestBacked &&
            !firstBattleButtonCoachCompleted &&
            (!Self.isRunningUnderTests || Self.enablesButtonCoachUnderUITests)
    }

    private var showsFirstBattleTutorialGhosts: Bool {
        showsFirstBattleButtonCoach && model.isFirstBattleTutorialEligible
    }

    private var activeFirstBattleHint: TutorialHint? {
        guard showsTutorials,
              !Self.disablesFirstBattleGuidanceHintsUnderUITests,
              model.isFirstBattleTutorialEligible,
              !firstBattleGuidanceDismissed else {
            return nil
        }
        return firstBattleTutorial.activeHint(in: firstBattleTutorialFlow)
    }

    private func recordFirstBattleTutorialTrigger(_ trigger: TutorialTrigger) {
        guard showsTutorials else {
            dzwPlayableLog.info("First-battle tutorial trigger suppressed by automation presentation options trigger=\(trigger.rawValue, privacy: .public)")
            return
        }

        guard !Self.disablesFirstBattleGuidanceHintsUnderUITests else {
            dzwPlayableLog.info("First-battle tutorial trigger suppressed by UI test launch argument trigger=\(trigger.rawValue, privacy: .public)")
            return
        }

        guard model.isFirstBattleTutorialEligible else {
            dzwPlayableLog.debug("First-battle tutorial trigger ignored because battle is not eligible trigger=\(trigger.rawValue, privacy: .public)")
            return
        }

        guard !firstBattleGuidanceDismissed else {
            dzwPlayableLog.info("First-battle tutorial trigger ignored because tutorial is dismissed trigger=\(trigger.rawValue, privacy: .public)")
            return
        }
        firstBattleTutorial.record(trigger, in: firstBattleTutorialFlow)
        let activeHint = firstBattleTutorial.activeHint(in: firstBattleTutorialFlow)?.accessibilityIdentifier ?? "none"
        dzwPlayableLog.info("First-battle tutorial trigger recorded trigger=\(trigger.rawValue, privacy: .public) activeHint=\(activeHint, privacy: .public) completedHints=\(firstBattleTutorial.progress.completedHintCount(in: firstBattleTutorialFlow), privacy: .public)")
    }

    private func advanceFirstBattleTutorial() {
        guard let hint = activeFirstBattleHint else {
            dzwPlayableLog.info("First-battle tutorial advance requested with no active hint.")
            return
        }
        let isFinal = firstBattleTutorialFlow.isLastHint(hint)
        dzwPlayableLog.info("First-battle tutorial advance hint=\(hint.accessibilityIdentifier, privacy: .public) isFinal=\(isFinal, privacy: .public) doNotShowAgain=\(firstBattleTutorialDoNotShowAgain, privacy: .public)")
        firstBattleTutorial.completeActiveHint(in: firstBattleTutorialFlow)
        if isFinal {
            if firstBattleTutorialDoNotShowAgain {
                firstBattleGuidanceDismissed = true
            }
            firstBattleTutorial.dismiss(firstBattleTutorialFlow)
        }
        let activeHint = firstBattleTutorial.activeHint(in: firstBattleTutorialFlow)?.accessibilityIdentifier ?? "none"
        dzwPlayableLog.info("First-battle tutorial advanced activeHint=\(activeHint, privacy: .public) dismissed=\(firstBattleGuidanceDismissed, privacy: .public) completedHints=\(firstBattleTutorial.progress.completedHintCount(in: firstBattleTutorialFlow), privacy: .public)")
    }

    private func skipFirstBattleTutorialHint() {
        guard let hint = activeFirstBattleHint else {
            dzwPlayableLog.info("First-battle tutorial skip requested with no active hint.")
            return
        }
        dzwPlayableLog.info("First-battle tutorial skip hint=\(hint.accessibilityIdentifier, privacy: .public)")
        firstBattleTutorial.completeActiveHint(in: firstBattleTutorialFlow)
        let activeHint = firstBattleTutorial.activeHint(in: firstBattleTutorialFlow)?.accessibilityIdentifier ?? "none"
        dzwPlayableLog.info("First-battle tutorial skipped activeHint=\(activeHint, privacy: .public) completedHints=\(firstBattleTutorial.progress.completedHintCount(in: firstBattleTutorialFlow), privacy: .public)")
    }

    private func markButtonCoachUsed(_ id: FirstBattleButtonCoachID) {
        firstBattleButtonCoachProgress.recordUse(id)
    }

    private func resetFirstBattleButtonCoachForUITestingIfNeeded() {
        guard Self.resetsFirstBattleButtonCoachUnderUITests else {
            return
        }
        UserDefaults.standard.removeObject(forKey: GuderianTutorialCatalog.firstBattleButtonCoachStorageKey.rawValue)
        firstBattleButtonCoachProgress = FirstBattleButtonCoachProgress()
        firstBattleButtonCoachCompleted = false
    }

    private func completeFirstBattleButtonCoach() {
        guard showsFirstBattleButtonCoach else {
            return
        }
        guard !firstBattleButtonCoachCompleted else {
            return
        }
        firstBattleButtonCoachProgress.completeFirstGame()
        firstBattleButtonCoachCompleted = true
        dzwPlayableLog.info("First-battle button coach completed for future launches.")
    }

    private func recordCompletion(_ record: DZWPlayableCompletionRecord) {
        completeFirstBattleButtonCoach()
        onCompletion(record)
    }

    private static var isRunningUnderTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil ||
            environment["GUDERIAN_TEST_MODE"] != nil ||
            environment["GUDERIAN_UI_TESTING"] != nil
    }

    private static var enablesButtonCoachUnderUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("--guderian-ui-test-enable-button-coach")
    }

    private static var resetsFirstBattleButtonCoachUnderUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("--guderian-ui-test-reset-button-coach")
    }

    private static var disablesFirstBattleGuidanceHintsUnderUITests: Bool {
        ProcessInfo.processInfo.arguments.contains("--guderian-ui-test-disable-first-battle-hints")
    }

    private var battlefieldToolbar: some View {
        HStack(spacing: 10) {
            Label("Battlefield", systemImage: "map")
                .font(.system(size: 13, weight: .bold, design: .rounded))

            Button {
                markButtonCoachUsed(.zoomOut)
                adjustZoom(by: -0.15)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel("Zoom out")
            .firstBattleButtonCoach(
                .zoomOut,
                showsCoach: showsFirstBattleButtonCoach,
                progress: firstBattleButtonCoachProgress,
                completedFirstGame: firstBattleButtonCoachCompleted
            )

            Slider(value: zoomBinding, in: 0.6...2.2)
                .frame(width: 160)
                .accessibilityIdentifier("battlefield-zoom-slider")

            Text("\(Int((battlefieldZoom * 100).rounded()))%")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .frame(width: 44, alignment: .trailing)

            Button {
                markButtonCoachUsed(.resetZoom)
                battlefieldZoom = 1
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel("Reset zoom")
            .firstBattleButtonCoach(
                .resetZoom,
                showsCoach: showsFirstBattleButtonCoach,
                progress: firstBattleButtonCoachProgress,
                completedFirstGame: firstBattleButtonCoachCompleted
            )

            Divider()
                .frame(height: 24)

            ForEach(DZWPlayableBattlePanel.allCases) { panel in
                Button {
                    markButtonCoachUsed(panel.buttonCoachID)
                    toggle(panel)
                } label: {
                    Label(panel.title, systemImage: panel.systemImage)
                }
                .tint(panelWindows.visiblePanels.contains(panel) ? Color(red: 0.13, green: 0.32, blue: 0.67) : Color.black.opacity(0.32))
                .accessibilityIdentifier("toggle-\(panel.rawValue)-window")
                .firstBattleButtonCoach(
                    panel.buttonCoachID,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
        }
        .buttonStyle(.borderedProminent)
        .padding(10)
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.68))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 10)
    }

    private var openingTurnPreparationBadge: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Preparing \(model.humanSideTitle)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("battle-opening-turn-preparing")
    }

    private var zoomBinding: Binding<CGFloat> {
        Binding(
            get: { battlefieldZoom },
            set: { battlefieldZoom = clampedZoom($0) }
        )
    }

    private func toggle(_ panel: DZWPlayableBattlePanel) {
        panelWindows.toggle(
            panel,
            model: model,
            assaultAdvance: $assaultAdvance,
            firstBattleButtonCoachProgress: $firstBattleButtonCoachProgress,
            firstBattleButtonCoachCompleted: $firstBattleButtonCoachCompleted,
            showsFirstBattleButtonCoach: showsFirstBattleButtonCoach,
            onCompletion: onCompletion
        )
    }

    private func adjustZoom(by delta: CGFloat) {
        battlefieldZoom = clampedZoom(battlefieldZoom + delta)
    }

    private func clampedZoom(_ zoom: CGFloat) -> CGFloat {
        min(max(zoom, 0.6), 2.2)
    }

    private func header(_ snapshot: NativeBoardSnapshot) -> some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("battle-title")
                Text(model.nativeScenarioLabel)
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.92, green: 0.78, blue: 0.42))
                Text("Turn \(snapshot.turnNumber) | \(snapshot.orderDice.current.map { model.sideTitle(for: $0.owner) } ?? "No die drawn") | \(snapshot.phase.rawValue)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("battle-phase-label")
                    .firstBattleButtonCoach(
                        .phaseStatus,
                        showsCoach: showsFirstBattleButtonCoach,
                        progress: firstBattleButtonCoachProgress,
                        completedFirstGame: firstBattleButtonCoachCompleted
                    )
                Text("\(snapshot.mission.name) | \(model.sideTitle(for: .player)) \(snapshot.mission.playerScore) - \(snapshot.mission.opponentScore) \(model.sideTitle(for: .guderianAI))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.92, green: 0.78, blue: 0.42))
                Text(snapshot.mission.winner == .none ? "Native battle in progress" : "\(model.sideTitle(for: snapshot.mission.winner)) controls the scenario")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    markButtonCoachUsed(.autoStep)
                    model.runAutomatedActiveStep()
                } label: {
                    Label("Auto Step", systemImage: "play.fill")
                }
                .disabled(model.isBattleOver)
                .firstBattleButtonCoach(
                    .autoStep,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.germanTurn)
                    model.runGermanTurn()
                } label: {
                    Label(model.aiTurnButtonTitle, systemImage: "forward.frame.fill")
                }
                .disabled(model.isBattleOver)
                .accessibilityIdentifier("german-turn-button")
                .firstBattleButtonCoach(
                    .germanTurn,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.playToEnd)
                    if let record = model.playBattleToEnd() {
                        recordCompletion(record)
                    }
                } label: {
                    Label("Play To End", systemImage: "forward.end.alt.fill")
                }
                .disabled(model.hasCompletion)
                .accessibilityIdentifier("play-to-end-button")
                .firstBattleButtonCoach(
                    .playToEnd,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.nextPhase)
                    model.drawOrderDie()
                } label: {
                    Label("Draw Die", systemImage: "die.face.5.fill")
                }
                .disabled(!model.canDrawOrderDie)
                .accessibilityIdentifier("next-phase-button")
                .firstBattleButtonCoach(
                    .nextPhase,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.debrief)
                    if let record = model.completeBattle() {
                        recordCompletion(record)
                    }
                } label: {
                    Label("Debrief", systemImage: "flag.checkered")
                }
                .disabled(model.hasCompletion)
                .accessibilityIdentifier("battle-debrief-button")
                .firstBattleButtonCoach(
                    .debrief,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )

                Button {
                    markButtonCoachUsed(.restart)
                    model.restartBattle()
                } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                }
                .accessibilityIdentifier("battle-restart-button")
                .firstBattleButtonCoach(
                    .restart,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.45))
                .overlay {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                }
        )
    }

    private func board(_ snapshot: NativeBoardSnapshot) -> some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 24)
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

                grid(in: geometry.size)
                    .stroke(Color.black.opacity(0.18), lineWidth: 1)

                ForEach(snapshot.zones) { zone in
                    terrainShape(for: zone, in: geometry.size)
                }

                ForEach(snapshot.objectives) { objective in
                    objectiveMarker(objective, in: geometry.size)
                }

                ForEach(snapshot.units) { unit in
                    unitToken(unit, in: geometry.size)
                }

                if showsFirstBattleTutorialGhosts {
                    firstBattleMovementGhost(snapshot, in: geometry.size)
                    firstBattleTargetingGhost(snapshot, in: geometry.size)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .aspectRatio(DZWPlayableBattleViewModel.boardWidth / DZWPlayableBattleViewModel.boardHeight, contentMode: .fit)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("battle-board")
        .accessibilityLabel("Battle board")
    }

    private func selectionSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selection")
                .font(.headline)
            if let selected = snapshot.selectedUnit {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selected.name)
                        .font(.title3.weight(.bold))
                    Text("\(model.sideTitle(for: selected.owner)) | \(selected.roleLine)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Wounds \(selected.totalWoundsRemaining) | \(selected.inCover ? "Cover" : "Open") | \(selected.hullDown ? "Hull-down" : "Exposed")")
                        .font(.caption.monospaced())
                    Text(selected.historicalNote.isEmpty ? "Engine unit: \(selected.engineName)" : selected.historicalNote)
                        .font(.caption.monospaced())
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("battle-selected-unit-summary")
                .firstBattleButtonCoach(
                    selected.owner == model.humanPlayer ? .boardUnitMovement : .boardEnemyTargeting,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            } else {
                Text("No unit selected")
                    .foregroundStyle(.secondary)
            }

            if let target = snapshot.selectedTarget {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Target", systemImage: "scope")
                        .font(.caption.weight(.bold))
                    Text(target.name)
                        .font(.subheadline.weight(.bold))
                    Text("\(model.sideTitle(for: target.owner)) | \(target.roleLine)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.35)))
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("battle-selected-target-summary")
                .firstBattleButtonCoach(
                    .boardEnemyTargeting,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            } else {
                Text("No target selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("battle-selected-target-summary")
                    .firstBattleButtonCoach(
                        .boardEnemyTargeting,
                        showsCoach: showsFirstBattleButtonCoach,
                        progress: firstBattleButtonCoachProgress,
                        completedFirstGame: firstBattleButtonCoachCompleted
                    )
            }

            HStack {
                Button("Prev Ready") {
                    markButtonCoachUsed(.previousReady)
                    model.cycleActiveUnit(forward: false)
                }
                .accessibilityIdentifier("prev-ready-button")
                .firstBattleButtonCoach(
                    .previousReady,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                Button("Next Ready") {
                    markButtonCoachUsed(.nextReady)
                    model.cycleActiveUnit(forward: true)
                }
                .accessibilityIdentifier("next-ready-button")
                .firstBattleButtonCoach(
                    .nextReady,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .disabled(!model.canIssueHumanOrders)
            HStack {
                Button("Nearest Enemy") {
                    markButtonCoachUsed(.nearestEnemy)
                    model.selectNearestEnemy()
                }
                .accessibilityIdentifier("nearest-enemy-button")
                .firstBattleButtonCoach(
                    .nearestEnemy,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                Button("Clear") {
                    markButtonCoachUsed(.clearSelection)
                    model.clearSelection()
                }
                .accessibilityIdentifier("clear-selection-button")
                .firstBattleButtonCoach(
                    .clearSelection,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .disabled(!model.canIssueHumanOrders)
        }
        .buttonStyle(.bordered)
    }

    private func actionsSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions")
                .font(.headline)

            HStack {
                Button {
                    markButtonCoachUsed(.rotateLeft)
                    model.rotateSelected(by: -45)
                } label: {
                    Label("Rotate -45", systemImage: "rotate.left")
                }
                .accessibilityIdentifier("rotate-left-button")
                .firstBattleButtonCoach(
                    .rotateLeft,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                Button {
                    markButtonCoachUsed(.rotateRight)
                    model.rotateSelected(by: 45)
                } label: {
                    Label("Rotate +45", systemImage: "rotate.right")
                }
                .accessibilityIdentifier("rotate-right-button")
                .firstBattleButtonCoach(
                    .rotateRight,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer)

            HStack {
                Toggle("Manual Cover", isOn: Binding(
                    get: { snapshot.selectedUnit?.inCover ?? false },
                    set: {
                        markButtonCoachUsed(.manualCover)
                        model.toggleCover($0)
                    }
                ))
                .firstBattleButtonCoach(
                    .manualCover,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                Toggle("Hull Down", isOn: Binding(
                    get: { snapshot.selectedUnit?.hullDown ?? false },
                    set: {
                        markButtonCoachUsed(.hullDown)
                        model.toggleHullDown($0)
                    }
                ))
                .firstBattleButtonCoach(
                    .hullDown,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
            }
            .font(.caption.weight(.semibold))
            .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer)

            Button {
                markButtonCoachUsed(.shootTarget)
                model.shootSelected()
            } label: {
                Label("Shoot Target", systemImage: "scope")
            }
            .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer || snapshot.selectedUnit?.canShootNow != true || snapshot.selectedTarget == nil)
            .accessibilityIdentifier("shoot-target-button")
            .firstBattleButtonCoach(
                .shootTarget,
                showsCoach: showsFirstBattleButtonCoach,
                progress: firstBattleButtonCoachProgress,
                completedFirstGame: firstBattleButtonCoachCompleted
            )

            Toggle("Assault follow-up advances", isOn: Binding(
                get: { assaultAdvance },
                set: {
                    markButtonCoachUsed(.assaultFollowUp)
                    assaultAdvance = $0
                }
            ))
                .font(.caption.weight(.semibold))
                .firstBattleButtonCoach(
                    .assaultFollowUp,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
                .disabled(!model.canResolveHumanActivation)

            Button {
                markButtonCoachUsed(.assaultTarget)
                model.assaultSelected(advance: assaultAdvance)
            } label: {
                Label("Assault Target", systemImage: "figure.run")
            }
            .disabled(!model.canResolveHumanActivation || snapshot.selectedUnit?.owner != model.humanPlayer || snapshot.selectedUnit?.canAssaultNow != true || snapshot.selectedTarget == nil)
            .accessibilityIdentifier("assault-target-button")
            .firstBattleButtonCoach(
                .assaultTarget,
                showsCoach: showsFirstBattleButtonCoach,
                progress: firstBattleButtonCoachProgress,
                completedFirstGame: firstBattleButtonCoachCompleted
            )

            Button {
                markButtonCoachUsed(.resolvePending)
                model.resolvePendingChoice()
            } label: {
                Label("Resolve Pending", systemImage: "checkmark.circle")
            }
            .disabled(!model.canResolveHumanActivation)
            .accessibilityIdentifier("resolve-pending-button")
            .firstBattleButtonCoach(
                .resolvePending,
                showsCoach: showsFirstBattleButtonCoach,
                progress: firstBattleButtonCoachProgress,
                completedFirstGame: firstBattleButtonCoachCompleted
            )

            Label(snapshot.lastAction.detail, systemImage: snapshot.lastAction.status == .blocked ? "exclamationmark.triangle" : "checkmark.circle")
                .font(.caption)
                .foregroundStyle(snapshot.lastAction.status == .blocked ? .orange : .secondary)
                .accessibilityIdentifier("battle-action-feedback")
                .firstBattleButtonCoach(
                    .actionFeedback,
                    showsCoach: showsFirstBattleButtonCoach,
                    progress: firstBattleButtonCoachProgress,
                    completedFirstGame: firstBattleButtonCoachCompleted
                )
        }
        .buttonStyle(.bordered)
    }

    private func resultSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Result")
                .font(.headline)

            if let completion = model.completion {
                Label(completion.victoryBandLabel, systemImage: "rosette")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
                Text("\(completion.score) VP | turn \(completion.completedTurn)")
                    .font(.caption.monospaced())
                Text(completion.sourceName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let playableTestGameResult = model.playableTestGameResult {
                    Text("\(playableTestGameResult.antiGuderianStepCount) default-side steps | \(playableTestGameResult.germanStepCount) Guderian-command steps")
                        .font(.caption.monospaced())
                        .foregroundStyle(playableTestGameResult.completedToEnd ? .green : .orange)
                    Text(playableTestGameResult.summary)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                Text(completion.debriefSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(5)
                Text("Persisted to campaign progress.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("battle-persisted-result")
            } else if let debriefError = model.debriefError {
                Label(debriefError, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if snapshot.mission.winner != .none {
                Label("\(model.sideTitle(for: snapshot.mission.winner)) has reached the scenario result.", systemImage: "flag.checkered")
                    .font(.caption)
                    .foregroundStyle(snapshot.mission.winner == model.humanPlayer ? .green : .orange)
            } else {
                Text("No debrief recorded yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.45)))
        .accessibilityIdentifier("battle-debrief-panel")
    }

    private func objectivesSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Objectives")
                .font(.headline)
            ForEach(snapshot.objectives) { objective in
                VStack(alignment: .leading, spacing: 2) {
                    Text(objective.name)
                        .font(.subheadline.weight(.bold))
                    Text("\(model.sideTitle(for: objective.controller)) | \(objective.playerPresence)-\(objective.opponentPresence)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.45)))
            }
        }
        .onAppear {
            model.recordTutorialTrigger(.objectiveInspection)
        }
    }

    private func armiesSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Matchup")
                .font(.headline)
            Text("Selected side: \(model.humanSideTitle). Opposing automation: \(model.aiSideTitle). Both forces use the same rules-backed board state.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach([NativeBoardPlayer.player, NativeBoardPlayer.guderianAI], id: \.self) { owner in
                let units = snapshot.units.filter { $0.owner == owner }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(model.sideTitle(for: owner))\(owner == model.humanPlayer ? " (you)" : " (AI)")")
                        .font(.subheadline.weight(.bold))
                    ForEach(units.prefix(8)) { unit in
                        Text("\(unit.name) | \(unit.role) | \(unit.totalWoundsRemaining) wounds")
                            .font(.caption.monospaced())
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.16), lineWidth: 1))
            }
        }
    }

    private func aiTurnSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.aiTurnSectionTitle)
                .font(.headline)
            ForEach(Array(model.aiTurnEvents.enumerated()), id: \.offset) { _, event in
                Text(event)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
    }

    private func logSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Battle Log")
                .font(.headline)
            ForEach(Array(snapshot.logLines.suffix(8).enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
    }

    private func grid(in size: CGSize) -> Path {
        var path = Path()
        let columns = Int(DZWPlayableBattleViewModel.boardWidth)
        let rows = Int(DZWPlayableBattleViewModel.boardHeight)

        for column in 0...columns {
            let x = size.width * CGFloat(column) / DZWPlayableBattleViewModel.boardWidth
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }

        for row in 0...rows {
            let y = size.height * CGFloat(row) / DZWPlayableBattleViewModel.boardHeight
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }

        return path
    }

    @ViewBuilder
    private func firstBattleMovementGhost(_ snapshot: NativeBoardSnapshot, in size: CGSize) -> some View {
        if let unit = tutorialMovementUnit(in: snapshot) {
            let start = boardPoint(CGPoint(x: unit.x, y: unit.y), in: size)
            let destination = tutorialMovementDestination(for: unit, in: snapshot)
            let end = boardPoint(destination, in: size)
            let radius = tokenRadius(for: unit, in: size)
            let ownerColor = boardOwnerColor(for: unit.owner)

            TimelineView(.animation) { timeline in
                let progress = tutorialCycleProgress(at: timeline.date, period: 2.4)
                let ghostPosition = interpolate(from: start, to: end, progress: progress)

                ZStack {
                    Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    .stroke(Color.white.opacity(0.34), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [10, 7]))

                    tutorialArrowHead(from: start, to: end, size: 13)
                        .stroke(Color.white.opacity(0.38), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    tutorialGhostUnitToken(unit, radius: radius, ownerColor: ownerColor, systemImage: "arrow.up.right")
                        .position(ghostPosition)
                }
            }
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("first-battle-movement-ghost")
            .accessibilityLabel("Low alpha movement ghost")
        }
    }

    @ViewBuilder
    private func firstBattleTargetingGhost(_ snapshot: NativeBoardSnapshot, in size: CGSize) -> some View {
        if let attacker = tutorialMovementUnit(in: snapshot),
           let target = tutorialTargetUnit(in: snapshot, from: attacker) {
            let start = boardPoint(CGPoint(x: attacker.x, y: attacker.y), in: size)
            let end = boardPoint(CGPoint(x: target.x, y: target.y), in: size)
            let radius = tokenRadius(for: target, in: size)
            let targetColor = boardOwnerColor(for: target.owner)

            TimelineView(.animation) { timeline in
                let pulse = tutorialPulse(at: timeline.date, period: 1.8)
                let ringScale = 1.05 + pulse * 0.28

                ZStack {
                    Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    }
                    .stroke(Color.yellow.opacity(0.32 + pulse * 0.18), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 5]))

                    Circle()
                        .stroke(Color.yellow.opacity(0.54), style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
                        .frame(width: radius * 3.2 * ringScale, height: radius * 3.2 * ringScale)
                        .position(end)

                    Circle()
                        .fill(targetColor.opacity(0.18))
                        .frame(width: radius * 2.4, height: radius * 2.4)
                        .overlay(
                            Image(systemName: "scope")
                                .font(.system(size: max(CGFloat(16), radius * 0.9), weight: .heavy))
                                .foregroundStyle(Color.white.opacity(0.72))
                        )
                        .position(end)
                }
            }
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("first-battle-targeting-ghost")
            .accessibilityLabel("Low alpha targeting ghost")
        }
    }

    private func terrainShape(for zone: NativeBoardZoneSnapshot, in size: CGSize) -> some View {
        let rect = boardRect(zone, in: size)
        let fill = terrainFill(for: zone)

        return RoundedRectangle(cornerRadius: 18)
            .fill(fill)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .overlay(alignment: .topLeading) {
                Text(zone.name)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.68)))
                    .padding(8)
                    .position(x: rect.minX + 54, y: rect.minY + 18)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: zone.blocksLineOfSight ? [6, 4] : []))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            )
            .firstBattleButtonCoach(
                .boardTerrain,
                showsCoach: showsFirstBattleButtonCoach,
                progress: firstBattleButtonCoachProgress,
                completedFirstGame: firstBattleButtonCoachCompleted
            )
    }

    private func objectiveMarker(_ objective: NativeBoardObjectiveSnapshot, in size: CGSize) -> some View {
        let position = boardPoint(CGPoint(x: objective.x, y: objective.y), in: size)
        let boardScale = size.width / DZWPlayableBattleViewModel.boardWidth
        let radius = CGFloat(objective.radius) * boardScale
        let markerColor = objectiveColor(objective.controller, contested: objective.playerPresence > 0 && objective.opponentPresence > 0)

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
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.7)))
                .offset(y: radius + 14)
        }
        .position(position)
        .firstBattleButtonCoach(
            .boardObjective,
            showsCoach: showsFirstBattleButtonCoach,
            progress: firstBattleButtonCoachProgress,
            completedFirstGame: firstBattleButtonCoachCompleted
        )
    }

    @ViewBuilder
    private func unitToken(_ unit: NativeBoardUnitSnapshot, in size: CGSize) -> some View {
        let gamePoint = dragPreview[unit.id] ?? CGPoint(x: unit.x, y: unit.y)
        let position = boardPoint(gamePoint, in: size)
        let radius = tokenRadius(for: unit, in: size)
        let isSelected = unit.selected || unit.targeted
        let ownerColor = boardOwnerColor(for: unit.owner)
        let selectionStroke = isSelected ? Color.white.opacity(0.98) : Color.white.opacity(0.35)

        ZStack {
            if unit.kind == "Vehicle" || unit.kind == "Assault gun" {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ownerColor)
                    .frame(width: radius * 2.4, height: radius * 1.6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectionStroke, lineWidth: isSelected ? 3.5 : 1)
                    )
            } else {
                Circle()
                    .fill(ownerColor)
                    .frame(width: radius * 2, height: radius * 2)
                    .overlay(
                        Circle()
                            .stroke(selectionStroke, lineWidth: isSelected ? 3.5 : 1)
                    )
            }

            VStack(spacing: 2) {
                Text(tokenName(for: unit))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .frame(width: radius * 2.2)
                    .lineLimit(2)
                    .accessibilityIdentifier(unit.owner == model.humanPlayer ? "battle-board-friendly-unit-\(unit.id)" : "battle-board-enemy-unit-\(unit.id)")
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
        }
        .position(position)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 6)
        .shadow(color: isSelected ? ownerColor.opacity(0.45) : .clear, radius: 12, x: 0, y: 0)
        .opacity(unit.destroyed ? 0.35 : 1)
        .onTapGesture {
            model.select(unit)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard model.canManipulate(unit) else {
                        return
                    }
                    model.select(unit)
                    dragPreview[unit.id] = gameCoordinates(for: value.location, in: size)
                }
                .onEnded { value in
                    guard model.canManipulate(unit) else {
                        dragPreview[unit.id] = nil
                        return
                    }
                    let point = gameCoordinates(for: value.location, in: size)
                    dragPreview[unit.id] = nil
                    model.moveUnit(id: unit.id, to: point)
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(unit.owner == model.humanPlayer ? "battle-board-friendly-unit-\(unit.id)" : "battle-board-enemy-unit-\(unit.id)")
        .accessibilityLabel("\(unit.name), \(model.sideTitle(for: unit.owner))")
        .firstBattleButtonCoach(
            unit.owner == model.humanPlayer ? .boardUnitMovement : .boardEnemyTargeting,
            showsCoach: showsFirstBattleButtonCoach,
            progress: firstBattleButtonCoachProgress,
            completedFirstGame: firstBattleButtonCoachCompleted
        )
    }

    private func boardRect(_ zone: NativeBoardZoneSnapshot, in size: CGSize) -> CGRect {
        let origin = boardPoint(CGPoint(x: zone.x, y: zone.y), in: size)
        let width = size.width * CGFloat(zone.width) / DZWPlayableBattleViewModel.boardWidth
        let height = size.height * CGFloat(zone.height) / DZWPlayableBattleViewModel.boardHeight
        return CGRect(x: origin.x, y: origin.y, width: width, height: height)
    }

    private func boardPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: size.width * point.x / DZWPlayableBattleViewModel.boardWidth,
            y: size.height * point.y / DZWPlayableBattleViewModel.boardHeight
        )
    }

    private func gameCoordinates(for point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(0, point.x / size.width * DZWPlayableBattleViewModel.boardWidth), DZWPlayableBattleViewModel.boardWidth),
            y: min(max(0, point.y / size.height * DZWPlayableBattleViewModel.boardHeight), DZWPlayableBattleViewModel.boardHeight)
        )
    }

    private func tutorialMovementUnit(in snapshot: NativeBoardSnapshot) -> NativeBoardUnitSnapshot? {
        if let selected = snapshot.selectedUnit,
           selected.owner == model.humanPlayer,
           !selected.destroyed {
            return selected
        }

        return snapshot.units
            .filter { $0.owner == model.humanPlayer && !$0.destroyed }
            .sorted { $0.id < $1.id }
            .first
    }

    private func tutorialTargetUnit(in snapshot: NativeBoardSnapshot, from attacker: NativeBoardUnitSnapshot) -> NativeBoardUnitSnapshot? {
        if let target = snapshot.selectedTarget,
           target.owner != model.humanPlayer,
           !target.destroyed {
            return target
        }

        let attackerPoint = CGPoint(x: attacker.x, y: attacker.y)
        return snapshot.units
            .filter { $0.owner != model.humanPlayer && $0.owner != .none && !$0.destroyed }
            .min {
                distanceSquared(from: attackerPoint, to: CGPoint(x: $0.x, y: $0.y)) <
                    distanceSquared(from: attackerPoint, to: CGPoint(x: $1.x, y: $1.y))
            }
    }

    private func tutorialMovementDestination(for unit: NativeBoardUnitSnapshot, in snapshot: NativeBoardSnapshot) -> CGPoint {
        let origin = CGPoint(x: unit.x, y: unit.y)
        let objective = snapshot.objectives.min {
            distanceSquared(from: origin, to: CGPoint(x: $0.x, y: $0.y)) <
                distanceSquared(from: origin, to: CGPoint(x: $1.x, y: $1.y))
        }
        let target = objective.map { CGPoint(x: $0.x, y: $0.y) } ?? CGPoint(x: origin.x + 6, y: origin.y)
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let distance = max(sqrt(dx * dx + dy * dy), 0.001)
        let step = min(max(distance * 0.36, 3), 7)

        return clampedBoardPoint(CGPoint(
            x: origin.x + dx / distance * step,
            y: origin.y + dy / distance * step
        ))
    }

    private func clampedBoardPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(0, point.x), DZWPlayableBattleViewModel.boardWidth),
            y: min(max(0, point.y), DZWPlayableBattleViewModel.boardHeight)
        )
    }

    private func distanceSquared(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }

    private func interpolate(from start: CGPoint, to end: CGPoint, progress: CGFloat) -> CGPoint {
        CGPoint(
            x: start.x + (end.x - start.x) * progress,
            y: start.y + (end.y - start.y) * progress
        )
    }

    private func tutorialCycleProgress(at date: Date, period: TimeInterval) -> CGFloat {
        let rawProgress = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: period) / period
        return max(0, min(1, CGFloat(rawProgress)))
    }

    private func tutorialPulse(at date: Date, period: TimeInterval) -> CGFloat {
        let progress = tutorialCycleProgress(at: date, period: period)
        return CGFloat((sin(Double(progress) * 2 * Double.pi) + 1) / 2)
    }

    private func tutorialArrowHead(from start: CGPoint, to end: CGPoint, size: CGFloat) -> Path {
        var path = Path()
        let angle = atan2(end.y - start.y, end.x - start.x)
        let left = CGPoint(
            x: end.x - cos(angle - .pi / 6) * size,
            y: end.y - sin(angle - .pi / 6) * size
        )
        let right = CGPoint(
            x: end.x - cos(angle + .pi / 6) * size,
            y: end.y - sin(angle + .pi / 6) * size
        )

        path.move(to: end)
        path.addLine(to: left)
        path.move(to: end)
        path.addLine(to: right)
        return path
    }

    private func tutorialGhostUnitToken(
        _ unit: NativeBoardUnitSnapshot,
        radius: CGFloat,
        ownerColor: Color,
        systemImage: String
    ) -> some View {
        ZStack {
            if unit.kind == "Vehicle" || unit.kind == "Assault gun" {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ownerColor.opacity(0.24))
                    .frame(width: radius * 2.4, height: radius * 1.6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.48), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    )
            } else {
                Circle()
                    .fill(ownerColor.opacity(0.22))
                    .frame(width: radius * 2, height: radius * 2)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.48), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    )
            }

            Image(systemName: systemImage)
                .font(.system(size: max(CGFloat(14), radius * 0.75), weight: .heavy))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .opacity(0.82)
    }

    private func tokenRadius(for unit: NativeBoardUnitSnapshot, in size: CGSize) -> CGFloat {
        let base: CGFloat = unit.kind == "Vehicle" || unit.kind == "Assault gun" ? 20 : 18
        return max(base, size.width / 46)
    }

    private func tokenName(for unit: NativeBoardUnitSnapshot) -> String {
        let cleaned = unit.name
            .replacingOccurrences(of: "German ", with: "")
            .replacingOccurrences(of: "British ", with: "")
            .replacingOccurrences(of: "Polish ", with: "")
        return cleaned.split(separator: " ").prefix(2).joined(separator: " ")
    }

    private func boardOwnerColor(for owner: NativeBoardPlayer) -> Color {
        switch owner {
        case .player:
            return Color(red: 0.13, green: 0.32, blue: 0.67)
        case .guderianAI:
            return Color(red: 0.63, green: 0.23, blue: 0.16)
        case .none:
            return Color(red: 0.55, green: 0.56, blue: 0.46)
        }
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
}
