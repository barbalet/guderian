import Foundation

public enum GuderianBattleID: String, CaseIterable, Codable, Hashable, Sendable {
    case tucholaForest
    case wizna
    case brzescLitewski
    case kobryn
    case sedan
    case stonne
    case montcornet
    case amiensAbbeville
    case boulogne
    case calais
    case dunkirk
    case fallRot
    case bialystokMinsk
    case smolensk
    case roslavlNovozybkov
    case kiev
    case bryansk
    case mtsensk
    case moscowTulaKashira
}

public enum CampaignTheater: String, Codable, Hashable, Sendable {
    case poland1939 = "Poland 1939"
    case france1940 = "France 1940"
    case easternFront1941 = "Eastern Front 1941"
}

public enum ScenarioStatus: String, Codable, Hashable, Sendable {
    case dataLocked = "Data locked"
    case dzwProxyLoadable = "dzw proxy loadable"
    case planned = "Planned"
}

public enum PlayerPosture: String, Codable, Hashable, Sendable {
    case fortifiedDelay = "Fortified delay"
    case mobileDelay = "Mobile delay"
    case urbanDefense = "Urban defense"
    case counterattack = "Counterattack"
    case breakout = "Breakout"
    case evacuationDefense = "Evacuation defense"
}

public struct ScenarioDateKey: Codable, Comparable, Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public static func < (lhs: ScenarioDateKey, rhs: ScenarioDateKey) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}

public struct ScenarioSource: Codable, Hashable, Sendable {
    public let title: String
    public let url: URL

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}

public struct ScenarioMapFeature: Codable, Hashable, Sendable {
    public let name: String
    public let role: String

    public init(name: String, role: String) {
        self.name = name
        self.role = role
    }
}

public struct ScenarioObjective: Codable, Hashable, Sendable {
    public let name: String
    public let victoryPoints: Int
    public let description: String

    public init(name: String, victoryPoints: Int, description: String) {
        self.name = name
        self.victoryPoints = victoryPoints
        self.description = description
    }
}

public struct ScenarioForceSlot: Codable, Hashable, Sendable {
    public let side: String
    public let historicalForce: String
    public let role: String

    public init(side: String, historicalForce: String, role: String) {
        self.side = side
        self.historicalForce = historicalForce
        self.role = role
    }
}

public struct GuderianScenario: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let order: Int
    public let title: String
    public let dateLabel: String
    public let startDate: ScenarioDateKey
    public let theater: CampaignTheater
    public let status: ScenarioStatus
    public let playerPosture: PlayerPosture
    public let guderianCommand: String
    public let playerForceSummary: String
    public let historicalResult: String
    public let designIntent: String
    public let sourceLinks: [ScenarioSource]
    public let mapFeatures: [ScenarioMapFeature]
    public let objectives: [ScenarioObjective]
    public let forces: [ScenarioForceSlot]
    public let tags: [String]

    public var sourceSummary: String {
        sourceLinks.map(\.title).joined(separator: ", ")
    }

    public var isDemoScenario: Bool {
        id == .wizna || id == .sedan || id == .moscowTulaKashira
    }
}

