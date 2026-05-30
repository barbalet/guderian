import Foundation

public enum GuderianOrderDiceAuditCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case legacyPhaseCommand = "Legacy phase command"
    case phaseNameRead = "Phase name read"
    case sideTurnBoundary = "Side-turn boundary"
    case fixedActionScript = "Fixed action script"
    case tutorialOrCopy = "Tutorial or copy"
}

public enum GuderianOrderDiceAuditDisposition: String, Codable, Hashable, Sendable {
    case wrapWithOrderShim = "Wrap with order shim"
    case convertToOrderUI = "Convert to order UI"
    case convertToActivationAI = "Convert to activation AI"
    case reviseCopy = "Revise copy"
    case keepAsLegacyOnly = "Keep as legacy only"
}

public struct GuderianOrderDiceAuditFinding: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let typeName: String
    public let sourcePath: String
    public let category: GuderianOrderDiceAuditCategory
    public let legacyAssumption: String
    public let disposition: GuderianOrderDiceAuditDisposition
    public let targetCycles: ClosedRange<Int>

    public init(
        id: String,
        typeName: String,
        sourcePath: String,
        category: GuderianOrderDiceAuditCategory,
        legacyAssumption: String,
        disposition: GuderianOrderDiceAuditDisposition,
        targetCycles: ClosedRange<Int>
    ) {
        self.id = id
        self.typeName = typeName
        self.sourcePath = sourcePath
        self.category = category
        self.legacyAssumption = legacyAssumption
        self.disposition = disposition
        self.targetCycles = targetCycles
    }
}

public enum GuderianOrderDiceAuditCatalog {
    public static let cycleRange = 1...5

    public static let findings: [GuderianOrderDiceAuditFinding] = [
        finding(
            "playable-view-model-phase-advance",
            "DZWPlayableBattleViewModel",
            "Sources/GuderianApp/DZWPlayableBattleView.swift",
            .legacyPhaseCommand,
            "The visible battle surface still advances movement, shooting, and assault as global phases.",
            .convertToOrderUI,
            46...75
        ),
        finding(
            "playable-session-protocol-phase-advance",
            "DZWPlayableBoardSession",
            "Sources/GuderianApp/DZWPlayableBattleView.swift",
            .legacyPhaseCommand,
            "The shared board protocol exposes advancePhase as a normal command beside movement, shooting, and assault helpers.",
            .wrapWithOrderShim,
            11...45
        ),
        finding(
            "playable-view-phase-labels",
            "DZWPlayableBattleView",
            "Sources/GuderianApp/DZWPlayableBattleView.swift",
            .phaseNameRead,
            "The battle header, controls, and status copy render the current phase as the primary turn state.",
            .convertToOrderUI,
            46...75
        ),
        finding(
            "guderian-test-phase-budget",
            "GuderianTestFirstBattleRunController",
            "Sources/GuderianCore/GuderianTestFirstBattleAutoplay.swift",
            .fixedActionScript,
            "Autoplay step and safety accounting are named around phase advances rather than order-dice activations.",
            .convertToActivationAI,
            101...145
        ),
        finding(
            "playable-test-runner-phase-loop",
            "PlayableTestGameRunner",
            "dzw/Sources/DerZweiteWeltkriegGuderian/PlayableTestGameRunner.swift",
            .fixedActionScript,
            "Full-campaign automation still performs movement, shooting, assault, then phase advancement in a fixed order.",
            .convertToActivationAI,
            101...165
        ),
        finding(
            "field-command-native-session-phase-actions",
            "NativeBoardSession",
            "dzw/Sources/DerZweiteWeltkriegGuderian/NativeBoardSession.swift",
            .legacyPhaseCommand,
            "The field-command board session has order assignment available, but movement, shooting, and assault helpers still guard against the legacy phase.",
            .wrapWithOrderShim,
            11...45
        ),
        finding(
            "late-career-native-session-no-order-command",
            "LateCareerNativeBoardSession",
            "Sources/GuderianCore/UnifiedGuderianBattleCatalog.swift",
            .legacyPhaseCommand,
            "The late-career board session mirrors movement, shooting, assault, and advancePhase without a public issueOrder command yet.",
            .wrapWithOrderShim,
            21...45
        ),
        finding(
            "guderian-mac-catalyst-phase-controls",
            "GuderianMacCatalystBattleModel",
            "Sources/GuderianMacCatalyst/GuderianMacCatalystApp.swift",
            .legacyPhaseCommand,
            "The Catalyst interface exposes the same Phase command and phase-gated action buttons as the macOS surface.",
            .convertToOrderUI,
            46...75
        ),
        finding(
            "side-turn-german-button",
            "DZWPlayableBattleViewModel.runGermanTurn",
            "Sources/GuderianApp/DZWPlayableBattleView.swift",
            .sideTurnBoundary,
            "German automation is still presented as an AI turn boundary instead of a sequence of drawn-die activations.",
            .convertToActivationAI,
            76...105
        ),
        finding(
            "tutorial-next-phase-copy",
            "GuderianTutorialCatalog",
            "Sources/GuderianCore/TutorialOnboarding.swift",
            .tutorialOrCopy,
            "First-battle tutorial copy teaches Next Phase and phase-gated actions.",
            .reviseCopy,
            136...140
        ),
        finding(
            "briefing-rules-phase-copy",
            "UnifiedBattleBriefingCatalog",
            "Sources/GuderianCore/UnifiedGuderianBattleCatalog.swift",
            .tutorialOrCopy,
            "The shared briefing rules section still describes phase, action, and AI flow rather than order-dice activation.",
            .reviseCopy,
            176...180
        ),
    ]

    public static var impactedTypeNames: [String] {
        Array(Set(findings.map(\.typeName))).sorted()
    }

    public static var categoriesCovered: Set<GuderianOrderDiceAuditCategory> {
        Set(findings.map(\.category))
    }

    public static var acceptanceReadyThroughCycle5: Bool {
        cycleRange == 1...5 &&
            findings.count >= 10 &&
            categoriesCovered == Set(GuderianOrderDiceAuditCategory.allCases) &&
            impactedTypeNames.contains("DZWPlayableBattleViewModel") &&
            impactedTypeNames.contains("NativeBoardSession") &&
            impactedTypeNames.contains("LateCareerNativeBoardSession") &&
            findings.allSatisfy { !$0.legacyAssumption.isEmpty && !$0.sourcePath.isEmpty }
    }

    private static func finding(
        _ id: String,
        _ typeName: String,
        _ sourcePath: String,
        _ category: GuderianOrderDiceAuditCategory,
        _ legacyAssumption: String,
        _ disposition: GuderianOrderDiceAuditDisposition,
        _ targetCycles: ClosedRange<Int>
    ) -> GuderianOrderDiceAuditFinding {
        GuderianOrderDiceAuditFinding(
            id: id,
            typeName: typeName,
            sourcePath: sourcePath,
            category: category,
            legacyAssumption: legacyAssumption,
            disposition: disposition,
            targetCycles: targetCycles
        )
    }
}

public enum GuderianOrderDiceQualityMix: String, Codable, Hashable, Sendable {
    case inexperiencedRegular = "Inexperienced/Regular"
    case regular = "Regular"
    case regularVeteran = "Regular/Veteran"
    case mixedMilitiaRegularVeteran = "Militia/Regular/Veteran"
    case veteranArmored = "Veteran armored"
}

public enum GuderianOrderDicePinPressure: String, Codable, Hashable, Sendable {
    case light = "Light"
    case moderate = "Moderate"
    case heavy = "Heavy"
    case severe = "Severe"
}

public enum GuderianOrderDiceOfficerPresence: String, Codable, Hashable, Sendable {
    case sparse = "Sparse"
    case local = "Local"
    case strong = "Strong"
    case commandCritical = "Command critical"
}

public enum GuderianOrderDiceVehicleClass: String, CaseIterable, Codable, Hashable, Sendable {
    case infantry = "Infantry"
    case cavalry = "Cavalry"
    case gun = "Gun"
    case artillery = "Artillery"
    case engineer = "Engineer"
    case command = "Command"
    case armoredTrain = "Armored train"
    case softSkin = "Soft-skin"
    case halfTrack = "Half-track"
    case lightArmor = "Light armor"
    case mediumArmor = "Medium armor"
    case heavyArmor = "Heavy armor"
    case assaultGun = "Assault gun"
    case airPressure = "Air pressure"
    case navalSupport = "Naval support"
}

public enum GuderianOrderDiceTerrainCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case open = "Open"
    case rough = "Rough"
    case obstacle = "Obstacle"
    case building = "Building"
    case road = "Road"
    case water = "Water"
    case fortification = "Fortification"
}

public enum GuderianOrderDiceRetainedOrderUse: String, Codable, Hashable, Sendable {
    case rare = "Rare"
    case downCommon = "Down common"
    case ambushLikely = "Ambush likely"
    case ambushAndDown = "Ambush and Down"
}

public struct GuderianOrderDiceScenarioImpact: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let title: String
    public let order: Int
    public let commandScope: GuderianCommandScope
    public let playerQuality: GuderianOrderDiceQualityMix
    public let guderianQuality: GuderianOrderDiceQualityMix
    public let playerOrderDice: Int
    public let guderianOrderDice: Int
    public let expectedPinPressure: GuderianOrderDicePinPressure
    public let officerPresence: GuderianOrderDiceOfficerPresence
    public let vehicleClasses: [GuderianOrderDiceVehicleClass]
    public let terrainCategories: [GuderianOrderDiceTerrainCategory]
    public let retainedOrderUse: GuderianOrderDiceRetainedOrderUse
    public let scenarioNotes: String

    public var hasOrderDiceForBothSides: Bool {
        playerOrderDice > 0 && guderianOrderDice > 0
    }
}

public enum GuderianOrderDiceScenarioImpactCatalog {
    public static let cycleRange = 6...10

    public static var allRows: [GuderianOrderDiceScenarioImpact] {
        fieldCommandRows + lateCareerRows
    }

