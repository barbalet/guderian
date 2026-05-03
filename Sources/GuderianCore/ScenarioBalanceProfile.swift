import Foundation

public enum ScenarioScoringSide: String, Codable, Hashable, Sendable {
    case player = "Player"
    case guderianAI = "Guderian AI"
    case contested = "Contested"
}

public enum VictoryBand: String, Codable, Hashable, Sendable {
    case decisive = "Decisive"
    case operational = "Operational"
    case tactical = "Tactical"
    case marginal = "Marginal"
    case historicalPressure = "Historical pressure"
}

public struct ScenarioScoreChannel: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: ScenarioScoringSide
    public let victoryPoints: Int
    public let timing: String
    public let description: String

    public init(
        id: String,
        name: String,
        side: ScenarioScoringSide,
        victoryPoints: Int,
        timing: String,
        description: String
    ) {
        self.id = id
        self.name = name
        self.side = side
        self.victoryPoints = victoryPoints
        self.timing = timing
        self.description = description
    }
}

public struct ScenarioPacingRule: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let turnWindow: String
    public let effect: String

    public init(id: String, name: String, turnWindow: String, effect: String) {
        self.id = id
        self.name = name
        self.turnWindow = turnWindow
        self.effect = effect
    }
}

public struct ScenarioReinforcement: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let side: ScenarioUnitSide
    public let turnWindow: String
    public let unitName: String
    public let entryCondition: String
    public let role: String

    public init(
        id: String,
        side: ScenarioUnitSide,
        turnWindow: String,
        unitName: String,
        entryCondition: String,
        role: String
    ) {
        self.id = id
        self.side = side
        self.turnWindow = turnWindow
        self.unitName = unitName
        self.entryCondition = entryCondition
        self.role = role
    }
}

public struct ScenarioOutcomeBand: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let grade: VictoryBand
    public let scoreRange: ClosedRange<Int>
    public let summary: String

    public init(id: String, grade: VictoryBand, scoreRange: ClosedRange<Int>, summary: String) {
        self.id = id
        self.grade = grade
        self.scoreRange = scoreRange
        self.summary = summary
    }
}

public struct ScenarioBalanceProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let targetTurns: ClosedRange<Int>
    public let balanceIntent: String
    public let playerWinCondition: String
    public let germanPressureLimit: String
    public let scoreChannels: [ScenarioScoreChannel]
    public let pacingRules: [ScenarioPacingRule]
    public let reinforcements: [ScenarioReinforcement]
    public let outcomeBands: [ScenarioOutcomeBand]

    public init(
        id: GuderianBattleID,
        targetTurns: ClosedRange<Int>,
        balanceIntent: String,
        playerWinCondition: String,
        germanPressureLimit: String,
        scoreChannels: [ScenarioScoreChannel],
        pacingRules: [ScenarioPacingRule],
        reinforcements: [ScenarioReinforcement],
        outcomeBands: [ScenarioOutcomeBand]
    ) {
        self.id = id
        self.targetTurns = targetTurns
        self.balanceIntent = balanceIntent
        self.playerWinCondition = playerWinCondition
        self.germanPressureLimit = germanPressureLimit
        self.scoreChannels = scoreChannels
        self.pacingRules = pacingRules
        self.reinforcements = reinforcements
        self.outcomeBands = outcomeBands
    }

    public var maxPlayerScore: Int {
        scoreChannels
            .filter { $0.side == .player || $0.side == .contested }
            .map(\.victoryPoints)
            .reduce(0, +)
    }
}

public enum ScenarioBalanceCatalog {
    public static func profile(for scenario: GuderianScenario) -> ScenarioBalanceProfile {
        switch scenario.id {
        case .wizna:
            return wizna
        case .sedan:
            return sedan
        case .moscowTulaKashira:
            return moscowTulaKashira
        default:
            return generic(for: scenario)
        }
    }

