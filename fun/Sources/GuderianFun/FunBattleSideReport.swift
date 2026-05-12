import Foundation
import GuderianCore

public struct FunBattleSideScore: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: String
    public let order: Int
    public let title: String
    public let kind: FunScenarioKind
    public let dateLabel: String
    public let sideID: String
    public let sideTitle: String
    public let sideLens: String
    public let funScore: Double
    public let funDTScore: Double
    public let weakestDimension: FunDimension
    public let weakestDimensionScore: Int
    public let strongestDTAxes: [String]
    public let improvementFocus: String
}

public struct FunBattleSideReport: Codable, Hashable, Sendable {
    public let rows: [FunBattleSideScore]

    public var highestFunRows: [FunBattleSideScore] {
        ranked(rows, by: \.funScore, descending: true)
    }

    public var lowestFunRows: [FunBattleSideScore] {
        ranked(rows, by: \.funScore, descending: false)
    }

    public var highestFunDTRows: [FunBattleSideScore] {
        ranked(rows, by: \.funDTScore, descending: true)
    }

    public var lowestFunDTRows: [FunBattleSideScore] {
        ranked(rows, by: \.funDTScore, descending: false)
    }

    public func markdownAppendix(topLimit: Int = 5, bottomLimit: Int = 5) -> String {
        var lines: [String] = []
        lines.append("## Battle Fun And funDT Appendix")
        lines.append("")
        lines.append("This appendix is generated from `FunBattleSideReportCatalog.generate()`. `Fun` is the side-adjusted weighted score from the catalog audit. `funDT` is the side-specific temporal-difference reconstruction: it asks how much this side's posture, command lens, objectives, pressure, force texture, and continuity change over campaign time. Scores are signals for tuning, not final truth.")
        lines.append("")
        lines.append("### Highest Fun")
        for row in highestFunRows.prefix(topLimit) {
            lines.append("- \(row.order). \(row.title) / \(row.sideTitle): \(FunScoreFormatter.percent(row.funScore)) fun; weakest \(row.weakestDimension.rawValue) \(row.weakestDimensionScore).")
        }
        lines.append("")
        lines.append("### Lowest Fun")
        for row in lowestFunRows.prefix(bottomLimit) {
            lines.append("- \(row.order). \(row.title) / \(row.sideTitle): \(FunScoreFormatter.percent(row.funScore)) fun; improve \(row.improvementFocus).")
        }
        lines.append("")
        lines.append("### Highest funDT")
        for row in highestFunDTRows.prefix(topLimit) {
            lines.append("- \(row.order). \(row.title) / \(row.sideTitle): \(FunScoreFormatter.percent(row.funDTScore)) funDT; strongest axes \(row.strongestDTAxes.joined(separator: ", ")).")
        }
        lines.append("")
        lines.append("### Lowest funDT")
        for row in lowestFunDTRows.prefix(bottomLimit) {
            lines.append("- \(row.order). \(row.title) / \(row.sideTitle): \(FunScoreFormatter.percent(row.funDTScore)) funDT; add/change \(row.improvementFocus).")
        }
        lines.append("")
        lines.append("### Per Battle / Per Side Data")
        lines.append("")
        lines.append("| # | Battle | Side | Fun | funDT | Weakest | Strongest funDT axes | Improvement focus |")
        lines.append("| ---: | --- | --- | ---: | ---: | --- | --- | --- |")
        for row in rows {
            lines.append("| \(row.order) | \(row.title.markdownEscaped) | \(row.sideTitle.markdownEscaped) | \(FunScoreFormatter.percent(row.funScore)) | \(FunScoreFormatter.percent(row.funDTScore)) | \(row.weakestDimension.rawValue) \(row.weakestDimensionScore) | \(row.strongestDTAxes.joined(separator: ", ").markdownEscaped) | \(row.improvementFocus.markdownEscaped) |")
        }
        lines.append("")
        lines.append("### Improvement Themes")
        lines.append("")
        lines.append("- Raise low-fun rows by strengthening their weakest scored dimension first: for this catalog that usually means richer consequence/debrief language, more side-specific agency, or clearer command-study caveats.")
        lines.append("- Raise low-funDT rows by changing the temporal grammar rather than merely adding content: alter objective verbs, pressure triggers, force texture, or map-use rhythm compared with the previous three battles.")
        lines.append("- Late-career staff-context battles need the most funDT help because many share Soviet pressure, German defensive context, medium tempo, and command-caveat structure. They benefit from sharper asymmetry: mines versus bridgeheads, fortress reduction versus pursuit, urban compression versus operational breakout, supply collapse versus relief attempts.")
        lines.append("- Guderian-command rows stay fun when they remain explicit command study. Their safest improvements are better comparative objectives, visible caveat labels, non-celebratory debriefs, and AI/player parity, not heroic copy or conquest rewards.")
        lines.append("- Opposing-force rows gain fun when partial success is more granular: preserved units, delayed crossings, denied exits, exhausted supply, and readable counterattack timing should all show up in score channels and debriefs.")
        return lines.joined(separator: "\n")
    }

