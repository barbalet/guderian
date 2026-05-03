import Foundation

public enum ScenarioUnitSide: String, Codable, Hashable, Sendable {
    case player = "Player"
    case guderianAI = "Guderian AI"
}

public struct ScenarioUnitCard: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: ScenarioUnitSide
    public let role: String
    public let historicalNote: String

    public init(id: String, name: String, side: ScenarioUnitSide, role: String, historicalNote: String) {
        self.id = id
        self.name = name
        self.side = side
        self.role = role
        self.historicalNote = historicalNote
    }
}

public struct ScenarioTrigger: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let condition: String
    public let effect: String

    public init(id: String, name: String, condition: String, effect: String) {
        self.id = id
        self.name = name
        self.condition = condition
        self.effect = effect
    }
}

public struct TutorialStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let instruction: String

    public init(id: String, title: String, instruction: String) {
        self.id = id
        self.title = title
        self.instruction = instruction
    }
}

public struct ScenarioSetupScript: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let playerBriefing: String
    public let guderianBriefing: String
    public let units: [ScenarioUnitCard]
    public let triggers: [ScenarioTrigger]
    public let tutorialSteps: [TutorialStep]

    public init(
        id: GuderianBattleID,
        playerBriefing: String,
        guderianBriefing: String,
        units: [ScenarioUnitCard],
        triggers: [ScenarioTrigger],
        tutorialSteps: [TutorialStep] = []
    ) {
        self.id = id
        self.playerBriefing = playerBriefing
        self.guderianBriefing = guderianBriefing
        self.units = units
        self.triggers = triggers
        self.tutorialSteps = tutorialSteps
    }

    public var playerUnits: [ScenarioUnitCard] {
        units.filter { $0.side == .player }
    }

    public var guderianUnits: [ScenarioUnitCard] {
        units.filter { $0.side == .guderianAI }
    }
}

