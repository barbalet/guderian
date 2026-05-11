import Foundation
import GuderianCore

public enum FunScenarioKind: String, Codable, Hashable, Sendable {
    case fieldCommand = "Field command"
    case lateCareer = "Late career"
}

public enum FunScenarioRunStatus: String, Codable, Hashable, Sendable {
    case notRun = "Not run"
    case passed = "Passed"
    case blocked = "Blocked"
}

public struct FunScenarioRunSummary: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let status: FunScenarioRunStatus
    public let stepCount: Int
    public let blockerCount: Int
    public let completionPersistenceKey: String
    public let detail: String

    public init(
        id: String,
        status: FunScenarioRunStatus,
        stepCount: Int,
        blockerCount: Int,
        completionPersistenceKey: String,
        detail: String
    ) {
        self.id = id
        self.status = status
        self.stepCount = stepCount
        self.blockerCount = blockerCount
        self.completionPersistenceKey = completionPersistenceKey
        self.detail = detail
    }

    public var completed: Bool {
        status == .passed
    }
}

public struct FunScenarioAudit: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let order: Int
    public let title: String
    public let kind: FunScenarioKind
    public let dimensionScores: [FunDimensionScore]
    public let runSummary: FunScenarioRunSummary?
    public let gates: [FunAcceptanceGate]
    public let opportunities: [String]

    public init(
        id: String,
        order: Int,
        title: String,
        kind: FunScenarioKind,
        dimensionScores: [FunDimensionScore],
        runSummary: FunScenarioRunSummary?,
        gates: [FunAcceptanceGate],
        opportunities: [String]
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.kind = kind
        self.dimensionScores = dimensionScores
        self.runSummary = runSummary
        self.gates = gates
        self.opportunities = opportunities
    }

    public var overallScore: Double {
        let weighted = dimensionScores.reduce(0.0) { $0 + Double($1.score * $1.weight) }
        let totalWeight = dimensionScores.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else {
            return 0
        }
        return weighted / Double(totalWeight)
    }

    public var blockerGates: [FunAcceptanceGate] {
        gates.filter { $0.status == .blocker }
    }

    public var warningGates: [FunAcceptanceGate] {
        gates.filter { $0.status == .warning }
    }

    public var passedFunGates: Bool {
        blockerGates.isEmpty
    }

    public func score(for dimension: FunDimension) -> Int {
        dimensionScores.first { $0.dimension == dimension }?.score ?? 0
    }
}

public enum FunScenarioAuditCatalog {
    public static func allAudits(runUnifiedHarness: Bool = false) throws -> [FunScenarioAudit] {
        let runSummaries: [UnifiedGuderianBattleID: FunScenarioRunSummary]
        if runUnifiedHarness {
            let harnessResults = try UnifiedPlayableScreenHarness.runAll35FlowsThroughCycle805()
            runSummaries = Dictionary(
                uniqueKeysWithValues: harnessResults.map { ($0.id, FunScenarioRunSummary(harnessResult: $0)) }
            )
        } else {
            runSummaries = [:]
        }

        let fieldAudits = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map { scenario in
                audit(
                    for: scenario,
                    runSummary: runSummaries[.fieldCommand(scenario.id)]
                )
            }
        let lateAudits = LateCareerGuderianPresentationCatalog.allEntries
            .sorted { $0.order < $1.order }
            .map { entry in
                audit(
                    for: entry,
                    runSummary: runSummaries[.lateCareer(entry.id)]
                )
            }

        return fieldAudits + lateAudits
    }

    public static func audit(
        for scenario: GuderianScenario,
        runSummary: FunScenarioRunSummary? = nil
    ) -> FunScenarioAudit {
        let id = "field:\(scenario.id.rawValue)"
        let dimensions = FunDimension.allCases.map { dimension in
            FunDimensionScore(
                dimension: dimension,
                metrics: fieldCommandMetrics(
                    for: dimension,
                    scenario: scenario,
                    runSummary: runSummary
                )
            )
        }
        return FunScenarioAudit(
            id: id,
            order: scenario.order,
            title: scenario.title,
            kind: .fieldCommand,
            dimensionScores: dimensions,
            runSummary: runSummary,
            gates: gates(for: id, dimensions: dimensions, runSummary: runSummary),
            opportunities: opportunities(for: dimensions, runSummary: runSummary)
        )
    }

