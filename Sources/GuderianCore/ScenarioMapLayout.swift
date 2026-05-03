import Foundation

public enum ScenarioMapElementKind: String, Codable, Hashable, Sendable {
    case road = "Road"
    case river = "River"
    case town = "Town"
    case forest = "Forest"
    case ridge = "Ridge"
    case bunker = "Bunker"
    case fortifiedLine = "Fortified line"
    case bridge = "Bridge"
    case objective = "Objective"
    case artillery = "Artillery"
    case airPressure = "Air pressure"
    case deployment = "Deployment"
}

public enum ScenarioSide: String, Codable, Hashable, Sendable {
    case player = "Player"
    case guderianAI = "Guderian AI"
    case neutral = "Neutral"
}

public struct ScenarioMapPoint: Codable, Hashable, Sendable {
    public let x: Double
    public let y: Double

    public init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }
}

public struct ScenarioMapElement: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: ScenarioMapElementKind
    public let side: ScenarioSide
    public let points: [ScenarioMapPoint]
    public let radius: Double
    public let strokeWidth: Double
    public let note: String

    public init(
        id: String,
        name: String,
        kind: ScenarioMapElementKind,
        side: ScenarioSide = .neutral,
        points: [ScenarioMapPoint],
        radius: Double = 0,
        strokeWidth: Double = 3,
        note: String = ""
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.side = side
        self.points = points
        self.radius = radius
        self.strokeWidth = strokeWidth
        self.note = note
    }
}

public struct ScenarioDeploymentZone: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let side: ScenarioSide
    public let origin: ScenarioMapPoint
    public let width: Double
    public let height: Double
    public let note: String

    public init(
        id: String,
        name: String,
        side: ScenarioSide,
        origin: ScenarioMapPoint,
        width: Double,
        height: Double,
        note: String
    ) {
        self.id = id
        self.name = name
        self.side = side
        self.origin = origin
        self.width = width
        self.height = height
        self.note = note
    }
}

public struct ScenarioMapLayout: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let width: Double
    public let height: Double
    public let elements: [ScenarioMapElement]
    public let deploymentZones: [ScenarioDeploymentZone]

    public init(
        id: GuderianBattleID,
        title: String,
        width: Double = 100,
        height: Double = 64,
        elements: [ScenarioMapElement],
        deploymentZones: [ScenarioDeploymentZone]
    ) {
        self.id = id
        self.title = title
        self.width = width
        self.height = height
        self.elements = elements
        self.deploymentZones = deploymentZones
    }

    public var objectiveElements: [ScenarioMapElement] {
        elements.filter { $0.kind == .objective }
    }
}

public enum ScenarioMapCatalog {
    public static func layout(for scenario: GuderianScenario) -> ScenarioMapLayout {
        switch scenario.id {
        case .tucholaForest:
            return tucholaForest
        case .wizna:
            return wizna
        case .brzescLitewski:
            return brzescLitewski
        case .kobryn:
            return kobryn
        case .sedan:
            return sedan
        case .stonne:
            return stonne
        case .montcornet:
            return montcornet
        case .amiensAbbeville:
            return amiensAbbeville
        case .boulogne:
            return boulogne
        case .calais:
            return calais
        case .dunkirk:
            return dunkirk
        case .fallRot:
            return fallRot
        case .bialystokMinsk:
            return bialystokMinsk
        case .moscowTulaKashira:
            return moscowTulaKashira
        default:
            return fallback(for: scenario)
        }
    }