    public static var fieldCommandRows: [GuderianOrderDiceScenarioImpact] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map { scenario in
                let instance = NativeBattleInstanceCatalog.instance(for: scenario)
                return row(for: scenario, instance: instance)
            }
    }

    public static var lateCareerRows: [GuderianOrderDiceScenarioImpact] {
        UnifiedGuderianBattleCatalog.lateCareerEntries
            .sorted { $0.order < $1.order }
            .compactMap { entry in
                guard let battlefieldID = entry.id.lateCareerID,
                      let instance = LateCareerNativeBattleInstanceCatalog.instance(for: battlefieldID) else {
                    return nil
                }
                return row(for: entry, instance: instance)
            }
    }

    public static var acceptanceReadyThroughCycle10: Bool {
        let rows = allRows
        return cycleRange == 6...10 &&
            rows.count == UnifiedGuderianBattleCatalog.allEntries.count &&
            rows.count == 35 &&
            Set(rows.map(\.id)).count == 35 &&
            rows.allSatisfy(\.hasOrderDiceForBothSides) &&
            rows.allSatisfy { !$0.vehicleClasses.isEmpty && !$0.terrainCategories.isEmpty } &&
            rows.contains { $0.expectedPinPressure == .severe } &&
            rows.contains { $0.retainedOrderUse == .ambushAndDown }
    }

    public static func row(for id: UnifiedGuderianBattleID) -> GuderianOrderDiceScenarioImpact? {
        allRows.first { $0.id == id }
    }

    private static func row(
        for scenario: GuderianScenario,
        instance: NativeBattleInstance
    ) -> GuderianOrderDiceScenarioImpact {
        let playerUnits = instance.units.filter { $0.side == .player }
        let guderianUnits = instance.units.filter { $0.side == .guderianAI }
        return GuderianOrderDiceScenarioImpact(
            id: .fieldCommand(scenario.id),
            title: scenario.title,
            order: scenario.order,
            commandScope: GuderianCareerScopeCatalog.record(for: scenario.id)?.scope ?? .directFieldCommand,
            playerQuality: playerQuality(for: scenario),
            guderianQuality: guderianQuality(for: scenario),
            playerOrderDice: max(1, playerUnits.count),
            guderianOrderDice: max(1, guderianUnits.count),
            expectedPinPressure: pinPressure(for: scenario.playerPosture, terrain: instance.terrain),
            officerPresence: officerPresence(for: scenario),
            vehicleClasses: vehicleClasses(from: instance.units),
            terrainCategories: terrainCategories(from: instance.terrain),
            retainedOrderUse: retainedOrderUse(for: scenario.playerPosture, terrain: instance.terrain),
            scenarioNotes: "\(scenario.playerPosture.rawValue) in \(scenario.theater.rawValue); convert scripted pressure into activation choices before balance tuning."
        )
    }

    private static func row(
        for entry: UnifiedGuderianBattleEntry,
        instance: LateCareerNativeBattleInstance
    ) -> GuderianOrderDiceScenarioImpact {
        let playerUnits = instance.units.filter { $0.side == .player }
        let guderianUnits = instance.units.filter { $0.side == .guderianAI }
        return GuderianOrderDiceScenarioImpact(
            id: entry.id,
            title: entry.title,
            order: entry.order,
            commandScope: entry.commandScope,
            playerQuality: .regularVeteran,
            guderianQuality: .mixedMilitiaRegularVeteran,
            playerOrderDice: max(1, playerUnits.count),
            guderianOrderDice: max(1, guderianUnits.count),
            expectedPinPressure: lateCareerPinPressure(for: instance),
            officerPresence: .commandCritical,
            vehicleClasses: vehicleClasses(from: instance.units),
            terrainCategories: terrainCategories(from: instance.terrain),
            retainedOrderUse: lateCareerRetainedOrderUse(for: instance),
            scenarioNotes: "\(entry.commandScope.rawValue) caveat; keep order-dice play unified while preserving the command-study warning."
        )
    }

    private static func playerQuality(for scenario: GuderianScenario) -> GuderianOrderDiceQualityMix {
        switch scenario.theater {
        case .poland1939:
            return scenario.playerPosture == .fortifiedDelay ? .regularVeteran : .inexperiencedRegular
        case .france1940:
            return scenario.playerPosture == .counterattack ? .regularVeteran : .regular
        case .easternFront1941:
            if scenario.id == .mtsensk || scenario.id == .moscowTulaKashira {
                return .regularVeteran
            }
            return .mixedMilitiaRegularVeteran
        }
    }

    private static func guderianQuality(for scenario: GuderianScenario) -> GuderianOrderDiceQualityMix {
        switch scenario.theater {
        case .poland1939, .france1940:
            return .regularVeteran
        case .easternFront1941:
            return scenario.id == .moscowTulaKashira ? .regular : .regularVeteran
        }
    }

    private static func pinPressure(
        for posture: PlayerPosture,
        terrain: [NativeBattleTerrainFeature]
    ) -> GuderianOrderDicePinPressure {
        let denseTerrain = terrain.count >= 28
        switch posture {
        case .fortifiedDelay, .urbanDefense:
            return .severe
        case .evacuationDefense, .counterattack:
            return .heavy
        case .breakout:
            return denseTerrain ? .heavy : .moderate
        case .mobileDelay:
            return denseTerrain ? .heavy : .moderate
        }
    }

    private static func lateCareerPinPressure(for instance: LateCareerNativeBattleInstance) -> GuderianOrderDicePinPressure {
        if instance.terrain.contains(where: { $0.kind == .urbanDistrict || $0.kind == .fortifiedLine || $0.kind == .bunker }) {
            return .severe
        }
        if instance.units.contains(where: { $0.mobility == .armor || $0.mobility == .artillery }) {
            return .heavy
        }
        return .moderate
    }

    private static func officerPresence(for scenario: GuderianScenario) -> GuderianOrderDiceOfficerPresence {
        switch scenario.playerPosture {
        case .breakout:
            return .commandCritical
        case .fortifiedDelay, .urbanDefense, .evacuationDefense:
            return .local
        case .counterattack:
            return .strong
        case .mobileDelay:
            return .sparse
        }
    }

    private static func retainedOrderUse(
        for posture: PlayerPosture,
        terrain: [NativeBattleTerrainFeature]
    ) -> GuderianOrderDiceRetainedOrderUse {
        let hasFortification = terrain.contains { $0.kind == .bunker || $0.kind == .fortifiedLine || $0.kind == .urbanDistrict }
        switch posture {
        case .fortifiedDelay, .urbanDefense:
            return .ambushAndDown
        case .counterattack:
            return hasFortification ? .ambushAndDown : .ambushLikely
        case .evacuationDefense:
            return .downCommon
        case .breakout:
            return hasFortification ? .downCommon : .rare
        case .mobileDelay:
            return .ambushLikely
        }
    }

    private static func lateCareerRetainedOrderUse(for instance: LateCareerNativeBattleInstance) -> GuderianOrderDiceRetainedOrderUse {
        let terrain = Set(instance.terrain.map(\.kind))
        if terrain.contains(.urbanDistrict) || terrain.contains(.fortifiedLine) || terrain.contains(.bunker) {
            return .ambushAndDown
        }
        if terrain.contains(.forest) || terrain.contains(.ridge) || terrain.contains(.bridge) {
            return .ambushLikely
        }
        return .downCommon
    }

    private static func terrainCategories(from terrain: [NativeBattleTerrainFeature]) -> [GuderianOrderDiceTerrainCategory] {
        let categories = terrain.map { feature in
            switch feature.kind {
            case .road, .railway, .phaseLine:
                return GuderianOrderDiceTerrainCategory.road
            case .river, .canal, .lake, .ford, .ferry, .bridge:
                return .water
            case .marsh, .forest, .ridge:
                return .rough
            case .town, .village, .urbanDistrict:
                return .building
            case .bunker, .fortifiedLine:
                return .fortification
            case .objective, .artilleryPark, .airPressure:
                return .open
            }
        }
        return sortedUnique(categories)
    }

    private static func vehicleClasses(from units: [NativeBattleUnit]) -> [GuderianOrderDiceVehicleClass] {
        let classes = units.flatMap(classesForUnit)
        return sortedUnique(classes)
    }

    private static func classesForUnit(_ unit: NativeBattleUnit) -> [GuderianOrderDiceVehicleClass] {
        var classes: [GuderianOrderDiceVehicleClass]
        switch unit.mobility {
        case .infantry:
            classes = [.infantry]
        case .armor:
            classes = [armorClass(for: unit)]
        case .gun:
            classes = [.gun]
        case .artillery:
            classes = [.artillery]
        case .engineer:
            classes = [.engineer]
        case .command:
            classes = [.command]
        case .cavalry:
            classes = [.cavalry]
        case .armoredTrain:
            classes = [.armoredTrain]
        case .airPressure:
            classes = [.airPressure]
        case .navalSupport:
            classes = [.navalSupport]
        }

        let lowerName = "\(unit.name) \(unit.role)".lowercased()
        if lowerName.contains("half-track") || lowerName.contains("half track") {
            classes.append(.halfTrack)
        }
        if lowerName.contains("truck") || lowerName.contains("column") || lowerName.contains("transport") {
            classes.append(.softSkin)
        }
        if lowerName.contains("assault gun") || lowerName.contains("stug") {
            classes.append(.assaultGun)
        }
        return sortedUnique(classes)
    }

    private static func armorClass(for unit: NativeBattleUnit) -> GuderianOrderDiceVehicleClass {
        let lowerName = "\(unit.name) \(unit.role) \(unit.historicalNote)".lowercased()
        if lowerName.contains("kv") || lowerName.contains("t-34") || lowerName.contains("char b1") || lowerName.contains("heavy") {
            return .heavyArmor
        }
        if lowerName.contains("ft-17") || lowerName.contains("recon") || lowerName.contains("armored car") || lowerName.contains("armoured car") {
            return .lightArmor
        }
        return .mediumArmor
    }

    private static func sortedUnique<T: RawRepresentable & Hashable>(_ values: [T]) -> [T] where T.RawValue == String {
        Array(Set(values)).sorted { $0.rawValue < $1.rawValue }
    }
}

