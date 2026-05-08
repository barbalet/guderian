import GuderianCore
import DerZweiteWeltkriegHistorical
import Foundation
import Metal
import OSLog
import SwiftUI

private let guderianCampaignLog = Logger(subsystem: "com.barbalet.guderian", category: "GuderianCampaign")

private enum GuderianCampaignStorageKeys {
    static let legacyCampaignSave = UnifiedCampaignSaveCodec.migratedCampaignStorageKey
    static let lateCareerProgress = UnifiedCampaignSaveCodec.migratedLateCareerStorageKey
    static let unifiedCampaignSave = UnifiedCampaignSaveCodec.appStorageKey
    static let selectedPlayableSide = "guderian.campaign.selected-side.v1"
    static let selectedPlayableSideByBattle = "guderian.campaign.selected-side-by-battle.v1"
}

private enum LateCareerScopeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case inspectorGeneral = "Inspector"
    case armyGeneralStaff = "General Staff"
    case epilogue = "Epilogue"

    var id: String { rawValue }

    var title: String { rawValue }

    var scope: GuderianCommandScope? {
        switch self {
        case .all:
            return nil
        case .inspectorGeneral:
            return .inspectorGeneralInfluence
        case .armyGeneralStaff:
            return .armyGeneralStaffInfluence
        case .epilogue:
            return .postDismissalContext
        }
    }

    func entries(from catalog: [LateCareerGuderianPresentation]) -> [LateCareerGuderianPresentation] {
        guard let scope else {
            return catalog
        }

        return catalog.filter { $0.scope == scope }
    }
}

public struct GuderianCampaignView: View {
    private let scenarios = GuderianCampaignCatalog.all.sorted { $0.order < $1.order }
    private let lateCareerEntries = LateCareerGuderianPresentationCatalog.allEntries
    @State private var selectedID: GuderianBattleID? = .tucholaForest
    @State private var selectedBattleID = UnifiedGuderianBattleID.fieldCommand(.tucholaForest)
    @State private var progress = CampaignProgress()
    @State private var lateCareerProgress = LateCareerProgress()
    @State private var playMode: CampaignPlayMode = .chronological
    @State private var lateCareerScopeFilter: LateCareerScopeFilter = .all
    @State private var hasLoadedSaveState = false
    @State private var hasLoadedLateCareerState = false
    @State private var hasEvaluatedFirstRunTutorial = false
    @State private var showsFirstRunTutorial = false
    @AppStorage(GuderianCampaignStorageKeys.lateCareerProgress) private var savedLateCareerProgressData = Data()
    @AppStorage(GuderianCampaignStorageKeys.unifiedCampaignSave) private var savedUnifiedCampaignStateData = Data()
    @AppStorage(GuderianCampaignStorageKeys.selectedPlayableSide) private var selectedSideID = GuderianHistoricalSideSelectionResolver.defaultHumanSideID
    @AppStorage(GuderianCampaignStorageKeys.selectedPlayableSideByBattle) private var selectedSideIDsByBattle = ""
    @AppStorage("guderian.tutorial.firstRunHistory.v1.dismissed") private var firstRunHistoryDismissed = false

    private var selectedScenario: GuderianScenario {
        scenarios.first { $0.id == selectedID } ?? scenarios[0]
    }

    private var completionSummary: CampaignCompletionSummary {
        progress.completionSummary(catalog: scenarios)
    }

    private var lateCareerCompletionSummary: LateCareerCompletionSummary {
        lateCareerProgress.completionSummary(catalog: lateCareerEntries)
    }

    private var unifiedProgress: UnifiedCampaignProgress {
        UnifiedCampaignProgressCatalog.progress(
            fieldCommandProgress: progress,
            lateCareerProgress: lateCareerProgress
        )
    }

    private var unifiedCompletionSummary: UnifiedCampaignCompletionSummary {
        unifiedProgress.summary()
    }

    private var unifiedProgressLabel: String {
        unifiedCompletionSummary.progressLabel
    }

    private var unifiedRows: [UnifiedCampaignListRow] {
        UnifiedCampaignListCatalog.rows(
            progress: progress,
            lateCareerProgress: lateCareerProgress,
            playMode: playMode
        )
    }

    private var shipReport: FullCampaignShipReport {
        FullCampaignShipReportCatalog.report(catalog: scenarios)
    }

    private var visibleLateCareerEntries: [LateCareerGuderianPresentation] {
        lateCareerScopeFilter.entries(from: lateCareerEntries)
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                campaignStatusSection
                unifiedBattleListSection
            }
            .listStyle(.inset)
            .navigationTitle("Campaign")
            .navigationDestination(for: UnifiedGuderianBattleID.self) { id in
                switch id.kind {
                case .fieldCommand:
                    if let battleID = id.fieldCommandID,
                       let scenario = scenarios.first(where: { $0.id == battleID }) {
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
                case .lateCareer:
                    if let entry = LateCareerGuderianPresentationCatalog.entry(for: id.rawValue) {
                        UnifiedLateCareerBattleDestinationView(
                            entry: entry,
                            completionRecord: lateCareerProgress.completionRecord(for: entry.id)
                        ) { record in
                            lateCareerProgress.recordCompletion(record)
                        }
                        .navigationTitle(entry.title)
                    }
                }
            }
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
                            markSelectedBattleComplete()
                        } label: {
                            Label("Complete Selected", systemImage: "checkmark.circle")
                        }
                        .accessibilityLabel("Mark selected battle complete")
                        .accessibilityIdentifier("complete-scenario-button")

