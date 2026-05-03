import DerZweiteWeltkriegCore
import Foundation

public enum NativeBoardPlayer: String, Codable, Hashable, Sendable {
    case none = "None"
    case player = "Player"
    case guderianAI = "Guderian AI"

    init(_ player: player_t) {
        switch player {
        case TE_PLAYER_ONE:
            self = .player
        case TE_PLAYER_TWO:
            self = .guderianAI
        default:
            self = .none
        }
    }
}

public enum NativeBoardPhase: String, Codable, Hashable, Sendable {
    case movement = "Movement"
    case shooting = "Shooting"
    case assault = "Assault"

    init(_ phase: phase_t) {
        switch phase {
        case TE_PHASE_SHOOTING:
            self = .shooting
        case TE_PHASE_ASSAULT:
            self = .assault
        default:
            self = .movement
        }
    }
}

public enum NativeBoardActionStatus: String, Codable, Hashable, Sendable {
    case idle = "Idle"
    case succeeded = "Succeeded"
    case blocked = "Blocked"
}

public struct NativeBoardActionMessage: Codable, Hashable, Sendable {
    public let status: NativeBoardActionStatus
    public let title: String
    public let detail: String

    public init(status: NativeBoardActionStatus, title: String, detail: String) {
        self.status = status
        self.title = title
        self.detail = detail
    }
}

public struct NativeBoardMissionSnapshot: Codable, Hashable, Sendable {
    public let name: String
    public let targetScore: Int
    public let playerScore: Int
    public let opponentScore: Int
    public let winner: NativeBoardPlayer
}

public struct NativeBoardUnitSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let owner: NativeBoardPlayer
    public let kind: String
    public let x: Double
    public let y: Double
    public let facingDegrees: Double
    public let totalWoundsRemaining: Int
    public let destroyed: Bool
    public let inCover: Bool
    public let hullDown: Bool
    public let pinned: Bool
    public let canMoveNow: Bool
    public let canShootNow: Bool
    public let canAssaultNow: Bool
    public let selected: Bool
    public let targeted: Bool
}

public struct NativeBoardZoneSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let kind: String
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double
    public let coverSave: Int
    public let blocksLineOfSight: Bool
    public let hullDown: Bool
}

public struct NativeBoardObjectiveSnapshot: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let x: Double
    public let y: Double
    public let radius: Double
    public let controller: NativeBoardPlayer
    public let playerPresence: Int
    public let opponentPresence: Int
}

public struct NativeBoardSnapshot: Codable, Hashable, Sendable {
    public let scenarioID: GuderianBattleID
    public let scenarioTitle: String
    public let turnNumber: Int
    public let activePlayer: NativeBoardPlayer
    public let phase: NativeBoardPhase
    public let mission: NativeBoardMissionSnapshot
    public let units: [NativeBoardUnitSnapshot]
    public let zones: [NativeBoardZoneSnapshot]
    public let objectives: [NativeBoardObjectiveSnapshot]
    public let logLines: [String]
    public let lastAction: NativeBoardActionMessage
    public let boardReport: NativeScenarioBoardReport
    public let deploymentReport: NativeScenarioDeploymentReport

    public var isScenarioBoardPlayable: Bool {
        boardReport.isScenarioSpecific && !units.isEmpty && !objectives.isEmpty
    }

    public var selectedUnit: NativeBoardUnitSnapshot? {
        units.first(where: \.selected)
    }

    public var selectedTarget: NativeBoardUnitSnapshot? {
        units.first(where: \.targeted)
    }
}

public final class NativeBoardSession {
    public static let cycleRange = 281...290

    public let loadout: NativeScenarioLoadout
    private let loadedGame: NativeScenarioLoadedGame
    private var selectedUnitID: Int?
    private var selectedTargetID: Int?
    private var lastAction = NativeBoardActionMessage(status: .idle, title: "Ready", detail: "Board session is ready.")

    public var handle: OpaquePointer {
        loadedGame.handle
    }

    public init?(scenario: GuderianScenario, seed: UInt32 = 1941) {
        let loadout = NativeScenarioLoader.load(scenario, seed: seed)
        guard let loadedGame = loadout.makeGame() else {
            return nil
        }
        self.loadout = loadout
        self.loadedGame = loadedGame
        selectFirstActiveUnit()
        selectNearestEnemyToSelectedUnit()
    }

    public convenience init?(battleID: GuderianBattleID, seed: UInt32 = 1941) {
        guard let scenario = GuderianCampaignCatalog.scenario(id: battleID) else {
            return nil
        }
        self.init(scenario: scenario, seed: seed)
    }

