import GuderianCore
import SwiftUI

@main
struct GuderianTestApp: App {
    var body: some Scene {
        WindowGroup("GuderianTest") {
            GuderianTestDashboard()
                .frame(minWidth: 1180, minHeight: 760)
        }
        .windowResizability(.contentMinSize)
    }
}

@MainActor
final class GuderianTestViewModel: ObservableObject {
    @Published private(set) var reports: [CampaignAutomationBattleReport] = []
    @Published private(set) var isRunning = false
    @Published var selectedID: GuderianBattleID? = GuderianCampaignCatalog.all.first?.id

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

    var selectedReport: CampaignAutomationBattleReport? {
        guard let selectedID else {
            return reports.first
        }
        return reports.first { $0.id == selectedID }
    }

    func start() {
        guard !isRunning else {
            return
        }

        reports = []
        isRunning = true
        runTask = Task {
            var progress = CampaignProgress()
            for scenario in GuderianCampaignCatalog.all.sorted(by: { $0.order < $1.order }) {
                guard !Task.isCancelled else {
                    break
                }
                if selectedID == nil {
                    selectedID = scenario.id
                }

                let report = CampaignAutomationRunner.runBattle(
                    scenario,
                    progress: &progress,
                    options: .appDefault
                )
                reports.append(report)
                selectedID = report.id
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
        selectedID = GuderianCampaignCatalog.all.first?.id
    }
}

struct GuderianTestDashboard: View {
    @StateObject private var viewModel = GuderianTestViewModel()

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                runHeader
                Divider()
                battleList
            }
            .navigationSplitViewColumnWidth(min: 360, ideal: 420)
        } detail: {
            detailPane
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
            }
        }
        .padding(16)
    }

    private var battleList: some View {
        List(selection: $viewModel.selectedID) {
            ForEach(GuderianCampaignCatalog.all.sorted(by: { $0.order < $1.order })) { scenario in
                let report = viewModel.reports.first { $0.id == scenario.id }
                GuderianTestBattleRow(scenario: scenario, report: report)
                    .tag(scenario.id)
            }
        }
        .listStyle(.sidebar)
        .accessibilityIdentifier("guderian-test-battle-list")
    }

    @ViewBuilder
    private var detailPane: some View {
        if let report = viewModel.selectedReport {
            GuderianTestReportDetail(report: report)
        } else {
            VStack(spacing: 12) {
                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Awaiting first automation report")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
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

    var body: some View {
        HStack(spacing: 10) {
            statusIcon
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(scenario.order). \(scenario.title)")
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(scenario.theater.rawValue)
                    Text(report.map { "\($0.actionsSucceeded)/\($0.actionsAttempted) actions" } ?? "queued")
                    if let record = report?.completionRecord {
                        Text("\(record.score) VP")
                    }
                    if report?.nativeBoardDiagnosticsPassed == true {
                        Text("board ok")
                    }
                    if let report, !report.issues.isEmpty {
                        Text("\(report.issues.count) issues")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
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
            .frame(maxWidth: 980, alignment: .leading)
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

            HStack(spacing: 10) {
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
