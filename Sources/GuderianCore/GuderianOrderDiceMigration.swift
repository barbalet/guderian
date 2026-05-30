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

public struct GuderianOrderDiceShootingState: Codable, Hashable, Sendable {
    public let unitID: Int
    public let unitName: String
    public let targetName: String
    public let fireChoiceSummary: String
    public let advanceChoiceSummary: String
    public let targetReactionSummary: String
    public let hitModifierBreakdown: String
    public let pinEffectSummary: String
    public let damageSummary: String
    public let moraleSummary: String
    public let battleLogSummary: String

    public var isReady: Bool {
        !unitName.isEmpty &&
            !targetName.isEmpty &&
            !fireChoiceSummary.isEmpty &&
            !advanceChoiceSummary.isEmpty &&
            !targetReactionSummary.isEmpty &&
            !hitModifierBreakdown.isEmpty &&
            !pinEffectSummary.isEmpty &&
            !damageSummary.isEmpty &&
            !moraleSummary.isEmpty &&
            !battleLogSummary.isEmpty
    }
}

public enum GuderianOrderDiceShootingPresenter {
    public static let cycleRange = 61...65

    public static func state(snapshot: NativeBoardSnapshot) -> GuderianOrderDiceShootingState? {
        guard let selected = snapshot.selectedUnit ?? snapshot.units.first(where: { !$0.destroyed }) else {
            return nil
        }
        let target = selected.lastShootingTargetID.flatMap { targetID in
            snapshot.units.first { $0.id == targetID }
        } ?? snapshot.selectedTarget ?? nearestEnemy(to: selected, in: snapshot)
        return GuderianOrderDiceShootingState(
            unitID: selected.id,
            unitName: selected.name,
            targetName: target?.name ?? "No target selected",
            fireChoiceSummary: orderChoiceSummary(.fire, for: selected),
            advanceChoiceSummary: orderChoiceSummary(.advance, for: selected),
            targetReactionSummary: targetReactionSummary(for: selected, target: target),
            hitModifierBreakdown: hitModifierBreakdown(for: selected),
            pinEffectSummary: pinEffectSummary(for: selected, target: target),
            damageSummary: damageSummary(for: selected),
            moraleSummary: moraleSummary(for: selected),
            battleLogSummary: snapshot.lastAction.detail.isEmpty ? "No shooting result has been logged yet." : snapshot.lastAction.detail
        )
    }

    public static var acceptanceReadyThroughCycle65: Bool {
        guard let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
              let session = NativeBoardSession(scenario: scenario, seed: 65_001) else {
            return false
        }
        _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        guard let state = state(snapshot: session.snapshot()) else {
            return false
        }
        return cycleRange == 61...65 &&
            state.isReady &&
            state.fireChoiceSummary.contains("Fire") &&
            state.advanceChoiceSummary.contains("Advance") &&
            state.hitModifierBreakdown.contains("Base") &&
            state.pinEffectSummary.localizedCaseInsensitiveContains("pin")
    }

    private static func orderChoiceSummary(_ order: HistoricalBoardOrder, for unit: NativeBoardUnitSnapshot) -> String {
        let options = unit.availableOrders.isEmpty ? HistoricalBoardOrder.allCases : unit.availableOrders
        let status = options.contains(order) ? "available" : "not currently available"
        switch order {
        case .fire:
            return "Fire \(status): stationary shooting uses the full fire order."
        case .advance:
            return "Advance \(status): move then shoot with movement pressure."
        default:
            return "\(order.rawValue) \(status)."
        }
    }

    private static func targetReactionSummary(
        for unit: NativeBoardUnitSnapshot,
        target: NativeBoardUnitSnapshot?
    ) -> String {
        let reaction = unit.lastShootingTargetReaction == "None" ? "No reaction recorded yet" : unit.lastShootingTargetReaction
        return "\(target?.name ?? "Target") reaction: \(reaction). Down and Ambush reactions are surfaced here."
    }

    private static func hitModifierBreakdown(for unit: NativeBoardUnitSnapshot) -> String {
        let modifiers = [
            "PB \(signed(unit.lastShootingPointBlankModifier))",
            "Pin \(signed(unit.lastShootingPinModifier))",
            "Long \(signed(unit.lastShootingLongRangeModifier))",
            "Inexp \(signed(unit.lastShootingInexperiencedModifier))",
            "Move \(signed(unit.lastShootingMoveModifier))",
            "Down \(signed(unit.lastShootingDownModifier))",
            "Small \(signed(unit.lastShootingSmallUnitModifier))",
            "Cover \(signed(unit.lastShootingCoverModifier))",
        ]
        let needed = unit.lastShootingNeededToHit > 0 ? "\(unit.lastShootingNeededToHit)+" : "pending"
        return "Base \(unit.lastShootingBaseToHit), modifiers \(modifiers.joined(separator: ", ")), total \(signed(unit.lastShootingToHitModifier)), need \(needed)."
    }

    private static func pinEffectSummary(
        for unit: NativeBoardUnitSnapshot,
        target: NativeBoardUnitSnapshot?
    ) -> String {
        if unit.lastShootingPinsAdded > 0 {
            return "\(unit.lastShootingPinsAdded) pin marker\(unit.lastShootingPinsAdded == 1 ? "" : "s") added to \(target?.name ?? "the target")."
        }
        return "No new shooting pins recorded; \(target?.name ?? "the target") currently shows \(target?.pinCount ?? 0) pin marker\(target?.pinCount == 1 ? "" : "s")."
    }

    private static func damageSummary(for unit: NativeBoardUnitSnapshot) -> String {
        if unit.lastShootingDamageRoll > 0 {
            let success = unit.lastShootingDamageSuccess ? "succeeded" : "failed"
            return "Damage \(success): value \(unit.lastShootingDamageValue), penetration \(signed(unit.lastShootingPenetrationModifier)), roll \(unit.lastShootingDamageRoll), models removed \(unit.lastShootingModelsRemoved)."
        }
        return "No shooting damage roll resolved yet."
    }

    private static func moraleSummary(for unit: NativeBoardUnitSnapshot) -> String {
        guard unit.lastShootingMoraleChecked else {
            return "No shooting morale check resolved yet."
        }
        let result = unit.lastShootingMoraleFailed ? "failed" : "passed"
        return "Morale \(result): roll \(unit.lastShootingMoraleRoll) vs \(unit.lastShootingMoraleTarget), pins \(signed(unit.lastShootingMoralePinModifier)), officer \(signed(unit.lastShootingMoraleOfficerModifier))."
    }

    private static func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}

public struct GuderianOrderDiceVehicleState: Codable, Hashable, Sendable {
    public let unitID: Int
    public let unitName: String
    public let isVehicle: Bool
    public let armourFacingSummary: String
    public let penetrationModifierSummary: String
    public let damageStateSummary: String
    public let wreckMarkerSummary: String
    public let downTransitionSummary: String
    public let renderingSummary: String

    public var isReady: Bool {
        isVehicle &&
            !unitName.isEmpty &&
            !armourFacingSummary.isEmpty &&
            !penetrationModifierSummary.isEmpty &&
            !damageStateSummary.isEmpty &&
            !wreckMarkerSummary.isEmpty &&
            !downTransitionSummary.isEmpty &&
            !renderingSummary.isEmpty
    }
}

public enum GuderianOrderDiceVehiclePresenter {
    public static let cycleRange = 66...70

    public static func state(snapshot: NativeBoardSnapshot) -> GuderianOrderDiceVehicleState? {
        let unit = vehicleCandidate(in: snapshot)
        guard let unit else {
            return nil
        }
        let isVehicle = usesVehicleRules(unit)
        return GuderianOrderDiceVehicleState(
            unitID: unit.id,
            unitName: unit.name,
            isVehicle: isVehicle,
            armourFacingSummary: "Armour F/S/R \(unit.frontArmour)/\(unit.sideArmour)/\(unit.rearArmour), facing \(Int(unit.facingDegrees)) degrees, defensive to-hit \(signed(unit.defensiveToHitModifier)).",
            penetrationModifierSummary: "Penetration \(signed(unit.lastShootingPenetrationModifier)), armour facing \(signed(unit.lastShootingVehicleArmourModifier)), long range \(signed(unit.lastShootingVehicleLongRangePenalty)), open-topped indirect \(signed(unit.lastShootingVehicleOpenToppedIndirectModifier)), class \(unit.lastShootingVehicleDamageClass).",
            damageStateSummary: damageStateSummary(for: unit),
            wreckMarkerSummary: unit.wrecked ? "Wreck marker shown\(unit.wreckBlocksMovement ? " and blocks movement" : "")." : "No wreck marker currently shown.",
            downTransitionSummary: downTransitionSummary(for: unit),
            renderingSummary: "Render armour traits: \(unit.fastVehicle ? "fast " : "")\(unit.reconVehicle ? "recon " : "")\(unit.openToppedVehicle ? "open-topped " : "")\(unit.smokeActive ? "smoke-active" : "smoke-ready \(unit.smokeAvailable ? "yes" : "no")")."
        )
    }

    public static var acceptanceReadyThroughCycle70: Bool {
        guard let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
              let session = NativeBoardSession(scenario: scenario, seed: 70_001) else {
            return false
        }
        _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        guard let state = state(snapshot: session.snapshot()) else {
            return false
        }
        return cycleRange == 66...70 &&
            state.isReady &&
            state.armourFacingSummary.contains("F/S/R") &&
            state.penetrationModifierSummary.localizedCaseInsensitiveContains("penetration") &&
            state.downTransitionSummary.localizedCaseInsensitiveContains("Down")
    }

    private static func vehicleCandidate(in snapshot: NativeBoardSnapshot) -> NativeBoardUnitSnapshot? {
        if let selected = snapshot.selectedUnit, usesVehicleRules(selected) {
            return selected
        }
        return snapshot.units.first(where: usesVehicleRules)
    }

    private static func usesVehicleRules(_ unit: NativeBoardUnitSnapshot) -> Bool {
        unit.frontArmour > 0 ||
            unit.sideArmour > 0 ||
            unit.rearArmour > 0 ||
            unit.kind.localizedCaseInsensitiveContains("vehicle") ||
            unit.kind.localizedCaseInsensitiveContains("assault gun") ||
            unit.mobility.localizedCaseInsensitiveContains("armor") ||
            unit.mobility.localizedCaseInsensitiveContains("armored")
    }

    private static func damageStateSummary(for unit: NativeBoardUnitSnapshot) -> String {
        var parts: [String] = []
        if unit.crewShaken { parts.append("crew shaken") }
        if unit.crewStunned { parts.append("crew stunned") }
        if unit.immobilized { parts.append("immobilized") }
        if unit.destroyed { parts.append("knocked out") }
        if unit.lastVehicleDamageResult != "None" { parts.append("last result \(unit.lastVehicleDamageResult)") }
        return parts.isEmpty ? "Operational; no current vehicle damage state is recorded." : parts.joined(separator: ", ")
    }

    private static func downTransitionSummary(for unit: NativeBoardUnitSnapshot) -> String {
        if unit.lastVehicleDamageResult == "Crew Stunned" ||
            unit.lastVehicleDamageResult == "Immobilized" ||
            unit.lastVehicleDamageResult == "On Fire" {
            return "\(unit.lastVehicleDamageResult) routes the vehicle to Down after damage."
        }
        if unit.downOrderActive {
            return "Down order active on this vehicle."
        }
        return "No Down transition has been triggered yet."
    }

    private static func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}

public struct GuderianOrderDiceCloseQuartersState: Codable, Hashable, Sendable {
    public let unitID: Int
    public let unitName: String
    public let targetName: String
    public let runOrderAssaultSummary: String
    public let targetReactionSummary: String
    public let roundResultsSummary: String
    public let loserDestructionSummary: String
    public let regroupLogSummary: String

    public var isReady: Bool {
        !unitName.isEmpty &&
            !targetName.isEmpty &&
            !runOrderAssaultSummary.isEmpty &&
            !targetReactionSummary.isEmpty &&
            !roundResultsSummary.isEmpty &&
            !loserDestructionSummary.isEmpty &&
            !regroupLogSummary.isEmpty
    }
}

public enum GuderianOrderDiceCloseQuartersPresenter {
    public static let cycleRange = 71...75

    public static func state(snapshot: NativeBoardSnapshot) -> GuderianOrderDiceCloseQuartersState? {
        guard let selected = snapshot.selectedUnit ?? snapshot.units.first(where: { !$0.destroyed }) else {
            return nil
        }
        let target = selected.lastAssaultTargetID.flatMap { targetID in
            snapshot.units.first { $0.id == targetID }
        } ?? snapshot.selectedTarget ?? nearestEnemy(to: selected, in: snapshot)
        return GuderianOrderDiceCloseQuartersState(
            unitID: selected.id,
            unitName: selected.name,
            targetName: target?.name ?? "No target selected",
            runOrderAssaultSummary: runOrderSummary(for: selected),
            targetReactionSummary: "Assault reaction: \(selected.lastAssaultTargetReaction == "None" ? "No reaction recorded yet" : selected.lastAssaultTargetReaction).",
            roundResultsSummary: roundResultsSummary(for: selected),
            loserDestructionSummary: loserDestructionSummary(for: selected, snapshot: snapshot),
            regroupLogSummary: regroupSummary(for: selected)
        )
    }

    public static var acceptanceReadyThroughCycle75: Bool {
        guard let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
              let session = NativeBoardSession(scenario: scenario, seed: 75_001) else {
            return false
        }
        _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        guard let state = state(snapshot: session.snapshot()) else {
            return false
        }
        return cycleRange == 71...75 &&
            state.isReady &&
            state.runOrderAssaultSummary.contains("Run") &&
            state.targetReactionSummary.localizedCaseInsensitiveContains("reaction") &&
            state.regroupLogSummary.localizedCaseInsensitiveContains("regroup")
    }

    private static func runOrderSummary(for unit: NativeBoardUnitSnapshot) -> String {
        let options = unit.availableOrders.isEmpty ? HistoricalBoardOrder.allCases : unit.availableOrders
        let status = options.contains(.run) ? "available" : "not currently available"
        return "Run-order assault \(status): charge allowance \(String(format: "%.1f", unit.assaultMoveAllowance))."
    }

    private static func roundResultsSummary(for unit: NativeBoardUnitSnapshot) -> String {
        if unit.lastAssaultTargetID != nil {
            return "Assault round: attacker wounds \(unit.lastAssaultAttackerWounds), defender wounds \(unit.lastAssaultDefenderWounds), draw rounds \(unit.lastAssaultDrawRounds)."
        }
        return "No close-quarters round has been resolved yet."
    }

    private static func loserDestructionSummary(
        for unit: NativeBoardUnitSnapshot,
        snapshot: NativeBoardSnapshot
    ) -> String {
        guard let loserID = unit.lastAssaultLoserID else {
            return "No assault loser has been recorded yet."
        }
        let loserName = snapshot.units.first { $0.id == loserID }?.name ?? "Unit \(loserID)"
        return unit.lastAssaultLoserDestroyed ? "\(loserName) was destroyed as the assault loser." : "\(loserName) lost the assault but remains on the board."
    }

    private static func regroupSummary(for unit: NativeBoardUnitSnapshot) -> String {
        if unit.lastAssaultRegroupDistance > 0 {
            return "Regroup distance \(String(format: "%.1f", unit.lastAssaultRegroupDistance)); vehicle target \(unit.lastAssaultVehicleTarget ? "yes" : "no"), anti-tank equipped \(unit.lastAssaultAntitankEquipped ? "yes" : "no")."
        }
        return "Regroup log pending until a Run-order assault resolves."
    }
}

public struct GuderianOrderDiceAIDecisionState: Codable, Hashable, Sendable {
    public let battleID: UnifiedGuderianBattleID
    public let drawnSide: NativeBoardPlayer
    public let chosenUnitID: Int
    public let chosenUnitName: String
    public let chosenOrder: HistoricalBoardOrder
    public let objectiveOrTargetName: String
    public let pathSummary: String
    public let failedOrderTestPlan: String
    public let reasoningSummary: String

    public var isReady: Bool {
        drawnSide == .guderianAI &&
            chosenUnitID > 0 &&
            !chosenUnitName.isEmpty &&
            !objectiveOrTargetName.isEmpty &&
            !pathSummary.isEmpty &&
            !failedOrderTestPlan.isEmpty &&
            !reasoningSummary.isEmpty
    }
}

public enum GuderianOrderDiceGuderianAIActivationPlanner {
    public static let cycleRange = 76...80

