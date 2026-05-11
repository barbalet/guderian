import Foundation
import GuderianCore

public enum FunDTAxis: String, CaseIterable, Codable, Hashable, Sendable {
    case chronology = "Chronology"
    case commandScope = "Command Scope"
    case playerPosture = "Player Posture"
    case terrainSystem = "Terrain System"
    case objectiveSystem = "Objective System"
    case pressureSystem = "Pressure System"
    case forceSystem = "Force System"
    case tempo = "Tempo"

    var weight: Double {
        switch self {
        case .chronology:
            return 0.10
        case .commandScope:
            return 0.12
        case .playerPosture:
            return 0.16
        case .terrainSystem:
            return 0.15
        case .objectiveSystem:
            return 0.18
        case .pressureSystem:
            return 0.14
        case .forceSystem:
            return 0.10
        case .tempo:
            return 0.05
        }
    }
}

public struct FunDTAxisFeatureSet: Identifiable, Codable, Hashable, Sendable {
    public let axis: FunDTAxis
    public let values: [String]

    public var id: String {
        axis.rawValue
    }

    public init(axis: FunDTAxis, values: Set<String>) {
        self.axis = axis
        self.values = values.filter { !$0.isEmpty }.sorted()
    }

    public var valueSet: Set<String> {
        Set(values)
    }
}

public struct FunDTBattleFeatureVector: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let order: Int
    public let title: String
    public let kind: FunScenarioKind
    public let dateLabel: String
    public let axes: [FunDTAxisFeatureSet]

    public init(
        id: String,
        order: Int,
        title: String,
        kind: FunScenarioKind,
        dateLabel: String,
        axes: [FunDTAxisFeatureSet]
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.kind = kind
        self.dateLabel = dateLabel
        self.axes = axes
    }

    public func values(for axis: FunDTAxis) -> Set<String> {
        axes.first { $0.axis == axis }?.valueSet ?? []
    }
}

public struct FunDTAxisDelta: Identifiable, Codable, Hashable, Sendable {
    public let axis: FunDTAxis
    public let previousValues: [String]
    public let currentValues: [String]
    public let differenceScore: Double
    public let note: String

    public var id: String {
        axis.rawValue
    }
}

public struct FunDTBattleReconstruction: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let order: Int
    public let title: String
    public let kind: FunScenarioKind
    public let dateLabel: String
    public let previousBattleTitle: String?
    public let immediateDifferenceScore: Double
    public let cumulativeNoveltyScore: Double
    public let rollingDifferenceScore: Double
    public let motifContinuityScore: Double
    public let funDTScore: Double
    public let axisDeltas: [FunDTAxisDelta]
    public let reconstructionSummary: String

    public var strongestDeltaAxes: [FunDTAxisDelta] {
        Array(axisDeltas.sorted { lhs, rhs in
            if lhs.differenceScore == rhs.differenceScore {
                return lhs.axis.rawValue < rhs.axis.rawValue
            }
            return lhs.differenceScore > rhs.differenceScore
        }.prefix(3))
    }

    public var strongestDeltaAxisLabels: [String] {
        strongestDeltaAxes.map { $0.axis.rawValue }
    }
}

public struct FunDTReport: Codable, Hashable, Sendable {
    public let reconstructions: [FunDTBattleReconstruction]

    public var averageFunDTScore: Double {
        guard !reconstructions.isEmpty else {
            return 0
        }
        return reconstructions.reduce(0) { $0 + $1.funDTScore } / Double(reconstructions.count)
    }

    public var lowestFunDTBattles: [FunDTBattleReconstruction] {
        reconstructions.sorted { lhs, rhs in
            if lhs.funDTScore == rhs.funDTScore {
                return lhs.order < rhs.order
            }
            return lhs.funDTScore < rhs.funDTScore
        }
    }
}

public enum FunDTCatalog {
    public static func reconstructAllBattles() -> [FunDTBattleReconstruction] {
        let vectors = allBattleVectors()
        return vectors.enumerated().map { index, vector in
            reconstruct(vector: vector, previous: vectors[safe: index - 1], history: Array(vectors.prefix(index)))
        }
    }

    public static func report() -> FunDTReport {
        FunDTReport(reconstructions: reconstructAllBattles())
    }

    public static func allBattleVectors() -> [FunDTBattleFeatureVector] {
        fieldCommandVectors() + lateCareerVectors()
    }

