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
        case .brzescLitewski:
            return GermanAIPlan(
                id: .brzescLitewski,
                postureName: "Fortress isolation",
                strategicGoal: "Fix the town, cut the rail line, isolate the citadel, and prevent Polish mobile assets from withdrawing.",
                targetPriorities: ["Brzesc town", "Armored train track", "Brzesc Citadel", "South fallback gate"],
                orders: [
                    order("brzesc-town-fix", "Turns 1-2", .movement, "Brzesc town", "Motorized infantry fixes the town before armor pushes the citadel approaches."),
                    order("brzesc-rail-cut", "Turns 2-3", .shooting, "Armored train track", "Suppress rail support and reduce armored-train freedom."),
                    order("brzesc-citadel-ring", "Turns 3-5", .movement, "Brzesc Citadel", "Armor and engineers close the ring around fortress sectors."),
                    order("brzesc-final-assault", "Turns 5+", .assault, "South fallback gate", "Assault or interdict the fallback gate once the citadel is isolated."),
                ]
            )
        case .kobryn:
            return GermanAIPlan(
                id: .kobryn,
                postureName: "Motorized rearguard fixation",
                strategicGoal: "Fix the Kobryn road hub with 2nd Motorized Infantry Division and close eastern exits before Operational Group Polesie withdraws.",
                targetPriorities: ["Western roadblock", "Kobryn", "Eastern exit", "60th Reserve Infantry line"],
                orders: [
                    order("kobryn-west-contact", "Turns 1-2", .movement, "Western roadblock", "Drive motorized infantry into contact without overextending into gun lanes."),
                    order("kobryn-town-fix", "Turns 2-4", .shooting, "Kobryn", "Suppress the town defense so flank patrols can threaten exits."),
                    order("kobryn-exit-threat", "Turns 3-5", .movement, "Eastern exit", "Send flank patrol markers toward withdrawal lanes."),
                    order("kobryn-close-rearguard", "Turns 5+", .assault, "60th Reserve Infantry line", "Assault isolated rearguard units after exit pressure is active."),
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
        case .stonne:
            return GermanAIPlan(
                id: .stonne,
                postureName: "Bridgehead flank containment",
                strategicGoal: "Keep Stonne and the heights from becoming a French platform against the Sedan bridgehead.",
                targetPriorities: ["Stonne village", "Stonne heights", "Char B1 shock point", "Bridgehead risk line"],
                orders: [
                    order("stonne-pin-infantry", "Turn 1", .shooting, "French infantry around Stonne", "Pin infantry before heavy tanks can convert shock into control."),
                    order("stonne-retake-village", "Turns 2-4", .assault, "Stonne village", "Retake or contest the village after each French thrust."),
                    order("stonne-flank-char", "Turns 3-5", .movement, "Char B1 shock point", "Seek flanking or isolation markers before anti-tank fire resolves."),
                    order("stonne-secure-heights", "Turns 5+", .reinforcement, "Stonne heights", "Commit support to secure the heights and lower bridgehead-risk scoring."),
                ]
            )
        case .montcornet:
            return GermanAIPlan(
                id: .montcornet,
                postureName: "Raid absorption and air reaction",
                strategicGoal: "Absorb the French armored raid, protect road-column assets, then use reserves and air pressure to force withdrawal.",
                targetPriorities: ["German column park", "Montcornet", "Armor disengagement", "4e DCR attack group"],
                orders: [
                    order("montcornet-column-guard", "Turns 1-2", .movement, "German column park", "Screen soft targets without overcommitting reserves."),
                    order("montcornet-reserve-reaction", "Turns 3-4", .reinforcement, "Montcornet", "Bring reserves in after the French raid window opens."),
                    order("montcornet-air-pressure", "Turns 4-6", .artillery, "4e DCR attack group", "Use air pressure against French armor that stays on road objectives."),
                    order("montcornet-pursuit", "Turns 5+", .assault, "Armor disengagement", "Threaten French withdrawal lanes if raid forces linger."),
                ]
            )
        case .amiensAbbeville:
            return GermanAIPlan(
                id: .amiensAbbeville,
                postureName: "Channel race and Somme guard",
                strategicGoal: "Capture Amiens, reach Abbeville, and secure the Somme line to complete the Channel cut.",
                targetPriorities: ["Amiens", "Somme bridges", "Abbeville", "Channel exit"],
                orders: [
                    order("amiens-race", "Turn 1", .movement, "Amiens", "Drive 1st Panzer toward Amiens before blocking detachments can consolidate."),
                    order("amiens-bridge-pressure", "Turns 2-3", .movement, "Somme bridges", "Force or bypass contested bridges while engineers clear roadblocks."),
                    order("amiens-abbeville-push", "Turns 3-4", .reinforcement, "Abbeville", "Shift 2nd Panzer pressure toward Abbeville and the Channel exit."),
                    order("amiens-channel-secure", "Turns 5+", .shooting, "Channel exit", "Secure the Somme line and suppress counterattack routes."),
                ]
            )
        case .boulogne:
            return GermanAIPlan(
                id: .boulogne,
                postureName: "Port assault and harbor split",
                strategicGoal: "Split the old town from the harbor, disrupt destroyer embarkation, and capture Boulogne before evacuation and demolition scoring runs out.",
                targetPriorities: ["Harbor evacuation", "Haute Ville perimeter", "Destroyer fire lane", "Port demolition party"],
                orders: [
                    order("boulogne-ridge-approach", "Turn 1", .movement, "Mont St. Lambert ridge", "Gain observation and approach lanes before the harbor assault."),
                    order("boulogne-harbor-split", "Turns 2-3", .assault, "Haute Ville perimeter", "Separate old-town defenders from harbor embarkation."),
                    order("boulogne-air-harbor", "Turns 3-4", .artillery, "Harbor evacuation", "Reduce destroyer and embarkation capacity."),
                    order("boulogne-port-capture", "Turns 5+", .assault, "Port demolition party", "Capture or disable demolition teams before port denial resolves."),
                ]
            )
        case .calais:
            return GermanAIPlan(
                id: .calais,
                postureName: "Layered siege reduction",
                strategicGoal: "Reduce Calais perimeter layers, cut garrison supply, and end the Dunkirk-time delay by seizing the citadel and docks.",
                targetPriorities: ["Outer perimeter", "Garrison supply point", "Citadel", "Docks and harbor"],
                orders: [
                    order("calais-outer-ring", "Turns 1-2", .movement, "Outer perimeter", "Invest the town and force the first defense layer."),
                    order("calais-supply-pressure", "Turns 2-4", .artillery, "Garrison supply point", "Suppress supply and command nodes to lower defensive fire."),
                    order("calais-citadel-assault", "Turns 4-5", .assault, "Citadel", "Assault inner positions after supply pressure accumulates."),
                    order("calais-docks-final", "Turns 6+", .assault, "Docks and harbor", "Clear the final port objective and stop delay scoring."),
                ]
            )
        case .dunkirk:
            return GermanAIPlan(
                id: .dunkirk,
                postureName: "Perimeter compression",
                strategicGoal: "Compress canal lines, reduce beach evacuation capacity, and force rear guards to choose between holding gates and escaping.",
                targetPriorities: ["Canal gate", "Rear-guard line", "Beach sector", "Dunkirk harbor"],
                orders: [
                    order("dunkirk-canal-pressure", "Turns 1-2", .movement, "Canal defensive line", "Pressure canal crossings without skipping the command-scope caveat."),
                    order("dunkirk-air-capacity", "Turns 2-5", .artillery, "Beach sector", "Use air pressure to reduce evacuation capacity."),
                    order("dunkirk-rearguard-fix", "Turns 3-6", .shooting, "Rear-guard line", "Pin rear guards so beach exits become harder to hold."),
                    order("dunkirk-perimeter-collapse", "Turns 6+", .assault, "Dunkirk harbor", "Compress the final harbor and beachhead objectives."),
                ]
            )
        case .fallRot:
            return GermanAIPlan(
                id: .fallRot,
                postureName: "Deep exploitation to Swiss border",
                strategicGoal: "Force crossings, bypass or reduce fortress towns, and connect with eastern pressure to trap French forces near the Vosges.",
                targetPriorities: ["Aisne and Marne-Rhine crossings", "Langres road hub", "Belfort fortress town", "Vosges retreat corridor"],
                orders: [
                    order("fallrot-crossings", "Turns 1-2", .movement, "Aisne and Marne-Rhine crossings", "Force or repair crossings before French demolition chains mature."),
                    order("fallrot-road-exploit", "Turns 2-4", .movement, "Langres road hub", "Exploit road gaps and trigger congestion checks if demolitions fire."),
                    order("fallrot-fortress-pressure", "Turns 4-6", .assault, "Belfort and Epinal fortress towns", "Reduce or bypass fortress towns while link-up pressure grows."),
                    order("fallrot-vosges-trap", "Turns 6+", .reinforcement, "Vosges retreat corridor", "Close the retreat corridor with Army Group C link-up pressure."),
                ]
            )
        case .bialystokMinsk:
            return GermanAIPlan(
                id: .bialystokMinsk,
                postureName: "Double envelopment to Minsk",
                strategicGoal: "Drive 2nd Panzer Group from the south and 3rd Panzer Group from the north to close Bialystok and Minsk pockets before Soviet command assets escape.",
                targetPriorities: ["Bug River crossing line", "Bialystok salient", "Minsk rail junction", "Novogrudok pocket"],
                orders: [
                    order("bialystok-bug-crossing", "Turn 1", .movement, "Bug River crossing line", "Use 2nd Panzer Group to open the southern pincer."),
                    order("bialystok-neman-pressure", "Turns 1-2", .movement, "Neman crossing line", "Coordinate northern pincer pressure with Hoth's 3rd Panzer Group."),
                    order("bialystok-counterattack-check", "Turns 2-4", .shooting, "Mechanized counterattack", "Suppress fuel-low Soviet counterattack groups after they delay a pincer."),
                    order("bialystok-pocket-close", "Turns 4-6", .reinforcement, "Novogrudok pocket", "Close pocket markers east of Bialystok and cut road/rail escape."),
                    order("bialystok-pocket-reduction", "Turns 6+", .assault, "Bialystok salient", "Bring infantry armies forward to reduce trapped formations."),
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