    private static let wizna = ScenarioBalanceProfile(
        id: .wizna,
        targetTurns: 5...7,
        balanceIntent: "Teach fortified delay by letting the player score meaningful success even as the line is eventually overwhelmed.",
        playerWinCondition: "Hold at least two bunker objectives through turn 5 or preserve the command post after the final German assault.",
        germanPressureLimit: "German artillery can pin but should not remove a full bunker before the player has acted twice.",
        scoreChannels: [
            score("wizna-bunker-turns", "Bunker turns held", .player, 5, "End of each player turn", "One point per turn with two or more bunker objectives still controlled."),
            score("wizna-at-survival", "Anti-tank gun survival", .player, 2, "Scenario end", "Award if at least one anti-tank asset remains operational."),
            score("wizna-command-post", "Command post stand", .player, 3, "Scenario end", "Award if Gora Strekowa HQ is controlled or contested."),
            score("wizna-german-breakthrough", "German breakthrough", .guderianAI, 5, "Scenario end", "German pressure score for clearing the road and reducing the bunker belt."),
        ],
        pacingRules: [
            pacing("wizna-no-alpha", "No opening wipeout", "Turn 1", "Limit German fire to suppression/pinning before armor has moved."),
            pacing("wizna-escalation", "Escalating pressure", "Turns 3-5", "Allow assaults only after artillery or machine-gun pressure has marked the bunker as isolated."),
        ],
        reinforcements: [
            reinforcement("wizna-pioneers", .guderianAI, "Turn 3", "German assault pioneers", "Enter if at least one bunker is pinned.", "Bunker assault"),
        ],
        outcomeBands: [
            outcome("wizna-decisive", .decisive, 8...10, "The fortified line delays the assault far beyond expectations."),
            outcome("wizna-operational", .operational, 5...7, "The defenders buy useful time despite heavy losses."),
            outcome("wizna-historical", .historicalPressure, 0...4, "The line falls quickly under overwhelming pressure."),
        ]
    )

    private static let sedan = ScenarioBalanceProfile(
        id: .sedan,
        targetTurns: 6...8,
        balanceIntent: "Make Sedan a tense delay scenario: the German crossing should feel dangerous, but French artillery and counterattack timing must give the player agency.",
        playerWinCondition: "Deny a stable bridgehead through turn 6 or destroy enough follow-up armor that the German breakout stalls.",
        germanPressureLimit: "German air pressure suppresses artillery but cannot both neutralize all observers and release panzer follow-up before turn 3.",
        scoreChannels: [
            score("sedan-delay", "Bridgehead delay", .player, 6, "Turns 1-6", "One point for each turn the bridgehead perimeter is uncontrolled by German forces."),
            score("sedan-artillery", "Artillery control", .player, 3, "Scenario end", "Award if French observers or artillery remain active."),
            score("sedan-counterattack-damage", "Counterattack damage", .player, 4, "After reserve release", "Award for damaging engineer or panzer follow-up units."),
            score("sedan-bridge-denial", "Bridge denial", .contested, 3, "Scenario end", "Award if at least one bridge site is contested or blocked."),
            score("sedan-german-bridgehead", "Stable bridgehead", .guderianAI, 6, "Scenario end", "German score for holding bridgehead and road-exit objectives."),
        ],
        pacingRules: [
            pacing("sedan-air-cap", "Air-pressure cap", "Turn 1", "Air pressure may pin artillery or observers, not both across the whole line."),
            pacing("sedan-engineer-window", "Engineer crossing window", "Turns 2-3", "Engineers can establish a crossing only if an adjacent French defender is pinned or displaced."),
            pacing("sedan-counterattack-window", "Counterattack agency", "Turns 3-5", "French reserve counterattack enters before German armor can score the road-exit objective."),
            pacing("sedan-breakout-check", "Breakout check", "Turns 6-8", "German panzer follow-up must hold the bridgehead for one full player turn before exit scoring."),
        ],
        reinforcements: [
            reinforcement("sedan-french-reserve", .player, "Turns 3-4", "French reserve counterattack group", "Enter when the bridgehead is German-controlled or artillery control is lost.", "Counterattack damage"),
            reinforcement("sedan-panzer-followup", .guderianAI, "Turns 3-5", "German panzer follow-up", "Enter after German engineers establish and hold a crossing.", "Bridgehead exploitation"),
        ],
        outcomeBands: [
            outcome("sedan-decisive", .decisive, 12...16, "The Meuse crossing is disrupted and German breakout tempo collapses."),
            outcome("sedan-operational", .operational, 8...11, "The bridgehead forms, but the French delay and counterattack damage meaningfully slow exploitation."),
            outcome("sedan-tactical", .tactical, 4...7, "The defense inflicts losses but cannot prevent a working bridgehead."),
            outcome("sedan-historical", .historicalPressure, 0...3, "The German crossing runs close to the historical tempo."),
        ]
    )