    private static let tucholaForest = ScenarioMapLayout(
        id: .tucholaForest,
        title: "Tuchola Forest Corridor",
        elements: [
            line("tuchola-corridor-road", "Chojnice-Tuchola-Bydgoszcz road", .road, [p(6, 28), p(21, 31), p(39, 34), p(61, 42), p(93, 54)], note: "Main withdrawal and pursuit route through the corridor."),
            line("tuchola-rail", "Chojnice rail line", .road, [p(2, 18), p(19, 24), p(42, 29), p(72, 31), p(99, 36)], width: 2, note: "Rail corridor and early Chojnice pressure axis."),
            line("tuchola-brda", "Brda River", .river, [p(8, 43), p(27, 39), p(47, 37), p(72, 45), p(99, 49)], width: 5, note: "Bridge obstacle and demolition line."),
            line("tuchola-forest-belt", "Tuchola forest belt", .forest, [p(13, 14), p(32, 20), p(55, 18), p(80, 25), p(94, 33)], width: 9, note: "Dense forest funnels armor onto the road net."),
            marker("tuchola-chojnice", "Chojnice", .town, .player, p(18, 25), radius: 5, note: "Rail and road hub where German motorized pressure opens."),
            marker("tuchola-town", "Tuchola", .town, .player, p(43, 33), radius: 5, note: "Infantry strongpoint and midgame delay objective."),
            marker("tuchola-pruszcz-bridge", "Pruszcz bridge", .bridge, .neutral, p(32, 38), radius: 3, note: "Early bridge fight over the Brda."),
            marker("tuchola-pila-mlyn", "Pila-Mlyn bridge", .bridge, .neutral, p(49, 37), radius: 3, note: "Demolition site and secondary crossing."),
            marker("tuchola-krojanty", "Krojanty screen", .objective, .player, p(24, 18), radius: 4, note: "Cavalry screen disrupts pursuit, then must withdraw."),
            marker("tuchola-bydgoszcz", "Bydgoszcz withdrawal", .objective, .player, p(88, 54), radius: 5, note: "Exit lane for coherent Polish formations."),
            marker("tuchola-german-pincer", "East Prussia pincer", .airPressure, .guderianAI, p(73, 18), radius: 5, note: "Operational pressure that converts the battle from delay to withdrawal."),
            marker("tuchola-panzer-entry", "XIX Corps spearhead", .objective, .guderianAI, p(7, 35), radius: 4, note: "German armored entry pressure from Western Pomerania."),
        ],
        deploymentZones: [
            zone("tuchola-polish-corridor", "Pomeranian Army corridor defense", .player, p(16, 20), 44, 29, "Polish infantry, anti-tank guns, demolition teams, and cavalry screens start around the forest road net."),
            zone("tuchola-german-assembly", "German pincer assembly", .guderianAI, p(0, 11), 30, 36, "XIX Panzer Corps pushes from the west while pincer pressure appears from the north and east."),
        ]
    )

    private static let brzescLitewski = ScenarioMapLayout(
        id: .brzescLitewski,
        title: "Brzesc Fortress Defense",
        elements: [
            line("brzesc-bug", "Bug River", .river, [p(8, 18), p(31, 24), p(55, 25), p(87, 18)], width: 5, note: "River edge and fortress approach."),
            line("brzesc-muchawiec", "Muchawiec River", .river, [p(23, 56), p(41, 45), p(58, 35), p(73, 26)], width: 4, note: "Secondary obstacle dividing the town and fortress approaches."),
            line("brzesc-rail", "Rail line", .road, [p(4, 46), p(29, 42), p(49, 38), p(78, 34), p(97, 29)], width: 2, note: "Armored-train support and German approach lane."),
            marker("brzesc-citadel", "Brzesc Citadel", .fortifiedLine, .player, p(52, 32), radius: 7, note: "Central fortress objective."),
            marker("brzesc-town", "Brzesc town", .town, .player, p(43, 43), radius: 6, note: "Urban delay zone before the citadel."),
            marker("brzesc-armored-train", "Armored train track", .artillery, .player, p(35, 40), radius: 4, note: "Rail-bound fire support and evacuation cover."),
            marker("brzesc-ft17", "FT-17 tank park", .objective, .player, p(59, 45), radius: 4, note: "Obsolete tanks used as mobile strongpoints."),
            marker("brzesc-panzer-entry", "XIX Corps west entry", .objective, .guderianAI, p(7, 44), radius: 4, note: "German panzer and motorized assault approach."),
            marker("brzesc-south-exit", "South fallback gate", .objective, .player, p(78, 55), radius: 4, note: "Withdrawal route after citadel delay."),
        ],
        deploymentZones: [
            zone("brzesc-polish-fortress", "Polish fortress defense", .player, p(34, 24), 43, 28, "Improvised infantry battalions, engineers, artillery, armored trains, and FT-17 tanks defend the town and citadel."),
            zone("brzesc-german-assault", "XIX Corps assault columns", .guderianAI, p(0, 35), 29, 22, "German panzer, motorized infantry, and artillery pressure the west and rail approaches."),
        ]
    )

