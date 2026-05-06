import AppKit
import GuderianCore
import GuderianAppUI
import OSLog
import SwiftUI

private let guderianTestLog = Logger(subsystem: "com.barbalet.guderian", category: "GuderianTest")

private enum GuderianTestLaunchMode {
    static var isUITesting: Bool {
        let processInfo = ProcessInfo.processInfo
        if processInfo.arguments.contains("--guderian-ui-testing") ||
            processInfo.arguments.contains("-guderian-ui-testing") {
            return true
        }

        return environmentFlagIsEnabled("GUDERIAN_UI_TESTING", environment: processInfo.environment)
    }

    private static func environmentFlagIsEnabled(_ key: String, environment: [String: String]) -> Bool {
        guard let value = environment[key]?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }

        switch value.lowercased() {
        case "1", "true", "yes", "on":
            return true
        default:
            return false
        }
    }
}

@MainActor
private func logGuderianTestWindowSnapshot(_ context: String) {
    let windows = NSApp.windows.map { window in
        let title = window.title.isEmpty ? "<untitled>" : window.title
        let visibility = window.isVisible ? "visible" : "hidden"
        let keyState = window.isKeyWindow ? "key" : "not-key"
        let frame = "\(Int(window.frame.minX)),\(Int(window.frame.minY)) \(Int(window.frame.width))x\(Int(window.frame.height))"
        return "#\(window.windowNumber) \(title) \(visibility) \(keyState) \(frame)"
    }.joined(separator: " | ")

    guderianTestLog.info("Window snapshot [\(context, privacy: .public)] count=\(NSApp.windows.count, privacy: .public) windows=\(windows, privacy: .public)")
}

@main
struct GuderianTestApp: App {
    var body: some Scene {
        WindowGroup("GuderianTest") {
            GuderianTestFirstBattleAutoplayView(isUITesting: GuderianTestLaunchMode.isUITesting)
                .frame(minWidth: 1280, minHeight: 820)
                .onAppear {
                    guderianTestLog.info("GuderianTest root view appeared uiTesting=\(GuderianTestLaunchMode.isUITesting, privacy: .public).")
                    logGuderianTestWindowSnapshot("root-on-appear")
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        logGuderianTestWindowSnapshot("root-on-appear-delayed")
                    }
                }
                .onDisappear {
                    guderianTestLog.info("GuderianTest root view disappeared.")
                    logGuderianTestWindowSnapshot("root-on-disappear")
                }
        }
        .windowResizability(.contentMinSize)
    }
}

@MainActor
final class GuderianTestFirstBattleAutoplayViewModel: ObservableObject {
    @Published private(set) var scenario: GuderianScenario
    @Published private(set) var snapshot: NativeBoardSnapshot?
    @Published private(set) var report: GuderianTestFirstBattleAutoplayReport?
    @Published private(set) var runState: GuderianTestFirstBattleRunState = .ready
    @Published private(set) var steps: [PlayableTestGameStep] = []
    @Published private(set) var phaseAdvances = 0
    @Published private(set) var blockers: [String] = []
    @Published private(set) var isRunning = false
    @Published private(set) var speed: GuderianTestFirstBattleAutoplaySpeed = .standard
    @Published private(set) var errorMessage: String?

    private var controller: GuderianTestFirstBattleRunController?
    private var runTask: Task<Void, Never>?
    private var lastStateLogSignature = ""

    init() {
        do {
            let controller = try GuderianTestFirstBattleRunController()
            self.controller = controller
            scenario = controller.scenario
            syncFromController()
            guderianTestLog.info("GuderianTest controller initialized scenario=\(self.scenario.id.rawValue, privacy: .public) title=\(self.scenario.title, privacy: .public)")
        } catch {
            scenario = (try? GuderianTestFirstBattleAutoplayContract.primaryScenario()) ?? GuderianCampaignCatalog.all.sorted { $0.order < $1.order }[0]
            runState = .failed
            errorMessage = "\(error)"
            guderianTestLog.error("GuderianTest controller failed to initialize error=\(String(describing: error), privacy: .public)")
        }
    }

    deinit {
        guderianTestLog.info("GuderianTest view model deinit; cancelling run task.")
        runTask?.cancel()
    }