    public static func audit(
        for entry: LateCareerGuderianPresentation,
        runSummary: FunScenarioRunSummary? = nil
    ) -> FunScenarioAudit {
        let id = "late:\(entry.id)"
        let dimensions = FunDimension.allCases.map { dimension in
            FunDimensionScore(
                dimension: dimension,
                metrics: lateCareerMetrics(
                    for: dimension,
                    entry: entry,
                    runSummary: runSummary
                )
            )
        }
        return FunScenarioAudit(
            id: id,
            order: GuderianCampaignCatalog.all.count + entry.order,
            title: entry.title,
            kind: .lateCareer,
            dimensionScores: dimensions,
            runSummary: runSummary,
            gates: gates(for: id, dimensions: dimensions, runSummary: runSummary),
            opportunities: opportunities(for: dimensions, runSummary: runSummary)
        )
    }

    private static func fieldCommandMetrics(
        for dimension: FunDimension,
        scenario: GuderianScenario,
        runSummary: FunScenarioRunSummary?
    ) -> [FunMetric] {
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let layout = ScenarioMapCatalog.layout(for: scenario)
        let mapMetrics = ScenarioMapDetailMetrics(layout: layout)
        let germanPlan = GermanAIPlanCatalog.plan(for: scenario)
        let opposingPlan = OpposingForceAIPlanCatalog.plan(for: scenario)
        let briefing = UnifiedBattleBriefingCatalog.shell(for: .fieldCommand(scenario.id))
        let scopeRecord = GuderianCareerScopeCatalog.record(for: scenario.id)
        let text = [
            scenario.title,
            scenario.playerForceSummary,
            scenario.historicalResult,
            scenario.designIntent,
            scenario.objectives.map(\.description).joined(separator: " "),
            scenario.mapFeatures.map(\.role).joined(separator: " "),
            scopeRecord?.playableFraming ?? "",
            briefing?.displayText ?? "",
        ].joined(separator: " ")

        switch dimension {
        case .clarity:
            return [
                metric(dimension, "Objective visibility", FunMetricScoring.countScore(scenario.objectives.count, target: 3), "\(scenario.objectives.count) objectives are cataloged."),
                metric(dimension, "Briefing shell", FunMetricScoring.booleanScore(briefing?.usesSharedBriefingShell == true), briefing?.hostSurfaceName ?? "No unified briefing shell."),
                metric(dimension, "Source context", FunMetricScoring.countScore(scenario.sourceLinks.count, target: 2), "\(scenario.sourceLinks.count) source links."),
                runtimeMetric(dimension, "Playable feedback loop", runSummary, notRunScore: 82),
            ]
        case .agency:
            return [
                metric(dimension, "Player score channels", FunMetricScoring.countScore(balance.scoreChannels.filter { $0.side == .player || $0.side == .contested }.count, target: 4), "\(balance.scoreChannels.count) total score channels."),
                metric(dimension, "Opposing-force plan", FunMetricScoring.countScore(opposingPlan.targetPriorities.count, target: 5), "\(opposingPlan.targetPriorities.count) target priorities."),
                metric(dimension, "Distinct outcome routes", FunMetricScoring.countScore(Set(balance.outcomeBands.map(\.grade)).count, target: 4), "\(balance.outcomeBands.count) outcome bands."),
                runtimeMetric(dimension, "Selectable scenario flow", runSummary, notRunScore: 80),
            ]
        case .challenge:
            return [
                metric(dimension, "Pressure window", targetTurnScore(balance.targetTurns), "Target turns \(balance.targetTurns.lowerBound)-\(balance.targetTurns.upperBound)."),
                metric(dimension, "German pressure plan", FunMetricScoring.countScore(germanPlan.orders.count, target: 4), "\(germanPlan.orders.count) German-command orders."),
                metric(dimension, "Recoverable score bands", FunMetricScoring.countScore(balance.outcomeBands.count, target: 4), "\(balance.outcomeBands.count) score bands."),
                metric(dimension, "AI executability", FunMetricScoring.booleanScore(germanPlan.isExecutableByNativeAutoplay && opposingPlan.isExecutableByNativeAutoplay), "Both side plans expose native autoplay priorities."),
            ]
        case .mastery:
            return [
                metric(dimension, "Learnable channels", FunMetricScoring.countScore(balance.scoreChannels.count, target: 5), "\(balance.scoreChannels.count) named scoring lessons."),
                metric(dimension, "Debrief granularity", FunMetricScoring.countScore(balance.outcomeBands.map(\.summary).filter { !$0.isEmpty }.count, target: 4), "\(balance.outcomeBands.count) debrief summaries."),
                metric(dimension, "Visible reasoning", FunMetricScoring.countScore(germanPlan.orders.count + opposingPlan.orders.count, target: 7), "\(germanPlan.orders.count + opposingPlan.orders.count) AI orders explain intent."),
            ]
        case .novelty:
            return [
                metric(dimension, "Map identity", FunMetricScoring.countScore(mapMetrics.mapFeatureCount, target: 40), "\(mapMetrics.mapFeatureCount) map features."),
                categoryVarietyMetric(dimension, mapMetrics: mapMetrics),
                metric(dimension, "Posture identity", FunMetricScoring.booleanScore(!scenario.playerPosture.rawValue.isEmpty), scenario.playerPosture.rawValue),
                metric(dimension, "Scenario-specific tags", FunMetricScoring.countScore(scenario.tags.count + scenario.mapFeatures.count, target: 8), "\(scenario.tags.count) tags and \(scenario.mapFeatures.count) feature notes."),
            ]
        case .consequence:
            let minimum = balance.outcomeBands.map(\.scoreRange.lowerBound).min() ?? 0
            return [
                metric(dimension, "Fair score spread", scoreSpreadMetric(balance), "\(minimum)...\(balance.maxPlayerScore) player score range."),
                metric(dimension, "Partial success language", FunMetricScoring.textSignalScore(text: text, signals: ["delay", "withdraw", "evacuat", "preserve", "contest", "counterattack", "breakout"], target: 3), "Scenario text is checked for partial-success verbs."),
                metric(dimension, "Completion memory", runSummary?.completed == true ? 94 : 82, runSummary?.completionPersistenceKey ?? "Completion persistence is defined by the campaign resolver."),
            ]
        case .pacing:
            return [
                metric(dimension, "Pacing rules", FunMetricScoring.countScore(balance.pacingRules.count, target: 3), "\(balance.pacingRules.count) pacing rules."),
                metric(dimension, "Phase coverage", phaseCoverageScore(germanPlan: germanPlan, opposingPlan: opposingPlan), "Both AI plans are checked across movement, shooting, and assault."),
                metric(dimension, "Run cadence", runSummary?.completed == true ? 92 : 80, runSummary?.detail ?? "Run harness was not requested."),
            ]
        case .ethicalFrame:
            return [
                metric(dimension, "Default resistance frame", resistanceFrameScore(text: text), "Default text is checked for delay, survival, evacuation, counterattack, or containment framing."),
                metric(dimension, "Command caveat policy", commandCaveatScore(scopeRecord: scopeRecord, briefing: briefing), scopeRecord?.playableFraming ?? "Direct field-command scenario."),
                metric(dimension, "Non-celebratory language", nonCelebratoryLanguageScore(text), "Scenario-facing copy is checked for heroic German-command language."),
                metric(dimension, "Side integrity", FunMetricScoring.booleanScore(UnifiedGuderianBattleSideSelectionCatalog.defaultHumanSideID == GuderianHistoricalSideID.opposingForce), "Default human side remains the opposing force."),
            ]
        }
    }