                        Button {
                            markAllBattlesComplete()
                        } label: {
                            Label("Complete All 35", systemImage: "checkmark.seal")
                        }
                        .accessibilityLabel("Mark all 35 battles complete")
                        .accessibilityIdentifier("complete-all-scenarios-button")

                        Button {
                            progress.reset()
                            lateCareerProgress.reset()
                        } label: {
                            Label("Reset 35", systemImage: "arrow.counterclockwise")
                        }
                        .accessibilityLabel("Reset 35-battle campaign progress")
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
            guderianCampaignLog.info("Campaign view appeared firstRunDismissed=\(firstRunHistoryDismissed, privacy: .public) hasEvaluatedTutorial=\(hasEvaluatedFirstRunTutorial, privacy: .public)")
            loadSavedCampaignState()
            loadSavedLateCareerState()
            presentFirstRunTutorialIfNeeded()
        }
        .onChange(of: selectedID) { _, _ in
            persistCampaignState()
        }
        .onChange(of: selectedBattleID) { _, _ in
            persistCampaignState()
        }
        .onChange(of: progress) { _, _ in
            persistCampaignState()
        }
        .onChange(of: lateCareerProgress) { _, _ in
            persistLateCareerState()
        }
        .onChange(of: playMode) { _, _ in
            persistCampaignState()
        }
        .sheet(isPresented: $showsFirstRunTutorial) {
            FirstRunTutorialView(flow: GuderianTutorialCatalog.firstRunHistoryFlow) { doNotShowAgain in
                guderianCampaignLog.info("First-run tutorial finished doNotShowAgain=\(doNotShowAgain, privacy: .public)")
                if doNotShowAgain {
                    firstRunHistoryDismissed = true
                }
                showsFirstRunTutorial = false
                guderianCampaignLog.info("First-run tutorial sheet dismissed firstRunDismissed=\(firstRunHistoryDismissed, privacy: .public)")
            }
        }
    }

    private var campaignStatusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(unifiedProgressLabel)
                    .font(.headline)
                Text("\(unifiedRows.filter(\.isAvailable).count) available | \(playMode.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(UnifiedCampaignAcceptanceCatalog.acceptanceReadyThroughCycle830 ? UnifiedDocumentationCleanupCatalog.inAppUnifiedLabel : "\(UnifiedCampaignAcceptanceCatalog.report().blockers.count) unified blockers")
                    .font(.caption)
                    .foregroundStyle(UnifiedCampaignAcceptanceCatalog.acceptanceReadyThroughCycle830 ? .green : .orange)
                Text("\(UnifiedGuderianBattleCatalog.allEntries.count) battles | one \(UnifiedGuderianBattleCatalog.hostSurfaceName) UI")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(unifiedProgressLabel), \(unifiedRows.filter(\.isAvailable).count) available, \(UnifiedCampaignAcceptanceCatalog.acceptanceReadyThroughCycle830 ? "unified 35-battle campaign ready" : "unified blockers present")")

            Picker("Play mode", selection: $playMode) {
                Text(CampaignPlayMode.chronological.rawValue).tag(CampaignPlayMode.chronological)
                Text(CampaignPlayMode.standalone.rawValue).tag(CampaignPlayMode.standalone)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Campaign play mode")
        }
    }

    private var unifiedBattleListSection: some View {
        Section(UnifiedCampaignListCatalog.sectionTitle) {
            ForEach(unifiedRows) { row in
                NavigationLink(value: row.id) {
                    unifiedBattleSelectionLabel(for: row)
                }
                .disabled(!row.isAvailable)
                .simultaneousGesture(TapGesture().onEnded {
                    guard row.isAvailable else {
                        return
                    }
                    selectedBattleID = row.id
                    if let battleID = row.id.fieldCommandID {
                        selectedID = battleID
                    }
                })
                .accessibilityIdentifier(row.navigationAccessibilityIdentifier)
            }
        }
    }

    @ViewBuilder
    private func unifiedBattleSelectionLabel(for row: UnifiedCampaignListRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            UnifiedCampaignBattleRow(row: row)

            if let scenario = fieldCommandScenario(for: row) {
                HistoricalBattleSidePicker(
                    scenario: GuderianHistoricalScenarioAdapter.scenario(for: scenario),
                    selectedSideID: sideSelectionBinding(for: scenario),
                    accessibilityIdentifier: "battle-selection-side-picker-\(row.id.rawValue)",
                    optionAccessibilityIDPrefix: "guderian-battle-selection-side-option",
                    isEnabled: row.isAvailable,
                    showsBriefing: false
                )
            }
        }
    }

    private func fieldCommandScenario(for row: UnifiedCampaignListRow) -> GuderianScenario? {
        guard let battleID = row.id.fieldCommandID else {
            return nil
        }
        return scenarios.first { $0.id == battleID }
    }

    private func sideSelectionBinding(for scenario: GuderianScenario) -> Binding<String> {
        Binding(
            get: {
                GuderianHistoricalSideSelectionMemory.selectedSideID(
                    for: scenario,
                    encodedSelections: selectedSideIDsByBattle,
                    fallbackSideID: selectedSideID
                )
            },
            set: { newSideID in
                selectedSideIDsByBattle = GuderianHistoricalSideSelectionMemory.encodedSelections(
                    selectedSideIDsByBattle,
                    selecting: newSideID,
                    for: scenario
                )
            }
        )
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

    private var lateCareerListSection: some View {
        Section(LateCareerGuderianPresentationCatalog.sectionTitle) {
            Picker("Scope", selection: $lateCareerScopeFilter) {
                ForEach(LateCareerScopeFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Late career context scope")

            ForEach(visibleLateCareerEntries) { entry in
                NavigationLink {
                    LateCareerContextBriefingView(
                        entry: entry,
                        completionRecord: lateCareerProgress.completionRecord(for: entry.id)
                    ) { record in
                        lateCareerProgress.recordCompletion(record)
                    }
                        .navigationTitle(entry.title)
                } label: {
                    LateCareerContextRow(entry: entry, progress: lateCareerProgress)
                }
                .accessibilityIdentifier("late-career-row-link-\(entry.id)")
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

    private func markSelectedBattleComplete() {
        switch selectedBattleID.kind {
        case .fieldCommand:
            guard let battleID = selectedBattleID.fieldCommandID,
                  let scenario = scenarios.first(where: { $0.id == battleID }) else {
                return
            }
            let balance = ScenarioContentCatalog.bundle(for: scenario).balance
            progress.recordCompletion(
                CampaignCompletionRecord(
                    scenarioID: scenario.id,
                    score: balance.maxPlayerScore,
                    victoryBand: .operational,
                    completedTurn: balance.targetTurns.upperBound,
                    note: "Marked complete from the unified campaign workspace."
                )
            )
        case .lateCareer:
            if let summary = UnifiedLateCareerScoringDebriefCatalog.completionSummaries.first(where: { $0.completionRecord.battlefieldID == selectedBattleID.rawValue }) {
                lateCareerProgress.recordCompletion(summary.completionRecord)
            }
        }
    }

    private func markAllBattlesComplete() {
        markAllScenariosComplete()
        markAllLateCareerComplete()
    }

    private func markAllLateCareerComplete() {
        lateCareerProgress.recordAllParityCompletions()
    }

    private func persistCampaignState() {
        persistUnifiedCampaignState()
    }

    private func loadSavedCampaignState(force: Bool = false) {
        guard force || !hasLoadedSaveState else {
            return
        }
        hasLoadedSaveState = true

        let legacyCampaignData = Self.legacyCampaignStateData()
        let envelope = UnifiedCampaignSaveCodec.decodeOrMigrate(
            unifiedData: savedUnifiedCampaignStateData,
            legacyCampaignData: legacyCampaignData,
            legacyLateCareerData: savedLateCareerProgressData
        )
        progress = envelope.progress.fieldCommandProgress
        lateCareerProgress = envelope.progress.lateCareerProgress
        playMode = envelope.playMode
        selectedBattleID = envelope.selectedBattleID
        if let battleID = envelope.selectedBattleID.fieldCommandID,
           scenarios.contains(where: { $0.id == battleID }) {
            selectedID = battleID
        }
        hasLoadedLateCareerState = true
        persistUnifiedCampaignState()
        if !legacyCampaignData.isEmpty {
            Self.clearLegacyCampaignStateData()
        }
    }

    private func persistLateCareerState() {
        if let data = try? LateCareerProgressCodec.encode(lateCareerProgress) {
            savedLateCareerProgressData = data
        }
        persistUnifiedCampaignState()
    }

    private func persistUnifiedCampaignState() {
        let envelope = UnifiedCampaignSaveEnvelope(
            selectedBattleID: selectedBattleID,
            playMode: playMode,
            progress: unifiedProgress
        )
        if let data = try? UnifiedCampaignSaveCodec.encode(envelope) {
            savedUnifiedCampaignStateData = data
        }
    }

    private func loadSavedLateCareerState(force: Bool = false) {
        guard force || !hasLoadedLateCareerState else {
            return
        }
        hasLoadedLateCareerState = true
        guard let progress = LateCareerProgressCodec.decodeIfCurrent(savedLateCareerProgressData) else {
            persistLateCareerState()
            return
        }

        lateCareerProgress = progress
    }

    private static func legacyCampaignStateData() -> Data {
        UserDefaults.standard.data(forKey: GuderianCampaignStorageKeys.legacyCampaignSave) ?? Data()
    }

    private static func clearLegacyCampaignStateData() {
        UserDefaults.standard.removeObject(forKey: GuderianCampaignStorageKeys.legacyCampaignSave)
    }

    private func presentFirstRunTutorialIfNeeded() {
        guard !hasEvaluatedFirstRunTutorial else {
            guderianCampaignLog.info("First-run tutorial evaluation skipped because it already ran showsFirstRunTutorial=\(showsFirstRunTutorial, privacy: .public)")
            return
        }
        hasEvaluatedFirstRunTutorial = true
        showsFirstRunTutorial = !firstRunHistoryDismissed
        guderianCampaignLog.info("First-run tutorial evaluated dismissed=\(firstRunHistoryDismissed, privacy: .public) presenting=\(showsFirstRunTutorial, privacy: .public)")
    }

    private func resetTutorialsForDebug() {
        guderianCampaignLog.info("Tutorial debug reset requested.")
        firstRunHistoryDismissed = false
        hasEvaluatedFirstRunTutorial = false
        presentFirstRunTutorialIfNeeded()
    }
}

struct FirstRunTutorialView: View {
    let flow: TutorialFlow
    let onFinish: (Bool) -> Void
    @State private var pageIndex = 0
    @State private var doNotShowAgain = false

    private var currentPage: TutorialPage {
        flow.pages[min(max(0, pageIndex), max(0, flow.pages.count - 1))]
    }

    private var isLastPage: Bool {
        pageIndex >= flow.pages.count - 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flow.title)
                        .font(.title2.weight(.bold))
                    Text("Page \(pageIndex + 1) of \(flow.pages.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("first-run-tutorial-progress")
                }
                Spacer()
                Button {
                    guderianCampaignLog.info("First-run tutorial skip tapped page=\(pageIndex + 1, privacy: .public)")
                    onFinish(false)
                } label: {
                    Label("Skip", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("first-run-tutorial-skip-button")
            }

            ProgressView(value: Double(pageIndex + 1), total: Double(max(1, flow.pages.count)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 12) {
                Text(currentPage.title)
                    .font(.title3.weight(.semibold))
                    .accessibilityIdentifier("first-run-tutorial-page-title")
                Text(currentPage.body)
                    .font(.body)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(currentPage.accessibilityIdentifier)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            if isLastPage {
                Toggle(flow.doNotShowAgainLabel, isOn: $doNotShowAgain)
                    .toggleStyle(.checkbox)
                    .accessibilityIdentifier("first-run-tutorial-do-not-show-again")
            }

            HStack {
                Button {
                    pageIndex = max(0, pageIndex - 1)
                    guderianCampaignLog.info("First-run tutorial back tapped page=\(pageIndex + 1, privacy: .public)")
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .disabled(pageIndex == 0)
                .accessibilityIdentifier("first-run-tutorial-back-button")

                Spacer()

                Button {
                    if isLastPage {
                        guderianCampaignLog.info("First-run tutorial finish tapped page=\(pageIndex + 1, privacy: .public) doNotShowAgain=\(doNotShowAgain, privacy: .public)")
                        onFinish(doNotShowAgain)
                    } else {
                        pageIndex = min(flow.pages.count - 1, pageIndex + 1)
                        guderianCampaignLog.info("First-run tutorial next tapped page=\(pageIndex + 1, privacy: .public)")
                    }
                } label: {
                    Label(isLastPage ? "Finish" : "Next", systemImage: isLastPage ? "checkmark" : "chevron.right")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(isLastPage ? "first-run-tutorial-finish-button" : "first-run-tutorial-next-button")
            }
        }
        .padding(26)
        .frame(width: 620)
        .frame(minHeight: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("first-run-history-tutorial")
        .onAppear {
            guderianCampaignLog.info("First-run tutorial view appeared flow=\(flow.id.rawValue, privacy: .public) pages=\(flow.pages.count, privacy: .public)")
        }
        .onDisappear {
            guderianCampaignLog.info("First-run tutorial view disappeared flow=\(flow.id.rawValue, privacy: .public) finalPage=\(pageIndex + 1, privacy: .public)")
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

struct UnifiedCampaignBattleRow: View {
    let row: UnifiedCampaignListRow

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .frame(width: 18)
                    .accessibilityHidden(true)
                Text("\(row.numberLabel) \(row.title)")
                    .font(.headline)
                Spacer()
                Label(row.playAffordanceTitle, systemImage: "play.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(row.isAvailable ? Color.accentColor : Color.secondary)
            }
            Text(row.dateLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(row.scopeLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let caveatLabel = row.caveatLabel {
                Text(caveatLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.order). \(row.title), \(row.dateLabel), \(row.scopeLabel), \(row.completionState.rawValue), \(row.availability.rawValue)")
        .accessibilityIdentifier(row.rowAccessibilityIdentifier)
    }

    private var iconName: String {
        if row.completionState == .complete {
            return "checkmark.circle.fill"
        }
        if row.isAvailable {
            return "circle.dashed"
        }
        return "lock"
    }

    private var iconColor: Color {
        if row.completionState == .complete {
            return .green
        }
        if row.isAvailable {
            return .accentColor
        }
        return .secondary
    }
}

struct UnifiedLateCareerBattleDestinationView: View {
    let entry: LateCareerGuderianPresentation
    let completionRecord: LateCareerCompletionRecord?
    let onCompletion: (LateCareerCompletionRecord) -> Void

    var body: some View {
        if UnifiedPlayableBoardRouteCatalog.isRoutedToPlayableBattleView(.lateCareer(entry.id)) {
            DZWPlayableBattleView(lateCareerEntry: entry, onCompletion: onCompletion)
                .id(entry.id)
        } else {
            LateCareerSharedBriefingView(
                entry: entry,
                completionRecord: completionRecord,
                onCompletion: onCompletion
            )
        }
    }
}

struct LateCareerSharedBriefingView: View {
    let entry: LateCareerGuderianPresentation
    let completionRecord: LateCareerCompletionRecord?
    let onCompletion: (LateCareerCompletionRecord) -> Void
    @State private var zoom: CGFloat = 1
    @State private var selectedForceID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LateCareerHeader(entry: entry)
                LateCareerMetricStrip(entry: entry)
                LateCareerMapSurface(entry: entry, zoom: $zoom, height: 520)
                LateCareerTextSection(title: "Player Force", text: entry.playerRole, icon: "person.crop.square")
                LateCareerTextSection(title: "German Context", text: entry.germanContext, icon: "bolt.horizontal")
                LateCareerTextSection(title: "Design Intent", text: entry.playableFraming, icon: "scope")
                LateCareerObjectiveGrid(entry: entry)
                LateCareerForceGrid(entry: entry, selectedForceID: $selectedForceID)
                LateCareerRuleList(entry: entry)
                LateCareerSourcesList(entry: entry)
                if let completionRecord {
                    Label("\(completionRecord.score) VP recorded", systemImage: "rosette")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .accessibilityIdentifier("battle-persisted-result")
                }
            }
            .padding(28)
            .frame(maxWidth: 1240, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("unified-battle-briefing-\(entry.id)")
    }
}

struct LateCareerUnifiedPlayableBoardView: View {
    let entry: LateCareerGuderianPresentation
    let onCompletion: (LateCareerCompletionRecord) -> Void
    @State private var zoom: CGFloat = 1
    @State private var completionRecord: LateCareerCompletionRecord?
    @State private var actionLog: [String]

    init(
        entry: LateCareerGuderianPresentation,
        completionRecord: LateCareerCompletionRecord? = nil,
        onCompletion: @escaping (LateCareerCompletionRecord) -> Void = { _ in }
    ) {
        self.entry = entry
        self.onCompletion = onCompletion
        _completionRecord = State(initialValue: completionRecord)
        _actionLog = State(initialValue: [Self.initialLogLine(for: entry)])
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                LateCareerHeader(entry: entry)
                LateCareerMetricStrip(entry: entry)
                LateCareerMapSurface(entry: entry, zoom: $zoom, height: 560)
                    .accessibilityIdentifier("battle-board")
            }
            .padding(20)
            .frame(minWidth: 680, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    playableControls
                    routePanel
                    LateCareerPlayableStatusPanel(entry: entry, report: report, completionRecord: completionRecord)
                        .accessibilityIdentifier("battle-debrief-panel")
                    LateCareerObjectiveGrid(entry: entry)
                    LateCareerRuleList(entry: entry)
                    LateCareerAIPlanPanel(plan: aiPlan)
                    actionLogPanel
                    LateCareerSourcesList(entry: entry)
                }
                .padding(18)
            }
            .frame(width: 390)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("battle-screen")
    }

    private var route: UnifiedPlayableBattleRoute? {
        UnifiedPlayableBoardRouteCatalog.route(for: .lateCareer(entry.id))
    }

    private var report: LateCareerPlayableBattleReport? {
        LateCareerPlayableSurfaceCatalog.report(for: entry.id)
    }

    private var aiPlan: LateCareerAIPlan? {
        LateCareerPlayableSurfaceCatalog.aiPlan(for: entry.id)
    }

    private var boardSnapshot: LateCareerNativeBoardSnapshot? {
        LateCareerNativeBoardSession(battlefieldID: entry.id, seed: UInt32(790_000 + entry.order))?.lateCareerSnapshot()
    }

    private var playableControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Battlefield", systemImage: "map")
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Text(entry.visibleCommandCaveatLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button {
                    runGermanTurn()
                } label: {
                    Label("German Turn", systemImage: "forward.frame.fill")
                }
                .accessibilityIdentifier("german-turn-button")

                Button {
                    completeBattle()
                } label: {
                    Label(completionRecord == nil ? "Debrief" : "Debriefed", systemImage: "flag.checkered")
                }
                .disabled(report == nil || completionRecord != nil)
                .accessibilityIdentifier("battle-debrief-button")
            }

            Label(actionLog.first ?? "Ready.", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("battle-action-feedback")

            if completionRecord != nil {
                Text("Persisted to campaign progress.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("battle-persisted-result")
            }
        }
        .buttonStyle(.borderedProminent)
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var routePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(route?.hostSurfaceName ?? UnifiedGuderianBattleCatalog.hostSurfaceName, systemImage: "play.circle")
                .font(.headline)
            if let boardSnapshot {
                HStack {
                    Label("\(boardSnapshot.unitCount) units", systemImage: "person.3")
                    Label("\(boardSnapshot.objectiveCount) objectives", systemImage: "target")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Text(boardSnapshot.mission.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            if let route {
                Text(route.acceptanceGates.map(\.rawValue).joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var actionLogPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Battle Log", systemImage: "list.bullet.rectangle")
                .font(.headline)
            ForEach(Array(actionLog.enumerated()), id: \.offset) { _, logEntry in
                Text(logEntry)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func runGermanTurn() {
        if let report = UnifiedLateCareerAIExecutionCatalog.report(for: entry.id, seed: UInt32(785_000 + entry.order)),
           let firstStep = report.steps.first {
            actionLog.insert("\(report.germanTurnRunnerName): \(firstStep.action.detail)", at: 0)
        } else {
            let priority = aiPlan?.priorities.first?.targetName ?? "the nearest objective"
            actionLog.insert("German turn runner could not resolve live board pressure toward \(priority).", at: 0)
        }
        actionLog = Array(actionLog.prefix(6))
    }

    private func completeBattle() {
        guard let session = LateCareerNativeBoardSession(battlefieldID: entry.id, seed: UInt32(790_000 + entry.order)),
              let summary = UnifiedLateCareerCompletionResolver.completeBattle(from: session) else {
            actionLog.insert("Debrief is unavailable for \(entry.title).", at: 0)
            actionLog = Array(actionLog.prefix(6))
            return
        }

        completionRecord = summary.completionRecord
        onCompletion(summary.completionRecord)
        actionLog.insert("Debrief recorded: \(summary.completionRecord.score) VP, \(summary.completionRecord.victoryBand.rawValue), \(summary.persistenceKey).", at: 0)
        actionLog = Array(actionLog.prefix(6))
    }

    private static func initialLogLine(for entry: LateCareerGuderianPresentation) -> String {
        "\(entry.title) loaded through the unified DZW-style battle route."
    }
}

struct LateCareerContextRow: View {
    let entry: LateCareerGuderianPresentation
    let progress: LateCareerProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: rowIconName)
                    .foregroundStyle(rowIconColor)
                    .frame(width: 18)
                    .accessibilityHidden(true)
                Text("LC\(entry.order). \(entry.title)")
                    .font(.headline)
                Spacer()
                Text(progress.isCompleted(entry.id) ? "Complete" : entry.readinessLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(progress.isCompleted(entry.id) || entry.isSetAPlayablePilot ? .green : .secondary)
            }
            Text("\(entry.dateLabel) | \(entry.scopeLabel)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.visibleCommandCaveatLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Late career \(entry.order), \(entry.title), \(entry.dateLabel), \(entry.scopeLabel), \(progress.isCompleted(entry.id) ? "complete" : entry.readinessLabel)")
        .accessibilityIdentifier("late-career-row-\(entry.id)")
    }

    private var rowIconName: String {
        if progress.isCompleted(entry.id) {
            return "checkmark.circle.fill"
        }
        if entry.isParityReady {
            return "checkmark.seal"
        }
        if entry.isRoutedToLateCareerPlayableSurface {
            return "play.circle"
        }
        return "doc.text.magnifyingglass"
    }

    private var rowIconColor: Color {
        if progress.isCompleted(entry.id) {
            return .green
        }
        if entry.isParityReady {
            return .green
        }
        if entry.isRoutedToLateCareerPlayableSurface {
            return .accentColor
        }
        return .secondary
    }
}

struct LateCareerContextBriefingView: View {
    let entry: LateCareerGuderianPresentation
    let completionRecord: LateCareerCompletionRecord?
    let onCompletion: (LateCareerCompletionRecord) -> Void
    @State private var zoom: CGFloat = 1
    @State private var selectedForceID: String?

    init(
        entry: LateCareerGuderianPresentation,
        completionRecord: LateCareerCompletionRecord? = nil,
        onCompletion: @escaping (LateCareerCompletionRecord) -> Void = { _ in }
    ) {
        self.entry = entry
        self.completionRecord = completionRecord
        self.onCompletion = onCompletion
    }

    var body: some View {
        if entry.isRoutedToLateCareerPlayableSurface {
            LateCareerPlayablePilotView(
                entry: entry,
                completionRecord: completionRecord,
                onCompletion: onCompletion
            )
        } else {
            briefingWorkspace
        }
    }

    private var briefingWorkspace: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LateCareerHeader(entry: entry)
                LateCareerMetricStrip(entry: entry)
                LateCareerMapSurface(entry: entry, zoom: $zoom, height: 520)
                LateCareerTextSection(title: "Player Role", text: entry.playerRole, icon: "person.crop.square")
                LateCareerTextSection(title: "German Context", text: entry.germanContext, icon: "bolt.horizontal")
                LateCareerTextSection(title: "Playable Framing", text: entry.playableFraming, icon: "scope")
                LateCareerObjectiveGrid(entry: entry)
                LateCareerForceGrid(entry: entry, selectedForceID: $selectedForceID)
                LateCareerRuleList(entry: entry)
                LateCareerSourcesList(entry: entry)
            }
            .padding(28)
            .frame(maxWidth: 1240, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("late-career-briefing-\(entry.id)")
    }
}

struct LateCareerPlayablePilotView: View {
    let entry: LateCareerGuderianPresentation
    let onCompletion: (LateCareerCompletionRecord) -> Void
    @State private var zoom: CGFloat = 1
    @State private var selectedForceID: String?
    @State private var phaseIndex = 0
    @State private var completionRecord: LateCareerCompletionRecord?
    @State private var actionLog: [String]

    private let phases = ["Briefing", "Player Pressure", "German Response", "Assessment"]

    init(
        entry: LateCareerGuderianPresentation,
        completionRecord: LateCareerCompletionRecord? = nil,
        onCompletion: @escaping (LateCareerCompletionRecord) -> Void = { _ in }
    ) {
        self.entry = entry
        self.onCompletion = onCompletion
        _completionRecord = State(initialValue: completionRecord)
        _actionLog = State(initialValue: [Self.initialLogLine(for: entry)])
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                LateCareerHeader(entry: entry)
                LateCareerMetricStrip(entry: entry)
                LateCareerMapSurface(entry: entry, zoom: $zoom, height: 560)
            }
            .padding(20)
            .frame(minWidth: 680, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    pilotControls
                    LateCareerPlayableStatusPanel(entry: entry, report: report, completionRecord: completionRecord)
                    activeForcePanel
                    LateCareerObjectiveGrid(entry: entry)
                    LateCareerRuleList(entry: entry)
                    LateCareerAIPlanPanel(plan: aiPlan)
                    LateCareerRuleBindingPanel(entry: entry)
                    pilotLog
                    LateCareerSourcesList(entry: entry)
                }
                .padding(18)
            }
            .frame(width: 390)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("late-career-playable-pilot-\(entry.id)")
    }

    private var report: LateCareerPlayableBattleReport? {
        entry.playableReport
    }

    private var aiPlan: LateCareerAIPlan? {
        LateCareerPlayableSurfaceCatalog.aiPlan(for: entry.id)
    }

    private var activeForce: LateCareerStaffBattlefieldForce? {
        if let selectedForceID,
           let selected = entry.battlefield.forces.first(where: { $0.id == selectedForceID }) {
            return selected
        }

        return entry.battlefield.forces.first
    }

    private var pilotControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("DZW-Style Surface", systemImage: entry.isParityReady ? "checkmark.seal" : "play.circle")
                .font(.headline)
                .foregroundStyle(entry.isParityReady ? .green : .accentColor)
            Text(entry.visibleCommandCaveatLabel)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Label(phases[phaseIndex], systemImage: "clock.arrow.circlepath")
                    .font(.caption.weight(.semibold))
                Spacer()
                Button {
                    advancePhase()
                } label: {
                    Label("Phase", systemImage: "forward.end")
                }
                .accessibilityIdentifier("late-career-pilot-phase-button-\(entry.id)")
            }

            Button {
                focusNextForce()
            } label: {
                Label("Next Force", systemImage: "scope")
            }
            .accessibilityIdentifier("late-career-pilot-next-force-button-\(entry.id)")

            Button {
                completeBattle()
            } label: {
                Label(completionRecord == nil ? "Debrief" : "Debriefed", systemImage: "rosette")
            }
            .disabled(report == nil || completionRecord != nil)
            .accessibilityIdentifier("late-career-pilot-complete-button-\(entry.id)")
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var activeForcePanel: some View {
        if let activeForce {
            VStack(alignment: .leading, spacing: 8) {
                Label("Selected Force", systemImage: "shield.lefthalf.filled")
                    .font(.headline)
                Text(activeForce.name)
                    .font(.body.weight(.semibold))
                Text(activeForce.side.rawValue)
                    .font(.caption)
                    .foregroundStyle(activeForce.side == .player ? .blue : .red)
                Text(activeForce.role)
                    .font(.callout)
                Text(activeForce.caveat)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityIdentifier("late-career-pilot-active-force-\(entry.id)")
        }
    }

    private var pilotLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Combat Log", systemImage: "list.bullet.rectangle")
                .font(.headline)
            ForEach(Array(actionLog.enumerated()), id: \.offset) { _, logEntry in
                Text(logEntry)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func advancePhase() {
        phaseIndex = (phaseIndex + 1) % phases.count
        actionLog.insert("\(phases[phaseIndex]) phase active for \(entry.title).", at: 0)
        actionLog = Array(actionLog.prefix(6))
    }

    private func focusNextForce() {
        let forces = entry.battlefield.forces
        guard !forces.isEmpty else {
            return
        }

        let currentIndex = selectedForceID.flatMap { id in
            forces.firstIndex { $0.id == id }
        } ?? -1
        let nextIndex = (currentIndex + 1) % forces.count
        selectedForceID = forces[nextIndex].id
        actionLog.insert("Focused \(forces[nextIndex].name).", at: 0)
        actionLog = Array(actionLog.prefix(6))
    }

    private func completeBattle() {
        guard let report else {
            actionLog.insert("Scoring and debrief parity are still planned for \(entry.title).", at: 0)
            actionLog = Array(actionLog.prefix(6))
            return
        }

        completionRecord = report.completionRecord
        onCompletion(report.completionRecord)
        actionLog.insert("Debrief recorded: \(report.completionRecord.score) VP, \(report.completionRecord.victoryBand.rawValue), \(report.completionRecord.persistenceKey).", at: 0)
        actionLog = Array(actionLog.prefix(6))
    }

    private static func initialLogLine(for entry: LateCareerGuderianPresentation) -> String {
        if entry.isParityReady {
            return "\(entry.title) loaded with playable parity, scoring, debrief, AI, and persistence metadata."
        }
        return "\(entry.title) routed to the DZW-style late-career surface with caveated setup metadata."
    }
}

struct LateCareerPlayableStatusPanel: View {
    let entry: LateCareerGuderianPresentation
    let report: LateCareerPlayableBattleReport?
    let completionRecord: LateCareerCompletionRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(entry.isParityReady ? "Parity Ready" : "Routed", systemImage: entry.isParityReady ? "checkmark.seal" : "arrow.triangle.turn.up.right.circle")
                .font(.headline)
                .foregroundStyle(entry.isParityReady ? .green : .accentColor)
            Text(entry.readinessLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let report {
                HStack {
                    Label("\(report.scoringProfile.maxPlayerScore) VP", systemImage: "sum")
                    Label("Turns \(report.scoringProfile.targetTurnLowerBound)-\(report.scoringProfile.targetTurnUpperBound)", systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(completionRecord?.note ?? report.debriefProfile.operationalText)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(completionRecord?.persistenceKey ?? report.scoringProfile.persistenceKey)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            } else {
                Text("Routing is live; scoring, debrief, and persistence parity remain scheduled for a later cycle.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("late-career-playable-status-\(entry.id)")
    }
}

struct LateCareerAIPlanPanel: View {
    let plan: LateCareerAIPlan?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AI Pressure", systemImage: "brain.head.profile")
                .font(.headline)

            if let plan {
                ForEach(plan.priorities) { priority in
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(priority.order). \(priority.targetName)")
                            .font(.caption.weight(.semibold))
                        Text(priority.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Label("Blocked Actions", systemImage: "hand.raised")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 4)

                ForEach(plan.blockedActionExpectations) { expectation in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(expectation.action)
                            .font(.caption.weight(.semibold))
                        Text(expectation.reason)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("AI pressure metadata is not routed yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct LateCareerRuleBindingPanel: View {
    let entry: LateCareerGuderianPresentation

    private var bindings: [LateCareerRuleBinding] {
        LateCareerConsolidatedPlaybookCatalog.ruleBindings(for: entry.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Rule Bindings", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.headline)

            ForEach(bindings) { binding in
                VStack(alignment: .leading, spacing: 3) {
                    Text(binding.family.rawValue)
                        .font(.caption.weight(.semibold))
                    Text(binding.trigger)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(binding.effect)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("late-career-rule-bindings-\(entry.id)")
    }
}

struct LateCareerHeader: View {
    let entry: LateCareerGuderianPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title)
                .font(.system(size: 34, weight: .semibold))
            Text("\(entry.dateLabel) | \(entry.scopeLabel)")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(entry.commandCaveat)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("late-career-header-\(entry.id)")
    }
}

struct LateCareerMetricStrip: View {
    let entry: LateCareerGuderianPresentation

    var body: some View {
        HStack(spacing: 12) {
            Label(entry.readinessLabel, systemImage: readinessIcon)
                .foregroundStyle(readinessColor)
            Label("\(entry.mapFeatureCount) map features", systemImage: "map")
            Label("\(entry.objectiveCount) objectives", systemImage: "target")
            Label("\(entry.forceCount) forces", systemImage: "person.2")
            Label("\(entry.ruleCount) rules", systemImage: "checklist")
            Label("\(entry.sourceCount) sources", systemImage: "link")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private var readinessIcon: String {
        if entry.isParityReady {
            return "checkmark.seal"
        }
        if entry.isRoutedToLateCareerPlayableSurface {
            return "play.circle"
        }
        return "doc.text"
    }

    private var readinessColor: Color {
        if entry.isParityReady {
            return .green
        }
        if entry.isRoutedToLateCareerPlayableSurface {
            return .accentColor
        }
        return .secondary
    }
}

struct LateCareerMapSurface: View {
    let entry: LateCareerGuderianPresentation
    @Binding var zoom: CGFloat
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Battlefield", systemImage: "map")
                    .font(.headline)
                Spacer()
                Slider(value: $zoom, in: 0.75...1.85, step: 0.05)
                    .frame(width: 180)
                    .accessibilityLabel("Late career map zoom")
                Text("\(Int(zoom * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .trailing)
            }

            BattlefieldViewport(
                zoom: $zoom,
                boardWidth: CGFloat(entry.battlefield.map.width),
                boardHeight: CGFloat(entry.battlefield.map.height),
                pointsPerBoardUnit: 16
            ) {
                ScenarioMapView(layout: entry.battlefield.map)
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            }
            .accessibilityIdentifier("late-career-map-viewport-\(entry.id)")
        }
    }
}

struct LateCareerTextSection: View {
    let title: String
    let text: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(text)
                .font(.callout)
        }
    }
}

struct LateCareerObjectiveGrid: View {
    let entry: LateCareerGuderianPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Objectives", systemImage: "target")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(entry.battlefield.objectives) { objective in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(objective.name)
                                .font(.body.weight(.medium))
                            Spacer()
                            Text("\(objective.victoryPoints) VP")
                                .font(.caption.weight(.semibold))
                        }
                        Text(objective.side.rawValue)
                            .font(.caption)
                            .foregroundStyle(objective.side == .player ? .blue : .red)
                        Text(objective.description)
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
}

struct LateCareerForceGrid: View {
    let entry: LateCareerGuderianPresentation
    @Binding var selectedForceID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Forces", systemImage: "person.2")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(entry.battlefield.forces) { force in
                    Button {
                        selectedForceID = force.id
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(force.name)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(force.side.rawValue)
                                .font(.caption)
                                .foregroundStyle(force.side == .player ? .blue : .red)
                            Text(force.role)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(force.caveat)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(force.id == selectedForceID ? Color.accentColor.opacity(0.12) : Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct LateCareerRuleList: View {
    let entry: LateCareerGuderianPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Rules", systemImage: "checklist")
                .font(.headline)
            ForEach(entry.battlefield.rules) { rule in
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name)
                        .font(.body.weight(.medium))
                    Text(rule.trigger)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(rule.effect)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct LateCareerSourcesList: View {
    let entry: LateCareerGuderianPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Sources", systemImage: "link")
                .font(.headline)
            ForEach(entry.battlefield.sourceLinks, id: \.url) { source in
                Link(source.title, destination: source.url)
                    .font(.caption)
            }
        }
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
    @AppStorage(GuderianCampaignStorageKeys.selectedPlayableSide) private var selectedSideID = GuderianHistoricalSideSelectionResolver.defaultHumanSideID
    @AppStorage(GuderianCampaignStorageKeys.selectedPlayableSideByBattle) private var selectedSideIDsByBattle = ""

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

    var historicalScenario: HistoricalBattleScenario<GuderianBattleID> {
        GuderianHistoricalScenarioAdapter.scenario(for: scenario)
    }

    var effectiveSelectedSideID: String {
        GuderianHistoricalSideSelectionMemory.selectedSideID(
            for: scenario,
            encodedSelections: selectedSideIDsByBattle,
            fallbackSideID: selectedSideID
        )
    }

    var sideSelectionBinding: Binding<String> {
        Binding(
            get: { effectiveSelectedSideID },
            set: { newSideID in
                selectedSideIDsByBattle = GuderianHistoricalSideSelectionMemory.encodedSelections(
                    selectedSideIDsByBattle,
                    selecting: newSideID,
                    for: scenario
                )
            }
        )
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
            VStack(spacing: 0) {
                fieldCommandSideSelector
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                    .background(Color(nsColor: .windowBackgroundColor))

                DZWPlayableBattleView(
                    scenario: scenario,
                    chosenSideID: effectiveSelectedSideID,
                    onCompletion: onCompletion
                )
                .id("\(scenario.id.rawValue)-\(effectiveSelectedSideID)")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        } else {
            briefingWorkspace
        }
    }

    private var fieldCommandSideSelector: some View {
        HistoricalBattleSidePicker(
            scenario: historicalScenario,
            selectedSideID: sideSelectionBinding,
            title: "Playable Side",
            accessibilityIdentifier: HistoricalBattleSidePickerDefaults.accessibilityIdentifier,
            optionAccessibilityIDPrefix: "guderian-side-option"
        )
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
            Text(aiPlan.executionMode.rawValue)
                .font(.caption.weight(.semibold))
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
