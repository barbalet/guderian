import Foundation

public enum NativePlayabilityStatus: String, Codable, Hashable, Sendable {
    case architectureReady = "Architecture ready"
    case nativeInstanceMissing = "Native instance missing"
    case nativeLoaderMissing = "Native loader missing"
    case nativeBoardHookMissing = "Native board hook missing"
    case nativeBoardShellReady = "Native board shell ready"
    case nativePlayable = "Native playable"
}

public enum NativePlayabilityOwner: String, Codable, Hashable, Sendable {
    case dzwEngine = "DerZweiteWeltkrieg engine"
    case guderianCore = "GuderianCore"
    case guderianApp = "Guderian app"
    case guderianTest = "GuderianTest"
}

public struct NativeEngineBoundaryItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let owner: NativePlayabilityOwner
    public let responsibility: String

    public init(id: String, title: String, owner: NativePlayabilityOwner, responsibility: String) {
        self.id = id
        self.title = title
        self.owner = owner
        self.responsibility = responsibility
    }
}

public struct NativeEngineHookPlan: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let guardMacro: String
    public let owner: NativePlayabilityOwner
    public let reason: String
    public let firstNeededCycles: ClosedRange<Int>

    public init(
        id: String,
        title: String,
        guardMacro: String,
        owner: NativePlayabilityOwner,
        reason: String,
        firstNeededCycles: ClosedRange<Int>
    ) {
        self.id = id
        self.title = title
        self.guardMacro = guardMacro
        self.owner = owner
        self.reason = reason
        self.firstNeededCycles = firstNeededCycles
    }
}

public struct NativePlayabilityArchitecturePlan: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let demoPlayableTargetCycle: Int
    public let fullCampaignPlayableTargetCycle: Int
    public let guardMacro: String
    public let reusedEngineSystems: [NativeEngineBoundaryItem]
    public let guderianOwnedSystems: [NativeEngineBoundaryItem]
    public let requiredEngineHooks: [NativeEngineHookPlan]

    public init(
        cycleRange: ClosedRange<Int>,
        demoPlayableTargetCycle: Int,
        fullCampaignPlayableTargetCycle: Int,
        guardMacro: String,
        reusedEngineSystems: [NativeEngineBoundaryItem],
        guderianOwnedSystems: [NativeEngineBoundaryItem],
        requiredEngineHooks: [NativeEngineHookPlan]
    ) {
        self.cycleRange = cycleRange
        self.demoPlayableTargetCycle = demoPlayableTargetCycle
        self.fullCampaignPlayableTargetCycle = fullCampaignPlayableTargetCycle
        self.guardMacro = guardMacro
        self.reusedEngineSystems = reusedEngineSystems
        self.guderianOwnedSystems = guderianOwnedSystems
        self.requiredEngineHooks = requiredEngineHooks
    }

    public var dzwEditsRequiredDuringArchitectureCycle: Bool {
        false
    }
}

public struct NativeBattleReadinessReport: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let status: NativePlayabilityStatus
    public let authoredUnitCount: Int
    public let authoredObjectiveCount: Int
    public let authoredTerrainElementCount: Int
    public let deploymentZoneCount: Int
    public let requiredHookIDs: [String]
    public let notes: [String]

    public init(
        id: GuderianBattleID,
        title: String,
        status: NativePlayabilityStatus,
        authoredUnitCount: Int,
        authoredObjectiveCount: Int,
        authoredTerrainElementCount: Int,
        deploymentZoneCount: Int,
        requiredHookIDs: [String],
        notes: [String]
    ) {
        self.id = id
        self.title = title
        self.status = status
        self.authoredUnitCount = authoredUnitCount
        self.authoredObjectiveCount = authoredObjectiveCount
        self.authoredTerrainElementCount = authoredTerrainElementCount
        self.deploymentZoneCount = deploymentZoneCount
        self.requiredHookIDs = requiredHookIDs
        self.notes = notes
    }

    public var hasMinimumAuthoredInputs: Bool {
        authoredUnitCount > 0 &&
            authoredObjectiveCount > 0 &&
            authoredTerrainElementCount > 0 &&
            deploymentZoneCount >= 2
    }

    public var summary: String {
        "\(authoredUnitCount) units, \(authoredObjectiveCount) objectives, \(authoredTerrainElementCount) terrain elements, \(deploymentZoneCount) deployment zones."
    }
}

public enum NativePlayabilityArchitectureCatalog {
    public static let guardMacro = "HEINZ_GUDERIAN_GAME"