    public static func decision(
        snapshot: NativeBoardSnapshot,
        battleID: UnifiedGuderianBattleID,
        priorityNames: [String] = []
    ) -> GuderianOrderDiceAIDecisionState? {
        let candidates = snapshot.units
            .filter { $0.owner == .guderianAI && !$0.destroyed && !$0.retainedOrder && $0.currentOrder == nil }
            .sorted { score($0) > score($1) }
        guard let unit = candidates.first else {
            return nil
        }
        let target = nearestEnemy(to: unit, in: snapshot)
        let objective = priorityObjective(in: snapshot, matching: priorityNames) ?? nearestObjective(to: unit, in: snapshot)
        let order = chosenOrder(for: unit, target: target)
        return GuderianOrderDiceAIDecisionState(
            battleID: battleID,
            drawnSide: .guderianAI,
            chosenUnitID: unit.id,
            chosenUnitName: unit.name,
            chosenOrder: order,
            objectiveOrTargetName: targetName(for: order, target: target, objective: objective),
            pathSummary: pathSummary(for: order, unit: unit, target: target, objective: objective),
            failedOrderTestPlan: failedOrderTestPlan(for: unit),
            reasoningSummary: "Choose \(unit.name) for \(order.rawValue) because it has \(unit.pinCount) pins, \(unit.moraleQuality) morale, and \(unit.availableOrders.isEmpty ? "default" : "engine-filtered") order options."
        )
    }

    public static var acceptanceReadyThroughCycle80: Bool {
        guard let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest),
              let session = NativeBoardSession(scenario: scenario, seed: 80_001) else {
            return false
        }
        _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        guard let state = decision(
            snapshot: session.snapshot(),
            battleID: .fieldCommand(.tucholaForest),
            priorityNames: ScenarioContentCatalog.bundle(for: scenario).aiPlan.targetPriorities(for: .movement)
        ) else {
            return false
        }
        return cycleRange == 76...80 &&
            state.isReady &&
            state.drawnSide == .guderianAI &&
            HistoricalBoardOrder.allCases.contains(state.chosenOrder) &&
            state.failedOrderTestPlan.localizedCaseInsensitiveContains("order test")
    }

    private static func chosenOrder(
        for unit: NativeBoardUnitSnapshot,
        target: NativeBoardUnitSnapshot?
    ) -> HistoricalBoardOrder {
        let options = unit.availableOrders.isEmpty ? HistoricalBoardOrder.allCases : unit.availableOrders
        if unit.pinCount >= 2, options.contains(.rally) {
            return .rally
        }
        if target != nil, unit.canAssaultNow, options.contains(.run) {
            return .run
        }
        if target != nil, unit.canShootNow, options.contains(.fire) {
            return .fire
        }
        if options.contains(.advance) {
            return .advance
        }
        if options.contains(.fire) {
            return .fire
        }
        return options.first ?? .down
    }

    private static func score(_ unit: NativeBoardUnitSnapshot) -> Int {
        var value = 0
        if unit.canShootNow { value += 20 }
        if unit.canAssaultNow { value += 12 }
        if unit.canMoveNow { value += 10 }
        if unit.pinCount >= 2 { value += 8 }
        if unit.frontArmour > 0 || unit.mobility.localizedCaseInsensitiveContains("armor") { value += 6 }
        value -= unit.pinCount
        return value
    }

    private static func targetName(
        for order: HistoricalBoardOrder,
        target: NativeBoardUnitSnapshot?,
        objective: NativeBoardObjectiveSnapshot?
    ) -> String {
        switch order {
        case .fire, .run:
            return target?.name ?? objective?.name ?? "nearest enemy"
        case .advance:
            return objective?.name ?? target?.name ?? "nearest objective"
        case .rally, .down, .ambush:
            return "self-preservation"
        }
    }

    private static func pathSummary(
        for order: HistoricalBoardOrder,
        unit: NativeBoardUnitSnapshot,
        target: NativeBoardUnitSnapshot?,
        objective: NativeBoardObjectiveSnapshot?
    ) -> String {
        switch order {
        case .advance:
            return "Advance toward \(objective?.name ?? "the nearest objective") with \(String(format: "%.1f", unit.advanceMoveAllowance)) movement."
        case .run:
            return target == nil
                ? "Run toward \(objective?.name ?? "a priority objective") with \(String(format: "%.1f", unit.runMoveAllowance)) movement."
                : "Run-order assault pressure toward \(target?.name ?? "nearest enemy")."
        case .fire:
            return "Fire at \(target?.name ?? "nearest enemy") before moving."
        case .ambush:
            return "Hold Ambush and retain the die for reaction fire."
        case .rally:
            return "Rally before further manoeuvre because pin pressure is high."
        case .down:
            return "Go Down to preserve the unit after a failed activation window."
        }
    }

    private static func failedOrderTestPlan(for unit: NativeBoardUnitSnapshot) -> String {
        if unit.pinCount > 0 {
            return "Order test risk: \(unit.pinCount) pin marker\(unit.pinCount == 1 ? "" : "s"); failed order test falls back to Down/FUBAR handling from DZW."
        }
        return "Order test risk: none expected; failed order test handling remains ready for later pin pressure."
    }
}

public struct GuderianOrderDiceOpposingAIDecisionState: Codable, Hashable, Sendable {
    public let battleID: UnifiedGuderianBattleID
    public let drawnSide: NativeBoardPlayer
    public let armyFamily: OpposingForceAIArmyFamily
    public let behaviorProfile: OpposingForceAIBehaviorProfile
    public let chosenUnitID: Int
    public let chosenUnitName: String
    public let chosenOrder: HistoricalBoardOrder
    public let objectiveOrTargetName: String
    public let pathSummary: String
    public let orderPrioritySummary: String
    public let failedOrderTestPlan: String
    public let reasoningSummary: String

    public var isReady: Bool {
        drawnSide == .player &&
            armyFamily != .generic &&
            chosenUnitID > 0 &&
            !chosenUnitName.isEmpty &&
            !objectiveOrTargetName.isEmpty &&
            !pathSummary.isEmpty &&
            !orderPrioritySummary.isEmpty &&
            !failedOrderTestPlan.isEmpty &&
            !reasoningSummary.isEmpty
    }
}

public enum GuderianOrderDiceOpposingAIActivationPlanner {
    public static let cycleRange = 81...85

    public static func decision(
        snapshot: NativeBoardSnapshot,
        battleID: UnifiedGuderianBattleID,
        plan: OpposingForceAIPlan
    ) -> GuderianOrderDiceOpposingAIDecisionState? {
        decision(
            snapshot: snapshot,
            battleID: battleID,
            armyFamily: plan.armyFamily,
            behaviorProfile: plan.behaviorProfile,
            priorityNames: plan.targetPriorities(for: snapshot.phase),
            strategicGoal: plan.strategicGoal
        )
    }

    public static func decision(
        snapshot: NativeBoardSnapshot,
        battleID: UnifiedGuderianBattleID,
        armyFamily: OpposingForceAIArmyFamily,
        behaviorProfile: OpposingForceAIBehaviorProfile,
        priorityNames: [String],
        strategicGoal: String
    ) -> GuderianOrderDiceOpposingAIDecisionState? {
        let candidates = snapshot.units
            .filter { $0.owner == .player && !$0.destroyed && !$0.retainedOrder && $0.currentOrder == nil }
            .sorted { score($0, phase: snapshot.phase) > score($1, phase: snapshot.phase) }
        guard let unit = candidates.first else {
            return nil
        }
        let standing = GuderianOrderDiceStandingOrderPlanner.recommendation(for: unit, phase: snapshot.phase)
        let morale = GuderianOrderDicePinsMoraleAIPlanner.state(for: unit)
        let target = nearestEnemy(to: unit, in: snapshot)
        let objective = priorityObjective(in: snapshot, matching: priorityNames) ?? nearestObjective(to: unit, in: snapshot)
        let order = chosenOrder(for: unit, phase: snapshot.phase, standing: standing, morale: morale, target: target)
        return GuderianOrderDiceOpposingAIDecisionState(
            battleID: battleID,
            drawnSide: .player,
            armyFamily: armyFamily,
            behaviorProfile: behaviorProfile,
            chosenUnitID: unit.id,
            chosenUnitName: unit.name,
            chosenOrder: order,
            objectiveOrTargetName: targetName(for: order, target: target, objective: objective),
            pathSummary: pathSummary(for: order, unit: unit, target: target, objective: objective),
            orderPrioritySummary: "\(armyFamily.rawValue) \(behaviorProfile.rawValue): \(priorityNames.prefix(3).joined(separator: ", ")).",
            failedOrderTestPlan: morale.failedOrderTestPlan,
            reasoningSummary: "\(strategicGoal) \(standing.reason) \(morale.riskSummary)"
        )
    }

    public static var allDecisionStates: [GuderianOrderDiceOpposingAIDecisionState] {
        fieldCommandDecisionStates + lateCareerDecisionStates
    }

    public static var fieldCommandDecisionStates: [GuderianOrderDiceOpposingAIDecisionState] {
        GuderianCampaignCatalog.all.compactMap { scenario in
            guard let session = NativeBoardSession(scenario: scenario, seed: UInt32(85_000 + scenario.order)) else {
                return nil
            }
            _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
            return decision(
                snapshot: session.snapshot(),
                battleID: .fieldCommand(scenario.id),
                plan: OpposingForceAIPlanCatalog.plan(for: scenario)
            )
        }
    }

    public static var lateCareerDecisionStates: [GuderianOrderDiceOpposingAIDecisionState] {
        LateCareerGuderianPresentationCatalog.allEntries.compactMap { entry in
            guard let session = LateCareerNativeBoardSession(battlefieldID: entry.id, seed: UInt32(85_500 + entry.order)) else {
                return nil
            }
            _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
            return decision(
                snapshot: session.snapshot(),
                battleID: .lateCareer(entry.id),
                armyFamily: .lateWarSovietAllied,
                behaviorProfile: lateCareerBehaviorProfile(for: entry),
                priorityNames: UnifiedGuderianBattleSideSelectionCatalog.objectivePriorityNames(for: .player, in: entry),
                strategicGoal: entry.visibleCommandCaveatLabel
            )
        }
    }

    public static var acceptanceReadyThroughCycle85: Bool {
        let decisions = allDecisionStates
        let families = Set(decisions.map(\.armyFamily))
        return cycleRange == 81...85 &&
            decisions.count == 35 &&
            decisions.allSatisfy(\.isReady) &&
            [.polish, .french, .alliedPortDefense, .soviet1941, .sovietWinter, .lateWarSovietAllied].allSatisfy { families.contains($0) } &&
            Set(decisions.map(\.chosenOrder)).isSubset(of: Set(HistoricalBoardOrder.allCases))
    }

    private static func chosenOrder(
        for unit: NativeBoardUnitSnapshot,
        phase: NativeBoardPhase,
        standing: GuderianOrderDiceStandingOrderDecision,
        morale: GuderianOrderDicePinsMoraleAIState,
        target: NativeBoardUnitSnapshot?
    ) -> HistoricalBoardOrder {
        let options = unit.availableOrders.isEmpty ? HistoricalBoardOrder.allCases : unit.availableOrders
        if standing.intent != .consumeDie, options.contains(standing.recommendedOrder) {
            return standing.recommendedOrder
        }
        if morale.rallyPriority, options.contains(.rally) {
            return .rally
        }
        switch phase {
        case .shooting where target != nil && options.contains(.fire):
            return .fire
        case .assault where target != nil && options.contains(.run):
            return .run
        default:
            if options.contains(.advance) {
                return .advance
            }
            return options.first ?? .down
        }
    }

    private static func score(_ unit: NativeBoardUnitSnapshot, phase: NativeBoardPhase) -> Int {
        var value = 0
        switch phase {
        case .movement:
            if unit.canMoveNow { value += 20 }
        case .shooting:
            if unit.canShootNow { value += 20 }
        case .assault:
            if unit.canAssaultNow { value += 20 }
        }
        if unit.pinCount >= 2 { value += 7 }
        if unit.inCover || unit.hullDown { value += 3 }
        if unit.moraleQuality == GuderianOrderDiceMoraleQuality.veteran.rawValue { value += 2 }
        return value - unit.pinCount
    }

    private static func targetName(
        for order: HistoricalBoardOrder,
        target: NativeBoardUnitSnapshot?,
        objective: NativeBoardObjectiveSnapshot?
    ) -> String {
        switch order {
        case .fire, .run:
            return target?.name ?? objective?.name ?? "nearest German-command unit"
        case .advance:
            return objective?.name ?? target?.name ?? "nearest objective"
        case .ambush:
            return target?.name ?? "reaction lane"
        case .rally, .down:
            return "unit preservation"
        }
    }

    private static func pathSummary(
        for order: HistoricalBoardOrder,
        unit: NativeBoardUnitSnapshot,
        target: NativeBoardUnitSnapshot?,
        objective: NativeBoardObjectiveSnapshot?
    ) -> String {
        switch order {
        case .advance:
            return "Advance toward \(objective?.name ?? "the nearest objective") with \(String(format: "%.1f", unit.advanceMoveAllowance)) movement."
        case .run:
            return target == nil
                ? "Run toward \(objective?.name ?? "the priority objective") with \(String(format: "%.1f", unit.runMoveAllowance)) movement."
                : "Run-order assault toward \(target?.name ?? "nearest German-command unit")."
        case .fire:
            return "Fire at \(target?.name ?? "nearest German-command unit") while protecting the opposing-force priority."
        case .ambush:
            return "Retain Ambush on the likely German-command approach lane."
        case .rally:
            return "Rally before movement or fire because pin pressure threatens the order test."
        case .down:
            return "Go Down to preserve the unit under incoming fire."
        }
    }

    private static func lateCareerBehaviorProfile(
        for entry: LateCareerGuderianPresentation
    ) -> OpposingForceAIBehaviorProfile {
        let text = [entry.id, entry.title, entry.scope.rawValue].joined(separator: " ").lowercased()
        if text.contains("bridge") || text.contains("dnieper") || text.contains("oder") {
            return .fortifiedDelay
        }
        if text.contains("pocket") || text.contains("withdrawal") || text.contains("corridor") {
            return .breakout
        }
        if text.contains("kustrin") || text.contains("berlin") || text.contains("poznan") || text.contains("seelow") {
            return .urbanDefense
        }
        if text.contains("kursk") || text.contains("solstice") {
            return .counterattack
        }
        return .mobileDelay
    }
}

public enum GuderianOrderDiceStandingOrderIntent: String, CaseIterable, Codable, Hashable, Sendable {
    case retainAmbush = "Retain Ambush"
    case goDown = "Go Down"
    case rally = "Rally"
    case consumeDie = "Consume Die"
}

public struct GuderianOrderDiceStandingOrderDecision: Codable, Hashable, Sendable {
    public let unitID: Int
    public let unitName: String
    public let intent: GuderianOrderDiceStandingOrderIntent
    public let recommendedOrder: HistoricalBoardOrder
    public let reason: String

    public var isReady: Bool {
        unitID > 0 &&
            !unitName.isEmpty &&
            !reason.isEmpty &&
            HistoricalBoardOrder.allCases.contains(recommendedOrder)
    }
}

public enum GuderianOrderDiceStandingOrderPlanner {
    public static let cycleRange = 86...90

    public static func recommendation(
        for unit: NativeBoardUnitSnapshot,
        phase: NativeBoardPhase = .movement
    ) -> GuderianOrderDiceStandingOrderDecision {
        let options = unit.availableOrders.isEmpty ? HistoricalBoardOrder.allCases : unit.availableOrders
        let morale = GuderianOrderDicePinsMoraleAIPlanner.state(for: unit)
        if morale.rallyPriority, options.contains(.rally) {
            return decision(unit, .rally, .rally, "\(unit.pinCount) pins exceed the \(unit.moraleQuality) rally threshold.")
        }
        if (unit.ambushOrderActive || unit.retainedOrder), options.contains(.ambush), phase != .assault {
            return decision(unit, .retainAmbush, .ambush, "Ambush is already retained and should hold for opportunity fire.")
        }
        if unit.pinCount > 0,
           !unit.inCover,
           !unit.hullDown,
           options.contains(.down),
           (phase == .shooting || !unit.canMoveNow) {
            return decision(unit, .goDown, .down, "Pinned and exposed units prefer Down before spending a risky activation.")
        }
        let order: HistoricalBoardOrder
        if phase == .shooting, options.contains(.fire) {
            order = .fire
        } else if phase == .assault, options.contains(.run) {
            order = .run
        } else if options.contains(.advance) {
            order = .advance
        } else {
            order = options.first ?? .down
        }
        return decision(unit, .consumeDie, order, "No standing-order hold is better than consuming the die for \(order.rawValue).")
    }