    private static let kobryn = ScenarioMapLayout(
        id: .kobryn,
        title: "Kobryn Rearguard",
        elements: [
            line("kobryn-road-west", "Brzesc-Kobryn road", .road, [p(3, 37), p(25, 35), p(47, 34), p(70, 31), p(96, 28)], note: "German motorized infantry approach and Polish withdrawal route."),
            line("kobryn-eastern-road", "Eastern withdrawal road", .road, [p(46, 39), p(63, 48), p(82, 54), p(99, 58)], width: 2, note: "Exit path for Operational Group Polesie."),
            line("kobryn-canal", "Mukhavets marsh/canal line", .river, [p(4, 51), p(27, 48), p(53, 51), p(79, 46), p(100, 42)], width: 4, note: "Wet terrain and partial obstacle around Kobryn."),
            marker("kobryn-town", "Kobryn", .town, .player, p(47, 35), radius: 7, note: "Road hub and rearguard anchor."),
            marker("kobryn-reserve-line", "60th Reserve Infantry line", .fortifiedLine, .player, p(57, 42), radius: 5, note: "Improvised defensive line covering eastern exits."),
            marker("kobryn-west-roadblock", "Western roadblock", .objective, .player, p(29, 35), radius: 4, note: "Delay motorized pressure before the town fight."),
            marker("kobryn-east-exit", "Eastern exit", .objective, .player, p(87, 55), radius: 5, note: "Force-preservation scoring route."),
            marker("kobryn-german-fix", "2nd Motorized pressure", .objective, .guderianAI, p(12, 38), radius: 4, note: "German effort to fix and envelop the rearguard."),
        ],
        deploymentZones: [
            zone("kobryn-polish-rearguard", "Operational Group Polesie", .player, p(34, 28), 42, 25, "Polish reserve infantry, guns, and rearguard detachments start around Kobryn and the eastern road."),
            zone("kobryn-german-entry", "German motorized entry", .guderianAI, p(0, 27), 28, 25, "German 2nd Motorized Infantry Division attacks from the west."),
        ]
    )

    private static let wizna = ScenarioMapLayout(
        id: .wizna,
        title: "Wizna Fortified Line",
        elements: [
            line("narew-road", "Narew approach road", .road, [p(4, 52), p(30, 42), p(58, 33), p(94, 22)], note: "Main armored approach toward the bunker line."),
            line("narew-river", "Narew river line", .river, [p(0, 29), p(24, 25), p(47, 27), p(72, 20), p(100, 18)], width: 6, note: "River obstacle shaping the German attack lanes."),
            line("wizna-line", "Polish bunker belt", .fortifiedLine, [p(32, 19), p(43, 24), p(52, 30), p(61, 38)], width: 4, note: "Forward fortified positions."),
            marker("kurpiki-bunker", "Kurpiki bunker", .bunker, .player, p(39, 24), radius: 3, note: "Tutorial strongpoint for cover and anti-tank fire."),
            marker("gelczyn-bunker", "Gelczyn bunker", .bunker, .player, p(52, 31), radius: 3, note: "Central defense objective."),
            marker("gora-strekowa", "Gora Strekowa HQ", .objective, .player, p(61, 39), radius: 4, note: "Command position and final hold objective."),
            marker("german-artillery", "German artillery park", .artillery, .guderianAI, p(15, 47), radius: 4, note: "Pressure source for tutorial bombardment events."),
        ],
        deploymentZones: [
            zone("polish-line", "Polish fortified line", .player, p(30, 16), 38, 30, "Player deploys bunkers, machine guns, and anti-tank guns along the line."),
            zone("german-approach", "German assembly area", .guderianAI, p(0, 39), 24, 21, "German armor and infantry enter from the western approach."),
        ]
    )