    var hasReport: Bool {
        report != nil
    }

    var canRun: Bool {
        controller?.canRun == true && !isRunning
    }

    var canStep: Bool {
        controller?.canStep == true && !isRunning
    }

    var canPause: Bool {
        isRunning
    }

    var antiGuderianStepCount: Int {
        steps.filter { $0.controller == .antiGuderian }.count
    }

    var germanStepCount: Int {
        steps.filter { $0.controller == .guderian }.count
    }

    var recentSteps: [PlayableTestGameStep] {
        Array(steps.suffix(8).reversed())
    }

    var speedModes: [GuderianTestFirstBattleAutoplaySpeed] {
        GuderianTestFirstBattleAutoplaySpeed.allCases
    }

    var maxPhaseAdvances: Int {
        controller?.maxPhaseAdvances ?? 0
    }

    var phaseBudgetRemaining: Int {
        controller?.phaseBudgetRemaining ?? 0
    }

    var phaseProgressFraction: Double {
        controller?.phaseProgressFraction ?? 0
    }

    func setSpeed(_ speed: GuderianTestFirstBattleAutoplaySpeed) {
        guderianTestLog.info("GuderianTest speed changed from \(self.speed.rawValue, privacy: .public) to \(speed.rawValue, privacy: .public)")
        self.speed = speed
    }

    func runToDebrief() {
        guard !isRunning, let controller else {
            if controller == nil {
                errorMessage = "GuderianTest first-battle controller is unavailable."
                guderianTestLog.error("Run requested but controller is unavailable.")
            } else {
                guderianTestLog.info("Run requested while already running.")
            }
            return
        }

        guard controller.canRun else {
            guderianTestLog.info("Run requested but controller cannot run state=\(controller.runState.rawValue, privacy: .public)")
            return
        }

        guderianTestLog.info("Run-to-debrief started state=\(controller.runState.rawValue, privacy: .public) speed=\(self.speed.rawValue, privacy: .public)")
        runTask?.cancel()
        errorMessage = nil
        controller.resume()
        syncFromController()

        runTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            while let controller = self.controller,
                  controller.runState == .running,
                  !Task.isCancelled {
                do {
                    _ = try controller.runUntilPauseOrDebrief(maxSteps: 1)
                    self.syncFromController()
                } catch {
                    self.report = nil
                    self.errorMessage = "\(error)"
                    guderianTestLog.error("Run-to-debrief failed error=\(String(describing: error), privacy: .public)")
                    self.syncFromController()
                    return
                }

                if controller.runState == .running {
                    try? await Task.sleep(nanoseconds: self.speed.stepDelayNanoseconds)
                }
            }

            self.runTask = nil
            self.syncFromController()
            guderianTestLog.info("Run-to-debrief stopped state=\(self.runState.rawValue, privacy: .public) report=\(self.report == nil ? "none" : "available", privacy: .public)")
        }
    }

    func stepOnce() {
        guard let controller else {
            errorMessage = "GuderianTest first-battle controller is unavailable."
            guderianTestLog.error("Step requested but controller is unavailable.")
            return
        }

        guard controller.canStep, !isRunning else {
            guderianTestLog.info("Step requested but unavailable state=\(controller.runState.rawValue, privacy: .public) isRunning=\(self.isRunning, privacy: .public)")
            return
        }

        do {
            _ = try controller.stepOnce()
            errorMessage = nil
            guderianTestLog.info("Step completed state=\(controller.runState.rawValue, privacy: .public) steps=\(controller.steps.count, privacy: .public) phaseAdvances=\(controller.phaseAdvances, privacy: .public)")
        } catch {
            errorMessage = "\(error)"
            guderianTestLog.error("Step failed error=\(String(describing: error), privacy: .public)")
        }
        syncFromController()
    }

    func pause() {
        guderianTestLog.info("Pause requested state=\(self.runState.rawValue, privacy: .public)")
        runTask?.cancel()
        runTask = nil
        controller?.pause()
        syncFromController()
    }

    func resume() {
        runToDebrief()
    }

    func runSynchronouslyForTests() {
        guard let controller else {
            errorMessage = "GuderianTest first-battle controller is unavailable."
            guderianTestLog.error("Synchronous run requested but controller is unavailable.")
            return
        }

        do {
            _ = try controller.runToDebrief()
            errorMessage = nil
            guderianTestLog.info("Synchronous run completed state=\(controller.runState.rawValue, privacy: .public) report=\(controller.lastReport == nil ? "none" : "available", privacy: .public)")
        } catch {
            errorMessage = "\(error)"
            guderianTestLog.error("Synchronous run failed error=\(String(describing: error), privacy: .public)")
        }
        syncFromController()
    }

    func restart() {
        guard let controller else {
            errorMessage = "GuderianTest first-battle controller is unavailable."
            guderianTestLog.error("Restart requested but controller is unavailable.")
            return
        }

        guderianTestLog.info("Restart requested state=\(controller.runState.rawValue, privacy: .public)")
        runTask?.cancel()
        runTask = nil
        do {
            try controller.restart()
            errorMessage = nil
            guderianTestLog.info("Restart completed.")
        } catch {
            errorMessage = "\(error)"
            guderianTestLog.error("Restart failed error=\(String(describing: error), privacy: .public)")
        }
        syncFromController()
    }

    private func syncFromController() {
        guard let controller else {
            isRunning = false
            logStateIfNeeded("controller-unavailable")
            return
        }

        scenario = controller.scenario
        snapshot = controller.latestSnapshot
        report = controller.lastReport
        runState = controller.runState
        steps = controller.steps
        phaseAdvances = controller.phaseAdvances
        blockers = controller.blockers
        isRunning = controller.runState == .running
        logStateIfNeeded("controller-sync")
    }

    private func logStateIfNeeded(_ context: String) {
        let signature = [
            context,
            runState.rawValue,
            "\(steps.count)",
            "\(phaseAdvances)",
            "\(blockers.count)",
            report == nil ? "no-report" : "report",
            errorMessage ?? "no-error",
        ].joined(separator: "|")

        guard signature != lastStateLogSignature else {
            return
        }

        lastStateLogSignature = signature
        guderianTestLog.info("State [\(context, privacy: .public)] runState=\(self.runState.rawValue, privacy: .public) isRunning=\(self.isRunning, privacy: .public) steps=\(self.steps.count, privacy: .public) phaseAdvances=\(self.phaseAdvances, privacy: .public) blockers=\(self.blockers.count, privacy: .public) report=\(self.report == nil ? "none" : "available", privacy: .public) error=\(self.errorMessage ?? "none", privacy: .public)")
    }
}

