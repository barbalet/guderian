import GuderianCore
#if SWIFT_PACKAGE
import GuderianAppUI
#endif
import SwiftUI

@main
struct GuderianTestApp: App {
    var body: some Scene {
        WindowGroup("GuderianTest") {
            GuderianCampaignView()
                .frame(minWidth: 1120, minHeight: 760)
        }
        .windowResizability(.contentMinSize)

        WindowGroup("GuderianTest Playability") {
            GuderianTestDashboard()
                .frame(minWidth: 1180, minHeight: 760)
        }
        .windowResizability(.contentMinSize)
    }
}

@MainActor
final class GuderianTestViewModel: ObservableObject {
    @Published private(set) var reports: [CampaignAutomationBattleReport] = []
    @Published private(set) var lateCareerReport = LateCareerAutomationCatalog.runAll
    @Published private(set) var isRunning = false
    @Published private(set) var focusedID: GuderianBattleID? = GuderianCampaignCatalog.all.first?.id

    private var runTask: Task<Void, Never>?

    var summary: CampaignAutomationRunReport {
        CampaignAutomationRunReport(
            reports: reports,
            completionSummary: completionProgress.completionSummary(catalog: GuderianCampaignCatalog.all)
        )
    }

    private var completionProgress: CampaignProgress {
        var progress = CampaignProgress()
        for report in reports where report.status == .passed || report.status == .warning {
            if let record = report.completionRecord {
                progress.recordCompletion(record)
                continue
            }
            guard let scenario = GuderianCampaignCatalog.scenario(id: report.id) else {
                continue
            }
            let balance = ScenarioBalanceCatalog.profile(for: scenario)
            progress.recordCompletion(
                CampaignCompletionRecord(
                    scenarioID: report.id,
                    score: balance.maxPlayerScore,
                    victoryBand: report.status == .passed ? .operational : .tactical,
                    completedTurn: report.finalTurn,
                    note: "Recorded by GuderianTest dashboard."
                )
            )
        }
        return progress
    }

    func report(for id: GuderianBattleID) -> CampaignAutomationBattleReport? {
        reports.first { $0.id == id }
    }

    func start() {
        guard !isRunning else {
            return
        }

        reports = []
        lateCareerReport = LateCareerAutomationCatalog.runAll
        isRunning = true
        runTask = Task {
            var progress = CampaignProgress()
            for scenario in GuderianCampaignCatalog.all.sorted(by: { $0.order < $1.order }) {
                guard !Task.isCancelled else {
                    break
                }
                if focusedID == nil {
                    focusedID = scenario.id
                }

                let report = CampaignAutomationRunner.runBattle(
                    scenario,
                    progress: &progress,
                    options: .appDefault
                )
                reports.append(report)
                focusedID = report.id
                try? await Task.sleep(nanoseconds: 70_000_000)
            }
            isRunning = false
        }
    }

    func stop() {
        runTask?.cancel()
        runTask = nil
        isRunning = false
    }

    func reset() {
        stop()
        reports = []
        lateCareerReport = LateCareerAutomationCatalog.runAll
        focusedID = GuderianCampaignCatalog.all.first?.id
    }
}

