import Foundation

public enum FunDimension: String, CaseIterable, Codable, Hashable, Sendable {
    case clarity = "Clarity"
    case agency = "Agency"
    case challenge = "Challenge"
    case mastery = "Mastery"
    case novelty = "Novelty"
    case consequence = "Consequence"
    case pacing = "Pacing"
    case ethicalFrame = "Ethical Frame"

    public var weight: Int {
        switch self {
        case .clarity, .agency, .challenge, .mastery:
            return 15
        case .novelty, .consequence, .pacing, .ethicalFrame:
            return 10
        }
    }

    public var documentationAnchor: String {
        switch self {
        case .clarity:
            return "Clear Goals / Immediate And Useful Feedback / Readable Battlefield State"
        case .agency:
            return "Meaningful Autonomy"
        case .challenge:
            return "Challenge-Skill Balance"
        case .mastery:
            return "Competence And Mastery"
        case .novelty:
            return "Novelty And Discovery"
        case .consequence:
            return "Fair Consequence / Replayability"
        case .pacing:
            return "Pacing And Rhythm"
        case .ethicalFrame:
            return "Ethical Historical Framing"
        }
    }
}

public enum FunAcceptanceStatus: String, Codable, Hashable, Sendable {
    case pass = "Pass"
    case warning = "Warning"
    case blocker = "Blocker"
}

public struct FunThresholds: Codable, Hashable, Sendable {
    public let acceptableOverallScore: Int
    public let minimumDimensionScore: Int
    public let ethicalFrameBlockerScore: Int

    public init(
        acceptableOverallScore: Int = 75,
        minimumDimensionScore: Int = 60,
        ethicalFrameBlockerScore: Int = 60
    ) {
        self.acceptableOverallScore = acceptableOverallScore
        self.minimumDimensionScore = minimumDimensionScore
        self.ethicalFrameBlockerScore = ethicalFrameBlockerScore
    }

    public static let guderianDefault = FunThresholds()
}

public struct FunAcceptanceGate: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let dimension: FunDimension?
    public let status: FunAcceptanceStatus
    public let title: String
    public let detail: String

    public init(
        id: String,
        dimension: FunDimension?,
        status: FunAcceptanceStatus,
        title: String,
        detail: String
    ) {
        self.id = id
        self.dimension = dimension
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public enum FunScoreFormatter {
    public static func percent(_ score: Double) -> String {
        String(format: "%.1f", score)
    }
}
