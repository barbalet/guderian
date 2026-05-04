import GuderianCore
import SwiftUI

@MainActor
private final class DZWPlayableBattleViewModel: ObservableObject {
    static let boardWidth: CGFloat = 72
    static let boardHeight: CGFloat = 48

    @Published private(set) var snapshot: NativeBoardSnapshot?
    @Published private(set) var lastError: String = ""
    @Published private(set) var completion: PlayableBattleCompletionSummary?
    @Published private(set) var debriefError: String?
    @Published private(set) var aiTurnEvents: [String]

    let scenario: GuderianScenario
    private var session: NativeBoardSession?
    private let aiTargetPriorities: [String]
    private var restartCount = 0

    init(scenario: GuderianScenario) {
        self.scenario = scenario
        let aiPlan = ScenarioContentCatalog.bundle(for: scenario).aiPlan
        aiTargetPriorities = aiPlan.targetPriorities
        aiTurnEvents = [
            "German AI ready: \(aiPlan.postureName) will pressure \(Self.prioritySummary(aiPlan.targetPriorities))."
        ]
        session = Self.makeSession(for: scenario, restartCount: restartCount)
        refresh()
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

    var hasCompletion: Bool {
        completion != nil
    }

    var title: String {
        "\(scenario.title) Operations Map"
    }

    var matchupText: String {
        "\(scenario.playerForceSummary) vs \(scenario.guderianCommand)"
    }

    var activeUnits: [NativeBoardUnitSnapshot] {
        guard let snapshot else {
            return []
        }
        return snapshot.units
            .filter { $0.owner == snapshot.activePlayer && !$0.destroyed }
            .sorted { $0.id < $1.id }
    }

    func select(_ unit: NativeBoardUnitSnapshot) {
        guard let snapshot, !isBattleOver else {
            return
        }
        if unit.owner == snapshot.activePlayer {
            session?.selectUnit(unit.id)
            session?.selectNearestEnemyToSelectedUnit()
        } else {
            session?.selectTarget(unit.id)
        }
        refresh()
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
            return
        }

        let offset = forward ? 1 : -1
        let nextIndex = (currentIndex + offset + candidates.count) % candidates.count
        session?.selectUnit(candidates[nextIndex].id)
        session?.selectNearestEnemyToSelectedUnit()
        refresh()
    }

    func clearSelection() {
        guard let snapshot else {
            return
        }
        if let first = snapshot.units.first(where: { $0.owner == snapshot.activePlayer && !$0.destroyed }) {
            session?.selectUnit(first.id)
            session?.selectNearestEnemyToSelectedUnit()
        }
        refresh()
    }

    func selectNearestEnemy() {
        session?.selectNearestEnemyToSelectedUnit()
        refresh()
    }

    func canManipulate(_ unit: NativeBoardUnitSnapshot) -> Bool {
        guard let snapshot, !isBattleOver else {
            return false
        }
        return unit.owner == snapshot.activePlayer &&
            snapshot.phase == .movement &&
            unit.canMoveNow &&
            !unit.destroyed
    }

    func moveUnit(id: Int, to point: CGPoint) {
        let coordinate = NativeBattleCoordinate(
            x: min(max(Double(point.x), 1), Double(Self.boardWidth - 1)),
            y: min(max(Double(point.y), 1), Double(Self.boardHeight - 1))
        )
        session?.moveUnit(id, to: coordinate)
        refresh()
    }

    func rotateSelected(by degrees: Double) {
        guard let selectedUnit else {
            return
        }
        session?.rotateUnit(selectedUnit.id, to: selectedUnit.facingDegrees + degrees)
        refresh()
    }

    func toggleCover(_ enabled: Bool) {
        guard let selectedUnit else {
            return
        }
        session?.toggleCover(for: selectedUnit.id, enabled: enabled)
        refresh()
    }

    func toggleHullDown(_ enabled: Bool) {
        guard let selectedUnit else {
            return
        }
        session?.toggleHullDown(for: selectedUnit.id, enabled: enabled)
        refresh()
    }

