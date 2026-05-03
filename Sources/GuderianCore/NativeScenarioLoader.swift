import DerZweiteWeltkriegCore
import Foundation

public enum NativeScenarioGameCreationMode: String, Codable, Hashable, Sendable {
    case nativeBlueprintSkirmishBridge = "Native blueprint skirmish bridge"
}

public struct NativeScenarioArmyListSelection: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let catalogID: Int
    public let count: Int
    public let catalogName: String
    public let roleHints: [String]

    public init(id: String, catalogID: Int, count: Int, catalogName: String, roleHints: [String]) {
        self.id = id
        self.catalogID = catalogID
        self.count = count
        self.catalogName = catalogName
        self.roleHints = roleHints
    }
}

public struct NativeScenarioLoaderWarning: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let detail: String

    public init(id: String, title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

public struct NativeScenarioDeploymentReport: Codable, Hashable, Sendable {
    public let attempted: Int
    public let succeeded: Int
    public let skipped: Int
    public let notes: [String]

    public init(attempted: Int, succeeded: Int, skipped: Int, notes: [String]) {
        self.attempted = attempted
        self.succeeded = succeeded
        self.skipped = skipped
        self.notes = notes
    }

    public var placedAnyScenarioUnit: Bool {
        succeeded > 0
    }
}

public final class NativeScenarioLoadedGame {
    public let handle: OpaquePointer
    public let deploymentReport: NativeScenarioDeploymentReport

    public init(handle: OpaquePointer, deploymentReport: NativeScenarioDeploymentReport) {
        self.handle = handle
        self.deploymentReport = deploymentReport
    }

    deinit {
        game_destroy(handle)
    }
}

public struct NativeScenarioLoadout {
    public let scenario: GuderianScenario
    public let seed: UInt32
    public let instance: NativeBattleInstance
    public let blueprint: NativeEngineBattleBlueprint
    public let playerArmy: army_list_t
    public let opponentArmy: army_list_t
    public let playerEntries: [NativeScenarioArmyListSelection]
    public let opponentEntries: [NativeScenarioArmyListSelection]
    public let warnings: [NativeScenarioLoaderWarning]
    public let gameCreationMode: NativeScenarioGameCreationMode

    public var playerArmyName: String {
        armyName(playerArmy)
    }

    public var opponentArmyName: String {
        armyName(opponentArmy)
    }

    public var usesForcePresetProxy: Bool {
        false
    }

    public var canCreateSkirmishBridge: Bool {
        blueprint.isCompleteForScenarioLoader && !playerEntries.isEmpty && !opponentEntries.isEmpty
    }

    public func makeGame() -> NativeScenarioLoadedGame? {
        let playerCEntries = playerEntries.map { army_list_entry_t(catalog_id: Int32($0.catalogID), count: Int32($0.count)) }
        let opponentCEntries = opponentEntries.map { army_list_entry_t(catalog_id: Int32($0.catalogID), count: Int32($0.count)) }

        let game = playerCEntries.withUnsafeBufferPointer { playerBuffer in
            opponentCEntries.withUnsafeBufferPointer { opponentBuffer in
                game_create_skirmish(
                    seed,
                    playerArmy,
                    playerBuffer.baseAddress,
                    Int32(playerBuffer.count),
                    opponentArmy,
                    opponentBuffer.baseAddress,
                    Int32(opponentBuffer.count)
                )
            }
        }
        guard let game else {
            return nil
        }

        let report = deployBlueprintUnits(in: game)
        return NativeScenarioLoadedGame(handle: game, deploymentReport: report)
    }

    private func deployBlueprintUnits(in game: OpaquePointer) -> NativeScenarioDeploymentReport {
        let playerIDs = engineUnitIDs(in: game, owner: TE_PLAYER_ONE)
        let opponentIDs = engineUnitIDs(in: game, owner: TE_PLAYER_TWO)
        let playerSpawns = blueprint.units.filter { $0.side == .player }
        let opponentSpawns = blueprint.units.filter { $0.side == .guderianAI }

        var attempted = 0
        var succeeded = 0
        var notes: [String] = []
        let playerResult = deploy(playerSpawns, onto: playerIDs, in: game)
        attempted += playerResult.attempted
        succeeded += playerResult.succeeded
        notes.append(contentsOf: playerResult.notes)

        let opponentResult = deploy(opponentSpawns, onto: opponentIDs, in: game)
        attempted += opponentResult.attempted
        succeeded += opponentResult.succeeded
        notes.append(contentsOf: opponentResult.notes)

        let skipped = max(0, playerSpawns.count + opponentSpawns.count - attempted)
        if skipped > 0 {
            notes.append("\(skipped) native unit blueprints did not have matching skirmish-roster slots after catalog caps were applied.")
        }
        return NativeScenarioDeploymentReport(
            attempted: attempted,
            succeeded: succeeded,
            skipped: skipped,
            notes: notes
        )
    }

    private func engineUnitIDs(in game: OpaquePointer, owner: player_t) -> [Int32] {
        (0..<Int(game_unit_count(game))).compactMap { index in
            let view = game_unit_view(game, Int32(index))
            guard view.owner == owner, !view.destroyed, !view.embarked else {
                return nil
            }
            return Int32(view.id)
        }
    }

    private func deploy(
        _ spawns: [NativeEngineUnitSpawn],
        onto ids: [Int32],
        in game: OpaquePointer
    ) -> (attempted: Int, succeeded: Int, notes: [String]) {
        let count = min(spawns.count, ids.count)
        var succeeded = 0
        var notes: [String] = []
        guard count > 0 else {
            return (0, 0, [])
        }

        for index in 0..<count {
            let spawn = spawns[index]
            let unitID = ids[index]
            if deploy(unitID: unitID, near: spawn, in: game) {
                succeeded += 1
            } else {
                notes.append("Could not deploy skirmish unit \(unitID) near native spawn \(spawn.name).")
            }
        }
        return (count, succeeded, notes)
    }

    private func deploy(unitID: Int32, near spawn: NativeEngineUnitSpawn, in game: OpaquePointer) -> Bool {
        let offsets: [(Double, Double)] = [
            (0, 0), (1.5, 0), (-1.5, 0), (0, 1.5), (0, -1.5),
            (3, 0), (-3, 0), (0, 3), (0, -3),
            (3, 3), (-3, 3), (3, -3), (-3, -3),
            (5, 0), (-5, 0), (0, 5), (0, -5),
        ]

        for offset in offsets {
            let x = Float(clamp(spawn.x + offset.0, min: 2, max: blueprint.engineBoardFrame.width - 2))
            let y = Float(clamp(spawn.y + offset.1, min: 2, max: blueprint.engineBoardFrame.height - 2))
            if game_deploy_unit(game, unitID, x, y) {
                return true
            }
        }
        return false
    }

    private func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }
}