    private static func lateCareerMetrics(
        for dimension: FunDimension,
        entry: LateCareerGuderianPresentation,
        runSummary: FunScenarioRunSummary?
    ) -> [FunMetric] {
        let battlefield = entry.battlefield
        let report = entry.playableReport
        let text = [
            entry.title,
            entry.playerRole,
            entry.germanContext,
            entry.playableFraming,
            entry.visibleCommandCaveatLabel,
            battlefield.objectives.map(\.description).joined(separator: " "),
            battlefield.rules.map(\.effect).joined(separator: " "),
            report?.debriefProfile.operationalText ?? "",
            report?.debriefProfile.tacticalText ?? "",
            report?.debriefProfile.failureText ?? "",
        ].joined(separator: " ")

        switch dimension {
        case .clarity:
            return [
                metric(dimension, "Briefing readiness", FunMetricScoring.booleanScore(entry.isBriefingReady), "\(entry.objectiveCount) objectives, \(entry.ruleCount) rules."),
                metric(dimension, "Objective visibility", FunMetricScoring.countScore(entry.objectiveCount, target: 4), "\(entry.objectiveCount) objectives."),
                metric(dimension, "Rule visibility", FunMetricScoring.countScore(entry.ruleCount, target: 4), "\(entry.ruleCount) rule hooks."),
                runtimeMetric(dimension, "Unified playable flow", runSummary, notRunScore: 82),
            ]
        case .agency:
            return [
                metric(dimension, "Playable parity", FunMetricScoring.booleanScore(entry.isParityReady), entry.readinessLabel),
                metric(dimension, "Player objectives", FunMetricScoring.countScore(battlefield.objectives.filter { $0.side == .player }.count, target: 3), "\(battlefield.objectives.filter { $0.side == .player }.count) player objectives."),
                metric(dimension, "AI priorities", FunMetricScoring.countScore(report?.aiPlan.priorities.count ?? 0, target: 2), "\(report?.aiPlan.priorities.count ?? 0) AI priorities."),
                runtimeMetric(dimension, "Selectable board route", runSummary, notRunScore: 80),
            ]
        case .challenge:
            return [
                metric(dimension, "Scoring profile", FunMetricScoring.countScore(report?.scoringProfile.maxPlayerScore ?? 0, target: 12), "Max score \(report?.scoringProfile.maxPlayerScore ?? 0)."),
                metric(dimension, "Blocked-action expectations", FunMetricScoring.countScore(report?.aiPlan.blockedActionExpectations.count ?? 0, target: 2), "\(report?.aiPlan.blockedActionExpectations.count ?? 0) blocked-action expectations."),
                metric(dimension, "Opposition objectives", FunMetricScoring.countScore(battlefield.objectives.filter { $0.side == .guderianAI }.count, target: 1), "\(battlefield.objectives.filter { $0.side == .guderianAI }.count) German-context objectives."),
            ]
        case .mastery:
            return [
                metric(dimension, "Debrief learning", FunMetricScoring.booleanScore(report?.debriefProfile.failureText.isEmpty == false), report?.debriefProfile.title ?? "No debrief profile."),
                metric(dimension, "Rule families", FunMetricScoring.countScore(LateCareerConsolidatedPlaybookCatalog.ruleBindings(for: entry.id).count, target: LateCareerRuleFamily.allCases.count), "\(LateCareerConsolidatedPlaybookCatalog.ruleBindings(for: entry.id).count) rule bindings."),
                metric(dimension, "Scoring persistence", FunMetricScoring.booleanScore(report?.isParityReady == true), report?.completionRecord.persistenceKey ?? "No completion record."),
            ]
        case .novelty:
            return [
                metric(dimension, "Staff map detail", FunMetricScoring.countScore(entry.mapFeatureCount, target: 24), "\(entry.mapFeatureCount) map features."),
                metric(dimension, "Sourceable geography", FunMetricScoring.countScore(entry.mapSourceNoteCount, target: 1), "\(entry.mapSourceNoteCount) source notes."),
                metric(dimension, "Rule texture", FunMetricScoring.countScore(entry.ruleCount, target: 4), "\(entry.ruleCount) scenario rules."),
                metric(dimension, "Scope identity", FunMetricScoring.booleanScore(entry.scope.requiresCommandCaveat), entry.scopeLabel),
            ]
        case .consequence:
            return [
                metric(dimension, "Completion record", FunMetricScoring.booleanScore(report?.completionRecord.persistenceKey.isEmpty == false), report?.completionRecord.note ?? "No completion record."),
                metric(dimension, "Score stakes", FunMetricScoring.countScore(report?.scoringProfile.playerObjectiveScore ?? 0, target: 8), "Player objective score \(report?.scoringProfile.playerObjectiveScore ?? 0)."),
                metric(dimension, "Failure handling", FunMetricScoring.textSignalScore(text: text, signals: ["failure", "withdraw", "cut", "preserve", "contain", "hold", "break"], target: 2), "Debrief and rules are checked for consequence language."),
            ]
        case .pacing:
            return [
                metric(dimension, "Turn bounds", lateCareerTurnScore(report), "Target turn \(report?.scoringProfile.targetTurnLowerBound ?? 0)-\(report?.scoringProfile.targetTurnUpperBound ?? 0)."),
                metric(dimension, "AI pressure cadence", FunMetricScoring.countScore(report?.aiPlan.priorities.count ?? 0, target: 2), "\(report?.aiPlan.priorities.count ?? 0) priorities."),
                metric(dimension, "Run cadence", runSummary?.completed == true ? 92 : 80, runSummary?.detail ?? "Run harness was not requested."),
            ]
        case .ethicalFrame:
            return [
                metric(dimension, "Visible command caveat", FunMetricScoring.booleanScore(entry.visibleCommandCaveatLabel.localizedCaseInsensitiveContains("not a Guderian field command"), fail: 20), entry.visibleCommandCaveatLabel),
                metric(dimension, "Default opposition frame", resistanceFrameScore(text: text), "Playable role text is checked for opposition, defense, breakout, or containment framing."),
                metric(dimension, "Scope separation", FunMetricScoring.booleanScore(!entry.scope.allowsDirectBattlefieldScenario), entry.scopeLabel),
                metric(dimension, "Non-celebratory language", nonCelebratoryLanguageScore(text), "Late-career copy is checked for heroic German-command language."),
            ]
        }
    }