    private static let sedan = ScenarioMapLayout(
        id: .sedan,
        title: "Sedan Meuse Crossing",
        elements: [
            line("meuse", "Meuse river", .river, [p(0, 29), p(19, 25), p(41, 28), p(62, 35), p(100, 38)], width: 7, note: "Major crossing obstacle."),
            line("sedan-road", "Sedan-Gaulier road", .road, [p(18, 57), p(35, 43), p(49, 34), p(67, 22), p(91, 9)], note: "Axis of German bridgehead expansion."),
            marker("sedan-town", "Sedan", .town, .player, p(40, 38), radius: 8, note: "Urban anchor for French defense."),
            marker("gaulier-bridge", "Gaulier bridge site", .bridge, .neutral, p(48, 31), radius: 3, note: "Primary German crossing objective."),
            marker("wadelincourt-bridge", "Wadelincourt bridge site", .bridge, .neutral, p(58, 34), radius: 3, note: "Secondary engineer crossing."),
            marker("french-artillery", "French artillery positions", .artillery, .player, p(73, 48), radius: 6, note: "Defensive fire support and morale objective."),
            marker("air-pressure", "Stuka pressure lane", .airPressure, .guderianAI, p(30, 15), radius: 7, note: "Timed disruption event against defenders."),
            marker("bridgehead", "Bridgehead perimeter", .objective, .neutral, p(61, 27), radius: 7, note: "German expansion goal; player scores by denying it."),
        ],
        deploymentZones: [
            zone("french-bank", "French near-bank defense", .player, p(34, 30), 52, 27, "French infantry, guns, and observers defend the east bank and artillery parks."),
            zone("german-west-bank", "German west-bank assembly", .guderianAI, p(0, 7), 32, 35, "German engineers, infantry, and panzers prepare the forced crossing."),
        ]
    )

    private static let stonne = ScenarioMapLayout(
        id: .stonne,
        title: "Stonne Heights Counterattack",
        elements: [
            line("stonne-sedan-road", "Sedan-Stonne road", .road, [p(6, 54), p(25, 44), p(45, 34), p(70, 22), p(93, 14)], note: "German bridgehead flank route."),
            line("stonne-mont-dieu-woods", "Mont-Dieu woods", .forest, [p(18, 21), p(38, 20), p(58, 18), p(82, 24)], width: 8, note: "Concealment and approach cover."),
            marker("stonne-village", "Stonne village", .town, .neutral, p(52, 33), radius: 7, note: "Repeatedly contested village objective."),
            marker("stonne-heights", "Stonne heights", .ridge, .player, p(58, 25), radius: 6, note: "Observation and bridgehead threat."),
            marker("stonne-char-b1", "Char B1 shock point", .objective, .player, p(44, 39), radius: 4, note: "French heavy-tank counterattack start."),
            marker("stonne-bridgehead-risk", "Bridgehead risk line", .objective, .player, p(69, 25), radius: 4, note: "Player scores by threatening the Sedan bridgehead flank."),
            marker("stonne-german-support", "German support line", .artillery, .guderianAI, p(31, 48), radius: 5, note: "Motorized infantry, anti-tank, and artillery support."),
        ],
        deploymentZones: [
            zone("stonne-french-counterattack", "French armor and infantry", .player, p(37, 23), 32, 24, "French heavy tanks and infantry stage to contest Stonne and the heights."),
            zone("stonne-german-bridgehead", "German bridgehead flank", .guderianAI, p(8, 40), 32, 18, "German Grossdeutschland and panzer support protect the bridgehead flank."),
        ]
    )

    private static let montcornet = ScenarioMapLayout(
        id: .montcornet,
        title: "Montcornet Armored Raid",
        elements: [
            line("montcornet-road-net", "Montcornet road net", .road, [p(4, 40), p(27, 37), p(48, 32), p(72, 30), p(96, 23)], note: "German rear-area movement and French raid path."),
            line("montcornet-withdrawal", "French withdrawal lane", .road, [p(43, 53), p(33, 44), p(21, 35), p(8, 28)], width: 2, note: "Armor exit route after raid objectives are hit."),
            marker("montcornet-town", "Montcornet", .town, .neutral, p(52, 32), radius: 6, note: "Raid center and German road hub."),
            marker("montcornet-column", "German column park", .objective, .guderianAI, p(66, 28), radius: 5, note: "Transport, command, and supply disruption target."),
            marker("montcornet-4dcr", "4e DCR attack group", .objective, .player, p(34, 43), radius: 4, note: "French armored raid start."),
            marker("montcornet-air", "Luftwaffe reaction lane", .airPressure, .guderianAI, p(62, 15), radius: 6, note: "Late air-pressure source."),
            marker("montcornet-exit", "Armor disengagement", .objective, .player, p(12, 29), radius: 4, note: "Exit point for surviving French tanks."),
        ],
        deploymentZones: [
            zone("montcornet-french-armor", "4e Division cuirassee", .player, p(22, 35), 30, 22, "French armor enters for a time-limited raid."),
            zone("montcornet-german-column", "German column security", .guderianAI, p(55, 18), 34, 22, "German road guards, reserves, and air-pressure markers defend the road net."),
        ]
    )