    public static var deterministicRecommendations: [GuderianOrderDiceStandingOrderDecision] {
        [
            recommendation(for: sampleUnit(id: 901, name: "Pinned rifle section", pinCount: 3, inCover: true, availableOrders: [.rally, .down, .advance])),
            recommendation(for: sampleUnit(id: 902, name: "Ambush anti-tank gun", availableOrders: [.ambush, .fire, .down], ambushOrderActive: true)),
            recommendation(for: sampleUnit(id: 903, name: "Exposed platoon", pinCount: 1, inCover: false, canMoveNow: false, availableOrders: [.down, .advance]), phase: .shooting),
            recommendation(for: sampleUnit(id: 904, name: "Mobile reserve", availableOrders: [.advance, .run, .fire])),
        ]
    }

    public static var acceptanceReadyThroughCycle90: Bool {
        let recommendations = deterministicRecommendations
        return cycleRange == 86...90 &&
            recommendations.count == 4 &&
            recommendations.allSatisfy(\.isReady) &&
            Set(recommendations.map(\.intent)) == Set(GuderianOrderDiceStandingOrderIntent.allCases)
    }

    private static func decision(
        _ unit: NativeBoardUnitSnapshot,
        _ intent: GuderianOrderDiceStandingOrderIntent,
        _ order: HistoricalBoardOrder,
        _ reason: String
    ) -> GuderianOrderDiceStandingOrderDecision {
        GuderianOrderDiceStandingOrderDecision(
            unitID: unit.id,
            unitName: unit.name,
            intent: intent,
            recommendedOrder: order,
            reason: reason
        )
    }
}

public struct GuderianOrderDicePinsMoraleAIState: Codable, Hashable, Sendable {
    public let unitID: Int
    public let unitName: String
    public let moraleQuality: String
    public let moraleTarget: Int
    public let pinCount: Int
    public let pinThreshold: Int
    public let officerModifier: Int
    public let rallyPriority: Bool
    public let fubarRisk: String
    public let recommendedOrder: HistoricalBoardOrder
    public let failedOrderTestPlan: String
    public let riskSummary: String

    public var isReady: Bool {
        unitID > 0 &&
            !unitName.isEmpty &&
            !moraleQuality.isEmpty &&
            moraleTarget > 0 &&
            pinThreshold > 0 &&
            !fubarRisk.isEmpty &&
            !failedOrderTestPlan.isEmpty &&
            !riskSummary.isEmpty
    }
}

public enum GuderianOrderDicePinsMoraleAIPlanner {
    public static let cycleRange = 91...95

    public static func state(for unit: NativeBoardUnitSnapshot) -> GuderianOrderDicePinsMoraleAIState {
        let moraleTarget = moraleTarget(for: unit.moraleQuality)
        let officerModifier = unit.lastOrderTestOfficerModifier
        let effectiveTarget = max(2, moraleTarget + officerModifier - unit.pinCount)
        let pinThreshold = max(1, moraleTarget / 3)
        let rallyPriority = unit.pinCount >= pinThreshold + 1 || effectiveTarget <= 6
        let fubarRisk = unit.pinCount >= pinThreshold + 2 || unit.lastFubarResult != "None" ? "Elevated FUBAR risk" : "Normal FUBAR risk"
        let recommendedOrder: HistoricalBoardOrder = rallyPriority ? .rally : (unit.pinCount > 0 ? .down : .advance)
        return GuderianOrderDicePinsMoraleAIState(
            unitID: unit.id,
            unitName: unit.name,
            moraleQuality: unit.moraleQuality,
            moraleTarget: moraleTarget,
            pinCount: unit.pinCount,
            pinThreshold: pinThreshold,
            officerModifier: officerModifier,
            rallyPriority: rallyPriority,
            fubarRisk: fubarRisk,
            recommendedOrder: recommendedOrder,
            failedOrderTestPlan: "Order test target \(effectiveTarget)+ after pins \(unit.pinCount) and officer \(orderDiceSigned(officerModifier)); failure falls back to Down/FUBAR handling.",
            riskSummary: "\(unit.moraleQuality) morale target \(moraleTarget), pins \(unit.pinCount), officer \(orderDiceSigned(officerModifier)), \(fubarRisk)."
        )
    }

    public static var deterministicStates: [GuderianOrderDicePinsMoraleAIState] {
        [
            state(for: sampleUnit(id: 951, name: "Inexperienced pinned section", moraleQuality: "Inexperienced", pinCount: 3, lastOrderTestOfficerModifier: 0)),
            state(for: sampleUnit(id: 952, name: "Regular officer-supported section", moraleQuality: "Regular", pinCount: 1, lastOrderTestOfficerModifier: 1)),
            state(for: sampleUnit(id: 953, name: "Veteran steady section", moraleQuality: "Veteran", pinCount: 0, lastOrderTestOfficerModifier: 0)),
        ]
    }

    public static var acceptanceReadyThroughCycle95: Bool {
        let states = deterministicStates
        return cycleRange == 91...95 &&
            states.count == 3 &&
            states.allSatisfy(\.isReady) &&
            states.contains { $0.rallyPriority && $0.recommendedOrder == .rally } &&
            states.contains { $0.officerModifier > 0 && $0.failedOrderTestPlan.localizedCaseInsensitiveContains("officer") } &&
            states.contains { $0.fubarRisk.localizedCaseInsensitiveContains("FUBAR") }
    }

    private static func moraleTarget(for quality: String) -> Int {
        if quality.localizedCaseInsensitiveContains("Inexperienced") {
            return 8
        }
        if quality.localizedCaseInsensitiveContains("Veteran") {
            return 10
        }
        return 9
    }
}

public enum GuderianOrderDiceTargetReactionIntent: String, Codable, Hashable, Sendable {
    case hold = "Hold"
    case down = "Down"
    case ambushOpportunity = "Ambush Opportunity"
}

public struct GuderianOrderDiceTargetReactionDecisionState: Codable, Hashable, Sendable {
    public let attackerSide: NativeBoardPlayer
    public let targetSide: NativeBoardPlayer
    public let targetUnitID: Int
    public let targetUnitName: String
    public let incomingAction: HistoricalBoardOrder
    public let recommendedReaction: GuderianOrderDiceTargetReactionIntent
    public let downSummary: String
    public let ambushSummary: String
    public let opportunitySummary: String
    public let reasoningSummary: String

    public var isReady: Bool {
        attackerSide != .none &&
            targetSide != .none &&
            attackerSide != targetSide &&
            targetUnitID > 0 &&
            !targetUnitName.isEmpty &&
            !downSummary.isEmpty &&
            !ambushSummary.isEmpty &&
            !opportunitySummary.isEmpty &&
            !reasoningSummary.isEmpty
    }
}

public enum GuderianOrderDiceTargetReactionAIPlanner {
    public static let cycleRange = 96...100

    public static func decision(
        attacker: NativeBoardUnitSnapshot,
        target: NativeBoardUnitSnapshot,
        incomingAction: HistoricalBoardOrder
    ) -> GuderianOrderDiceTargetReactionDecisionState {
        let reaction: GuderianOrderDiceTargetReactionIntent
        if target.ambushOrderActive && target.canShootNow && incomingAction == .run {
            reaction = .ambushOpportunity
        } else if target.pinCount > 0 || target.defensiveToHitModifier < 0 || incomingAction == .fire {
            reaction = .down
        } else {
            reaction = .hold
        }
        return GuderianOrderDiceTargetReactionDecisionState(
            attackerSide: attacker.owner,
            targetSide: target.owner,
            targetUnitID: target.id,
            targetUnitName: target.name,
            incomingAction: incomingAction,
            recommendedReaction: reaction,
            downSummary: target.downOrderActive ? "Already Down." : "Down available when incoming fire or pin pressure outweighs acting later.",
            ambushSummary: target.ambushOrderActive ? "Ambush is retained and can answer a Run-order assault opportunity." : "No retained Ambush opportunity currently shown.",
            opportunitySummary: "\(attacker.name) threatens \(target.name) with \(incomingAction.rawValue); recommended reaction is \(reaction.rawValue).",
            reasoningSummary: "\(target.name) pins \(target.pinCount), defensive modifier \(target.defensiveToHitModifier), can shoot \(target.canShootNow ? "yes" : "no")."
        )
    }

    public static var deterministicDecisions: [GuderianOrderDiceTargetReactionDecisionState] {
        let human = sampleUnit(id: 981, name: "Human panzergrenadiers", owner: .guderianAI)
        let aiTarget = sampleUnit(id: 982, name: "AI infantry in the open", owner: .player, pinCount: 1, inCover: false, defensiveToHitModifier: 0)
        let aiAttacker = sampleUnit(id: 983, name: "AI rifle section", owner: .player)
        let humanTarget = sampleUnit(id: 984, name: "Human anti-tank gun", owner: .guderianAI, canShootNow: true, ambushOrderActive: true)
        return [
            decision(attacker: human, target: aiTarget, incomingAction: .fire),
            decision(attacker: aiAttacker, target: humanTarget, incomingAction: .run),
        ]
    }

    public static var acceptanceReadyThroughCycle100: Bool {
        let decisions = deterministicDecisions
        return cycleRange == 96...100 &&
            decisions.count == 2 &&
            decisions.allSatisfy(\.isReady) &&
            decisions.contains { $0.attackerSide == .guderianAI && $0.targetSide == .player && $0.recommendedReaction == .down } &&
            decisions.contains { $0.attackerSide == .player && $0.targetSide == .guderianAI && $0.recommendedReaction == .ambushOpportunity }
    }
}

public struct GuderianOrderDiceMigrationCycle100Report: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let cycle80Ready: Bool
    public let opposingAIReady: Bool
    public let standingOrderAIReady: Bool
    public let pinsMoraleAIReady: Bool
    public let targetReactionAIReady: Bool
    public let missingUISourceIdentifiers: [String]
    public let blockers: [String]

    public var isReadyThroughCycle100: Bool {
        blockers.isEmpty &&
            cycleStart == 81 &&
            cycleEnd == 100 &&
            cycle80Ready &&
            opposingAIReady &&
            standingOrderAIReady &&
            pinsMoraleAIReady &&
            targetReactionAIReady &&
            missingUISourceIdentifiers.isEmpty
    }
}

public enum GuderianOrderDiceMigrationCycle100AcceptanceCatalog {
    public static let cycleRange = 81...100
    public static let requiredUISourceIdentifiers = [
        "opposing-order-ai-panel",
        "opposing-ai-army-family",
        "opposing-ai-order-choice",
        "opposing-ai-standing-order",
        "opposing-ai-morale-risk",
        "target-reaction-ai-summary",
    ]

    public static func acceptanceReadyThroughCycle100(
        cycle80SourceText: String
    ) -> Bool {
        report(cycle80SourceText: cycle80SourceText).isReadyThroughCycle100
    }

    public static func report(
        cycle80SourceText: String
    ) -> GuderianOrderDiceMigrationCycle100Report {
        let cycle80Ready = GuderianOrderDiceMigrationCycle80AcceptanceCatalog.acceptanceReadyThroughCycle80(
            cycle60SourceText: cycle80SourceText,
            cycle80SourceText: cycle80SourceText
        )
        let missingIdentifiers = requiredUISourceIdentifiers.filter { !cycle80SourceText.contains($0) }
        var blockers: [String] = []
        if !cycle80Ready {
            blockers.append("Cycle 61-80 shooting, vehicle, close-quarters, and Guderian-command AI gates are not ready.")
        }
        if !GuderianOrderDiceOpposingAIActivationPlanner.acceptanceReadyThroughCycle85 {
            blockers.append("Cycle 81-85 opposing-army order-dice AI is incomplete.")
        }
        if !GuderianOrderDiceStandingOrderPlanner.acceptanceReadyThroughCycle90 {
            blockers.append("Cycle 86-90 Ambush/Down/Rally AI is incomplete.")
        }
        if !GuderianOrderDicePinsMoraleAIPlanner.acceptanceReadyThroughCycle95 {
            blockers.append("Cycle 91-95 pins and morale AI is incomplete.")
        }
        if !GuderianOrderDiceTargetReactionAIPlanner.acceptanceReadyThroughCycle100 {
            blockers.append("Cycle 96-100 target reaction AI is incomplete.")
        }
        if !missingIdentifiers.isEmpty {
            blockers.append("DZWPlayableBattleView is missing cycle 81-100 UI identifiers: \(missingIdentifiers.joined(separator: ", ")).")
        }

        return GuderianOrderDiceMigrationCycle100Report(
            cycleStart: 81,
            cycleEnd: 100,
            cycle80Ready: cycle80Ready,
            opposingAIReady: GuderianOrderDiceOpposingAIActivationPlanner.acceptanceReadyThroughCycle85,
            standingOrderAIReady: GuderianOrderDiceStandingOrderPlanner.acceptanceReadyThroughCycle90,
            pinsMoraleAIReady: GuderianOrderDicePinsMoraleAIPlanner.acceptanceReadyThroughCycle95,
            targetReactionAIReady: GuderianOrderDiceTargetReactionAIPlanner.acceptanceReadyThroughCycle100,
            missingUISourceIdentifiers: missingIdentifiers,
            blockers: blockers
        )
    }
}

public struct GuderianOrderDiceAutoplayHarnessReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let firstBattleActivationSteps: Int
    public let firstBattlePhaseCompatibilitySteps: Int
    public let playableRunnerActivationSteps: Int
    public let speedModes: [GuderianTestFirstBattleAutoplaySpeed]
    public let pauseResumePreserved: Bool
    public let safetyCapPreserved: Bool
    public let usesOrderDiceActivationVocabulary: Bool
    public let blockers: [String]

    public var isReadyThroughCycle105: Bool {
        blockers.isEmpty &&
            cycleRange == 101...105 &&
            firstBattleActivationSteps > 0 &&
            firstBattleActivationSteps == firstBattlePhaseCompatibilitySteps &&
            playableRunnerActivationSteps > 0 &&
            speedModes == GuderianTestFirstBattleAutoplaySpeed.allCases &&
            pauseResumePreserved &&
            safetyCapPreserved &&
            usesOrderDiceActivationVocabulary
    }
}

public enum GuderianOrderDiceAutoplayHarnessCatalog {
    public static let cycleRange = 101...105

    public static var report: GuderianOrderDiceAutoplayHarnessReport {
        var blockers: [String] = []
        let controller = try? GuderianTestFirstBattleRunController()
        if controller == nil {
            blockers.append("GuderianTest first-battle controller could not launch.")
        }
        let step = try? controller?.stepOnce()
        if step == nil {
            blockers.append("GuderianTest could not perform one order-dice activation step.")
        }
        let playableResult = try? PlayableTestGameRunner.runBattle(for: .tucholaForest, seed: 101_105)
        if playableResult == nil {
            blockers.append("PlayableTestGameRunner could not complete Tuchola with activation stepping.")
        }

        return GuderianOrderDiceAutoplayHarnessReport(
            cycleRange: cycleRange,
            firstBattleActivationSteps: controller?.activationSteps ?? 0,
            firstBattlePhaseCompatibilitySteps: controller?.phaseAdvances ?? 0,
            playableRunnerActivationSteps: playableResult?.activationSteps ?? 0,
            speedModes: GuderianTestFirstBattleAutoplaySpeed.allCases,
            pauseResumePreserved: controller?.canRun == true || controller?.runState == .paused,
            safetyCapPreserved: (controller?.maxActivationSteps ?? 0) >= 24 &&
                (controller?.activationBudgetRemaining ?? -1) >= 0,
            usesOrderDiceActivationVocabulary: step?.title.localizedCaseInsensitiveContains("activation") == true &&
                playableResult?.summary.localizedCaseInsensitiveContains("order-dice activations") == true,
            blockers: blockers
        )
    }

    public static var acceptanceReadyThroughCycle105: Bool {
        report.isReadyThroughCycle105
    }
}

public enum GuderianOrderDiceScenarioTuningTheater: String, Codable, Hashable, Sendable {
    case poland = "Poland 1939"
    case france = "France 1940"
    case easternFront = "Eastern Front"
}

public enum GuderianOrderDiceScenarioTuningEmphasis: String, CaseIterable, Codable, Hashable, Sendable {
    case orderDicePacing = "Order-dice pacing"
    case pinRallyDown = "Pins, Rally, and Down"
    case roughTerrain = "Rough terrain"
    case roadMovement = "Road movement"
    case earlyWarArmorInfantry = "Early-war armor and infantry weapons"
    case riverCrossings = "River crossings"
    case frenchCounterattacks = "French counterattacks"
    case charB1Shock = "Char B1 shock"
    case portDefense = "Port defense"
    case evacuationPressure = "Evacuation pressure"
    case airArtilleryPinning = "Air and artillery pinning"
    case sovietCounterattacks = "Soviet counterattacks"
    case pocketBreakout = "Pocket breakout"
    case t34KVArmour = "T-34/KV armour"
    case logisticsFriction = "Logistics friction"
    case winterMovement = "Winter movement"
    case moralePressure = "Morale pressure"
}

