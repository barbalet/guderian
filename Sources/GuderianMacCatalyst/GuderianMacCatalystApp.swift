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

@MainActor
private final class GuderianCatalystBattleViewModel: ObservableObject {
    @Published private(set) var entries: [UnifiedGuderianBattleEntry]
    @Published private(set) var selectedEntry: UnifiedGuderianBattleEntry?
    @Published private(set) var snapshot: NativeBoardSnapshot?
    @Published private(set) var completion: CatalystCompletion?
    @Published private(set) var errorMessage: String?

    private var session: CatalystNativeSession?
    private var restartCount = 0

    init() {
        entries = UnifiedGuderianBattleCatalog.allEntries.sorted { $0.order < $1.order }
        selectedEntry = nil
        snapshot = nil
        completion = nil
        errorMessage = nil
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
        return !isBattleOver && snapshot.activePlayer == humanPlayer
    }

    var canRunAITurn: Bool {
        guard let snapshot else {
            return false
        }
        return !isBattleOver && snapshot.activePlayer == aiPlayer
    }

    var completionLine: String? {
        guard let completion else {
            return nil
        }
        return "\(completion.victoryBand) | \(completion.score) VP | turn \(completion.completedTurn)"
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
        guard let session, let snapshot, !isBattleOver else {
            return
        }
        if unit.owner == snapshot.activePlayer {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
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
            .filter { $0.owner == humanPlayer && !$0.destroyed }
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
        let priorities = snapshot.flatMap { snapshot in
            session?.targetPriorities(for: snapshot.activePlayer, phase: snapshot.phase)
        } ?? []
        if !priorities.isEmpty {
            _ = session?.moveSelectedUnitTowardPriorityObjective(named: priorities, maxDistance: 6)
        } else {
            _ = session?.moveSelectedUnitTowardNearestObjective(maxDistance: 5)
        }
        refresh()
    }

    func move(_ unit: NativeBoardUnitSnapshot, to boardPoint: NativeBattleCoordinate) {
        guard canIssueHumanOrders, unit.owner == humanPlayer else {
            return
        }
        _ = session?.moveUnit(unit.id, to: boardPoint)
        refresh()
    }

    func rotateSelected(by degrees: Double) {
        guard let selected = snapshot?.selectedUnit, selected.owner == humanPlayer else {
            return
        }
        _ = session?.rotateUnit(selected.id, to: selected.facingDegrees + degrees)
        refresh()
    }

    func toggleCover(_ enabled: Bool) {
        guard let selected = snapshot?.selectedUnit, selected.owner == humanPlayer else {
            return
        }
        _ = session?.toggleCover(for: selected.id, enabled: enabled)
        refresh()
    }

    func toggleHullDown(_ enabled: Bool) {
        guard let selected = snapshot?.selectedUnit, selected.owner == humanPlayer else {
            return
        }
        _ = session?.toggleHullDown(for: selected.id, enabled: enabled)
        refresh()
    }

    func shootSelectedTarget() {
        _ = session?.shootSelectedTarget()
        refresh()
    }

    func assaultSelected(advance: Bool) {
        guard let selected = snapshot?.selectedUnit,
              let target = snapshot?.selectedTarget else {
            return
        }
        _ = session?.assaultUnit(selected.id, targetID: target.id, advance: advance)
        refresh()
    }

    func resolvePendingChoice() {
        _ = session?.resolveFirstPendingChoice()
        refresh()
    }

    func advancePhase() {
        session?.advancePhase()
        refresh()
    }

    func runAutomatedActiveStep() {
        guard let session, let snapshot, !isBattleOver else {
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
        guard !isBattleOver else {
            return
        }

        var safety = 0
        while snapshot?.activePlayer != aiPlayer && isBattleOver == false && safety < 4 {
            session?.advancePhase()
            refresh()
            safety += 1
        }

        while snapshot?.activePlayer == aiPlayer && isBattleOver == false && safety < 16 {
            runAutomatedActiveStep()
            safety += 1
        }
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
            session = .field(scenario, nativeSession)
            return
        }

        if let id = entry.id.lateCareerID,
           let presentation = LateCareerGuderianPresentationCatalog.entry(for: id),
           let nativeSession = LateCareerNativeBoardSession(battlefieldID: id, seed: seed) {
            session = .late(presentation, nativeSession)
            return
        }

        session = nil
        errorMessage = CatalystBattleError.launchUnavailable.localizedDescription
    }

    private func refresh() {
        snapshot = session?.snapshot()
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
                        sideTitle: model.sideTitle(for:),
                        onSelect: model.select(_:),
                        onMove: model.move(_:to:)
                    )
                    .ignoresSafeArea()

                    topHUD(snapshot, in: proxy.size)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

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
        let top = min(210, max(150, size.height * 0.13))
        let bottom = min(130, max(90, size.height * 0.07))
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
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CatalystPalette.gold)
                        .lineLimit(2)
                    Text("\(model.sideTitle(for: .player)) \(snapshot.mission.playerScore) - \(snapshot.mission.opponentScore) \(model.sideTitle(for: .guderianAI))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer(minLength: 10)

                if let line = model.completionLine {
                    Label(line, systemImage: "flag.checkered")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                        .lineLimit(2)
                } else if snapshot.mission.winner != .none {
                    Label(model.sideTitle(for: snapshot.mission.winner), systemImage: "rosette")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.green)
                }
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