    private static let amiensAbbeville = ScenarioMapLayout(
        id: .amiensAbbeville,
        title: "Amiens-Abbeville Channel Race",
        elements: [
            line("amiens-somme", "Somme River", .river, [p(4, 42), p(25, 39), p(49, 41), p(73, 36), p(98, 34)], width: 6, note: "River line for blocking and bridge denial."),
            line("amiens-channel-road", "Amiens-Abbeville road", .road, [p(11, 50), p(32, 43), p(54, 38), p(77, 31), p(96, 24)], note: "German race to the Channel."),
            marker("amiens", "Amiens", .town, .player, p(33, 43), radius: 7, note: "Central road hub captured in the Channel dash."),
            marker("abbeville", "Abbeville", .town, .player, p(78, 31), radius: 7, note: "Channel cut objective."),
            marker("somme-bridges", "Somme bridges", .bridge, .neutral, p(55, 40), radius: 4, note: "Crossing contest for Allied delay."),
            marker("allied-roadblocks", "Allied roadblocks", .objective, .player, p(51, 33), radius: 4, note: "Blocking detachments buy evacuation time."),
            marker("channel-exit", "Channel exit", .objective, .guderianAI, p(94, 24), radius: 5, note: "German operational finish line."),
            marker("panzer-race", "Panzer race column", .objective, .guderianAI, p(14, 50), radius: 4, note: "XIX Corps armored entry."),
        ],
        deploymentZones: [
            zone("amiens-allied-block", "Allied blocking line", .player, p(30, 28), 52, 24, "French and British blocking detachments defend Somme bridges and road hubs."),
            zone("amiens-german-race", "XIX Corps road columns", .guderianAI, p(2, 42), 28, 18, "German panzer divisions race from the west toward Amiens and Abbeville."),
        ]
    )

    private static let boulogne = ScenarioMapLayout(
        id: .boulogne,
        title: "Boulogne Port Defense",
        elements: [
            line("boulogne-liane", "River Liane harbor channel", .river, [p(15, 54), p(31, 44), p(47, 34), p(67, 27), p(90, 22)], width: 5, note: "Harbor channel and urban crossing obstacle."),
            line("boulogne-coast-road", "Channel coast road", .road, [p(4, 48), p(24, 42), p(45, 36), p(68, 29), p(96, 18)], note: "2nd Panzer approach toward the port."),
            marker("boulogne-harbor", "Harbor evacuation", .objective, .player, p(70, 28), radius: 7, note: "Embarkation and destroyer docking objective."),
            marker("boulogne-haute-ville", "Haute Ville perimeter", .fortifiedLine, .player, p(55, 36), radius: 6, note: "Old-town defensive anchor above the port."),
            marker("boulogne-destroyers", "Destroyer fire lane", .artillery, .player, p(82, 17), radius: 5, note: "Naval support window for re-embarkation."),
            marker("boulogne-demolition", "Port demolition party", .objective, .player, p(73, 37), radius: 4, note: "Port denial after evacuation scoring."),
            marker("boulogne-mont-lambert", "Mont St. Lambert ridge", .ridge, .guderianAI, p(37, 23), radius: 5, note: "German observation and assault approach."),
            marker("boulogne-panzer-entry", "2nd Panzer entry", .objective, .guderianAI, p(9, 48), radius: 4, note: "German armor closes on the port."),
        ],
        deploymentZones: [
            zone("boulogne-allied-port", "Allied port perimeter", .player, p(48, 23), 38, 25, "French, British, and Belgian defenders hold harbor and old-town positions."),
            zone("boulogne-german-coast", "2nd Panzer assault area", .guderianAI, p(0, 34), 34, 22, "German armor and infantry enter along the coast road and ridge approaches."),
        ]
    )