public enum NativeScenarioLoader {
    public static let cycleRange = 271...280

    public static func load(_ id: GuderianBattleID, seed: UInt32 = 1941) -> NativeScenarioLoadout? {
        guard let scenario = GuderianCampaignCatalog.scenario(id: id) else {
            return nil
        }
        return load(scenario, seed: seed)
    }

    public static func load(_ scenario: GuderianScenario, seed: UInt32 = 1941) -> NativeScenarioLoadout {
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)
        let blueprint = instance.engineBlueprint(seed: seed)
        let armies = armyMapping(for: scenario)
        let playerUnits = instance.units.filter { $0.side == .player }
        let opponentUnits = instance.units.filter { $0.side == .guderianAI }
        let playerEntries = armyListSelections(for: playerUnits, army: armies.playerArmy)
        let opponentEntries = armyListSelections(for: opponentUnits, army: armies.opponentArmy)
        let warnings = warnings(
            scenario: scenario,
            blueprint: blueprint,
            playerEntries: playerEntries,
            opponentEntries: opponentEntries
        )

        return NativeScenarioLoadout(
            scenario: scenario,
            seed: seed,
            instance: instance,
            blueprint: blueprint,
            playerArmy: armies.playerArmy,
            opponentArmy: armies.opponentArmy,
            playerEntries: playerEntries,
            opponentEntries: opponentEntries,
            warnings: warnings,
            gameCreationMode: .nativeBlueprintSkirmishBridge
        )
    }

    private static func armyListSelections(
        for units: [NativeBattleUnit],
        army: army_list_t
    ) -> [NativeScenarioArmyListSelection] {
        let options = catalogOptions(for: army)
        var counts: [Int: Int] = [:]
        var hints: [Int: Set<String>] = [:]

        for unit in units {
            guard let option = bestCatalogOption(for: unit, options: options, currentCounts: counts) else {
                continue
            }
            counts[option.catalogID, default: 0] += 1
            hints[option.catalogID, default: []].insert(unit.mobility.rawValue)
            for weapon in unit.weapons.prefix(2) {
                hints[option.catalogID, default: []].insert(weapon.role.rawValue)
            }
        }

        return counts.keys.sorted().compactMap { catalogID in
            guard let option = options.first(where: { $0.catalogID == catalogID }) else {
                return nil
            }
            return NativeScenarioArmyListSelection(
                id: "\(armyName(army))-\(catalogID)",
                catalogID: catalogID,
                count: counts[catalogID, default: 0],
                catalogName: option.name,
                roleHints: Array(hints[catalogID, default: []]).sorted()
            )
        }
    }

    private static func bestCatalogOption(
        for unit: NativeBattleUnit,
        options: [CatalogOption],
        currentCounts: [Int: Int]
    ) -> CatalogOption? {
        options
            .filter { currentCounts[$0.catalogID, default: 0] < $0.maxCount }
            .max { lhs, rhs in
                score(lhs, for: unit) < score(rhs, for: unit)
            }
    }

    private static func score(_ option: CatalogOption, for unit: NativeBattleUnit) -> Int {
        let text = "\(option.name) \(option.primaryWeaponName)".lowercased()
        var score = 1
        switch unit.mobility {
        case .armor:
            if option.kind == TE_UNIT_VEHICLE || option.kind == TE_UNIT_ASSAULT_GUN { score += 8 }
            if containsAny(text, ["tank", "sherman", "stug", "m10", "semovente", "armored", "car"]) { score += 4 }
        case .gun, .artillery:
            if containsAny(text, ["mortar", "mg", "piat", "anti", "gun", "battery", "destroyer"]) { score += 7 }
        case .engineer:
            if containsAny(text, ["engineer", "pioneer", "sapper", "flamethrower"]) { score += 8 }
        case .command:
            if containsAny(text, ["command", "hq", "officer", "observer"]) { score += 8 }
        case .cavalry:
            if option.kind == TE_UNIT_INFANTRY { score += 4 }
            if containsAny(text, ["recon", "scout", "dingo", "jeep"]) { score += 5 }
        case .airPressure, .navalSupport:
            if containsAny(text, ["mortar", "battery", "observer", "command"]) { score += 4 }
        case .armoredTrain:
            if option.kind == TE_UNIT_VEHICLE || option.kind == TE_UNIT_ASSAULT_GUN { score += 5 }
            if containsAny(text, ["gun", "tank", "transport"]) { score += 3 }
        case .infantry:
            if option.kind == TE_UNIT_INFANTRY { score += 6 }
        }

        for weapon in unit.weapons {
            switch weapon.role {
            case .antiTank:
                if containsAny(text, ["anti", "piat", "tank", "destroyer", "gun"]) { score += 3 }
            case .armorGun:
                if option.kind == TE_UNIT_VEHICLE || option.kind == TE_UNIT_ASSAULT_GUN { score += 3 }
            case .artillery:
                if containsAny(text, ["mortar", "battery", "gun"]) { score += 3 }
            case .demolition:
                if containsAny(text, ["engineer", "pioneer", "sapper", "flamethrower"]) { score += 3 }
            case .command:
                if containsAny(text, ["command", "hq", "observer"]) { score += 3 }
            case .reconnaissance:
                if containsAny(text, ["recon", "scout", "dingo", "jeep"]) { score += 3 }
            case .machineGun:
                if containsAny(text, ["mg", "machine"]) { score += 3 }
            case .airSupport, .navalSupport, .smallArms:
                break
            }
        }
        return score
    }

    private static func catalogOptions(for army: army_list_t) -> [CatalogOption] {
        (0..<Int(army_catalog_unit_count(army))).map { index in
            let view = army_catalog_unit_view(army, Int32(index))
            return CatalogOption(
                catalogID: index,
                name: cString(view.name),
                primaryWeaponName: cString(view.unit.primary_weapon_name),
                kind: view.unit.kind,
                maxCount: max(1, Int(view.max_count))
            )
        }
    }

    private static func warnings(
        scenario: GuderianScenario,
        blueprint: NativeEngineBattleBlueprint,
        playerEntries: [NativeScenarioArmyListSelection],
        opponentEntries: [NativeScenarioArmyListSelection]
    ) -> [NativeScenarioLoaderWarning] {
        var warnings: [NativeScenarioLoaderWarning] = [
            NativeScenarioLoaderWarning(
                id: "\(scenario.id.rawValue)-board-hook",
                title: "Scenario board hook pending",
                detail: "The native loader creates skirmish rosters and deploys units from the Guderian blueprint, but the dzw C engine still needs the guarded scenario board/mission constructor for custom terrain, objectives, mission target score, and event triggers."
            )
        ]
        if !blueprint.isCompleteForScenarioLoader {
            warnings.append(
                NativeScenarioLoaderWarning(
                    id: "\(scenario.id.rawValue)-blueprint-incomplete",
                    title: "Native blueprint incomplete",
                    detail: "The engine blueprint is missing units, objectives, terrain, or mission target score."
                )
            )
        }
        if playerEntries.isEmpty || opponentEntries.isEmpty {
            warnings.append(
                NativeScenarioLoaderWarning(
                    id: "\(scenario.id.rawValue)-army-list-empty",
                    title: "Army-list bridge incomplete",
                    detail: "The loader could not map one side of the native unit roster onto the current dzw army catalog."
                )
            )
        }
        return warnings
    }

    private static func armyMapping(for scenario: GuderianScenario) -> (playerArmy: army_list_t, opponentArmy: army_list_t) {
        switch scenario.theater {
        case .easternFront1941:
            return (TE_ARMY_SOVIET, TE_ARMY_GERMAN)
        case .france1940, .poland1939:
            return (TE_ARMY_BRITISH, TE_ARMY_GERMAN)
        }
    }

    private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains { text.contains($0) }
    }

    private static func cString(_ pointer: UnsafePointer<CChar>?) -> String {
        guard let pointer else {
            return ""
        }
        return String(cString: pointer)
    }
}

private struct CatalogOption {
    let catalogID: Int
    let name: String
    let primaryWeaponName: String
    let kind: unit_kind_t
    let maxCount: Int
}