public enum GuderianOrderDiceCompatibilityShim {
    public static let cycleRange = 11...15

    public static let requiredOrders: [HistoricalBoardOrder] = [
        .fire,
        .advance,
        .run,
        .ambush,
        .rally,
        .down,
    ]

    public static let requiredSnapshotFields: [String] = [
        "currentOrder",
        "availableOrders",
        "orderDiceSummary",
        "pinCount",
        "moraleQuality",
        "retainedOrder",
        "downOrderActive",
        "ambushOrderActive",
    ]

    public static var dzwOrderContractReady: Bool {
        HistoricalBoardOrder.allCases == requiredOrders
    }

    public static var acceptanceReadyThroughCycle15: Bool {
        cycleRange == 11...15 &&
            dzwOrderContractReady &&
            Set(legacyPhaseMap.keys) == Set(NativeBoardPhase.allCasesForOrderDiceShim) &&
            requiredSnapshotFields.count == 8
    }

    public static var legacyPhaseMap: [NativeBoardPhase: HistoricalBoardOrder] {
        [
            .movement: .advance,
            .shooting: .fire,
            .assault: .run,
        ]
    }

    public static func preferredOrder(for phase: NativeBoardPhase) -> HistoricalBoardOrder {
        legacyPhaseMap[phase] ?? .advance
    }

    public static func preferredOrder(for phase: HistoricalBoardPhase) -> HistoricalBoardOrder {
        switch phase {
        case .movement:
            return .advance
        case .shooting:
            return .fire
        case .assault:
            return .run
        }
    }

    @discardableResult
    public static func issuePreferredOrderBeforeLegacyAction(
        in session: NativeBoardSession,
        unitID: Int,
        phase: NativeBoardPhase
    ) -> Bool {
        session.issueOrder(preferredOrder(for: phase), to: unitID)
    }
}

extension NativeBoardPhase {
    fileprivate static let allCasesForOrderDiceShim: [NativeBoardPhase] = [
        .movement,
        .shooting,
        .assault,
    ]
}

public struct GuderianOrderDicePhaseSurfaceGate: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let sourcePath: String
    public let forbiddenIdentifiers: [String]
    public let blockingCycle: Int
    public let replacementContract: String

    public init(
        id: String,
        sourcePath: String,
        forbiddenIdentifiers: [String],
        blockingCycle: Int,
        replacementContract: String
    ) {
        self.id = id
        self.sourcePath = sourcePath
        self.forbiddenIdentifiers = forbiddenIdentifiers
        self.blockingCycle = blockingCycle
        self.replacementContract = replacementContract
    }

    public func observedLegacyIdentifiers(in sourceText: String) -> [String] {
        forbiddenIdentifiers.filter { sourceText.contains($0) }
    }
}

public struct GuderianOrderDicePhaseSurfaceGateReport: Codable, Hashable, Sendable {
    public let gate: GuderianOrderDicePhaseSurfaceGate
    public let evaluatedCycle: Int
    public let observedLegacyIdentifiers: [String]

    public var isBlocking: Bool {
        evaluatedCycle >= gate.blockingCycle && !observedLegacyIdentifiers.isEmpty
    }

    public var isSatisfied: Bool {
        observedLegacyIdentifiers.isEmpty
    }
}

public struct GuderianOrderDiceMigrationAcceptanceReport: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let auditFindingCount: Int
    public let scenarioImpactRowCount: Int
    public let shimReady: Bool
    public let phaseSurfaceGateCount: Int
    public let gateReports: [GuderianOrderDicePhaseSurfaceGateReport]
    public let blockers: [String]

    public var isReadyThroughCycle20: Bool {
        blockers.isEmpty &&
            cycleStart == 1 &&
            cycleEnd == 20 &&
            auditFindingCount >= 10 &&
            scenarioImpactRowCount == 35 &&
            shimReady &&
            phaseSurfaceGateCount >= 2
    }
}

public enum GuderianOrderDiceAcceptanceCatalog {
    public static let cycleRange = 16...20

    public static let phaseSurfaceGates: [GuderianOrderDicePhaseSurfaceGate] = [
        GuderianOrderDicePhaseSurfaceGate(
            id: "macos-playable-phase-buttons",
            sourcePath: "Sources/GuderianApp/DZWPlayableBattleView.swift",
            forbiddenIdentifiers: [
                "battle-next-phase-button",
                "next-phase-button",
                "german-turn-button",
                "battle-phase-label",
            ],
            blockingCycle: 75,
            replacementContract: "The macOS playable battle surface must expose drawn die, order picker, order-test result, activation log, and turn-end state instead of phase controls."
        ),
        GuderianOrderDicePhaseSurfaceGate(
            id: "catalyst-playable-phase-buttons",
            sourcePath: "Sources/GuderianMacCatalyst/GuderianMacCatalystApp.swift",
            forbiddenIdentifiers: [
                "Phase",
                "advancePhase()",
                "snapshot.phase",
            ],
            blockingCycle: 75,
            replacementContract: "The Catalyst single-window surface must use the same compact order-dice command contract as macOS."
        ),
        GuderianOrderDicePhaseSurfaceGate(
            id: "autoplay-phase-budget",
            sourcePath: "Sources/GuderianCore/GuderianTestFirstBattleAutoplay.swift",
            forbiddenIdentifiers: [
                "phaseAdvances",
                "maxPhaseAdvances",
                "phaseBudgetRemaining",
            ],
            blockingCycle: 145,
            replacementContract: "GuderianTest must count activations and order-dice turn cleanup, not phase advances."
        ),
    ]

    public static var acceptanceReadyThroughCycle20: Bool {
        report().isReadyThroughCycle20
    }

    public static func gateReports(
        sourceTextByPath: [String: String],
        evaluatedCycle: Int
    ) -> [GuderianOrderDicePhaseSurfaceGateReport] {
        phaseSurfaceGates.map { gate in
            let sourceText = sourceTextByPath[gate.sourcePath] ?? ""
            return GuderianOrderDicePhaseSurfaceGateReport(
                gate: gate,
                evaluatedCycle: evaluatedCycle,
                observedLegacyIdentifiers: gate.observedLegacyIdentifiers(in: sourceText)
            )
        }
    }

    public static func report(
        sourceTextByPath: [String: String] = [:],
        evaluatedCycle: Int = 20
    ) -> GuderianOrderDiceMigrationAcceptanceReport {
        let gateReports = gateReports(
            sourceTextByPath: sourceTextByPath,
            evaluatedCycle: evaluatedCycle
        )
        var blockers: [String] = []
        if !GuderianOrderDiceAuditCatalog.acceptanceReadyThroughCycle5 {
            blockers.append("Cycle 1-5 DZW contract audit is incomplete.")
        }
        if !GuderianOrderDiceScenarioImpactCatalog.acceptanceReadyThroughCycle10 {
            blockers.append("Cycle 6-10 scenario impact map does not cover all 35 battles.")
        }
        if !GuderianOrderDiceCompatibilityShim.acceptanceReadyThroughCycle15 {
            blockers.append("Cycle 11-15 compile shim is not ready against DZW order contracts.")
        }
        if phaseSurfaceGates.count < 2 {
            blockers.append("Cycle 16-20 phase-surface retirement gates are missing.")
        }
        blockers.append(contentsOf: gateReports.filter(\.isBlocking).map { report in
            "\(report.gate.id) still contains \(report.observedLegacyIdentifiers.joined(separator: ", "))."
        })

        return GuderianOrderDiceMigrationAcceptanceReport(
            cycleStart: 1,
            cycleEnd: 20,
            auditFindingCount: GuderianOrderDiceAuditCatalog.findings.count,
            scenarioImpactRowCount: GuderianOrderDiceScenarioImpactCatalog.allRows.count,
            shimReady: GuderianOrderDiceCompatibilityShim.acceptanceReadyThroughCycle15,
            phaseSurfaceGateCount: phaseSurfaceGates.count,
            gateReports: gateReports,
            blockers: blockers
        )
    }
}

public enum GuderianOrderDiceForceFamily: String, CaseIterable, Codable, Hashable, Sendable {
    case polish = "Polish"
    case french = "French"
    case britishExpeditionary = "BEF"
    case belgianDutch = "Belgian/Dutch"
    case soviet1941 = "Soviet 1941"
    case sovietWinter = "Soviet winter"
    case germanEarlyWar = "German early-war"
    case germanEasternFront = "German Eastern Front"
    case lateWarGerman = "Late-war German"
    case lateCareerGenerated = "Late-career generated"
}

public enum GuderianOrderDiceMoraleQuality: String, CaseIterable, Codable, Hashable, Sendable {
    case inexperienced = "Inexperienced"
    case regular = "Regular"
    case veteran = "Veteran"
}

public struct GuderianOrderDiceUnitQualityAssignment: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: UnifiedGuderianBattleID
    public let battleTitle: String
    public let side: NativeBattleSide
    public let forceFamily: GuderianOrderDiceForceFamily
    public let unitName: String
    public let mobility: NativeBattleUnitMobility
    public let weaponRoles: [NativeBattleWeaponRole]
    public let moraleQuality: GuderianOrderDiceMoraleQuality
    public let reason: String

    public var isVehicleOrSupport: Bool {
        mobility != .infantry && mobility != .cavalry && mobility != .command
    }
}

public enum GuderianOrderDiceUnitQualityCatalog {
    public static let cycleRange = 21...25

    public static var allAssignments: [GuderianOrderDiceUnitQualityAssignment] {
        fieldCommandAssignments + lateCareerAssignments
    }

