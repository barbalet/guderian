import Foundation

public enum FunTelemetryObservationKind: String, Codable, Hashable, Sendable {
    case playtestNote = "Playtest note"
    case blockedAction = "Blocked action"
    case debriefReaction = "Debrief reaction"
    case replayIntent = "Replay intent"
    case confusion = "Confusion"
    case delight = "Delight"
}

public struct FunTelemetryObservation: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let scenarioID: String
    public let kind: FunTelemetryObservationKind
    public let dimension: FunDimension
    public let scoreDelta: Int
    public let note: String

    public init(
        id: String,
        scenarioID: String,
        kind: FunTelemetryObservationKind,
        dimension: FunDimension,
        scoreDelta: Int,
        note: String
    ) {
        self.id = id
        self.scenarioID = scenarioID
        self.kind = kind
        self.dimension = dimension
        self.scoreDelta = min(20, max(-20, scoreDelta))
        self.note = note
    }
}

public struct FunTelemetrySchema: Codable, Hashable, Sendable {
    public let version: Int
    public let observations: [FunTelemetryObservation]

    public init(version: Int = 1, observations: [FunTelemetryObservation] = []) {
        self.version = version
        self.observations = observations
    }
}