    private static func metric(
        _ dimension: FunDimension,
        _ name: String,
        _ score: Int,
        _ evidence: String
    ) -> FunMetric {
        FunMetric(
            id: "\(dimension.rawValue)-\(name)".stableMetricID,
            dimension: dimension,
            name: name,
            score: score,
            evidence: evidence
        )
    }

    private static func runtimeMetric(
        _ dimension: FunDimension,
        _ name: String,
        _ runSummary: FunScenarioRunSummary?,
        notRunScore: Int
    ) -> FunMetric {
        let score: Int
        let evidence: String
        if let runSummary {
            score = runSummary.completed ? 94 : FunMetricScoring.penalized(62, blockerCount: max(1, runSummary.blockerCount))
            evidence = runSummary.detail
        } else {
            score = notRunScore
            evidence = "Scenario run was not requested; static catalog signals are used."
        }
        return metric(dimension, name, score, evidence)
    }

    private static func categoryVarietyMetric(
        _ dimension: FunDimension,
        mapMetrics: ScenarioMapDetailMetrics
    ) -> FunMetric {
        let categories: [ScenarioMapDetailCategory] = [
            .water,
            .roads,
            .railways,
            .crossings,
            .settlements,
            .groundTerrain,
            .objectives,
            .pressureMarkers,
        ]
        let present = categories.filter { mapMetrics.count(for: $0) > 0 }.count
        return metric(dimension, "Map variety", FunMetricScoring.countScore(present, target: 7), "\(present) geography/play categories represented.")
    }