    public static var fieldCommandAssignments: [GuderianOrderDiceUnitQualityAssignment] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .flatMap { scenario -> [GuderianOrderDiceUnitQualityAssignment] in
                let instance = NativeBattleInstanceCatalog.instance(for: scenario)
                return instance.units.map { unit in
                    assignment(for: unit, battleID: .fieldCommand(scenario.id), title: scenario.title, scenario: scenario)
                }
            }
    }

    public static var lateCareerAssignments: [GuderianOrderDiceUnitQualityAssignment] {
        UnifiedGuderianBattleCatalog.lateCareerEntries
            .sorted { $0.order < $1.order }
            .compactMap { entry -> (UnifiedGuderianBattleEntry, LateCareerNativeBattleInstance)? in
                guard let battlefieldID = entry.id.lateCareerID,
                      let instance = LateCareerNativeBattleInstanceCatalog.instance(for: battlefieldID) else {
                    return nil
                }
                return (entry, instance)
            }
            .flatMap { entry, instance in
                instance.units.map { unit in
                    let family: GuderianOrderDiceForceFamily = unit.side == .guderianAI ? .lateWarGerman : .lateCareerGenerated
                    let quality = lateCareerQuality(for: unit, family: family, commandScope: entry.commandScope)
                    return GuderianOrderDiceUnitQualityAssignment(
                        id: "\(entry.id.rawValue)-\(unit.id)",
                        battleID: entry.id,
                        battleTitle: entry.title,
                        side: unit.side,
                        forceFamily: family,
                        unitName: unit.name,
                        mobility: unit.mobility,
                        weaponRoles: unit.weapons.map(\.role),
                        moraleQuality: quality,
                        reason: "\(family.rawValue) \(unit.mobility.rawValue) quality for \(entry.commandScope.rawValue) order-dice conversion."
                    )
                }
            }
    }

    public static var forceFamiliesCovered: Set<GuderianOrderDiceForceFamily> {
        Set(allAssignments.map(\.forceFamily))
    }

    public static var moraleQualitiesCovered: Set<GuderianOrderDiceMoraleQuality> {
        Set(allAssignments.map(\.moraleQuality))
    }

    public static var acceptanceReadyThroughCycle25: Bool {
        cycleRange == 21...25 &&
            !allAssignments.isEmpty &&
            forceFamiliesCovered.isSuperset(of: Set(GuderianOrderDiceForceFamily.allCases)) &&
            moraleQualitiesCovered == Set(GuderianOrderDiceMoraleQuality.allCases) &&
            allAssignments.contains { $0.forceFamily == .lateWarGerman && $0.moraleQuality == .regular } &&
            allAssignments.contains { $0.forceFamily == .sovietWinter && $0.moraleQuality == .veteran }
    }

    public static func assignments(for id: UnifiedGuderianBattleID) -> [GuderianOrderDiceUnitQualityAssignment] {
        allAssignments.filter { $0.battleID == id }
    }

    private static func assignment(
        for unit: NativeBattleUnit,
        battleID: UnifiedGuderianBattleID,
        title: String,
        scenario: GuderianScenario
    ) -> GuderianOrderDiceUnitQualityAssignment {
        let family = forceFamily(for: unit, scenario: scenario)
        let quality = moraleQuality(for: unit, scenario: scenario, family: family)
        return GuderianOrderDiceUnitQualityAssignment(
            id: "\(battleID.rawValue)-\(unit.id)",
            battleID: battleID,
            battleTitle: title,
            side: unit.side,
            forceFamily: family,
            unitName: unit.name,
            mobility: unit.mobility,
            weaponRoles: unit.weapons.map(\.role),
            moraleQuality: quality,
            reason: "\(family.rawValue) \(unit.mobility.rawValue) quality assigned for \(scenario.playerPosture.rawValue) order-dice play."
        )
    }

    private static func forceFamily(
        for unit: NativeBattleUnit,
        scenario: GuderianScenario
    ) -> GuderianOrderDiceForceFamily {
        if unit.side == .guderianAI {
            return scenario.theater == .easternFront1941 ? .germanEasternFront : .germanEarlyWar
        }

        switch scenario.theater {
        case .poland1939:
            return .polish
        case .france1940:
            if scenario.id == .boulogne || scenario.id == .calais {
                return unit.name.localizedCaseInsensitiveContains("belg") ? .belgianDutch : .britishExpeditionary
            }
            if scenario.id == .dunkirk {
                let lowerName = unit.name.lowercased()
                return lowerName.contains("dutch") || lowerName.contains("belgian") ? .belgianDutch : .britishExpeditionary
            }
            return .french
        case .easternFront1941:
            return scenario.id == .moscowTulaKashira ? .sovietWinter : .soviet1941
        }
    }

    private static func moraleQuality(
        for unit: NativeBattleUnit,
        scenario: GuderianScenario,
        family: GuderianOrderDiceForceFamily
    ) -> GuderianOrderDiceMoraleQuality {
        switch family {
        case .polish:
            if scenario.playerPosture == .fortifiedDelay || unit.mobility == .cavalry || unit.mobility == .armoredTrain {
                return .veteran
            }
            return unit.mobility == .armor ? .inexperienced : .regular
        case .french:
            if unit.mobility == .armor ||
                unit.mobility == .artillery ||
                unit.mobility == .command ||
                unit.weapons.contains(where: { $0.role == .armorGun || $0.role == .antiTank || $0.role == .artillery || $0.role == .command }) {
                return .veteran
            }
            return .regular
        case .britishExpeditionary:
            return unit.mobility == .command || unit.weapons.contains(where: { $0.role == .navalSupport }) ? .veteran : .regular
        case .belgianDutch:
            return .regular
        case .soviet1941:
            if unit.name.localizedCaseInsensitiveContains("guard") || unit.name.localizedCaseInsensitiveContains("tank") {
                return .veteran
            }
            return unit.mobility == .command ? .regular : .inexperienced
        case .sovietWinter:
            if unit.mobility == .command || unit.mobility == .armor || unit.name.localizedCaseInsensitiveContains("reserve") {
                return .veteran
            }
            return .regular
        case .germanEarlyWar:
            return unit.mobility == .command || unit.mobility == .armor || unit.mobility == .engineer ? .veteran : .regular
        case .germanEasternFront:
            return scenario.id == .moscowTulaKashira && unit.mobility == .infantry ? .regular : .veteran
        case .lateWarGerman, .lateCareerGenerated:
            return .regular
        }
    }

    private static func lateCareerQuality(
        for unit: NativeBattleUnit,
        family: GuderianOrderDiceForceFamily,
        commandScope: GuderianCommandScope
    ) -> GuderianOrderDiceMoraleQuality {
        if family == .lateWarGerman {
            return commandScope == .postDismissalContext ? .inexperienced : .regular
        }
        if unit.mobility == .armor || unit.mobility == .artillery || unit.mobility == .command {
            return .veteran
        }
        return .regular
    }
}

public struct GuderianOrderDiceSideCupReport: Codable, Hashable, Sendable {
    public let battleID: UnifiedGuderianBattleID
    public let title: String
    public let rulesetName: String
    public let playerDice: Int
    public let guderianDice: Int
    public let totalRemainingDice: Int
    public let replaySignature: UInt32
    public let eligiblePlayerUnits: Int
    public let eligibleGuderianUnits: Int
    public let blockers: [String]

    public var isReady: Bool {
        blockers.isEmpty &&
            rulesetName == "Order Dice" &&
            playerDice == eligiblePlayerUnits &&
            guderianDice == eligibleGuderianUnits &&
            totalRemainingDice == playerDice + guderianDice
    }
}

public enum GuderianOrderDiceSessionBootstrap {
    public static let cycleRange = 26...30

    public static func enableOrderDice(
        in session: NativeBoardSession
    ) -> GuderianOrderDiceSideCupReport {
        enableOrderDice(
            handle: session.handle,
            battleID: .fieldCommand(session.loadout.scenario.id),
            title: session.loadout.scenario.title
        )
    }

    public static func enableOrderDice(
        in session: LateCareerNativeBoardSession
    ) -> GuderianOrderDiceSideCupReport {
        enableOrderDice(
            handle: session.handle,
            battleID: .lateCareer(session.loadout.battlefield.id),
            title: session.loadout.battlefield.title
        )
    }

    public static var acceptanceReadyThroughCycle30: Bool {
        guard let fieldScenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
              let fieldSession = NativeBoardSession(scenario: fieldScenario, seed: 26_030),
              let lateID = UnifiedGuderianBattleCatalog.lateCareerEntries.first?.id.lateCareerID,
              let lateSession = LateCareerNativeBoardSession(battlefieldID: lateID, seed: 26_130) else {
            return false
        }

        return cycleRange == 26...30 &&
            enableOrderDice(in: fieldSession).isReady &&
            enableOrderDice(in: lateSession).isReady
    }

    private static func enableOrderDice(
        handle: OpaquePointer,
        battleID: UnifiedGuderianBattleID,
        title: String
    ) -> GuderianOrderDiceSideCupReport {
        var blockers: [String] = []
        if !game_set_ruleset(handle, DZW_RULESET_ORDER_DICE) {
            blockers.append("DZW refused the Order Dice ruleset.")
        }
        if !game_rebuild_order_dice_cup(handle) {
            blockers.append("DZW could not rebuild the order-dice cup.")
        }

        let playerDice = diceCount(in: handle, owner: DZW_PLAYER_ONE)
        let guderianDice = diceCount(in: handle, owner: DZW_PLAYER_TWO)
        let eligiblePlayerUnits = eligibleUnitCount(in: handle, owner: DZW_PLAYER_ONE)
        let eligibleGuderianUnits = eligibleUnitCount(in: handle, owner: DZW_PLAYER_TWO)
        let rulesetName = guderianCString(game_ruleset_name(game_view(handle).ruleset))

        if playerDice != eligiblePlayerUnits {
            blockers.append("Player order dice \(playerDice) did not match eligible units \(eligiblePlayerUnits).")
        }
        if guderianDice != eligibleGuderianUnits {
            blockers.append("Guderian order dice \(guderianDice) did not match eligible units \(eligibleGuderianUnits).")
        }

        return GuderianOrderDiceSideCupReport(
            battleID: battleID,
            title: title,
            rulesetName: rulesetName,
            playerDice: playerDice,
            guderianDice: guderianDice,
            totalRemainingDice: Int(game_order_dice_remaining_count(handle)),
            replaySignature: game_order_dice_replay_signature(handle),
            eligiblePlayerUnits: eligiblePlayerUnits,
            eligibleGuderianUnits: eligibleGuderianUnits,
            blockers: blockers
        )
    }

