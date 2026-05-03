import Foundation

public enum GermanAIActionKind: String, Codable, Hashable, Sendable {
    case movement = "Movement"
    case artillery = "Artillery"
    case shooting = "Shooting"
    case assault = "Assault"
    case reinforcement = "Reinforcement"
}

public struct GermanAIOrder: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let turnWindow: String
    public let kind: GermanAIActionKind
    public let target: String
    public let instruction: String

    public init(id: String, turnWindow: String, kind: GermanAIActionKind, target: String, instruction: String) {
        self.id = id
        self.turnWindow = turnWindow
        self.kind = kind
        self.target = target
        self.instruction = instruction
    }
}

public struct GermanAIPlan: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let postureName: String
    public let strategicGoal: String
    public let targetPriorities: [String]
    public let orders: [GermanAIOrder]

    public init(
        id: GuderianBattleID,
        postureName: String,
        strategicGoal: String,
        targetPriorities: [String],
        orders: [GermanAIOrder]
    ) {
        self.id = id
        self.postureName = postureName
        self.strategicGoal = strategicGoal
        self.targetPriorities = targetPriorities
        self.orders = orders
    }
}

public enum GermanAIPlanCatalog {
    public static func plan(for scenario: GuderianScenario) -> GermanAIPlan {
        switch scenario.id {
        case .tucholaForest:
            return GermanAIPlan(
                id: .tucholaForest,
                postureName: "Corridor pincer breakthrough",
                strategicGoal: "Force the Brda crossings, clear the Chojnice-Tuchola road net, and trap Polish formations before they can withdraw toward Bydgoszcz.",
                targetPriorities: ["Pruszcz bridge", "Pila-Mlyn bridge", "Chojnice", "Tuchola", "Bydgoszcz withdrawal"],
                orders: [
                    order("tuchola-border-contact", "Turn 1", .movement, "Chojnice and Brda approaches", "Push reconnaissance and panzer elements to contact without bypassing active Polish anti-tank lanes."),
                    order("tuchola-bridge-repair", "Turns 2-3", .reinforcement, "Pruszcz and Pila-Mlyn bridges", "Commit engineers to reopen demolished or blocked crossings."),
                    order("tuchola-road-hubs", "Turns 2-4", .shooting, "Chojnice-Tuchola road net", "Use motorized infantry to fix Polish strongpoints before armor attempts a deep move."),
                    order("tuchola-pincer", "Turns 3-5", .movement, "East Prussia pincer marker", "Apply northern/eastern pressure once the Brda bridgehead exists."),
                    order("tuchola-encirclement", "Turns 5+", .assault, "Bydgoszcz withdrawal", "Attack withdrawal lanes and isolated Polish groups after the pincer alarm triggers."),
                ]
            )
        case .wizna:
            return GermanAIPlan(
                id: .wizna,
                postureName: "Deliberate bunker reduction",
                strategicGoal: "Fix Polish bunkers with artillery, force the road approach, and assault isolated strongpoints.",
                targetPriorities: ["Gora Strekowa HQ", "Gelczyn bunker", "Kurpiki bunker", "anti-tank guns"],
                orders: [
                    order("wizna-bombard", "Turns 1-2", .artillery, "Bunker belt", "Pin fortified positions before armor moves into anti-tank range."),
                    order("wizna-road", "Turns 2-3", .movement, "Narew approach road", "Advance armor along road cover while infantry screens bunker arcs."),
                    order("wizna-assault", "Turns 4+", .assault, "Isolated bunkers", "Assault the weakest strongpoint after artillery and machine-gun suppression."),
                ]
            )
        case .sedan:
            return GermanAIPlan(
                id: .sedan,
                postureName: "Forced river crossing",
                strategicGoal: "Suppress French artillery, push engineers to the Meuse, then expand the bridgehead along the Sedan road.",
                targetPriorities: ["French artillery positions", "Gaulier bridge site", "Wadelincourt bridge site", "Bridgehead perimeter"],
                orders: [
                    order("sedan-air", "Turn 1", .artillery, "French artillery positions", "Use air-pressure event as suppression before the crossing."),
                    order("sedan-engineers", "Turns 1-2", .movement, "Meuse bridge sites", "Move engineers and infantry to crossing points while panzers wait for bridgehead space."),
                    order("sedan-bridgehead", "Turns 3-4", .reinforcement, "Bridgehead perimeter", "Release panzer follow-up after an infantry foothold is established."),
                    order("sedan-breakout", "Turns 5+", .assault, "Sedan-Gaulier road", "Exploit east along the road if French artillery is neutralized."),
                ]
            )
        case .moscowTulaKashira:
            return GermanAIPlan(
                id: .moscowTulaKashira,
                postureName: "Exhausted winter thrust",
                strategicGoal: "Push along the road net while supply strain slowly reduces German freedom of action.",
                targetPriorities: ["Tula", "Kashira road", "Soviet artillery", "winter supply routes"],
                orders: [
                    order("moscow-road", "Turns 1-2", .movement, "Orel-Tula road", "Keep armor on roads to reduce winter penalties."),
                    order("moscow-pressure", "Turns 3-4", .shooting, "Tula defensive belt", "Suppress city defenders before committing assault troops."),
                    order("moscow-exhaustion", "Turns 5+", .reinforcement, "German supply strain", "Throttle reinforcements and force the player to time counterattacks."),
                ]
            )
        default:
            return GermanAIPlan(
                id: scenario.id,
                postureName: "Scenario pressure plan",
                strategicGoal: "Advance on the primary player objective while preserving mobile formations.",
                targetPriorities: scenario.objectives.map(\.name),
                orders: [
                    order("\(scenario.id.rawValue)-advance", "Opening", .movement, scenario.objectives.first?.name ?? scenario.title, "Move toward the highest-value objective."),
                    order("\(scenario.id.rawValue)-fire", "Midgame", .shooting, scenario.playerForceSummary, "Suppress the player force before assaulting or bypassing."),
                ]
            )
        }
    }
}

private func order(
    _ id: String,
    _ turnWindow: String,
    _ kind: GermanAIActionKind,
    _ target: String,
    _ instruction: String
) -> GermanAIOrder {
    GermanAIOrder(id: id, turnWindow: turnWindow, kind: kind, target: target, instruction: instruction)
}