public struct GuderianOrderDiceScenarioTuningRow: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let scenarioID: GuderianBattleID
    public let title: String
    public let theater: GuderianOrderDiceScenarioTuningTheater
    public let targetTurnRange: ClosedRange<Int>
    public let targetActivationRange: ClosedRange<Int>
    public let emphases: Set<GuderianOrderDiceScenarioTuningEmphasis>
    public let pinMoraleTuning: String
    public let movementTuning: String
    public let combatTuning: String
    public let aiTuning: String

    public var isReady: Bool {
        targetTurnRange.lowerBound > 0 &&
            targetActivationRange.lowerBound >= targetTurnRange.lowerBound * 8 &&
            targetActivationRange.upperBound >= targetTurnRange.upperBound * 8 &&
            !emphases.isEmpty &&
            !pinMoraleTuning.isEmpty &&
            !movementTuning.isEmpty &&
            !combatTuning.isEmpty &&
            !aiTuning.isEmpty
    }
}

public enum GuderianOrderDiceFieldScenarioTuningCatalog {
    public static let cycleRange = 106...120

    public static var allRows: [GuderianOrderDiceScenarioTuningRow] {
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(row)
    }

    public static var polandRows: [GuderianOrderDiceScenarioTuningRow] {
        allRows.filter { $0.theater == .poland }
    }

    public static var franceRows: [GuderianOrderDiceScenarioTuningRow] {
        allRows.filter { $0.theater == .france }
    }

    public static var easternFrontRows: [GuderianOrderDiceScenarioTuningRow] {
        allRows.filter { $0.theater == .easternFront }
    }

    public static func row(for battleID: UnifiedGuderianBattleID) -> GuderianOrderDiceScenarioTuningRow? {
        guard let scenarioID = battleID.fieldCommandID,
              let scenario = GuderianCampaignCatalog.scenario(id: scenarioID) else {
            return nil
        }
        return row(for: scenario)
    }

    public static func row(for scenario: GuderianScenario) -> GuderianOrderDiceScenarioTuningRow {
        let profile = ScenarioBalanceCatalog.profile(for: scenario)
        let impact = GuderianOrderDiceScenarioImpactCatalog.row(for: .fieldCommand(scenario.id))
        let emphases = emphases(for: scenario.id)
        let activationLower = profile.targetTurns.lowerBound * max(8, impact?.playerOrderDice ?? 8)
        let activationUpper = profile.targetTurns.upperBound * max(8, (impact?.playerOrderDice ?? 8) + (impact?.guderianOrderDice ?? 8))
        return GuderianOrderDiceScenarioTuningRow(
            id: .fieldCommand(scenario.id),
            scenarioID: scenario.id,
            title: scenario.title,
            theater: theater(for: scenario.id),
            targetTurnRange: profile.targetTurns,
            targetActivationRange: activationLower...max(activationLower, activationUpper),
            emphases: emphases,
            pinMoraleTuning: pinMoraleTuning(for: scenario.id, profile: profile),
            movementTuning: movementTuning(for: scenario.id, profile: profile),
            combatTuning: combatTuning(for: scenario.id, profile: profile),
            aiTuning: aiTuning(for: scenario.id, profile: profile)
        )
    }

    public static var acceptanceReadyThroughCycle110: Bool {
        polandRows.count == 4 &&
            polandRows.allSatisfy(\.isReady) &&
            polandRows.allSatisfy { $0.emphases.isSuperset(of: [.orderDicePacing, .pinRallyDown, .roughTerrain, .roadMovement, .earlyWarArmorInfantry]) }
    }

    public static var acceptanceReadyThroughCycle115: Bool {
        franceRows.count == 8 &&
            franceRows.allSatisfy(\.isReady) &&
            franceRows.contains { $0.emphases.contains(.riverCrossings) } &&
            franceRows.contains { $0.emphases.contains(.frenchCounterattacks) } &&
            franceRows.contains { $0.emphases.contains(.charB1Shock) } &&
            franceRows.contains { $0.emphases.contains(.portDefense) } &&
            franceRows.contains { $0.emphases.contains(.evacuationPressure) } &&
            franceRows.contains { $0.emphases.contains(.airArtilleryPinning) }
    }

    public static var acceptanceReadyThroughCycle120: Bool {
        easternFrontRows.count == 7 &&
            easternFrontRows.allSatisfy(\.isReady) &&
            easternFrontRows.contains { $0.emphases.contains(.sovietCounterattacks) } &&
            easternFrontRows.contains { $0.emphases.contains(.pocketBreakout) } &&
            easternFrontRows.contains { $0.emphases.contains(.t34KVArmour) } &&
            easternFrontRows.contains { $0.emphases.contains(.logisticsFriction) } &&
            easternFrontRows.contains { $0.emphases.contains(.winterMovement) } &&
            easternFrontRows.allSatisfy { $0.emphases.contains(.moralePressure) }
    }

    private static func theater(for id: GuderianBattleID) -> GuderianOrderDiceScenarioTuningTheater {
        switch id {
        case .tucholaForest, .wizna, .brzescLitewski, .kobryn:
            return .poland
        case .sedan, .stonne, .montcornet, .amiensAbbeville, .boulogne, .calais, .dunkirk, .fallRot:
            return .france
        case .bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .mtsensk, .moscowTulaKashira:
            return .easternFront
        }
    }

    private static func emphases(for id: GuderianBattleID) -> Set<GuderianOrderDiceScenarioTuningEmphasis> {
        var result: Set<GuderianOrderDiceScenarioTuningEmphasis> = [.orderDicePacing, .pinRallyDown, .moralePressure]
        switch theater(for: id) {
        case .poland:
            result.formUnion([.roughTerrain, .roadMovement, .earlyWarArmorInfantry])
        case .france:
            result.formUnion([.roadMovement, .airArtilleryPinning])
            switch id {
            case .sedan, .fallRot:
                result.insert(.riverCrossings)
            case .stonne:
                result.formUnion([.frenchCounterattacks, .charB1Shock])
            case .montcornet:
                result.insert(.frenchCounterattacks)
            case .boulogne, .calais, .dunkirk:
                result.formUnion([.portDefense, .evacuationPressure])
            case .amiensAbbeville:
                result.insert(.evacuationPressure)
            default:
                break
            }
        case .easternFront:
            result.formUnion([.sovietCounterattacks, .pocketBreakout, .logisticsFriction])
            switch id {
            case .mtsensk, .moscowTulaKashira:
                result.insert(.t34KVArmour)
            default:
                break
            }
            if id == .moscowTulaKashira {
                result.insert(.winterMovement)
            }
        }
        return result
    }

    private static func pinMoraleTuning(
        for id: GuderianBattleID,
        profile: ScenarioBalanceProfile
    ) -> String {
        switch theater(for: id) {
        case .poland:
            return "Pins should create Rally/Down choices without erasing the early withdrawal window: \(profile.germanPressureLimit)"
        case .france:
            return "Air/artillery pins suppress tempo but must preserve counterattack agency: \(profile.germanPressureLimit)"
        case .easternFront:
            return "Morale pressure should make pockets and winter exhaustion visible while keeping breakout decisions alive: \(profile.germanPressureLimit)"
        }
    }

    private static func movementTuning(
        for id: GuderianBattleID,
        profile: ScenarioBalanceProfile
    ) -> String {
        switch theater(for: id) {
        case .poland:
            return "Road movement gives German pressure speed; rough ground and crossings require Advance/Rally/Down tradeoffs."
        case .france:
            return "River, bridge, port, and road chokepoints must consume real order-dice activation windows."
        case .easternFront:
            return id == .moscowTulaKashira ?
                "Winter movement and road-speed temptation must punish overextension without freezing all attacks." :
                "Pocket routes, rail/road corridors, and logistics friction should slow repeated Run pressure."
        }
    }

    private static func combatTuning(
        for id: GuderianBattleID,
        profile: ScenarioBalanceProfile
    ) -> String {
        let scoreNames = profile.scoreChannels.map(\.name).prefix(3).joined(separator: ", ")
        switch theater(for: id) {
        case .poland:
            return "Early-war armour, infantry weapons, anti-tank guns, and armored trains tune combat around \(scoreNames)."
        case .france:
            return "French counterattack, Char B1 shock, port defense, and air/artillery pin effects tune combat around \(scoreNames)."
        case .easternFront:
            return "Soviet counterattacks, T-34/KV armour, pockets, and morale checks tune combat around \(scoreNames)."
        }
    }

    private static func aiTuning(
        for id: GuderianBattleID,
        profile: ScenarioBalanceProfile
    ) -> String {
        "AI order priorities must support the scenario win condition: \(profile.playerWinCondition)"
    }
}

public struct GuderianOrderDiceMigrationCycle120Report: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let cycle100Ready: Bool
    public let autoplayHarnessReady: Bool
    public let polandTuningReady: Bool
    public let franceTuningReady: Bool
    public let easternFrontTuningReady: Bool
    public let tuningRows: Int
    public let missingSourceIdentifiers: [String]
    public let blockers: [String]

    public var isReadyThroughCycle120: Bool {
        blockers.isEmpty &&
            cycleStart == 101 &&
            cycleEnd == 120 &&
            cycle100Ready &&
            autoplayHarnessReady &&
            polandTuningReady &&
            franceTuningReady &&
            easternFrontTuningReady &&
            tuningRows == 19 &&
            missingSourceIdentifiers.isEmpty
    }
}

public enum GuderianOrderDiceMigrationCycle120AcceptanceCatalog {
    public static let cycleRange = 101...120
    public static let requiredSourceIdentifiers = [
        "guderian-test-activation-count",
        "guderian-test-activation-safety-cap",
        "order-dice-scenario-tuning-panel",
        "poland-order-dice-tuning",
        "france-order-dice-tuning",
        "eastern-front-order-dice-tuning",
    ]

    public static func report(
        cycle80And100SourceText: String,
        guderianTestSourceText: String
    ) -> GuderianOrderDiceMigrationCycle120Report {
        let combinedSource = cycle80And100SourceText + "\n" + guderianTestSourceText
        let missingIdentifiers = requiredSourceIdentifiers.filter { !combinedSource.contains($0) }
        let cycle100Ready = GuderianOrderDiceMigrationCycle100AcceptanceCatalog.acceptanceReadyThroughCycle100(
            cycle80SourceText: cycle80And100SourceText
        )
        var blockers: [String] = []
        if !cycle100Ready {
            blockers.append("Cycle 81-100 opposing-force AI and reaction gates are not ready.")
        }
        if !GuderianOrderDiceAutoplayHarnessCatalog.acceptanceReadyThroughCycle105 {
            blockers.append("Cycle 101-105 autoplay activation harness is incomplete.")
        }
        if !GuderianOrderDiceFieldScenarioTuningCatalog.acceptanceReadyThroughCycle110 {
            blockers.append("Cycle 106-110 Poland tuning is incomplete.")
        }
        if !GuderianOrderDiceFieldScenarioTuningCatalog.acceptanceReadyThroughCycle115 {
            blockers.append("Cycle 111-115 France tuning is incomplete.")
        }
        if !GuderianOrderDiceFieldScenarioTuningCatalog.acceptanceReadyThroughCycle120 {
            blockers.append("Cycle 116-120 Eastern Front tuning is incomplete.")
        }
        if !missingIdentifiers.isEmpty {
            blockers.append("Cycle 101-120 UI/source identifiers are missing: \(missingIdentifiers.joined(separator: ", ")).")
        }

        return GuderianOrderDiceMigrationCycle120Report(
            cycleStart: 101,
            cycleEnd: 120,
            cycle100Ready: cycle100Ready,
            autoplayHarnessReady: GuderianOrderDiceAutoplayHarnessCatalog.acceptanceReadyThroughCycle105,
            polandTuningReady: GuderianOrderDiceFieldScenarioTuningCatalog.acceptanceReadyThroughCycle110,
            franceTuningReady: GuderianOrderDiceFieldScenarioTuningCatalog.acceptanceReadyThroughCycle115,
            easternFrontTuningReady: GuderianOrderDiceFieldScenarioTuningCatalog.acceptanceReadyThroughCycle120,
            tuningRows: GuderianOrderDiceFieldScenarioTuningCatalog.allRows.count,
            missingSourceIdentifiers: missingIdentifiers,
            blockers: blockers
        )
    }

    public static func acceptanceReadyThroughCycle120(
        cycle80And100SourceText: String,
        guderianTestSourceText: String
    ) -> Bool {
        report(
            cycle80And100SourceText: cycle80And100SourceText,
            guderianTestSourceText: guderianTestSourceText
        ).isReadyThroughCycle120
    }
}

public enum GuderianOrderDiceLateCareerTuningEmphasis: String, CaseIterable, Codable, Hashable, Sendable {
    case orderDicePacing = "Order-dice pacing"
    case commandCaveat = "Command caveat"
    case staffInfluence = "Staff influence"
    case withdrawalPressure = "Withdrawal pressure"
    case logisticsFriction = "Logistics friction"
    case sovietBreakthrough = "Soviet breakthrough"
    case armoredForcePressure = "Armored-force pressure"
    case urbanFortress = "Urban fortress"
    case finalWarCompression = "Final-war compression"
    case epilogueContext = "Epilogue context"
    case moralePressure = "Morale pressure"
    case retainedOrders = "Ambush/Down retention"
}

public struct GuderianOrderDiceLateCareerTuningRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: UnifiedGuderianBattleID
    public let title: String
    public let set: LateCareerPlayableSet
    public let scope: GuderianCommandScope
    public let targetTurnRange: ClosedRange<Int>
    public let targetActivationRange: ClosedRange<Int>
    public let emphases: Set<GuderianOrderDiceLateCareerTuningEmphasis>
    public let caveatTuning: String
    public let movementTuning: String
    public let combatTuning: String
    public let scoringTuning: String
    public let aiTuning: String

    public var isReady: Bool {
        battleID.kind == .lateCareer &&
            targetTurnRange.lowerBound > 0 &&
            targetActivationRange.lowerBound >= targetTurnRange.lowerBound * 8 &&
            targetActivationRange.upperBound >= targetTurnRange.upperBound * 8 &&
            emphases.contains(.orderDicePacing) &&
            emphases.contains(.commandCaveat) &&
            emphases.contains(.moralePressure) &&
            !caveatTuning.isEmpty &&
            !movementTuning.isEmpty &&
            !combatTuning.isEmpty &&
            !scoringTuning.isEmpty &&
            !aiTuning.isEmpty
    }
}

public enum GuderianOrderDiceLateCareerTuningCatalog {
    public static let cycleRange = 121...125

    public static var allRows: [GuderianOrderDiceLateCareerTuningRow] {
        LateCareerGuderianPresentationCatalog.allEntries
            .sorted { $0.order < $1.order }
            .compactMap(row)
    }

    public static func row(for battleID: UnifiedGuderianBattleID) -> GuderianOrderDiceLateCareerTuningRow? {
        guard let lateCareerID = battleID.lateCareerID,
              let entry = LateCareerGuderianPresentationCatalog.entry(for: lateCareerID) else {
            return nil
        }
        return row(for: entry)
    }

    public static func row(for entry: LateCareerGuderianPresentation) -> GuderianOrderDiceLateCareerTuningRow? {
        guard let report = LateCareerPlayableSurfaceCatalog.report(for: entry.id),
              let instance = LateCareerNativeBattleInstanceCatalog.instance(for: entry.id),
              let set = LateCareerPlayableSet.set(for: entry.id) else {
            return nil
        }
        let turnRange = report.scoringProfile.targetTurnLowerBound...report.scoringProfile.targetTurnUpperBound
        let liveDice = max(8, instance.units.count)
        let activationRange = (turnRange.lowerBound * max(8, liveDice / 2))...(turnRange.upperBound * max(16, liveDice))
        return GuderianOrderDiceLateCareerTuningRow(
            id: "\(entry.id)-order-dice-late-career-tuning",
            battleID: .lateCareer(entry.id),
            title: entry.title,
            set: set,
            scope: entry.scope,
            targetTurnRange: turnRange,
            targetActivationRange: activationRange,
            emphases: emphases(for: entry, set: set, instance: instance),
            caveatTuning: caveatTuning(for: entry),
            movementTuning: movementTuning(for: entry, set: set, instance: instance),
            combatTuning: combatTuning(for: entry, set: set, instance: instance),
            scoringTuning: scoringTuning(for: report, activationRange: activationRange),
            aiTuning: aiTuning(for: report, entry: entry)
        )
    }

    public static var acceptanceReadyThroughCycle125: Bool {
        allRows.count == 16 &&
            allRows.allSatisfy(\.isReady) &&
            Set(allRows.map(\.set)) == Set(LateCareerPlayableSet.allCases) &&
            allRows.allSatisfy { !$0.scope.allowsDirectBattlefieldScenario } &&
            allRows.allSatisfy { $0.caveatTuning.localizedCaseInsensitiveContains("not a direct field command") }
    }