    func shootSelected() {
        guard let selectedUnit, let selectedTarget else {
            return
        }
        session?.shootUnit(selectedUnit.id, targetID: selectedTarget.id)
        refresh()
    }

    func assaultSelected(advance: Bool) {
        guard let selectedUnit, let selectedTarget else {
            return
        }
        session?.assaultUnit(selectedUnit.id, targetID: selectedTarget.id, advance: advance)
        refresh()
    }

    func resolvePendingChoice() {
        session?.resolveFirstPendingChoice()
        refresh()
    }

    func advancePhase() {
        session?.advancePhase()
        refresh()
    }

    func runAutomatedActiveStep() {
        guard let snapshot, !isBattleOver else {
            return
        }

        let before = "\(snapshot.activePlayer.rawValue) \(snapshot.phase.rawValue)"
        switch snapshot.phase {
        case .movement:
            if snapshot.activePlayer == .guderianAI {
                session?.moveSelectedUnitTowardPriorityObjective(named: aiTargetPriorities, maxDistance: 6)
            } else {
                session?.moveSelectedUnitTowardNearestObjective(maxDistance: 4)
            }
        case .shooting:
            session?.selectNearestEnemyToSelectedUnit()
            _ = session?.shootSelectedTarget()
        case .assault:
            _ = session?.resolveFirstPendingChoice()
        }
        let actionDetail = session?.snapshot().lastAction.detail ?? "No action resolved."
        session?.advancePhase()
        refresh()
        recordAIEvent("\(before): \(actionDetail)")
    }

    func runGermanTurn() {
        guard !isBattleOver else {
            return
        }

        recordAIEvent("German turn runner started.")
        var safety = 0
        while snapshot?.activePlayer != .guderianAI && isBattleOver == false && safety < 4 {
            session?.advancePhase()
            refresh()
            safety += 1
        }

        while snapshot?.activePlayer == .guderianAI && isBattleOver == false && safety < 10 {
            runAutomatedActiveStep()
            safety += 1
        }

        if snapshot?.activePlayer == .guderianAI {
            recordAIEvent("German turn paused: action loop hit its safety cap.")
        } else {
            recordAIEvent("German turn complete: control returned to \(snapshot?.activePlayer.rawValue ?? "the player").")
        }
    }

    func restartBattle() {
        restartCount += 1
        session = Self.makeSession(for: scenario, restartCount: restartCount)
        completion = nil
        debriefError = nil
        let aiPlan = ScenarioContentCatalog.bundle(for: scenario).aiPlan
        aiTurnEvents = [
            "Battle restarted: \(aiPlan.postureName) ready for \(scenario.title)."
        ]
        refresh()
    }

    func completeBattle() -> CampaignCompletionRecord? {
        guard let session else {
            debriefError = "Board session unavailable."
            return nil
        }

        do {
            let result = try PlayableBattleCompletionResolver.completeBattle(from: session)
            completion = result
            debriefError = nil
            refresh()
            recordAIEvent("Debrief recorded: \(result.completionRecord.score) VP, \(result.completionRecord.victoryBand.rawValue).")
            return result.completionRecord
        } catch {
            completion = nil
            debriefError = "\(error)"
            refresh()
            return nil
        }
    }

    private func refresh() {
        snapshot = session?.snapshot()
        lastError = snapshot?.lastAction.detail ?? "Board session unavailable."
    }

    private func recordAIEvent(_ message: String) {
        aiTurnEvents.append(message)
        if aiTurnEvents.count > 8 {
            aiTurnEvents.removeFirst(aiTurnEvents.count - 8)
        }
    }

    private static func makeSession(for scenario: GuderianScenario, restartCount: Int) -> NativeBoardSession? {
        NativeBoardSession(scenario: scenario, seed: UInt32(510_000 + scenario.order + restartCount * 97))
    }