    public static let architecture = NativePlayabilityArchitecturePlan(
        cycleRange: 251...260,
        demoPlayableTargetCycle: 300,
        fullCampaignPlayableTargetCycle: 400,
        guardMacro: guardMacro,
        reusedEngineSystems: [
            boundary("turn-phases", "Turn phases", .dzwEngine, "Reuse movement, shooting, assault, turn advancement, and active-player state."),
            boundary("movement-rules", "Movement rules", .dzwEngine, "Reuse legal movement, footprint spacing, terrain collision, transports, and smoke interactions."),
            boundary("combat-rules", "Combat rules", .dzwEngine, "Reuse shooting, mounted fire arcs, artillery, vehicle damage, morale, pinning, assaults, and pending choices."),
            boundary("objective-scoring", "Objective scoring", .dzwEngine, "Reuse objective control and VP accumulation where scenario victory logic maps cleanly to the engine."),
            boundary("snapshots", "Board snapshots", .dzwEngine, "Reuse C snapshot views as the board-state source for SwiftUI and automation."),
        ],
        guderianOwnedSystems: [
            boundary("scenario-instance-data", "Scenario instance data", .guderianCore, "Own battle-specific unit lists, deployment, terrain, objectives, scripted events, reinforcements, and victory bands."),
            boundary("historical-campaign-flow", "Campaign flow", .guderianCore, "Own chronology, unlocks, completion records, source notes, and debrief mapping."),
            boundary("battle-board-ui", "Battle board UI", .guderianApp, "Own the Guderian campaign board shell, scenario briefing/debrief, and player-facing diagnostics."),
            boundary("campaign-automation", "Campaign automation", .guderianTest, "Own full-campaign automated playthrough checks that surface blocked phases and impossible board states."),
        ],
        requiredEngineHooks: [
            hook("scenario-instance-loader", "Scenario-defined game creation", "Create a game from Guderian-owned units, zones, objectives, deployment, mission target, and seed rather than inherited force presets.", 271...280),
            hook("scenario-mission-state", "Scenario mission state", "Expose mission target, score channels, winner, and debrief-relevant state for Guderian victory bands.", 271...300),
            hook("scenario-event-triggers", "Scenario event triggers", "Allow reinforcements, weather, supply, demolition, evacuation, pocket, and air-pressure events to alter legal board state.", 291...380),
            hook("scenario-ai-controls", "Scenario AI controls", "Let Guderian AI select priorities from scenario-authored objectives, exit lanes, supply targets, and fallback behaviors.", 291...380),
        ]
    )

    public static func readiness(for scenario: GuderianScenario) -> NativeBattleReadinessReport {
        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        let terrainCount = bundle.mapLayout.elements.filter { element in
            switch element.kind {
            case .road, .river, .town, .forest, .ridge, .bunker, .fortifiedLine, .bridge, .artillery, .airPressure:
                return true
            case .objective, .deployment:
                return false
            }
        }.count

        let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(80_000 + scenario.order))
        let requiredHookIDs = architecture.requiredEngineHooks
            .filter { hook in
                if loadout.canApplyScenarioBoardHook {
                    return hook.id != "scenario-instance-loader"
                }
                return true
            }
            .map(\.id)
        var notes = [
            loadout.canApplyScenarioBoardHook
                ? "Native loader creates an army-list skirmish bridge, applies scenario-specific terrain/objectives/mission target through the guarded dzw board hook, and deploys units from the Guderian blueprint."
                : loadout.canCreateSkirmishBridge
                ? "Native loader creates an army-list skirmish bridge and deploys units from the Guderian blueprint."
                : "Authored scenario data is present but the native loader cannot create a skirmish bridge.",
            "Remaining native work is board-flow polish, debrief mission state, scripted events, reinforcements, and scenario AI controls.",
        ]
        if scenario.isDemoScenario {
            notes.append("Demo parity target: cycle \(architecture.demoPlayableTargetCycle).")
        }

        let status: NativePlayabilityStatus
        if loadout.canApplyScenarioBoardHook {
            status = .nativeBoardShellReady
        } else if loadout.canCreateSkirmishBridge {
            status = .nativeBoardHookMissing
        } else {
            status = .nativeLoaderMissing
        }

        return NativeBattleReadinessReport(
            id: scenario.id,
            title: scenario.title,
            status: status,
            authoredUnitCount: bundle.setup.units.count,
            authoredObjectiveCount: scenario.objectives.count,
            authoredTerrainElementCount: terrainCount,
            deploymentZoneCount: bundle.mapLayout.deploymentZones.count,
            requiredHookIDs: requiredHookIDs,
            notes: notes
        )
    }

    public static var allReadinessReports: [NativeBattleReadinessReport] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(readiness)
    }

    private static func boundary(
        _ id: String,
        _ title: String,
        _ owner: NativePlayabilityOwner,
        _ responsibility: String
    ) -> NativeEngineBoundaryItem {
        NativeEngineBoundaryItem(id: id, title: title, owner: owner, responsibility: responsibility)
    }

    private static func hook(
        _ id: String,
        _ title: String,
        _ reason: String,
        _ cycles: ClosedRange<Int>
    ) -> NativeEngineHookPlan {
        NativeEngineHookPlan(
            id: id,
            title: title,
            guardMacro: guardMacro,
            owner: .dzwEngine,
            reason: reason,
            firstNeededCycles: cycles
        )
    }
}