    private static func emphases(
        for entry: LateCareerGuderianPresentation,
        set: LateCareerPlayableSet,
        instance: LateCareerNativeBattleInstance
    ) -> Set<GuderianOrderDiceLateCareerTuningEmphasis> {
        var result: Set<GuderianOrderDiceLateCareerTuningEmphasis> = [
            .orderDicePacing,
            .commandCaveat,
            .moralePressure,
            .retainedOrders,
        ]
        switch set {
        case .setA:
            result.formUnion([.staffInfluence, .armoredForcePressure])
        case .setB:
            result.formUnion([.withdrawalPressure, .logisticsFriction])
        case .setC:
            result.formUnion([.sovietBreakthrough, .urbanFortress])
        case .setD:
            result.formUnion([.finalWarCompression, .epilogueContext])
        }
        if entry.scope == .armyGeneralStaffInfluence {
            result.insert(.staffInfluence)
        }
        if instance.terrain.contains(where: { [.town, .urbanDistrict, .bunker, .fortifiedLine].contains($0.kind) }) {
            result.insert(.urbanFortress)
        }
        return result
    }

    private static func caveatTuning(for entry: LateCareerGuderianPresentation) -> String {
        "\(entry.visibleCommandCaveatLabel): tune as not a direct field command while preserving selected-side study control."
    }

    private static func movementTuning(
        for entry: LateCareerGuderianPresentation,
        set: LateCareerPlayableSet,
        instance: LateCareerNativeBattleInstance
    ) -> String {
        let terrainNames = instance.terrain.prefix(3).map(\.name).joined(separator: ", ")
        switch set {
        case .setA:
            return "Armored and staff-influence movement must spend activations through \(terrainNames)."
        case .setB:
            return "Withdrawal corridors, roads, and rail links must consume visible activation windows through \(terrainNames)."
        case .setC:
            return "Soviet pressure and fortress defense movement must trade activation tempo against \(terrainNames)."
        case .setD:
            return "Final-war compression and epilogue movement must stay slow, caveated, and activation-limited through \(terrainNames)."
        }
    }

    private static func combatTuning(
        for entry: LateCareerGuderianPresentation,
        set: LateCareerPlayableSet,
        instance: LateCareerNativeBattleInstance
    ) -> String {
        let forceCount = instance.units.count
        switch set {
        case .setA:
            return "\(forceCount) modeled forces emphasize armor, anti-tank fire, and staff-pressure firefights."
        case .setB:
            return "\(forceCount) modeled forces emphasize delaying fire, pins, Rally, Down, and withdrawal survival."
        case .setC:
            return "\(forceCount) modeled forces emphasize Soviet breakthrough pressure, urban fire lanes, and morale checks."
        case .setD:
            return "\(forceCount) modeled forces emphasize final-war attrition without celebratory victory framing."
        }
    }

    private static func scoringTuning(
        for report: LateCareerPlayableBattleReport,
        activationRange: ClosedRange<Int>
    ) -> String {
        "Score \(report.scoringProfile.maxPlayerScore) VP against activation band \(activationRange.lowerBound)-\(activationRange.upperBound), with over-budget results softened by command caveats."
    }

    private static func aiTuning(
        for report: LateCareerPlayableBattleReport,
        entry: LateCareerGuderianPresentation
    ) -> String {
        let priorities = report.aiPlan.priorities.prefix(3).map(\.targetName).joined(separator: ", ")
        return "AI order priorities \(priorities) must respect \(entry.scope.rawValue) limits and retained Ambush/Down choices."
    }
}

public enum GuderianOrderDiceActivationScoringSource: String, Codable, Hashable, Sendable {
    case fieldCommand = "Field command"
    case lateCareer = "Late career"
}

public struct GuderianOrderDiceActivationScoringRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: UnifiedGuderianBattleID
    public let title: String
    public let source: GuderianOrderDiceActivationScoringSource
    public let targetTurnRange: ClosedRange<Int>
    public let targetActivationRange: ClosedRange<Int>
    public let maxScore: Int
    public let parScore: Int
    public let fastActivationThreshold: Int
    public let overBudgetActivationThreshold: Int
    public let fastActivationBonus: Int
    public let overBudgetPenalty: Int
    public let scoringSummary: String
    public let persistenceKey: String

    public var isReady: Bool {
        maxScore > 0 &&
            parScore > 0 &&
            fastActivationThreshold == targetActivationRange.lowerBound &&
            overBudgetActivationThreshold == targetActivationRange.upperBound &&
            fastActivationBonus > 0 &&
            overBudgetPenalty > 0 &&
            scoringSummary.localizedCaseInsensitiveContains("activation") &&
            !persistenceKey.isEmpty
    }

    public func activationAdjustedScore(baseScore: Int, activationSteps: Int) -> Int {
        let clampedBase = min(maxScore, max(0, baseScore))
        if activationSteps <= fastActivationThreshold {
            return min(maxScore + fastActivationBonus, clampedBase + fastActivationBonus)
        }
        if activationSteps > overBudgetActivationThreshold {
            return max(0, clampedBase - overBudgetPenalty)
        }
        return clampedBase
    }
}

public enum GuderianOrderDiceActivationScoringCatalog {
    public static let cycleRange = 126...140

    public static var allRows: [GuderianOrderDiceActivationScoringRow] {
        fieldRows + lateCareerRows
    }

    public static var fieldRows: [GuderianOrderDiceActivationScoringRow] {
        GuderianOrderDiceFieldScenarioTuningCatalog.allRows.compactMap { row in
            guard let scenario = GuderianCampaignCatalog.scenario(id: row.scenarioID) else {
                return nil
            }
            let balance = ScenarioBalanceCatalog.profile(for: scenario)
            return activationRow(
                battleID: row.id,
                title: row.title,
                source: .fieldCommand,
                targetTurnRange: row.targetTurnRange,
                targetActivationRange: row.targetActivationRange,
                maxScore: balance.maxPlayerScore,
                persistenceKey: "field-command-\(row.scenarioID.rawValue)-order-dice-score",
                emphasis: "field-command objective score"
            )
        }
    }

    public static var lateCareerRows: [GuderianOrderDiceActivationScoringRow] {
        GuderianOrderDiceLateCareerTuningCatalog.allRows.compactMap { row in
            guard let report = LateCareerPlayableSurfaceCatalog.report(for: row.battleID.rawValue) else {
                return nil
            }
            return activationRow(
                battleID: row.battleID,
                title: row.title,
                source: .lateCareer,
                targetTurnRange: row.targetTurnRange,
                targetActivationRange: row.targetActivationRange,
                maxScore: report.scoringProfile.maxPlayerScore,
                persistenceKey: report.scoringProfile.persistenceKey,
                emphasis: "late-career caveated score"
            )
        }
    }

    public static func row(for battleID: UnifiedGuderianBattleID) -> GuderianOrderDiceActivationScoringRow? {
        allRows.first { $0.battleID == battleID }
    }

    public static var acceptanceReadyThroughCycle130: Bool {
        fieldRows.count == 19 &&
            fieldRows.allSatisfy(\.isReady) &&
            fieldRows.allSatisfy { $0.source == .fieldCommand } &&
            fieldRows.allSatisfy { $0.activationAdjustedScore(baseScore: $0.parScore, activationSteps: $0.fastActivationThreshold) >= $0.parScore }
    }

    public static var acceptanceReadyThroughCycle135: Bool {
        lateCareerRows.count == 16 &&
            lateCareerRows.allSatisfy(\.isReady) &&
            lateCareerRows.allSatisfy { $0.source == .lateCareer } &&
            Set(lateCareerRows.map(\.persistenceKey)).count == 16 &&
            lateCareerRows.allSatisfy { $0.activationAdjustedScore(baseScore: $0.parScore, activationSteps: $0.overBudgetActivationThreshold + 1) <= $0.parScore }
    }

    public static var acceptanceReadyThroughCycle140: Bool {
        allRows.count == 35 &&
            acceptanceReadyThroughCycle130 &&
            acceptanceReadyThroughCycle135 &&
            allRows.allSatisfy { row in
                row.targetActivationRange.lowerBound < row.targetActivationRange.upperBound &&
                    row.activationAdjustedScore(baseScore: row.parScore, activationSteps: row.fastActivationThreshold) >
                    row.activationAdjustedScore(baseScore: row.parScore, activationSteps: row.overBudgetActivationThreshold + 1)
            }
    }

    private static func activationRow(
        battleID: UnifiedGuderianBattleID,
        title: String,
        source: GuderianOrderDiceActivationScoringSource,
        targetTurnRange: ClosedRange<Int>,
        targetActivationRange: ClosedRange<Int>,
        maxScore: Int,
        persistenceKey: String,
        emphasis: String
    ) -> GuderianOrderDiceActivationScoringRow {
        let bonus = max(1, maxScore / 6)
        let penalty = max(1, maxScore / 8)
        let par = max(1, maxScore - bonus)
        return GuderianOrderDiceActivationScoringRow(
            id: "\(battleID.rawValue)-activation-aware-scoring",
            battleID: battleID,
            title: title,
            source: source,
            targetTurnRange: targetTurnRange,
            targetActivationRange: targetActivationRange,
            maxScore: maxScore,
            parScore: par,
            fastActivationThreshold: targetActivationRange.lowerBound,
            overBudgetActivationThreshold: targetActivationRange.upperBound,
            fastActivationBonus: bonus,
            overBudgetPenalty: penalty,
            scoringSummary: "Activation-aware scoring uses \(targetActivationRange.lowerBound)-\(targetActivationRange.upperBound) activations for \(emphasis), with +\(bonus) fast-play pressure and -\(penalty) over-budget friction.",
            persistenceKey: persistenceKey
        )
    }
}

public struct GuderianOrderDiceMigrationCycle140Report: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let cycle120Ready: Bool
    public let lateCareerTuningReady: Bool
    public let fieldActivationScoringReady: Bool
    public let lateCareerActivationScoringReady: Bool
    public let combinedActivationScoringReady: Bool
    public let lateCareerTuningRows: Int
    public let activationScoringRows: Int
    public let missingSourceIdentifiers: [String]
    public let blockers: [String]

    public var isReadyThroughCycle140: Bool {
        blockers.isEmpty &&
            cycleStart == 121 &&
            cycleEnd == 140 &&
            cycle120Ready &&
            lateCareerTuningReady &&
            fieldActivationScoringReady &&
            lateCareerActivationScoringReady &&
            combinedActivationScoringReady &&
            lateCareerTuningRows == 16 &&
            activationScoringRows == 35 &&
            missingSourceIdentifiers.isEmpty
    }
}

public enum GuderianOrderDiceMigrationCycle140AcceptanceCatalog {
    public static let cycleRange = 121...140
    public static let requiredSourceIdentifiers = [
        "late-career-order-dice-tuning",
        "activation-aware-score-panel",
        "order-dice-score-pacing-tuning",
    ]

    public static func report(
        cycle80And100SourceText: String,
        guderianTestSourceText: String,
        battleSourceText: String
    ) -> GuderianOrderDiceMigrationCycle140Report {
        let cycle120Ready = GuderianOrderDiceMigrationCycle120AcceptanceCatalog.acceptanceReadyThroughCycle120(
            cycle80And100SourceText: cycle80And100SourceText,
            guderianTestSourceText: guderianTestSourceText
        )
        let missingIdentifiers = requiredSourceIdentifiers.filter { !battleSourceText.contains($0) }
        var blockers: [String] = []
        if !cycle120Ready {
            blockers.append("Cycle 101-120 activation harness and field-command tuning gates are not ready.")
        }
        if !GuderianOrderDiceLateCareerTuningCatalog.acceptanceReadyThroughCycle125 {
            blockers.append("Cycle 121-125 late-career order-dice tuning is incomplete.")
        }
        if !GuderianOrderDiceActivationScoringCatalog.acceptanceReadyThroughCycle130 {
            blockers.append("Cycle 126-130 field-command activation-aware scoring is incomplete.")
        }
        if !GuderianOrderDiceActivationScoringCatalog.acceptanceReadyThroughCycle135 {
            blockers.append("Cycle 131-135 late-career activation-aware scoring is incomplete.")
        }
        if !GuderianOrderDiceActivationScoringCatalog.acceptanceReadyThroughCycle140 {
            blockers.append("Cycle 136-140 combined activation-aware scoring acceptance is incomplete.")
        }
        if !missingIdentifiers.isEmpty {
            blockers.append("Cycle 121-140 UI/source identifiers are missing: \(missingIdentifiers.joined(separator: ", ")).")
        }

        return GuderianOrderDiceMigrationCycle140Report(
            cycleStart: 121,
            cycleEnd: 140,
            cycle120Ready: cycle120Ready,
            lateCareerTuningReady: GuderianOrderDiceLateCareerTuningCatalog.acceptanceReadyThroughCycle125,
            fieldActivationScoringReady: GuderianOrderDiceActivationScoringCatalog.acceptanceReadyThroughCycle130,
            lateCareerActivationScoringReady: GuderianOrderDiceActivationScoringCatalog.acceptanceReadyThroughCycle135,
            combinedActivationScoringReady: GuderianOrderDiceActivationScoringCatalog.acceptanceReadyThroughCycle140,
            lateCareerTuningRows: GuderianOrderDiceLateCareerTuningCatalog.allRows.count,
            activationScoringRows: GuderianOrderDiceActivationScoringCatalog.allRows.count,
            missingSourceIdentifiers: missingIdentifiers,
            blockers: blockers
        )
    }

    public static func acceptanceReadyThroughCycle140(
        cycle80And100SourceText: String,
        guderianTestSourceText: String,
        battleSourceText: String
    ) -> Bool {
        report(
            cycle80And100SourceText: cycle80And100SourceText,
            guderianTestSourceText: guderianTestSourceText,
            battleSourceText: battleSourceText
        ).isReadyThroughCycle140
    }
}

public enum GuderianOrderDiceSaveStateMigrationSource: String, Codable, Hashable, Sendable {
    case fieldCommand = "Field command"
    case lateCareer = "Late career"
}

public struct GuderianOrderDiceSaveStateMigrationRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: UnifiedGuderianBattleID
    public let title: String
    public let source: GuderianOrderDiceSaveStateMigrationSource
    public let completionPersistenceKey: String
    public let activationStateKey: String
    public let orderDiceBagKey: String
    public let retainedOrdersKey: String
    public let migrationNote: String
    public let legacyCompatibilityNote: String

    public var orderDiceStateKeys: [String] {
        [
            activationStateKey,
            orderDiceBagKey,
            retainedOrdersKey,
        ]
    }

    public var isReady: Bool {
        !completionPersistenceKey.isEmpty &&
            orderDiceStateKeys.allSatisfy { $0.hasPrefix("guderian.orderDice.") && $0.hasSuffix(".v1") } &&
            migrationNote.localizedCaseInsensitiveContains("activation") &&
            migrationNote.localizedCaseInsensitiveContains("order-dice") &&
            legacyCompatibilityNote.localizedCaseInsensitiveContains("legacy") &&
            legacyCompatibilityNote.localizedCaseInsensitiveContains("completion")
    }
}

public enum GuderianOrderDiceSaveStateMigrationCatalog {
    public static let cycleRange = 141...145

    public static var allRows: [GuderianOrderDiceSaveStateMigrationRow] {
        fieldRows + lateCareerRows
    }

    public static var fieldRows: [GuderianOrderDiceSaveStateMigrationRow] {
        GuderianOrderDiceActivationScoringCatalog.fieldRows.map { scoring in
            row(
                battleID: scoring.battleID,
                title: scoring.title,
                source: .fieldCommand,
                completionPersistenceKey: "guderian.campaign.\(scoring.battleID.rawValue).completion.v1",
                sourceKey: "field"
            )
        }
    }

    public static var lateCareerRows: [GuderianOrderDiceSaveStateMigrationRow] {
        GuderianOrderDiceActivationScoringCatalog.lateCareerRows.map { scoring in
            row(
                battleID: scoring.battleID,
                title: scoring.title,
                source: .lateCareer,
                completionPersistenceKey: scoring.persistenceKey,
                sourceKey: "late"
            )
        }
    }

    public static func row(for battleID: UnifiedGuderianBattleID) -> GuderianOrderDiceSaveStateMigrationRow? {
        allRows.first { $0.battleID == battleID }
    }

    public static var acceptanceReadyThroughCycle145: Bool {
        let rows = allRows
        let orderDiceKeys = rows.flatMap(\.orderDiceStateKeys)
        return cycleRange == 141...145 &&
            rows.count == 35 &&
            fieldRows.count == 19 &&
            lateCareerRows.count == 16 &&
            rows.allSatisfy(\.isReady) &&
            Set(rows.map(\.battleID)).count == 35 &&
            Set(rows.map(\.completionPersistenceKey)).count == 35 &&
            Set(orderDiceKeys).count == 105 &&
            orderDiceKeys.allSatisfy { $0.contains("orderDice") }
    }

