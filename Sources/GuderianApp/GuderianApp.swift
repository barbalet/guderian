import GuderianCore
import Foundation
import Metal
import SwiftUI

@main
struct GuderianApp: App {
    var body: some Scene {
        WindowGroup("guderian") {
            GuderianCampaignView()
                .frame(minWidth: 1120, minHeight: 760)
        }
        .windowResizability(.contentMinSize)
    }
}

struct GuderianCampaignView: View {
    private let scenarios = GuderianCampaignCatalog.all.sorted { $0.order < $1.order }
    @State private var selectedID: GuderianBattleID? = .tucholaForest
    @State private var progress = CampaignProgress()
    @State private var playMode: CampaignPlayMode = .chronological
    @State private var hasLoadedSaveState = false
    @AppStorage("guderian.campaignSaveState.v1") private var savedCampaignStateData = Data()

    private var selectedScenario: GuderianScenario {
        scenarios.first { $0.id == selectedID } ?? scenarios[0]
    }

    private var completionSummary: CampaignCompletionSummary {
        progress.completionSummary(catalog: scenarios)
    }

    private var shipReport: FullCampaignShipReport {
        FullCampaignShipReportCatalog.report(catalog: scenarios)
    }

    var body: some View {
        NavigationStack {
            List {
                campaignStatusSection
                scenarioListSection
            }
            .listStyle(.inset)
            .navigationTitle("Campaign")
            .navigationDestination(for: GuderianBattleID.self) { id in
                if let scenario = scenarios.first(where: { $0.id == id }) {
                    ScenarioBriefingView(
                        scenario: scenario,
                        progress: progress,
                        playMode: playMode,
                        shipReport: shipReport
                    ) { record in
                        progress.recordCompletion(record)
                    }
                    .navigationTitle(scenario.title)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button {
                            let balance = ScenarioContentCatalog.bundle(for: selectedScenario).balance
                            progress.recordCompletion(
                                CampaignCompletionRecord(
                                    scenarioID: selectedScenario.id,
                                    score: balance.maxPlayerScore,
                                    victoryBand: .operational,
                                    completedTurn: balance.targetTurns.upperBound,
                                    note: "Marked complete from the campaign workspace."
                                )
                            )
                        } label: {
                            Label("Complete", systemImage: "checkmark.circle")
                        }
                        .accessibilityLabel("Mark selected scenario complete")
                        .accessibilityIdentifier("complete-scenario-button")

                        Button {
                            markAllScenariosComplete()
                        } label: {
                            Label("Complete All", systemImage: "checkmark.seal")
                        }
                        .accessibilityLabel("Mark full campaign complete")
                        .accessibilityIdentifier("complete-all-scenarios-button")

                        Button {
                            progress.reset()
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                        .accessibilityLabel("Reset campaign progress")
                        .accessibilityIdentifier("reset-campaign-button")
                    }
                    .buttonStyle(.borderless)

                    HStack {
                        Button {
                            persistCampaignState()
                        } label: {
                            Label("Save", systemImage: "tray.and.arrow.down")
                        }
                        .accessibilityLabel("Save campaign progress")
                        .accessibilityIdentifier("save-campaign-button")

                        Button {
                            loadSavedCampaignState(force: true)
                        } label: {
                            Label("Load", systemImage: "tray.and.arrow.up")
                        }
                        .accessibilityLabel("Load campaign progress")
                        .accessibilityIdentifier("load-campaign-button")
                    }
                    .buttonStyle(.borderless)

                    RendererStatusView()
                }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.bar)
            }
        }
        .onAppear {
            loadSavedCampaignState()
        }
        .onChange(of: selectedID) { _, _ in
            persistCampaignState()
        }
        .onChange(of: progress) { _, _ in
            persistCampaignState()
        }
        .onChange(of: playMode) { _, _ in
            persistCampaignState()
        }
    }

    private var campaignStatusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(completionSummary.progressLabel)
                    .font(.headline)
                Text("\(progress.availableScenarios(in: playMode, catalog: scenarios).count) available | \(playMode.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(shipReport.isShipReady ? "Full campaign ship-ready" : "\(shipReport.blockers.count) ship blockers")
                    .font(.caption)
                    .foregroundStyle(shipReport.isShipReady ? .green : .orange)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(completionSummary.progressLabel), \(progress.availableScenarios(in: playMode, catalog: scenarios).count) available, \(shipReport.isShipReady ? "ship ready" : "ship blockers present")")

            Picker("Play mode", selection: $playMode) {
                Text(CampaignPlayMode.chronological.rawValue).tag(CampaignPlayMode.chronological)
                Text(CampaignPlayMode.standalone.rawValue).tag(CampaignPlayMode.standalone)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Campaign play mode")
        }
    }

    private var scenarioListSection: some View {
        Section("Scenarios") {
            ForEach(scenarios) { scenario in
                NavigationLink(value: scenario.id) {
                    ScenarioRow(scenario: scenario, progress: progress, playMode: playMode)
                }
                .disabled(!progress.isAvailable(scenario, in: playMode))
                .simultaneousGesture(TapGesture().onEnded {
                    if progress.isAvailable(scenario, in: playMode) {
                        selectedID = scenario.id
                    }
                })
                .accessibilityIdentifier("scenario-row-link-\(scenario.id.rawValue)")
            }
        }
    }

    private func markAllScenariosComplete() {
        for scenario in scenarios {
            let balance = ScenarioContentCatalog.bundle(for: scenario).balance
            progress.recordCompletion(
                CampaignCompletionRecord(
                    scenarioID: scenario.id,
                    score: balance.maxPlayerScore,
                    victoryBand: .operational,
                    completedTurn: balance.targetTurns.upperBound,
                    note: "Marked complete during full-campaign ship polish."
                )
            )
        }
    }

    private func persistCampaignState() {
        let state = CampaignSaveState(
            selectedScenarioID: selectedScenario.id,
            playMode: playMode,
            progress: progress
        )
        if let data = try? CampaignSaveCodec.encode(state) {
            savedCampaignStateData = data
        }
    }

    private func loadSavedCampaignState(force: Bool = false) {
        guard force || !hasLoadedSaveState else {
            return
        }
        hasLoadedSaveState = true
        guard let state = CampaignSaveCodec.decodeIfCurrent(savedCampaignStateData) else {
            persistCampaignState()
            return
        }

        progress = state.progress
        playMode = state.playMode
        if scenarios.contains(where: { $0.id == state.selectedScenarioID }) {
            selectedID = state.selectedScenarioID
        }
    }
}