    public func snapshot() -> NativeBoardSnapshot {
        let view = game_view(handle)
        let mission = game_mission_view(handle)
        return NativeBoardSnapshot(
            scenarioID: loadout.scenario.id,
            scenarioTitle: loadout.scenario.title,
            turnNumber: Int(view.turn_number),
            activePlayer: NativeBoardPlayer(view.active_player),
            phase: NativeBoardPhase(view.phase),
            mission: NativeBoardMissionSnapshot(
                name: nativeBoardCString(mission.name),
                targetScore: Int(mission.target_score),
                playerScore: Int(mission.player_one_score),
                opponentScore: Int(mission.player_two_score),
                winner: NativeBoardPlayer(mission.winner)
            ),
            units: unitSnapshots(),
            zones: zoneSnapshots(),
            objectives: objectiveSnapshots(),
            logLines: logLines(),
            lastAction: lastAction,
            boardReport: loadedGame.boardReport,
            deploymentReport: loadedGame.deploymentReport
        )
    }

    public func selectUnit(_ id: Int) {
        selectedUnitID = id
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Unit selected", detail: unitName(id: id))
        if selectedTargetID == id {
            selectedTargetID = nil
        }
    }

    public func selectTarget(_ id: Int) {
        selectedTargetID = id
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Target selected", detail: unitName(id: id))
    }

    public func selectFirstActiveUnit() {
        selectedUnitID = (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { $0.owner == game_view(self.handle).active_player && !$0.destroyed && !$0.embarked }
            .map { Int($0.id) }
    }

    public func selectNearestEnemyToSelectedUnit() {
        guard let selected = selectedUnitView() else {
            selectedTargetID = nil
            return
        }
        selectedTargetID = (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .filter { $0.owner != selected.owner && $0.owner != TE_PLAYER_NONE && !$0.destroyed && !$0.embarked }
            .min { lhs, rhs in
                distance(from: selected, to: lhs) < distance(from: selected, to: rhs)
            }
            .map { Int($0.id) }
    }

    @discardableResult
    public func moveSelectedUnitTowardNearestObjective(maxDistance: Double = 4) -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before issuing movement.")
        }
        guard NativeBoardPhase(game_view(handle).phase) == .movement, unit.can_move_now else {
            return failAction("Movement blocked", "\(nativeBoardCString(unit.name)) cannot move in the current phase.")
        }
        guard let objective = nearestObjective(to: unit) else {
            return failAction("No objective", "The board has no scenario objective to move toward.")
        }

        let dx = Double(objective.x) - Double(unit.x)
        let dy = Double(objective.y) - Double(unit.y)
        let length = max(0.01, sqrt(dx * dx + dy * dy))
        let step = min(maxDistance, length)
        let x = clamp(Double(unit.x) + (dx / length) * step, min: 1, max: loadout.blueprint.engineBoardFrame.width - 1)
        let y = clamp(Double(unit.y) + (dy / length) * step, min: 1, max: loadout.blueprint.engineBoardFrame.height - 1)

        if game_move_unit(handle, Int32(unit.id), Float(x), Float(y)) {
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Moved", detail: "\(nativeBoardCString(unit.name)) advanced toward \(nativeBoardCString(objective.name)).")
            return true
        }
        return failFromEngine("Move blocked")
    }

