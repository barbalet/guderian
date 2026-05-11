import Foundation

public struct FunDimensionAggregate: Identifiable, Codable, Hashable, Sendable {
    public let dimension: FunDimension
    public let averageScore: Double
    public let minimumScore: Int

    public var id: String {
        dimension.rawValue
    }
}

public struct FunScenarioKindSummary: Identifiable, Codable, Hashable, Sendable {
    public let kind: FunScenarioKind
    public let scenarioCount: Int
    public let averageOverallScore: Double
    public let passingScenarioCount: Int

    public var id: String {
        kind.rawValue
    }
}

public struct FunScoreComparison: Codable, Hashable, Sendable {
    public let baselineLabel: String
    public let candidateLabel: String
    public let baselineAverage: Double
    public let candidateAverage: Double

    public var delta: Double {
        candidateAverage - baselineAverage
    }

    public var increased: Bool {
        delta > 0
    }
}

public struct FunOptimizationReport: Codable, Hashable, Sendable {
    public let title: String
    public let runUnifiedHarness: Bool
    public let audits: [FunScenarioAudit]
    public let funDTReport: FunDTReport
    public let thresholds: FunThresholds

    public init(
        title: String,
        runUnifiedHarness: Bool,
        audits: [FunScenarioAudit],
        funDTReport: FunDTReport = FunDTCatalog.report(),
        thresholds: FunThresholds = .guderianDefault
    ) {
        self.title = title
        self.runUnifiedHarness = runUnifiedHarness
        self.audits = audits
        self.funDTReport = funDTReport
        self.thresholds = thresholds
    }

    public static func generate(runUnifiedHarness: Bool = false) throws -> FunOptimizationReport {
        try FunOptimizationReport(
            title: runUnifiedHarness ? "Guderian Fun Live Scenario Report" : "Guderian Fun Static Catalog Report",
            runUnifiedHarness: runUnifiedHarness,
            audits: FunScenarioAuditCatalog.allAudits(runUnifiedHarness: runUnifiedHarness)
        )
    }

    public static func compare(
        baseline: FunOptimizationReport,
        candidate: FunOptimizationReport
    ) -> FunScoreComparison {
        FunScoreComparison(
            baselineLabel: baseline.title,
            candidateLabel: candidate.title,
            baselineAverage: baseline.averageOverallScore,
            candidateAverage: candidate.averageOverallScore
        )
    }

    public var scenarioCount: Int {
        audits.count
    }

    public var averageOverallScore: Double {
        guard !audits.isEmpty else {
            return 0
        }
        return audits.reduce(0) { $0 + $1.overallScore } / Double(audits.count)
    }

    public var passingScenarioCount: Int {
        audits.filter(\.passedFunGates).count
    }

    public var blockerCount: Int {
        audits.reduce(0) { $0 + $1.blockerGates.count }
    }

    public var averageFunDTScore: Double {
        funDTReport.averageFunDTScore
    }

    public var dimensionAggregates: [FunDimensionAggregate] {
        FunDimension.allCases.map { dimension in
            let scores = audits.map { $0.score(for: dimension) }
            let average = scores.isEmpty ? 0 : Double(scores.reduce(0, +)) / Double(scores.count)
            return FunDimensionAggregate(
                dimension: dimension,
                averageScore: average,
                minimumScore: scores.min() ?? 0
            )
        }
    }

    public var kindSummaries: [FunScenarioKindSummary] {
        FunScenarioKind.allCasesInReportOrder.compactMap { kind in
            let kindAudits = audits.filter { $0.kind == kind }
            guard !kindAudits.isEmpty else {
                return nil
            }
            let average = kindAudits.reduce(0) { $0 + $1.overallScore } / Double(kindAudits.count)
            return FunScenarioKindSummary(
                kind: kind,
                scenarioCount: kindAudits.count,
                averageOverallScore: average,
                passingScenarioCount: kindAudits.filter(\.passedFunGates).count
            )
        }
    }

    public func weakestAudits(limit: Int = 5) -> [FunScenarioAudit] {
        Array(audits.sorted { lhs, rhs in
            if lhs.overallScore == rhs.overallScore {
                return lhs.order < rhs.order
            }
            return lhs.overallScore < rhs.overallScore
        }.prefix(limit))
    }

    public func markdownSummary(maxWeakRows: Int = 5) -> String {
        var lines: [String] = []
        lines.append("# \(title)")
        lines.append("")
        lines.append("- Scenarios audited: \(scenarioCount)")
        lines.append("- Average fun score: \(FunScoreFormatter.percent(averageOverallScore))")
        lines.append("- Average funDT score: \(FunScoreFormatter.percent(averageFunDTScore))")
        lines.append("- Passing scenarios: \(passingScenarioCount)/\(scenarioCount)")
        lines.append("- Blocker gates: \(blockerCount)")
        lines.append("- Runtime harness: \(runUnifiedHarness ? "executed" : "not executed")")
        lines.append("")
        lines.append("## Kind Summary")
        for summary in kindSummaries {
            lines.append("- \(summary.kind.rawValue): \(summary.passingScenarioCount)/\(summary.scenarioCount) passing, average \(FunScoreFormatter.percent(summary.averageOverallScore))")
        }
        lines.append("")
        lines.append("## Dimension Averages")
        for aggregate in dimensionAggregates {
            lines.append("- \(aggregate.dimension.rawValue): average \(FunScoreFormatter.percent(aggregate.averageScore)), minimum \(aggregate.minimumScore)")
        }
        lines.append("")
        lines.append("## Weakest Scenarios")
        for audit in weakestAudits(limit: maxWeakRows) {
            let weakestDimension = audit.dimensionScores.min { $0.score < $1.score }
            lines.append("- \(audit.title): \(FunScoreFormatter.percent(audit.overallScore)) overall; weakest \(weakestDimension?.dimension.rawValue ?? "n/a") \(weakestDimension?.score ?? 0)")
        }
        lines.append("")
        lines.append("## funDT Timeline")
        for reconstruction in funDTReport.reconstructions {
            lines.append("- \(reconstruction.order). \(reconstruction.title): \(FunScoreFormatter.percent(reconstruction.funDTScore)) funDT; axes \(reconstruction.strongestDeltaAxisLabels.joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }
}

private extension FunScenarioKind {
    static let allCasesInReportOrder: [FunScenarioKind] = [.fieldCommand, .lateCareer]
}
