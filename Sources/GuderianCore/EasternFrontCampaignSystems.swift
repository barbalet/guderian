import Foundation

public enum EasternFrontAssetKind: String, Codable, Hashable, Sendable {
    case rifleArmy = "Rifle army"
    case mechanizedCorps = "Mechanized corps"
    case tankReserve = "Tank reserve"
    case commandPost = "Command post"
    case breakoutRoute = "Breakout route"
    case riverCrossing = "River crossing"
    case railJunction = "Rail junction"
    case pocket = "Pocket"
    case logisticsFriction = "Logistics friction"
    case winterFriction = "Winter friction"
}

public struct EasternFrontAsset: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let kind: EasternFrontAssetKind
    public let battlefieldRole: String
    public let limitation: String

    public init(
        id: String,
        name: String,
        kind: EasternFrontAssetKind,
        battlefieldRole: String,
        limitation: String
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.battlefieldRole = battlefieldRole
        self.limitation = limitation
    }
}

public struct EasternFrontRule: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let trigger: String
    public let effect: String

    public init(id: String, name: String, trigger: String, effect: String) {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.effect = effect
    }
}

public struct EasternFrontScenarioSystemProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let operationalProblem: String
    public let playerDoctrine: String
    public let assets: [EasternFrontAsset]
    public let specialRules: [EasternFrontRule]

    public init(
        id: GuderianBattleID,
        operationalProblem: String,
        playerDoctrine: String,
        assets: [EasternFrontAsset],
        specialRules: [EasternFrontRule]
    ) {
        self.id = id
        self.operationalProblem = operationalProblem
        self.playerDoctrine = playerDoctrine
        self.assets = assets
        self.specialRules = specialRules
    }
}

public enum EasternFrontCampaignSystemCatalog {
    public static func profile(for scenario: GuderianScenario) -> EasternFrontScenarioSystemProfile? {
        profile(for: scenario.id)
    }

    public static func profile(for id: GuderianBattleID) -> EasternFrontScenarioSystemProfile? {
        switch id {
        case .bialystokMinsk:
            return bialystokMinsk
        case .moscowTulaKashira:
            return moscowTulaKashira
        default:
            return nil
        }
    }

    public static let easternFrontScenarioIDs: [GuderianBattleID] = [
        .bialystokMinsk,
        .moscowTulaKashira,
    ]

    private static let bialystokMinsk = EasternFrontScenarioSystemProfile(
        id: .bialystokMinsk,
        operationalProblem: "Soviet Western Front formations are forward-deployed in a vulnerable salient while Guderian's 2nd Panzer Group and Hoth's 3rd Panzer Group attempt a double envelopment toward Minsk.",
        playerDoctrine: "Preserve command posts, open at least one breakout route, counterattack only to unpin trapped armies, and keep rail/road communications alive long enough for units to escape the pockets.",
        assets: [
            easternAsset("bialystok-3rd-army", "Soviet 3rd Army detachments", .rifleArmy, "Northern pocket and breakout pressure around Bialystok.", "Can be cut off from Minsk roads by northern pincer markers."),
            easternAsset("bialystok-10th-army", "Soviet 10th Army salient force", .rifleArmy, "Largest forward salient force whose survival depends on timely withdrawal.", "Suffers command friction if ordered to counterattack and withdraw in the same window."),
            easternAsset("bialystok-4th-army", "Soviet 4th Army remnants", .rifleArmy, "Southern screen against 2nd Panzer Group.", "Starts vulnerable to Bug River penetration and air disruption."),
            easternAsset("bialystok-mechanized", "Mechanized corps counterattack groups", .mechanizedCorps, "Limited counterattacks to reopen lanes or delay panzers.", "Fuel and coordination losses make repeated attacks costly."),
            easternAsset("bialystok-minsk-rail", "Minsk road and rail junction", .railJunction, "Main command-and-escape objective east of the pockets.", "If cut, breakout scoring becomes much harder."),
            easternAsset("bialystok-bug-neman", "Bug and Neman crossings", .riverCrossing, "Initial German penetration points and Soviet delay opportunities.", "Crossings cannot stop panzers alone once bridgeheads exist."),
            easternAsset("bialystok-pocket", "Bialystok-Novogrudok pockets", .pocket, "Encirclement zones whose pressure rises each turn.", "Units trapped inside score only through breakout or command preservation."),
        ],
        specialRules: [
            easternRule("bialystok-double-envelopment", "Double envelopment", "German northern and southern pincer markers both advance east of the pocket line.", "Close one breakout route and increase pocket attrition."),
            easternRule("bialystok-boldin-counterattack", "Boldin counterattack", "Mechanized or cavalry assets attack a pincer marker on turns 2-4.", "Delay one pincer order and open a temporary escape lane, then mark the counterattack group fuel-low."),
            easternRule("bialystok-command-preservation", "Command preservation", "A Soviet command post reaches Minsk road or rail control.", "Award command-survival points and reduce pocket attrition for one turn."),
            easternRule("bialystok-breakout-lane", "Breakout lane", "A road/rail objective remains Soviet-controlled at turn end.", "Exit one trapped formation or remove one isolation marker."),
        ]
    )

    private static let moscowTulaKashira = EasternFrontScenarioSystemProfile(
        id: .moscowTulaKashira,
        operationalProblem: "German armor pushes through winter, supply strain, and Soviet defensive belts toward Tula and Kashira.",
        playerDoctrine: "Hold city belts, use anti-tank guns and reserves after German overextension, and convert winter logistics into counterattack timing.",
        assets: [
            easternAsset("moscow-rifle-belt", "Tula rifle defensive belt", .rifleArmy, "Prepared city defense and morale anchor.", "Can be worn down if reserves arrive too late."),
            easternAsset("moscow-tank-reserve", "Soviet tank reserve", .tankReserve, "Counterattack force against overextended armor.", "Scores best after German exhaustion markers appear."),
            easternAsset("moscow-winter", "Winter logistics friction", .winterFriction, "Limits repeated German armored assaults.", "Should slow pressure without freezing the battle."),
        ],
        specialRules: [
            easternRule("moscow-exhaustion", "German exhaustion", "German armor outruns infantry or supply.", "Add exhaustion and unlock Soviet reserve timing."),
            easternRule("moscow-counteroffensive", "Counteroffensive window", "Late turns with German exhaustion active.", "Soviet mobile reserves may enter and score flank pressure."),
        ]
    )
}

private func easternAsset(
    _ id: String,
    _ name: String,
    _ kind: EasternFrontAssetKind,
    _ role: String,
    _ limitation: String
) -> EasternFrontAsset {
    EasternFrontAsset(id: id, name: name, kind: kind, battlefieldRole: role, limitation: limitation)
}

private func easternRule(_ id: String, _ name: String, _ trigger: String, _ effect: String) -> EasternFrontRule {
    EasternFrontRule(id: id, name: name, trigger: trigger, effect: effect)
}