    private static func diceCount(in handle: OpaquePointer, owner: player_t) -> Int {
        let count = Int(game_order_dice_remaining_count(handle))
        return (0..<count)
            .map { game_order_dice_remaining_view(handle, Int32($0)) }
            .filter { $0.available && $0.owner == owner }
            .count
    }

    private static func eligibleUnitCount(in handle: OpaquePointer, owner: player_t) -> Int {
        (0..<Int(game_unit_count(handle)))
            .map { game_unit_view(handle, Int32($0)) }
            .filter { $0.owner == owner && orderDiceUnitCanReceiveDie($0) }
            .count
    }

    private static func orderDiceUnitCanReceiveDie(_ unit: unit_view_t) -> Bool {
        !unit.destroyed &&
            Int(unit.models) > 0 &&
            unit.owner != DZW_PLAYER_NONE &&
            !unit.embarked &&
            !unit.falling_back &&
            !unit.locked_in_assault &&
            !unit.acted_this_turn &&
            !unit.retained_order &&
            unit.current_order == DZW_ORDER_NONE
    }
}

public enum GuderianOrderDiceEligibilityCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case eligible = "Eligible"
    case commandCaveat = "Command caveat"
    case noDrawnDie = "No drawn die"
    case wrongSideDie = "Wrong-side die"
    case destroyed = "Destroyed"
    case embarked = "Embarked"
    case retainedOrder = "Retained order"
    case alreadyOrdered = "Already ordered"
    case pinnedOrderTest = "Pinned order test"
    case immobilizedVehicle = "Immobilized vehicle"
    case crewStunned = "Crew stunned"
    case lockedInAssault = "Locked in assault"
    case fallingBack = "Falling back"
    case unavailable = "Unavailable"
}

public struct GuderianOrderDiceEligibilityReason: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let unitID: Int
    public let order: HistoricalBoardOrder?
    public let category: GuderianOrderDiceEligibilityCategory
    public let message: String
    public let requiresOrderTest: Bool
}

public struct GuderianOrderDiceEligibilityReport: Codable, Hashable, Sendable {
    public let battleID: UnifiedGuderianBattleID
    public let unitID: Int
    public let unitName: String
    public let reasons: [GuderianOrderDiceEligibilityReason]

    public var categories: Set<GuderianOrderDiceEligibilityCategory> {
        Set(reasons.map(\.category))
    }

    public var hasOrderTestReason: Bool {
        reasons.contains { $0.requiresOrderTest || $0.category == .pinnedOrderTest }
    }
}

public enum GuderianOrderDiceEligibilityMapper {
    public static let cycleRange = 31...35

    public static var acceptanceReadyThroughCycle35: Bool {
        cycleRange == 31...35 &&
            category(for: "Destroyed units cannot receive orders.") == .destroyed &&
            category(for: "Embarked units cannot receive orders directly.") == .embarked &&
            category(for: "Unit is retaining an order.") == .retainedOrder &&
            category(for: "Pin markers require an order test.") == .pinnedOrderTest &&
            category(for: "Immobilized vehicles cannot receive movement orders.") == .immobilizedVehicle &&
            GuderianOrderDiceEligibilityCategory.allCases.contains(.commandCaveat)
    }

    public static func report(
        in session: NativeBoardSession,
        unitID: Int,
        commandCaveat: String? = nil
    ) -> GuderianOrderDiceEligibilityReport? {
        report(handle: session.handle, battleID: .fieldCommand(session.loadout.scenario.id), unitID: unitID, commandCaveat: commandCaveat)
    }

    public static func report(
        in session: LateCareerNativeBoardSession,
        unitID: Int,
        commandCaveat: String? = nil
    ) -> GuderianOrderDiceEligibilityReport? {
        report(handle: session.handle, battleID: .lateCareer(session.loadout.battlefield.id), unitID: unitID, commandCaveat: commandCaveat ?? session.loadout.battlefield.visibleCommandCaveatLabel)
    }

    public static func category(for reason: String) -> GuderianOrderDiceEligibilityCategory {
        let lower = reason.lowercased()
        if lower.contains("eligible") {
            return .eligible
        }
        if lower.contains("command caveat") || lower.contains("not a guderian field command") {
            return .commandCaveat
        }
        if lower.contains("draw an order die") {
            return .noDrawnDie
        }
        if lower.contains("opposing side") {
            return .wrongSideDie
        }
        if lower.contains("destroyed") {
            return .destroyed
        }
        if lower.contains("embarked") {
            return .embarked
        }
        if lower.contains("retaining") {
            return .retainedOrder
        }
        if lower.contains("already received") {
            return .alreadyOrdered
        }
        if lower.contains("pin") || lower.contains("order test") {
            return .pinnedOrderTest
        }
        if lower.contains("immobilized") {
            return .immobilizedVehicle
        }
        if lower.contains("crew stunned") {
            return .crewStunned
        }
        if lower.contains("close-quarters") || lower.contains("locked") {
            return .lockedInAssault
        }
        if lower.contains("falling back") {
            return .fallingBack
        }
        return .unavailable
    }

    private static func report(
        handle: OpaquePointer,
        battleID: UnifiedGuderianBattleID,
        unitID: Int,
        commandCaveat: String?
    ) -> GuderianOrderDiceEligibilityReport? {
        guard let unit = unitView(handle: handle, unitID: unitID) else {
            return nil
        }

        _ = game_set_ruleset(handle, DZW_RULESET_ORDER_DICE)
        var reasons: [GuderianOrderDiceEligibilityReason] = []
        if let commandCaveat, !commandCaveat.isEmpty {
            reasons.append(reason(unitID: unitID, order: nil, category: .commandCaveat, message: commandCaveat, requiresOrderTest: false))
        }
        if unit.destroyed {
            reasons.append(reason(unitID: unitID, order: nil, category: .destroyed, message: "Destroyed units cannot receive orders.", requiresOrderTest: false))
        }
        if unit.embarked {
            reasons.append(reason(unitID: unitID, order: nil, category: .embarked, message: "Embarked units cannot receive orders directly.", requiresOrderTest: false))
        }
        if unit.retained_order {
            reasons.append(reason(unitID: unitID, order: nil, category: .retainedOrder, message: "Unit is retaining an order.", requiresOrderTest: false))
        }
        if unit.pin_count > 0 {
            reasons.append(reason(unitID: unitID, order: nil, category: .pinnedOrderTest, message: "Pin markers require an order test.", requiresOrderTest: true))
        }
        if let movementReason = optionalCString(unit.movement_rejection_reason), !movementReason.isEmpty {
            let category = category(for: movementReason)
            if category != .eligible {
                reasons.append(reason(unitID: unitID, order: nil, category: category, message: movementReason, requiresOrderTest: false))
            }
        }

        reasons.append(contentsOf: HistoricalBoardOrder.allCases.map { order in
            let eligibility = game_unit_order_eligibility_view(handle, Int32(unitID), order.guderianCValue)
            let message = guderianCString(eligibility.reason)
            return reason(
                unitID: unitID,
                order: order,
                category: category(for: message),
                message: message,
                requiresOrderTest: eligibility.requires_order_test
            )
        })

        return GuderianOrderDiceEligibilityReport(
            battleID: battleID,
            unitID: unitID,
            unitName: guderianCString(unit.name),
            reasons: reasons
        )
    }

    private static func reason(
        unitID: Int,
        order: HistoricalBoardOrder?,
        category: GuderianOrderDiceEligibilityCategory,
        message: String,
        requiresOrderTest: Bool
    ) -> GuderianOrderDiceEligibilityReason {
        GuderianOrderDiceEligibilityReason(
            id: "\(unitID)-\(order?.rawValue ?? category.rawValue)-\(message)",
            unitID: unitID,
            order: order,
            category: category,
            message: message,
            requiresOrderTest: requiresOrderTest
        )
    }
}

public enum GuderianOrderDiceMovementClass: String, CaseIterable, Codable, Hashable, Sendable {
    case openAdvanceRun = "Open Advance/Run"
    case roughAdvanceOnly = "Rough Advance only"
    case obstacleAdvanceCheck = "Obstacle Advance check"
    case buildingEntry = "Building entry"
    case roadRunBonus = "Road Run bonus"
    case waterCrossingLimited = "Water crossing limited"
    case fortifiedCover = "Fortified cover"
}

public struct GuderianOrderDiceSetupMigrationRow: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let title: String
    public let movementClasses: [GuderianOrderDiceMovementClass]
    public let deploymentOpeningOrders: [HistoricalBoardOrder]
    public let objectiveOrders: [HistoricalBoardOrder]
    public let eventOrders: [HistoricalBoardOrder]
    public let notes: [String]

    public var isReady: Bool {
        !movementClasses.isEmpty &&
            deploymentOpeningOrders.contains(.advance) &&
            !objectiveOrders.isEmpty &&
            !eventOrders.isEmpty &&
            !notes.isEmpty
    }
}

public enum GuderianOrderDiceSetupMigrationCatalog {
    public static let cycleRange = 36...40

    public static var allRows: [GuderianOrderDiceSetupMigrationRow] {
        fieldCommandRows + lateCareerRows
    }