    private static let calais = ScenarioMapLayout(
        id: .calais,
        title: "Calais Siege Perimeter",
        elements: [
            line("calais-coast-road", "Boulogne-Calais road", .road, [p(5, 45), p(25, 40), p(46, 36), p(70, 31), p(95, 26)], note: "German 10th Panzer approach."),
            line("calais-dunkirk-road", "Dunkirk road", .road, [p(66, 18), p(79, 14), p(94, 10)], width: 2, note: "Strategic delay axis toward Dunkirk."),
            marker("calais-outer-perimeter", "Outer perimeter", .fortifiedLine, .player, p(50, 35), radius: 8, note: "Layered town defenses."),
            marker("calais-citadel", "Citadel", .fortifiedLine, .player, p(61, 29), radius: 6, note: "Inner siege objective."),
            marker("calais-docks", "Docks and harbor", .objective, .player, p(72, 24), radius: 5, note: "Final port objective and supply route."),
            marker("calais-supply", "Garrison supply point", .artillery, .player, p(56, 43), radius: 4, note: "Ammunition and command endurance."),
            marker("calais-10th-panzer", "10th Panzer pressure", .objective, .guderianAI, p(14, 43), radius: 4, note: "German siege assault force."),
            marker("calais-air-pressure", "Air and artillery pressure", .airPressure, .guderianAI, p(37, 24), radius: 5, note: "Supply and perimeter suppression."),
        ],
        deploymentZones: [
            zone("calais-garrison", "Calais garrison", .player, p(47, 22), 36, 27, "British, French, and Belgian defenders hold layered port defenses."),
            zone("calais-german-siege", "10th Panzer siege line", .guderianAI, p(0, 31), 34, 22, "German armor, infantry, artillery, and air pressure reduce the port."),
        ]
    )

    private static let dunkirk = ScenarioMapLayout(
        id: .dunkirk,
        title: "Dunkirk Evacuation Perimeter",
        elements: [
            line("dunkirk-beach", "Beach evacuation line", .road, [p(58, 13), p(70, 11), p(84, 12), p(98, 15)], width: 4, note: "Embarkation sectors along the beach."),
            line("dunkirk-canal", "Canal defensive line", .river, [p(8, 43), p(28, 38), p(51, 35), p(75, 30), p(100, 28)], width: 5, note: "Perimeter obstacle and breach line."),
            line("dunkirk-road", "Dunkirk perimeter road", .road, [p(12, 53), p(35, 46), p(58, 36), p(82, 22)], note: "Rear-guard withdrawal route."),
            marker("dunkirk-beach-sector", "Beach sector", .objective, .player, p(78, 13), radius: 7, note: "Evacuation capacity objective."),
            marker("dunkirk-harbor", "Dunkirk harbor", .town, .player, p(72, 24), radius: 6, note: "Harbor evacuation and perimeter anchor."),
            marker("dunkirk-canal-gate", "Canal gate", .bridge, .player, p(55, 35), radius: 4, note: "Key perimeter crossing."),
            marker("dunkirk-rearguard", "Rear-guard line", .fortifiedLine, .player, p(45, 42), radius: 5, note: "Force left behind to protect evacuation lanes."),
            marker("dunkirk-air", "Air attack lane", .airPressure, .guderianAI, p(68, 8), radius: 6, note: "Evacuation-capacity pressure."),
            marker("dunkirk-german-pressure", "German pressure front", .objective, .guderianAI, p(17, 47), radius: 5, note: "Campaign-pressure marker compressing the perimeter."),
        ],
        deploymentZones: [
            zone("dunkirk-allied-perimeter", "Allied evacuation perimeter", .player, p(43, 16), 45, 31, "Allied rear guards defend canals, harbor, and beach sectors."),
            zone("dunkirk-german-front", "German perimeter pressure", .guderianAI, p(0, 35), 34, 23, "German pressure forces advance against canal and road exits."),
        ]
    )