    private static func prioritySummary(_ priorities: [String]) -> String {
        let visiblePriorities = priorities.prefix(3)
        guard !visiblePriorities.isEmpty else {
            return "the scenario objectives"
        }
        return visiblePriorities.joined(separator: ", ")
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
}

struct DZWPlayableBattleView: View {
    @StateObject private var model: DZWPlayableBattleViewModel
    @State private var dragPreview: [Int: CGPoint] = [:]
    @State private var assaultAdvance = true
    @State private var battlefieldZoom: CGFloat = 1
    @State private var visiblePanels: Set<DZWPlayableBattlePanel> = [.command, .inspector]
    private let onCompletion: (CampaignCompletionRecord) -> Void

    init(scenario: GuderianScenario, onCompletion: @escaping (CampaignCompletionRecord) -> Void = { _ in }) {
        _model = StateObject(wrappedValue: DZWPlayableBattleViewModel(scenario: scenario))
        self.onCompletion = onCompletion
    }

    var body: some View {
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

                floatingPanels(snapshot)
            }
            .background(Color(red: 0.10, green: 0.14, blue: 0.10))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("battle-screen")
        } else {
            ContentUnavailableView(
                "Battle board unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(model.lastError)
            )
        }
    }

    private var battlefieldToolbar: some View {
        HStack(spacing: 10) {
            Label("Battlefield", systemImage: "map")
                .font(.system(size: 13, weight: .bold, design: .rounded))

            Button {
                adjustZoom(by: -0.15)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel("Zoom out")

            Slider(value: zoomBinding, in: 0.6...2.2)
                .frame(width: 160)
                .accessibilityIdentifier("battlefield-zoom-slider")

            Text("\(Int((battlefieldZoom * 100).rounded()))%")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .frame(width: 44, alignment: .trailing)

            Button {
                battlefieldZoom = 1
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 24, height: 24)
            }
            .accessibilityLabel("Reset zoom")

            Divider()
                .frame(height: 24)

            ForEach(DZWPlayableBattlePanel.allCases) { panel in
                Button {
                    toggle(panel)
                } label: {
                    Label(panel.title, systemImage: panel.systemImage)
                }
                .tint(visiblePanels.contains(panel) ? Color(red: 0.13, green: 0.32, blue: 0.67) : Color.black.opacity(0.32))
                .accessibilityIdentifier("toggle-\(panel.rawValue)-window")
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

    @ViewBuilder
    private func floatingPanels(_ snapshot: NativeBoardSnapshot) -> some View {
        if visiblePanels.contains(.command) {
            BattleFloatingWindow(
                title: DZWPlayableBattlePanel.command.title,
                systemImage: DZWPlayableBattlePanel.command.systemImage,
                width: 780,
                maxHeight: 700,
                scrollIdentifier: "battle-sidebar-scroll",
                onClose: { toggle(.command) }
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    header(snapshot)
                    actionsSection(snapshot)
                    resultSection(snapshot)
                }
            }
            .padding(.top, 82)
            .padding(.leading, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .zIndex(4)
        }

        if visiblePanels.contains(.inspector) {
            BattleFloatingWindow(
                title: DZWPlayableBattlePanel.inspector.title,
                systemImage: DZWPlayableBattlePanel.inspector.systemImage,
                width: 320,
                maxHeight: 540,
                scrollIdentifier: "battle-inspector-scroll",
                onClose: { toggle(.inspector) }
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    selectionSection(snapshot)
                    objectivesSection(snapshot)
                }
            }
            .padding(.top, 82)
            .padding(.trailing, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .zIndex(5)
        }

        if visiblePanels.contains(.forces) {
            BattleFloatingWindow(
                title: DZWPlayableBattlePanel.forces.title,
                systemImage: DZWPlayableBattlePanel.forces.systemImage,
                width: 360,
                maxHeight: 560,
                scrollIdentifier: "battle-forces-scroll",
                onClose: { toggle(.forces) }
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    armiesSection(snapshot)
                    aiTurnSection()
                }
            }
            .padding(.trailing, 18)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .zIndex(3)
        }

        if visiblePanels.contains(.log) {
            BattleFloatingWindow(
                title: DZWPlayableBattlePanel.log.title,
                systemImage: DZWPlayableBattlePanel.log.systemImage,
                width: 380,
                maxHeight: 460,
                scrollIdentifier: "battle-log-scroll",
                onClose: { toggle(.log) }
            ) {
                logSection(snapshot)
            }
            .padding(.leading, 18)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .zIndex(3)
        }
    }

    private var zoomBinding: Binding<CGFloat> {
        Binding(
            get: { battlefieldZoom },
            set: { battlefieldZoom = clampedZoom($0) }
        )
    }

    private func toggle(_ panel: DZWPlayableBattlePanel) {
        if visiblePanels.contains(panel) {
            visiblePanels.remove(panel)
        } else {
            visiblePanels.insert(panel)
        }
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
                Text("\(model.scenario.title) native scenario")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.92, green: 0.78, blue: 0.42))
                Text("Turn \(snapshot.turnNumber) | \(snapshot.activePlayer.rawValue) | \(snapshot.phase.rawValue)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("battle-phase-label")
                Text("\(snapshot.mission.name) | P1 \(snapshot.mission.playerScore) - \(snapshot.mission.opponentScore) P2")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.92, green: 0.78, blue: 0.42))
                Text(snapshot.mission.winner == .none ? "Native battle in progress" : "\(snapshot.mission.winner.rawValue) wins the scenario")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    model.runAutomatedActiveStep()
                } label: {
                    Label("Auto Step", systemImage: "play.fill")
                }
                .disabled(model.isBattleOver)

                Button {
                    model.runGermanTurn()
                } label: {
                    Label("German Turn", systemImage: "forward.frame.fill")
                }
                .disabled(model.isBattleOver)
                .accessibilityIdentifier("german-turn-button")

                Button {
                    model.advancePhase()
                } label: {
                    Label("Next Phase", systemImage: "forward.end.fill")
                }
                .disabled(model.isBattleOver)
                .accessibilityIdentifier("next-phase-button")

                Button {
                    if let record = model.completeBattle() {
                        onCompletion(record)
                    }
                } label: {
                    Label("Debrief", systemImage: "flag.checkered")
                }
                .disabled(model.hasCompletion)
                .accessibilityIdentifier("battle-debrief-button")

                Button {
                    model.restartBattle()
                } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                }
                .accessibilityIdentifier("battle-restart-button")
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
                Text(selected.name)
                    .font(.title3.weight(.bold))
                Text("\(selected.owner.rawValue) | \(selected.roleLine)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Wounds \(selected.totalWoundsRemaining) | \(selected.inCover ? "Cover" : "Open") | \(selected.hullDown ? "Hull-down" : "Exposed")")
                    .font(.caption.monospaced())
                Text(selected.historicalNote.isEmpty ? "Engine unit: \(selected.engineName)" : selected.historicalNote)
                    .font(.caption.monospaced())
            } else {
                Text("No unit selected")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Prev Ready") {
                    model.cycleActiveUnit(forward: false)
                }
                .accessibilityIdentifier("prev-ready-button")
                Button("Next Ready") {
                    model.cycleActiveUnit(forward: true)
                }
                .accessibilityIdentifier("next-ready-button")
            }
            HStack {
                Button("Nearest Enemy") {
                    model.selectNearestEnemy()
                }
                .accessibilityIdentifier("nearest-enemy-button")
                Button("Clear") {
                    model.clearSelection()
                }
                .accessibilityIdentifier("clear-selection-button")
            }
        }
        .buttonStyle(.bordered)
    }

    private func actionsSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions")
                .font(.headline)

            HStack {
                Button {
                    model.rotateSelected(by: -45)
                } label: {
                    Label("Rotate -45", systemImage: "rotate.left")
                }
                Button {
                    model.rotateSelected(by: 45)
                } label: {
                    Label("Rotate +45", systemImage: "rotate.right")
                }
            }
            .disabled(snapshot.selectedUnit == nil || model.isBattleOver)

            HStack {
                Toggle("Manual Cover", isOn: Binding(
                    get: { snapshot.selectedUnit?.inCover ?? false },
                    set: { model.toggleCover($0) }
                ))
                Toggle("Hull Down", isOn: Binding(
                    get: { snapshot.selectedUnit?.hullDown ?? false },
                    set: { model.toggleHullDown($0) }
                ))
            }
            .font(.caption.weight(.semibold))
            .disabled(snapshot.selectedUnit == nil || model.isBattleOver)

            Button {
                model.shootSelected()
            } label: {
                Label("Shoot Target", systemImage: "scope")
            }
            .disabled(snapshot.phase != .shooting || snapshot.selectedUnit?.canShootNow != true || snapshot.selectedTarget == nil)
            .accessibilityIdentifier("shoot-target-button")

            Toggle("Assault follow-up advances", isOn: $assaultAdvance)
                .font(.caption.weight(.semibold))

            Button {
                model.assaultSelected(advance: assaultAdvance)
            } label: {
                Label("Assault Target", systemImage: "figure.run")
            }
            .disabled(snapshot.phase != .assault || snapshot.selectedUnit?.canAssaultNow != true || snapshot.selectedTarget == nil)
            .accessibilityIdentifier("assault-target-button")

            Button {
                model.resolvePendingChoice()
            } label: {
                Label("Resolve Pending", systemImage: "checkmark.circle")
            }

            Label(snapshot.lastAction.detail, systemImage: snapshot.lastAction.status == .blocked ? "exclamationmark.triangle" : "checkmark.circle")
                .font(.caption)
                .foregroundStyle(snapshot.lastAction.status == .blocked ? .orange : .secondary)
                .accessibilityIdentifier("battle-action-feedback")
        }
        .buttonStyle(.bordered)
    }

    private func resultSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Result")
                .font(.headline)

            if let completion = model.completion {
                Label(completion.completionRecord.victoryBand.rawValue, systemImage: "rosette")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.green)
                Text("\(completion.completionRecord.score) VP | turn \(completion.completionRecord.completedTurn)")
                    .font(.caption.monospaced())
                Text(completion.sourceName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
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
            } else if snapshot.mission.winner == .guderianAI {
                Label("Failure: Guderian AI has won the scenario.", systemImage: "xmark.octagon")
                    .font(.caption)
                    .foregroundStyle(.red)
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
                    Text("\(objective.controller.rawValue) | \(objective.playerPresence)-\(objective.opponentPresence)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.45)))
            }
        }
    }

    private func armiesSection(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Matchup")
                .font(.headline)
            Text("You command the force resisting Guderian's formation. The red force can be inspected and advanced through the same rules-backed board state.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach([NativeBoardPlayer.player, NativeBoardPlayer.guderianAI], id: \.self) { owner in
                let units = snapshot.units.filter { $0.owner == owner }
                VStack(alignment: .leading, spacing: 4) {
                    Text(owner.rawValue)
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
            Text("German AI")
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
    }

    @ViewBuilder
    private func unitToken(_ unit: NativeBoardUnitSnapshot, in size: CGSize) -> some View {
        let gamePoint = dragPreview[unit.id] ?? CGPoint(x: unit.x, y: unit.y)
        let position = boardPoint(gamePoint, in: size)
        let radius = tokenRadius(for: unit, in: size)
        let isSelected = unit.selected || unit.targeted
        let ownerColor = unit.owner == .player ? Color(red: 0.13, green: 0.32, blue: 0.67) : Color(red: 0.63, green: 0.23, blue: 0.16)
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
        .accessibilityLabel("\(unit.name), \(unit.owner.rawValue)")
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