    public static var fieldCommandRows: [GuderianOrderDiceSetupMigrationRow] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map { scenario in
                let instance = NativeBattleInstanceCatalog.instance(for: scenario)
                return row(id: .fieldCommand(scenario.id), title: scenario.title, terrain: instance.terrain, objectives: instance.objectives, events: instance.events, posture: scenario.playerPosture.rawValue)
            }
    }

    public static var lateCareerRows: [GuderianOrderDiceSetupMigrationRow] {
        UnifiedGuderianBattleCatalog.lateCareerEntries
            .sorted { $0.order < $1.order }
            .compactMap { entry in
                guard let battlefieldID = entry.id.lateCareerID,
                      let instance = LateCareerNativeBattleInstanceCatalog.instance(for: battlefieldID) else {
                    return nil
                }
                return row(id: entry.id, title: entry.title, terrain: instance.terrain, objectives: instance.objectives, events: instance.events, posture: entry.commandScope.rawValue)
            }
    }

    public static var acceptanceReadyThroughCycle40: Bool {
        let rows = allRows
        return cycleRange == 36...40 &&
            rows.count == 35 &&
            rows.allSatisfy(\.isReady) &&
            rows.contains { $0.movementClasses.contains(.roadRunBonus) } &&
            rows.contains { $0.movementClasses.contains(.roughAdvanceOnly) } &&
            rows.contains { $0.objectiveOrders.contains(.rally) || $0.eventOrders.contains(.rally) }
    }

    private static func row(
        id: UnifiedGuderianBattleID,
        title: String,
        terrain: [NativeBattleTerrainFeature],
        objectives: [NativeBattleObjective],
        events: [NativeBattleEventTrigger],
        posture: String
    ) -> GuderianOrderDiceSetupMigrationRow {
        GuderianOrderDiceSetupMigrationRow(
            id: id,
            title: title,
            movementClasses: sortedUnique(terrain.map(movementClass)),
            deploymentOpeningOrders: [.advance, .run, .down],
            objectiveOrders: sortedUnique(objectives.flatMap(ordersForObjective)),
            eventOrders: sortedUnique(events.flatMap(ordersForEvent)),
            notes: [
                "\(posture) setup uses DZW order/movement categories.",
                "Deployment opens with Advance/Run choices while Down remains available for pinned or exposed units.",
                "Objectives and scripted events are classified into order intents before UI conversion.",
            ]
        )
    }

    private static func movementClass(for terrain: NativeBattleTerrainFeature) -> GuderianOrderDiceMovementClass {
        switch terrain.kind {
        case .road, .railway, .phaseLine:
            return .roadRunBonus
        case .river, .canal, .lake, .ford, .ferry, .bridge:
            return .waterCrossingLimited
        case .marsh, .forest, .ridge:
            return .roughAdvanceOnly
        case .town, .village, .urbanDistrict:
            return .buildingEntry
        case .bunker, .fortifiedLine:
            return .fortifiedCover
        case .objective, .artilleryPark, .airPressure:
            return .openAdvanceRun
        }
    }

    private static func ordersForObjective(_ objective: NativeBattleObjective) -> [HistoricalBoardOrder] {
        switch objective.kind {
        case .hold, .delay, .preserve:
            return [.advance, .down, .ambush, .rally]
        case .withdraw, .evacuate, .breakout:
            return [.advance, .run, .rally]
        case .disrupt, .counterattack:
            return [.advance, .fire, .run]
        case .deny:
            return [.fire, .ambush, .down]
        case .score:
            return [.advance, .fire]
        }
    }

    private static func ordersForEvent(_ event: NativeBattleEventTrigger) -> [HistoricalBoardOrder] {
        switch event.kind {
        case .trigger:
            return [.advance, .fire]
        case .reinforcement:
            return [.run, .advance]
        case .pacing:
            return [.rally, .down]
        case .tutorial:
            return [.advance]
        }
    }

    private static func sortedUnique<T: RawRepresentable & Hashable>(_ values: [T]) -> [T] where T.RawValue == String {
        Array(Set(values)).sorted { $0.rawValue < $1.rawValue }
    }
}

public struct GuderianOrderDiceMigrationCycle40Report: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let qualityAssignments: Int
    public let sideCupFieldReady: Bool
    public let sideCupLateCareerReady: Bool
    public let eligibilityReady: Bool
    public let setupRows: Int
    public let blockers: [String]

    public var isReadyThroughCycle40: Bool {
        blockers.isEmpty &&
            cycleStart == 21 &&
            cycleEnd == 40 &&
            qualityAssignments > 0 &&
            sideCupFieldReady &&
            sideCupLateCareerReady &&
            eligibilityReady &&
            setupRows == 35
    }
}

public enum GuderianOrderDiceMigrationCycle40AcceptanceCatalog {
    public static let cycleRange = 21...40

    public static var acceptanceReadyThroughCycle40: Bool {
        report().isReadyThroughCycle40
    }

    public static func report() -> GuderianOrderDiceMigrationCycle40Report {
        var blockers: [String] = []
        if !GuderianOrderDiceUnitQualityCatalog.acceptanceReadyThroughCycle25 {
            blockers.append("Cycle 21-25 unit quality assignment is incomplete.")
        }
        if !GuderianOrderDiceSessionBootstrap.acceptanceReadyThroughCycle30 {
            blockers.append("Cycle 26-30 order-dice side-cup bootstrap is incomplete.")
        }
        if !GuderianOrderDiceEligibilityMapper.acceptanceReadyThroughCycle35 {
            blockers.append("Cycle 31-35 eligibility mapping is incomplete.")
        }
        if !GuderianOrderDiceSetupMigrationCatalog.acceptanceReadyThroughCycle40 {
            blockers.append("Cycle 36-40 setup migration is incomplete.")
        }

        let fieldReady: Bool
        if let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
           let session = NativeBoardSession(scenario: scenario, seed: 40_021) {
            fieldReady = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session).isReady
        } else {
            fieldReady = false
        }
        let lateReady: Bool
        if let lateID = UnifiedGuderianBattleCatalog.lateCareerEntries.first?.id.lateCareerID,
           let session = LateCareerNativeBoardSession(battlefieldID: lateID, seed: 40_022) {
            lateReady = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session).isReady
        } else {
            lateReady = false
        }

        return GuderianOrderDiceMigrationCycle40Report(
            cycleStart: 21,
            cycleEnd: 40,
            qualityAssignments: GuderianOrderDiceUnitQualityCatalog.allAssignments.count,
            sideCupFieldReady: fieldReady,
            sideCupLateCareerReady: lateReady,
            eligibilityReady: GuderianOrderDiceEligibilityMapper.acceptanceReadyThroughCycle35,
            setupRows: GuderianOrderDiceSetupMigrationCatalog.allRows.count,
            blockers: blockers
        )
    }
}

public struct GuderianOrderDiceSideOwnershipBinding: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: UnifiedGuderianBattleID
    public let title: String
    public let chosenHumanSideID: String
    public let selectedSideTitle: String
    public let opposingSideTitle: String
    public let humanPlayer: NativeBoardPlayer
    public let aiPlayer: NativeBoardPlayer
    public let humanDice: Int
    public let aiDice: Int
    public let blockers: [String]

    public var canHumanControlDrawnDice: Bool {
        humanDice > 0
    }

    public var isReady: Bool {
        blockers.isEmpty &&
            humanPlayer != .none &&
            aiPlayer != .none &&
            humanPlayer != aiPlayer &&
            humanDice > 0 &&
            aiDice > 0 &&
            !selectedSideTitle.isEmpty &&
            !opposingSideTitle.isEmpty
    }
}

public enum GuderianOrderDiceSideOwnershipCatalog {
    public static let cycleRange = 41...45
    public static let sideIDs = [
        GuderianHistoricalSideID.guderianCommand,
        GuderianHistoricalSideID.opposingForce,
    ]

    public static var allBindings: [GuderianOrderDiceSideOwnershipBinding] {
        fieldCommandBindings + lateCareerBindings
    }