    private static let fallRot = ScenarioMapLayout(
        id: .fallRot,
        title: "Fall Rot Swiss-Border Drive",
        elements: [
            line("fallrot-drive-road", "Panzergruppe Guderian drive", .road, [p(5, 48), p(23, 43), p(42, 36), p(63, 29), p(86, 18)], note: "Deep exploitation route toward the Swiss border."),
            line("fallrot-canal", "Aisne and Marne-Rhine crossings", .river, [p(9, 36), p(31, 34), p(55, 31), p(77, 27), p(98, 25)], width: 5, note: "Crossing and demolition line."),
            line("fallrot-vosges", "Vosges retreat corridor", .ridge, [p(55, 54), p(68, 48), p(82, 39), p(95, 32)], width: 5, note: "French withdrawal corridor and trap line."),
            marker("fallrot-langres", "Langres road hub", .town, .player, p(41, 36), radius: 5, note: "Mid-route delay point."),
            marker("fallrot-belfort", "Belfort fortress town", .fortifiedLine, .player, p(78, 30), radius: 6, note: "Late fortress-town stand."),
            marker("fallrot-epinal", "Epinal fortress town", .fortifiedLine, .player, p(72, 46), radius: 5, note: "Northern fortress and retreat hinge."),
            marker("fallrot-fuel", "Fuel denial point", .objective, .player, p(50, 33), radius: 4, note: "Road congestion and fuel friction scoring."),
            marker("fallrot-swiss-border", "Swiss-border cut line", .objective, .guderianAI, p(89, 19), radius: 5, note: "German encirclement finish line."),
        ],
        deploymentZones: [
            zone("fallrot-french-delay", "French late-campaign defense", .player, p(36, 27), 46, 28, "French bridge, fortress, and retreat-corridor defenders."),
            zone("fallrot-panzergruppe", "Panzergruppe Guderian columns", .guderianAI, p(0, 38), 30, 19, "German deep exploitation columns enter from the west."),
        ]
    )

    private static let bialystokMinsk = ScenarioMapLayout(
        id: .bialystokMinsk,
        title: "Bialystok-Minsk Pocket",
        elements: [
            line("bialystok-minsk-road", "Bialystok-Minsk road and rail", .road, [p(7, 44), p(28, 39), p(51, 34), p(76, 28), p(96, 23)], note: "Main communications and breakout route."),
            line("bialystok-bug", "Bug River crossing line", .river, [p(4, 54), p(24, 48), p(44, 44), p(66, 41)], width: 5, note: "Southern penetration line for 2nd Panzer Group."),
            line("bialystok-neman", "Neman crossing line", .river, [p(17, 20), p(38, 24), p(61, 27), p(83, 24)], width: 4, note: "Northern pincer crossing pressure."),
            marker("bialystok-salient", "Bialystok salient", .objective, .player, p(31, 38), radius: 7, note: "Forward Soviet pocket risk."),
            marker("bialystok-novogrudok", "Novogrudok pocket", .objective, .neutral, p(55, 35), radius: 6, note: "Larger encirclement zone."),
            marker("bialystok-minsk", "Minsk rail junction", .town, .player, p(83, 25), radius: 7, note: "Command and breakout objective."),
            marker("bialystok-boldin", "Mechanized counterattack", .objective, .player, p(43, 30), radius: 4, note: "Counterattack marker to reopen escape lanes."),
            marker("bialystok-guderian", "2nd Panzer Group pincer", .objective, .guderianAI, p(23, 50), radius: 5, note: "Southern German pincer."),
            marker("bialystok-hoth", "3rd Panzer Group pincer", .objective, .guderianAI, p(43, 23), radius: 5, note: "Northern German pincer."),
        ],
        deploymentZones: [
            zone("bialystok-soviet-front", "Soviet Western Front", .player, p(23, 27), 52, 25, "Soviet rifle armies, command posts, and mechanized counterattack groups start in the salient."),
            zone("bialystok-german-pincers", "German pincer approaches", .guderianAI, p(4, 18), 36, 39, "2nd and 3rd Panzer Group pressure closes from south and north."),
        ]
    )

