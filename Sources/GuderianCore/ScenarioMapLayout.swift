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
        case .wizna:
            return wizna
        case .sedan:
            return sedan
        case .moscowTulaKashira:
            return moscowTulaKashira
        default:
            return fallback(for: scenario)
        }
    }

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