    private static let moscowTulaKashira = ScenarioBalanceProfile(
        id: .moscowTulaKashira,
        targetTurns: 7...9,
        balanceIntent: "Turn the southern Moscow approach into an exhaustion contest where holding Tula, timing counterattacks, and forcing supply strain matter more than simply destroying every German unit.",
        playerWinCondition: "Hold Tula through turn 7 and trigger at least two German exhaustion checks before the final counteroffensive window.",
        germanPressureLimit: "German armor must choose between road speed and supply exposure; winter attrition should slow repeated assaults without stopping all attacks.",
        scoreChannels: [
            score("moscow-hold-tula", "Hold Tula", .player, 6, "Scenario end", "Award if Tula remains controlled or contested."),
            score("moscow-kashira-road", "Deny Kashira road", .player, 3, "Turns 4-8", "Award if German spearheads do not exit through the Kashira road objective."),
            score("moscow-exhaustion", "German exhaustion checks", .player, 4, "Any German turn", "Award up to four points when German units suffer supply strain or winter movement penalties."),
            score("moscow-counterattack", "Counterattack timing", .player, 3, "Turns 5-8", "Award if Soviet reserve armor damages or pins a German spearhead after it outruns infantry support."),
            score("moscow-german-breakthrough", "Southern breakthrough", .guderianAI, 7, "Scenario end", "German score for controlling Tula or exiting toward Kashira."),
        ],
        pacingRules: [
            pacing("moscow-road-speed", "Road speed temptation", "Turns 1-3", "German armor moves best on road elements but becomes vulnerable to planned ambush points."),
            pacing("moscow-supply-friction", "Supply friction", "Turns 3+", "Each German turn with spearheads beyond infantry support adds an exhaustion marker."),
            pacing("moscow-winter-attrition", "Winter attrition", "Turns 5+", "German assaults after repeated exhaustion checks suffer morale or movement pressure."),
            pacing("moscow-counteroffensive-window", "Counteroffensive window", "Turns 6-8", "Soviet reserves should arrive before German pressure collapses completely."),
        ],
        reinforcements: [
            reinforcement("moscow-soviet-armor", .player, "Turns 5-6", "Soviet reserve armor counterattack", "Enter when a German spearhead controls a road objective or has two exhaustion markers.", "Counterattack"),
            reinforcement("moscow-ski-cavalry", .player, "Turn 6", "Mobile winter reserve", "Enter if Tula remains contested.", "Flank pressure"),
            reinforcement("moscow-german-infantry", .guderianAI, "Turns 3-4", "German infantry follow-up", "Enter if panzer units hold the Orel-Tula road.", "Assault support"),
        ],
        outcomeBands: [
            outcome("moscow-decisive", .decisive, 13...16, "Tula holds, Kashira is denied, and German armor is exhausted before the counteroffensive."),
            outcome("moscow-operational", .operational, 9...12, "The Soviet defense holds the city while German pressure slows under winter and supply strain."),
            outcome("moscow-marginal", .marginal, 5...8, "The city is contested and both sides are badly worn down."),
            outcome("moscow-historical", .historicalPressure, 0...4, "German pressure reaches dangerous depth before the Soviet defense stabilizes."),
        ]
    )

    private static func generic(for scenario: GuderianScenario) -> ScenarioBalanceProfile {
        ScenarioBalanceProfile(
            id: scenario.id,
            targetTurns: 5...7,
            balanceIntent: "Placeholder balance profile until this battle receives detailed scenario tuning.",
            playerWinCondition: scenario.objectives.first?.description ?? scenario.designIntent,
            germanPressureLimit: "Prevent early no-agency collapses by keeping the first German turn focused on movement pressure.",
            scoreChannels: scenario.objectives.map {
                score("\(scenario.id.rawValue)-\($0.name)", $0.name, .player, $0.victoryPoints, "Scenario end", $0.description)
            },
            pacingRules: [
                pacing("\(scenario.id.rawValue)-opening", "Opening pressure cap", "Turn 1", "German AI starts with movement or suppression before assault resolution."),
            ],
            reinforcements: [],
            outcomeBands: [
                outcome("\(scenario.id.rawValue)-tactical", .tactical, 4...8, "The player achieves the main local scenario goal."),
                outcome("\(scenario.id.rawValue)-historical", .historicalPressure, 0...3, "The battle follows historical German pressure."),
            ]
        )
    }
}

private func score(
    _ id: String,
    _ name: String,
    _ side: ScenarioScoringSide,
    _ victoryPoints: Int,
    _ timing: String,
    _ description: String
) -> ScenarioScoreChannel {
    ScenarioScoreChannel(id: id, name: name, side: side, victoryPoints: victoryPoints, timing: timing, description: description)
}

private func pacing(_ id: String, _ name: String, _ turnWindow: String, _ effect: String) -> ScenarioPacingRule {
    ScenarioPacingRule(id: id, name: name, turnWindow: turnWindow, effect: effect)
}

private func reinforcement(
    _ id: String,
    _ side: ScenarioUnitSide,
    _ turnWindow: String,
    _ unitName: String,
    _ entryCondition: String,
    _ role: String
) -> ScenarioReinforcement {
    ScenarioReinforcement(id: id, side: side, turnWindow: turnWindow, unitName: unitName, entryCondition: entryCondition, role: role)
}

private func outcome(_ id: String, _ grade: VictoryBand, _ scoreRange: ClosedRange<Int>, _ summary: String) -> ScenarioOutcomeBand {
    ScenarioOutcomeBand(id: id, grade: grade, scoreRange: scoreRange, summary: summary)
}