    @discardableResult
    public func shootSelectedTarget() -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before shooting.")
        }
        guard let targetID = selectedTargetID else {
            return failAction("No target selected", "Select an enemy unit before shooting.")
        }
        guard NativeBoardPhase(game_view(handle).phase) == .shooting, unit.can_shoot_now else {
            return failAction("Shooting blocked", "\(nativeBoardCString(unit.name)) cannot shoot in the current phase.")
        }

        if game_shoot_unit(handle, Int32(unit.id), Int32(targetID)) {
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Fired", detail: "\(nativeBoardCString(unit.name)) fired at \(unitName(id: targetID)).")
            resolveFirstPendingChoice()
            return true
        }
        return failFromEngine("Shot blocked")
    }

    public func advancePhase() {
        game_advance_phase(handle)
        selectFirstActiveUnit()
        selectNearestEnemyToSelectedUnit()
        let view = game_view(handle)
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Phase advanced", detail: "\(NativeBoardPlayer(view.active_player).rawValue) \(NativeBoardPhase(view.phase).rawValue), turn \(Int(view.turn_number)).")
    }

    @discardableResult
    public func resolveFirstPendingChoice() -> Bool {
        let hitAllocation = game_pending_hit_allocation_view(handle)
        if hitAllocation.active {
            let result = game_choose_pending_hit_allocation(handle, 0)
            lastAction = NativeBoardActionMessage(
                status: result ? .succeeded : .blocked,
                title: result ? "Hit allocation resolved" : "Hit allocation blocked",
                detail: result ? "Applied the first legal damage allocation." : lastEngineError()
            )
            return result
        }

        let weaponChoice = game_pending_weapon_destroy_view(handle)
        if weaponChoice.active, game_pending_weapon_destroy_option_count(handle) > 0 {
            let option = game_pending_weapon_destroy_option_view(handle, 0)
            let result = game_choose_pending_weapon_destroy(handle, option.weapon_index)
            lastAction = NativeBoardActionMessage(
                status: result ? .succeeded : .blocked,
                title: result ? "Weapon damage resolved" : "Weapon damage blocked",
                detail: result ? "Applied the first legal weapon-damage option." : lastEngineError()
            )
            return result
        }

        return false
    }

    private func unitSnapshots() -> [NativeBoardUnitSnapshot] {
        (0..<Int(game_unit_count(handle))).map { index in
            let unit = game_unit_view(handle, Int32(index))
            return NativeBoardUnitSnapshot(
                id: Int(unit.id),
                name: nativeBoardCString(unit.name),
                owner: NativeBoardPlayer(unit.owner),
                kind: unitKindName(unit.kind),
                x: Double(unit.x),
                y: Double(unit.y),
                facingDegrees: Double(unit.facing_degrees),
                totalWoundsRemaining: Int(unit.total_wounds_remaining),
                destroyed: unit.destroyed,
                inCover: unit.in_cover,
                hullDown: unit.hull_down,
                pinned: unit.pinned,
                canMoveNow: unit.can_move_now,
                canShootNow: unit.can_shoot_now,
                canAssaultNow: unit.can_assault_now,
                selected: Int(unit.id) == selectedUnitID,
                targeted: Int(unit.id) == selectedTargetID
            )
        }
    }

    private func zoneSnapshots() -> [NativeBoardZoneSnapshot] {
        (0..<Int(game_zone_count(handle))).map { index in
            let zone = game_zone_view(handle, Int32(index))
            return NativeBoardZoneSnapshot(
                id: Int(zone.id),
                name: nativeBoardCString(zone.name),
                kind: terrainKindName(zone.kind),
                x: Double(zone.rect.x),
                y: Double(zone.rect.y),
                width: Double(zone.rect.width),
                height: Double(zone.rect.height),
                coverSave: Int(zone.cover_save),
                blocksLineOfSight: zone.blocks_line_of_sight,
                hullDown: zone.hull_down
            )
        }
    }

    private func objectiveSnapshots() -> [NativeBoardObjectiveSnapshot] {
        (0..<Int(game_objective_count(handle))).map { index in
            let objective = game_objective_view(handle, Int32(index))
            return NativeBoardObjectiveSnapshot(
                id: Int(objective.id),
                name: nativeBoardCString(objective.name),
                x: Double(objective.x),
                y: Double(objective.y),
                radius: Double(objective.radius),
                controller: NativeBoardPlayer(objective.controller),
                playerPresence: Int(objective.player_one_presence),
                opponentPresence: Int(objective.player_two_presence)
            )
        }
    }

    private func logLines() -> [String] {
        (0..<Int(game_log_count(handle))).map { index in
            nativeBoardCString(game_log_line(handle, Int32(index)))
        }
    }

    private func selectedUnitView() -> unit_view_t? {
        guard let selectedUnitID else {
            return nil
        }
        return (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { Int($0.id) == selectedUnitID }
    }

    private func nearestObjective(to unit: unit_view_t) -> objective_view_t? {
        (0..<Int(game_objective_count(handle))).lazy
            .map { game_objective_view(self.handle, Int32($0)) }
            .min { lhs, rhs in
                distance(from: unit, to: lhs) < distance(from: unit, to: rhs)
            }
    }

    private func unitName(id: Int) -> String {
        (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { Int($0.id) == id }
            .map { nativeBoardCString($0.name) } ?? "Unit \(id)"
    }

    private func failFromEngine(_ title: String) -> Bool {
        failAction(title, lastEngineError())
    }

    private func failAction(_ title: String, _ detail: String) -> Bool {
        lastAction = NativeBoardActionMessage(status: .blocked, title: title, detail: detail)
        return false
    }

    private func lastEngineError() -> String {
        let error = nativeBoardCString(game_last_error(handle))
        return error.isEmpty ? "The engine rejected the action." : error
    }

    private func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.min(Swift.max(value, minimum), maximum)
    }
}

private func distance(from unit: unit_view_t, to objective: objective_view_t) -> Double {
    let dx = Double(unit.x) - Double(objective.x)
    let dy = Double(unit.y) - Double(objective.y)
    return sqrt(dx * dx + dy * dy)
}

private func distance(from lhs: unit_view_t, to rhs: unit_view_t) -> Double {
    let dx = Double(lhs.x) - Double(rhs.x)
    let dy = Double(lhs.y) - Double(rhs.y)
    return sqrt(dx * dx + dy * dy)
}

private func nativeBoardCString(_ pointer: UnsafePointer<CChar>?) -> String {
    guard let pointer else {
        return ""
    }
    return String(cString: pointer)
}

private func unitKindName(_ kind: unit_kind_t) -> String {
    switch kind {
    case TE_UNIT_VEHICLE:
        return "Vehicle"
    case TE_UNIT_ASSAULT_GUN:
        return "Assault gun"
    default:
        return "Infantry"
    }
}

private func terrainKindName(_ kind: terrain_kind_t) -> String {
    switch kind {
    case TE_TERRAIN_DIFFICULT:
        return "Difficult"
    case TE_TERRAIN_IMPASSABLE:
        return "Impassable"
    default:
        return "Open"
    }
}