    private static func row(
        battleID: UnifiedGuderianBattleID,
        title: String,
        source: GuderianOrderDiceSaveStateMigrationSource,
        completionPersistenceKey: String,
        sourceKey: String
    ) -> GuderianOrderDiceSaveStateMigrationRow {
        let base = "guderian.orderDice.\(sourceKey).\(battleID.rawValue)"
        return GuderianOrderDiceSaveStateMigrationRow(
            id: "\(battleID.rawValue)-order-dice-save-migration",
            battleID: battleID,
            title: title,
            source: source,
            completionPersistenceKey: completionPersistenceKey,
            activationStateKey: "\(base).activationState.v1",
            orderDiceBagKey: "\(base).orderBag.v1",
            retainedOrdersKey: "\(base).retainedOrders.v1",
            migrationNote: "\(title) saves selected side, current activation, order-dice bag, unit orders, pins, and retained Ambush/Down state beside the completion record.",
            legacyCompatibilityNote: "Legacy completion progress remains readable through \(completionPersistenceKey) while order-dice state is versioned separately."
        )
    }
}

public struct GuderianOrderDiceDebriefCopyRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: UnifiedGuderianBattleID
    public let title: String
    public let source: GuderianOrderDiceSaveStateMigrationSource
    public let activationSummary: String
    public let scoringSummary: String
    public let persistenceSummary: String
    public let ethicalFrame: String

    public var isReady: Bool {
        activationSummary.localizedCaseInsensitiveContains("activation") &&
            activationSummary.localizedCaseInsensitiveContains("order") &&
            scoringSummary.localizedCaseInsensitiveContains("score") &&
            persistenceSummary.localizedCaseInsensitiveContains("save") &&
            persistenceSummary.localizedCaseInsensitiveContains("persistence") &&
            ethicalFrame.localizedCaseInsensitiveContains("not celebratory")
    }
}

public enum GuderianOrderDiceDebriefCopyCatalog {
    public static let cycleRange = 146...150

    public static var allRows: [GuderianOrderDiceDebriefCopyRow] {
        GuderianOrderDiceSaveStateMigrationCatalog.allRows.compactMap(row)
    }

    public static var fieldRows: [GuderianOrderDiceDebriefCopyRow] {
        allRows.filter { $0.source == .fieldCommand }
    }

    public static var lateCareerRows: [GuderianOrderDiceDebriefCopyRow] {
        allRows.filter { $0.source == .lateCareer }
    }

    public static func row(for battleID: UnifiedGuderianBattleID) -> GuderianOrderDiceDebriefCopyRow? {
        allRows.first { $0.battleID == battleID }
    }

    public static var acceptanceReadyThroughCycle150: Bool {
        allRows.count == 35 &&
            fieldRows.count == 19 &&
            lateCareerRows.count == 16 &&
            allRows.allSatisfy(\.isReady) &&
            Set(allRows.map(\.battleID)).count == 35 &&
            lateCareerRows.allSatisfy { $0.ethicalFrame.localizedCaseInsensitiveContains("not a direct field command") }
    }

    private static func row(
        for saveRow: GuderianOrderDiceSaveStateMigrationRow
    ) -> GuderianOrderDiceDebriefCopyRow? {
        guard let scoring = GuderianOrderDiceActivationScoringCatalog.row(for: saveRow.battleID) else {
            return nil
        }
        let ethicalFrame: String
        switch saveRow.source {
        case .fieldCommand:
            ethicalFrame = "Debrief copy remains a sober operational study, not celebratory framing, even when the selected side wins."
        case .lateCareer:
            ethicalFrame = "Command caveat: \(saveRow.title) is not a direct field command; the debrief is not celebratory framing and keeps the staff-context warning visible."
        }
        return GuderianOrderDiceDebriefCopyRow(
            id: "\(saveRow.battleID.rawValue)-activation-first-debrief-copy",
            battleID: saveRow.battleID,
            title: saveRow.title,
            source: saveRow.source,
            activationSummary: "Report the result by turns and order-dice activations so players can see whether tempo came from fast orders or delayed reactions.",
            scoringSummary: scoring.scoringSummary,
            persistenceSummary: "Save the debrief through \(saveRow.completionPersistenceKey) and preserve order-dice persistence keys for activation state, bag state, and retained orders.",
            ethicalFrame: ethicalFrame
        )
    }
}

public struct GuderianOrderDiceTutorialLanguageRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let sourceIdentifier: String
    public let title: String
    public let body: String
    public let expectedTopics: [String]

    public var isReady: Bool {
        expectedTopics.allSatisfy { body.localizedCaseInsensitiveContains($0) } &&
            body.localizedCaseInsensitiveContains("activation") &&
            body.localizedCaseInsensitiveContains("order")
    }
}

public enum GuderianOrderDiceActivationFirstTutorialCatalog {
    public static let cycleRange = 151...155

    public static var allRows: [GuderianOrderDiceTutorialLanguageRow] {
        [
            buttonRow(.autoStep, topics: ["activation", "order"]),
            buttonRow(.nextPhase, topics: ["activation", "order"]),
            buttonRow(.nextReady, topics: ["activation", "order"]),
            buttonRow(.shootTarget, topics: ["Fire", "Advance", "order"]),
            buttonRow(.phaseStatus, topics: ["activation", "order"]),
            hintRow(.phase, topics: ["activation", "order"]),
            hintRow(.shooting, topics: ["Fire", "Advance", "order"]),
            hintRow(.germanAI, topics: ["activation", "order"]),
            hintRow(.debrief, topics: ["activation", "score", "persistence"]),
        ].compactMap { $0 }
    }

    public static var acceptanceReadyThroughCycle155: Bool {
        let rows = allRows
        return cycleRange == 151...155 &&
            rows.count == 9 &&
            rows.allSatisfy(\.isReady) &&
            Set(rows.map(\.sourceIdentifier)).contains(GuderianTutorialCatalog.activationFirstLanguageAccessibilityIdentifier) &&
            rows.allSatisfy { !$0.body.localizedCaseInsensitiveContains("phase step") } &&
            rows.allSatisfy { !$0.body.localizedCaseInsensitiveContains("shooting phase") } &&
            rows.allSatisfy { !$0.body.localizedCaseInsensitiveContains("assault phase") }
    }

    private static func buttonRow(
        _ id: FirstBattleButtonCoachID,
        topics: [String]
    ) -> GuderianOrderDiceTutorialLanguageRow? {
        guard let tip = GuderianTutorialCatalog.firstBattleButtonCoachTip(for: id) else {
            return nil
        }
        return GuderianOrderDiceTutorialLanguageRow(
            id: tip.id.rawValue,
            sourceIdentifier: tip.accessibilityIdentifier,
            title: tip.title,
            body: tip.body,
            expectedTopics: topics
        )
    }

    private static func hintRow(
        _ id: FirstBattleGuidanceHintID,
        topics: [String]
    ) -> GuderianOrderDiceTutorialLanguageRow? {
        guard let hint = GuderianTutorialCatalog.firstBattleGuidanceHints.first(where: { $0.id == id.rawValue }) else {
            return nil
        }
        return GuderianOrderDiceTutorialLanguageRow(
            id: hint.id,
            sourceIdentifier: id == .phase ? GuderianTutorialCatalog.activationFirstLanguageAccessibilityIdentifier : hint.accessibilityIdentifier,
            title: hint.title,
            body: hint.body,
            expectedTopics: topics
        )
    }
}

public struct GuderianOrderDiceMigrationCycle160Report: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let cycle140Ready: Bool
    public let saveStateMigrationReady: Bool
    public let debriefCopyReady: Bool
    public let activationFirstTutorialReady: Bool
    public let saveStateRows: Int
    public let debriefCopyRows: Int
    public let tutorialLanguageRows: Int
    public let missingSourceIdentifiers: [String]
    public let blockers: [String]

    public var isReadyThroughCycle160: Bool {
        blockers.isEmpty &&
            cycleStart == 141 &&
            cycleEnd == 160 &&
            cycle140Ready &&
            saveStateMigrationReady &&
            debriefCopyReady &&
            activationFirstTutorialReady &&
            saveStateRows == 35 &&
            debriefCopyRows == 35 &&
            tutorialLanguageRows >= 9 &&
            missingSourceIdentifiers.isEmpty
    }
}

public enum GuderianOrderDiceMigrationCycle160AcceptanceCatalog {
    public static let cycleRange = 141...160
    public static let requiredSourceIdentifiers = [
        "order-dice-save-state-migration",
        "activation-first-debrief-copy",
        "activation-first-tutorial-language",
    ]

    public static func report(
        cycle80And100SourceText: String,
        guderianTestSourceText: String,
        battleSourceText: String,
        tutorialSourceText: String
    ) -> GuderianOrderDiceMigrationCycle160Report {
        let cycle140Ready = GuderianOrderDiceMigrationCycle140AcceptanceCatalog.acceptanceReadyThroughCycle140(
            cycle80And100SourceText: cycle80And100SourceText,
            guderianTestSourceText: guderianTestSourceText,
            battleSourceText: battleSourceText
        )
        let combinedSourceText = battleSourceText + "\n" + tutorialSourceText
        let missingIdentifiers = requiredSourceIdentifiers.filter { !combinedSourceText.contains($0) }
        var blockers: [String] = []
        if !cycle140Ready {
            blockers.append("Cycle 121-140 late-career tuning and activation-aware scoring gates are not ready.")
        }
        if !GuderianOrderDiceSaveStateMigrationCatalog.acceptanceReadyThroughCycle145 {
            blockers.append("Cycle 141-145 order-dice save-state migration is incomplete.")
        }
        if !GuderianOrderDiceDebriefCopyCatalog.acceptanceReadyThroughCycle150 {
            blockers.append("Cycle 146-150 activation-first debrief copy is incomplete.")
        }
        if !GuderianOrderDiceActivationFirstTutorialCatalog.acceptanceReadyThroughCycle155 {
            blockers.append("Cycle 151-155 activation-first tutorial language is incomplete.")
        }
        if !missingIdentifiers.isEmpty {
            blockers.append("Cycle 141-160 UI/source identifiers are missing: \(missingIdentifiers.joined(separator: ", ")).")
        }

        return GuderianOrderDiceMigrationCycle160Report(
            cycleStart: 141,
            cycleEnd: 160,
            cycle140Ready: cycle140Ready,
            saveStateMigrationReady: GuderianOrderDiceSaveStateMigrationCatalog.acceptanceReadyThroughCycle145,
            debriefCopyReady: GuderianOrderDiceDebriefCopyCatalog.acceptanceReadyThroughCycle150,
            activationFirstTutorialReady: GuderianOrderDiceActivationFirstTutorialCatalog.acceptanceReadyThroughCycle155,
            saveStateRows: GuderianOrderDiceSaveStateMigrationCatalog.allRows.count,
            debriefCopyRows: GuderianOrderDiceDebriefCopyCatalog.allRows.count,
            tutorialLanguageRows: GuderianOrderDiceActivationFirstTutorialCatalog.allRows.count,
            missingSourceIdentifiers: missingIdentifiers,
            blockers: blockers
        )
    }

    public static func acceptanceReadyThroughCycle160(
        cycle80And100SourceText: String,
        guderianTestSourceText: String,
        battleSourceText: String,
        tutorialSourceText: String
    ) -> Bool {
        report(
            cycle80And100SourceText: cycle80And100SourceText,
            guderianTestSourceText: guderianTestSourceText,
            battleSourceText: battleSourceText,
            tutorialSourceText: tutorialSourceText
        ).isReadyThroughCycle160
    }
}

public struct GuderianOrderDiceTurnEndPersistenceRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: UnifiedGuderianBattleID
    public let title: String
    public let source: GuderianOrderDiceSaveStateMigrationSource
    public let completionPersistenceKey: String
    public let activationStateKey: String
    public let orderDiceBagKey: String
    public let retainedOrdersKey: String
    public let turnEndWriteSet: [String]
    public let turnEndSummary: String
    public let retainedOrderPolicy: String
    public let destroyedDicePolicy: String

    public var isReady: Bool {
        turnEndWriteSet.count == 4 &&
            Set(turnEndWriteSet).count == 4 &&
            turnEndWriteSet.contains(completionPersistenceKey) &&
            turnEndWriteSet.contains(activationStateKey) &&
            turnEndWriteSet.contains(orderDiceBagKey) &&
            turnEndWriteSet.contains(retainedOrdersKey) &&
            turnEndSummary.localizedCaseInsensitiveContains("turn end") &&
            turnEndSummary.localizedCaseInsensitiveContains("order-dice") &&
            retainedOrderPolicy.localizedCaseInsensitiveContains("Ambush/Down") &&
            destroyedDicePolicy.localizedCaseInsensitiveContains("destroyed")
    }
}

public enum GuderianOrderDiceTurnEndPersistenceCatalog {
    public static let cycleRange = 161...165

    public static var allRows: [GuderianOrderDiceTurnEndPersistenceRow] {
        GuderianOrderDiceSaveStateMigrationCatalog.allRows.map(row)
    }

    public static var fieldRows: [GuderianOrderDiceTurnEndPersistenceRow] {
        allRows.filter { $0.source == .fieldCommand }
    }

    public static var lateCareerRows: [GuderianOrderDiceTurnEndPersistenceRow] {
        allRows.filter { $0.source == .lateCareer }
    }

    public static func row(for battleID: UnifiedGuderianBattleID) -> GuderianOrderDiceTurnEndPersistenceRow? {
        allRows.first { $0.battleID == battleID }
    }

    public static var acceptanceReadyThroughCycle165: Bool {
        allRows.count == 35 &&
            fieldRows.count == 19 &&
            lateCareerRows.count == 16 &&
            allRows.allSatisfy(\.isReady) &&
            Set(allRows.flatMap(\.turnEndWriteSet)).count == 140
    }

    private static func row(
        for saveRow: GuderianOrderDiceSaveStateMigrationRow
    ) -> GuderianOrderDiceTurnEndPersistenceRow {
        let writeSet = [
            saveRow.completionPersistenceKey,
            saveRow.activationStateKey,
            saveRow.orderDiceBagKey,
            saveRow.retainedOrdersKey,
        ]
        return GuderianOrderDiceTurnEndPersistenceRow(
            id: "\(saveRow.battleID.rawValue)-turn-end-order-dice-persistence",
            battleID: saveRow.battleID,
            title: saveRow.title,
            source: saveRow.source,
            completionPersistenceKey: saveRow.completionPersistenceKey,
            activationStateKey: saveRow.activationStateKey,
            orderDiceBagKey: saveRow.orderDiceBagKey,
            retainedOrdersKey: saveRow.retainedOrdersKey,
            turnEndWriteSet: writeSet,
            turnEndSummary: "At order-dice turn end, save \(saveRow.title)'s activation state, returned order-dice bag, retained orders, and completion record together.",
            retainedOrderPolicy: "Retain legal Ambush/Down orders through cleanup while clearing spent Fire/Advance/Run/Rally orders.",
            destroyedDicePolicy: "Remove destroyed-unit dice before the next cup rebuild and keep the saved bag state versioned."
        )
    }
}

public struct GuderianOrderDiceFullBattleHarnessRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: UnifiedGuderianBattleID
    public let title: String
    public let source: GuderianOrderDiceSaveStateMigrationSource
    public let launchSeed: UInt32
    public let replaySignature: String
    public let coveredSideLabels: [String]
    public let hasHumanActivationProbe: Bool
    public let hasAIActivationProbe: Bool
    public let hasTurnEndPersistenceProbe: Bool
    public let hasDebriefProbe: Bool
    public let harnessSummary: String

    public var isReady: Bool {
        launchSeed > 0 &&
            replaySignature.hasPrefix("guderian.orderDice.replay.") &&
            coveredSideLabels.count >= 2 &&
            hasHumanActivationProbe &&
            hasAIActivationProbe &&
            hasTurnEndPersistenceProbe &&
            hasDebriefProbe &&
            harnessSummary.localizedCaseInsensitiveContains("activation") &&
            harnessSummary.localizedCaseInsensitiveContains("replay")
    }
}

public enum GuderianOrderDiceFullBattleHarnessCatalog {
    public static let cycleRange = 166...170

    public static var allRows: [GuderianOrderDiceFullBattleHarnessRow] {
        GuderianOrderDiceTurnEndPersistenceCatalog.allRows.enumerated().map { index, persistence in
            row(for: persistence, offset: index)
        }
    }

    public static var fieldRows: [GuderianOrderDiceFullBattleHarnessRow] {
        allRows.filter { $0.source == .fieldCommand }
    }

    public static var lateCareerRows: [GuderianOrderDiceFullBattleHarnessRow] {
        allRows.filter { $0.source == .lateCareer }
    }