    private static func fieldCommandVectors() -> [FunDTBattleFeatureVector] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map { scenario in
                let balance = ScenarioBalanceCatalog.profile(for: scenario)
                let layout = ScenarioMapCatalog.layout(for: scenario)
                let mapMetrics = ScenarioMapDetailMetrics(layout: layout)
                let scope = GuderianCareerScopeCatalog.record(for: scenario.id)?.scope.rawValue ?? GuderianCommandScope.directFieldCommand.rawValue
                let forceText = scenario.forces.map { "\($0.side) \($0.historicalForce) \($0.role)" }.joined(separator: " ")
                let objectiveText = scenario.objectives.map { "\($0.name) \($0.description)" }.joined(separator: " ")
                let pressureText = (
                    balance.pacingRules.map { "\($0.name) \($0.effect)" } +
                        GermanAIPlanCatalog.plan(for: scenario).orders.map { "\($0.target) \($0.instruction)" } +
                        OpposingForceAIPlanCatalog.plan(for: scenario).orders.map { "\($0.target) \($0.instruction)" }
                ).joined(separator: " ")

                return FunDTBattleFeatureVector(
                    id: "field:\(scenario.id.rawValue)",
                    order: scenario.order,
                    title: scenario.title,
                    kind: .fieldCommand,
                    dateLabel: scenario.dateLabel,
                    axes: axisSets([
                        .chronology: [
                            scenario.theater.rawValue,
                            "year-\(scenario.startDate.year)",
                        ],
                        .commandScope: [
                            scope,
                            scenario.id == .dunkirk ? "explicit-caveat" : "field-command-track",
                        ],
                        .playerPosture: Set([scenario.playerPosture.rawValue]).union(tokens(in: "\(scenario.designIntent) \(objectiveText)", matching: postureKeywords)),
                        .terrainSystem: terrainTokens(mapMetrics: mapMetrics, elements: layout.elements),
                        .objectiveSystem: tokens(in: objectiveText, matching: objectiveKeywords),
                        .pressureSystem: tokens(in: pressureText, matching: pressureKeywords).union([OpposingForceAIPlanCatalog.plan(for: scenario).behaviorProfile.rawValue]),
                        .forceSystem: tokens(in: forceText, matching: forceKeywords).union([OpposingForceAIPlanCatalog.plan(for: scenario).armyFamily.rawValue]),
                        .tempo: tempoTokens(lower: balance.targetTurns.lowerBound, upper: balance.targetTurns.upperBound),
                    ])
                )
            }
    }

    private static func lateCareerVectors() -> [FunDTBattleFeatureVector] {
        LateCareerGuderianPresentationCatalog.allEntries
            .sorted { $0.order < $1.order }
            .map { entry in
                let battlefield = entry.battlefield
                let report = entry.playableReport
                let objectiveText = battlefield.objectives.map { "\($0.name) \($0.description)" }.joined(separator: " ")
                let forceText = battlefield.forces.map { "\($0.name) \($0.role) \($0.caveat)" }.joined(separator: " ")
                let ruleText = battlefield.rules.map { "\($0.name) \($0.trigger) \($0.effect)" }.joined(separator: " ")
                let aiText = report?.aiPlan.priorities.map { "\($0.targetName) \($0.detail)" }.joined(separator: " ") ?? ""

                return FunDTBattleFeatureVector(
                    id: "late:\(entry.id)",
                    order: GuderianCampaignCatalog.all.count + entry.order,
                    title: entry.title,
                    kind: .lateCareer,
                    dateLabel: entry.dateLabel,
                    axes: axisSets([
                        .chronology: [
                            "year-\(battlefield.dateRange.start.year)",
                            entry.scopeLabel,
                            "late-career",
                        ],
                        .commandScope: [
                            entry.scopeLabel,
                            "not-field-command",
                            battlefield.requiresCommandCaveat ? "explicit-caveat" : "uncaveated",
                        ],
                        .playerPosture: tokens(in: "\(entry.playerRole) \(entry.playableFraming) \(objectiveText)", matching: postureKeywords).union(["staff-context"]),
                        .terrainSystem: lateTerrainTokens(map: battlefield.map),
                        .objectiveSystem: tokens(in: objectiveText, matching: objectiveKeywords),
                        .pressureSystem: tokens(in: "\(ruleText) \(aiText)", matching: pressureKeywords).union(["late-war-pressure"]),
                        .forceSystem: tokens(in: forceText, matching: forceKeywords).union(["Late-war Soviet/Allied"]),
                        .tempo: tempoTokens(
                            lower: report?.scoringProfile.targetTurnLowerBound ?? 4,
                            upper: report?.scoringProfile.targetTurnUpperBound ?? 7
                        ),
                    ])
                )
            }
    }

    private static func reconstruct(
        vector: FunDTBattleFeatureVector,
        previous: FunDTBattleFeatureVector?,
        history: [FunDTBattleFeatureVector]
    ) -> FunDTBattleReconstruction {
        let axisDeltas = FunDTAxis.allCases.map { axis in
            axisDelta(axis: axis, vector: vector, previous: previous)
        }
        let immediate = previous.map { weightedDifference(vector, $0) } ?? 75
        let cumulative = history.isEmpty ? 100 : history.map { weightedDifference(vector, $0) }.reduce(0, +) / Double(history.count)
        let recent = Array(history.suffix(3))
        let rolling = recent.isEmpty ? 75 : recent.map { weightedDifference(vector, $0) }.reduce(0, +) / Double(recent.count)
        let rollingSimilarity = recent.isEmpty ? 0.35 : recent.map { weightedSimilarity(vector, $0) }.reduce(0, +) / Double(recent.count)
        let continuity = continuityScore(forSimilarity: rollingSimilarity)
        let funDT = immediate * 0.35 + cumulative * 0.35 + rolling * 0.20 + continuity * 0.10

        return FunDTBattleReconstruction(
            id: vector.id,
            order: vector.order,
            title: vector.title,
            kind: vector.kind,
            dateLabel: vector.dateLabel,
            previousBattleTitle: previous?.title,
            immediateDifferenceScore: immediate,
            cumulativeNoveltyScore: cumulative,
            rollingDifferenceScore: rolling,
            motifContinuityScore: continuity,
            funDTScore: funDT,
            axisDeltas: axisDeltas,
            reconstructionSummary: summary(
                title: vector.title,
                previousTitle: previous?.title,
                immediate: immediate,
                cumulative: cumulative,
                strongestAxes: Array(axisDeltas.sorted { $0.differenceScore > $1.differenceScore }.prefix(3)).map(\.axis)
            )
        )
    }

    private static func axisDelta(
        axis: FunDTAxis,
        vector: FunDTBattleFeatureVector,
        previous: FunDTBattleFeatureVector?
    ) -> FunDTAxisDelta {
        let currentValues = vector.values(for: axis)
        let previousValues = previous?.values(for: axis) ?? []
        let difference = previous == nil ? 75 : (1 - jaccard(currentValues, previousValues)) * 100
        let note: String
        if previous == nil {
            note = "Campaign origin establishes this axis."
        } else if difference >= 70 {
            note = "Strong temporal change on this axis."
        } else if difference >= 35 {
            note = "Moderate temporal change on this axis."
        } else {
            note = "Mostly continuous with the previous battle."
        }

        return FunDTAxisDelta(
            axis: axis,
            previousValues: previousValues.sorted(),
            currentValues: currentValues.sorted(),
            differenceScore: difference,
            note: note
        )
    }

    private static func weightedDifference(
        _ lhs: FunDTBattleFeatureVector,
        _ rhs: FunDTBattleFeatureVector
    ) -> Double {
        FunDTAxis.allCases.reduce(0) { partial, axis in
            let similarity = jaccard(lhs.values(for: axis), rhs.values(for: axis))
            return partial + (1 - similarity) * 100 * axis.weight
        }
    }

    private static func weightedSimilarity(
        _ lhs: FunDTBattleFeatureVector,
        _ rhs: FunDTBattleFeatureVector
    ) -> Double {
        FunDTAxis.allCases.reduce(0) { partial, axis in
            partial + jaccard(lhs.values(for: axis), rhs.values(for: axis)) * axis.weight
        }
    }

    private static func jaccard(_ lhs: Set<String>, _ rhs: Set<String>) -> Double {
        if lhs.isEmpty && rhs.isEmpty {
            return 1
        }
        let union = lhs.union(rhs)
        guard !union.isEmpty else {
            return 1
        }
        return Double(lhs.intersection(rhs).count) / Double(union.count)
    }

    private static func continuityScore(forSimilarity similarity: Double) -> Double {
        let idealSimilarity = 0.35
        return max(0, 100 - abs(similarity - idealSimilarity) * 180)
    }

    private static func summary(
        title: String,
        previousTitle: String?,
        immediate: Double,
        cumulative: Double,
        strongestAxes: [FunDTAxis]
    ) -> String {
        let axisText = strongestAxes.map(\.rawValue).joined(separator: ", ")
        guard let previousTitle else {
            return "\(title) is the funDT origin point, establishing \(axisText) as the first temporal pattern."
        }
        return "\(title) changes from \(previousTitle) most through \(axisText), with \(FunScoreFormatter.percent(immediate)) immediate difference and \(FunScoreFormatter.percent(cumulative)) cumulative novelty."
    }

    private static func axisSets(_ values: [FunDTAxis: Set<String>]) -> [FunDTAxisFeatureSet] {
        FunDTAxis.allCases.map { axis in
            FunDTAxisFeatureSet(axis: axis, values: values[axis] ?? [])
        }
    }

    private static func terrainTokens(
        mapMetrics: ScenarioMapDetailMetrics,
        elements: [ScenarioMapElement]
    ) -> Set<String> {
        var result: Set<String> = []
        for category in terrainCategories where mapMetrics.count(for: category) > 0 {
            result.insert(category.rawValue)
        }
        for element in elements {
            result.insert(element.kind.rawValue)
        }
        return result
    }

    private static func lateTerrainTokens(map: LateCareerStaffBattlefieldMap) -> Set<String> {
        var result = Set(map.elements.map { $0.kind.rawValue })
        if map.waterFeatureCount > 0 { result.insert(ScenarioMapDetailCategory.water.rawValue) }
        if map.roadFeatureCount > 0 { result.insert(ScenarioMapDetailCategory.roads.rawValue) }
        if map.railwayFeatureCount > 0 { result.insert(ScenarioMapDetailCategory.railways.rawValue) }
        if map.crossingFeatureCount > 0 { result.insert(ScenarioMapDetailCategory.crossings.rawValue) }
        if map.settlementFeatureCount > 0 { result.insert(ScenarioMapDetailCategory.settlements.rawValue) }
        if map.groundTerrainFeatureCount > 0 { result.insert(ScenarioMapDetailCategory.groundTerrain.rawValue) }
        return result
    }

    private static func tempoTokens(lower: Int, upper: Int) -> Set<String> {
        var result: Set<String> = []
        if upper <= 5 {
            result.insert("short")
        } else if upper <= 8 {
            result.insert("medium")
        } else {
            result.insert("long")
        }
        result.insert("turns-\(lower)-\(upper)")
        return result
    }

    private static func tokens(in text: String, matching keywords: [String]) -> Set<String> {
        let lowered = text.lowercased()
        return Set(keywords.filter { lowered.contains($0.lowercased()) })
    }

    private static let terrainCategories: [ScenarioMapDetailCategory] = [
        .water,
        .roads,
        .railways,
        .crossings,
        .settlements,
        .groundTerrain,
        .fortifications,
        .objectives,
        .pressureMarkers,
    ]

    private static let postureKeywords = [
        "delay",
        "mobile",
        "fortified",
        "urban",
        "counterattack",
        "breakout",
        "withdraw",
        "evacuat",
        "defend",
        "hold",
        "raid",
        "ambush",
        "staff",
        "bridgehead",
        "pocket",
    ]

    private static let objectiveKeywords = [
        "hold",
        "delay",
        "withdraw",
        "disrupt",
        "preserve",
        "evacuat",
        "counterattack",
        "breakout",
        "deny",
        "score",
        "bridge",
        "crossing",
        "rail",
        "road",
        "harbor",
        "port",
        "bunker",
        "pocket",
        "command",
        "supply",
        "exit",
        "corridor",
        "perimeter",
        "fortress",
    ]

    private static let pressureKeywords = [
        "air",
        "artillery",
        "engineer",
        "pincer",
        "supply",
        "logistics",
        "reinforcement",
        "assault",
        "shooting",
        "movement",
        "bridgehead",
        "encirclement",
        "interdict",
        "demolition",
        "pressure",
        "winter",
        "mud",
        "mine",
        "rail",
        "road",
        "blocked",
    ]

    private static let forceKeywords = [
        "polish",
        "french",
        "british",
        "belgian",
        "soviet",
        "german",
        "panzer",
        "infantry",
        "armor",
        "tank",
        "cavalry",
        "engineer",
        "artillery",
        "naval",
        "command",
        "guards",
        "front",
        "army",
    ]
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