struct GuderianTestFirstBattleAutoplayView: View {
    @StateObject private var viewModel = GuderianTestFirstBattleAutoplayViewModel()
    let isUITesting: Bool

    var body: some View {
        HSplitView {
            DZWPlayableBattleView(
                scenario: viewModel.scenario,
                showsDefaultPanels: !isUITesting,
                showsTutorials: !isUITesting
            )
                .frame(minWidth: 860, minHeight: 760)
                .accessibilityIdentifier("guderian-test-primary-battle-surface")

            GuderianTestAutoplayControlPanel(viewModel: viewModel)
                .frame(minWidth: 360, idealWidth: 400, maxWidth: 460)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("guderian-test-first-battle-autoplay")
        .onAppear {
            guderianTestLog.info("GuderianTest autoplay view appeared scenario=\(viewModel.scenario.id.rawValue, privacy: .public) uiTesting=\(isUITesting, privacy: .public) showsDefaultPanels=\(!isUITesting, privacy: .public) showsTutorials=\(!isUITesting, privacy: .public)")
            logGuderianTestWindowSnapshot("autoplay-view-on-appear")
        }
        .onDisappear {
            guderianTestLog.info("GuderianTest autoplay view disappeared.")
            logGuderianTestWindowSnapshot("autoplay-view-on-disappear")
        }
    }
}

struct GuderianTestAutoplayControlPanel: View {
    @ObservedObject var viewModel: GuderianTestFirstBattleAutoplayViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                runControls
                liveSnapshotSection
                eventLogSection
                resultSection
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("GuderianTest", systemImage: "play.rectangle.on.rectangle")
                .font(.title2.weight(.semibold))
            Text("First-battle autoplay replacement")
                .font(.headline)
            Text(viewModel.scenario.title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Primary surface: \(GuderianTestFirstBattleAutoplayContract.embeddedBattleSurfaceName)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    private var runControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    viewModel.runToDebrief()
                } label: {
                    Label(runButtonTitle, systemImage: "forward.end.alt.fill")
                }
                .disabled(!viewModel.canRun)
                .accessibilityIdentifier("guderian-test-run-to-debrief-button")