public enum GuderianCampaignCatalog {
    public static let all: [GuderianScenario] = [
        makeScenario(
            .tucholaForest,
            order: 1,
            title: "Battle of Tuchola Forest",
            dateLabel: "1-5 Sep 1939",
            start: .init(year: 1939, month: 9, day: 1),
            theater: .poland1939,
            status: .planned,
            posture: .mobileDelay,
            command: "XIX Panzer Corps under 4th Army",
            playerForce: "Polish Pomeranian Army elements in the Polish Corridor",
            result: "German victory",
            intent: "Delay the armored corridor breakout with forests, roadblocks, limited anti-tank assets, and withdrawal routes.",
            sources: [source("Battle of Tuchola Forest", "https://en.wikipedia.org/wiki/Battle_of_Tuchola_Forest")],
            features: [feature("Tuchola forest roads", "restricted armored movement"), feature("Polish Corridor", "operational escape route")],
            objectives: [objective("Delay crossing columns", 3, "Score for each German spearhead held west of the exit roads."), objective("Withdraw command posts", 2, "Preserve headquarters and anti-tank assets.")],
            forces: [force("Player", "Polish corridor defenders", "delay and withdraw"), force("Guderian AI", "XIX Panzer Corps spearheads", "break through")]
        ),
        makeScenario(
            .wizna,
            order: 2,
            title: "Battle of Wizna",
            dateLabel: "7-10 Sep 1939",
            start: .init(year: 1939, month: 9, day: 7),
            theater: .poland1939,
            status: .dzwProxyLoadable,
            posture: .fortifiedDelay,
            command: "XIX Panzer Corps; Guderian listed with Ferdinand Schaal",
            playerForce: "Polish fortified line under Wladyslaw Raginis and Stanislaw Brykalski",
            result: "German victory",
            intent: "Use bunkers, anti-tank guns, and machine-gun nests to hold against overwhelming armor and artillery.",
            sources: [source("Battle of Wizna", "https://en.wikipedia.org/wiki/Battle_of_Wizna")],
            features: [feature("Bunker line", "fortified strongpoints"), feature("Narew approaches", "armored assault lane")],
            objectives: [objective("Hold the bunkers", 4, "Earn points for each fortification still resisting at turn end."), objective("Preserve the anti-tank guns", 2, "Keep scarce anti-armor weapons firing as long as possible.")],
            forces: [force("Player", "Polish Wizna defenders", "fortified delay"), force("Guderian AI", "German panzer and artillery assault group", "reduce bunkers")]
        ),
        makeScenario(
            .brzescLitewski,
            order: 3,
            title: "Battle of Brzesc Litewski",
            dateLabel: "14-17 Sep 1939",
            start: .init(year: 1939, month: 9, day: 14),
            theater: .poland1939,
            status: .planned,
            posture: .urbanDefense,
            command: "XIX Panzer Corps with 10th Panzer, 3rd Panzer, and 20th Infantry Division",
            playerForce: "Polish Brzesc defense group under Konstanty Plisowski",
            result: "German victory",
            intent: "Stage a fortress and urban delay with armored trains, old tanks, artillery, and fallback routes.",
            sources: [source("Battle of Brzesc Litewski", "https://en.wikipedia.org/wiki/Battle_of_Brze%C5%9B%C4%87_Litewski")],
            features: [feature("Citadel approaches", "urban strongpoint"), feature("Rail line", "armored train route")],
            objectives: [objective("Delay the citadel assault", 4, "Hold inner positions through multiple German assaults."), objective("Evacuate mobile reserves", 2, "Withdraw surviving armor and train assets.")],
            forces: [force("Player", "Brzesc defense group", "fortress defense"), force("Guderian AI", "XIX Panzer Corps assault columns", "capture fortress")]
        ),
        makeScenario(
            .kobryn,
            order: 4,
            title: "Battle of Kobryn",
            dateLabel: "14-18 Sep 1939",
            start: .init(year: 1939, month: 9, day: 14),
            theater: .poland1939,
            status: .planned,
            posture: .mobileDelay,
            command: "XIX Panzer Corps, primarily 2nd Motorized Infantry Division",
            playerForce: "Operational Group Polesie and 60th Reserve Infantry Division",
            result: "Inconclusive",
            intent: "Protect a rearguard, block routes, and escape before encirclement closes.",
            sources: [source("Battle of Kobryn", "https://en.wikipedia.org/wiki/Battle_of_Kobry%C5%84")],
            features: [feature("Kobryn town", "contested road hub"), feature("Eastern exits", "withdrawal lanes")],
            objectives: [objective("Keep the road hub contested", 3, "Prevent an early German route capture."), objective("Exit reserve infantry", 3, "Score for units leaving by the eastern edge.")],
            forces: [force("Player", "Operational Group Polesie", "rearguard withdrawal"), force("Guderian AI", "German motorized infantry", "fix and encircle")]
        ),
        makeScenario(
            .sedan,
            order: 5,
            title: "Battle of Sedan",
            dateLabel: "12-17 May 1940",
            start: .init(year: 1940, month: 5, day: 12),
            theater: .france1940,
            status: .dzwProxyLoadable,
            posture: .fortifiedDelay,
            command: "XIX Army Corps under Panzergruppe Kleist",
            playerForce: "French 2nd Army sector with British air support",
            result: "German victory",
            intent: "Defend the Meuse crossing, bridge approaches, artillery positions, and counterattack routes under air pressure.",
            sources: [source("Battle of Sedan", "https://en.wikipedia.org/wiki/Battle_of_Sedan_%281940%29"), source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps")],
            features: [feature("Meuse river", "crossing obstacle"), feature("Sedan bridge sites", "German bridgehead objectives"), feature("Artillery parks", "defensive fire support")],
            objectives: [objective("Deny bridgehead expansion", 5, "Keep German units away from the far-bank objectives."), objective("Save artillery control", 2, "Keep observer and artillery assets unbroken.")],
            forces: [force("Player", "French Sedan sector defenders", "river defense"), force("Guderian AI", "XIX Army Corps assault echelons", "force crossing")]
        ),
        makeScenario(.stonne, order: 6, title: "Stonne Heights", dateLabel: "15-17 May 1940", start: .init(year: 1940, month: 5, day: 15), theater: .france1940, status: .planned, posture: .counterattack, command: "XIX Army Corps bridgehead flank", playerForce: "French armor and infantry around Stonne", result: "German bridgehead secured", intent: "Threaten the bridgehead with heavy tanks, village cover, and hill control.", sources: [source("Battle of Sedan", "https://en.wikipedia.org/wiki/Battle_of_Sedan_%281940%29"), source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps")], features: [feature("Stonne village", "close-range armor fight"), feature("Heights", "bridgehead observation")], objectives: [objective("Contest the heights", 4, "Control high ground overlooking the bridgehead."), objective("Break assault guns", 2, "Damage German support before withdrawing.")], forces: [force("Player", "French Char B1 bis counterattack force", "counterattack"), force("Guderian AI", "German bridgehead flank guard", "hold bridgehead")]),
        makeScenario(.montcornet, order: 7, title: "Battle of Montcornet", dateLabel: "17-19 May 1940", start: .init(year: 1940, month: 5, day: 17), theater: .france1940, status: .planned, posture: .counterattack, command: "Guderian sector with German 1st Panzer Division", playerForce: "French 4e Division cuirassee under Charles de Gaulle", result: "French tactical success followed by withdrawal", intent: "Raid German columns with strong tanks but limited support.", sources: [source("Battle of Montcornet", "https://en.wikipedia.org/wiki/Battle_of_Montcornet")], features: [feature("Montcornet village", "raid target"), feature("Luftwaffe lanes", "air pressure timing")], objectives: [objective("Raid the column", 4, "Destroy or disrupt German transport units."), objective("Disengage armor", 2, "Exit tanks before air attacks peak.")], forces: [force("Player", "4e Division cuirassee", "armored raid"), force("Guderian AI", "German column guards", "absorb and counterattack")]),
        makeScenario(.amiensAbbeville, order: 8, title: "Amiens-Abbeville Channel Race", dateLabel: "20 May 1940", start: .init(year: 1940, month: 5, day: 20), theater: .france1940, status: .planned, posture: .mobileDelay, command: "XIX Army Corps", playerForce: "French and British blocking forces on Somme approaches", result: "German breakthrough to Channel", intent: "Buy evacuation time by holding bridges, towns, and road junctions.", sources: [source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps")], features: [feature("Somme bridges", "crossing control"), feature("Abbeville road", "exit axis")], objectives: [objective("Hold Somme crossings", 3, "Delay German exit movement."), objective("Demolish road links", 2, "Deny clean armored routes.")], forces: [force("Player", "Allied blocking detachments", "mobile delay"), force("Guderian AI", "Panzer spearheads", "reach Channel")]),
        makeScenario(.boulogne, order: 9, title: "Battle of Boulogne", dateLabel: "22-25 May 1940", start: .init(year: 1940, month: 5, day: 22), theater: .france1940, status: .planned, posture: .evacuationDefense, command: "XIX Corps; 2nd Panzer Division attack", playerForce: "French, British, and Belgian port defenders", result: "German victory", intent: "Protect evacuation points, demolitions, and naval-fire support while German armor closes in.", sources: [source("Battle of Boulogne", "https://en.wikipedia.org/wiki/Battle_of_Boulogne")], features: [feature("Harbor", "evacuation objective"), feature("Old town perimeter", "urban defense")], objectives: [objective("Evacuate troops", 5, "Score for units embarked from the harbor."), objective("Hold demolition teams", 2, "Keep port denial teams alive.")], forces: [force("Player", "Boulogne garrison", "port defense"), force("Guderian AI", "2nd Panzer Division", "capture port")]),
        makeScenario(.calais, order: 10, title: "Siege of Calais", dateLabel: "22-26 May 1940", start: .init(year: 1940, month: 5, day: 22), theater: .france1940, status: .planned, posture: .evacuationDefense, command: "XIX Corps sector; 10th Panzer Division under Ferdinand Schaal", playerForce: "British, French, and Belgian defenders", result: "German victory", intent: "Win strategically by holding long enough to support Dunkirk, not by keeping the port forever.", sources: [source("Siege of Calais", "https://en.wikipedia.org/wiki/Siege_of_Calais_%281940%29")], features: [feature("Calais walls", "defensive perimeter"), feature("Dunkirk road", "strategic delay axis")], objectives: [objective("Hold the perimeter", 4, "Delay German entry into the port."), objective("Protect Dunkirk time", 3, "Score each turn the German force is fixed at Calais.")], forces: [force("Player", "Calais garrison", "siege defense"), force("Guderian AI", "10th Panzer Division", "reduce port")]),
        makeScenario(.dunkirk, order: 11, title: "Dunkirk Perimeter Pressure", dateLabel: "26 May-4 Jun 1940", start: .init(year: 1940, month: 5, day: 26), theater: .france1940, status: .planned, posture: .evacuationDefense, command: "Guderian-adjacent Channel port campaign pressure", playerForce: "British, French, Belgian, and Dutch evacuation perimeter", result: "Allied evacuation under German pressure", intent: "Conduct perimeter defense and evacuation management with direct-command caveats.", sources: [source("Battle of Dunkirk", "https://en.wikipedia.org/wiki/Battle_of_Dunkirk")], features: [feature("Beach perimeter", "evacuation zone"), feature("Canal lines", "defensive obstacles")], objectives: [objective("Evacuate formations", 6, "Score for units withdrawn by sea."), objective("Hold perimeter exits", 2, "Keep German units out of evacuation lanes.")], forces: [force("Player", "Dunkirk perimeter forces", "evacuation defense"), force("Guderian AI", "German pressure forces", "compress perimeter")]),
        makeScenario(.fallRot, order: 12, title: "Fall Rot Swiss-Border Drive", dateLabel: "10-22 Jun 1940", start: .init(year: 1940, month: 6, day: 10), theater: .france1940, status: .planned, posture: .mobileDelay, command: "Panzergruppe Guderian", playerForce: "French defenders around Aisne, Marne-Rhine Canal, Langres, Belfort, and Epinal", result: "German victory", intent: "Stage bridge demolitions, fortress stands, fuel denial, and retreat corridors.", sources: [source("XIX Army Corps", "https://en.wikipedia.org/wiki/XIX_Army_Corps")], features: [feature("Marne-Rhine Canal", "crossing obstacle"), feature("Fortress towns", "late-campaign strongpoints")], objectives: [objective("Deny bridges", 3, "Destroy or hold canal crossings."), objective("Extract defenders", 3, "Move French forces toward retreat corridors.")], forces: [force("Player", "French late-campaign defenders", "mobile delay"), force("Guderian AI", "Panzergruppe Guderian", "deep exploitation")]),
        makeScenario(.bialystokMinsk, order: 13, title: "Battle of Bialystok-Minsk", dateLabel: "22 Jun-9 Jul 1941", start: .init(year: 1941, month: 6, day: 22), theater: .easternFront1941, status: .planned, posture: .breakout, command: "2nd Panzer Group as Army Group Centre southern pincer", playerForce: "Soviet Western Front formations", result: "German victory", intent: "Fight breakout and delaying actions while preserving command assets and supply routes.", sources: [source("Battle of Bialystok-Minsk", "https://en.wikipedia.org/wiki/Battle_of_Bia%C5%82ystok%E2%80%93Minsk")], features: [feature("Pocket roads", "breakout routes"), feature("Minsk approaches", "encirclement pressure")], objectives: [objective("Open breakout lanes", 4, "Keep at least one route free."), objective("Save command units", 2, "Withdraw headquarters and artillery.")], forces: [force("Player", "Soviet Western Front detachments", "breakout"), force("Guderian AI", "2nd Panzer Group", "encircle")]),
        makeScenario(.smolensk, order: 14, title: "Battle of Smolensk", dateLabel: "10 Jul-10 Sep 1941", start: .init(year: 1941, month: 7, day: 10), theater: .easternFront1941, status: .planned, posture: .breakout, command: "2nd Panzer Group with Hoth's northern pincer", playerForce: "Soviet armies around Smolensk", result: "German victory with delay to German advance", intent: "Counterattack, hold river crossings, and open pocket escape lanes.", sources: [source("Battle of Smolensk", "https://en.wikipedia.org/wiki/Battle_of_Smolensk_%281941%29")], features: [feature("Dnieper crossings", "river defense"), feature("Smolensk pocket", "encirclement zone")], objectives: [objective("Keep crossings contested", 4, "Prevent a clean pincer closure."), objective("Release trapped armies", 3, "Exit pocketed units eastward.")], forces: [force("Player", "Soviet Smolensk defenders", "counterattack and breakout"), force("Guderian AI", "2nd Panzer Group", "close pincer")]),
        makeScenario(.roslavlNovozybkov, order: 15, title: "Roslavl-Novozybkov Offensive", dateLabel: "30 Aug-12 Sep 1941", start: .init(year: 1941, month: 8, day: 30), theater: .easternFront1941, status: .planned, posture: .counterattack, command: "2nd Panzer Group turned south toward Kiev", playerForce: "Soviet Bryansk Front under Andrey Yeryomenko", result: "German victory", intent: "Disrupt the southward turn and damage German spearheads before Operation Typhoon.", sources: [source("Roslavl-Novozybkov offensive", "https://en.wikipedia.org/wiki/Roslavl%E2%80%93Novozybkov_offensive")], features: [feature("Desna crossings", "operational hinge"), feature("Bryansk Front assembly areas", "Soviet attack start")], objectives: [objective("Strike panzer flank", 4, "Damage German spearhead units."), objective("Preserve reserves", 2, "Avoid losing all tank and rifle reserves.")], forces: [force("Player", "Bryansk Front counterattack force", "spoiling offensive"), force("Guderian AI", "2nd Panzer Group", "continue south")]),
        makeScenario(.kiev, order: 16, title: "Battle of Kiev", dateLabel: "7 Jul-26 Sep 1941", start: .init(year: 1941, month: 9, day: 1), theater: .easternFront1941, status: .planned, posture: .breakout, command: "2nd Panzer Group northern pincer with Kleist's 1st Panzer Group", playerForce: "Soviet Southwestern Front", result: "German victory and major encirclement", intent: "Prioritize command evacuation, breakout corridors, and delaying pincer closure.", sources: [source("Battle of Kiev", "https://en.wikipedia.org/wiki/Battle_of_Kiev_%281941%29")], features: [feature("Northern pincer route", "Guderian approach"), feature("Kiev pocket", "encirclement zone")], objectives: [objective("Delay pincer closure", 5, "Hold key junctions against panzer pressure."), objective("Evacuate command assets", 3, "Move headquarters and artillery out of the pocket.")], forces: [force("Player", "Soviet Southwestern Front", "breakout defense"), force("Guderian AI", "2nd Panzer Group", "close northern pincer")]),
        makeScenario(.bryansk, order: 17, title: "Battle of Bryansk", dateLabel: "30 Sep-21 Oct 1941", start: .init(year: 1941, month: 9, day: 30), theater: .easternFront1941, status: .planned, posture: .breakout, command: "2nd Panzer Army after Kiev", playerForce: "Soviet Bryansk Front, including 50th, 13th, and 3rd Armies", result: "German victory", intent: "Trade ground for time, fight pocket liquidation, and protect the Tula axis.", sources: [source("Battle of Bryansk", "https://en.wikipedia.org/wiki/Battle_of_Bryansk_%281941%29")], features: [feature("Bryansk pocket", "encirclement fight"), feature("Tula road", "southern Moscow approach")], objectives: [objective("Delay pocket collapse", 4, "Keep encircled formations fighting."), objective("Guard Tula axis", 3, "Prevent a clean German breakthrough east.")], forces: [force("Player", "Bryansk Front detachments", "delay and breakout"), force("Guderian AI", "2nd Panzer Army", "encircle and advance")]),
        makeScenario(.mtsensk, order: 18, title: "Mtsensk Armored Ambush", dateLabel: "4-11 Oct 1941", start: .init(year: 1941, month: 10, day: 4), theater: .easternFront1941, status: .planned, posture: .counterattack, command: "Guderian's Panzergruppe 2 sector", playerForce: "Soviet 4th Tank Brigade / future 1st Guards Tank Brigade", result: "Soviet delaying success", intent: "Use T-34 and KV ambushes, anti-tank screens, and terrain to blunt German panzer divisions.", sources: [source("Mikhail Katukov", "https://en.wikipedia.org/wiki/Mikhail_Katukov"), source("Battle of Moscow", "https://en.wikipedia.org/wiki/Battle_of_Moscow")], features: [feature("Mtsensk approaches", "ambush lanes"), feature("Wooded ridges", "concealed armor positions")], objectives: [objective("Ambush panzer lead", 5, "Destroy or immobilize spearhead vehicles."), objective("Withdraw tanks intact", 2, "Preserve elite armor after the ambush.")], forces: [force("Player", "4th Tank Brigade", "armored ambush"), force("Guderian AI", "German panzer divisions", "force road")]),
        makeScenario(
            .moscowTulaKashira,
            order: 19,
            title: "Moscow Southern Approach",
            dateLabel: "2 Oct 1941-7 Jan 1942",
            start: .init(year: 1941, month: 10, day: 24),
            theater: .easternFront1941,
            status: .dzwProxyLoadable,
            posture: .fortifiedDelay,
            command: "2nd Panzer Army under Guderian",
            playerForce: "Soviet forces defending Tula, Kashira, and southern approaches to Moscow",
            result: "Soviet victory",
            intent: "Balance winter, logistics, reinforcements, city defense, and counteroffensive timing.",
            sources: [source("Battle of Moscow", "https://en.wikipedia.org/wiki/Battle_of_Moscow"), source("2nd Panzer Army", "https://en.wikipedia.org/wiki/2nd_Panzer_Army")],
            features: [feature("Tula defensive belt", "city strongpoint"), feature("Kashira road", "southern approach to Moscow"), feature("Winter roads", "logistics friction")],
            objectives: [objective("Hold Tula", 5, "Keep Soviet control of the city objective."), objective("Exhaust panzer supply", 3, "Force German units to spend turns in poor supply or winter terrain.")],
            forces: [force("Player", "Soviet Tula and Kashira defenders", "winter defense"), force("Guderian AI", "2nd Panzer Army", "break southern approach")]
        ),
    ]

    public static let demoIDs: [GuderianBattleID] = [.wizna, .sedan, .moscowTulaKashira]

    public static func scenario(id: GuderianBattleID) -> GuderianScenario? {
        all.first { $0.id == id }
    }
}

private func makeScenario(
    _ id: GuderianBattleID,
    order: Int,
    title: String,
    dateLabel: String,
    start: ScenarioDateKey,
    theater: CampaignTheater,
    status: ScenarioStatus,
    posture: PlayerPosture,
    command: String,
    playerForce: String,
    result: String,
    intent: String,
    sources: [ScenarioSource],
    features: [ScenarioMapFeature],
    objectives: [ScenarioObjective],
    forces: [ScenarioForceSlot],
    tags: [String] = []
) -> GuderianScenario {
    GuderianScenario(
        id: id,
        order: order,
        title: title,
        dateLabel: dateLabel,
        startDate: start,
        theater: theater,
        status: status,
        playerPosture: posture,
        guderianCommand: command,
        playerForceSummary: playerForce,
        historicalResult: result,
        designIntent: intent,
        sourceLinks: sources,
        mapFeatures: features,
        objectives: objectives,
        forces: forces,
        tags: tags
    )
}

private func source(_ title: String, _ urlString: String) -> ScenarioSource {
    guard let url = URL(string: urlString) else {
        preconditionFailure("Invalid source URL: \(urlString)")
    }
    return ScenarioSource(title: title, url: url)
}

private func feature(_ name: String, _ role: String) -> ScenarioMapFeature {
    ScenarioMapFeature(name: name, role: role)
}

private func objective(_ name: String, _ victoryPoints: Int, _ description: String) -> ScenarioObjective {
    ScenarioObjective(name: name, victoryPoints: victoryPoints, description: description)
}

private func force(_ side: String, _ historicalForce: String, _ role: String) -> ScenarioForceSlot {
    ScenarioForceSlot(side: side, historicalForce: historicalForce, role: role)
}