public enum ScenarioSetupCatalog {
    public static func setup(for scenario: GuderianScenario) -> ScenarioSetupScript {
        switch scenario.id {
        case .tucholaForest:
            return tucholaForest
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

    private static let tucholaForest = ScenarioSetupScript(
        id: .tucholaForest,
        playerBriefing: "Delay XIX Panzer Corps at the Brda crossings and forest roads, then turn the defense into a disciplined withdrawal toward Bydgoszcz before the German pincer seals the corridor.",
        guderianBriefing: "The German plan drives armor through the forest road net, repairs blocked bridges, uses motorized infantry to fix Polish strongpoints, and converts delay into encirclement once the pincer pressure appears.",
        units: [
            unit("tuchola-9th-infantry", "Polish 9th Infantry Division bridge guards", .player, "Brda crossing defense", "Holds Pruszcz and Pila-Mlyn long enough for demolition teams to work."),
            unit("tuchola-27th-infantry", "Polish 27th Infantry Division counterattack group", .player, "Piecemeal counterattack", "Can hit the Brda bridgehead but suffers command friction if committed too late."),
            unit("tuchola-czersk-group", "Czersk Operational Group detachments", .player, "Forest road defense", "Defends Chojnice and Tuchola road hubs before withdrawal."),
            unit("tuchola-cavalry", "Pomeranian Cavalry Brigade screen", .player, "Reconnaissance disruption", "Covers withdrawal around Krojanty and can cancel a German pursuit order."),
            unit("tuchola-at-guns", "Polish anti-tank gun sections", .player, "Forest choke fire lanes", "Scarce guns that threaten panzers moving through marked road chokepoints."),
            unit("tuchola-demolition-parties", "Brda bridge demolition parties", .player, "Crossing denial", "Convert early bridge defense into German engineer delay."),
            unit("tuchola-3rd-panzer", "German 3rd Panzer Division spearhead", .guderianAI, "Armored breakthrough", "Primary armored pressure along forest roads and bridge approaches."),
            unit("tuchola-motorized-divisions", "German 2nd and 20th Motorized Divisions", .guderianAI, "Infantry pursuit", "Fixes Polish road hubs and supports panzer bridgehead expansion."),
            unit("tuchola-engineers", "German bridge engineers", .guderianAI, "Bridge repair", "Reopens blocked Brda crossings after demolition or artillery pressure."),
            unit("tuchola-pincer", "German pincer pressure from East Prussia", .guderianAI, "Encirclement clock", "Operational pressure marker that forces Polish withdrawal decisions."),
        ],
        triggers: [
            trigger("tuchola-first-contact", "Border contact", "German turn 1 reaches a Brda or Chojnice approach", "Reveal bridge demolition and forest choke objectives."),
            trigger("tuchola-brda-demolition", "Brda bridge demolition", "Polish demolition parties hold Pruszcz or Pila-Mlyn at turn end", "Block that crossing and delay German panzer movement until engineers act."),
            trigger("tuchola-krojanty-screen", "Krojanty cavalry screen", "Pomeranian Cavalry Brigade is committed on turns 2-3", "Cancel one German reconnaissance or pursuit order, then require cavalry withdrawal."),
            trigger("tuchola-pincer-arrival", "Pincer arrival", "German AI controls a bridgehead and the East Prussia marker is active", "Shift scoring emphasis from road defense to Bydgoszcz withdrawal."),
            trigger("tuchola-withdrawal-window", "Bydgoszcz withdrawal window", "Turns 4-7", "Score surviving infantry, cavalry screen, command, and anti-tank units that exit east."),
        ]
    )

    private static let wizna = ScenarioSetupScript(
        id: .wizna,
        playerBriefing: "Hold the fortified line long enough for the wider Polish defense to gain time. Survival and delay matter more than destroying every attacker.",
        guderianBriefing: "The German plan pressures the bunkers with artillery, probes for weak strongpoints, then assaults once defenders are pinned.",
        units: [
            unit("wizna-raginis-hq", "Raginis command post", .player, "Command objective", "Represents the fortified command position around Gora Strekowa."),
            unit("wizna-bunker-line", "Bunker machine-gun sections", .player, "Fortified infantry", "Static defense groups occupying the bunker belt."),
            unit("wizna-at-guns", "Polish anti-tank guns", .player, "Anti-armor screen", "Scarce weapons that teach fire lanes and target priority."),
            unit("wizna-artillery", "German artillery batteries", .guderianAI, "Suppression", "Scheduled fire used to introduce pinning and bunker pressure."),
            unit("wizna-panzer-column", "Panzer assault column", .guderianAI, "Armored pressure", "Temporary dzw German armor proxy until Polish/German 1939 rosters are added."),
            unit("wizna-assault-pioneers", "German assault pioneers", .guderianAI, "Bunker assault", "Infantry tasked with reducing isolated fortifications."),
        ],
        triggers: [
            trigger("wizna-turn-pressure", "Bombardment pressure", "Start of German turns 1 and 2", "Apply artillery/pinning pressure to bunker objectives."),
            trigger("wizna-last-stand", "Last bunker stand", "Player controls one or fewer bunker objectives", "Award delay points and surface withdrawal/hold guidance."),
        ],
        tutorialSteps: [
            tutorial("wizna-cover", "Use the bunkers", "Select a fortified unit and keep it inside the bunker belt to preserve cover saves."),
            tutorial("wizna-fire-lanes", "Prioritize armor lanes", "Use anti-tank fire against vehicles on the Narew approach road before they reach assault range."),
            tutorial("wizna-delay", "Score by delaying", "End turns with bunkers contested or controlled; the tutorial rewards time bought, not total destruction."),
            tutorial("wizna-assault", "Survive close assault", "When a bunker is isolated, prepare for assault and preserve nearby support fire."),
        ]
    )

    private static let sedan = ScenarioSetupScript(
        id: .sedan,
        playerBriefing: "Defend the Meuse line, keep artillery control intact, and prevent German engineers from expanding the bridgehead.",
        guderianBriefing: "The German plan suppresses the defenders, pushes engineers to two bridge sites, then releases panzer follow-up into the Sedan road net.",
        units: [
            unit("sedan-french-infantry", "French Meuse infantry", .player, "River defense", "Defenders holding the east bank and town approaches."),
            unit("sedan-french-artillery", "French artillery group", .player, "Defensive fire support", "Key morale and fire-support objective behind the river line."),
            unit("sedan-french-observers", "French forward observers", .player, "Artillery control", "Observation assets that protect the fire plan."),
            unit("sedan-counterattack", "French reserve counterattack group", .player, "Timed counterattack", "Arrives after the bridgehead forms or artillery control is lost."),
            unit("sedan-engineers", "German assault engineers", .guderianAI, "Bridgehead creation", "Crossing troops that unlock the panzer follow-up trigger."),
            unit("sedan-motorized-infantry", "German motorized infantry", .guderianAI, "Crossing support", "Infantry that clears near-bank positions."),
            unit("sedan-panzer-followup", "German panzer follow-up", .guderianAI, "Breakout force", "Armor released after bridgehead conditions are met."),
            unit("sedan-air-support", "German air-pressure event", .guderianAI, "Suppression", "Represents the disruption that opens the river-crossing sequence."),
        ],
        triggers: [
            trigger("sedan-air-pressure", "Air-pressure opening", "Start of turn 1", "Suppress or pin selected French artillery/observer positions."),
            trigger("sedan-engineer-crossing", "Engineer crossing", "German engineers control a bridge site", "Unlock bridgehead objective scoring and panzer follow-up."),
            trigger("sedan-french-counterattack", "French counterattack", "Bridgehead perimeter is German-controlled or artillery control is lost", "Release French reserve counterattack group."),
            trigger("sedan-panzer-release", "Panzer release", "German bridgehead survives a full player turn", "Allow German armor to move east along the Sedan-Gaulier road."),
        ]
    )

    private static let moscowTulaKashira = ScenarioSetupScript(
        id: .moscowTulaKashira,
        playerBriefing: "Hold Tula, deny the Kashira road, and force German armor to outrun its infantry and supply. The Soviet player wins by timing reserves after German spearheads are tired, not by meeting every thrust at the map edge.",
        guderianBriefing: "The German plan drives along the Orel-Tula road, attempts to crack the city belt with infantry follow-up, and risks exhaustion if armor keeps pushing without support.",
        units: [
            unit("moscow-tula-rifle", "Tula rifle defense group", .player, "City defense", "Infantry and guns holding the Tula belt and prepared urban positions."),
            unit("moscow-worker-militia", "Tula worker militia detachments", .player, "Morale anchor", "Local defense units that help keep city objectives contested under pressure."),
            unit("moscow-at-guns", "Soviet anti-tank gun line", .player, "Road denial", "Guns deployed to punish German armor that remains on the Orel-Tula road."),
            unit("moscow-reserve-armor", "Soviet reserve armor counterattack", .player, "Timed counterattack", "T-34/KV-style counterattack placeholder that enters after German exhaustion or road overextension."),
            unit("moscow-mobile-winter-reserve", "Mobile winter reserve", .player, "Flank pressure", "Ski, cavalry, or mobile detachments represented as a late-game pressure force."),
            unit("moscow-panzer-spearhead", "German panzer spearhead", .guderianAI, "Road thrust", "Armor racing the winter road net toward Tula and Kashira."),
            unit("moscow-motorized-infantry", "German motorized infantry follow-up", .guderianAI, "Assault support", "Infantry needed to convert panzer reach into objective control."),
            unit("moscow-supply-columns", "German supply columns", .guderianAI, "Exhaustion clock", "Represents the logistical strain limiting repeated German attacks."),
            unit("moscow-artillery-support", "German artillery support", .guderianAI, "City suppression", "Fire support that helps attacks but cannot fully offset winter and supply penalties."),
        ],
        triggers: [
            trigger("moscow-first-exhaustion", "First exhaustion marker", "German armor ends a turn beyond infantry support", "Mark supply strain and expose the spearhead to Soviet counterattack scoring."),
            trigger("moscow-road-ambush", "Road ambush", "German armor moves through a marked winter road choke", "Allow Soviet anti-tank guns to score counterattack or exhaustion points."),
            trigger("moscow-reserve-release", "Soviet reserve release", "German spearhead controls a road objective or has two exhaustion markers", "Release Soviet reserve armor counterattack."),
            trigger("moscow-city-morale", "Tula morale check", "Tula is contested at the end of a German assault turn", "Worker militia and city defenders may preserve contested control."),
            trigger("moscow-final-counteroffensive", "Final counteroffensive window", "Turns 6-8 and German exhaustion is active", "Soviet mobile winter reserve can enter on a flank objective."),
        ]
    )

    private static func generic(for scenario: GuderianScenario) -> ScenarioSetupScript {
        ScenarioSetupScript(
            id: scenario.id,
            playerBriefing: scenario.designIntent,
            guderianBriefing: GermanAIPlanCatalog.plan(for: scenario).strategicGoal,
            units: [
                unit("\(scenario.id.rawValue)-player-main", scenario.playerForceSummary, .player, scenario.playerPosture.rawValue, "Placeholder force card until the scenario receives a hand-authored order of battle."),
                unit("\(scenario.id.rawValue)-german-main", scenario.guderianCommand, .guderianAI, "German pressure force", "Placeholder force card until the scenario receives a hand-authored order of battle."),
            ],
            triggers: [
                trigger("\(scenario.id.rawValue)-objective-pressure", "Objective pressure", "German AI reaches a primary objective", "Escalate from movement pressure to shooting or assault orders."),
            ]
        )
    }
}

private func unit(_ id: String, _ name: String, _ side: ScenarioUnitSide, _ role: String, _ note: String) -> ScenarioUnitCard {
    ScenarioUnitCard(id: id, name: name, side: side, role: role, historicalNote: note)
}

private func trigger(_ id: String, _ name: String, _ condition: String, _ effect: String) -> ScenarioTrigger {
    ScenarioTrigger(id: id, name: name, condition: condition, effect: effect)
}

private func tutorial(_ id: String, _ title: String, _ instruction: String) -> TutorialStep {
    TutorialStep(id: id, title: title, instruction: instruction)
}