struct ScenarioRow: View {
    let scenario: GuderianScenario
    let progress: CampaignProgress
    let playMode: CampaignPlayMode

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .frame(width: 18)
                    .accessibilityHidden(true)
                Text("\(scenario.order). \(scenario.title)")
                    .font(.headline)
                Spacer()
                if scenario.isDemoScenario {
                    Image(systemName: "flag.checkered")
                        .foregroundStyle(.green)
                        .accessibilityLabel("Demo scenario")
                }
            }
            Text(scenario.dateLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(scenario.theater.rawValue) | \(scenario.playerPosture.rawValue)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scenario.order). \(scenario.title), \(scenario.dateLabel), \(scenario.theater.rawValue), \(progress.isCompleted(scenario.id) ? "complete" : progress.isAvailable(scenario, in: playMode) ? "available" : "locked")")
        .accessibilityIdentifier("scenario-row-\(scenario.id.rawValue)")
    }

    private var iconName: String {
        if progress.isCompleted(scenario.id) {
            return "checkmark.circle.fill"
        }
        if progress.isAvailable(scenario, in: playMode) {
            return "circle.dashed"
        }
        return "lock"
    }

    private var iconColor: Color {
        if progress.isCompleted(scenario.id) {
            return .green
        }
        if progress.isAvailable(scenario, in: playMode) {
            return .accentColor
        }
        return .secondary
    }
}

struct RendererStatusView: View {
    private let deviceName = MTLCreateSystemDefaultDevice()?.name ?? "Unavailable"