                Button {
                    viewModel.stepOnce()
                } label: {
                    Label("Step", systemImage: "forward.frame.fill")
                }
                .disabled(!viewModel.canStep)
                .accessibilityIdentifier("guderian-test-step-button")
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(!viewModel.canPause)
                .accessibilityIdentifier("guderian-test-pause-button")

                Button {
                    viewModel.restart()
                } label: {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                }
                .disabled(viewModel.isRunning)
                .accessibilityIdentifier("guderian-test-restart-button")
            }

            Picker(
                "Speed",
                selection: Binding(
                    get: { viewModel.speed },
                    set: { viewModel.setSpeed($0) }
                )
            ) {
                ForEach(viewModel.speedModes) { speed in
                    Text(speed.rawValue).tag(speed)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.hasReport)
            .accessibilityIdentifier("guderian-test-speed-picker")
        }
        .buttonStyle(.borderedProminent)
    }

    private var runButtonTitle: String {
        if viewModel.isRunning {
            return "Running"
        }
        return viewModel.runState == .paused ? "Resume" : "Run"
    }

    private var liveSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live Session")
                .font(.headline)

            metric("State", viewModel.runState.rawValue)
            metric("Speed", viewModel.speed.rawValue)
            metric("Phase advances", "\(viewModel.phaseAdvances)")
            metric("Safety cap", "\(viewModel.phaseBudgetRemaining) of \(viewModel.maxPhaseAdvances) left")
            metric("Steps", "\(viewModel.steps.count)")
            ProgressView(value: viewModel.phaseProgressFraction)
                .accessibilityIdentifier("guderian-test-safety-cap")

            if let snapshot = viewModel.snapshot {
                metric("Turn", "\(snapshot.turnNumber)")
                metric("Active", snapshot.activePlayer.rawValue)
                metric("Phase", snapshot.phase.rawValue)
                metric("Winner", snapshot.mission.winner.rawValue)
                metric("Score", "\(snapshot.mission.playerScore)-\(snapshot.mission.opponentScore)")
                Text(snapshot.lastAction.detail)
                    .font(.caption)
                    .foregroundStyle(snapshot.lastAction.status == .blocked ? .orange : .secondary)
            } else {
                Text("No native board snapshot is available.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var eventLogSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Autoplay Log")
                .font(.headline)

            if viewModel.recentSteps.isEmpty {
                Text("No automated phase has run yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.recentSteps) { step in
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(step.turnNumber) \(step.activePlayer.rawValue) \(step.phase.rawValue)")
                            .font(.caption.weight(.semibold))
                        Text(step.title)
                            .font(.caption)
                        Text(step.detail)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("guderian-test-event-log")
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Result")
                .font(.headline)

            if let report = viewModel.report {
                Label(report.outcomeLabel, systemImage: report.outcomeLabel == "Loss" ? "xmark.octagon" : "rosette")
                    .font(.headline)
                    .foregroundStyle(report.outcomeLabel == "Loss" ? .red : .green)
                Text(report.finalResultSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("guderian-test-result-summary")
                metric("Score", report.scoreLabel)
                metric("Turn", "\(report.result.completion.completionRecord.completedTurn)")
                metric("Anti-Guderian steps", "\(report.result.antiGuderianStepCount)")
                metric("German steps", "\(report.result.germanStepCount)")
                metric("Phase advances", "\(report.result.phaseAdvances)")
                metric("Persisted", report.completedToDebrief ? "Yes" : "No")
                Text(report.result.completion.debriefSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if !viewModel.blockers.isEmpty {
                ForEach(viewModel.blockers, id: \.self) { blocker in
                    Label(blocker, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("Run, resume, or step the first-battle autoplay check to produce a real debrief record.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityIdentifier("guderian-test-result-panel")
    }

    private func metric(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption.monospacedDigit())
                .multilineTextAlignment(.trailing)
        }
    }
}