    private static func scoreSpreadMetric(_ balance: ScenarioBalanceProfile) -> Int {
        let minimum = balance.outcomeBands.map(\.scoreRange.lowerBound).min() ?? 0
        let spread = balance.maxPlayerScore - minimum
        return FunMetricScoring.countScore(spread, target: 10)
    }

    private static func targetTurnScore(_ range: ClosedRange<Int>) -> Int {
        let span = range.upperBound - range.lowerBound + 1
        let base = range.lowerBound >= 4 && range.upperBound <= 10 ? 88 : 74
        return FunMetricScoring.bounded(base + min(span, 4) * 2)
    }

    private static func lateCareerTurnScore(_ report: LateCareerPlayableBattleReport?) -> Int {
        guard let report else {
            return 55
        }
        let lower = report.scoringProfile.targetTurnLowerBound
        let upper = report.scoringProfile.targetTurnUpperBound
        let base = lower >= 3 && upper <= 9 ? 88 : 74
        return FunMetricScoring.bounded(base + min(max(1, upper - lower + 1), 4) * 2)
    }

    private static func phaseCoverageScore(
        germanPlan: GermanAIPlan,
        opposingPlan: OpposingForceAIPlan
    ) -> Int {
        let phases: [NativeBoardPhase] = [.movement, .shooting, .assault]
        let germanCoverage = phases.filter { !germanPlan.targetPriorities(for: $0).isEmpty }.count
        let opposingCoverage = phases.filter { !opposingPlan.targetPriorities(for: $0).isEmpty }.count
        return FunMetricScoring.countScore(germanCoverage + opposingCoverage, target: 6)
    }

    private static func resistanceFrameScore(text: String) -> Int {
        FunMetricScoring.textSignalScore(
            text: text,
            signals: ["resist", "delay", "withdraw", "evacuat", "counterattack", "contain", "defend", "breakout", "preserve", "hold"],
            target: 3,
            floor: 45
        )
    }

    private static func commandCaveatScore(
        scopeRecord: GuderianCareerScopeRecord?,
        briefing: UnifiedBattleBriefingShell?
    ) -> Int {
        guard let scopeRecord else {
            return 72
        }
        if !scopeRecord.requiresCommandCaveat {
            return 90
        }
        let text = "\(scopeRecord.playableFraming) \(briefing?.displayText ?? "")"
        return FunMetricScoring.booleanScore(
            text.localizedCaseInsensitiveContains("not a clean direct") ||
                text.localizedCaseInsensitiveContains("contextual") ||
                text.localizedCaseInsensitiveContains("caveat"),
            pass: 94,
            fail: 50
        )
    }