    var body: some View {
        Label(deviceName, systemImage: deviceName == "Unavailable" ? "exclamationmark.triangle" : "display")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

struct ScenarioBriefingView: View {
    let scenario: GuderianScenario
    let progress: CampaignProgress
    let playMode: CampaignPlayMode
    let shipReport: FullCampaignShipReport
    let onCompletion: (CampaignCompletionRecord) -> Void
    @State private var logCategory: ScenarioLogCategory? = nil

    var loadout: DZWScenarioLoadout? {
        DZWScenarioLoader.load(scenario.id)
    }

    var content: ScenarioContentBundle {
        ScenarioContentCatalog.bundle(for: scenario)
    }

    var layout: ScenarioMapLayout {
        content.mapLayout
    }

    var aiPlan: GermanAIPlan {
        content.aiPlan
    }

    var setup: ScenarioSetupScript {
        content.setup
    }

    var balance: ScenarioBalanceProfile {
        content.balance
    }

    var historicalOverlay: ScenarioHistoricalOverlay {
        content.historicalOverlay
    }

    var aiSnapshot: GermanAISnapshot {
        GermanAIRefinementCatalog.snapshot(for: scenario)
    }

    var balanceAudit: ScenarioBalanceAudit {
        ScenarioBalanceAuditCatalog.audit(for: scenario)
    }

    var completionSummary: CampaignCompletionSummary {
        progress.completionSummary()
    }

    var logEntries: [ScenarioLogEntry] {
        content.logEntries
    }

    var polishProfile: PolishScenarioSystemProfile? {
        PolishCampaignSystemCatalog.profile(for: scenario)
    }

    var franceProfile: FranceScenarioSystemProfile? {
        FranceCampaignSystemCatalog.profile(for: scenario)
    }

    var easternFrontProfile: EasternFrontScenarioSystemProfile? {
        EasternFrontCampaignSystemCatalog.profile(for: scenario)
    }

    var filteredLogEntries: [ScenarioLogEntry] {
        guard let logCategory else {
            return logEntries
        }
        return logEntries.filter { $0.category == logCategory }
    }

    var body: some View {
        if PlayableBattleSurfaceCatalog.isRoutedToPlayableScreen(scenario.id) {
            DZWPlayableBattleView(scenario: scenario, onCompletion: onCompletion)
                .id(scenario.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
        } else {
            briefingWorkspace
        }
    }

    private var briefingWorkspace: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statusStrip
                if completionSummary.isComplete {
                    campaignCompletionView
                }
                shipReadinessView
                ScenarioMapView(layout: layout)
                    .frame(maxWidth: 1120)
                playableScreenRolloutView
                NativeBattleBoardView(scenario: scenario)
                    .id(scenario.id)
                    .frame(maxWidth: 1120)
                briefingSection("Player Force", scenario.playerForceSummary, icon: "shield.lefthalf.filled")
                briefingSection("Guderian Command", scenario.guderianCommand, icon: "bolt.horizontal")
                briefingSection("Design Intent", scenario.designIntent, icon: "scope")
                historicalOverlayView
                forceOrder
                polishSystemView
                franceSystemView
                easternFrontSystemView
                objectives
                balanceView
                balanceAuditView
                reinforcementsView
                triggers
                aiPlanView
                aiRefinementView
                tutorialView
                scenarioLog
                debriefView
                terrain
                engineMapping
                sources
            }
            .padding(28)
            .frame(maxWidth: 1240, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(scenario.title)
                .font(.system(size: 34, weight: .semibold))
            Text("\(scenario.dateLabel) | \(scenario.theater.rawValue)")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(scenario.historicalResult)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var historicalOverlayView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Historical Overlay", systemImage: "book")
                .font(.headline)
            Text(historicalOverlay.commanderContext)
                .font(.callout)
            Text(historicalOverlay.mapNote)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(historicalOverlay.outcomeSummary)
                .font(.callout)
                .foregroundStyle(.secondary)

            ForEach(historicalOverlay.caveats, id: \.self) { caveat in
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                    Text(caveat)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statusStrip: some View {
        HStack(spacing: 12) {
            Label(scenario.status.rawValue, systemImage: "checklist")
            Label(scenario.playerPosture.rawValue, systemImage: "person.crop.square")
            Label(progress.isCompleted(scenario.id) ? "Complete" : "Open", systemImage: progress.isCompleted(scenario.id) ? "checkmark.circle" : "circle")
            Label(progress.isAvailable(scenario, in: playMode) ? "Available" : "Locked", systemImage: progress.isAvailable(scenario, in: playMode) ? "lock.open" : "lock")
            if scenario.isDemoScenario {
                Label("Demo", systemImage: "flag.checkered")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private var campaignCompletionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(completionSummary.completionTitle, systemImage: "rosette")
                .font(.headline)
            Text(completionSummary.completionMessage)
                .font(.callout)
            HStack {
                Label(completionSummary.progressLabel, systemImage: "checkmark.circle")
                Label("\(completionSummary.totalScore) campaign VP", systemImage: "sum")
                Label("\(completionSummary.victoryBands.values.reduce(0, +)) recorded results", systemImage: "chart.bar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("campaign-completion-panel")
    }

    private var shipReadinessView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Full Campaign Ship", systemImage: shipReport.isShipReady ? "checkmark.seal" : "exclamationmark.triangle")
                .font(.headline)
                .foregroundStyle(shipReport.isShipReady ? .green : .orange)
            HStack {
                Label(shipReport.cycleLabel, systemImage: "calendar")
                Label("\(shipReport.scenarioCount) scenarios", systemImage: "list.number")
                Label("\(shipReport.proxyLoadableCount) proxy loads", systemImage: "gearshape.2")
                Label("\(shipReport.handAuthoredCount) hand-authored", systemImage: "square.and.pencil")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ForEach(shipReport.releaseChecklist) { item in
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: item.status == .passed ? "checkmark.circle" : "exclamationmark.triangle")
                        .foregroundStyle(item.status == .passed ? .green : .orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.body.weight(.medium))
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Label("Release Budgets", systemImage: "speedometer")
                .font(.subheadline.weight(.semibold))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(shipReport.performanceBudgets) { budget in
                    VStack(alignment: .leading, spacing: 3) {
                        Label("\(budget.measuredCount)/\(budget.limit)", systemImage: budget.isPassing ? "checkmark.circle" : "exclamationmark.triangle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(budget.isPassing ? .green : .orange)
                        Text(budget.title)
                            .font(.caption)
                        Text(budget.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Label("Accessibility", systemImage: "accessibility")
                .font(.subheadline.weight(.semibold))
            ForEach(shipReport.accessibilityItems) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.caption.weight(.semibold))
                    Text(item.coverage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Label("Credits", systemImage: "text.book.closed")
                .font(.subheadline.weight(.semibold))
            ForEach(shipReport.credits) { credit in
                VStack(alignment: .leading, spacing: 2) {
                    Text(credit.title)
                        .font(.caption.weight(.semibold))
                    Text("\(credit.detail) \(credit.sourcePathOrURL)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ship-readiness-panel")
    }

    private var playableScreenRolloutView: some View {
        let plan = PlayableBattleSurfaceCatalog.plan(for: scenario.id)
        return VStack(alignment: .leading, spacing: 8) {
            Label("Playable Screen Rollout", systemImage: "checkerboard.rectangle")
                .font(.headline)
            if let plan {
                let isPlayableComplete = plan.readiness.isPlayableComplete
                HStack {
                    Label(plan.readiness.rawValue, systemImage: isPlayableComplete ? "checkmark.circle" : "clock")
                    Label(plan.cycleLabel, systemImage: "calendar")
                    Label(plan.hostSurfaceName, systemImage: "rectangle.3.group")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(plan.acceptanceGates, id: \.self) { gate in
                        Label(gate.rawValue, systemImage: isPlayableComplete ? "checkmark.circle" : "circle")
                            .font(.caption)
                            .foregroundStyle(isPlayableComplete ? .green : .secondary)
                    }
                }
                ForEach(plan.notes, id: \.self) { note in
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("playable-screen-rollout-panel")
    }

    private func briefingSection(_ title: String, _ value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    private var forceOrder: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Force Setup", systemImage: "person.3.sequence")
                .font(.headline)
            Text(setup.playerBriefing)
                .font(.callout)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(setup.units) { unit in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(unit.side.rawValue, systemImage: unit.side == .player ? "shield" : "bolt")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(unit.side == .player ? .blue : .red)
                        Text(unit.name)
                            .font(.body.weight(.medium))
                        Text(unit.role)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(unit.historicalNote)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    @ViewBuilder
    private var polishSystemView: some View {
        if let polishProfile {
            VStack(alignment: .leading, spacing: 10) {
                Label("Polish Campaign Systems", systemImage: "shield.righthalf.filled")
                    .font(.headline)
                Text(polishProfile.operationalProblem)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(polishProfile.playerDoctrine)
                    .font(.callout)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 10)], alignment: .leading, spacing: 10) {
                    ForEach(polishProfile.assets) { asset in
                        VStack(alignment: .leading, spacing: 4) {
                            Label(asset.kind.rawValue, systemImage: "shield")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.blue)
                            Text(asset.name)
                                .font(.body.weight(.medium))
                            Text(asset.battlefieldRole)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(asset.limitation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                ForEach(polishProfile.specialRules) { rule in
                    HStack(alignment: .firstTextBaseline) {
                        Text(rule.name)
                            .font(.caption.weight(.semibold))
                            .frame(width: 140, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.trigger)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(rule.effect)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var franceSystemView: some View {
        if let franceProfile {
            VStack(alignment: .leading, spacing: 10) {
                Label("France 1940 Systems", systemImage: "tank")
                    .font(.headline)
                Text(franceProfile.operationalProblem)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(franceProfile.playerDoctrine)
                    .font(.callout)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 10)], alignment: .leading, spacing: 10) {
                    ForEach(franceProfile.assets) { asset in
                        VStack(alignment: .leading, spacing: 4) {
                            Label(asset.kind.rawValue, systemImage: "shield")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.blue)
                            Text(asset.name)
                                .font(.body.weight(.medium))
                            Text(asset.battlefieldRole)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(asset.limitation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                ForEach(franceProfile.specialRules) { rule in
                    HStack(alignment: .firstTextBaseline) {
                        Text(rule.name)
                            .font(.caption.weight(.semibold))
                            .frame(width: 140, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.trigger)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(rule.effect)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var easternFrontSystemView: some View {
        if let easternFrontProfile {
            VStack(alignment: .leading, spacing: 10) {
                Label("Eastern Front Systems", systemImage: "map")
                    .font(.headline)
                Text(easternFrontProfile.operationalProblem)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(easternFrontProfile.playerDoctrine)
                    .font(.callout)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 10)], alignment: .leading, spacing: 10) {
                    ForEach(easternFrontProfile.assets) { asset in
                        VStack(alignment: .leading, spacing: 4) {
                            Label(asset.kind.rawValue, systemImage: "shield")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.blue)
                            Text(asset.name)
                                .font(.body.weight(.medium))
                            Text(asset.battlefieldRole)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(asset.limitation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                ForEach(easternFrontProfile.specialRules) { rule in
                    HStack(alignment: .firstTextBaseline) {
                        Text(rule.name)
                            .font(.caption.weight(.semibold))
                            .frame(width: 140, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.trigger)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(rule.effect)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var balanceView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Balance", systemImage: "scale.3d")
                .font(.headline)
            Text(balance.balanceIntent)
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack {
                Label("Turns \(balance.targetTurns.lowerBound)-\(balance.targetTurns.upperBound)", systemImage: "clock")
                Label("\(balance.maxPlayerScore) player VP available", systemImage: "sum")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ForEach(balance.scoreChannels) { channel in
                HStack(alignment: .firstTextBaseline) {
                    Text("\(channel.victoryPoints) VP")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(channel.side == .guderianAI ? .red : .blue)
                        .frame(width: 54, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.name)
                            .font(.body.weight(.medium))
                        Text("\(channel.side.rawValue) | \(channel.timing)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(channel.description)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var balanceAuditView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Balance Audit", systemImage: "checkmark.seal")
                .font(.headline)
            Text(balanceAudit.agencyNote)
                .font(.callout)
            Text(balanceAudit.pressureNote)
                .font(.callout)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(balanceAudit.victoryGradeCount) grades", systemImage: "chart.bar")
                Label("\(balanceAudit.maximumPlayerScore) max VP", systemImage: "sum")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var reinforcementsView: some View {
        if !balance.reinforcements.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Reinforcements", systemImage: "arrow.down.forward.and.arrow.up.backward")
                    .font(.headline)
                ForEach(balance.reinforcements) { reinforcement in
                    HStack(alignment: .firstTextBaseline) {
                        Text(reinforcement.turnWindow)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 72, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reinforcement.unitName)
                                .font(.body.weight(.medium))
                            Text("\(reinforcement.side.rawValue) | \(reinforcement.role)")
                                .font(.caption)
                                .foregroundStyle(reinforcement.side == .player ? .blue : .red)
                            Text(reinforcement.entryCondition)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var objectives: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Objectives", systemImage: "target")
                .font(.headline)
            ForEach(scenario.objectives, id: \.name) { objective in
                HStack(alignment: .firstTextBaseline) {
                    Text("\(objective.victoryPoints) VP")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 52, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(objective.name)
                            .font(.body.weight(.medium))
                        Text(objective.description)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var scenarioLog: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Operation Log", systemImage: "line.3.horizontal.decrease.circle")
                .font(.headline)
            Picker("Log filter", selection: $logCategory) {
                Text("All").tag(Optional<ScenarioLogCategory>.none)
                ForEach(ScenarioLogCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(Optional(category))
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Filter operation log")

            ForEach(filteredLogEntries) { entry in
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.turnWindow)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 88, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title)
                            .font(.body.weight(.medium))
                        Text(entry.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(entry.detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var debriefView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Debrief Bands", systemImage: "chart.bar")
                .font(.headline)
            Text(balance.playerWinCondition)
                .font(.callout)
                .foregroundStyle(.secondary)
            ForEach(balance.outcomeBands) { outcome in
                HStack(alignment: .firstTextBaseline) {
                    Text("\(outcome.scoreRange.lowerBound)-\(outcome.scoreRange.upperBound)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 54, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(outcome.grade.rawValue)
                            .font(.body.weight(.medium))
                        Text(outcome.summary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var triggers: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Scenario Triggers", systemImage: "bolt.badge.clock")
                .font(.headline)
            ForEach(setup.triggers) { trigger in
                VStack(alignment: .leading, spacing: 2) {
                    Text(trigger.name)
                        .font(.body.weight(.medium))
                    Text(trigger.condition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(trigger.effect)
                        .font(.callout)
                }
            }
        }
    }

    private var aiPlanView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Guderian AI Plan", systemImage: "arrow.triangle.branch")
                .font(.headline)
            Text(aiPlan.postureName)
                .font(.body.weight(.medium))
            Text(aiPlan.strategicGoal)
                .font(.callout)
                .foregroundStyle(.secondary)
            ForEach(aiPlan.orders) { order in
                HStack(alignment: .firstTextBaseline) {
                    Text(order.turnWindow)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 72, alignment: .leading)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(order.kind.rawValue): \(order.target)")
                            .font(.body.weight(.medium))
                        Text(order.instruction)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var aiRefinementView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AI Refinement", systemImage: "slider.horizontal.3")
                .font(.headline)
            Text("Primary order: \(aiSnapshot.primaryOrderID)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Seed hint: \(aiSnapshot.deterministicSeedHint)")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(aiSnapshot.difficultyTiers, id: \.self) { tier in
                    Text(tier.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            ForEach(aiSnapshot.fallbackBehaviors) { behavior in
                VStack(alignment: .leading, spacing: 2) {
                    Text(behavior.trigger)
                        .font(.caption.weight(.semibold))
                    Text(behavior.response)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var tutorialView: some View {
        if !setup.tutorialSteps.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Tutorial Flow", systemImage: "graduationcap")
                    .font(.headline)
                ForEach(setup.tutorialSteps) { step in
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "smallcircle.filled.circle")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.body.weight(.medium))
                            Text(step.instruction)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var terrain: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Terrain", systemImage: "map")
                .font(.headline)
            ForEach(scenario.mapFeatures, id: \.name) { feature in
                HStack(alignment: .firstTextBaseline) {
                    Text(feature.name)
                        .font(.body.weight(.medium))
                        .frame(width: 180, alignment: .leading)
                    Text(feature.role)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var engineMapping: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Engine Load", systemImage: "gearshape.2")
                .font(.headline)
            if let loadout {
                Text("\(loadout.playerArmyName) vs \(loadout.opponentArmyName)")
                    .font(.body.weight(.medium))
                ForEach(loadout.adapterNotes, id: \.self) { note in
                    Text(note)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Sources", systemImage: "link")
                .font(.headline)
            ForEach(scenario.sourceLinks, id: \.url) { source in
                Link(source.title, destination: source.url)
                    .font(.callout)
            }
        }
    }
}

@MainActor
struct NativeBattleBoardCompletionSummary: Equatable {
    let sourceName: String
    let victoryBand: String
    let score: Int
    let completedTurn: Int
    let outcomeSummary: String
}

@MainActor
final class NativeBattleBoardViewModel: ObservableObject {
    @Published private(set) var snapshot: NativeBoardSnapshot?
    @Published private(set) var completion: NativeBattleBoardCompletionSummary?
    @Published private(set) var debriefError: String?

    private let scenario: GuderianScenario
    private var session: NativeBoardSession?

    init(scenario: GuderianScenario) {
        self.scenario = scenario
        session = NativeBoardSession(scenario: scenario, seed: UInt32(120_000 + scenario.order))
        refresh()
    }

    var canCompleteNativeBattle: Bool {
        NativeDemoParityRunner.playableBattleIDs.contains(scenario.id) ||
            NativePolandBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id) ||
            NativeFranceBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id) ||
            NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id)
    }

    func select(_ unit: NativeBoardUnitSnapshot) {
        guard let session else {
            return
        }
        if unit.owner == snapshot?.activePlayer {
            session.selectUnit(unit.id)
            session.selectNearestEnemyToSelectedUnit()
        } else {
            session.selectTarget(unit.id)
        }
        refresh()
    }

    func moveSelectedUnit() {
        session?.moveSelectedUnitTowardNearestObjective()
        refresh()
    }

    func shootSelectedTarget() {
        session?.shootSelectedTarget()
        refresh()
    }

    func advancePhase() {
        session?.advancePhase()
        refresh()
    }

    func resolvePendingChoice() {
        session?.resolveFirstPendingChoice()
        refresh()
    }

    func completeNativeBattle() {
        guard let session else {
            debriefError = "Board session unavailable."
            return
        }
        do {
            if NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id) {
                completion = try completionSummary(from: NativeEasternFrontPackRunner.completeBattle(from: session))
            } else if NativeFranceBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id) {
                completion = try completionSummary(from: NativeFrancePackRunner.completeBattle(from: session))
            } else if NativePolandBattlefieldPackCatalog.playableBattleIDs.contains(scenario.id) {
                completion = try completionSummary(from: NativePolandPackRunner.completeBattle(from: session))
            } else {
                completion = try completionSummary(from: NativeDemoParityRunner.completeBattle(from: session))
            }
            debriefError = nil
        } catch {
            completion = nil
            debriefError = "\(error)"
        }
        refresh()
    }

    private func completionSummary(from report: NativeDemoBattleCompletionReport) -> NativeBattleBoardCompletionSummary {
        NativeBattleBoardCompletionSummary(
            sourceName: "Native Demo",
            victoryBand: report.victoryBand.rawValue,
            score: report.score,
            completedTurn: report.completedTurn,
            outcomeSummary: report.outcomeSummary
        )
    }

    private func completionSummary(from report: NativePolandCompletionReport) -> NativeBattleBoardCompletionSummary {
        NativeBattleBoardCompletionSummary(
            sourceName: "Native Poland Pack",
            victoryBand: report.completionRecord.victoryBand.rawValue,
            score: report.completionRecord.score,
            completedTurn: report.completionRecord.completedTurn,
            outcomeSummary: report.debriefSummary
        )
    }

    private func completionSummary(from report: NativeFranceCompletionReport) -> NativeBattleBoardCompletionSummary {
        NativeBattleBoardCompletionSummary(
            sourceName: "Native France Pack",
            victoryBand: report.completionRecord.victoryBand.rawValue,
            score: report.completionRecord.score,
            completedTurn: report.completionRecord.completedTurn,
            outcomeSummary: report.debriefSummary
        )
    }

    private func completionSummary(from report: NativeEasternFrontCompletionReport) -> NativeBattleBoardCompletionSummary {
        NativeBattleBoardCompletionSummary(
            sourceName: "Native Eastern Front Pack",
            victoryBand: report.completionRecord.victoryBand.rawValue,
            score: report.completionRecord.score,
            completedTurn: report.completionRecord.completedTurn,
            outcomeSummary: report.debriefSummary
        )
    }

    private func refresh() {
        snapshot = session?.snapshot()
    }
}

struct NativeBattleBoardView: View {
    @StateObject private var model: NativeBattleBoardViewModel

    init(scenario: GuderianScenario) {
        _model = StateObject(wrappedValue: NativeBattleBoardViewModel(scenario: scenario))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Native Battle Board", systemImage: "square.grid.3x3")
                .font(.headline)

            if let snapshot = model.snapshot {
                HStack(alignment: .top, spacing: 14) {
                    board(snapshot)
                    boardControls(snapshot)
                }
            } else {
                Label("Board session unavailable", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("native-battle-board")
    }

    private func board(_ snapshot: NativeBoardSnapshot) -> some View {
        GeometryReader { proxy in
            ZStack {
                Rectangle()
                    .fill(Color(red: 0.69, green: 0.73, blue: 0.62))
                boardGrid(in: proxy.size)

                ForEach(snapshot.zones) { zone in
                    terrainZone(zone, in: proxy.size)
                }

                ForEach(snapshot.objectives) { objective in
                    objectiveMarker(objective, in: proxy.size)
                }

                ForEach(snapshot.units) { unit in
                    unitButton(unit, in: proxy.size, activePlayer: snapshot.activePlayer)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.18), lineWidth: 1)
            }
        }
        .aspectRatio(72 / 48, contentMode: .fit)
        .frame(minWidth: 520)
    }

    private func boardControls(_ snapshot: NativeBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.mission.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text("Turn \(snapshot.turnNumber) | \(snapshot.activePlayer.rawValue) | \(snapshot.phase.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(snapshot.mission.playerScore)-\(snapshot.mission.opponentScore) / \(snapshot.mission.targetScore) VP")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button {
                    model.moveSelectedUnit()
                } label: {
                    Label("Move", systemImage: "arrow.up.right")
                }
                .disabled(snapshot.phase != .movement || snapshot.selectedUnit?.canMoveNow != true)

                Button {
                    model.shootSelectedTarget()
                } label: {
                    Label("Fire", systemImage: "scope")
                }
                .disabled(snapshot.phase != .shooting || snapshot.selectedUnit?.canShootNow != true || snapshot.selectedTarget == nil)
            }
            .buttonStyle(.bordered)

            HStack {
                Button {
                    model.resolvePendingChoice()
                } label: {
                    Label("Resolve", systemImage: "checkmark.circle")
                }

                Button {
                    model.advancePhase()
                } label: {
                    Label("Phase", systemImage: "forward.end")
                }
            }
            .buttonStyle(.bordered)

            if model.canCompleteNativeBattle {
                Button {
                    model.completeNativeBattle()
                } label: {
                    Label("Debrief", systemImage: "flag.checkered")
                }
                .buttonStyle(.borderedProminent)
            }

            if let completion = model.completion {
                VStack(alignment: .leading, spacing: 3) {
                    Label(completion.victoryBand, systemImage: "rosette")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    Text("\(completion.score) VP | turn \(completion.completedTurn)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(completion.sourceName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(completion.outcomeSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            } else if let debriefError = model.debriefError {
                Label(debriefError, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            if let selected = snapshot.selectedUnit {
                VStack(alignment: .leading, spacing: 3) {
                    Label(selected.name, systemImage: "dot.scope")
                        .font(.caption.weight(.semibold))
                    Text("\(selected.kind) | \(selected.owner.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Wounds \(selected.totalWoundsRemaining), \(selected.inCover ? "in cover" : "open"), \(selected.hullDown ? "hull-down" : "exposed")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Label(snapshot.lastAction.title, systemImage: snapshot.lastAction.status == .blocked ? "exclamationmark.triangle" : "checkmark.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(snapshot.lastAction.status == .blocked ? .orange : .secondary)
                Text(snapshot.lastAction.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Divider()

            ForEach(snapshot.logLines.suffix(5), id: \.self) { line in
                Text(line)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 260, alignment: .topLeading)
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
        .stroke(Color.primary.opacity(0.07), lineWidth: 1)
    }

    private func terrainZone(_ zone: NativeBoardZoneSnapshot, in size: CGSize) -> some View {
        Rectangle()
            .fill(terrainColor(zone).opacity(zone.kind == "Impassable" ? 0.42 : 0.28))
            .overlay {
                Rectangle()
                    .stroke(terrainColor(zone).opacity(0.65), lineWidth: zone.blocksLineOfSight ? 2 : 1)
            }
            .frame(
                width: max(8, size.width * zone.width / 72),
                height: max(8, size.height * zone.height / 48)
            )
            .position(
                x: size.width * (zone.x + zone.width / 2) / 72,
                y: size.height * (zone.y + zone.height / 2) / 48
            )
            .accessibilityLabel(zone.name)
    }

    private func objectiveMarker(_ objective: NativeBoardObjectiveSnapshot, in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(objectiveColor(objective.controller).opacity(0.78))
                .frame(width: max(22, objective.radius * 6), height: max(22, objective.radius * 6))
            Image(systemName: "target")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .position(x: size.width * objective.x / 72, y: size.height * objective.y / 48)
        .accessibilityLabel(objective.name)
    }

    private func unitButton(_ unit: NativeBoardUnitSnapshot, in size: CGSize, activePlayer: NativeBoardPlayer) -> some View {
        Button {
            model.select(unit)
        } label: {
            Image(systemName: unitSymbol(unit))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: unit.selected || unit.targeted ? 28 : 24, height: unit.selected || unit.targeted ? 28 : 24)
                .background(unitColor(unit.owner))
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(unit.selected ? Color.yellow : unit.targeted ? Color.white : Color.black.opacity(0.18), lineWidth: unit.selected || unit.targeted ? 3 : 1)
                }
                .opacity(unit.destroyed ? 0.35 : activePlayer == unit.owner ? 1 : 0.86)
        }
        .buttonStyle(.plain)
        .position(x: size.width * unit.x / 72, y: size.height * unit.y / 48)
        .accessibilityLabel("\(unit.name), \(unit.owner.rawValue)")
    }

    private func terrainColor(_ zone: NativeBoardZoneSnapshot) -> Color {
        if zone.kind == "Impassable" {
            return Color(red: 0.12, green: 0.36, blue: 0.66)
        }
        if zone.hullDown {
            return Color(red: 0.45, green: 0.43, blue: 0.34)
        }
        if zone.blocksLineOfSight {
            return Color(red: 0.23, green: 0.43, blue: 0.26)
        }
        return Color(red: 0.48, green: 0.42, blue: 0.34)
    }

    private func unitColor(_ player: NativeBoardPlayer) -> Color {
        switch player {
        case .player:
            return Color(red: 0.10, green: 0.33, blue: 0.68)
        case .guderianAI:
            return Color(red: 0.62, green: 0.14, blue: 0.11)
        case .none:
            return .secondary
        }
    }

    private func objectiveColor(_ player: NativeBoardPlayer) -> Color {
        switch player {
        case .player:
            return Color(red: 0.10, green: 0.45, blue: 0.62)
        case .guderianAI:
            return Color(red: 0.68, green: 0.22, blue: 0.12)
        case .none:
            return Color(red: 0.38, green: 0.30, blue: 0.62)
        }
    }

    private func unitSymbol(_ unit: NativeBoardUnitSnapshot) -> String {
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
