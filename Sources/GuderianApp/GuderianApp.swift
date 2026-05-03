import GuderianCore
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
    @State private var selectedID: GuderianBattleID? = GuderianCampaignCatalog.demoIDs.first
    @State private var progress = CampaignProgress()
    @State private var playMode: CampaignPlayMode = .chronological

    private var selectedScenario: GuderianScenario {
        scenarios.first { $0.id == selectedID } ?? scenarios[0]
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedID) {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(progress.completedCount) of \(scenarios.count) complete")
                            .font(.headline)
                        Text("\(progress.availableScenarios(in: playMode, catalog: scenarios).count) available | \(playMode.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    Picker("Play mode", selection: $playMode) {
                        Text(CampaignPlayMode.chronological.rawValue).tag(CampaignPlayMode.chronological)
                        Text(CampaignPlayMode.standalone.rawValue).tag(CampaignPlayMode.standalone)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Campaign play mode")
                }

                Section("Scenarios") {
                    ForEach(scenarios) { scenario in
                        ScenarioRow(scenario: scenario, progress: progress, playMode: playMode)
                            .tag(scenario.id)
                    }
                }
            }
            .navigationTitle("Campaign")
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

                        Button {
                            progress.reset()
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                        }
                    }
                    .buttonStyle(.borderless)

                    RendererStatusView()
                }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.bar)
            }
        } detail: {
            ScenarioBriefingView(scenario: selectedScenario, progress: progress, playMode: playMode)
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

    var logEntries: [ScenarioLogEntry] {
        content.logEntries
    }

    var polishProfile: PolishScenarioSystemProfile? {
        PolishCampaignSystemCatalog.profile(for: scenario)
    }

    var filteredLogEntries: [ScenarioLogEntry] {
        guard let logCategory else {
            return logEntries
        }
        return logEntries.filter { $0.category == logCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statusStrip
                ScenarioMapView(layout: layout)
                    .frame(maxWidth: 860)
                briefingSection("Player Force", scenario.playerForceSummary, icon: "shield.lefthalf.filled")
                briefingSection("Guderian Command", scenario.guderianCommand, icon: "bolt.horizontal")
                briefingSection("Design Intent", scenario.designIntent, icon: "scope")
                forceOrder
                polishSystemView
                objectives
                balanceView
                reinforcementsView
                triggers
                aiPlanView
                tutorialView
                scenarioLog
                debriefView
                terrain
                engineMapping
                sources
            }
            .padding(28)
            .frame(maxWidth: 920, alignment: .leading)
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