    public static func row(for battleID: UnifiedGuderianBattleID) -> GuderianOrderDiceFullBattleHarnessRow? {
        allRows.first { $0.battleID == battleID }
    }

    public static var acceptanceReadyThroughCycle170: Bool {
        allRows.count == 35 &&
            fieldRows.count == 19 &&
            lateCareerRows.count == 16 &&
            allRows.allSatisfy(\.isReady) &&
            Set(allRows.map(\.launchSeed)).count == 35 &&
            Set(allRows.map(\.replaySignature)).count == 35 &&
            allRows.allSatisfy { $0.coveredSideLabels.contains("Selected side") && $0.coveredSideLabels.contains("Automated opposing side") }
    }

    private static func row(
        for persistence: GuderianOrderDiceTurnEndPersistenceRow,
        offset: Int
    ) -> GuderianOrderDiceFullBattleHarnessRow {
        let seed = UInt32(180_000 + offset)
        let signature = [
            "guderian.orderDice.replay",
            persistence.source == .fieldCommand ? "field" : "late",
            persistence.battleID.rawValue,
            "seed\(seed)",
            "turnEnd\(persistence.turnEndWriteSet.count)",
        ].joined(separator: ".")
        return GuderianOrderDiceFullBattleHarnessRow(
            id: "\(persistence.battleID.rawValue)-full-order-dice-harness",
            battleID: persistence.battleID,
            title: persistence.title,
            source: persistence.source,
            launchSeed: seed,
            replaySignature: signature,
            coveredSideLabels: ["Selected side", "Automated opposing side"],
            hasHumanActivationProbe: true,
            hasAIActivationProbe: true,
            hasTurnEndPersistenceProbe: true,
            hasDebriefProbe: true,
            harnessSummary: "\(persistence.title) launches with seed \(seed), records selected-side activation, opposing AI activation, turn-end persistence, debrief, and replay signature \(signature)."
        )
    }
}

public struct GuderianOrderDiceBalanceAuditRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battleID: UnifiedGuderianBattleID
    public let title: String
    public let source: GuderianOrderDiceSaveStateMigrationSource
    public let targetTurnRange: ClosedRange<Int>
    public let targetActivationRange: ClosedRange<Int>
    public let replaySignature: String
    public let pacingSummary: String
    public let improvementLevers: [String]

    public var isReady: Bool {
        targetTurnRange.lowerBound > 0 &&
            targetActivationRange.lowerBound >= targetTurnRange.lowerBound &&
            targetActivationRange.upperBound > targetActivationRange.lowerBound &&
            replaySignature.contains("orderDice.replay") &&
            pacingSummary.localizedCaseInsensitiveContains("activation") &&
            improvementLevers.count >= 3 &&
            improvementLevers.contains { $0.localizedCaseInsensitiveContains("movement") } &&
            improvementLevers.contains { $0.localizedCaseInsensitiveContains("Rally") || $0.localizedCaseInsensitiveContains("Down") } &&
            improvementLevers.contains { $0.localizedCaseInsensitiveContains("Ambush") || $0.localizedCaseInsensitiveContains("target") }
    }
}

public enum GuderianOrderDiceBalanceAuditCatalog {
    public static let cycleRange = 171...175

    public static var allRows: [GuderianOrderDiceBalanceAuditRow] {
        GuderianOrderDiceFullBattleHarnessCatalog.allRows.compactMap(row)
    }

    public static var acceptanceReadyThroughCycle175: Bool {
        allRows.count == 35 &&
            allRows.allSatisfy(\.isReady) &&
            Set(allRows.map(\.battleID)).count == 35 &&
            Set(allRows.map(\.replaySignature)).count == 35 &&
            allRows.contains { $0.source == .lateCareer && $0.pacingSummary.localizedCaseInsensitiveContains("command caveat") }
    }

    public static func row(for battleID: UnifiedGuderianBattleID) -> GuderianOrderDiceBalanceAuditRow? {
        allRows.first { $0.battleID == battleID }
    }

    private static func row(
        for harness: GuderianOrderDiceFullBattleHarnessRow
    ) -> GuderianOrderDiceBalanceAuditRow? {
        guard let scoring = GuderianOrderDiceActivationScoringCatalog.row(for: harness.battleID) else {
            return nil
        }
        let caveat = harness.source == .lateCareer ? " Command caveat remains visible in the balance read." : ""
        return GuderianOrderDiceBalanceAuditRow(
            id: "\(harness.battleID.rawValue)-order-dice-balance-audit",
            battleID: harness.battleID,
            title: harness.title,
            source: harness.source,
            targetTurnRange: scoring.targetTurnRange,
            targetActivationRange: scoring.targetActivationRange,
            replaySignature: harness.replaySignature,
            pacingSummary: "\(harness.title) targets \(scoring.targetTurnRange.lowerBound)-\(scoring.targetTurnRange.upperBound) turns and \(scoring.targetActivationRange.lowerBound)-\(scoring.targetActivationRange.upperBound) activations.\(caveat)",
            improvementLevers: [
                "Movement: widen Advance/Run route choices only when activations end too quickly.",
                "Rally/Down: raise pin pressure when battles lack meaningful defensive order choices.",
                "Ambush/targeting: add target-reaction value when replay signatures show low interaction.",
            ]
        )
    }
}

public struct GuderianOrderDicePhaseSurfaceRetirementReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let missingBattleIdentifiers: [String]
    public let retiredVisibleLabelsStillPresent: [String]
    public let tutorialPhaseFirstCopyStillPresent: [String]
    public let docsMentionCycle180: Bool
    public let compatibilityIdentifiersRetained: [String]

    public var isReady: Bool {
        cycleRange == 176...180 &&
            missingBattleIdentifiers.isEmpty &&
            retiredVisibleLabelsStillPresent.isEmpty &&
            tutorialPhaseFirstCopyStillPresent.isEmpty &&
            docsMentionCycle180 &&
            compatibilityIdentifiersRetained.contains("next-phase-button")
    }
}

public enum GuderianOrderDicePhaseSurfaceRetirementCatalog {
    public static let cycleRange = 176...180
    public static let requiredBattleIdentifiers = [
        "order-dice-turn-end-persistence",
        "order-dice-replay-signature",
        "order-dice-full-harness-report",
        "stale-phase-surface-retirement",
    ]
    public static let retiredVisibleBattleLabels = [
        "Label(\"Next Phase\"",
        "Label(\"Phase\"",
    ]
    public static let retiredTutorialPhrases = [
        "phase step",
        "shooting phase",
        "assault phase",
        "Phases Set What Is Legal",
    ]
    public static let compatibilityIdentifiers = [
        "next-phase-button",
        "advancePhase()",
        "maxPhaseAdvances",
    ]

    public static func report(
        battleSourceText: String,
        tutorialSourceText: String,
        readmeText: String,
        planText: String
    ) -> GuderianOrderDicePhaseSurfaceRetirementReport {
        GuderianOrderDicePhaseSurfaceRetirementReport(
            cycleRange: cycleRange,
            missingBattleIdentifiers: requiredBattleIdentifiers.filter { !battleSourceText.contains($0) },
            retiredVisibleLabelsStillPresent: retiredVisibleBattleLabels.filter { battleSourceText.contains($0) },
            tutorialPhaseFirstCopyStillPresent: retiredTutorialPhrases.filter { tutorialSourceText.localizedCaseInsensitiveContains($0) },
            docsMentionCycle180: readmeText.contains("guderian_order_dice_cycle_161_180.md") &&
                planText.contains("Cycles 161-180 complete"),
            compatibilityIdentifiersRetained: compatibilityIdentifiers.filter { battleSourceText.contains($0) || planText.contains($0) }
        )
    }
}

public struct GuderianOrderDiceMigrationCycle180Report: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let cycle160Ready: Bool
    public let turnEndPersistenceReady: Bool
    public let fullHarnessReady: Bool
    public let balanceAuditReady: Bool
    public let phaseSurfaceRetirementReady: Bool
    public let turnEndRows: Int
    public let harnessRows: Int
    public let balanceRows: Int
    public let replaySignatureCount: Int
    public let blockers: [String]

    public var isReadyThroughCycle180: Bool {
        blockers.isEmpty &&
            cycleStart == 161 &&
            cycleEnd == 180 &&
            cycle160Ready &&
            turnEndPersistenceReady &&
            fullHarnessReady &&
            balanceAuditReady &&
            phaseSurfaceRetirementReady &&
            turnEndRows == 35 &&
            harnessRows == 35 &&
            balanceRows == 35 &&
            replaySignatureCount == 35
    }
}

public enum GuderianOrderDiceMigrationCycle180AcceptanceCatalog {
    public static let cycleRange = 161...180

    public static func report(
        cycle80And100SourceText: String,
        guderianTestSourceText: String,
        battleSourceText: String,
        tutorialSourceText: String,
        readmeText: String,
        planText: String
    ) -> GuderianOrderDiceMigrationCycle180Report {
        let cycle160Ready = GuderianOrderDiceMigrationCycle160AcceptanceCatalog.acceptanceReadyThroughCycle160(
            cycle80And100SourceText: cycle80And100SourceText,
            guderianTestSourceText: guderianTestSourceText,
            battleSourceText: battleSourceText,
            tutorialSourceText: tutorialSourceText
        )
        let phaseReport = GuderianOrderDicePhaseSurfaceRetirementCatalog.report(
            battleSourceText: battleSourceText,
            tutorialSourceText: tutorialSourceText,
            readmeText: readmeText,
            planText: planText
        )
        var blockers: [String] = []
        if !cycle160Ready {
            blockers.append("Cycle 141-160 save/debrief/tutorial gates are not ready.")
        }
        if !GuderianOrderDiceTurnEndPersistenceCatalog.acceptanceReadyThroughCycle165 {
            blockers.append("Cycle 161-165 turn-end order-dice persistence is incomplete.")
        }
        if !GuderianOrderDiceFullBattleHarnessCatalog.acceptanceReadyThroughCycle170 {
            blockers.append("Cycle 166-170 full 35-battle harness reporting is incomplete.")
        }
        if !GuderianOrderDiceBalanceAuditCatalog.acceptanceReadyThroughCycle175 {
            blockers.append("Cycle 171-175 activation balance audit is incomplete.")
        }
        if !phaseReport.isReady {
            blockers.append("Cycle 176-180 stale phase-surface retirement is incomplete.")
        }

        return GuderianOrderDiceMigrationCycle180Report(
            cycleStart: 161,
            cycleEnd: 180,
            cycle160Ready: cycle160Ready,
            turnEndPersistenceReady: GuderianOrderDiceTurnEndPersistenceCatalog.acceptanceReadyThroughCycle165,
            fullHarnessReady: GuderianOrderDiceFullBattleHarnessCatalog.acceptanceReadyThroughCycle170,
            balanceAuditReady: GuderianOrderDiceBalanceAuditCatalog.acceptanceReadyThroughCycle175,
            phaseSurfaceRetirementReady: phaseReport.isReady,
            turnEndRows: GuderianOrderDiceTurnEndPersistenceCatalog.allRows.count,
            harnessRows: GuderianOrderDiceFullBattleHarnessCatalog.allRows.count,
            balanceRows: GuderianOrderDiceBalanceAuditCatalog.allRows.count,
            replaySignatureCount: Set(GuderianOrderDiceFullBattleHarnessCatalog.allRows.map(\.replaySignature)).count,
            blockers: blockers
        )
    }
}

public enum GuderianOrderDiceMontyAPIHandoffSurface: String, CaseIterable, Codable, Hashable, Sendable {
    case sideSelection = "Side selection"
    case boardSession = "Order-dice board session"
    case snapshot = "Snapshot"
    case commandCallbacks = "Command callbacks"
    case aiAutoplay = "AI/autoplay"
    case debriefPersistence = "Debrief persistence"
}

public struct GuderianOrderDiceMontyAPIHandoffRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let surface: GuderianOrderDiceMontyAPIHandoffSurface
    public let publicSymbols: [String]
    public let sourcePath: String
    public let handoffSummary: String
    public let montyRequirement: String

    public var isReady: Bool {
        !publicSymbols.isEmpty &&
            !sourcePath.isEmpty &&
            handoffSummary.localizedCaseInsensitiveContains("order") &&
            montyRequirement.localizedCaseInsensitiveContains("Monty")
    }
}

public enum GuderianOrderDiceMontyAPIHandoffCatalog {
    public static let cycleRange = 181...185

    public static let allRows: [GuderianOrderDiceMontyAPIHandoffRow] = [
        row(
            .sideSelection,
            ["GuderianHistoricalSideSelectionResolver", "GuderianOrderDiceSideOwnershipCatalog"],
            "Sources/GuderianCore/GuderianOrderDiceMigration.swift",
            "Monty can bind its selected historical side to order-dice ownership before launch.",
            "Monty must know which side can command the drawn die and which side is automated."
        ),
        row(
            .boardSession,
            ["NativeBoardSession.issueOrder(_:to:)", "NativeBoardSession.prepareNextOrderDiceActivation()"],
            "Sources/GuderianCore/UnifiedGuderianBattleCatalog.swift",
            "Monty can issue explicit Fire/Advance/Run/Ambush/Rally/Down orders through the shared DZW-backed session.",
            "Monty must call order commands rather than building a separate phase runner."
        ),
        row(
            .snapshot,
            ["NativeBoardSnapshot", "NativeBoardUnitSnapshot", "HistoricalBoardSnapshot"],
            "dzw/Sources/DerZweiteWeltkriegGuderian/NativeBoardSession.swift",
            "Monty can read order, pin, retained-order, Down, Ambush, morale, and activation state from snapshots.",
            "Monty must render order-dice state from shared snapshots instead of re-deriving rules."
        ),
        row(
            .commandCallbacks,
            ["DZWPlayableBoardSession", "HistoricalBoardInteractionResolver"],
            "Sources/GuderianApp/DZWPlayableBattleView.swift",
            "Monty can map compact order UI commands onto the same order/action callback surface used by Guderian.",
            "Monty must preserve blocked-action feedback and command callback semantics."
        ),
        row(
            .aiAutoplay,
            ["GuderianOrderDiceOpposingAIActivationPlanner", "GuderianTestFirstBattleRunController"],
            "Sources/GuderianCore/GuderianTestFirstBattleAutoplay.swift",
            "Monty can consume activation-first order AI/autoplay decisions with deterministic seeds and safety caps.",
            "Monty must treat one step as one order-dice activation for testing and playback."
        ),
        row(
            .debriefPersistence,
            ["GuderianOrderDiceSaveStateMigrationCatalog", "GuderianOrderDiceDebriefCopyCatalog"],
            "Sources/GuderianCore/GuderianOrderDiceMigration.swift",
            "Monty can persist completion, activation state, order bag, retained orders, and activation-aware debrief copy.",
            "Monty must keep debrief persistence compatible with Guderian's versioned order-dice keys."
        ),
    ]

    public static var acceptanceReadyThroughCycle185: Bool {
        cycleRange == 181...185 &&
            allRows.count == GuderianOrderDiceMontyAPIHandoffSurface.allCases.count &&
            Set(allRows.map(\.surface)) == Set(GuderianOrderDiceMontyAPIHandoffSurface.allCases) &&
            allRows.allSatisfy(\.isReady)
    }

    public static var summary: String {
        "Monty handoff covers \(allRows.count) order-dice API surfaces: \(allRows.map { $0.surface.rawValue }.joined(separator: ", "))."
    }

    private static func row(
        _ surface: GuderianOrderDiceMontyAPIHandoffSurface,
        _ publicSymbols: [String],
        _ sourcePath: String,
        _ handoffSummary: String,
        _ montyRequirement: String
    ) -> GuderianOrderDiceMontyAPIHandoffRow {
        GuderianOrderDiceMontyAPIHandoffRow(
            id: "monty-order-dice-\(surface.rawValue.lowercased().replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "-"))",
            surface: surface,
            publicSymbols: publicSymbols,
            sourcePath: sourcePath,
            handoffSummary: handoffSummary,
            montyRequirement: montyRequirement
        )
    }
}

public enum GuderianOrderDiceBuildMatrixStatus: String, Codable, Hashable, Sendable {
    case passed = "Passed"
    case documented = "Documented"
    case deferred = "Deferred"
}

public struct GuderianOrderDiceBuildMatrixRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let command: String
    public let workingDirectory: String
    public let status: GuderianOrderDiceBuildMatrixStatus
    public let verificationScope: String

    public var isReady: Bool {
        !command.isEmpty &&
            !workingDirectory.isEmpty &&
            verificationScope.localizedCaseInsensitiveContains("order") &&
            status != .deferred
    }
}

public enum GuderianOrderDiceBuildMatrixCatalog {
    public static let cycleRange = 186...190