    private static let moscowTulaKashira = ScenarioMapLayout(
        id: .moscowTulaKashira,
        title: "Tula-Kashira Winter Defense",
        elements: [
            line("tula-road", "Orel-Tula road", .road, [p(6, 56), p(30, 43), p(57, 31), p(86, 12)], note: "Main panzer advance route."),
            line("winter-track", "Frozen side track", .road, [p(18, 61), p(34, 52), p(52, 46), p(76, 39)], width: 2, note: "Secondary movement route with winter friction."),
            line("upa-river", "Upa river", .river, [p(12, 33), p(39, 30), p(65, 24), p(100, 28)], width: 5, note: "Frozen river and defensive obstacle."),
            line("tula-belt", "Tula defensive belt", .fortifiedLine, [p(58, 18), p(66, 23), p(76, 23), p(86, 18)], width: 4, note: "Prepared city defenses and anti-tank positions."),
            marker("road-choke", "Winter road choke", .ridge, .neutral, p(47, 37), radius: 4, note: "Movement friction and ambush point."),
            marker("tula", "Tula", .town, .player, p(69, 23), radius: 8, note: "City hold objective."),
            marker("kashira-road", "Kashira road", .objective, .player, p(83, 12), radius: 5, note: "Southern approach to Moscow."),
            marker("soviet-reserve", "Soviet reserve staging", .objective, .player, p(73, 49), radius: 5, note: "Reserve armor and mobile winter forces enter from this area."),
            marker("winter-supply", "German supply strain", .airPressure, .guderianAI, p(26, 48), radius: 5, note: "Attrition and movement friction event source."),
            marker("panzer-overreach", "Panzer overreach line", .objective, .guderianAI, p(55, 32), radius: 4, note: "German armor beyond this line starts checking supply and morale pressure."),
        ],
        deploymentZones: [
            zone("soviet-city-belt", "Soviet Tula belt", .player, p(58, 12), 35, 24, "Soviet infantry, guns, and reserves defend Tula and Kashira approaches."),
            zone("german-road-column", "German road columns", .guderianAI, p(0, 40), 30, 20, "2nd Panzer Army enters along strained winter roads."),
        ]
    )

    private static func fallback(for scenario: GuderianScenario) -> ScenarioMapLayout {
        let featureElements = scenario.mapFeatures.enumerated().map { index, feature in
            marker(
                "\(scenario.id.rawValue)-feature-\(index)",
                feature.name,
                index.isMultiple(of: 2) ? .objective : .town,
                .neutral,
                p(22 + Double(index * 18 % 58), 20 + Double(index * 11 % 28)),
                radius: 4,
                note: feature.role
            )
        }

        return ScenarioMapLayout(
            id: scenario.id,
            title: "\(scenario.title) planning map",
            elements: [
                line("\(scenario.id.rawValue)-main-road", "Operational road", .road, [p(4, 51), p(35, 38), p(63, 26), p(96, 13)], note: "Generic campaign route until a hand-authored map is added."),
            ] + featureElements,
            deploymentZones: [
                zone("\(scenario.id.rawValue)-player", "Player deployment", .player, p(58, 11), 34, 28, "Opposing force deployment area."),
                zone("\(scenario.id.rawValue)-german", "Guderian approach", .guderianAI, p(2, 36), 30, 22, "German attack or pursuit start area."),
            ]
        )
    }
}

private func line(
    _ id: String,
    _ name: String,
    _ kind: ScenarioMapElementKind,
    _ points: [ScenarioMapPoint],
    width: Double = 3,
    note: String
) -> ScenarioMapElement {
    ScenarioMapElement(id: id, name: name, kind: kind, points: points, strokeWidth: width, note: note)
}

private func marker(
    _ id: String,
    _ name: String,
    _ kind: ScenarioMapElementKind,
    _ side: ScenarioSide,
    _ point: ScenarioMapPoint,
    radius: Double,
    note: String
) -> ScenarioMapElement {
    ScenarioMapElement(id: id, name: name, kind: kind, side: side, points: [point], radius: radius, note: note)
}

private func zone(
    _ id: String,
    _ name: String,
    _ side: ScenarioSide,
    _ origin: ScenarioMapPoint,
    _ width: Double,
    _ height: Double,
    _ note: String
) -> ScenarioDeploymentZone {
    ScenarioDeploymentZone(id: id, name: name, side: side, origin: origin, width: width, height: height, note: note)
}

private func p(_ x: Double, _ y: Double) -> ScenarioMapPoint {
    ScenarioMapPoint(x, y)
}