    private func ranked(
        _ rows: [FunBattleSideScore],
        by keyPath: KeyPath<FunBattleSideScore, Double>,
        descending: Bool
    ) -> [FunBattleSideScore] {
        rows.sorted { lhs, rhs in
            let lhsScore = lhs[keyPath: keyPath]
            let rhsScore = rhs[keyPath: keyPath]
            if lhsScore == rhsScore {
                if lhs.order == rhs.order {
                    return lhs.sideTitle < rhs.sideTitle
                }
                return lhs.order < rhs.order
            }
            return descending ? lhsScore > rhsScore : lhsScore < rhsScore
        }
    }
}

public enum FunBattleSideReportCatalog {
    public static func generate(runUnifiedHarness: Bool = false) throws -> FunBattleSideReport {
        let report = try FunOptimizationReport.generate(runUnifiedHarness: runUnifiedHarness)
        let auditsByID = Dictionary(uniqueKeysWithValues: report.audits.map { ($0.id, $0) })
        let sideDTTimelines = sideFunDTTimelines()
        let baseVectors = FunDTCatalog.allBattleVectors().sorted { $0.order < $1.order }

        let rows = baseVectors.flatMap { vector -> [FunBattleSideScore] in
            guard let audit = auditsByID[vector.id] else {
                return []
            }
            let sideOptions = self.sideOptions(for: vector)
            return sideOptions.map { option in
                let dimensions = sideDimensionScores(for: audit, side: option)
                let weighted = weightedScore(dimensions)
                let weakest = dimensions.sorted { lhs, rhs in
                    if lhs.score == rhs.score {
                        return lhs.dimension.rawValue < rhs.dimension.rawValue
                    }
                    return lhs.score < rhs.score
                }.first
                let sideDT = sideDTTimelines[option.sideID]?[vector.id]

                return FunBattleSideScore(
                    id: "\(vector.id):\(option.sideID)",
                    battleID: vector.id,
                    order: vector.order,
                    title: vector.title,
                    kind: vector.kind,
                    dateLabel: vector.dateLabel,
                    sideID: option.sideID,
                    sideTitle: option.title,
                    sideLens: option.isCommandSide ? "Command study" : "Default opposing-force play",
                    funScore: weighted,
                    funDTScore: sideDT?.funDTScore ?? 0,
                    weakestDimension: weakest?.dimension ?? .clarity,
                    weakestDimensionScore: weakest?.score ?? 0,
                    strongestDTAxes: sideDT?.strongestDeltaAxisLabels ?? [],
                    improvementFocus: improvementFocus(weakestDimension: weakest?.dimension ?? .clarity, side: option)
                )
            }
        }

        return FunBattleSideReport(rows: rows.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return sideSortKey(lhs.sideID) < sideSortKey(rhs.sideID)
            }
            return lhs.order < rhs.order
        })
    }

    private static func sideDimensionScores(
        for audit: FunScenarioAudit,
        side: BattleSideOption
    ) -> [FunDimensionScore] {
        FunDimension.allCases.map { dimension in
            let base = audit.score(for: dimension)
            let score = adjustedScore(base: base, dimension: dimension, side: side, kind: audit.kind)
            return FunDimensionScore(
                dimension: dimension,
                metrics: [
                    FunMetric(
                        id: "\(audit.id)-\(side.sideID)-\(dimension.rawValue)".stableID,
                        dimension: dimension,
                        name: "Side-adjusted \(dimension.rawValue)",
                        score: score,
                        evidence: side.evidence
                    ),
                ]
            )
        }
    }

    private static func adjustedScore(
        base: Int,
        dimension: FunDimension,
        side: BattleSideOption,
        kind: FunScenarioKind
    ) -> Int {
        let hasBriefing = !side.playerBriefing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let caveatReady = hasCommandStudySignal(side.combinedText)

        switch dimension {
        case .clarity:
            return bounded(base + (hasBriefing ? 2 : -4) + (side.isCommandSide && !caveatReady ? -5 : 0))
        case .agency:
            return bounded(base + (side.isCommandSide ? -2 : 2))
        case .challenge:
            return bounded(base)
        case .mastery:
            return bounded(base + (side.isCommandSide ? 2 : 1))
        case .novelty:
            return bounded(base + (side.isCommandSide ? 4 : 2))
        case .consequence:
            return bounded(base + (side.isCommandSide ? -3 : 2))
        case .pacing:
            return bounded(base)
        case .ethicalFrame:
            if side.isCommandSide {
                let cap = kind == .lateCareer ? 92 : 88
                return min(cap, bounded(base + (caveatReady ? 0 : -12)))
            }
            return bounded(base + 3)
        }
    }

    private static func weightedScore(_ dimensions: [FunDimensionScore]) -> Double {
        let totalWeight = dimensions.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else {
            return 0
        }
        return dimensions.reduce(0.0) { $0 + Double($1.score * $1.weight) } / Double(totalWeight)
    }

    private static func improvementFocus(
        weakestDimension: FunDimension,
        side: BattleSideOption
    ) -> String {
        switch weakestDimension {
        case .clarity:
            return side.isCommandSide ? "make command-study caveats and objectives more visible" : "make first-turn objectives and feedback more explicit"
        case .agency:
            return side.isCommandSide ? "add German-side study objectives that are not just AI pressure" : "add alternate viable routes and recovery choices"
        case .challenge:
            return "tune pressure windows so mistakes are recoverable but costly"
        case .mastery:
            return "add debrief lessons that identify better timing, target, or withdrawal choices"
        case .novelty:
            return "change terrain use, objective verbs, or force mix versus nearby battles"
        case .consequence:
            return side.isCommandSide ? "tie command-study outcomes to sober tradeoffs and non-celebratory debriefs" : "score partial success through preservation, delay, escape, or counterattack effects"
        case .pacing:
            return "add mid-battle events or changing priorities before the outcome is obvious"
        case .ethicalFrame:
            return side.isCommandSide ? "strengthen non-celebratory framing and visible command caveats" : "keep resistance, survival, and containment language prominent"
        }
    }

    private static func sideFunDTTimelines() -> [String: [String: SideFunDTReconstruction]] {
        let baseVectors = FunDTCatalog.allBattleVectors().sorted { $0.order < $1.order }
        let sideIDs = [
            GuderianHistoricalSideID.opposingForce,
            GuderianHistoricalSideID.guderianCommand,
        ]

        return Dictionary(uniqueKeysWithValues: sideIDs.map { sideID in
            let vectors = baseVectors.compactMap { sideVector(for: $0, sideID: sideID) }
            let reconstructions = reconstruct(vectors: vectors)
            return (sideID, Dictionary(uniqueKeysWithValues: reconstructions.map { ($0.battleID, $0) }))
        })
    }

    private static func reconstruct(vectors: [SideFeatureVector]) -> [SideFunDTReconstruction] {
        vectors.enumerated().map { index, vector in
            let previous = vectors[safe: index - 1]
            let history = Array(vectors.prefix(index))
            let axisDeltas = FunDTAxis.allCases.map { axis in
                sideAxisDelta(axis: axis, vector: vector, previous: previous)
            }
            let immediate = previous.map { weightedDifference(vector, $0) } ?? 75
            let cumulative = history.isEmpty ? 100 : history.map { weightedDifference(vector, $0) }.reduce(0, +) / Double(history.count)
            let recent = Array(history.suffix(3))
            let rolling = recent.isEmpty ? 75 : recent.map { weightedDifference(vector, $0) }.reduce(0, +) / Double(recent.count)
            let rollingSimilarity = recent.isEmpty ? 0.35 : recent.map { weightedSimilarity(vector, $0) }.reduce(0, +) / Double(recent.count)
            let continuity = continuityScore(forSimilarity: rollingSimilarity)
            let score = immediate * 0.35 + cumulative * 0.35 + rolling * 0.20 + continuity * 0.10

            return SideFunDTReconstruction(
                battleID: vector.battleID,
                funDTScore: score,
                axisDeltas: axisDeltas
            )
        }
    }

    private static func sideAxisDelta(
        axis: FunDTAxis,
        vector: SideFeatureVector,
        previous: SideFeatureVector?
    ) -> FunDTAxisDelta {
        let currentValues = vector.values(for: axis)
        let previousValues = previous?.values(for: axis) ?? []
        let difference = previous == nil ? 75 : (1 - jaccard(currentValues, previousValues)) * 100
        let note: String
        if previous == nil {
            note = "Campaign origin establishes this side axis."
        } else if difference >= 70 {
            note = "Strong side-specific temporal change on this axis."
        } else if difference >= 35 {
            note = "Moderate side-specific temporal change on this axis."
        } else {
            note = "Mostly continuous with the previous same-side battle."
        }

        return FunDTAxisDelta(
            axis: axis,
            previousValues: previousValues.sorted(),
            currentValues: currentValues.sorted(),
            differenceScore: difference,
            note: note
        )
    }

    private static func sideVector(
        for vector: FunDTBattleFeatureVector,
        sideID: String
    ) -> SideFeatureVector? {
        guard let side = sideOptions(for: vector).first(where: { $0.sideID == sideID }) else {
            return nil
        }

        var axisValues = Dictionary(uniqueKeysWithValues: FunDTAxis.allCases.map { axis in
            (axis, vector.values(for: axis))
        })

        axisValues[.commandScope, default: []].formUnion([
            side.sideID,
            side.isCommandSide ? "command-study-side" : "opposing-force-default-side",
            side.role.rawValue,
        ])
        if side.isCommandSide && hasCommandStudySignal(side.combinedText) {
            axisValues[.commandScope, default: []].insert("visible-command-caveat")
        }
        axisValues[.playerPosture, default: []].formUnion(tokens(in: side.playerBriefing, matching: postureKeywords))
        axisValues[.playerPosture, default: []].insert(side.isCommandSide ? "command-study" : "resistance-default")
        axisValues[.objectiveSystem, default: []].formUnion(tokens(in: side.objectiveNames.joined(separator: " "), matching: objectiveKeywords))
        axisValues[.pressureSystem, default: []].formUnion(tokens(in: side.aiBriefing, matching: pressureKeywords))
        axisValues[.pressureSystem, default: []].insert(side.isCommandSide ? "german-pressure-player" : "anti-guderian-pressure")
        axisValues[.forceSystem, default: []].formUnion(tokens(in: "\(side.title) \(side.historicalForce) \(side.armyListName)", matching: forceKeywords))

        return SideFeatureVector(
            battleID: vector.id,
            order: vector.order,
            title: vector.title,
            sideID: side.sideID,
            axes: axisValues
        )
    }

    private static func sideOptions(for vector: FunDTBattleFeatureVector) -> [BattleSideOption] {
        if vector.id.hasPrefix("field:") {
            let raw = String(vector.id.dropFirst("field:".count))
            guard let id = GuderianBattleID(rawValue: raw),
                  let scenario = GuderianCampaignCatalog.scenario(id: id) else {
                return []
            }
            let historicalScenario = GuderianHistoricalScenarioAdapter.scenario(for: scenario)
            return historicalScenario.sideOptions.map { option in
                let objectiveNames: [String]
                if option.id == GuderianHistoricalSideID.guderianCommand {
                    objectiveNames = GermanAIPlanCatalog.plan(for: scenario).orders.map(\.target)
                } else {
                    objectiveNames = scenario.objectives.map(\.name)
                }
                return BattleSideOption(
                    sideID: option.id,
                    role: option.role,
                    title: option.title,
                    historicalForce: option.historicalForce,
                    armyListName: option.armyListName,
                    playerBriefing: option.playerBriefing,
                    aiBriefing: option.aiBriefing,
                    objectiveNames: objectiveNames
                )
            }.sorted { sideSortKey($0.sideID) < sideSortKey($1.sideID) }
        }

        if vector.id.hasPrefix("late:") {
            let id = String(vector.id.dropFirst("late:".count))
            guard let entry = LateCareerGuderianPresentationCatalog.entry(for: id) else {
                return []
            }
            return UnifiedGuderianBattleSideSelectionCatalog.sideOptions(for: entry).map { option in
                let nativePlayer = UnifiedGuderianBattleSideSelectionCatalog.nativePlayer(for: option.id) ?? .none
                return BattleSideOption(
                    sideID: option.id,
                    role: option.role,
                    title: option.title,
                    historicalForce: option.historicalForce,
                    armyListName: option.armyListName,
                    playerBriefing: option.playerBriefing,
                    aiBriefing: option.aiBriefing,
                    objectiveNames: UnifiedGuderianBattleSideSelectionCatalog.objectivePriorityNames(for: nativePlayer, in: entry)
                )
            }.sorted { sideSortKey($0.sideID) < sideSortKey($1.sideID) }
        }

        return []
    }

    private static func weightedDifference(_ lhs: SideFeatureVector, _ rhs: SideFeatureVector) -> Double {
        FunDTAxis.allCases.reduce(0) { partial, axis in
            let similarity = jaccard(lhs.values(for: axis), rhs.values(for: axis))
            return partial + (1 - similarity) * 100 * axis.weight
        }
    }

    private static func weightedSimilarity(_ lhs: SideFeatureVector, _ rhs: SideFeatureVector) -> Double {
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

    private static func tokens(in text: String, matching keywords: [String]) -> Set<String> {
        let lowered = text.lowercased()
        return Set(keywords.filter { lowered.contains($0.lowercased()) })
    }

    private static func hasCommandStudySignal(_ text: String) -> Bool {
        let lowered = text.lowercased()
        return [
            "study",
            "caveat",
            "non-celebratory",
            "not a guderian field command",
            "not direct",
            "context",
        ].contains { lowered.contains($0) }
    }

    private static func bounded(_ score: Int) -> Int {
        min(100, max(0, score))
    }

    private static func sideSortKey(_ sideID: String) -> Int {
        sideID == GuderianHistoricalSideID.opposingForce ? 0 : 1
    }

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
        "study",
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
        "pressure",
        "capture",
        "interdict",
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
        "contest",
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
        "allied",
    ]
}

