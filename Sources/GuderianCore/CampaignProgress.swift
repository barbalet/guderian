import Foundation

public struct CampaignProgress: Codable, Hashable, Sendable {
    public private(set) var completedScenarioIDs: Set<GuderianBattleID>

    public init(completedScenarioIDs: Set<GuderianBattleID> = []) {
        self.completedScenarioIDs = completedScenarioIDs
    }

    public var completedCount: Int {
        completedScenarioIDs.count
    }

    public func isCompleted(_ id: GuderianBattleID) -> Bool {
        completedScenarioIDs.contains(id)
    }

    public func isAvailable(_ scenario: GuderianScenario) -> Bool {
        scenario.isDemoScenario || scenario.order == nextLockedOrder || completedScenarioIDs.contains(scenario.id)
    }

    public mutating func markCompleted(_ id: GuderianBattleID) {
        completedScenarioIDs.insert(id)
    }

    public mutating func reset() {
        completedScenarioIDs.removeAll()
    }

    private var nextLockedOrder: Int {
        let completedOrders = GuderianCampaignCatalog.all
            .filter { completedScenarioIDs.contains($0.id) }
            .map(\.order)

        return (completedOrders.max() ?? 0) + 1
    }
}