struct GuderianTestDashboard: View {
    @StateObject private var viewModel = GuderianTestViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                runHeader
                Divider()
                battleList
            }
            .navigationTitle("Battles")
            .navigationDestination(for: GuderianBattleID.self) { id in
                if let scenario = GuderianCampaignCatalog.scenario(id: id) {
                    GuderianTestBattleScreen(
                        scenario: scenario,
                        report: viewModel.report(for: id),
                        isFocused: viewModel.focusedID == id,
                        isRunning: viewModel.isRunning
                    )
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    viewModel.start()
                } label: {
                    Label(viewModel.isRunning ? "Running" : "Run", systemImage: viewModel.isRunning ? "play.circle.fill" : "play.fill")
                }
                .disabled(viewModel.isRunning)
                .accessibilityIdentifier("guderian-test-run-button")

                Button {
                    viewModel.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .disabled(!viewModel.isRunning)
                .accessibilityIdentifier("guderian-test-stop-button")

                Button {
                    viewModel.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .accessibilityIdentifier("guderian-test-reset-button")
            }
        }
        .onAppear {
            if viewModel.reports.isEmpty {
                viewModel.start()
            }
        }
    }

    private var runHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GuderianTest")
                        .font(.title2.weight(.semibold))
                    Text(viewModel.summary.completionSummary.progressLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.lateCareerReport.completionSummary.progressLabel)
                        .font(.caption)
                        .foregroundStyle(viewModel.lateCareerReport.allPassed ? .green : .secondary)
                    Text(viewModel.isRunning ? "Automation is running through the campaign." : "Open a battle row to inspect the full automation playback.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if viewModel.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
                SummaryBadge(title: "Passed", value: viewModel.summary.passedCount, systemImage: "checkmark.circle.fill", color: .green)
                SummaryBadge(title: "Warnings", value: viewModel.summary.warningCount, systemImage: "exclamationmark.triangle.fill", color: .orange)
                SummaryBadge(title: "Failed", value: viewModel.summary.failedCount, systemImage: "xmark.octagon.fill", color: .red)
                SummaryBadge(title: "Blocked", value: viewModel.summary.blockedCount, systemImage: "hand.raised.fill", color: .purple)
                SummaryBadge(title: "Issues", value: viewModel.summary.issueCount, systemImage: "list.bullet.clipboard", color: .blue)
                SummaryBadge(title: "Late", value: viewModel.lateCareerReport.passedCount, systemImage: "checkmark.seal.fill", color: .green)
            }
        }
        .padding(16)
    }

    private var battleList: some View {
        List {
            Section("Field Command Campaign") {
                ForEach(GuderianCampaignCatalog.all.sorted(by: { $0.order < $1.order })) { scenario in
                    let report = viewModel.reports.first { $0.id == scenario.id }
                    NavigationLink(value: scenario.id) {
                        GuderianTestBattleRow(
                            scenario: scenario,
                            report: report,
                            isFocused: viewModel.focusedID == scenario.id
                        )
                    }
                    .accessibilityIdentifier("guderian-test-row-link-\(scenario.id.rawValue)")
                }
            }

            Section("Late Career Context") {
                ForEach(viewModel.lateCareerReport.reports) { report in
                    LateCareerTestContextRow(report: report)
                }
            }
        }
        .listStyle(.inset)
        .accessibilityIdentifier("guderian-test-battle-list")
    }
}