    public static var fieldCommandBindings: [GuderianOrderDiceSideOwnershipBinding] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .flatMap { scenario in
                sideIDs.map { sideID in
                    fieldCommandBinding(for: scenario, chosenHumanSideID: sideID)
                }
            }
    }

    public static var lateCareerBindings: [GuderianOrderDiceSideOwnershipBinding] {
        LateCareerGuderianPresentationCatalog.allEntries
            .sorted { $0.order < $1.order }
            .flatMap { entry in
                sideIDs.map { sideID in
                    lateCareerBinding(for: entry, chosenHumanSideID: sideID)
                }
            }
    }

    public static var acceptanceReadyThroughCycle45: Bool {
        cycleRange == 41...45 &&
            allBindings.count == 70 &&
            allBindings.allSatisfy(\.isReady) &&
            allBindings.contains { $0.chosenHumanSideID == GuderianHistoricalSideID.guderianCommand && $0.humanPlayer == .guderianAI } &&
            allBindings.contains { $0.chosenHumanSideID == GuderianHistoricalSideID.opposingForce && $0.humanPlayer == .player }
    }

    public static func binding(
        for battleID: UnifiedGuderianBattleID,
        chosenHumanSideID: String
    ) -> GuderianOrderDiceSideOwnershipBinding? {
        allBindings.first { $0.battleID == battleID && $0.chosenHumanSideID == chosenHumanSideID }
    }

    private static func fieldCommandBinding(
        for scenario: GuderianScenario,
        chosenHumanSideID: String
    ) -> GuderianOrderDiceSideOwnershipBinding {
        var blockers: [String] = []
        let battleID = UnifiedGuderianBattleID.fieldCommand(scenario.id)
        let humanPlayer = GuderianHistoricalSideSelectionResolver.nativePlayer(for: chosenHumanSideID) ?? .none
        let aiPlayer: NativeBoardPlayer = humanPlayer == .guderianAI ? .player : .guderianAI
        let selectedTitle = GuderianHistoricalScenarioAdapter.scenario(for: scenario).sideOption(id: chosenHumanSideID)?.title ?? ""
        let opposingTitle = GuderianHistoricalScenarioAdapter.scenario(for: scenario).opposingSideOption(to: chosenHumanSideID)?.title ?? ""

        guard let launch = try? GuderianHistoricalSideSelectionResolver.makeLaunch(
            for: scenario,
            chosenHumanSideID: chosenHumanSideID,
            seed: UInt32(41_000 + scenario.order)
        ), let session = NativeBoardSession(scenario: scenario, launch: launch) else {
            return GuderianOrderDiceSideOwnershipBinding(
                id: "\(battleID.rawValue)-\(chosenHumanSideID)",
                battleID: battleID,
                title: scenario.title,
                chosenHumanSideID: chosenHumanSideID,
                selectedSideTitle: selectedTitle,
                opposingSideTitle: opposingTitle,
                humanPlayer: humanPlayer,
                aiPlayer: aiPlayer,
                humanDice: 0,
                aiDice: 0,
                blockers: ["Could not launch field-command order-dice session."]
            )
        }

        let report = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        blockers.append(contentsOf: report.blockers)
        if session.humanPlayer != humanPlayer {
            blockers.append("Historical side selection did not bind the expected human engine owner.")
        }
        return GuderianOrderDiceSideOwnershipBinding(
            id: "\(battleID.rawValue)-\(chosenHumanSideID)",
            battleID: battleID,
            title: scenario.title,
            chosenHumanSideID: chosenHumanSideID,
            selectedSideTitle: selectedTitle,
            opposingSideTitle: opposingTitle,
            humanPlayer: humanPlayer,
            aiPlayer: aiPlayer,
            humanDice: diceCount(from: report, for: humanPlayer),
            aiDice: diceCount(from: report, for: aiPlayer),
            blockers: blockers
        )
    }

    private static func lateCareerBinding(
        for entry: LateCareerGuderianPresentation,
        chosenHumanSideID: String
    ) -> GuderianOrderDiceSideOwnershipBinding {
        var blockers: [String] = []
        let battleID = UnifiedGuderianBattleID.lateCareer(entry.id)
        let humanPlayer = UnifiedGuderianBattleSideSelectionCatalog.nativePlayer(for: chosenHumanSideID) ?? .none
        let aiPlayer: NativeBoardPlayer = humanPlayer == .guderianAI ? .player : .guderianAI
        guard let session = LateCareerNativeBoardSession(battlefieldID: entry.id, seed: UInt32(41_500 + entry.order)) else {
            return GuderianOrderDiceSideOwnershipBinding(
                id: "\(battleID.rawValue)-\(chosenHumanSideID)",
                battleID: battleID,
                title: entry.title,
                chosenHumanSideID: chosenHumanSideID,
                selectedSideTitle: UnifiedGuderianBattleSideSelectionCatalog.selectedSideTitle(for: chosenHumanSideID, in: entry),
                opposingSideTitle: UnifiedGuderianBattleSideSelectionCatalog.opposingSideTitle(to: chosenHumanSideID, in: entry),
                humanPlayer: humanPlayer,
                aiPlayer: aiPlayer,
                humanDice: 0,
                aiDice: 0,
                blockers: ["Could not launch late-career order-dice session."]
            )
        }

        let report = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        blockers.append(contentsOf: report.blockers)
        return GuderianOrderDiceSideOwnershipBinding(
            id: "\(battleID.rawValue)-\(chosenHumanSideID)",
            battleID: battleID,
            title: entry.title,
            chosenHumanSideID: chosenHumanSideID,
            selectedSideTitle: UnifiedGuderianBattleSideSelectionCatalog.selectedSideTitle(for: chosenHumanSideID, in: entry),
            opposingSideTitle: UnifiedGuderianBattleSideSelectionCatalog.opposingSideTitle(to: chosenHumanSideID, in: entry),
            humanPlayer: humanPlayer,
            aiPlayer: aiPlayer,
            humanDice: diceCount(from: report, for: humanPlayer),
            aiDice: diceCount(from: report, for: aiPlayer),
            blockers: blockers
        )
    }

    private static func diceCount(
        from report: GuderianOrderDiceSideCupReport,
        for player: NativeBoardPlayer
    ) -> Int {
        switch player {
        case .player:
            return report.playerDice
        case .guderianAI:
            return report.guderianDice
        case .none:
            return 0
        }
    }
}

public struct GuderianOrderDiceCommandPanelState: Codable, Hashable, Sendable {
    public let drawnSideTitle: String
    public let humanSideTitle: String
    public let canHumanControlDrawnDie: Bool
    public let eligibleUnitIDs: [Int]
    public let eligibleUnitNames: [String]
    public let selectedUnitID: Int?
    public let selectedUnitName: String?
    public let orderPickerOptions: [HistoricalBoardOrder]
    public let orderTestResultSummary: String
    public let actionExecutionSummary: String
    public let turnEndStatus: String

    public var isReady: Bool {
        !drawnSideTitle.isEmpty &&
            !humanSideTitle.isEmpty &&
            !eligibleUnitIDs.isEmpty &&
            !orderPickerOptions.isEmpty &&
            !orderTestResultSummary.isEmpty &&
            !actionExecutionSummary.isEmpty &&
            !turnEndStatus.isEmpty
    }
}

public enum GuderianOrderDiceCommandPanelPresenter {
    public static let cycleRange = 46...50

    public static func state(
        snapshot: NativeBoardSnapshot,
        humanPlayer: NativeBoardPlayer,
        humanSideTitle: String,
        activeSideTitle: String
    ) -> GuderianOrderDiceCommandPanelState {
        let eligibleUnits = snapshot.units
            .filter { $0.owner == humanPlayer && !$0.destroyed && !$0.retainedOrder && $0.currentOrder == nil }
            .sorted { $0.id < $1.id }
        let selected = snapshot.selectedUnit?.owner == humanPlayer ? snapshot.selectedUnit : eligibleUnits.first
        let orderOptions = selected.map(orderOptions(for:)) ?? HistoricalBoardOrder.allCases
        return GuderianOrderDiceCommandPanelState(
            drawnSideTitle: activeSideTitle,
            humanSideTitle: humanSideTitle,
            canHumanControlDrawnDie: snapshot.activePlayer == humanPlayer,
            eligibleUnitIDs: eligibleUnits.map(\.id),
            eligibleUnitNames: eligibleUnits.map(\.name),
            selectedUnitID: selected?.id,
            selectedUnitName: selected?.name,
            orderPickerOptions: orderOptions,
            orderTestResultSummary: orderTestSummary(for: selected),
            actionExecutionSummary: actionExecutionSummary(for: selected, options: orderOptions),
            turnEndStatus: turnEndStatus(for: snapshot)
        )
    }

    public static var acceptanceReadyThroughCycle50: Bool {
        guard let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
              let session = NativeBoardSession(scenario: scenario, seed: 50_001) else {
            return false
        }
        _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        let snapshot = session.snapshot()
        let state = state(
            snapshot: snapshot,
            humanPlayer: .player,
            humanSideTitle: GuderianHistoricalSideSelectionResolver.sideTitle(for: .player, in: scenario),
            activeSideTitle: GuderianHistoricalSideSelectionResolver.sideTitle(for: snapshot.activePlayer, in: scenario)
        )
        return cycleRange == 46...50 &&
            state.isReady &&
            state.orderPickerOptions == HistoricalBoardOrder.allCases &&
            state.drawnSideTitle.contains("Polish")
    }

    private static func orderOptions(for unit: NativeBoardUnitSnapshot) -> [HistoricalBoardOrder] {
        unit.availableOrders.isEmpty ? HistoricalBoardOrder.allCases : unit.availableOrders
    }

    private static func orderTestSummary(for unit: NativeBoardUnitSnapshot?) -> String {
        guard let unit else {
            return "Select a unit to see order-test pressure."
        }
        if unit.pinCount > 0 {
            return "\(unit.pinCount) pin marker\(unit.pinCount == 1 ? "" : "s") may require an order test."
        }
        return "No order test currently required for \(unit.name)."
    }

    private static func actionExecutionSummary(
        for unit: NativeBoardUnitSnapshot?,
        options: [HistoricalBoardOrder]
    ) -> String {
        guard let unit else {
            return "Draw a side and select an eligible unit before execution."
        }
        if let order = unit.currentOrder {
            return "\(unit.name) is executing \(order.rawValue)."
        }
        return "\(unit.name) can choose \(options.map(\.rawValue).joined(separator: ", "))."
    }

    private static func turnEndStatus(for snapshot: NativeBoardSnapshot) -> String {
        let unorderedActiveUnits = snapshot.units.filter {
            $0.owner == snapshot.activePlayer && !$0.destroyed && !$0.retainedOrder && $0.currentOrder == nil
        }
        if unorderedActiveUnits.isEmpty {
            return "No unassigned active-side units remain before order-dice cleanup."
        }
        return "\(unorderedActiveUnits.count) active-side unit\(unorderedActiveUnits.count == 1 ? "" : "s") still await an order."
    }
}

public struct GuderianOrderDiceInspectorState: Codable, Hashable, Sendable {
    public let unitID: Int
    public let unitName: String
    public let pinCount: Int
    public let moraleQuality: String
    public let currentOrderLabel: String
    public let retainedOrder: Bool
    public let actedState: String
    public let downDetails: String
    public let ambushDetails: String
    public let rallyDetails: String
    public let officerModifierSummary: String
    public let fubarSummary: String
    public let orderDiceSummary: String

    public var isReady: Bool {
        !unitName.isEmpty &&
            !moraleQuality.isEmpty &&
            !currentOrderLabel.isEmpty &&
            !actedState.isEmpty &&
            !downDetails.isEmpty &&
            !ambushDetails.isEmpty &&
            !rallyDetails.isEmpty &&
            !officerModifierSummary.isEmpty &&
            !fubarSummary.isEmpty
    }
}

public enum GuderianOrderDiceInspectorPresenter {
    public static let cycleRange = 51...55