            Button {
                zoom = max(0.65, zoom - 0.15)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .frame(width: 26, height: 26)
            }
            .help("Zoom out")

            if !compact {
                Slider(value: $zoom, in: 0.65...2.1)
                    .frame(width: 120)
                    .accessibilityIdentifier("catalyst-zoom-slider")
            }

            Button {
                zoom = min(2.1, zoom + 0.15)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .frame(width: 26, height: 26)
            }
            .help("Zoom in")
        }
        .buttonStyle(.bordered)
        .tint(CatalystPalette.gold)
        .padding(10)
        .frame(maxWidth: min(availableWidth, compact ? 430 : 640))
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .accessibilityIdentifier("catalyst-command-dock")
    }

    private func overlayButton(_ panel: CatalystOverlay) -> some View {
        Button {
            overlay = overlay == panel ? nil : panel
        } label: {
            Image(systemName: panel.systemImage)
                .frame(width: 26, height: 26)
        }
        .help(panel.title)
        .accessibilityLabel(panel.title)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(overlay == panel ? CatalystPalette.gold.opacity(0.20) : Color.clear)
        )
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
                            .fill(model.selectedEntry?.id == entry.id ? CatalystPalette.gold.opacity(0.16) : Color.white.opacity(0.04))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var commandPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let snapshot = model.snapshot {
                HStack(spacing: 8) {
                    commandButton("Move", "arrow.up.right") {
                        model.moveSelectedTowardObjective()
                        overlay = nil
                    }
                    .disabled(!model.canIssueHumanOrders || snapshot.phase != .movement || snapshot.selectedUnit?.canMoveNow != true)

                    commandButton("Fire", "scope") {
                        model.shootSelectedTarget()
                        overlay = nil
                    }
                    .disabled(!model.canIssueHumanOrders || snapshot.phase != .shooting || snapshot.selectedUnit?.canShootNow != true || snapshot.selectedTarget == nil)
                }

                HStack(spacing: 8) {
                    commandButton("Assault", "figure.run") {
                        model.assaultSelected(advance: assaultAdvance)
                        overlay = nil
                    }
                    .disabled(!model.canIssueHumanOrders || snapshot.phase != .assault || snapshot.selectedUnit?.canAssaultNow != true || snapshot.selectedTarget == nil)

                    commandButton("Resolve", "checkmark.circle") {
                        model.resolvePendingChoice()
                        overlay = nil
                    }
                    .disabled(!model.canIssueHumanOrders)
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
                    .disabled(!model.canIssueHumanOrders)
                }

                HStack(spacing: 8) {
                    commandButton("Phase", "forward.end") {
                        model.advancePhase()
                        overlay = nil
                    }
                    .disabled(!model.canIssueHumanOrders)

                    commandButton("AI", "forward.frame") {
                        model.runAITurn()
                        overlay = nil
                    }
                    .disabled(model.isBattleOver)

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
                    .disabled(!model.canIssueHumanOrders || snapshot.selectedUnit?.owner != model.humanPlayer)

                    Toggle("Hull-down", isOn: Binding(
                        get: { snapshot.selectedUnit?.hullDown ?? false },
                        set: { model.toggleHullDown($0) }
                    ))
                    .disabled(!model.canIssueHumanOrders || snapshot.selectedUnit?.owner != model.humanPlayer)
                }
                .font(.caption.weight(.semibold))

                HStack(spacing: 8) {
                    commandButton("Rotate", "rotate.right") {
                        model.rotateSelected(by: 45)
                    }
                    .disabled(!model.canIssueHumanOrders || snapshot.selectedUnit?.owner != model.humanPlayer)

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

                if let line = model.completionLine {
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
    let sideTitle: (NativeBoardPlayer) -> String
    let onSelect: (NativeBoardUnitSnapshot) -> Void
    let onMove: (NativeBoardUnitSnapshot, NativeBattleCoordinate) -> Void

    private static let boardWidth = CGFloat(game_board_width())
    private static let boardHeight = CGFloat(game_board_height())

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
                        .fill(CatalystPalette.mapBase)
                    boardGrid(in: fittedSize)

                    ForEach(snapshot.zones) { zone in
                        terrainZone(zone, in: fittedSize)
                    }

                    ForEach(snapshot.objectives) { objective in
                        objectiveMarker(objective, in: fittedSize)
                    }

                    ForEach(snapshot.units) { unit in
                        unitToken(unit, in: fittedSize)
                    }
                }
                .frame(width: fittedSize.width, height: fittedSize.height)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.32), lineWidth: 1)
                }
                .padding(28)
                .padding(.top, contentInsets.top)
                .padding(.bottom, contentInsets.bottom)
                .frame(minWidth: proxy.size.width, minHeight: proxy.size.height, alignment: .top)
            }
            .background(CatalystPalette.background)
        }
        .accessibilityIdentifier("catalyst-battle-map")
    }

    private func fittedBoardSize(in available: CGSize) -> CGSize {
        let safeWidth = max(available.width - 56, 320)
        let safeHeight = max(available.height - 56, 240)
        let aspect = Self.boardWidth / Self.boardHeight
        let widthFirstHeight = safeWidth / aspect
        let base: CGSize
        if widthFirstHeight <= safeHeight {
            base = CGSize(width: safeWidth, height: widthFirstHeight)
        } else {
            base = CGSize(width: safeHeight * aspect, height: safeHeight)
        }
        return CGSize(width: base.width * zoom, height: base.height * zoom)
    }

    private func boardGrid(in size: CGSize) -> some View {
        Path { path in
            for column in 1..<12 {
                let x = size.width * CGFloat(column) / 12
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for row in 1..<8 {
                let y = size.height * CGFloat(row) / 8
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
        }
        .stroke(Color.black.opacity(0.12), lineWidth: 1)
    }

    private func terrainZone(_ zone: NativeBoardZoneSnapshot, in size: CGSize) -> some View {
        Rectangle()
            .fill(terrainColor(zone).opacity(zone.kind == "Impassable" ? 0.42 : 0.26))
            .overlay {
                Rectangle()
                    .stroke(terrainColor(zone).opacity(0.65), lineWidth: zone.blocksLineOfSight ? 2 : 1)
            }
            .frame(
                width: max(8, size.width * zone.width / Self.boardWidth),
                height: max(8, size.height * zone.height / Self.boardHeight)
            )
            .position(
                x: size.width * (zone.x + zone.width / 2) / Self.boardWidth,
                y: size.height * (zone.y + zone.height / 2) / Self.boardHeight
            )
            .accessibilityLabel(zone.name)
    }

    private func objectiveMarker(_ objective: NativeBoardObjectiveSnapshot, in size: CGSize) -> some View {
        let diameter = max(24, objective.radius * 6 * min(size.width / Self.boardWidth, size.height / Self.boardHeight))
        return ZStack {
            Circle()
                .fill(objectiveColor(objective.controller).opacity(0.82))
                .frame(width: diameter, height: diameter)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                }
            Image(systemName: "target")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
            Text(objective.name)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 5))
                .offset(y: diameter * 0.62)
        }
        .position(x: size.width * objective.x / Self.boardWidth, y: size.height * objective.y / Self.boardHeight)
        .accessibilityLabel(objective.name)
    }

    private func unitToken(_ unit: NativeBoardUnitSnapshot, in size: CGSize) -> some View {
        let point = CGPoint(
            x: size.width * unit.x / Self.boardWidth,
            y: size.height * unit.y / Self.boardHeight
        )
        return ZStack {
            Circle()
                .fill(Self.unitColor(unit.owner))
            Image(systemName: Self.unitSymbol(unit))
                .font(.system(size: unit.selected || unit.targeted ? 15 : 13, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: unit.selected || unit.targeted ? 32 : 26, height: unit.selected || unit.targeted ? 32 : 26)
        .overlay {
            Circle()
                .stroke(unit.selected ? CatalystPalette.gold : unit.targeted ? .white : .black.opacity(0.22), lineWidth: unit.selected || unit.targeted ? 3 : 1)
        }
        .opacity(unit.destroyed ? 0.32 : snapshot.activePlayer == unit.owner ? 1 : 0.86)
        .position(point)
        .contentShape(Circle())
        .onTapGesture {
            onSelect(unit)
        }
        .gesture(
            DragGesture(minimumDistance: 8)
                .onEnded { value in
                    let x = min(
                        max(1, unit.x + Double(value.translation.width / size.width * Self.boardWidth)),
                        Double(Self.boardWidth - 1)
                    )
                    let y = min(
                        max(1, unit.y + Double(value.translation.height / size.height * Self.boardHeight)),
                        Double(Self.boardHeight - 1)
                    )
                    onMove(unit, NativeBattleCoordinate(x: x, y: y))
                }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(unit.name), \(sideTitle(unit.owner))")
    }

    private func terrainColor(_ zone: NativeBoardZoneSnapshot) -> Color {
        if zone.kind == "Impassable" {
            return Color(red: 0.12, green: 0.34, blue: 0.64)
        }
        if zone.hullDown {
            return Color(red: 0.50, green: 0.48, blue: 0.38)
        }
        if zone.blocksLineOfSight {
            return Color(red: 0.18, green: 0.42, blue: 0.25)
        }
        return Color(red: 0.55, green: 0.48, blue: 0.36)
    }

    static func unitColor(_ player: NativeBoardPlayer) -> Color {
        switch player {
        case .player:
            return Color(red: 0.08, green: 0.33, blue: 0.70)
        case .guderianAI:
            return Color(red: 0.68, green: 0.13, blue: 0.10)
        case .none:
            return .secondary
        }
    }

    private func objectiveColor(_ player: NativeBoardPlayer) -> Color {
        switch player {
        case .player:
            return Color(red: 0.07, green: 0.47, blue: 0.60)
        case .guderianAI:
            return Color(red: 0.70, green: 0.22, blue: 0.10)
        case .none:
            return Color(red: 0.40, green: 0.32, blue: 0.64)
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
    static let commandBlue = Color(red: 0.12, green: 0.31, blue: 0.62)
}