struct LateCareerTestContextRow: View {
    let report: LateCareerAutomationBattleReport

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .foregroundStyle(color)
                .frame(width: 24)
                .accessibilityLabel(report.status.rawValue)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(report.completionRecord.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], alignment: .leading, spacing: 4) {
                    Text(report.caveatVisible ? "caveat ok" : "caveat blocked")
                    Text(report.mapDetailReady ? "map ok" : "map blocked")
                    Text(report.aiPressureReady ? "AI ok" : "AI blocked")
                    Text(report.scoringReady ? "\(report.completionRecord.score) VP" : "score blocked")
                    Text(report.persistenceReady ? "save ok" : "save blocked")
                    Text(report.ruleBindingReady ? "rules ok" : "rules blocked")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if report.passed {
                Label("Debriefed", systemImage: "rosette")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            } else {
                Label("\(report.issues.count) issues", systemImage: "exclamationmark.triangle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("guderian-test-late-career-row-\(report.id)")
    }

    private var iconName: String {
        switch report.status {
        case .passed:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .failed:
            return "xmark.octagon.fill"
        case .blocked:
            return "hand.raised.fill"
        case .running:
            return "play.circle.fill"
        case .queued:
            return "circle"
        }
    }

    private var color: Color {
        switch report.status {
        case .passed:
            return .green
        case .warning:
            return .orange
        case .failed:
            return .red
        case .blocked:
            return .purple
        case .running:
            return .blue
        case .queued:
            return .secondary
        }
    }
}

struct SummaryBadge: View {
    let title: String
    let value: Int
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.headline)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct GuderianTestBattleRow: View {
    let scenario: GuderianScenario
    let report: CampaignAutomationBattleReport?
    let isFocused: Bool

    var body: some View {
        HStack(spacing: 14) {
            statusIcon
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(scenario.order). \(scenario.title)")
                    .font(.headline)
                    .lineLimit(1)
                Text("\(scenario.dateLabel) | \(scenario.theater.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], alignment: .leading, spacing: 4) {
                    Text(report.map { "\($0.actionsSucceeded)/\($0.actionsAttempted) actions" } ?? "queued")
                    Text(report?.nativeBoardDiagnosticsPassed == true ? "board ok" : "board pending")
                    Text(playableScreenLabel(report))
                    Text(playableTestGameLabel(report))
                    Text(report?.completionRecord.map { "\($0.score) VP" } ?? "score pending")
                    Text(report.map { $0.issues.isEmpty ? "no issues" : "\($0.issues.count) issues" } ?? "not run")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if isFocused {
                Label("Running", systemImage: "play.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("guderian-test-row-\(scenario.id.rawValue)")
    }

    @ViewBuilder
    private var statusIcon: some View {
        if let report {
            Image(systemName: iconName(for: report.status))
                .foregroundStyle(color(for: report.status))
                .accessibilityLabel(report.status.rawValue)
        } else {
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Queued")
        }
    }

    private func iconName(for status: CampaignAutomationStatus) -> String {
        switch status {
        case .passed:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .failed:
            return "xmark.octagon.fill"
        case .blocked:
            return "hand.raised.fill"
        case .running:
            return "play.circle.fill"
        case .queued:
            return "circle"
        }
    }

    private func color(for status: CampaignAutomationStatus) -> Color {
        switch status {
        case .passed:
            return .green
        case .warning:
            return .orange
        case .failed:
            return .red
        case .blocked:
            return .purple
        case .running:
            return .blue
        case .queued:
            return .secondary
        }
    }

    private func playableScreenLabel(_ report: CampaignAutomationBattleReport?) -> String {
        guard PlayableBattleSurfaceCatalog.isRoutedToPlayableScreen(scenario.id) else {
            return "screen queued"
        }
        guard let report else {
            return "screen pending"
        }
        return report.playableScreenParityCompleted ? "screen ok" : "screen blocked"
    }

    private func playableTestGameLabel(_ report: CampaignAutomationBattleReport?) -> String {
        guard let report else {
            return "test game pending"
        }
        return report.playableTestGameCompleted ? "test game ok" : "test game blocked"
    }
}

struct GuderianTestBattleScreen: View {
    let scenario: GuderianScenario
    let report: CampaignAutomationBattleReport?
    let isFocused: Bool
    let isRunning: Bool

    var body: some View {
        Group {
            if let report {
                GuderianTestReportDetail(report: report)
            } else {
                pendingScreen
            }
        }
        .navigationTitle(scenario.title)
        .accessibilityIdentifier("guderian-test-battle-screen-\(scenario.id.rawValue)")
    }

    private var pendingScreen: some View {
        VStack(spacing: 16) {
            Image(systemName: isFocused && isRunning ? "play.circle.fill" : "clock")
                .font(.system(size: 54))
                .foregroundStyle(isFocused && isRunning ? .blue : .secondary)
            Text(scenario.title)
                .font(.title2.weight(.semibold))
            Text(isFocused && isRunning ? "Automation is running this battle now." : "Automation has not produced a battle report yet.")
                .font(.callout)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Label(scenario.playerForceSummary, systemImage: "shield.lefthalf.filled")
                Label(scenario.guderianCommand, systemImage: "bolt.horizontal")
                Label("\(scenario.objectives.count) objectives queued", systemImage: "scope")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct GuderianTestReportDetail: View {
    let report: CampaignAutomationBattleReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if !report.issues.isEmpty {
                    issueSection
                }
                timelineSection
                engineLogSection
            }
            .padding(24)
            .frame(maxWidth: 1260, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityIdentifier("guderian-test-report-detail")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label(report.status.rawValue, systemImage: iconName(for: report.status))
                    .font(.headline)
                    .foregroundStyle(color(for: report.status))
                Spacer()
                Text("\(report.actionsSucceeded)/\(report.actionsAttempted) actions")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            Text(report.title)
                .font(.system(size: 30, weight: .semibold))
            Text("\(report.theater.rawValue) | \(report.playerArmy) vs \(report.opponentArmy)")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], alignment: .leading, spacing: 10) {
                DetailMetric(title: "Final Turn", value: "\(report.finalTurn)")
                DetailMetric(title: "Final Phase", value: report.finalPhase)
                DetailMetric(title: "Winner", value: report.engineWinner)
                DetailMetric(title: "Score", value: report.completionRecord.map { "\($0.score) VP" } ?? "Pending")
                DetailMetric(title: "Debrief", value: report.completionRecord?.victoryBand.rawValue ?? "Pending")
                DetailMetric(title: "Board", value: report.nativeBoardDiagnosticsPassed ? "Passed" : "Check")
                DetailMetric(title: "Units", value: "\(report.engineUnitCount)")
                DetailMetric(title: "Objectives", value: "\(report.engineObjectiveCount)")
            }

            if !report.debriefSummary.isEmpty {
                Label(
                    report.debriefSummary,
                    systemImage: report.nativeDemoBoardCompleted ? "flag.checkered" : "flag"
                )
                .font(.callout)
                .foregroundStyle(report.nativeDemoBoardCompleted ? .green : .secondary)
            }

            if let diagnostic = report.boardDiagnostic {
                Label(
                    "\(diagnostic.legalActionsSucceeded)/\(diagnostic.legalActionsAttempted) legal board actions, \(diagnostic.phaseAdvances) phase advances, \(diagnostic.findings.count) findings",
                    systemImage: diagnostic.passedRealBoardDiagnostics ? "checkerboard.rectangle" : "exclamationmark.triangle"
                )
                .font(.callout)
                .foregroundStyle(diagnostic.passedRealBoardDiagnostics ? .green : .orange)
            }

            if !report.nativePolandPackSummary.isEmpty {
                Label(report.nativePolandPackSummary, systemImage: "map")
                    .font(.callout)
                    .foregroundStyle(report.nativePolandPackCompleted ? .green : .secondary)
            }

            if !report.nativeFrancePackSummary.isEmpty {
                Label(report.nativeFrancePackSummary, systemImage: "flag.checkered")
                    .font(.callout)
                    .foregroundStyle(report.nativeFrancePackCompleted ? .green : .secondary)
            }

            if !report.easternFrontFoundationSummary.isEmpty {
                Label(report.easternFrontFoundationSummary, systemImage: "scope")
                    .font(.callout)
                    .foregroundStyle(report.easternFrontFoundationReady ? .green : .secondary)
            }

            if !report.nativeEasternFrontPackSummary.isEmpty {
                Label(report.nativeEasternFrontPackSummary, systemImage: "snowflake")
                    .font(.callout)
                    .foregroundStyle(report.nativeEasternFrontPackCompleted ? .green : .secondary)
            }

            if !report.nativeAIEventPassSummary.isEmpty {
                Label(report.nativeAIEventPassSummary, systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.callout)
                    .foregroundStyle(report.nativeAIEventPassReady ? .green : .secondary)
            }

            if !report.nativeAIEventExecutionSummary.isEmpty {
                Label(report.nativeAIEventExecutionSummary, systemImage: "arrow.triangle.branch")
                    .font(.callout)
                    .foregroundStyle(report.nativeAIEventExecutionReady ? .green : .secondary)
            }

            if !report.nativeBalanceUXSummary.isEmpty {
                Label(report.nativeBalanceUXSummary, systemImage: "slider.horizontal.3")
                    .font(.callout)
                    .foregroundStyle(report.nativeBalanceUXReady ? .green : .secondary)
            }

            if !report.nativePostShipAnalysisSummary.isEmpty {
                Label(report.nativePostShipAnalysisSummary, systemImage: "doc.text.magnifyingglass")
                    .font(.callout)
                    .foregroundStyle(report.nativePostShipAnalysisReady ? .green : .secondary)
            }

            if !report.nativeSoakSummary.isEmpty {
                Label(report.nativeSoakSummary, systemImage: "repeat.circle")
                    .font(.callout)
                    .foregroundStyle(report.nativeSoakReady ? .green : .secondary)
            }

            if !report.playableScreenParitySummary.isEmpty {
                Label(report.playableScreenParitySummary, systemImage: "checkerboard.rectangle")
                    .font(.callout)
                    .foregroundStyle(report.playableScreenParityCompleted ? .green : .orange)
            }

            if !report.playableTestGameSummary.isEmpty {
                Label(report.playableTestGameSummary, systemImage: "person.2.wave.2")
                    .font(.callout)
                    .foregroundStyle(report.playableTestGameCompleted ? .green : .orange)
            }
        }
    }

    private var issueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Failures And Blockers", systemImage: "exclamationmark.bubble")
                .font(.headline)
            ForEach(report.issues) { issue in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: iconName(for: issue.kind))
                        .foregroundStyle(color(for: issue.kind))
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(issue.kind.rawValue) | \(issue.stage)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(issue.title)
                            .font(.callout.weight(.medium))
                        Text(issue.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Automation Timeline", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.headline)
            ForEach(report.steps) { step in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: iconName(for: step.status))
                        .foregroundStyle(color(for: step.status))
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.stage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(step.title)
                            .font(.callout.weight(.medium))
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var engineLogSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Engine Trace", systemImage: "terminal")
                .font(.headline)
            if report.engineLogTail.isEmpty {
                Text("No engine log lines were emitted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(report.engineLogTail.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func iconName(for status: CampaignAutomationStatus) -> String {
        switch status {
        case .passed:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .failed:
            return "xmark.octagon.fill"
        case .blocked:
            return "hand.raised.fill"
        case .running:
            return "play.circle.fill"
        case .queued:
            return "circle"
        }
    }

    private func iconName(for kind: CampaignAutomationIssueKind) -> String {
        switch kind {
        case .warning:
            return "exclamationmark.triangle.fill"
        case .failure:
            return "xmark.octagon.fill"
        case .blocker:
            return "hand.raised.fill"
        }
    }

    private func color(for status: CampaignAutomationStatus) -> Color {
        switch status {
        case .passed:
            return .green
        case .warning:
            return .orange
        case .failed:
            return .red
        case .blocked:
            return .purple
        case .running:
            return .blue
        case .queued:
            return .secondary
        }
    }

    private func color(for kind: CampaignAutomationIssueKind) -> Color {
        switch kind {
        case .warning:
            return .orange
        case .failure:
            return .red
        case .blocker:
            return .purple
        }
    }
}

struct DetailMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(minWidth: 86, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