    public static func state(for unit: NativeBoardUnitSnapshot) -> GuderianOrderDiceInspectorState {
        let summary = unit.orderDiceSummary.isEmpty ? "Order \(unit.currentOrder?.rawValue ?? "None") | \(unit.moraleQuality) | Pins \(unit.pinCount)" : unit.orderDiceSummary
        return GuderianOrderDiceInspectorState(
            unitID: unit.id,
            unitName: unit.name,
            pinCount: unit.pinCount,
            moraleQuality: unit.moraleQuality,
            currentOrderLabel: unit.currentOrder?.rawValue ?? "None",
            retainedOrder: unit.retainedOrder,
            actedState: unit.currentOrder == nil ? "Awaiting order" : "Order assigned",
            downDetails: unit.downOrderActive ? "Down order active" : "Down order inactive",
            ambushDetails: unit.ambushOrderActive ? "Ambush retained" : "Ambush inactive",
            rallyDetails: unit.currentOrder == .rally ? "Rally order selected" : "Rally available through the order picker",
            officerModifierSummary: summary.localizedCaseInsensitiveContains("officer") ? summary : "Officer modifiers surface in DZW order-test summaries when present.",
            fubarSummary: summary.localizedCaseInsensitiveContains("fubar") ? summary : "No FUBAR result recorded.",
            orderDiceSummary: summary
        )
    }

    public static var acceptanceReadyThroughCycle55: Bool {
        guard let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
              let session = NativeBoardSession(scenario: scenario, seed: 55_001) else {
            return false
        }
        _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        guard let unit = session.snapshot().selectedUnit else {
            return false
        }
        let state = state(for: unit)
        return cycleRange == 51...55 &&
            state.isReady &&
            state.pinCount >= 0 &&
            state.currentOrderLabel == "None" &&
            state.orderDiceSummary.contains("Pins")
    }
}

public struct GuderianOrderDiceMovementPreviewState: Codable, Hashable, Sendable {
    public let unitID: Int
    public let unitName: String
    public let advanceMoveAllowance: Double
    public let runMoveAllowance: Double
    public let currentOrderMoveAllowance: Double
    public let reverseMoveAllowance: Double
    public let canReverseNow: Bool
    public let pivotBudget: Int
    public let pivotCountUsed: Int
    public let terrainClasses: [GuderianOrderDiceMovementClass]
    public let movementRejectionReason: String
    public let advanceEnabled: Bool
    public let runEnabled: Bool
    public let roadRoughObstacleMessage: String

    public var isReady: Bool {
        !unitName.isEmpty &&
            advanceMoveAllowance >= 0 &&
            runMoveAllowance >= advanceMoveAllowance &&
            pivotBudget >= pivotCountUsed &&
            !terrainClasses.isEmpty &&
            !roadRoughObstacleMessage.isEmpty
    }
}

public enum GuderianOrderDiceMovementPreviewPresenter {
    public static let cycleRange = 56...60

    public static func state(
        snapshot: NativeBoardSnapshot,
        battleID: UnifiedGuderianBattleID
    ) -> GuderianOrderDiceMovementPreviewState? {
        guard let selected = snapshot.selectedUnit else {
            return nil
        }
        let setup = GuderianOrderDiceSetupMigrationCatalog.allRows.first { $0.id == battleID }
        let terrainClasses = setup?.movementClasses ?? [.openAdvanceRun]
        return GuderianOrderDiceMovementPreviewState(
            unitID: selected.id,
            unitName: selected.name,
            advanceMoveAllowance: selected.advanceMoveAllowance,
            runMoveAllowance: selected.runMoveAllowance,
            currentOrderMoveAllowance: selected.currentOrderMoveAllowance,
            reverseMoveAllowance: selected.reverseMoveAllowance,
            canReverseNow: selected.canReverseNow,
            pivotBudget: selected.pivotBudget,
            pivotCountUsed: selected.pivotCountUsed,
            terrainClasses: terrainClasses,
            movementRejectionReason: selected.movementRejectionReason,
            advanceEnabled: selected.advanceMoveAllowance > 0 && !selected.destroyed,
            runEnabled: selected.runMoveAllowance > 0 && !selected.destroyed,
            roadRoughObstacleMessage: message(for: terrainClasses, unit: selected)
        )
    }

    public static var acceptanceReadyThroughCycle60: Bool {
        guard let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
              let session = NativeBoardSession(scenario: scenario, seed: 60_001) else {
            return false
        }
        _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        guard let state = state(snapshot: session.snapshot(), battleID: .fieldCommand(.tucholaForest)) else {
            return false
        }
        return cycleRange == 56...60 &&
            state.isReady &&
            state.advanceMoveAllowance > 0 &&
            state.runMoveAllowance >= state.advanceMoveAllowance &&
            state.terrainClasses.contains(.roadRunBonus)
    }

    private static func message(
        for terrainClasses: [GuderianOrderDiceMovementClass],
        unit: NativeBoardUnitSnapshot
    ) -> String {
        var parts: [String] = []
        if terrainClasses.contains(.roadRunBonus) {
            parts.append("Roads favor Run movement.")
        }
        if terrainClasses.contains(.roughAdvanceOnly) {
            parts.append("Rough ground favors Advance movement.")
        }
        if terrainClasses.contains(.waterCrossingLimited) || terrainClasses.contains(.obstacleAdvanceCheck) {
            parts.append("Crossings and obstacles can reject overlong movement.")
        }
        if unit.pivotBudget > 0 {
            parts.append("Vehicle pivot budget \(unit.pivotCountUsed)/\(unit.pivotBudget).")
        }
        if parts.isEmpty {
            parts.append("Open ground supports normal Advance and Run previews.")
        }
        return parts.joined(separator: " ")
    }
}

public struct GuderianOrderDiceMigrationCycle60Report: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let sideBindings: Int
    public let sideSelectionReady: Bool
    public let commandPanelReady: Bool
    public let inspectorReady: Bool
    public let movementPreviewReady: Bool
    public let missingUISourceIdentifiers: [String]
    public let blockers: [String]

    public var isReadyThroughCycle60: Bool {
        blockers.isEmpty &&
            cycleStart == 41 &&
            cycleEnd == 60 &&
            sideBindings == 70 &&
            sideSelectionReady &&
            commandPanelReady &&
            inspectorReady &&
            movementPreviewReady &&
            missingUISourceIdentifiers.isEmpty
    }
}

public enum GuderianOrderDiceMigrationCycle60AcceptanceCatalog {
    public static let cycleRange = 41...60
    public static let requiredUISourceIdentifiers = [
        "order-dice-command-panel",
        "order-drawn-side",
        "order-eligible-units-list",
        "order-picker",
        "order-test-result",
        "order-action-execution",
        "order-turn-end-status",
        "order-inspector-summary",
        "order-movement-preview",
        "advance-move-preview",
        "run-move-preview",
        "vehicle-pivot-budget",
    ]

    public static func acceptanceReadyThroughCycle60(sourceText: String) -> Bool {
        report(sourceText: sourceText).isReadyThroughCycle60
    }

    public static func report(sourceText: String) -> GuderianOrderDiceMigrationCycle60Report {
        let missingIdentifiers = requiredUISourceIdentifiers.filter { !sourceText.contains($0) }
        var blockers: [String] = []
        if !GuderianOrderDiceSideOwnershipCatalog.acceptanceReadyThroughCycle45 {
            blockers.append("Cycle 41-45 side ownership binding is incomplete.")
        }
        if !GuderianOrderDiceCommandPanelPresenter.acceptanceReadyThroughCycle50 {
            blockers.append("Cycle 46-50 command panel presenter is incomplete.")
        }
        if !GuderianOrderDiceInspectorPresenter.acceptanceReadyThroughCycle55 {
            blockers.append("Cycle 51-55 inspector presenter is incomplete.")
        }
        if !GuderianOrderDiceMovementPreviewPresenter.acceptanceReadyThroughCycle60 {
            blockers.append("Cycle 56-60 movement preview presenter is incomplete.")
        }
        if !missingIdentifiers.isEmpty {
            blockers.append("DZWPlayableBattleView is missing order-dice UI identifiers: \(missingIdentifiers.joined(separator: ", ")).")
        }

        return GuderianOrderDiceMigrationCycle60Report(
            cycleStart: 41,
            cycleEnd: 60,
            sideBindings: GuderianOrderDiceSideOwnershipCatalog.allBindings.count,
            sideSelectionReady: GuderianOrderDiceSideOwnershipCatalog.acceptanceReadyThroughCycle45,
            commandPanelReady: GuderianOrderDiceCommandPanelPresenter.acceptanceReadyThroughCycle50,
            inspectorReady: GuderianOrderDiceInspectorPresenter.acceptanceReadyThroughCycle55,
            movementPreviewReady: GuderianOrderDiceMovementPreviewPresenter.acceptanceReadyThroughCycle60,
            missingUISourceIdentifiers: missingIdentifiers,
            blockers: blockers
        )
    }
}

private func guderianCString(_ pointer: UnsafePointer<CChar>?) -> String {
    pointer.map { String(cString: $0) } ?? ""
}

private func optionalCString(_ pointer: UnsafePointer<CChar>?) -> String? {
    guard let pointer else {
        return nil
    }
    return String(cString: pointer)
}

private func unitView(handle: OpaquePointer, unitID: Int) -> unit_view_t? {
    (0..<Int(game_unit_count(handle))).lazy
        .map { game_unit_view(handle, Int32($0)) }
        .first { Int($0.id) == unitID }
}

private extension HistoricalBoardOrder {
    var guderianCValue: dzw_order_t {
        switch self {
        case .fire:
            return DZW_ORDER_FIRE
        case .advance:
            return DZW_ORDER_ADVANCE
        case .run:
            return DZW_ORDER_RUN
        case .ambush:
            return DZW_ORDER_AMBUSH
        case .rally:
            return DZW_ORDER_RALLY
        case .down:
            return DZW_ORDER_DOWN
        }
    }
}