private struct BattleSideOption: Hashable, Sendable {
    let sideID: String
    let role: HistoricalSideRole
    let title: String
    let historicalForce: String
    let armyListName: String
    let playerBriefing: String
    let aiBriefing: String
    let objectiveNames: [String]

    var isCommandSide: Bool {
        sideID == GuderianHistoricalSideID.guderianCommand
    }

    var combinedText: String {
        "\(title) \(historicalForce) \(playerBriefing) \(aiBriefing) \(objectiveNames.joined(separator: " "))"
    }

    var evidence: String {
        "\(sideID): \(playerBriefing)"
    }
}

private struct SideFeatureVector: Hashable, Sendable {
    let battleID: String
    let order: Int
    let title: String
    let sideID: String
    let axes: [FunDTAxis: Set<String>]

    func values(for axis: FunDTAxis) -> Set<String> {
        axes[axis] ?? []
    }
}

private struct SideFunDTReconstruction: Hashable, Sendable {
    let battleID: String
    let funDTScore: Double
    let axisDeltas: [FunDTAxisDelta]

    var strongestDeltaAxisLabels: [String] {
        Array(axisDeltas.sorted { lhs, rhs in
            if lhs.differenceScore == rhs.differenceScore {
                return lhs.axis.rawValue < rhs.axis.rawValue
            }
            return lhs.differenceScore > rhs.differenceScore
        }.prefix(3)).map { $0.axis.rawValue }
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension String {
    var stableID: String {
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

    var markdownEscaped: String {
        replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
