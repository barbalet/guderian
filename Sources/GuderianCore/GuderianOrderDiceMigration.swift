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