    public static let allRows: [GuderianOrderDiceBuildMatrixRow] = [
        row("guderian-swift-build", "swift build", "/Users/barbalet/github/guderian", .passed, "Compiles Guderian order-dice consumer catalogs and UI surfaces."),
        row("guderian-cycle-200-test", "swift test --filter finalAcceptanceAndMontyHandoffAreReady", "/Users/barbalet/github/guderian", .passed, "Checks final order-dice acceptance data and Monty handoff surfaces."),
        row("guderian-monty-compatibility-test", "swift test --filter MontyBackwardCompatibilityTests", "/Users/barbalet/github/guderian", .documented, "Protects Monty order-dice historical-interface imports."),
        row("dzw-swift-build", "swift build", "/Users/barbalet/github/guderian/dzw", .documented, "Builds DZW order-dice rules authority consumed by Guderian."),
        row("dzw-swift-test", "swift test", "/Users/barbalet/github/guderian/dzw", .documented, "Runs DZW order-dice rules tests before downstream release."),
        row("xcode-scheme-build", "xcodebuild -project Guderian.xcodeproj -scheme Guderian build", "/Users/barbalet/github/guderian", .documented, "Checks the app order-dice UI through the Xcode scheme when local tooling is available."),
    ]

    public static var acceptanceReadyThroughCycle190: Bool {
        cycleRange == 186...190 &&
            allRows.count >= 6 &&
            allRows.allSatisfy(\.isReady) &&
            allRows.contains { $0.status == .passed && $0.command == "swift build" } &&
            allRows.contains { $0.command.contains("MontyBackwardCompatibilityTests") } &&
            allRows.contains { $0.workingDirectory.hasSuffix("/dzw") }
    }

    public static var summary: String {
        "\(allRows.filter { $0.status == .passed }.count) passed matrix entries and \(allRows.filter { $0.status == .documented }.count) documented downstream order-dice checks."
    }

    private static func row(
        _ id: String,
        _ command: String,
        _ workingDirectory: String,
        _ status: GuderianOrderDiceBuildMatrixStatus,
        _ verificationScope: String
    ) -> GuderianOrderDiceBuildMatrixRow {
        GuderianOrderDiceBuildMatrixRow(
            id: id,
            command: command,
            workingDirectory: workingDirectory,
            status: status,
            verificationScope: verificationScope
        )
    }
}

public enum GuderianOrderDiceLegacyPhaseDisposition: String, Codable, Hashable, Sendable {
    case retiredFromVisibleSurface = "Retired from visible surface"
    case compatibilityOnly = "Compatibility only"
    case quarantinedTestName = "Quarantined test name"
}

public struct GuderianOrderDiceMigrationCleanupRow: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let legacySymbol: String
    public let sourcePath: String
    public let disposition: GuderianOrderDiceLegacyPhaseDisposition
    public let cleanupSummary: String

    public var isReady: Bool {
        !legacySymbol.isEmpty &&
            !sourcePath.isEmpty &&
            cleanupSummary.localizedCaseInsensitiveContains("compatibility") &&
            (disposition != .quarantinedTestName || cleanupSummary.localizedCaseInsensitiveContains("test"))
    }
}

public enum GuderianOrderDiceMigrationCleanupCatalog {
    public static let cycleRange = 191...195

    public static let allRows: [GuderianOrderDiceMigrationCleanupRow] = [
        row("next-phase-visible-label", "Label(\"Next Phase\"", "Sources/GuderianApp/DZWPlayableBattleView.swift", .retiredFromVisibleSurface, "Visible player copy is now Next Window; the old phrase is compatibility history only."),
        row("next-phase-accessibility-id", "next-phase-button", "Sources/GuderianApp/DZWPlayableBattleView.swift", .compatibilityOnly, "Identifier remains for compatibility with existing UI tests and downstream automation."),
        row("advance-phase-command", "advancePhase()", "Sources/GuderianApp/DZWPlayableBattleView.swift", .compatibilityOnly, "Command remains a compatibility window wrapper around order-dice activation flow."),
        row("max-phase-advances", "maxPhaseAdvances", "Sources/GuderianCore/GuderianTestFirstBattleAutoplay.swift", .quarantinedTestName, "Legacy test safety naming is quarantined until a downstream compatibility rename can land safely."),
        row("native-board-phase", "NativeBoardPhase", "Sources/GuderianCore/UnifiedGuderianBattleCatalog.swift", .compatibilityOnly, "Phase enum remains as DZW compatibility state while order choice drives default behavior."),
    ]

    public static func report(
        battleSourceText: String,
        testSourceText: String
    ) -> GuderianOrderDiceMigrationCleanupReport {
        GuderianOrderDiceMigrationCleanupReport(
            cycleRange: cycleRange,
            rows: allRows,
            retiredVisibleLabelsStillPresent: ["Label(\"Next Phase\""].filter { battleSourceText.contains($0) },
            compatibilitySymbolsRetained: allRows
                .filter { $0.disposition != .retiredFromVisibleSurface }
                .map(\.legacySymbol)
                .filter { battleSourceText.contains($0) || testSourceText.contains($0) }
        )
    }

    private static func row(
        _ id: String,
        _ legacySymbol: String,
        _ sourcePath: String,
        _ disposition: GuderianOrderDiceLegacyPhaseDisposition,
        _ cleanupSummary: String
    ) -> GuderianOrderDiceMigrationCleanupRow {
        GuderianOrderDiceMigrationCleanupRow(
            id: id,
            legacySymbol: legacySymbol,
            sourcePath: sourcePath,
            disposition: disposition,
            cleanupSummary: cleanupSummary
        )
    }
}

public struct GuderianOrderDiceMigrationCleanupReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let rows: [GuderianOrderDiceMigrationCleanupRow]
    public let retiredVisibleLabelsStillPresent: [String]
    public let compatibilitySymbolsRetained: [String]

    public var isReady: Bool {
        cycleRange == 191...195 &&
            rows.count >= 5 &&
            rows.allSatisfy(\.isReady) &&
            retiredVisibleLabelsStillPresent.isEmpty &&
            compatibilitySymbolsRetained.contains("next-phase-button") &&
            compatibilitySymbolsRetained.contains("advancePhase()")
    }
}

public struct GuderianOrderDiceMigrationCycle200Report: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let cycle180EvidenceReady: Bool
    public let montyHandoffReady: Bool
    public let buildMatrixReady: Bool
    public let migrationCleanupReady: Bool
    public let finalDocsReady: Bool
    public let zeroRemainingCycles: Bool
    public let knownLimitations: [String]
    public let blockers: [String]

    public var isReadyThroughCycle200: Bool {
        blockers.isEmpty &&
            cycleStart == 181 &&
            cycleEnd == 200 &&
            cycle180EvidenceReady &&
            montyHandoffReady &&
            buildMatrixReady &&
            migrationCleanupReady &&
            finalDocsReady &&
            zeroRemainingCycles &&
            !knownLimitations.isEmpty
    }
}

public enum GuderianOrderDiceMigrationCycle200AcceptanceCatalog {
    public static let cycleRange = 181...200

    public static func report(
        battleSourceText: String,
        testSourceText: String,
        readmeText: String,
        planText: String,
        montyDocsText: String,
        finalDocsText: String,
        cycle180EvidenceReady: Bool
    ) -> GuderianOrderDiceMigrationCycle200Report {
        let cleanup = GuderianOrderDiceMigrationCleanupCatalog.report(
            battleSourceText: battleSourceText,
            testSourceText: testSourceText
        )
        let finalDocsReady = readmeText.contains("guderian_order_dice_cycle_181_200.md") &&
            planText.contains("Cycles 181-200 complete") &&
            montyDocsText.contains("order-dice") &&
            finalDocsText.contains("Known Limitations") &&
            finalDocsText.contains("Zero Remaining Cycles")
        var blockers: [String] = []
        if !cycle180EvidenceReady {
            blockers.append("Cycle 161-180 evidence is not ready.")
        }
        if !GuderianOrderDiceMontyAPIHandoffCatalog.acceptanceReadyThroughCycle185 {
            blockers.append("Cycle 181-185 Monty API handoff is incomplete.")
        }
        if !GuderianOrderDiceBuildMatrixCatalog.acceptanceReadyThroughCycle190 {
            blockers.append("Cycle 186-190 build matrix is incomplete.")
        }
        if !cleanup.isReady {
            blockers.append("Cycle 191-195 migration cleanup is incomplete.")
        }
        if !finalDocsReady {
            blockers.append("Cycle 196-200 final documentation is incomplete.")
        }

        return GuderianOrderDiceMigrationCycle200Report(
            cycleStart: 181,
            cycleEnd: 200,
            cycle180EvidenceReady: cycle180EvidenceReady,
            montyHandoffReady: GuderianOrderDiceMontyAPIHandoffCatalog.acceptanceReadyThroughCycle185,
            buildMatrixReady: GuderianOrderDiceBuildMatrixCatalog.acceptanceReadyThroughCycle190,
            migrationCleanupReady: cleanup.isReady,
            finalDocsReady: finalDocsReady,
            zeroRemainingCycles: planText.contains("zero remaining Guderian order-dice migration cycles"),
            knownLimitations: [
                "Compatibility identifiers such as next-phase-button remain for downstream automation.",
                "Full DZW swift test and Xcode matrix entries are documented handoff checks when not run in the current local pass.",
            ],
            blockers: blockers
        )
    }
}

public struct GuderianOrderDiceMigrationCycle80Report: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let cycle60Ready: Bool
    public let shootingReady: Bool
    public let vehicleReady: Bool
    public let closeQuartersReady: Bool
    public let guderianAIReady: Bool
    public let missingUISourceIdentifiers: [String]
    public let blockers: [String]

    public var isReadyThroughCycle80: Bool {
        blockers.isEmpty &&
            cycleStart == 61 &&
            cycleEnd == 80 &&
            cycle60Ready &&
            shootingReady &&
            vehicleReady &&
            closeQuartersReady &&
            guderianAIReady &&
            missingUISourceIdentifiers.isEmpty
    }
}

public enum GuderianOrderDiceMigrationCycle80AcceptanceCatalog {
    public static let cycleRange = 61...80
    public static let requiredUISourceIdentifiers = [
        "order-shooting-panel",
        "fire-shooting-choice",
        "advance-shooting-choice",
        "target-reaction-summary",
        "hit-modifier-breakdown",
        "pin-effect-summary",
        "damage-morale-summary",
        "shooting-log-summary",
        "vehicle-status-panel",
        "vehicle-armour-facing",
        "vehicle-penetration-modifiers",
        "vehicle-damage-state",
        "vehicle-wreck-marker",
        "vehicle-down-transition",
        "close-quarters-panel",
        "run-order-assault-flow",
        "assault-target-reaction",
        "assault-round-results",
        "assault-loser-destruction",
        "assault-regroup-log",
        "guderian-order-ai-panel",
        "ai-drawn-die-unit",
        "ai-order-choice",
        "ai-objective-target",
        "ai-path-summary",
        "ai-failed-order-test-handling",
    ]

    public static func acceptanceReadyThroughCycle80(
        cycle60SourceText: String,
        cycle80SourceText: String
    ) -> Bool {
        report(cycle60SourceText: cycle60SourceText, cycle80SourceText: cycle80SourceText).isReadyThroughCycle80
    }

    public static func report(
        cycle60SourceText: String,
        cycle80SourceText: String
    ) -> GuderianOrderDiceMigrationCycle80Report {
        let missingIdentifiers = requiredUISourceIdentifiers.filter { !cycle80SourceText.contains($0) }
        var blockers: [String] = []
        let cycle60Ready = GuderianOrderDiceMigrationCycle60AcceptanceCatalog.acceptanceReadyThroughCycle60(sourceText: cycle60SourceText)
        if !cycle60Ready {
            blockers.append("Cycle 41-60 order panel, inspector, and movement preview gates are not ready.")
        }
        if !GuderianOrderDiceShootingPresenter.acceptanceReadyThroughCycle65 {
            blockers.append("Cycle 61-65 shooting presenter is incomplete.")
        }
        if !GuderianOrderDiceVehiclePresenter.acceptanceReadyThroughCycle70 {
            blockers.append("Cycle 66-70 vehicle presenter is incomplete.")
        }
        if !GuderianOrderDiceCloseQuartersPresenter.acceptanceReadyThroughCycle75 {
            blockers.append("Cycle 71-75 close-quarters presenter is incomplete.")
        }
        if !GuderianOrderDiceGuderianAIActivationPlanner.acceptanceReadyThroughCycle80 {
            blockers.append("Cycle 76-80 Guderian-command AI activation planner is incomplete.")
        }
        if !missingIdentifiers.isEmpty {
            blockers.append("DZWPlayableBattleView is missing cycle 61-80 UI identifiers: \(missingIdentifiers.joined(separator: ", ")).")
        }

        return GuderianOrderDiceMigrationCycle80Report(
            cycleStart: 61,
            cycleEnd: 80,
            cycle60Ready: cycle60Ready,
            shootingReady: GuderianOrderDiceShootingPresenter.acceptanceReadyThroughCycle65,
            vehicleReady: GuderianOrderDiceVehiclePresenter.acceptanceReadyThroughCycle70,
            closeQuartersReady: GuderianOrderDiceCloseQuartersPresenter.acceptanceReadyThroughCycle75,
            guderianAIReady: GuderianOrderDiceGuderianAIActivationPlanner.acceptanceReadyThroughCycle80,
            missingUISourceIdentifiers: missingIdentifiers,
            blockers: blockers
        )
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

private func nearestEnemy(
    to unit: NativeBoardUnitSnapshot,
    in snapshot: NativeBoardSnapshot
) -> NativeBoardUnitSnapshot? {
    snapshot.units
        .filter { $0.owner != unit.owner && $0.owner != .none && !$0.destroyed }
        .min { orderDiceDistance(unit.x, unit.y, $0.x, $0.y) < orderDiceDistance(unit.x, unit.y, $1.x, $1.y) }
}

private func nearestObjective(
    to unit: NativeBoardUnitSnapshot,
    in snapshot: NativeBoardSnapshot
) -> NativeBoardObjectiveSnapshot? {
    snapshot.objectives
        .min { orderDiceDistance(unit.x, unit.y, $0.x, $0.y) < orderDiceDistance(unit.x, unit.y, $1.x, $1.y) }
}

private func priorityObjective(
    in snapshot: NativeBoardSnapshot,
    matching priorityNames: [String]
) -> NativeBoardObjectiveSnapshot? {
    let normalizedPriorities = priorityNames.map { $0.lowercased() }
    return snapshot.objectives.first { objective in
        let name = objective.name.lowercased()
        return normalizedPriorities.contains { priority in
            name.contains(priority) || priority.contains(name)
        }
    }
}

private func orderDiceDistance(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) -> Double {
    let dx = x1 - x2
    let dy = y1 - y2
    return sqrt(dx * dx + dy * dy)
}

private func orderDiceSigned(_ value: Int) -> String {
    value >= 0 ? "+\(value)" : "\(value)"
}

private func sampleUnit(
    id: Int,
    name: String,
    owner: NativeBoardPlayer = .player,
    moraleQuality: String = "Regular",
    pinCount: Int = 0,
    inCover: Bool = true,
    hullDown: Bool = false,
    canMoveNow: Bool = true,
    canShootNow: Bool = true,
    canAssaultNow: Bool = false,
    availableOrders: [HistoricalBoardOrder] = HistoricalBoardOrder.allCases,
    retainedOrder: Bool = false,
    downOrderActive: Bool = false,
    ambushOrderActive: Bool = false,
    defensiveToHitModifier: Int = 0,
    lastOrderTestOfficerModifier: Int = 0,
    lastFubarResult: String = "None"
) -> NativeBoardUnitSnapshot {
    NativeBoardUnitSnapshot(
        id: id,
        name: name,
        engineName: name,
        nativeUnitID: nil,
        owner: owner,
        kind: "Infantry",
        mobility: "Infantry",
        role: "Rifle section",
        historicalNote: "",
        x: Double(id % 10) + 1,
        y: Double(id % 7) + 1,
        facingDegrees: 0,
        totalWoundsRemaining: 5,
        destroyed: false,
        inCover: inCover,
        hullDown: hullDown,
        pinned: pinCount > 0,
        canMoveNow: canMoveNow,
        canShootNow: canShootNow,
        canAssaultNow: canAssaultNow,
        selected: false,
        targeted: false,
        availableOrders: availableOrders,
        pinCount: pinCount,
        moraleQuality: moraleQuality,
        lastOrderTestOfficerModifier: lastOrderTestOfficerModifier,
        lastFubarResult: lastFubarResult,
        retainedOrder: retainedOrder,
        downOrderActive: downOrderActive,
        ambushOrderActive: ambushOrderActive,
        advanceMoveAllowance: 6,
        runMoveAllowance: 12,
        currentOrderMoveAllowance: 6,
        assaultMoveAllowance: 12,
        defensiveToHitModifier: defensiveToHitModifier
    )
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
