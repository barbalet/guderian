import Foundation

public struct FunMetric: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let dimension: FunDimension
    public let name: String
    public let score: Int
    public let evidence: String

    public init(
        id: String,
        dimension: FunDimension,
        name: String,
        score: Int,
        evidence: String
    ) {
        self.id = id
        self.dimension = dimension
        self.name = name
        self.score = Self.clamped(score)
        self.evidence = evidence
    }

    private static func clamped(_ score: Int) -> Int {
        min(100, max(0, score))
    }
}

public struct FunDimensionScore: Identifiable, Codable, Hashable, Sendable {
    public let dimension: FunDimension
    public let score: Int
    public let weight: Int
    public let metrics: [FunMetric]

    public var id: String {
        dimension.rawValue
    }

    public init(dimension: FunDimension, metrics: [FunMetric]) {
        self.dimension = dimension
        self.metrics = metrics
        weight = dimension.weight
        if metrics.isEmpty {
            score = 0
        } else {
            let total = metrics.reduce(0) { $0 + $1.score }
            score = Int((Double(total) / Double(metrics.count)).rounded())
        }
    }

    public var weightedContribution: Double {
        Double(score * weight) / 100.0
    }
}

enum FunMetricScoring {
    static func countScore(
        _ count: Int,
        target: Int,
        floor: Int = 55,
        cap: Int = 100
    ) -> Int {
        guard target > 0 else {
            return cap
        }
        let ratio = min(1.0, Double(count) / Double(target))
        return bounded(Int((Double(floor) + ratio * Double(cap - floor)).rounded()))
    }

    static func booleanScore(
        _ value: Bool,
        pass: Int = 90,
        fail: Int = 45
    ) -> Int {
        value ? pass : fail
    }

    static func textSignalScore(
        text: String,
        signals: [String],
        target: Int,
        floor: Int = 55
    ) -> Int {
        let lowered = text.lowercased()
        let hits = signals.filter { lowered.contains($0.lowercased()) }.count
        return countScore(hits, target: target, floor: floor)
    }

    static func bounded(_ score: Int) -> Int {
        min(100, max(0, score))
    }

    static func penalized(_ score: Int, blockerCount: Int) -> Int {
        guard blockerCount > 0 else {
            return bounded(score)
        }
        return bounded(score - blockerCount * 12)
    }
}