    private static func nonCelebratoryLanguageScore(_ text: String) -> Int {
        let lowered = text.lowercased()
        let forbidden = [
            "heroic german",
            "glorious",
            "admire",
            "admirable",
            "celebrate",
            "triumphant german",
        ]
        let hits = forbidden.filter { lowered.contains($0) }.count
        return hits == 0 ? 96 : max(20, 80 - hits * 25)
    }

    private static func gates(
        for id: String,
        dimensions: [FunDimensionScore],
        runSummary: FunScenarioRunSummary?,
        thresholds: FunThresholds = .guderianDefault
    ) -> [FunAcceptanceGate] {
        var gates: [FunAcceptanceGate] = []
        let weighted = dimensions.reduce(0.0) { $0 + Double($1.score * $1.weight) }
        let totalWeight = dimensions.reduce(0) { $0 + $1.weight }
        let overall = totalWeight > 0 ? weighted / Double(totalWeight) : 0

        if overall < Double(thresholds.acceptableOverallScore) {
            gates.append(
                FunAcceptanceGate(
                    id: "\(id)-overall",
                    dimension: nil,
                    status: .blocker,
                    title: "Overall fun score below threshold",
                    detail: "\(FunScoreFormatter.percent(overall)) is below \(thresholds.acceptableOverallScore)."
                )
            )
        }

        for dimension in dimensions where dimension.score < thresholds.minimumDimensionScore {
            gates.append(
                FunAcceptanceGate(
                    id: "\(id)-\(dimension.dimension.rawValue.stableMetricID)-minimum",
                    dimension: dimension.dimension,
                    status: .blocker,
                    title: "\(dimension.dimension.rawValue) below threshold",
                    detail: "\(dimension.score) is below \(thresholds.minimumDimensionScore)."
                )
            )
        }

        if let ethical = dimensions.first(where: { $0.dimension == .ethicalFrame }),
           ethical.score < thresholds.ethicalFrameBlockerScore {
            gates.append(
                FunAcceptanceGate(
                    id: "\(id)-ethical-frame-release-blocker",
                    dimension: .ethicalFrame,
                    status: .blocker,
                    title: "Ethical frame release blocker",
                    detail: "\(ethical.score) is below \(thresholds.ethicalFrameBlockerScore)."
                )
            )
        }

        if let runSummary, runSummary.status == .blocked {
            gates.append(
                FunAcceptanceGate(
                    id: "\(id)-runtime-blocked",
                    dimension: nil,
                    status: .blocker,
                    title: "Scenario run blocked",
                    detail: runSummary.detail
                )
            )
        }

        return gates
    }

    private static func opportunities(
        for dimensions: [FunDimensionScore],
        runSummary: FunScenarioRunSummary?
    ) -> [String] {
        var result = dimensions
            .sorted { $0.score < $1.score }
            .prefix(3)
            .map { "\($0.dimension.rawValue): raise \($0.metrics.sorted { $0.score < $1.score }.first?.name ?? $0.dimension.documentationAnchor)." }

        if runSummary == nil {
            result.append("Run the unified harness to replace static confidence with live scenario evidence.")
        }
        return Array(result.prefix(4))
    }
}

private extension FunScenarioRunSummary {
    init(harnessResult: UnifiedPlayableScreenHarnessResult) {
        self.init(
            id: harnessResult.id.description,
            status: harnessResult.completedAllStages ? .passed : .blocked,
            stepCount: harnessResult.steps.count,
            blockerCount: harnessResult.blockers.count,
            completionPersistenceKey: harnessResult.completionPersistenceKey,
            detail: harnessResult.completedAllStages ?
                "\(harnessResult.title) completed \(harnessResult.steps.count) unified playable stages." :
                "\(harnessResult.title) blocked: \(harnessResult.blockers.joined(separator: "; "))"
        )
    }
}

private extension String {
    var stableMetricID: String {
        lowercased()
            .map { character -> Character in
                if character.isLetter || character.isNumber {
                    return character
                }
                return "-"
            }
            .reduce(into: "") { result, character in
                if character == "-", result.last == "-" {
                    return
                }
                result.append(character)
            }
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
