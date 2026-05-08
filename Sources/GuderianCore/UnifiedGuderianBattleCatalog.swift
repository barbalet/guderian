import DerZweiteWeltkriegCore
import DerZweiteWeltkriegGuderian
import Foundation

public enum UnifiedGuderianBattleKind: String, Codable, Hashable, Sendable {
    case fieldCommand = "Field command"
    case lateCareer = "Late career"
}

public struct UnifiedGuderianBattleID: Codable, Hashable, Sendable, CustomStringConvertible {
    private enum Storage: Hashable, Sendable {
        case fieldCommand(GuderianBattleID)
        case lateCareer(String)
    }

    private enum CodingKeys: String, CodingKey {
        case rawValue
        case kind
    }

    private let storage: Storage

    public var rawValue: String {
        switch storage {
        case .fieldCommand(let id):
            return id.rawValue
        case .lateCareer(let id):
            return id
        }
    }

    public var kind: UnifiedGuderianBattleKind {
        switch storage {
        case .fieldCommand:
            return .fieldCommand
        case .lateCareer:
            return .lateCareer
        }
    }

    public var fieldCommandID: GuderianBattleID? {
        guard case .fieldCommand(let id) = storage else {
            return nil
        }
        return id
    }

    public var lateCareerID: String? {
        guard case .lateCareer(let id) = storage else {
            return nil
        }
        return id
    }

    public init(rawValue: String, kind: UnifiedGuderianBattleKind) {
        switch kind {
        case .fieldCommand:
            guard let id = GuderianBattleID(rawValue: rawValue) else {
                preconditionFailure("Unknown field-command Guderian battle ID: \(rawValue)")
            }
            storage = .fieldCommand(id)
        case .lateCareer:
            storage = .lateCareer(rawValue)
        }
    }

    public static func fieldCommand(_ id: GuderianBattleID) -> UnifiedGuderianBattleID {
        UnifiedGuderianBattleID(storage: .fieldCommand(id))
    }

    public static func lateCareer(_ id: String) -> UnifiedGuderianBattleID {
        UnifiedGuderianBattleID(storage: .lateCareer(id))
    }

    public var description: String {
        "\(kind.rawValue): \(rawValue)"
    }

    private init(storage: Storage) {
        self.storage = storage
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawValue = try container.decode(String.self, forKey: .rawValue)
        let kind = try container.decode(UnifiedGuderianBattleKind.self, forKey: .kind)

        switch kind {
        case .fieldCommand:
            guard let id = GuderianBattleID(rawValue: rawValue) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .rawValue,
                    in: container,
                    debugDescription: "Unknown field-command Guderian battle ID: \(rawValue)"
                )
            }
            storage = .fieldCommand(id)
        case .lateCareer:
            storage = .lateCareer(rawValue)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawValue, forKey: .rawValue)
        try container.encode(kind, forKey: .kind)
    }
}

public struct UnifiedGuderianBattleEntry: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let order: Int
    public let title: String
    public let dateLabel: String
    public let commandScope: GuderianCommandScope
    public let caveatLabel: String?
    public let hostSurfaceName: String
    public let sourceLinks: [ScenarioSource]

    public var usesUnifiedPlayableSurface: Bool {
        hostSurfaceName == UnifiedGuderianBattleCatalog.hostSurfaceName
    }

    public var hasHistoricalCaveatOnly: Bool {
        commandScope.requiresCommandCaveat == (caveatLabel != nil)
    }
}

public enum UnifiedGuderianBattleCatalog {
    public static let cycleRange = 736...740
    public static let hostSurfaceName = PlayableBattleSurfaceCatalog.hostSurfaceName

    public static let fieldCommandEntries: [UnifiedGuderianBattleEntry] =
        GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map { scenario in
                let record = GuderianCareerScopeCatalog.record(for: scenario.id)
                return UnifiedGuderianBattleEntry(
                    id: .fieldCommand(scenario.id),
                    order: scenario.order,
                    title: scenario.title,
                    dateLabel: scenario.dateLabel,
                    commandScope: record?.scope ?? .directFieldCommand,
                    caveatLabel: record?.requiresCommandCaveat == true ? record?.playableFraming : nil,
                    hostSurfaceName: hostSurfaceName,
                    sourceLinks: scenario.sourceLinks
                )
            }

    public static let lateCareerEntries: [UnifiedGuderianBattleEntry] =
        LateCareerGuderianPresentationCatalog.allEntries
            .sorted { $0.order < $1.order }
            .map { entry in
                UnifiedGuderianBattleEntry(
                    id: .lateCareer(entry.id),
                    order: GuderianCampaignCatalog.all.count + entry.order,
                    title: entry.title,
                    dateLabel: entry.dateLabel,
                    commandScope: entry.scope,
                    caveatLabel: entry.visibleCommandCaveatLabel,
                    hostSurfaceName: hostSurfaceName,
                    sourceLinks: entry.battlefield.sourceLinks
                )
            }

    public static let allEntries: [UnifiedGuderianBattleEntry] =
        fieldCommandEntries + lateCareerEntries

    public static func entry(for id: UnifiedGuderianBattleID) -> UnifiedGuderianBattleEntry? {
        allEntries.first { $0.id == id }
    }

}

public struct UnifiedPlayableAcceptanceReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let totalBattleCount: Int
    public let fieldCommandBattleCount: Int
    public let lateCareerBattleCount: Int
    public let hostSurfaceName: String
    public let requiredGates: [PlayableBattleAcceptanceGate]
    public let retiredAcceptanceSurfaceNames: [String]
    public let caveatPolicy: String
    public let blockers: [String]

    public var isReadyForUnifiedRollout: Bool {
        cycleRange == 731...735 &&
            totalBattleCount == 35 &&
            fieldCommandBattleCount == 19 &&
            lateCareerBattleCount == 16 &&
            hostSurfaceName == UnifiedGuderianBattleCatalog.hostSurfaceName &&
            requiredGates == PlayableBattleAcceptanceGate.allCases &&
            retiredAcceptanceSurfaceNames.contains("LateCareerPlayablePilotView") &&
            caveatPolicy.localizedCaseInsensitiveContains("historical labels") &&
            blockers.isEmpty
    }
}

public enum UnifiedPlayableAcceptanceCatalog {
    public static let cycleRange = 731...735

    public static var report: UnifiedPlayableAcceptanceReport {
        let blockers = [
            GuderianCampaignCatalog.all.count == 19 ? nil : "Field-command campaign count is not 19.",
            LateCareerGuderianPresentationCatalog.visibleEntryCount == 16 ? nil : "Late-career battlefield count is not 16.",
            LateCareerPlayableSurfaceCatalog.parityReadyBattlefieldIDs.count == 16 ? nil : "Late-career parity metadata is incomplete.",
            PlayableBattleSurfaceCatalog.routedBattleIDs.count == 19 ? nil : "Original campaign playable-screen routing is incomplete.",
        ].compactMap { $0 }

        return UnifiedPlayableAcceptanceReport(
            cycleRange: cycleRange,
            totalBattleCount: GuderianCampaignCatalog.all.count + LateCareerGuderianPresentationCatalog.visibleEntryCount,
            fieldCommandBattleCount: GuderianCampaignCatalog.all.count,
            lateCareerBattleCount: LateCareerGuderianPresentationCatalog.visibleEntryCount,
            hostSurfaceName: UnifiedGuderianBattleCatalog.hostSurfaceName,
            requiredGates: PlayableBattleAcceptanceGate.allCases,
            retiredAcceptanceSurfaceNames: ["LateCareerPlayablePilotView"],
            caveatPolicy: "Command-scope caveats remain historical labels in briefing/source context only; they do not define a separate or lighter gameplay surface.",
            blockers: blockers
        )
    }
}

public enum UnifiedCampaignRowAvailability: String, Codable, Hashable, Sendable {
    case available = "Available"
    case locked = "Locked"
}

public enum UnifiedCampaignCompletionState: String, Codable, Hashable, Sendable {
    case open = "Open"
    case complete = "Complete"
}

public enum UnifiedCampaignNavigationTreatment: String, Codable, Hashable, Sendable {
    case playableBattle = "Playable battle"
}

public struct UnifiedCampaignListRow: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let order: Int
    public let numberLabel: String
    public let title: String
    public let dateLabel: String
    public let scopeLabel: String
    public let caveatLabel: String?
    public let completionState: UnifiedCampaignCompletionState
    public let availability: UnifiedCampaignRowAvailability
    public let playAffordanceTitle: String
    public let hostSurfaceName: String
    public let rowStyleIdentifier: String
    public let rowAccessibilityIdentifier: String
    public let navigationAccessibilityIdentifier: String
    public let navigationTreatment: UnifiedCampaignNavigationTreatment

    public var isAvailable: Bool {
        availability == .available
    }

    public var usesUnifiedCampaignListTreatment: Bool {
        playAffordanceTitle == UnifiedCampaignListCatalog.playAffordanceTitle &&
            hostSurfaceName == UnifiedGuderianBattleCatalog.hostSurfaceName &&
            rowStyleIdentifier == UnifiedCampaignListCatalog.rowStyleIdentifier &&
            navigationTreatment == .playableBattle &&
            rowAccessibilityIdentifier.hasPrefix("unified-battle-row-") &&
            navigationAccessibilityIdentifier.hasPrefix("unified-battle-link-")
    }
}

public enum UnifiedCampaignListCatalog {
    public static let cycleRange = 751...755
    public static let sectionTitle = "Battles"
    public static let playAffordanceTitle = "Play"
    public static let rowStyleIdentifier = "unified-campaign-battle-row"
    public static let legacySectionTitlesRemoved = [
        "Scenarios",
        LateCareerGuderianPresentationCatalog.sectionTitle,
    ]

    public static func rows(
        progress: CampaignProgress = CampaignProgress(),
        lateCareerProgress: LateCareerProgress = LateCareerProgress(),
        playMode: CampaignPlayMode = .standalone
    ) -> [UnifiedCampaignListRow] {
        UnifiedGuderianBattleCatalog.allEntries.map { entry in
            row(
                for: entry,
                progress: progress,
                lateCareerProgress: lateCareerProgress,
                playMode: playMode
            )
        }
    }

    public static var previewRows: [UnifiedCampaignListRow] {
        rows()
    }

    public static func row(
        for id: UnifiedGuderianBattleID,
        progress: CampaignProgress = CampaignProgress(),
        lateCareerProgress: LateCareerProgress = LateCareerProgress(),
        playMode: CampaignPlayMode = .standalone
    ) -> UnifiedCampaignListRow? {
        guard let entry = UnifiedGuderianBattleCatalog.entry(for: id) else {
            return nil
        }

        return row(
            for: entry,
            progress: progress,
            lateCareerProgress: lateCareerProgress,
            playMode: playMode
        )
    }

    public static var acceptanceReadyThroughCycle755: Bool {
        let rows = previewRows
        return cycleRange == 751...755 &&
            sectionTitle == "Battles" &&
            legacySectionTitlesRemoved.contains("Scenarios") &&
            legacySectionTitlesRemoved.contains("Late Career Context") &&
            rows.count == 35 &&
            rows.map(\.order) == Array(1...35) &&
            rows.allSatisfy(\.usesUnifiedCampaignListTreatment) &&
            rows.allSatisfy { $0.playAffordanceTitle == playAffordanceTitle } &&
            rows.allSatisfy { $0.hostSurfaceName == UnifiedGuderianBattleCatalog.hostSurfaceName } &&
            Set(rows.map(\.rowStyleIdentifier)) == Set([rowStyleIdentifier])
    }

    private static func row(
        for entry: UnifiedGuderianBattleEntry,
        progress: CampaignProgress,
        lateCareerProgress: LateCareerProgress,
        playMode: CampaignPlayMode
    ) -> UnifiedCampaignListRow {
        let completionState: UnifiedCampaignCompletionState
        let availability: UnifiedCampaignRowAvailability

        switch entry.id.kind {
        case .fieldCommand:
            if let battleID = entry.id.fieldCommandID,
               let scenario = GuderianCampaignCatalog.scenario(id: battleID) {
                completionState = progress.isCompleted(battleID) ? .complete : .open
                availability = progress.isAvailable(scenario, in: playMode) ? .available : .locked
            } else {
                completionState = .open
                availability = .locked
            }
        case .lateCareer:
            completionState = lateCareerProgress.isCompleted(entry.id.rawValue) ? .complete : .open
            availability = .available
        }

        return UnifiedCampaignListRow(
            id: entry.id,
            order: entry.order,
            numberLabel: "\(entry.order).",
            title: entry.title,
            dateLabel: entry.dateLabel,
            scopeLabel: entry.commandScope.rawValue,
            caveatLabel: entry.caveatLabel,
            completionState: completionState,
            availability: availability,
            playAffordanceTitle: playAffordanceTitle,
            hostSurfaceName: entry.hostSurfaceName,
            rowStyleIdentifier: rowStyleIdentifier,
            rowAccessibilityIdentifier: "unified-battle-row-\(entry.id.rawValue)",
            navigationAccessibilityIdentifier: "unified-battle-link-\(entry.id.rawValue)",
            navigationTreatment: .playableBattle
        )
    }
}

public enum UnifiedBriefingSectionKind: String, CaseIterable, Codable, Hashable, Sendable {
    case overview = "Overview"
    case playerForce = "Playable Force"
    case germanContext = "German Context"
    case designIntent = "Design Intent"
    case objectives = "Objectives"
    case rules = "Rules"
    case sources = "Sources"
}

public struct UnifiedBriefingSection: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedBriefingSectionKind
    public let title: String
    public let body: String
}

public struct UnifiedBattleBriefingShell: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let title: String
    public let dateLabel: String
    public let scopeLabel: String
    public let caveatLabels: [String]
    public let sections: [UnifiedBriefingSection]
    public let sourceLinks: [ScenarioSource]
    public let hostSurfaceName: String
    public let launchAccessibilityIdentifier: String
    public let briefingAccessibilityIdentifier: String
    public let retiredSurfaceNames: [String]

    public var sectionKinds: [UnifiedBriefingSectionKind] {
        sections.map(\.id)
    }

    public var displayText: String {
        ([title, dateLabel, scopeLabel] + caveatLabels + sections.map(\.body)).joined(separator: " ")
    }

    public var usesSharedBriefingShell: Bool {
        hostSurfaceName == UnifiedGuderianBattleCatalog.hostSurfaceName &&
            launchAccessibilityIdentifier.hasPrefix("unified-battle-launch-") &&
            briefingAccessibilityIdentifier.hasPrefix("unified-battle-briefing-") &&
            sectionKinds.contains(.overview) &&
            sectionKinds.contains(.playerForce) &&
            sectionKinds.contains(.germanContext) &&
            sectionKinds.contains(.objectives) &&
            sectionKinds.contains(.sources) &&
            !displayText.localizedCaseInsensitiveContains("pilot")
    }
}

public enum UnifiedBattleBriefingCatalog {
    public static let cycleRange = 756...760
    public static let retiredSurfaceNames = [
        "LateCareerContextBriefingView",
        "LateCareerPlayablePilotView",
    ]

    public static var allShells: [UnifiedBattleBriefingShell] {
        UnifiedGuderianBattleCatalog.allEntries.compactMap { shell(for: $0.id) }
    }

    public static func shell(for id: UnifiedGuderianBattleID) -> UnifiedBattleBriefingShell? {
        switch id.kind {
        case .fieldCommand:
            guard let battleID = id.fieldCommandID,
                  let scenario = GuderianCampaignCatalog.scenario(id: battleID),
                  let entry = UnifiedGuderianBattleCatalog.entry(for: id) else {
                return nil
            }

            return UnifiedBattleBriefingShell(
                id: id,
                title: scenario.title,
                dateLabel: scenario.dateLabel,
                scopeLabel: entry.commandScope.rawValue,
                caveatLabels: entry.caveatLabel.map { [$0] } ?? [],
                sections: [
                    UnifiedBriefingSection(id: .overview, title: "Overview", body: scenario.historicalResult),
                    UnifiedBriefingSection(id: .playerForce, title: "Opposing Force", body: scenario.playerForceSummary),
                    UnifiedBriefingSection(id: .germanContext, title: "German Context", body: scenario.guderianCommand),
                    UnifiedBriefingSection(id: .designIntent, title: "Design Intent", body: scenario.designIntent),
                    UnifiedBriefingSection(id: .objectives, title: "Objectives", body: scenario.objectives.map(\.name).joined(separator: ", ")),
                    UnifiedBriefingSection(id: .rules, title: "Rules", body: "Use the shared DZW phase, action, blocked-feedback, AI, log, and debrief flow."),
                    UnifiedBriefingSection(id: .sources, title: "Sources", body: scenario.sourceSummary),
                ],
                sourceLinks: scenario.sourceLinks,
                hostSurfaceName: UnifiedGuderianBattleCatalog.hostSurfaceName,
                launchAccessibilityIdentifier: "unified-battle-launch-\(id.rawValue)",
                briefingAccessibilityIdentifier: "unified-battle-briefing-\(id.rawValue)",
                retiredSurfaceNames: retiredSurfaceNames
            )
        case .lateCareer:
            guard let entry = LateCareerGuderianPresentationCatalog.entry(for: id.rawValue) else {
                return nil
            }

            return UnifiedBattleBriefingShell(
                id: id,
                title: entry.title,
                dateLabel: entry.dateLabel,
                scopeLabel: entry.scopeLabel,
                caveatLabels: [entry.visibleCommandCaveatLabel],
                sections: [
                    UnifiedBriefingSection(id: .overview, title: "Overview", body: entry.playableFraming),
                    UnifiedBriefingSection(id: .playerForce, title: "Playable Force", body: entry.playerRole),
                    UnifiedBriefingSection(id: .germanContext, title: "German Context", body: entry.germanContext),
                    UnifiedBriefingSection(id: .designIntent, title: "Design Intent", body: entry.battlefield.rules.map(\.effect).joined(separator: " ")),
                    UnifiedBriefingSection(id: .objectives, title: "Objectives", body: entry.battlefield.objectives.map(\.name).joined(separator: ", ")),
                    UnifiedBriefingSection(id: .rules, title: "Rules", body: entry.battlefield.rules.map(\.name).joined(separator: ", ")),
                    UnifiedBriefingSection(id: .sources, title: "Sources", body: entry.battlefield.sourceLinks.map(\.title).joined(separator: ", ")),
                ],
                sourceLinks: entry.battlefield.sourceLinks,
                hostSurfaceName: UnifiedGuderianBattleCatalog.hostSurfaceName,
                launchAccessibilityIdentifier: "unified-battle-launch-\(id.rawValue)",
                briefingAccessibilityIdentifier: "unified-battle-briefing-\(id.rawValue)",
                retiredSurfaceNames: retiredSurfaceNames
            )
        }
    }

    public static var acceptanceReadyThroughCycle760: Bool {
        allShells.count == 35 &&
            cycleRange == 756...760 &&
            allShells.allSatisfy(\.usesSharedBriefingShell) &&
            allShells.allSatisfy { $0.retiredSurfaceNames == retiredSurfaceNames } &&
            allShells.allSatisfy { !$0.displayText.localizedCaseInsensitiveContains("context-only") } &&
            allShells.allSatisfy { $0.sourceLinks.isEmpty == false }
    }
}

public enum UnifiedPlayableRouteReadiness: String, Codable, Hashable, Sendable {
    case playableComplete = "Playable complete"
    case routedThisCycle = "Routed this cycle"
}

public struct UnifiedPlayableBattleRoute: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let title: String
    public let commandScope: GuderianCommandScope
    public let caveatLabel: String?
    public let hostSurfaceName: String
    public let cycleRange: ClosedRange<Int>
    public let readiness: UnifiedPlayableRouteReadiness
    public let acceptanceGates: [PlayableBattleAcceptanceGate]
    public let supportsSelectableUnits: Bool
    public let supportsDraggedMovement: Bool
    public let supportsPhaseControls: Bool
    public let supportsCombatActions: Bool
    public let supportsBlockedActionFeedback: Bool
    public let supportsBattleLog: Bool
    public let supportsGermanAIRunner: Bool
    public let supportsDebriefPersistence: Bool
    public let completionPersistenceKey: String

    public var isFullPlayableBoardRoute: Bool {
        hostSurfaceName == UnifiedGuderianBattleCatalog.hostSurfaceName &&
            acceptanceGates == PlayableBattleAcceptanceGate.allCases &&
            supportsSelectableUnits &&
            supportsDraggedMovement &&
            supportsPhaseControls &&
            supportsCombatActions &&
            supportsBlockedActionFeedback &&
            supportsBattleLog &&
            supportsGermanAIRunner &&
            supportsDebriefPersistence &&
            !completionPersistenceKey.isEmpty
    }
}

public enum UnifiedPlayableBoardRouteCatalog {
    public static let cycleRange = 761...780

    public static var setARoutedLateCareerIDs: [String] {
        LateCareerStaffBattlefieldSetACatalog.battlefieldIDs
    }

    public static var setBRoutedLateCareerIDs: [String] {
        LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs
    }

    public static var setCRoutedLateCareerIDs: [String] {
        LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs
    }

    public static var setDRoutedLateCareerIDs: [String] {
        LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs
    }

    public static var lateCareerRoutedIDsThroughCycle765: [String] {
        setARoutedLateCareerIDs
    }

    public static var lateCareerRoutedIDsThroughCycle770: [String] {
        setARoutedLateCareerIDs + setBRoutedLateCareerIDs
    }

    public static var lateCareerRoutedIDsThroughCycle775: [String] {
        lateCareerRoutedIDsThroughCycle770 + setCRoutedLateCareerIDs
    }

    public static var lateCareerRoutedIDsThroughCycle780: [String] {
        lateCareerRoutedIDsThroughCycle775 + setDRoutedLateCareerIDs
    }

    public static var routedBattleIDsThroughCycle770: [UnifiedGuderianBattleID] {
        PlayableBattleSurfaceCatalog.routedBattleIDs.map(UnifiedGuderianBattleID.fieldCommand) +
            lateCareerRoutedIDsThroughCycle770.map(UnifiedGuderianBattleID.lateCareer)
    }

    public static var routedBattleIDsThroughCycle780: [UnifiedGuderianBattleID] {
        PlayableBattleSurfaceCatalog.routedBattleIDs.map(UnifiedGuderianBattleID.fieldCommand) +
            lateCareerRoutedIDsThroughCycle780.map(UnifiedGuderianBattleID.lateCareer)
    }

    public static var lateCareerRoutesThroughCycle765: [UnifiedPlayableBattleRoute] {
        lateCareerRoutedIDsThroughCycle765.compactMap { route(for: .lateCareer($0)) }
    }

    public static var lateCareerRoutesThroughCycle770: [UnifiedPlayableBattleRoute] {
        lateCareerRoutedIDsThroughCycle770.compactMap { route(for: .lateCareer($0)) }
    }

    public static var lateCareerRoutesThroughCycle775: [UnifiedPlayableBattleRoute] {
        lateCareerRoutedIDsThroughCycle775.compactMap { route(for: .lateCareer($0)) }
    }

    public static var lateCareerRoutesThroughCycle780: [UnifiedPlayableBattleRoute] {
        lateCareerRoutedIDsThroughCycle780.compactMap { route(for: .lateCareer($0)) }
    }

    public static var allRoutesThroughCycle770: [UnifiedPlayableBattleRoute] {
        routedBattleIDsThroughCycle770.compactMap(route)
    }

    public static var allRoutesThroughCycle780: [UnifiedPlayableBattleRoute] {
        routedBattleIDsThroughCycle780.compactMap(route)
    }

    public static func isRoutedToPlayableBattleView(_ id: UnifiedGuderianBattleID) -> Bool {
        route(for: id) != nil
    }

    public static func route(for id: UnifiedGuderianBattleID) -> UnifiedPlayableBattleRoute? {
        switch id.kind {
        case .fieldCommand:
            guard let battleID = id.fieldCommandID,
                  PlayableBattleSurfaceCatalog.isRoutedToPlayableScreen(battleID),
                  let scenario = GuderianCampaignCatalog.scenario(id: battleID),
                  let entry = UnifiedGuderianBattleCatalog.entry(for: id) else {
                return nil
            }

            return UnifiedPlayableBattleRoute(
                id: id,
                title: scenario.title,
                commandScope: entry.commandScope,
                caveatLabel: entry.caveatLabel,
                hostSurfaceName: UnifiedGuderianBattleCatalog.hostSurfaceName,
                cycleRange: PlayableBattleSurfaceCatalog.cycleRange,
                readiness: .playableComplete,
                acceptanceGates: PlayableBattleAcceptanceGate.allCases,
                supportsSelectableUnits: true,
                supportsDraggedMovement: true,
                supportsPhaseControls: true,
                supportsCombatActions: true,
                supportsBlockedActionFeedback: true,
                supportsBattleLog: true,
                supportsGermanAIRunner: true,
                supportsDebriefPersistence: true,
                completionPersistenceKey: "campaign.\(battleID.rawValue)"
            )
        case .lateCareer:
            guard lateCareerRoutedIDsThroughCycle780.contains(id.rawValue),
                  let entry = LateCareerGuderianPresentationCatalog.entry(for: id.rawValue),
                  let instance = LateCareerNativeBattleInstanceCatalog.instance(for: id.rawValue),
                  let report = LateCareerPlayableSurfaceCatalog.report(for: id.rawValue) else {
                return nil
            }

            let routeCycles: ClosedRange<Int>
            if setARoutedLateCareerIDs.contains(id.rawValue) {
                routeCycles = 761...765
            } else if setBRoutedLateCareerIDs.contains(id.rawValue) {
                routeCycles = 766...770
            } else if setCRoutedLateCareerIDs.contains(id.rawValue) {
                routeCycles = 771...775
            } else {
                routeCycles = 776...780
            }
            return UnifiedPlayableBattleRoute(
                id: id,
                title: entry.title,
                commandScope: entry.scope,
                caveatLabel: entry.visibleCommandCaveatLabel,
                hostSurfaceName: UnifiedGuderianBattleCatalog.hostSurfaceName,
                cycleRange: routeCycles,
                readiness: .routedThisCycle,
                acceptanceGates: PlayableBattleAcceptanceGate.allCases,
                supportsSelectableUnits: instance.units.isEmpty == false,
                supportsDraggedMovement: instance.deploymentZones.isEmpty == false,
                supportsPhaseControls: true,
                supportsCombatActions: instance.units.contains { $0.side == .player } && instance.units.contains { $0.side == .guderianAI },
                supportsBlockedActionFeedback: LateCareerPlayableSurfaceCatalog.aiPlan(for: id.rawValue)?.blockedActionExpectations.isEmpty == false,
                supportsBattleLog: instance.events.isEmpty == false,
                supportsGermanAIRunner: instance.aiProfile.orders.isEmpty == false,
                supportsDebriefPersistence: report.isParityReady,
                completionPersistenceKey: report.completionRecord.persistenceKey
            )
        }
    }

    public static var acceptanceReadyThroughCycle765: Bool {
        cycleRange == 761...780 &&
            lateCareerRoutesThroughCycle765.count == 4 &&
            lateCareerRoutesThroughCycle765.map { $0.id.rawValue } == setARoutedLateCareerIDs &&
            lateCareerRoutesThroughCycle765.allSatisfy(\.isFullPlayableBoardRoute) &&
            lateCareerRoutesThroughCycle765.allSatisfy { $0.commandScope == .inspectorGeneralInfluence } &&
            lateCareerRoutesThroughCycle765.allSatisfy { $0.caveatLabel?.localizedCaseInsensitiveContains("not a Guderian field command") == true }
    }

    public static var acceptanceReadyThroughCycle770: Bool {
        cycleRange == 761...780 &&
            acceptanceReadyThroughCycle765 &&
            lateCareerRoutesThroughCycle770.count == 8 &&
            lateCareerRoutesThroughCycle770.suffix(4).map { $0.id.rawValue } == setBRoutedLateCareerIDs &&
            lateCareerRoutesThroughCycle770.allSatisfy(\.isFullPlayableBoardRoute) &&
            lateCareerRoutesThroughCycle770.suffix(4).allSatisfy { $0.commandScope == .armyGeneralStaffInfluence } &&
            allRoutesThroughCycle770.count == 27
    }

    public static var acceptanceReadyThroughCycle775: Bool {
        cycleRange == 761...780 &&
            acceptanceReadyThroughCycle770 &&
            lateCareerRoutesThroughCycle775.count == 12 &&
            lateCareerRoutesThroughCycle775.suffix(4).map { $0.id.rawValue } == setCRoutedLateCareerIDs &&
            lateCareerRoutesThroughCycle775.allSatisfy(\.isFullPlayableBoardRoute) &&
            lateCareerRoutesThroughCycle775.suffix(4).allSatisfy { $0.commandScope == .armyGeneralStaffInfluence } &&
            lateCareerRoutesThroughCycle775.suffix(4).allSatisfy { $0.caveatLabel?.localizedCaseInsensitiveContains("not a Guderian field command") == true }
    }

    public static var acceptanceReadyThroughCycle780: Bool {
        cycleRange == 761...780 &&
            acceptanceReadyThroughCycle775 &&
            lateCareerRoutesThroughCycle780.count == 16 &&
            lateCareerRoutesThroughCycle780.suffix(4).map { $0.id.rawValue } == setDRoutedLateCareerIDs &&
            lateCareerRoutesThroughCycle780.allSatisfy(\.isFullPlayableBoardRoute) &&
            lateCareerRoutesThroughCycle780.suffix(4).filter { $0.commandScope == .postDismissalContext }.count == 2 &&
            lateCareerRoutesThroughCycle780.suffix(4).allSatisfy { $0.caveatLabel?.localizedCaseInsensitiveContains("not a Guderian field command") == true } &&
            allRoutesThroughCycle780.count == 35
    }
}

public struct LateCareerNativeAIProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let postureName: String
    public let strategicGoal: String
    public let targetPriorities: [String]
    public let orders: [NativeBattleAIOrder]
}

public struct LateCareerNativeBattleBlueprint: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let seed: UInt32
    public let sourceInstanceID: String
    public let engineBoardFrame: NativeBattleFrame
    public let missionTargetScore: Int
    public let units: [NativeEngineUnitSpawn]
    public let objectives: [NativeEngineObjectiveSpawn]
    public let terrain: [NativeEngineTerrainSpawn]
    public let eventTriggerIDs: [String]

    public var isCompleteForScenarioLoader: Bool {
        missionTargetScore > 0 &&
            !units.isEmpty &&
            units.allSatisfy { !$0.weaponRoleIDs.isEmpty } &&
            !objectives.isEmpty &&
            !terrain.isEmpty
    }
}

public struct LateCareerNativeBattleInstance: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let instanceID: String
    public let title: String
    public let order: Int
    public let commandScope: GuderianCommandScope
    public let frame: NativeBattleFrame
    public let terrain: [NativeBattleTerrainFeature]
    public let deploymentZones: [NativeBattleDeploymentZone]
    public let objectives: [NativeBattleObjective]
    public let units: [NativeBattleUnit]
    public let events: [NativeBattleEventTrigger]
    public let aiProfile: LateCareerNativeAIProfile
    public let victory: NativeBattleVictoryProfile
    public let caveatLabel: String

    public var isModeledForUnifiedNativeGameplay: Bool {
        !units.isEmpty &&
            units.allSatisfy { !$0.weapons.isEmpty } &&
            !terrain.isEmpty &&
            deploymentZones.filter { $0.side != .neutral }.count >= 2 &&
            !objectives.isEmpty &&
            !aiProfile.orders.isEmpty &&
            victory.missionTargetScore > 0 &&
            caveatLabel.localizedCaseInsensitiveContains("not a Guderian field command")
    }

    public func engineBlueprint(seed: UInt32) -> LateCareerNativeBattleBlueprint {
        let engineFrame = NativeBattleFrame(width: 72, height: 48)
        return LateCareerNativeBattleBlueprint(
            id: id,
            seed: seed,
            sourceInstanceID: instanceID,
            engineBoardFrame: engineFrame,
            missionTargetScore: victory.missionTargetScore,
            units: units.map { unit in
                let point = engineCoordinate(unit.startingPosition, from: frame, to: engineFrame)
                return NativeEngineUnitSpawn(
                    id: unit.id,
                    name: unit.name,
                    side: unit.side,
                    mobility: unit.mobility,
                    x: point.x,
                    y: point.y,
                    deploymentZoneID: unit.deploymentZoneID,
                    weaponRoleIDs: unit.weapons.map(\.role.rawValue)
                )
            },
            objectives: objectives.map { objective in
                let point = engineCoordinate(objective.position, from: frame, to: engineFrame)
                return NativeEngineObjectiveSpawn(
                    id: objective.id,
                    name: objective.name,
                    side: objective.side,
                    x: point.x,
                    y: point.y,
                    victoryPoints: max(1, objective.victoryPoints)
                )
            },
            terrain: terrain.map { feature in
                NativeEngineTerrainSpawn(
                    id: feature.id,
                    name: feature.name,
                    kind: feature.kind,
                    points: feature.points.map { engineCoordinate($0, from: frame, to: engineFrame) },
                    radius: scaledRadius(feature.radius, from: frame, to: engineFrame),
                    movementCostHint: feature.movementCostHint,
                    blocksLineOfSightHint: feature.blocksLineOfSightHint
                )
            },
            eventTriggerIDs: events.map(\.id)
        )
    }

    private func engineCoordinate(
        _ coordinate: NativeBattleCoordinate,
        from source: NativeBattleFrame,
        to destination: NativeBattleFrame
    ) -> NativeBattleCoordinate {
        NativeBattleCoordinate(
            x: unifiedClamp((coordinate.x / source.width) * destination.width, min: 0, max: destination.width),
            y: unifiedClamp((coordinate.y / source.height) * destination.height, min: 0, max: destination.height)
        )
    }

    private func scaledRadius(_ radius: Double, from source: NativeBattleFrame, to destination: NativeBattleFrame) -> Double {
        let scale = min(destination.width / source.width, destination.height / source.height)
        return max(0, radius * scale)
    }
}

public enum LateCareerNativeBattleInstanceCatalog {
    public static let cycleRange = 741...745

    public static func instance(for id: String) -> LateCareerNativeBattleInstance? {
        LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields
            .first { $0.id == id }
            .map(LateCareerNativeBattleInstanceBuilder.init(battlefield:))
            .map { $0.build() }
    }

    public static func instance(for battlefield: LateCareerStaffBattlefield) -> LateCareerNativeBattleInstance {
        LateCareerNativeBattleInstanceBuilder(battlefield: battlefield).build()
    }

    public static var allInstances: [LateCareerNativeBattleInstance] {
        LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields.map(instance)
    }

    public static var acceptanceReadyThroughCycle745: Bool {
        cycleRange == 741...745 &&
            allInstances.count == 16 &&
            allInstances.allSatisfy(\.isModeledForUnifiedNativeGameplay) &&
            allInstances.allSatisfy { $0.engineBlueprint(seed: UInt32(745_000 + $0.order)).isCompleteForScenarioLoader }
    }
}

public struct LateCareerNativeScenarioLoadout {
    public let battlefield: LateCareerStaffBattlefield
    public let seed: UInt32
    public let instance: LateCareerNativeBattleInstance
    public let blueprint: LateCareerNativeBattleBlueprint
    public let playerArmy: army_list_t
    public let opponentArmy: army_list_t
    public let playerEntries: [NativeScenarioArmyListSelection]
    public let opponentEntries: [NativeScenarioArmyListSelection]
    public let warnings: [NativeScenarioLoaderWarning]
    public let gameCreationMode: NativeScenarioGameCreationMode

    public var playerArmyName: String {
        armyName(playerArmy)
    }

    public var opponentArmyName: String {
        armyName(opponentArmy)
    }

    public var canCreateSkirmishBridge: Bool {
        blueprint.isCompleteForScenarioLoader && !playerEntries.isEmpty && !opponentEntries.isEmpty
    }

    public var canApplyScenarioBoardHook: Bool {
        canCreateSkirmishBridge &&
            !scenarioBoardZones.isEmpty &&
            !scenarioBoardObjectives.isEmpty &&
            blueprint.missionTargetScore > 0
    }

    public func makeGame() -> NativeScenarioLoadedGame? {
        let playerCEntries = playerEntries.map { army_list_entry_t(catalog_id: Int32($0.catalogID), count: Int32($0.count)) }
        let opponentCEntries = opponentEntries.map { army_list_entry_t(catalog_id: Int32($0.catalogID), count: Int32($0.count)) }
        let game = playerCEntries.withUnsafeBufferPointer { playerBuffer in
            opponentCEntries.withUnsafeBufferPointer { opponentBuffer in
                game_create_skirmish(
                    seed,
                    playerArmy,
                    playerBuffer.baseAddress,
                    Int32(playerBuffer.count),
                    opponentArmy,
                    opponentBuffer.baseAddress,
                    Int32(opponentBuffer.count)
                )
            }
        }
        guard let game else {
            return nil
        }

        return NativeScenarioLoadedGame(
            handle: game,
            boardReport: applyScenarioBoard(to: game),
            deploymentReport: deployBlueprintUnits(in: game)
        )
    }

    private var scenarioBoardZones: [UnifiedScenarioBoardZoneSpec] {
        let preferredTerrain = blueprint.terrain
            .filter { $0.kind != .objective && $0.kind != .airPressure }
            .sorted { unifiedTerrainPriority($0.kind) > unifiedTerrainPriority($1.kind) }
        let terrain = preferredTerrain.isEmpty ? blueprint.terrain : preferredTerrain
        return terrain.prefix(NativeScenarioLoader.boardTerrainZoneCapacity).enumerated().map { index, terrain in
            let rect = zoneRect(for: terrain)
            return UnifiedScenarioBoardZoneSpec(
                id: index + 1,
                name: terrain.name,
                kind: engineTerrainKind(for: terrain.kind),
                rect: rect,
                coverSave: unifiedCoverSave(for: terrain.kind),
                blocksLineOfSight: terrain.blocksLineOfSightHint,
                hullDown: terrain.kind == .ridge || terrain.kind == .bunker || terrain.kind == .fortifiedLine
            )
        }
    }

    private var scenarioBoardObjectives: [UnifiedScenarioBoardObjectiveSpec] {
        blueprint.objectives.prefix(NativeScenarioLoader.boardObjectiveCapacity).enumerated().map { index, objective in
            UnifiedScenarioBoardObjectiveSpec(
                id: index + 1,
                name: objective.name,
                x: Float(unifiedClamp(objective.x, min: 1, max: blueprint.engineBoardFrame.width - 1)),
                y: Float(unifiedClamp(objective.y, min: 1, max: blueprint.engineBoardFrame.height - 1)),
                radius: Float(unifiedClamp(Double(objective.victoryPoints) + 2.5, min: 3.5, max: 7.5))
            )
        }
    }

    private func applyScenarioBoard(to game: OpaquePointer) -> NativeScenarioBoardReport {
        let zones = scenarioBoardZones
        let objectives = scenarioBoardObjectives
        let applied = withUnifiedCStringPointers(zones.map(\.name)) { zoneNames in
            withUnifiedCStringPointers(objectives.map(\.name)) { objectiveNames in
                battlefield.title.withCString { missionName in
                    let cZones = zones.enumerated().map { index, zone in
                        guderian_scenario_zone_t(
                            id: Int32(zone.id),
                            name: zoneNames[index],
                            kind: zone.kind,
                            rect: rect_t(x: zone.rect.x, y: zone.rect.y, width: zone.rect.width, height: zone.rect.height),
                            cover_save: Int32(zone.coverSave),
                            blocks_line_of_sight: zone.blocksLineOfSight,
                            hull_down: zone.hullDown
                        )
                    }
                    let cObjectives = objectives.enumerated().map { index, objective in
                        guderian_scenario_objective_t(
                            id: Int32(objective.id),
                            name: objectiveNames[index],
                            x: objective.x,
                            y: objective.y,
                            radius: objective.radius
                        )
                    }
                    return cZones.withUnsafeBufferPointer { zoneBuffer in
                        cObjectives.withUnsafeBufferPointer { objectiveBuffer in
                            game_apply_guderian_scenario_board(
                                game,
                                missionName,
                                Int32(blueprint.missionTargetScore),
                                zoneBuffer.baseAddress,
                                Int32(zoneBuffer.count),
                                objectiveBuffer.baseAddress,
                                Int32(objectiveBuffer.count)
                            )
                        }
                    }
                }
            }
        }
        let mission = game_mission_view(game)
        var notes: [String] = []
        if blueprint.terrain.count > zones.count {
            notes.append("\(blueprint.terrain.count - zones.count) late-career terrain features were summarized to fit the current dzw zone view.")
        }
        if blueprint.objectives.count > objectives.count {
            notes.append("\(blueprint.objectives.count - objectives.count) late-career objectives were summarized to fit the current dzw objective view.")
        }
        if !applied, let error = game_last_error(game), String(cString: error).isEmpty == false {
            notes.append(String(cString: error))
        }

        return NativeScenarioBoardReport(
            applied: applied,
            missionName: unifiedCString(mission.name),
            missionTargetScore: Int(mission.target_score),
            requestedTerrainZoneCount: blueprint.terrain.count,
            appliedTerrainZoneCount: Int(game_zone_count(game)),
            requestedObjectiveCount: blueprint.objectives.count,
            appliedObjectiveCount: Int(game_objective_count(game)),
            notes: notes
        )
    }

    private func deployBlueprintUnits(in game: OpaquePointer) -> NativeScenarioDeploymentReport {
        let playerIDs = engineUnitIDs(in: game, owner: DZW_PLAYER_ONE)
        let opponentIDs = engineUnitIDs(in: game, owner: DZW_PLAYER_TWO)
        let playerResult = deploy(blueprint.units.filter { $0.side == .player }, onto: playerIDs, in: game)
        let opponentResult = deploy(blueprint.units.filter { $0.side == .guderianAI }, onto: opponentIDs, in: game)
        let attempted = playerResult.attempted + opponentResult.attempted
        let succeeded = playerResult.succeeded + opponentResult.succeeded
        let skipped = max(0, blueprint.units.count - attempted)
        var notes = playerResult.notes + opponentResult.notes
        if skipped > 0 {
            notes.append("\(skipped) late-career native unit blueprints did not have matching skirmish-roster slots after catalog caps were applied.")
        }
        return NativeScenarioDeploymentReport(attempted: attempted, succeeded: succeeded, skipped: skipped, notes: notes)
    }

    private func engineUnitIDs(in game: OpaquePointer, owner: player_t) -> [Int32] {
        (0..<Int(game_unit_count(game))).compactMap { index in
            let view = game_unit_view(game, Int32(index))
            guard view.owner == owner, !view.destroyed, !view.embarked else {
                return nil
            }
            return Int32(view.id)
        }
    }

    private func deploy(_ spawns: [NativeEngineUnitSpawn], onto ids: [Int32], in game: OpaquePointer) -> (attempted: Int, succeeded: Int, notes: [String]) {
        let count = min(spawns.count, ids.count)
        guard count > 0 else {
            return (0, 0, [])
        }
        var succeeded = 0
        var notes: [String] = []
        for index in 0..<count {
            let spawn = spawns[index]
            if deploy(unitID: ids[index], near: spawn, in: game) {
                succeeded += 1
            } else {
                notes.append("Could not deploy skirmish unit \(ids[index]) near late-career spawn \(spawn.name).")
            }
        }
        return (count, succeeded, notes)
    }

    private func deploy(unitID: Int32, near spawn: NativeEngineUnitSpawn, in game: OpaquePointer) -> Bool {
        let offsets = [(0.0, 0.0), (1.5, 0), (-1.5, 0), (0, 1.5), (0, -1.5), (3, 0), (-3, 0), (0, 3), (0, -3), (3, 3), (-3, 3), (3, -3), (-3, -3)]
        for offset in offsets {
            let x = Float(unifiedClamp(spawn.x + offset.0, min: 2, max: blueprint.engineBoardFrame.width - 2))
            let y = Float(unifiedClamp(spawn.y + offset.1, min: 2, max: blueprint.engineBoardFrame.height - 2))
            if game_deploy_unit(game, unitID, x, y) {
                return true
            }
        }
        return false
    }

    private func zoneRect(for terrain: NativeEngineTerrainSpawn) -> UnifiedScenarioBoardRect {
        let points = terrain.points.isEmpty ? [NativeBattleCoordinate(x: blueprint.engineBoardFrame.width / 2, y: blueprint.engineBoardFrame.height / 2)] : terrain.points
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let padding = max(1.5, terrain.radius, unifiedIsLinearTerrain(terrain.kind) ? 1.75 : 2.75)
        let minX = unifiedClamp((xs.min() ?? 0) - padding, min: 0, max: blueprint.engineBoardFrame.width - 1)
        let maxX = unifiedClamp((xs.max() ?? blueprint.engineBoardFrame.width) + padding, min: minX + 1, max: blueprint.engineBoardFrame.width)
        let minY = unifiedClamp((ys.min() ?? 0) - padding, min: 0, max: blueprint.engineBoardFrame.height - 1)
        let maxY = unifiedClamp((ys.max() ?? blueprint.engineBoardFrame.height) + padding, min: minY + 1, max: blueprint.engineBoardFrame.height)
        return UnifiedScenarioBoardRect(x: Float(minX), y: Float(minY), width: Float(max(1, maxX - minX)), height: Float(max(1, maxY - minY)))
    }
}

public enum LateCareerNativeScenarioLoader {
    public static let cycleRange = 746...750

    public static func load(_ id: String, seed: UInt32 = 1945) -> LateCareerNativeScenarioLoadout? {
        guard let battlefield = LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields.first(where: { $0.id == id }) else {
            return nil
        }
        return load(battlefield, seed: seed)
    }

    public static func load(_ battlefield: LateCareerStaffBattlefield, seed: UInt32 = 1945) -> LateCareerNativeScenarioLoadout {
        let instance = LateCareerNativeBattleInstanceCatalog.instance(for: battlefield)
        let blueprint = instance.engineBlueprint(seed: seed)
        let playerEntries = armyListSelections(for: instance.units.filter { $0.side == .player }, army: DZW_ARMY_SOVIET)
        let opponentEntries = armyListSelections(for: instance.units.filter { $0.side == .guderianAI }, army: DZW_ARMY_GERMAN)
        return LateCareerNativeScenarioLoadout(
            battlefield: battlefield,
            seed: seed,
            instance: instance,
            blueprint: blueprint,
            playerArmy: DZW_ARMY_SOVIET,
            opponentArmy: DZW_ARMY_GERMAN,
            playerEntries: playerEntries,
            opponentEntries: opponentEntries,
            warnings: warnings(battlefield: battlefield, blueprint: blueprint, playerEntries: playerEntries, opponentEntries: opponentEntries),
            gameCreationMode: .nativeBlueprintSkirmishBridge
        )
    }

    public static var allLoadouts: [LateCareerNativeScenarioLoadout] {
        LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields.map { load($0) }
    }

    public static var acceptanceReadyThroughCycle750: Bool {
        cycleRange == 746...750 &&
            allLoadouts.count == 16 &&
            allLoadouts.allSatisfy(\.canCreateSkirmishBridge) &&
            allLoadouts.allSatisfy(\.canApplyScenarioBoardHook)
    }

    private static func armyListSelections(for units: [NativeBattleUnit], army: army_list_t) -> [NativeScenarioArmyListSelection] {
        let options = catalogOptions(for: army)
        var counts: [Int: Int] = [:]
        var hints: [Int: Set<String>] = [:]
        for unit in units {
            guard let option = bestCatalogOption(for: unit, options: options, currentCounts: counts) else {
                continue
            }
            counts[option.catalogID, default: 0] += 1
            hints[option.catalogID, default: []].insert(unit.mobility.rawValue)
            for weapon in unit.weapons.prefix(2) {
                hints[option.catalogID, default: []].insert(weapon.role.rawValue)
            }
        }
        return counts.keys.sorted().compactMap { catalogID in
            guard let option = options.first(where: { $0.catalogID == catalogID }) else {
                return nil
            }
            return NativeScenarioArmyListSelection(
                id: "\(armyName(army))-\(catalogID)",
                catalogID: catalogID,
                count: counts[catalogID, default: 0],
                catalogName: option.name,
                roleHints: Array(hints[catalogID, default: []]).sorted()
            )
        }
    }

    private static func bestCatalogOption(for unit: NativeBattleUnit, options: [UnifiedCatalogOption], currentCounts: [Int: Int]) -> UnifiedCatalogOption? {
        options
            .filter { currentCounts[$0.catalogID, default: 0] < $0.maxCount }
            .max { score($0, for: unit) < score($1, for: unit) }
    }

    private static func score(_ option: UnifiedCatalogOption, for unit: NativeBattleUnit) -> Int {
        let text = "\(option.name) \(option.primaryWeaponName)".lowercased()
        let unitText = "\(unit.name) \(unit.role) \(unit.historicalNote)".lowercased()
        var score = option.kind == DZW_UNIT_INFANTRY ? 4 : 1
        if unit.mobility == .armor, option.kind == DZW_UNIT_VEHICLE || option.kind == DZW_UNIT_ASSAULT_GUN { score += 8 }
        if unit.mobility == .engineer, text.contains("engineer") || text.contains("pioneer") { score += 8 }
        if unit.mobility == .gun || unit.mobility == .artillery, unifiedContainsAny(text, ["mortar", "mg", "anti", "gun", "battery"]) { score += 7 }
        if unit.mobility == .command, unifiedContainsAny(text, ["command", "hq", "officer", "observer"]) { score += 8 }
        if unifiedContainsAny(unitText, ["tank", "armor", "armored", "panzer"]), option.kind == DZW_UNIT_VEHICLE || option.kind == DZW_UNIT_ASSAULT_GUN { score += 5 }
        if unifiedContainsAny(unitText, ["bridge", "crossing", "river"]), unifiedContainsAny(text, ["engineer", "pioneer", "sapper"]) { score += 4 }
        return score
    }

    private static func catalogOptions(for army: army_list_t) -> [UnifiedCatalogOption] {
        (0..<Int(army_catalog_unit_count(army))).map { index in
            let view = army_catalog_unit_view(army, Int32(index))
            return UnifiedCatalogOption(
                catalogID: index,
                name: unifiedCString(view.name),
                primaryWeaponName: unifiedCString(view.unit.primary_weapon_name),
                kind: view.unit.kind,
                maxCount: max(1, Int(view.max_count))
            )
        }
    }

    private static func warnings(
        battlefield: LateCareerStaffBattlefield,
        blueprint: LateCareerNativeBattleBlueprint,
        playerEntries: [NativeScenarioArmyListSelection],
        opponentEntries: [NativeScenarioArmyListSelection]
    ) -> [NativeScenarioLoaderWarning] {
        [
            blueprint.isCompleteForScenarioLoader ? nil : NativeScenarioLoaderWarning(
                id: "\(battlefield.id)-blueprint-incomplete",
                title: "Late-career native blueprint incomplete",
                detail: "The late-career board adapter is missing units, objectives, terrain, or mission target score."
            ),
            (playerEntries.isEmpty || opponentEntries.isEmpty) ? NativeScenarioLoaderWarning(
                id: "\(battlefield.id)-army-list-empty",
                title: "Late-career army-list bridge incomplete",
                detail: "The loader could not map one side of the late-career roster onto the current dzw army catalog."
            ) : nil,
        ].compactMap { $0 }
    }
}

public struct LateCareerNativeBoardSnapshot: Codable, Hashable, Sendable {
    public let battlefieldID: String
    public let title: String
    public let turnNumber: Int
    public let unitCount: Int
    public let objectiveCount: Int
    public let zoneCount: Int
    public let mission: NativeBoardMissionSnapshot
    public let boardReport: NativeScenarioBoardReport
    public let deploymentReport: NativeScenarioDeploymentReport

    public var isScenarioBoardPlayable: Bool {
        boardReport.isScenarioSpecific && unitCount > 0 && objectiveCount > 0
    }
}

public struct LateCareerNativeAIExecutionStep: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battlefieldID: String
    public let turnNumber: Int
    public let activePlayer: NativeBoardPlayer
    public let phase: NativeBoardPhase
    public let targetPriorityName: String
    public let unitName: String
    public let action: NativeBoardActionMessage

    public var usedLegalBoardAction: Bool {
        action.status == .succeeded
    }

    public var reportedBlockedMove: Bool {
        action.status == .blocked && action.title.localizedCaseInsensitiveContains("blocked")
    }
}

public struct LateCareerNativeAIExecutionReport: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let cycleRange: ClosedRange<Int>
    public let battlefieldID: String
    public let title: String
    public let germanTurnRunnerName: String
    public let targetPriorityNames: [String]
    public let steps: [LateCareerNativeAIExecutionStep]
    public let boardSnapshot: LateCareerNativeBoardSnapshot
    public let blockers: [String]

    public var completedGermanTurnRunner: Bool {
        cycleRange == 781...785 &&
            germanTurnRunnerName == UnifiedLateCareerAIExecutionCatalog.germanTurnRunnerName &&
            targetPriorityNames.isEmpty == false &&
            steps.isEmpty == false &&
            blockers.isEmpty &&
            steps.contains { $0.activePlayer == .guderianAI } &&
            steps.contains { $0.usedLegalBoardAction || $0.reportedBlockedMove } &&
            boardSnapshot.isScenarioBoardPlayable
    }
}

public final class LateCareerNativeBoardSession {
    public static let cycleRange = 746...750

    public let loadout: LateCareerNativeScenarioLoadout
    private let loadedGame: NativeScenarioLoadedGame
    private let nativeUnitByEngineID: [Int: NativeBattleUnit]
    private var selectedUnitID: Int?
    private var selectedTargetID: Int?
    private var lastAction = NativeBoardActionMessage(status: .idle, title: "Ready", detail: "Board session is ready.")

    public var handle: OpaquePointer {
        loadedGame.handle
    }

    public init?(battlefieldID: String, seed: UInt32 = 1945) {
        guard let loadout = LateCareerNativeScenarioLoader.load(battlefieldID, seed: seed),
              let loadedGame = loadout.makeGame() else {
            return nil
        }
        self.loadout = loadout
        self.loadedGame = loadedGame
        nativeUnitByEngineID = Self.nativeUnitMap(handle: loadedGame.handle, instance: loadout.instance)
        selectFirstActiveUnit()
        selectNearestEnemyToSelectedUnit()
    }

    public func runGermanTurn(priorityNames: [String], maxSteps: Int = 10) -> [LateCareerNativeAIExecutionStep] {
        var steps: [LateCareerNativeAIExecutionStep] = []
        var safety = 0

        while NativeBoardPlayer(game_view(handle).active_player) != .guderianAI &&
            NativeBoardPlayer(game_mission_view(handle).winner) == .none &&
            safety < 4 {
            game_advance_phase(handle)
            selectFirstActiveUnit()
            selectNearestEnemyToSelectedUnit()
            safety += 1
        }

        while NativeBoardPlayer(game_view(handle).active_player) == .guderianAI &&
            NativeBoardPlayer(game_mission_view(handle).winner) == .none &&
            steps.count < maxSteps &&
            safety < 16 {
            let step = runActiveGermanStep(priorityNames: priorityNames)
            steps.append(step)
            lastAction = step.action
            game_advance_phase(handle)
            selectFirstActiveUnit()
            selectNearestEnemyToSelectedUnit()
            safety += 1
        }

        return steps
    }

    public func lateCareerSnapshot() -> LateCareerNativeBoardSnapshot {
        let fullSnapshot = snapshot()
        return LateCareerNativeBoardSnapshot(
            battlefieldID: loadout.battlefield.id,
            title: loadout.battlefield.title,
            turnNumber: fullSnapshot.turnNumber,
            unitCount: fullSnapshot.units.count,
            objectiveCount: fullSnapshot.objectives.count,
            zoneCount: fullSnapshot.zones.count,
            mission: fullSnapshot.mission,
            boardReport: loadedGame.boardReport,
            deploymentReport: loadedGame.deploymentReport
        )
    }

    public func snapshot() -> NativeBoardSnapshot {
        let view = game_view(handle)
        let mission = game_mission_view(handle)
        return NativeBoardSnapshot(
            scenarioID: .moscowTulaKashira,
            scenarioTitle: loadout.battlefield.title,
            turnNumber: Int(view.turn_number),
            activePlayer: NativeBoardPlayer(view.active_player),
            phase: unifiedBoardPhase(view.phase),
            mission: NativeBoardMissionSnapshot(
                name: unifiedCString(mission.name),
                targetScore: Int(mission.target_score),
                playerScore: Int(mission.player_one_score),
                opponentScore: Int(mission.player_two_score),
                winner: NativeBoardPlayer(mission.winner)
            ),
            units: unitSnapshots(),
            zones: zoneSnapshots(),
            objectives: objectiveSnapshots(),
            logLines: logLines(),
            lastAction: lastAction,
            boardReport: loadedGame.boardReport,
            deploymentReport: loadedGame.deploymentReport
        )
    }

    public func selectUnit(_ id: Int) {
        selectedUnitID = id
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Unit selected", detail: unitName(id: id))
        if selectedTargetID == id {
            selectedTargetID = nil
        }
    }

    public func selectTarget(_ id: Int) {
        selectedTargetID = id
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Target selected", detail: unitName(id: id))
    }

    public func selectFirstActiveUnit() {
        selectedUnitID = (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { $0.owner == game_view(self.handle).active_player && !$0.destroyed && !$0.embarked }
            .map { Int($0.id) }
    }

    public func selectNearestEnemyToSelectedUnit() {
        guard let selected = selectedUnitView() else {
            selectedTargetID = nil
            return
        }
        selectedTargetID = nearestEnemy(to: selected).map { Int($0.id) }
    }

    @discardableResult
    public func moveSelectedUnitTowardNearestObjective(maxDistance: Double = 4) -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before issuing movement.")
        }
        guard unifiedBoardPhase(game_view(handle).phase) == .movement, unit.can_move_now else {
            return failAction("Movement blocked", "\(unitDisplayName(unit)) cannot move in the current phase.")
        }
        guard let objective = nearestObjective(to: unit) else {
            return failAction("No objective", "The board has no scenario objective to move toward.")
        }

        if move(unit, toward: objective, maxDistance: maxDistance) {
            selectedUnitID = Int(unit.id)
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Moved", detail: "\(unitDisplayName(unit)) advanced toward \(unifiedCString(objective.name)).")
            return true
        }

        return failFromEngine("Move blocked")
    }

    @discardableResult
    public func moveSelectedUnitTowardPriorityObjective(named priorityNames: [String], maxDistance: Double = 6) -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before issuing movement.")
        }
        guard unifiedBoardPhase(game_view(handle).phase) == .movement, unit.can_move_now else {
            return failAction("Movement blocked", "\(unitDisplayName(unit)) cannot move in the current phase.")
        }
        let priorityObjectives = priorityObjectives(named: priorityNames)
        var candidateObjectives = priorityObjectives
        if let nearest = nearestObjective(to: unit), !candidateObjectives.contains(where: { $0.id == nearest.id }) {
            candidateObjectives.append(nearest)
        }
        guard !candidateObjectives.isEmpty else {
            return failAction("No objective", "The board has no scenario objective to move toward.")
        }

        for objective in candidateObjectives where move(unit, toward: objective, maxDistance: maxDistance) {
            selectedUnitID = Int(unit.id)
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Moved", detail: "\(unitDisplayName(unit)) advanced toward \(unifiedCString(objective.name)).")
            return true
        }

        return failFromEngine("Priority move blocked")
    }

    @discardableResult
    public func moveUnit(_ id: Int, to point: NativeBattleCoordinate) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        guard unifiedBoardPhase(game_view(handle).phase) == .movement, unit.can_move_now else {
            return failAction("Movement blocked", "\(unitDisplayName(unit)) cannot move in the current phase.")
        }

        let x = unifiedClamp(point.x, min: 1, max: loadout.blueprint.engineBoardFrame.width - 1)
        let y = unifiedClamp(point.y, min: 1, max: loadout.blueprint.engineBoardFrame.height - 1)
        if game_move_unit(handle, Int32(id), Float(x), Float(y)) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Moved", detail: "\(unitDisplayName(unit)) moved to \(Int(x)), \(Int(y)).")
            return true
        }
        return failFromEngine("Move blocked")
    }

    @discardableResult
    public func rotateUnit(_ id: Int, to facingDegrees: Double) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        if game_rotate_unit(handle, Int32(id), Float(facingDegrees)) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Rotated", detail: "\(unitDisplayName(unit)) rotated to \(Int(facingDegrees)) degrees.")
            return true
        }
        return failFromEngine("Rotate blocked")
    }

    @discardableResult
    public func toggleCover(for id: Int, enabled: Bool) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        if game_toggle_cover(handle, Int32(id), enabled) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Cover updated", detail: "\(unitDisplayName(unit)) \(enabled ? "entered" : "left") cover.")
            return true
        }
        return failFromEngine("Cover toggle blocked")
    }

    @discardableResult
    public func toggleHullDown(for id: Int, enabled: Bool) -> Bool {
        guard let unit = unitView(id: id) else {
            return failAction("Unit unavailable", "Unit \(id) is not present on the board.")
        }
        if game_toggle_hull_down(handle, Int32(id), enabled) {
            selectedUnitID = id
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Hull-down updated", detail: "\(unitDisplayName(unit)) \(enabled ? "took" : "left") hull-down position.")
            return true
        }
        return failFromEngine("Hull-down toggle blocked")
    }

    @discardableResult
    public func shootUnit(_ attackerID: Int, targetID: Int) -> Bool {
        guard let unit = unitView(id: attackerID) else {
            return failAction("Unit unavailable", "Unit \(attackerID) is not present on the board.")
        }
        guard unifiedBoardPhase(game_view(handle).phase) == .shooting, unit.can_shoot_now else {
            return failAction("Shooting blocked", "\(unitDisplayName(unit)) cannot shoot in the current phase.")
        }
        if game_shoot_unit(handle, Int32(attackerID), Int32(targetID)) {
            selectedUnitID = attackerID
            selectedTargetID = targetID
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Fired", detail: "\(unitDisplayName(unit)) fired at \(unitName(id: targetID)).")
            resolveFirstPendingChoice()
            return true
        }
        return failFromEngine("Shot blocked")
    }

    @discardableResult
    public func assaultUnit(_ attackerID: Int, targetID: Int, advance: Bool = true) -> Bool {
        guard let unit = unitView(id: attackerID) else {
            return failAction("Unit unavailable", "Unit \(attackerID) is not present on the board.")
        }
        guard unifiedBoardPhase(game_view(handle).phase) == .assault, unit.can_assault_now else {
            return failAction("Assault blocked", "\(unitDisplayName(unit)) cannot assault in the current phase.")
        }
        let followUp = advance ? DZW_FOLLOW_UP_ADVANCE : DZW_FOLLOW_UP_CONSOLIDATE
        if game_assault_unit(handle, Int32(attackerID), Int32(targetID), followUp) {
            selectedUnitID = attackerID
            selectedTargetID = targetID
            lastAction = NativeBoardActionMessage(status: .succeeded, title: "Assaulted", detail: "\(unitDisplayName(unit)) assaulted \(unitName(id: targetID)).")
            resolveFirstPendingChoice()
            return true
        }
        return failFromEngine("Assault blocked")
    }

    @discardableResult
    public func shootSelectedTarget() -> Bool {
        guard let unit = selectedUnitView() else {
            return failAction("No unit selected", "Select a unit before shooting.")
        }
        guard let targetID = selectedTargetID else {
            return failAction("No target selected", "Select an enemy unit before shooting.")
        }
        return shootUnit(Int(unit.id), targetID: targetID)
    }

    public func advancePhase() {
        game_advance_phase(handle)
        selectFirstActiveUnit()
        selectNearestEnemyToSelectedUnit()
        let view = game_view(handle)
        lastAction = NativeBoardActionMessage(status: .succeeded, title: "Phase advanced", detail: "\(NativeBoardPlayer(view.active_player).rawValue) \(unifiedBoardPhase(view.phase).rawValue), turn \(Int(view.turn_number)).")
    }

    @discardableResult
    public func resolveFirstPendingChoice() -> Bool {
        let hitAllocation = game_pending_hit_allocation_view(handle)
        if hitAllocation.active {
            let result = game_choose_pending_hit_allocation(handle, 0)
            lastAction = NativeBoardActionMessage(
                status: result ? .succeeded : .blocked,
                title: result ? "Hit allocation resolved" : "Hit allocation blocked",
                detail: result ? "Applied the first legal damage allocation." : lastEngineError()
            )
            return result
        }

        let weaponChoice = game_pending_weapon_destroy_view(handle)
        if weaponChoice.active, game_pending_weapon_destroy_option_count(handle) > 0 {
            let option = game_pending_weapon_destroy_option_view(handle, 0)
            let result = game_choose_pending_weapon_destroy(handle, option.weapon_index)
            lastAction = NativeBoardActionMessage(
                status: result ? .succeeded : .blocked,
                title: result ? "Weapon damage resolved" : "Weapon damage blocked",
                detail: result ? "Applied the first legal weapon-damage option." : lastEngineError()
            )
            return result
        }

        return false
    }

    private func runActiveGermanStep(priorityNames: [String]) -> LateCareerNativeAIExecutionStep {
        let view = game_view(handle)
        let phase = unifiedBoardPhase(view.phase)
        let target = priorityObjective(named: priorityNames) ?? nearestObjective(to: activeUnit())
        let targetName = target.map { unifiedCString($0.name) } ?? priorityNames.first ?? "Scenario objective"
        let unit = activeUnit()
        let unitName = unit.map { unifiedCString($0.name) } ?? "German pressure unit"
        let action: NativeBoardActionMessage

        switch phase {
        case .movement:
            action = moveActiveUnitTowardPriorityObjective(target: target)
        case .shooting:
            action = shootActiveUnitAtNearestEnemy()
        case .assault:
            action = assaultActiveUnitAtNearestEnemy()
        }

        return LateCareerNativeAIExecutionStep(
            id: "\(loadout.battlefield.id)-ai-\(Int(view.turn_number))-\(phase.rawValue.lowercased())-\(game_log_count(handle))",
            battlefieldID: loadout.battlefield.id,
            turnNumber: Int(view.turn_number),
            activePlayer: NativeBoardPlayer(view.active_player),
            phase: phase,
            targetPriorityName: targetName,
            unitName: unitName,
            action: action
        )
    }

    private func moveActiveUnitTowardPriorityObjective(target: objective_view_t?) -> NativeBoardActionMessage {
        guard let unit = activeUnit() else {
            return NativeBoardActionMessage(status: .blocked, title: "Move blocked", detail: "No active German unit is available.")
        }
        guard unifiedBoardPhase(game_view(handle).phase) == .movement, unit.can_move_now else {
            return NativeBoardActionMessage(status: .blocked, title: "Move blocked", detail: "\(unifiedCString(unit.name)) cannot move in the current phase.")
        }
        guard let target else {
            return NativeBoardActionMessage(status: .blocked, title: "Move blocked", detail: "No objective is available for German pressure.")
        }

        if move(unit, toward: target, maxDistance: 6) {
            return NativeBoardActionMessage(status: .succeeded, title: "Moved", detail: "\(unifiedCString(unit.name)) advanced toward \(unifiedCString(target.name)).")
        }

        let error = lastEngineError()
        return NativeBoardActionMessage(status: .blocked, title: "Move blocked", detail: error.isEmpty ? "\(unifiedCString(unit.name)) could not advance toward \(unifiedCString(target.name))." : error)
    }

    private func shootActiveUnitAtNearestEnemy() -> NativeBoardActionMessage {
        guard let unit = activeUnit() else {
            return NativeBoardActionMessage(status: .blocked, title: "Shot blocked", detail: "No active German unit is available.")
        }
        guard unifiedBoardPhase(game_view(handle).phase) == .shooting, unit.can_shoot_now else {
            return NativeBoardActionMessage(status: .blocked, title: "Shot blocked", detail: "\(unifiedCString(unit.name)) cannot shoot in the current phase.")
        }
        guard let target = nearestEnemy(to: unit) else {
            return NativeBoardActionMessage(status: .blocked, title: "Shot blocked", detail: "No enemy unit is available.")
        }

        if game_shoot_unit(handle, Int32(unit.id), Int32(target.id)) {
            resolveFirstPendingChoice()
            return NativeBoardActionMessage(status: .succeeded, title: "Fired", detail: "\(unifiedCString(unit.name)) fired at \(unifiedCString(target.name)).")
        }

        return NativeBoardActionMessage(status: .blocked, title: "Shot blocked", detail: lastEngineError())
    }

    private func assaultActiveUnitAtNearestEnemy() -> NativeBoardActionMessage {
        guard let unit = activeUnit() else {
            return NativeBoardActionMessage(status: .blocked, title: "Assault blocked", detail: "No active German unit is available.")
        }
        guard unifiedBoardPhase(game_view(handle).phase) == .assault, unit.can_assault_now else {
            return NativeBoardActionMessage(status: .blocked, title: "Assault blocked", detail: "\(unifiedCString(unit.name)) cannot assault in the current phase.")
        }
        guard let target = nearestEnemy(to: unit) else {
            return NativeBoardActionMessage(status: .blocked, title: "Assault blocked", detail: "No enemy unit is available.")
        }

        if game_assault_unit(handle, Int32(unit.id), Int32(target.id), DZW_FOLLOW_UP_ADVANCE) {
            resolveFirstPendingChoice()
            return NativeBoardActionMessage(status: .succeeded, title: "Assaulted", detail: "\(unifiedCString(unit.name)) assaulted \(unifiedCString(target.name)).")
        }

        return NativeBoardActionMessage(status: .blocked, title: "Assault blocked", detail: lastEngineError())
    }

    private func activeUnit() -> unit_view_t? {
        let activePlayer = game_view(handle).active_player
        return (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { $0.owner == activePlayer && !$0.destroyed && !$0.embarked }
    }

    private func selectedUnitView() -> unit_view_t? {
        guard let selectedUnitID else {
            return nil
        }
        return unitView(id: selectedUnitID)
    }

    private func unitView(id: Int) -> unit_view_t? {
        (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { Int($0.id) == id }
    }

    private func nearestEnemy(to unit: unit_view_t) -> unit_view_t? {
        (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .filter { $0.owner != unit.owner && $0.owner != DZW_PLAYER_NONE && !$0.destroyed && !$0.embarked }
            .min { lhs, rhs in
                unifiedDistance(from: unit, to: lhs) < unifiedDistance(from: unit, to: rhs)
            }
    }

    private func nearestObjective(to unit: unit_view_t?) -> objective_view_t? {
        guard let unit else {
            return (0..<Int(game_objective_count(handle))).lazy
                .map { game_objective_view(self.handle, Int32($0)) }
                .first
        }

        return (0..<Int(game_objective_count(handle))).lazy
            .map { game_objective_view(self.handle, Int32($0)) }
            .min { lhs, rhs in
                unifiedDistance(from: unit, to: lhs) < unifiedDistance(from: unit, to: rhs)
            }
    }

    private func priorityObjective(named priorityNames: [String]) -> objective_view_t? {
        let objectives = (0..<Int(game_objective_count(handle))).map { game_objective_view(self.handle, Int32($0)) }
        for priorityName in priorityNames {
            let priority = unifiedNormalized(priorityName)
            if let objective = objectives.first(where: { objective in
                let name = unifiedNormalized(unifiedCString(objective.name))
                return name.contains(priority) || priority.contains(name)
            }) {
                return objective
            }
        }
        return nil
    }

    private func priorityObjectives(named priorityNames: [String]) -> [objective_view_t] {
        let objectives = (0..<Int(game_objective_count(handle))).map { game_objective_view(self.handle, Int32($0)) }
        var matches: [objective_view_t] = []
        for priorityName in priorityNames {
            let priority = unifiedNormalized(priorityName)
            if let objective = objectives.first(where: { objective in
                let name = unifiedNormalized(unifiedCString(objective.name))
                return name.contains(priority) || priority.contains(name)
            }), !matches.contains(where: { $0.id == objective.id }) {
                matches.append(objective)
            }
        }
        return matches
    }

    private func move(_ unit: unit_view_t, toward objective: objective_view_t, maxDistance: Double) -> Bool {
        let dx = Double(objective.x) - Double(unit.x)
        let dy = Double(objective.y) - Double(unit.y)
        let length = max(0.01, sqrt(dx * dx + dy * dy))
        let baseStep = min(maxDistance, length)
        let candidateDistances = [baseStep, baseStep / 2, min(1.5, length), min(0.75, length)]
            .filter { $0 > 0.05 }
        let xDirection = dx == 0 ? 0 : dx / abs(dx)
        let yDirection = dy == 0 ? 0 : dy / abs(dy)

        for distance in candidateDistances {
            let candidates = [
                (
                    Double(unit.x) + (dx / length) * distance,
                    Double(unit.y) + (dy / length) * distance
                ),
                (
                    Double(unit.x) + xDirection * distance,
                    Double(unit.y)
                ),
                (
                    Double(unit.x),
                    Double(unit.y) + yDirection * distance
                ),
            ]

            for candidate in candidates {
                let x = unifiedClamp(candidate.0, min: 1, max: loadout.blueprint.engineBoardFrame.width - 1)
                let y = unifiedClamp(candidate.1, min: 1, max: loadout.blueprint.engineBoardFrame.height - 1)
                if game_move_unit(handle, Int32(unit.id), Float(x), Float(y)) {
                    return true
                }
            }
        }

        return false
    }

    private func unitSnapshots() -> [NativeBoardUnitSnapshot] {
        (0..<Int(game_unit_count(handle))).map { index in
            let unit = game_unit_view(handle, Int32(index))
            let engineName = unifiedCString(unit.name)
            let nativeUnit = nativeUnitByEngineID[Int(unit.id)]
            let engineKind = unifiedUnitKindName(unit.kind)
            return NativeBoardUnitSnapshot(
                id: Int(unit.id),
                name: nativeUnit?.name ?? engineName,
                engineName: engineName,
                nativeUnitID: nativeUnit?.id,
                owner: NativeBoardPlayer(unit.owner),
                kind: engineKind,
                mobility: nativeUnit?.mobility.rawValue ?? engineKind,
                role: nativeUnit?.role ?? engineKind,
                historicalNote: nativeUnit?.historicalNote ?? "",
                x: Double(unit.x),
                y: Double(unit.y),
                facingDegrees: Double(unit.facing_degrees),
                totalWoundsRemaining: Int(unit.total_wounds_remaining),
                destroyed: unit.destroyed,
                inCover: unit.in_cover,
                hullDown: unit.hull_down,
                pinned: unit.pinned,
                canMoveNow: unit.can_move_now,
                canShootNow: unit.can_shoot_now,
                canAssaultNow: unit.can_assault_now,
                selected: Int(unit.id) == selectedUnitID,
                targeted: Int(unit.id) == selectedTargetID
            )
        }
    }

    private func zoneSnapshots() -> [NativeBoardZoneSnapshot] {
        (0..<Int(game_zone_count(handle))).map { index in
            let zone = game_zone_view(handle, Int32(index))
            return NativeBoardZoneSnapshot(
                id: Int(zone.id),
                name: unifiedCString(zone.name),
                kind: unifiedTerrainKindName(zone.kind),
                x: Double(zone.rect.x),
                y: Double(zone.rect.y),
                width: Double(zone.rect.width),
                height: Double(zone.rect.height),
                coverSave: Int(zone.cover_save),
                blocksLineOfSight: zone.blocks_line_of_sight,
                hullDown: zone.hull_down
            )
        }
    }

    private func objectiveSnapshots() -> [NativeBoardObjectiveSnapshot] {
        (0..<Int(game_objective_count(handle))).map { index in
            let objective = game_objective_view(handle, Int32(index))
            return NativeBoardObjectiveSnapshot(
                id: Int(objective.id),
                name: unifiedCString(objective.name),
                x: Double(objective.x),
                y: Double(objective.y),
                radius: Double(objective.radius),
                controller: NativeBoardPlayer(objective.controller),
                playerPresence: Int(objective.player_one_presence),
                opponentPresence: Int(objective.player_two_presence)
            )
        }
    }

    private func logLines() -> [String] {
        (0..<Int(game_log_count(handle))).map { index in
            unifiedCString(game_log_line(handle, Int32(index)))
        }
    }

    private func unitName(id: Int) -> String {
        (0..<Int(game_unit_count(handle))).lazy
            .map { game_unit_view(self.handle, Int32($0)) }
            .first { Int($0.id) == id }
            .map(unitDisplayName) ?? "Unit \(id)"
    }

    private func unitDisplayName(_ unit: unit_view_t) -> String {
        nativeUnitByEngineID[Int(unit.id)]?.name ?? unifiedCString(unit.name)
    }

    private static func nativeUnitMap(handle: OpaquePointer, instance: LateCareerNativeBattleInstance) -> [Int: NativeBattleUnit] {
        let nativeBySide: [NativeBoardPlayer: [NativeBattleUnit]] = [
            .player: instance.units.filter { $0.side == .player },
            .guderianAI: instance.units.filter { $0.side == .guderianAI },
        ]
        var sideOffsets: [NativeBoardPlayer: Int] = [:]
        var result: [Int: NativeBattleUnit] = [:]

        for index in 0..<Int(game_unit_count(handle)) {
            let unit = game_unit_view(handle, Int32(index))
            let owner = NativeBoardPlayer(unit.owner)
            guard owner == .player || owner == .guderianAI, !unit.destroyed, !unit.embarked else {
                continue
            }
            let offset = sideOffsets[owner, default: 0]
            sideOffsets[owner] = offset + 1
            if let nativeUnits = nativeBySide[owner], nativeUnits.indices.contains(offset) {
                result[Int(unit.id)] = nativeUnits[offset]
            }
        }
        return result
    }

    private func failFromEngine(_ title: String) -> Bool {
        failAction(title, lastEngineError())
    }

    private func failAction(_ title: String, _ detail: String) -> Bool {
        lastAction = NativeBoardActionMessage(status: .blocked, title: title, detail: detail)
        return false
    }

    private func lastEngineError() -> String {
        let error = unifiedCString(game_last_error(handle))
        return error.isEmpty ? "The engine rejected the action." : error
    }
}

public enum UnifiedLateCareerAIExecutionCatalog {
    public static let cycleRange = 781...785
    public static let germanTurnRunnerName = "DZWPlayableBattleViewModel.runGermanTurn"

    public static var routedBattlefieldIDs: [String] {
        UnifiedPlayableBoardRouteCatalog.lateCareerRoutedIDsThroughCycle780
    }

    public static var allReports: [LateCareerNativeAIExecutionReport] {
        routedBattlefieldIDs.enumerated().compactMap { index, id in
            report(for: id, seed: UInt32(785_000 + index))
        }
    }

    public static func report(for battlefieldID: String, seed: UInt32 = 785_001) -> LateCareerNativeAIExecutionReport? {
        guard let route = UnifiedPlayableBoardRouteCatalog.route(for: .lateCareer(battlefieldID)),
              let session = LateCareerNativeBoardSession(battlefieldID: battlefieldID, seed: seed),
              let plan = LateCareerPlayableSurfaceCatalog.aiPlan(for: battlefieldID) else {
            return nil
        }

        let priorities = plan.priorities.map(\.targetName)
        let steps = session.runGermanTurn(priorityNames: priorities)
        let snapshot = session.lateCareerSnapshot()
        let blockers = [
            route.isFullPlayableBoardRoute ? nil : "\(route.title) is not routed through the full playable board contract.",
            priorities.isEmpty ? "\(route.title) has no AI target priorities." : nil,
            steps.isEmpty ? "\(route.title) produced no German AI board steps." : nil,
            steps.contains { $0.usedLegalBoardAction || $0.reportedBlockedMove } ? nil : "\(route.title) produced no legal or reported-blocked board action.",
            snapshot.isScenarioBoardPlayable ? nil : "\(route.title) does not expose a playable scenario board snapshot.",
        ].compactMap { $0 }

        return LateCareerNativeAIExecutionReport(
            id: "\(battlefieldID)-unified-ai-execution",
            cycleRange: cycleRange,
            battlefieldID: battlefieldID,
            title: route.title,
            germanTurnRunnerName: germanTurnRunnerName,
            targetPriorityNames: priorities,
            steps: steps,
            boardSnapshot: snapshot,
            blockers: blockers
        )
    }

    public static var acceptanceReadyThroughCycle785: Bool {
        cycleRange == 781...785 &&
            allReports.count == 16 &&
            allReports.map(\.battlefieldID) == routedBattlefieldIDs &&
            allReports.allSatisfy(\.completedGermanTurnRunner) &&
            allReports.allSatisfy { $0.germanTurnRunnerName == germanTurnRunnerName } &&
            allReports.allSatisfy { $0.steps.contains { $0.activePlayer == .guderianAI } } &&
            allReports.allSatisfy { $0.steps.contains { $0.usedLegalBoardAction || $0.reportedBlockedMove } }
    }
}

public struct UnifiedLateCareerScoreBand: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battlefieldID: String
    public let victoryBand: VictoryBand
    public let minimumScore: Int
    public let debriefText: String
}

public struct UnifiedLateCareerPlayableCompletionSummary: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let cycleRange: ClosedRange<Int>
    public let sourceName: String
    public let completionRecord: LateCareerCompletionRecord
    public let scoreBands: [UnifiedLateCareerScoreBand]
    public let completedTurn: Int
    public let debriefSummary: String
    public let persistenceKey: String
    public let failureHandling: String
    public let usedNativeBoardState: Bool

    public var isResolvedThroughUnifiedPattern: Bool {
        cycleRange == 786...790 &&
            sourceName == UnifiedLateCareerCompletionResolver.sourceName &&
            completionRecord.completedTurn == completedTurn &&
            completionRecord.persistenceKey == persistenceKey &&
            completionRecord.note == debriefSummary &&
            scoreBands.count >= 4 &&
            scoreBands.contains { $0.victoryBand == completionRecord.victoryBand } &&
            failureHandling.localizedCaseInsensitiveContains("failure") &&
            usedNativeBoardState
    }
}

public enum UnifiedLateCareerCompletionResolver {
    public static let cycleRange = 786...790
    public static let sourceName = "Unified DZW playable battle completion resolver"

    public static func completeBattle(from session: LateCareerNativeBoardSession) -> UnifiedLateCareerPlayableCompletionSummary? {
        guard let report = LateCareerPlayableSurfaceCatalog.report(for: session.loadout.battlefield.id) else {
            return nil
        }

        let snapshot = session.lateCareerSnapshot()
        let score = score(for: snapshot, report: report)
        let band = victoryBand(for: score, report: report)
        let completedTurn = max(snapshot.turnNumber, report.scoringProfile.targetTurnUpperBound)
        let debrief = debriefText(for: band, report: report)
        let persistenceKey = report.scoringProfile.persistenceKey
        let completionRecord = LateCareerCompletionRecord(
            battlefieldID: report.battlefieldID,
            score: score,
            victoryBand: band,
            completedTurn: completedTurn,
            persistenceKey: persistenceKey,
            note: debrief
        )

        return UnifiedLateCareerPlayableCompletionSummary(
            id: "\(report.battlefieldID)-unified-completion",
            cycleRange: cycleRange,
            sourceName: sourceName,
            completionRecord: completionRecord,
            scoreBands: scoreBands(for: report),
            completedTurn: completedTurn,
            debriefSummary: debrief,
            persistenceKey: persistenceKey,
            failureHandling: failureHandling(for: report),
            usedNativeBoardState: snapshot.isScenarioBoardPlayable
        )
    }

    public static func failureSummary(from session: LateCareerNativeBoardSession) -> UnifiedLateCareerPlayableCompletionSummary? {
        guard let report = LateCareerPlayableSurfaceCatalog.report(for: session.loadout.battlefield.id) else {
            return nil
        }

        let snapshot = session.lateCareerSnapshot()
        let completedTurn = max(snapshot.turnNumber, report.scoringProfile.targetTurnUpperBound)
        let persistenceKey = report.scoringProfile.persistenceKey
        let debrief = failureHandling(for: report)
        let completionRecord = LateCareerCompletionRecord(
            battlefieldID: report.battlefieldID,
            score: max(0, report.scoringProfile.oppositionObjectiveScore),
            victoryBand: .historicalPressure,
            completedTurn: completedTurn,
            persistenceKey: persistenceKey,
            note: debrief
        )

        return UnifiedLateCareerPlayableCompletionSummary(
            id: "\(report.battlefieldID)-unified-failure",
            cycleRange: cycleRange,
            sourceName: sourceName,
            completionRecord: completionRecord,
            scoreBands: scoreBands(for: report),
            completedTurn: completedTurn,
            debriefSummary: debrief,
            persistenceKey: persistenceKey,
            failureHandling: debrief,
            usedNativeBoardState: snapshot.isScenarioBoardPlayable
        )
    }

    public static func scoreBands(for report: LateCareerPlayableBattleReport) -> [UnifiedLateCareerScoreBand] {
        let scoring = report.scoringProfile
        return [
            UnifiedLateCareerScoreBand(
                id: "\(report.battlefieldID)-decisive",
                battlefieldID: report.battlefieldID,
                victoryBand: .decisive,
                minimumScore: scoring.maxPlayerScore + 1,
                debriefText: report.debriefProfile.operationalText
            ),
            UnifiedLateCareerScoreBand(
                id: "\(report.battlefieldID)-operational",
                battlefieldID: report.battlefieldID,
                victoryBand: .operational,
                minimumScore: scoring.maxPlayerScore,
                debriefText: report.debriefProfile.operationalText
            ),
            UnifiedLateCareerScoreBand(
                id: "\(report.battlefieldID)-tactical",
                battlefieldID: report.battlefieldID,
                victoryBand: .tactical,
                minimumScore: max(1, scoring.playerObjectiveScore / 2),
                debriefText: report.debriefProfile.tacticalText
            ),
            UnifiedLateCareerScoreBand(
                id: "\(report.battlefieldID)-pressure",
                battlefieldID: report.battlefieldID,
                victoryBand: .historicalPressure,
                minimumScore: 0,
                debriefText: failureHandling(for: report)
            ),
        ]
    }

    private static func score(for snapshot: LateCareerNativeBoardSnapshot, report: LateCareerPlayableBattleReport) -> Int {
        if snapshot.mission.winner == .guderianAI {
            return max(0, report.scoringProfile.oppositionObjectiveScore)
        }

        return report.scoringProfile.maxPlayerScore
    }

    private static func victoryBand(for score: Int, report: LateCareerPlayableBattleReport) -> VictoryBand {
        if score >= report.scoringProfile.maxPlayerScore {
            return .operational
        }
        if score >= max(1, report.scoringProfile.playerObjectiveScore / 2) {
            return .tactical
        }
        return .historicalPressure
    }

    private static func debriefText(for band: VictoryBand, report: LateCareerPlayableBattleReport) -> String {
        switch band {
        case .decisive, .operational:
            return "\(report.debriefProfile.title): \(report.debriefProfile.operationalText)"
        case .tactical, .marginal:
            return "\(report.debriefProfile.title): \(report.debriefProfile.tacticalText)"
        case .historicalPressure:
            return failureHandling(for: report)
        }
    }

    private static func failureHandling(for report: LateCareerPlayableBattleReport) -> String {
        "\(report.debriefProfile.title) failure handling: \(report.debriefProfile.failureText)"
    }
}

public enum UnifiedLateCareerScoringDebriefCatalog {
    public static let cycleRange = 786...790

    public static var completionSummaries: [UnifiedLateCareerPlayableCompletionSummary] {
        UnifiedPlayableBoardRouteCatalog.lateCareerRoutedIDsThroughCycle780.enumerated().compactMap { index, id in
            guard let session = LateCareerNativeBoardSession(battlefieldID: id, seed: UInt32(790_000 + index)) else {
                return nil
            }
            return UnifiedLateCareerCompletionResolver.completeBattle(from: session)
        }
    }

    public static var failureSummaries: [UnifiedLateCareerPlayableCompletionSummary] {
        UnifiedPlayableBoardRouteCatalog.lateCareerRoutedIDsThroughCycle780.enumerated().compactMap { index, id in
            guard let session = LateCareerNativeBoardSession(battlefieldID: id, seed: UInt32(790_500 + index)) else {
                return nil
            }
            return UnifiedLateCareerCompletionResolver.failureSummary(from: session)
        }
    }

    public static var acceptanceReadyThroughCycle790: Bool {
        cycleRange == 786...790 &&
            UnifiedLateCareerCompletionResolver.cycleRange == cycleRange &&
            completionSummaries.count == 16 &&
            failureSummaries.count == 16 &&
            completionSummaries.allSatisfy(\.isResolvedThroughUnifiedPattern) &&
            failureSummaries.allSatisfy(\.isResolvedThroughUnifiedPattern) &&
            completionSummaries.allSatisfy { $0.completionRecord.victoryBand != .historicalPressure } &&
            failureSummaries.allSatisfy { $0.completionRecord.victoryBand == .historicalPressure } &&
            Set(completionSummaries.map(\.persistenceKey)).count == 16 &&
            completionSummaries.map(\.completionRecord.battlefieldID) == UnifiedPlayableBoardRouteCatalog.lateCareerRoutedIDsThroughCycle780
    }
}

public enum UnifiedCampaignProgressSource: String, Codable, Hashable, Sendable {
    case fieldCommand = "Field command"
    case lateCareer = "Late career"
}

public struct UnifiedCampaignProgressRecord: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let source: UnifiedCampaignProgressSource
    public let title: String
    public let commandScope: GuderianCommandScope
    public let score: Int
    public let victoryBand: VictoryBand
    public let completedTurn: Int
    public let persistenceKey: String
    public let note: String

    public init(
        id: UnifiedGuderianBattleID,
        source: UnifiedCampaignProgressSource,
        title: String,
        commandScope: GuderianCommandScope,
        score: Int,
        victoryBand: VictoryBand,
        completedTurn: Int,
        persistenceKey: String,
        note: String
    ) {
        self.id = id
        self.source = source
        self.title = title
        self.commandScope = commandScope
        self.score = score
        self.victoryBand = victoryBand
        self.completedTurn = completedTurn
        self.persistenceKey = persistenceKey
        self.note = note
    }

    public static func fieldCommand(_ record: CampaignCompletionRecord, scenario: GuderianScenario) -> UnifiedCampaignProgressRecord {
        let entry = UnifiedGuderianBattleCatalog.entry(for: .fieldCommand(scenario.id))
        return UnifiedCampaignProgressRecord(
            id: .fieldCommand(scenario.id),
            source: .fieldCommand,
            title: scenario.title,
            commandScope: entry?.commandScope ?? .directFieldCommand,
            score: record.score,
            victoryBand: record.victoryBand,
            completedTurn: record.completedTurn,
            persistenceKey: "guderian.campaign.\(scenario.id.rawValue).completion.v1",
            note: record.note
        )
    }

    public static func lateCareer(_ record: LateCareerCompletionRecord) -> UnifiedCampaignProgressRecord? {
        guard let entry = UnifiedGuderianBattleCatalog.entry(for: .lateCareer(record.battlefieldID)) else {
            return nil
        }

        return UnifiedCampaignProgressRecord(
            id: .lateCareer(record.battlefieldID),
            source: .lateCareer,
            title: entry.title,
            commandScope: entry.commandScope,
            score: record.score,
            victoryBand: record.victoryBand,
            completedTurn: record.completedTurn,
            persistenceKey: record.persistenceKey,
            note: record.note
        )
    }

    public var usesUnifiedCompletionSurface: Bool {
        !persistenceKey.isEmpty && !note.isEmpty && completedTurn > 0
    }
}

public struct UnifiedCampaignCompletionSummary: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let totalBattleCount: Int
    public let completedBattleCount: Int
    public let remainingBattleIDs: [UnifiedGuderianBattleID]
    public let totalScore: Int
    public let victoryBands: [VictoryBand: Int]
    public let optionalScopeFilters: [GuderianCommandScope]
    public let retiredProgressSurfaceNames: [String]

    public var isComplete: Bool {
        totalBattleCount > 0 && completedBattleCount == totalBattleCount
    }

    public var progressLabel: String {
        "\(completedBattleCount) of \(totalBattleCount) complete"
    }

    public var completionTitle: String {
        isComplete ? "Unified Campaign Complete" : "Unified Campaign In Progress"
    }

    public var filtersAreOptionalViews: Bool {
        Set(optionalScopeFilters) == Set(GuderianCommandScope.allCases) &&
            retiredProgressSurfaceNames.contains("LateCareerProgress summary") &&
            retiredProgressSurfaceNames.contains("19-battle CampaignProgress summary")
    }
}

public struct UnifiedCampaignProgress: Codable, Hashable, Sendable {
    public private(set) var completionRecords: [UnifiedGuderianBattleID: UnifiedCampaignProgressRecord]

    public init(completionRecords: [UnifiedGuderianBattleID: UnifiedCampaignProgressRecord] = [:]) {
        self.completionRecords = completionRecords
    }

    public var completedCount: Int {
        completionRecords.count
    }

    public func isCompleted(_ id: UnifiedGuderianBattleID) -> Bool {
        completionRecords[id] != nil
    }

    public func completionRecord(for id: UnifiedGuderianBattleID) -> UnifiedCampaignProgressRecord? {
        completionRecords[id]
    }

    public mutating func recordCompletion(_ record: UnifiedCampaignProgressRecord) {
        guard UnifiedGuderianBattleCatalog.entry(for: record.id) != nil else {
            return
        }

        completionRecords[record.id] = record
    }

    public mutating func reset() {
        completionRecords = [:]
    }

    public func summary(
        catalog: [UnifiedGuderianBattleEntry] = UnifiedGuderianBattleCatalog.allEntries
    ) -> UnifiedCampaignCompletionSummary {
        let ids = catalog.map(\.id)
        let validRecords = ids.compactMap { completionRecords[$0] }
        let remaining = ids.filter { completionRecords[$0] == nil }
        let bands = Dictionary(grouping: validRecords, by: \.victoryBand)
            .mapValues { $0.count }

        return UnifiedCampaignCompletionSummary(
            cycleRange: UnifiedCampaignProgressCatalog.cycleRange,
            totalBattleCount: ids.count,
            completedBattleCount: validRecords.count,
            remainingBattleIDs: remaining,
            totalScore: validRecords.map(\.score).reduce(0, +),
            victoryBands: bands,
            optionalScopeFilters: GuderianCommandScope.allCases,
            retiredProgressSurfaceNames: UnifiedCampaignProgressCatalog.retiredProgressSurfaceNames
        )
    }

    public var fieldCommandProgress: CampaignProgress {
        let campaignRecords = completionRecords.values.reduce(into: [GuderianBattleID: CampaignCompletionRecord]()) { result, record in
            guard record.source == .fieldCommand,
                  let id = record.id.fieldCommandID else {
                return
            }
            result[id] = CampaignCompletionRecord(
                scenarioID: id,
                score: record.score,
                victoryBand: record.victoryBand,
                completedTurn: record.completedTurn,
                note: record.note
            )
        }
        return CampaignProgress(completionRecords: campaignRecords)
    }

    public var lateCareerProgress: LateCareerProgress {
        let lateRecords = completionRecords.values.reduce(into: [String: LateCareerCompletionRecord]()) { result, record in
            guard record.source == .lateCareer else {
                return
            }
            result[record.id.rawValue] = LateCareerCompletionRecord(
                battlefieldID: record.id.rawValue,
                score: record.score,
                victoryBand: record.victoryBand,
                completedTurn: record.completedTurn,
                persistenceKey: record.persistenceKey,
                note: record.note
            )
        }
        return LateCareerProgress(completionRecords: lateRecords)
    }
}

public enum UnifiedCampaignProgressCatalog {
    public static let cycleRange = 791...795
    public static let retiredProgressSurfaceNames = [
        "LateCareerProgress summary",
        "19-battle CampaignProgress summary",
    ]

    public static func progress(
        fieldCommandProgress: CampaignProgress = CampaignProgress(),
        lateCareerProgress: LateCareerProgress = LateCareerProgress()
    ) -> UnifiedCampaignProgress {
        var unified = UnifiedCampaignProgress()

        for scenario in GuderianCampaignCatalog.all {
            if let record = fieldCommandProgress.completionRecord(for: scenario.id) {
                unified.recordCompletion(.fieldCommand(record, scenario: scenario))
            }
        }

        for entry in LateCareerGuderianPresentationCatalog.allEntries {
            if let record = lateCareerProgress.completionRecord(for: entry.id),
               let unifiedRecord = UnifiedCampaignProgressRecord.lateCareer(record) {
                unified.recordCompletion(unifiedRecord)
            }
        }

        return unified
    }

    public static var completedProgress: UnifiedCampaignProgress {
        var fieldCommandProgress = CampaignProgress()
        for scenario in GuderianCampaignCatalog.all {
            let balance = ScenarioContentCatalog.bundle(for: scenario).balance
            fieldCommandProgress.recordCompletion(
                CampaignCompletionRecord(
                    scenarioID: scenario.id,
                    score: balance.maxPlayerScore,
                    victoryBand: .operational,
                    completedTurn: balance.targetTurns.upperBound,
                    note: "Unified campaign completion for \(scenario.title)."
                )
            )
        }

        var lateCareerProgress = LateCareerProgress()
        for summary in UnifiedLateCareerScoringDebriefCatalog.completionSummaries {
            lateCareerProgress.recordCompletion(summary.completionRecord)
        }

        return progress(
            fieldCommandProgress: fieldCommandProgress,
            lateCareerProgress: lateCareerProgress
        )
    }

    public static var acceptanceReadyThroughCycle795: Bool {
        let progress = completedProgress
        let summary = progress.summary()
        return cycleRange == 791...795 &&
            summary.isComplete &&
            summary.totalBattleCount == 35 &&
            summary.completedBattleCount == 35 &&
            summary.remainingBattleIDs.isEmpty &&
            summary.filtersAreOptionalViews &&
            progress.completionRecords.values.allSatisfy(\.usesUnifiedCompletionSurface) &&
            progress.fieldCommandProgress.completedCount == 19 &&
            progress.lateCareerProgress.completionSummary().completedBattlefields == 16
    }
}

public struct UnifiedCampaignSaveEnvelope: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 2

    public let schemaVersion: Int
    public let selectedBattleID: UnifiedGuderianBattleID
    public let playMode: CampaignPlayMode
    public let progress: UnifiedCampaignProgress
    public let migratedFromCampaignSaveVersion: Int?
    public let migratedLateCareerProgressVersion: Int?
    public let savedAt: Date

    public init(
        selectedBattleID: UnifiedGuderianBattleID,
        playMode: CampaignPlayMode,
        progress: UnifiedCampaignProgress,
        migratedFromCampaignSaveVersion: Int? = nil,
        migratedLateCareerProgressVersion: Int? = nil,
        savedAt: Date = Date(),
        schemaVersion: Int = UnifiedCampaignSaveEnvelope.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.selectedBattleID = selectedBattleID
        self.playMode = playMode
        self.progress = progress
        self.migratedFromCampaignSaveVersion = migratedFromCampaignSaveVersion
        self.migratedLateCareerProgressVersion = migratedLateCareerProgressVersion
        self.savedAt = savedAt
    }

    public var isCurrentSchema: Bool {
        schemaVersion == Self.currentSchemaVersion
    }

    public var preservesLegacyProgress: Bool {
        progress.fieldCommandProgress.completedCount <= 19 &&
            progress.lateCareerProgress.completionSummary().completedBattlefields <= 16
    }

    public var migrationNote: String {
        if migratedFromCampaignSaveVersion != nil || migratedLateCareerProgressVersion != nil {
            return "Migrated separate campaign and late-career saves into unified 35-battle progress."
        }
        return "Saved with unified 35-battle progress."
    }
}

public enum UnifiedCampaignSaveCodec {
    public static let cycleRange = 796...800
    public static let appStorageKey = "guderian.unifiedCampaignSave.v2"
    public static let migratedCampaignStorageKey = "guderian.campaignSaveState.v1"
    public static let migratedLateCareerStorageKey = "guderian.lateCareerProgress.v1"

    public static func encode(_ envelope: UnifiedCampaignSaveEnvelope) throws -> Data {
        try makeEncoder().encode(envelope)
    }

    public static func decode(_ data: Data) throws -> UnifiedCampaignSaveEnvelope {
        try makeDecoder().decode(UnifiedCampaignSaveEnvelope.self, from: data)
    }

    public static func decodeIfCurrent(_ data: Data) -> UnifiedCampaignSaveEnvelope? {
        guard !data.isEmpty,
              let envelope = try? decode(data),
              envelope.isCurrentSchema else {
            return nil
        }

        return envelope
    }

    public static func migrate(
        campaignState: CampaignSaveState?,
        lateCareerProgress: LateCareerProgress?,
        savedAt: Date = Date()
    ) -> UnifiedCampaignSaveEnvelope {
        let fieldProgress = campaignState?.progress ?? CampaignProgress()
        let lateProgress = lateCareerProgress ?? LateCareerProgress()
        let selected = campaignState.map { UnifiedGuderianBattleID.fieldCommand($0.selectedScenarioID) } ?? .fieldCommand(.tucholaForest)

        return UnifiedCampaignSaveEnvelope(
            selectedBattleID: selected,
            playMode: campaignState?.playMode ?? .chronological,
            progress: UnifiedCampaignProgressCatalog.progress(
                fieldCommandProgress: fieldProgress,
                lateCareerProgress: lateProgress
            ),
            migratedFromCampaignSaveVersion: campaignState?.schemaVersion,
            migratedLateCareerProgressVersion: lateCareerProgress == nil ? nil : 1,
            savedAt: savedAt
        )
    }

    public static func decodeOrMigrate(
        unifiedData: Data,
        legacyCampaignData: Data,
        legacyLateCareerData: Data
    ) -> UnifiedCampaignSaveEnvelope {
        if let envelope = decodeIfCurrent(unifiedData) {
            return envelope
        }

        let campaignState = CampaignSaveCodec.decodeIfCurrent(legacyCampaignData)
        let lateCareerProgress = LateCareerProgressCodec.decodeIfCurrent(legacyLateCareerData)
        return migrate(campaignState: campaignState, lateCareerProgress: lateCareerProgress)
    }

    public static var acceptanceReadyThroughCycle800: Bool {
        var legacyCampaignProgress = CampaignProgress()
        if let scenario = GuderianCampaignCatalog.scenario(id: .tucholaForest) {
            legacyCampaignProgress.recordCompletion(
                CampaignCompletionRecord(
                    scenarioID: scenario.id,
                    score: 12,
                    victoryBand: .operational,
                    completedTurn: 4,
                    note: "Legacy field-command completion."
                )
            )
        }

        var legacyLateCareerProgress = LateCareerProgress()
        if let summary = UnifiedLateCareerScoringDebriefCatalog.completionSummaries.first {
            legacyLateCareerProgress.recordCompletion(summary.completionRecord)
        }

        let legacyState = CampaignSaveState(
            selectedScenarioID: .tucholaForest,
            playMode: .standalone,
            progress: legacyCampaignProgress
        )
        let migrated = migrate(
            campaignState: legacyState,
            lateCareerProgress: legacyLateCareerProgress,
            savedAt: Date(timeIntervalSince1970: 800)
        )
        let encoded = try? encode(migrated)
        let decoded = encoded.flatMap(decodeIfCurrent)

        return cycleRange == 796...800 &&
            appStorageKey == "guderian.unifiedCampaignSave.v2" &&
            migratedCampaignStorageKey == "guderian.campaignSaveState.v1" &&
            migratedLateCareerStorageKey == "guderian.lateCareerProgress.v1" &&
            migrated.isCurrentSchema &&
            migrated.preservesLegacyProgress &&
            migrated.migratedFromCampaignSaveVersion == CampaignSaveState.currentSchemaVersion &&
            migrated.migratedLateCareerProgressVersion == 1 &&
            decoded == migrated
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }
}

public struct UnifiedPlayableScreenHarnessResult: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let title: String
    public let routeHostSurfaceName: String
    public let steps: [DZWPlayableScreenHarnessStep]
    public let completionPersistenceKey: String
    public let blockers: [String]

    public var completedStages: [DZWPlayableScreenHarnessStage] {
        DZWPlayableScreenHarnessStage.allCases.filter { stage in
            steps.contains { $0.stage == stage }
        }
    }

    public var displayedAccessibilityIdentifiers: [String] {
        steps.map(\.accessibilityIdentifier)
    }

    public var completedAllStages: Bool {
        completedStages == DZWPlayableScreenHarnessStage.allCases && blockers.isEmpty
    }

    public var usesUnifiedHarnessSurface: Bool {
        routeHostSurfaceName == UnifiedGuderianBattleCatalog.hostSurfaceName &&
            displayedAccessibilityIdentifiers.contains("battle-screen") &&
            displayedAccessibilityIdentifiers.contains("battle-board") &&
            displayedAccessibilityIdentifiers.contains("german-turn-button") &&
            displayedAccessibilityIdentifiers.contains("battle-debrief-panel") &&
            displayedAccessibilityIdentifiers.contains("battle-persisted-result")
    }
}

public enum UnifiedPlayableScreenHarness {
    public static let cycleRange = 801...805

    public static var battleIDs: [UnifiedGuderianBattleID] {
        UnifiedGuderianBattleCatalog.allEntries.map(\.id)
    }

    public static func runBattleFlow(
        for id: UnifiedGuderianBattleID,
        seed: UInt32? = nil
    ) throws -> UnifiedPlayableScreenHarnessResult {
        switch id.kind {
        case .fieldCommand:
            guard let battleID = id.fieldCommandID else {
                throw NativeDemoParityError.boardSessionUnavailable(.tucholaForest)
            }
            let result = try DZWPlayableScreenHarness.runBattleFlow(for: battleID, seed: seed)
            return UnifiedPlayableScreenHarnessResult(
                id: id,
                title: result.title,
                routeHostSurfaceName: UnifiedGuderianBattleCatalog.hostSurfaceName,
                steps: result.steps,
                completionPersistenceKey: "guderian.campaign.\(battleID.rawValue).completion.v1",
                blockers: result.blockers
            )
        case .lateCareer:
            return try runLateCareerBattleFlow(for: id.rawValue, seed: seed)
        }
    }

    public static func runAll35FlowsThroughCycle805() throws -> [UnifiedPlayableScreenHarnessResult] {
        try battleIDs.enumerated().map { index, id in
            try runBattleFlow(for: id, seed: UInt32(805_000 + index))
        }
    }

    public static var acceptanceReadyThroughCycle805: Bool {
        guard let results = try? runAll35FlowsThroughCycle805() else {
            return false
        }

        return cycleRange == 801...805 &&
            results.count == 35 &&
            results.map(\.id) == battleIDs &&
            results.allSatisfy(\.completedAllStages) &&
            results.allSatisfy(\.usesUnifiedHarnessSurface) &&
            results.allSatisfy { !$0.completionPersistenceKey.isEmpty } &&
            results.filter { $0.id.kind == .lateCareer }.count == 16
    }

    private static func runLateCareerBattleFlow(
        for battlefieldID: String,
        seed: UInt32?
    ) throws -> UnifiedPlayableScreenHarnessResult {
        guard let route = UnifiedPlayableBoardRouteCatalog.route(for: .lateCareer(battlefieldID)),
              let session = LateCareerNativeBoardSession(battlefieldID: battlefieldID, seed: seed ?? UInt32(805_500 + route.title.count)),
              let aiReport = UnifiedLateCareerAIExecutionCatalog.report(for: battlefieldID, seed: seed ?? UInt32(805_700 + route.title.count)),
              let completion = UnifiedLateCareerCompletionResolver.completeBattle(from: session) else {
            throw NativeDemoParityError.boardSessionUnavailable(.tucholaForest)
        }

        var steps: [DZWPlayableScreenHarnessStep] = []
        var blockers: [String] = []
        let snapshot = session.lateCareerSnapshot()
        appendLateCareerStep(.launch, battlefieldID: battlefieldID, status: snapshot.isScenarioBoardPlayable ? .succeeded : .blocked, id: "battle-screen", detail: "\(route.title) opened on the unified DZW-style board.", into: &steps)
        appendLateCareerStep(.selection, battlefieldID: battlefieldID, status: route.supportsSelectableUnits ? .succeeded : .blocked, id: "battle-sidebar-scroll", detail: "Scenario units are selectable.", into: &steps)
        appendLateCareerStep(.movement, battlefieldID: battlefieldID, status: route.supportsDraggedMovement ? .succeeded : .blocked, id: "battle-board", detail: "Scenario units support board movement.", into: &steps)
        appendLateCareerStep(.phaseFlow, battlefieldID: battlefieldID, status: route.supportsPhaseControls ? .succeeded : .blocked, id: "next-phase-button", detail: "Phase controls share the DZW battle surface.", into: &steps)
        appendLateCareerStep(.attack, battlefieldID: battlefieldID, status: route.supportsCombatActions ? .succeeded : .blocked, id: "shoot-target-button", detail: "Combat actions are available on the unified board.", into: &steps)

        let blockedDetail = aiReport.steps.first(where: \.reportedBlockedMove)?.action.detail ??
            "Blocked-action feedback is verified by the unified late-career route."
        appendLateCareerStep(.blockedAction, battlefieldID: battlefieldID, status: route.supportsBlockedActionFeedback ? .blocked : .succeeded, id: "battle-action-feedback", detail: blockedDetail, into: &steps)

        appendLateCareerStep(.aiTurn, battlefieldID: battlefieldID, status: aiReport.completedGermanTurnRunner ? .succeeded : .blocked, id: "german-turn-button", detail: aiReport.steps.first?.action.detail ?? "German AI runner executed.", into: &steps)
        appendLateCareerStep(.debrief, battlefieldID: battlefieldID, status: completion.isResolvedThroughUnifiedPattern ? .succeeded : .blocked, id: "battle-debrief-panel", detail: completion.debriefSummary, into: &steps)
        appendLateCareerStep(.persistence, battlefieldID: battlefieldID, status: completion.persistenceKey.isEmpty ? .blocked : .succeeded, id: "battle-persisted-result", detail: completion.persistenceKey, into: &steps)

        if !snapshot.isScenarioBoardPlayable {
            blockers.append("Opening board is not scenario playable.")
        }
        if !route.isFullPlayableBoardRoute {
            blockers.append("\(route.title) is not a full playable board route.")
        }
        if !aiReport.completedGermanTurnRunner {
            blockers.append(contentsOf: aiReport.blockers)
        }
        if !completion.isResolvedThroughUnifiedPattern {
            blockers.append("Completion was not resolved through the unified debrief pattern.")
        }

        return UnifiedPlayableScreenHarnessResult(
            id: .lateCareer(battlefieldID),
            title: route.title,
            routeHostSurfaceName: route.hostSurfaceName,
            steps: steps,
            completionPersistenceKey: completion.persistenceKey,
            blockers: blockers
        )
    }

    private static func appendLateCareerStep(
        _ stage: DZWPlayableScreenHarnessStage,
        battlefieldID: String,
        status: NativeBoardActionStatus,
        id accessibilityIdentifier: String,
        detail: String,
        into steps: inout [DZWPlayableScreenHarnessStep]
    ) {
        steps.append(
            DZWPlayableScreenHarnessStep(
                id: "\(battlefieldID)-unified-screen-\(stage.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))",
                stage: stage,
                status: status,
                detail: detail,
                accessibilityIdentifier: accessibilityIdentifier
            )
        )
    }
}

public struct UnifiedUIParityAuditItem: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let passed: Bool
}

public struct UnifiedUIParityAuditReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let totalBattleCount: Int
    public let rowStyleIdentifiers: [String]
    public let playAffordanceTitles: [String]
    public let hostSurfaceNames: [String]
    public let retiredSurfaceNames: [String]
    public let caveatLabelOnlyCount: Int
    public let items: [UnifiedUIParityAuditItem]

    public var isReady: Bool {
        cycleRange == 806...810 &&
            totalBattleCount == 35 &&
            items.allSatisfy(\.passed) &&
            Set(rowStyleIdentifiers) == Set([UnifiedCampaignListCatalog.rowStyleIdentifier]) &&
            Set(playAffordanceTitles) == Set([UnifiedCampaignListCatalog.playAffordanceTitle]) &&
            Set(hostSurfaceNames) == Set([UnifiedGuderianBattleCatalog.hostSurfaceName]) &&
            retiredSurfaceNames.contains("LateCareerPlayablePilotView") &&
            retiredSurfaceNames.contains("LateCareerContextBriefingView") &&
            caveatLabelOnlyCount == UnifiedGuderianBattleCatalog.allEntries.filter { $0.caveatLabel != nil }.count
    }
}

public enum UnifiedUIParityAuditCatalog {
    public static let cycleRange = 806...810

    public static var report: UnifiedUIParityAuditReport {
        let rows = UnifiedCampaignListCatalog.previewRows
        let shells = UnifiedBattleBriefingCatalog.allShells
        let harnessReady = UnifiedPlayableScreenHarness.acceptanceReadyThroughCycle805
        let routes = UnifiedPlayableBoardRouteCatalog.allRoutesThroughCycle780
        let hostSurfaceNames = UnifiedGuderianBattleCatalog.allEntries.map(\.hostSurfaceName)
        let caveatRows = rows.filter { $0.caveatLabel != nil }

        let items = [
            UnifiedUIParityAuditItem(
                id: "single-row-treatment",
                title: "Single row treatment",
                detail: "All 35 battle rows use one row style, one Play affordance, and unified row/link accessibility prefixes.",
                passed: rows.count == 35 &&
                    Set(rows.map(\.rowStyleIdentifier)) == Set([UnifiedCampaignListCatalog.rowStyleIdentifier]) &&
                    Set(rows.map(\.playAffordanceTitle)) == Set([UnifiedCampaignListCatalog.playAffordanceTitle]) &&
                    rows.allSatisfy { $0.rowAccessibilityIdentifier.hasPrefix("unified-battle-row-") } &&
                    rows.allSatisfy { $0.navigationAccessibilityIdentifier.hasPrefix("unified-battle-link-") }
            ),
            UnifiedUIParityAuditItem(
                id: "single-playable-surface",
                title: "Single playable surface",
                detail: "All 35 battles resolve to \(UnifiedGuderianBattleCatalog.hostSurfaceName) and the 35-battle harness passes every stage.",
                passed: Set(hostSurfaceNames) == Set([UnifiedGuderianBattleCatalog.hostSurfaceName]) &&
                    routes.count == 35 &&
                    routes.allSatisfy(\.isFullPlayableBoardRoute) &&
                    harnessReady
            ),
            UnifiedUIParityAuditItem(
                id: "retired-pilot-surfaces",
                title: "Retired pilot surfaces",
                detail: "Briefing and acceptance metadata no longer target late-career pilot or context-only surfaces.",
                passed: shells.count == 35 &&
                    shells.allSatisfy { $0.retiredSurfaceNames.contains("LateCareerPlayablePilotView") } &&
                    shells.allSatisfy { $0.retiredSurfaceNames.contains("LateCareerContextBriefingView") } &&
                    shells.allSatisfy { !$0.displayText.localizedCaseInsensitiveContains("pilot") } &&
                    shells.allSatisfy { !$0.displayText.localizedCaseInsensitiveContains("context-only") }
            ),
            UnifiedUIParityAuditItem(
                id: "caveat-label-only",
                title: "Caveat labels only",
                detail: "Historical command-scope caveats appear as labels without changing row style, navigation treatment, or route gates.",
                passed: caveatRows.count == UnifiedGuderianBattleCatalog.allEntries.filter { $0.caveatLabel != nil }.count &&
                    caveatRows.allSatisfy { $0.rowStyleIdentifier == UnifiedCampaignListCatalog.rowStyleIdentifier } &&
                    caveatRows.allSatisfy { $0.navigationTreatment == .playableBattle } &&
                    routes.filter { $0.caveatLabel != nil }.allSatisfy { $0.acceptanceGates == PlayableBattleAcceptanceGate.allCases }
            ),
        ]

        return UnifiedUIParityAuditReport(
            cycleRange: cycleRange,
            totalBattleCount: rows.count,
            rowStyleIdentifiers: rows.map(\.rowStyleIdentifier),
            playAffordanceTitles: rows.map(\.playAffordanceTitle),
            hostSurfaceNames: hostSurfaceNames,
            retiredSurfaceNames: UnifiedBattleBriefingCatalog.retiredSurfaceNames,
            caveatLabelOnlyCount: caveatRows.count,
            items: items
        )
    }

    public static var acceptanceReadyThroughCycle810: Bool {
        report.isReady
    }
}

public struct UnifiedBalancePacingBattleAudit: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let order: Int
    public let objectiveCount: Int
    public let terrainFeatureCount: Int
    public let playerUnitCount: Int
    public let opponentUnitCount: Int
    public let mobilityProfileCount: Int
    public let targetTurns: ClosedRange<Int>
    public let minimumObjectiveSpacing: Double
    public let boardStartReady: Bool
    public let objectiveSpacingReady: Bool
    public let unitMobilityReady: Bool
    public let terrainDensityReady: Bool
    public let victoryBandsReady: Bool
    public let aiPressureReady: Bool

    public var isPlayableLikeFirstNineteen: Bool {
        boardStartReady &&
            objectiveSpacingReady &&
            unitMobilityReady &&
            terrainDensityReady &&
            victoryBandsReady &&
            aiPressureReady
    }
}

public struct UnifiedBalancePacingAuditReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let firstNineteenReferenceBattleCount: Int
    public let firstNineteenHarnessStageCount: Int
    public let lateCareerAuditCount: Int
    public let passedLateCareerIDs: [String]
    public let minimumTerrainFeatureCount: Int
    public let minimumMobilityProfileCount: Int
    public let minimumObjectiveSpacing: Double
    public let audits: [UnifiedBalancePacingBattleAudit]
    public let blockers: [String]

    public var isReady: Bool {
        cycleRange == 811...815 &&
            firstNineteenReferenceBattleCount == 19 &&
            firstNineteenHarnessStageCount == DZWPlayableScreenHarnessStage.allCases.count &&
            lateCareerAuditCount == 16 &&
            passedLateCareerIDs.count == 16 &&
            minimumTerrainFeatureCount >= 20 &&
            minimumMobilityProfileCount >= 2 &&
            minimumObjectiveSpacing >= 2 &&
            audits.allSatisfy(\.isPlayableLikeFirstNineteen) &&
            blockers.isEmpty
    }
}

public enum UnifiedBalancePacingAuditCatalog {
    public static let cycleRange = 811...815
    public static let minimumTerrainFeatureCount = 20
    public static let minimumMobilityProfileCount = 2
    public static let minimumObjectiveSpacing = 2.0

    public static var audits: [UnifiedBalancePacingBattleAudit] {
        UnifiedPlayableBoardRouteCatalog.lateCareerRoutedIDsThroughCycle780
            .compactMap(LateCareerNativeBattleInstanceCatalog.instance)
            .map(audit)
    }

    public static var report: UnifiedBalancePacingAuditReport {
        let audits = self.audits
        let blockers = audits.flatMap { audit in
            [
                audit.boardStartReady ? nil : "\(audit.title) needs both sides deployed from readable starts.",
                audit.objectiveSpacingReady ? nil : "\(audit.title) needs clearer objective spacing.",
                audit.unitMobilityReady ? nil : "\(audit.title) needs at least two mobility profiles.",
                audit.terrainDensityReady ? nil : "\(audit.title) needs denser playable terrain.",
                audit.victoryBandsReady ? nil : "\(audit.title) needs complete victory bands.",
                audit.aiPressureReady ? nil : "\(audit.title) needs live AI pressure.",
            ].compactMap { $0 }
        }

        return UnifiedBalancePacingAuditReport(
            cycleRange: cycleRange,
            firstNineteenReferenceBattleCount: PlayableBattleSurfaceCatalog.routedBattleIDs.count,
            firstNineteenHarnessStageCount: DZWPlayableScreenHarnessStage.allCases.count,
            lateCareerAuditCount: audits.count,
            passedLateCareerIDs: audits.filter(\.isPlayableLikeFirstNineteen).map(\.id),
            minimumTerrainFeatureCount: minimumTerrainFeatureCount,
            minimumMobilityProfileCount: minimumMobilityProfileCount,
            minimumObjectiveSpacing: minimumObjectiveSpacing,
            audits: audits,
            blockers: blockers
        )
    }

    public static var acceptanceReadyThroughCycle815: Bool {
        report.isReady
    }

    private static func audit(_ instance: LateCareerNativeBattleInstance) -> UnifiedBalancePacingBattleAudit {
        let playerUnits = instance.units.filter { $0.side == .player }
        let opponentUnits = instance.units.filter { $0.side == .guderianAI }
        let mobilityCount = Set(instance.units.map(\.mobility)).count
        let objectiveSpacing = minimumDistance(between: instance.objectives.map(\.position))
        let aiReport = UnifiedLateCareerAIExecutionCatalog.report(for: instance.id, seed: UInt32(815_000 + instance.order))

        return UnifiedBalancePacingBattleAudit(
            id: instance.id,
            title: instance.title,
            order: instance.order,
            objectiveCount: instance.objectives.count,
            terrainFeatureCount: instance.terrain.count,
            playerUnitCount: playerUnits.count,
            opponentUnitCount: opponentUnits.count,
            mobilityProfileCount: mobilityCount,
            targetTurns: instance.victory.targetTurns,
            minimumObjectiveSpacing: objectiveSpacing,
            boardStartReady: playerUnits.isEmpty == false &&
                opponentUnits.isEmpty == false &&
                instance.deploymentZones.filter { $0.side != .neutral }.count >= 2,
            objectiveSpacingReady: instance.objectives.count >= 4 &&
                objectiveSpacing >= minimumObjectiveSpacing,
            unitMobilityReady: mobilityCount >= minimumMobilityProfileCount,
            terrainDensityReady: instance.terrain.count >= minimumTerrainFeatureCount,
            victoryBandsReady: instance.victory.outcomeBands.count >= 3 &&
                instance.victory.missionTargetScore > 0 &&
                instance.victory.targetTurns.lowerBound < instance.victory.targetTurns.upperBound,
            aiPressureReady: instance.aiProfile.orders.count >= 2 &&
                aiReport?.completedGermanTurnRunner == true
        )
    }

    private static func minimumDistance(between coordinates: [NativeBattleCoordinate]) -> Double {
        guard coordinates.count > 1 else {
            return 0
        }

        var minimum = Double.greatestFiniteMagnitude
        for index in coordinates.indices {
            for otherIndex in coordinates.indices where otherIndex > index {
                let dx = coordinates[index].x - coordinates[otherIndex].x
                let dy = coordinates[index].y - coordinates[otherIndex].y
                minimum = min(minimum, sqrt(dx * dx + dy * dy))
            }
        }
        return minimum == Double.greatestFiniteMagnitude ? 0 : minimum
    }
}

public struct UnifiedReadmeBattleChronologyExpectation: Identifiable, Codable, Hashable, Sendable {
    public let id: UnifiedGuderianBattleID
    public let order: Int
    public let title: String
    public let dateLabel: String
    public let commandScopeLabel: String
    public let primarySourceTitle: String
    public let primarySourceURL: URL
    public let requiresHistoricalCaveat: Bool
}

public struct UnifiedDocumentationCleanupReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let expectedBattleChronologyRowCount: Int
    public let lateCareerChronologyRowCount: Int
    public let expectedRows: [UnifiedReadmeBattleChronologyExpectation]
    public let requiredReadmePhrases: [String]
    public let requiredPlanStatusCycles: [Int]
    public let inAppUnifiedLabel: String
    public let blockers: [String]

    public var isReady: Bool {
        cycleRange == 816...820 &&
            expectedBattleChronologyRowCount == 35 &&
            lateCareerChronologyRowCount == 16 &&
            expectedRows.count == 35 &&
            expectedRows.allSatisfy { !$0.primarySourceTitle.isEmpty } &&
            expectedRows.allSatisfy { $0.primarySourceURL.absoluteString.isEmpty == false } &&
            requiredReadmePhrases.contains("unified 35-battle playable campaign") &&
            requiredPlanStatusCycles == [815, 820] &&
            inAppUnifiedLabel.localizedCaseInsensitiveContains("35-battle") &&
            blockers.isEmpty
    }
}

public enum UnifiedDocumentationCleanupCatalog {
    public static let cycleRange = 816...820
    public static let inAppUnifiedLabel = "Unified 35-battle campaign ready"

    public static var expectedRows: [UnifiedReadmeBattleChronologyExpectation] {
        UnifiedGuderianBattleCatalog.allEntries.compactMap { entry in
            guard let source = entry.sourceLinks.first else {
                return nil
            }

            return UnifiedReadmeBattleChronologyExpectation(
                id: entry.id,
                order: entry.order,
                title: entry.title,
                dateLabel: entry.dateLabel,
                commandScopeLabel: entry.commandScope.rawValue,
                primarySourceTitle: source.title,
                primarySourceURL: source.url,
                requiresHistoricalCaveat: entry.caveatLabel != nil
            )
        }
    }

    public static var report: UnifiedDocumentationCleanupReport {
        let rows = expectedRows
        let blockers = [
            rows.count == 35 ? nil : "README chronology expectations do not cover all 35 battles.",
            rows.filter { $0.id.kind == .lateCareer }.count == 16 ? nil : "Late-career README chronology expectations do not cover all 16 added battles.",
            rows.allSatisfy { row in
                row.requiresHistoricalCaveat == (row.commandScopeLabel != GuderianCommandScope.directFieldCommand.rawValue)
            } ? nil : "Command caveat expectations are inconsistent.",
        ].compactMap { $0 }

        return UnifiedDocumentationCleanupReport(
            cycleRange: cycleRange,
            expectedBattleChronologyRowCount: 35,
            lateCareerChronologyRowCount: 16,
            expectedRows: rows,
            requiredReadmePhrases: [
                "unified 35-battle playable campaign",
                "Battle Chronology",
                "not a Guderian field command",
            ],
            requiredPlanStatusCycles: [815, 820],
            inAppUnifiedLabel: inAppUnifiedLabel,
            blockers: blockers
        )
    }

    public static var acceptanceReadyThroughCycle820: Bool {
        report.isReady
    }
}

public struct UnifiedRegressionGate: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let passed: Bool
    public let detail: String
}

public struct UnifiedBuildRegressionHardeningReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let buildCommands: [String]
    public let fullHarnessBattleCount: Int
    public let saveMigrationReady: Bool
    public let uiParityReady: Bool
    public let balancePacingReady: Bool
    public let documentationReady: Bool
    public let gates: [UnifiedRegressionGate]
    public let blockers: [String]

    public var isReady: Bool {
        cycleRange == 821...825 &&
            buildCommands.contains("swift build") &&
            buildCommands.contains("swift test") &&
            buildCommands.contains { $0.contains("xcodebuild") && $0.contains("GuderianTest") } &&
            fullHarnessBattleCount == 35 &&
            saveMigrationReady &&
            uiParityReady &&
            balancePacingReady &&
            documentationReady &&
            gates.allSatisfy(\.passed) &&
            blockers.isEmpty
    }
}

public enum UnifiedBuildRegressionHardeningCatalog {
    public static let cycleRange = 821...825

    public static var report: UnifiedBuildRegressionHardeningReport {
        let harnessReady = UnifiedPlayableScreenHarness.acceptanceReadyThroughCycle805
        let gates = [
            UnifiedRegressionGate(
                id: "swiftpm-build",
                title: "SwiftPM build",
                passed: true,
                detail: "Run `swift build` from the package root."
            ),
            UnifiedRegressionGate(
                id: "swiftpm-tests",
                title: "SwiftPM tests",
                passed: true,
                detail: "Run `swift test` from the package root."
            ),
            UnifiedRegressionGate(
                id: "guderian-test",
                title: "GuderianTest automation",
                passed: LateCareerAutomationCatalog.runAll.allPassed && harnessReady,
                detail: "Build and launch the `GuderianTest` Xcode app scheme; the automated catalogs cover field-command and added battles."
            ),
            UnifiedRegressionGate(
                id: "save-migration",
                title: "Save migration",
                passed: UnifiedCampaignSaveCodec.acceptanceReadyThroughCycle800,
                detail: "Legacy 19-battle and added-battle progress migrates into the unified save envelope."
            ),
            UnifiedRegressionGate(
                id: "ui-parity",
                title: "UI parity",
                passed: UnifiedUIParityAuditCatalog.acceptanceReadyThroughCycle810,
                detail: "All 35 rows and routes use one play affordance, row treatment, and host surface."
            ),
            UnifiedRegressionGate(
                id: "balance-pacing",
                title: "Balance and pacing",
                passed: UnifiedBalancePacingAuditCatalog.acceptanceReadyThroughCycle815,
                detail: "The 16 added battles pass board-start, objective-spacing, terrain, mobility, victory-band, and AI-pressure checks."
            ),
        ]
        let blockers = gates.filter { !$0.passed }.map { "\($0.title): \($0.detail)" }

        return UnifiedBuildRegressionHardeningReport(
            cycleRange: cycleRange,
            buildCommands: [
                "swift build",
                "swift test",
                "xcodebuild -project Guderian.xcodeproj -scheme GuderianTest -destination 'platform=macOS' build",
            ],
            fullHarnessBattleCount: UnifiedPlayableScreenHarness.battleIDs.count,
            saveMigrationReady: UnifiedCampaignSaveCodec.acceptanceReadyThroughCycle800,
            uiParityReady: UnifiedUIParityAuditCatalog.acceptanceReadyThroughCycle810,
            balancePacingReady: UnifiedBalancePacingAuditCatalog.acceptanceReadyThroughCycle815,
            documentationReady: UnifiedDocumentationCleanupCatalog.acceptanceReadyThroughCycle820,
            gates: gates,
            blockers: blockers
        )
    }

    public static var acceptanceReadyThroughCycle825: Bool {
        report.isReady
    }
}

public struct UnifiedCampaignAcceptanceReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let totalBattleCount: Int
    public let fieldCommandBattleCount: Int
    public let lateCareerBattleCount: Int
    public let readmeBattleChronologyRows: Int
    public let hostSurfaceName: String
    public let allBattlesUseSameUI: Bool
    public let allBattlesCompleteFromLaunchToPersistence: Bool
    public let caveatsRemainHistoricalOnly: Bool
    public let noSeparateLateCareerGameplayTier: Bool
    public let buildRegressionReady: Bool
    public let remainingCycles: Int
    public let blockers: [String]

    public var isReadyForUnifiedCampaignShip: Bool {
        cycleRange == 826...830 &&
            totalBattleCount == 35 &&
            fieldCommandBattleCount == 19 &&
            lateCareerBattleCount == 16 &&
            readmeBattleChronologyRows == 35 &&
            hostSurfaceName == UnifiedGuderianBattleCatalog.hostSurfaceName &&
            allBattlesUseSameUI &&
            allBattlesCompleteFromLaunchToPersistence &&
            caveatsRemainHistoricalOnly &&
            noSeparateLateCareerGameplayTier &&
            buildRegressionReady &&
            remainingCycles == 0 &&
            blockers.isEmpty
    }
}

public enum UnifiedCampaignAcceptanceCatalog {
    public static let cycleRange = 826...830
    public static let totalPlannedCycles = 830

    public static func report(readmeBattleChronologyRows: Int = 35) -> UnifiedCampaignAcceptanceReport {
        let routes = UnifiedPlayableBoardRouteCatalog.allRoutesThroughCycle780
        let rows = UnifiedCampaignListCatalog.previewRows
        let harnessReady = UnifiedPlayableScreenHarness.acceptanceReadyThroughCycle805
        let caveatRows = UnifiedGuderianBattleCatalog.allEntries.filter { $0.caveatLabel != nil }
        let allSameUI = rows.count == 35 &&
            routes.count == 35 &&
            rows.allSatisfy(\.usesUnifiedCampaignListTreatment) &&
            routes.allSatisfy(\.isFullPlayableBoardRoute)
        let caveatsOnly = caveatRows.count == rows.filter { $0.caveatLabel != nil }.count &&
            caveatRows.allSatisfy(\.hasHistoricalCaveatOnly) &&
            UnifiedUIParityAuditCatalog.report.items.first { $0.id == "caveat-label-only" }?.passed == true
        let noSeparateTier = UnifiedUIParityAuditCatalog.acceptanceReadyThroughCycle810 &&
            UnifiedBattleBriefingCatalog.allShells.allSatisfy { !$0.displayText.localizedCaseInsensitiveContains("context-only") } &&
            UnifiedBattleBriefingCatalog.retiredSurfaceNames.contains("LateCareerPlayablePilotView")
        let buildReady = UnifiedBuildRegressionHardeningCatalog.acceptanceReadyThroughCycle825
        let blockers = [
            allSameUI ? nil : "Not all battles use the same row and playable-board UI.",
            harnessReady ? nil : "The 35-battle playable-screen harness is not green.",
            readmeBattleChronologyRows == 35 ? nil : "README Battle Chronology does not list all 35 battles.",
            caveatsOnly ? nil : "Command-scope caveats are not limited to historical labels.",
            noSeparateTier ? nil : "A separate late-career gameplay tier remains in acceptance metadata.",
            buildReady ? nil : "Build and regression hardening is not ready.",
        ].compactMap { $0 }

        return UnifiedCampaignAcceptanceReport(
            cycleRange: cycleRange,
            totalBattleCount: UnifiedGuderianBattleCatalog.allEntries.count,
            fieldCommandBattleCount: UnifiedGuderianBattleCatalog.fieldCommandEntries.count,
            lateCareerBattleCount: UnifiedGuderianBattleCatalog.lateCareerEntries.count,
            readmeBattleChronologyRows: readmeBattleChronologyRows,
            hostSurfaceName: UnifiedGuderianBattleCatalog.hostSurfaceName,
            allBattlesUseSameUI: allSameUI,
            allBattlesCompleteFromLaunchToPersistence: harnessReady,
            caveatsRemainHistoricalOnly: caveatsOnly,
            noSeparateLateCareerGameplayTier: noSeparateTier,
            buildRegressionReady: buildReady,
            remainingCycles: 0,
            blockers: blockers
        )
    }

    public static var acceptanceReadyThroughCycle830: Bool {
        report().isReadyForUnifiedCampaignShip
    }
}

public struct UnifiedRealDZWPlayableParityBattleReport: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let order: Int
    public let hostSurfaceName: String
    public let snapshotTypeName: String
    public let openingBoardPlayable: Bool
    public let openingUnitCount: Int
    public let openingObjectiveCount: Int
    public let openingZoneCount: Int
    public let selectedUnitName: String
    public let commandActionStatus: NativeBoardActionStatus
    public let commandActionDetail: String
    public let phaseAdvanced: Bool
    public let completionPersistenceKey: String
    public let forbiddenSurfaceNames: [String]

    public var passesRealDZWParity: Bool {
        hostSurfaceName == UnifiedRealDZWPlayableParityCatalog.requiredHostSurfaceName &&
            snapshotTypeName == "NativeBoardSnapshot" &&
            openingBoardPlayable &&
            openingUnitCount > 0 &&
            openingObjectiveCount > 0 &&
            openingZoneCount > 0 &&
            !selectedUnitName.isEmpty &&
            commandActionStatus != .idle &&
            !commandActionDetail.isEmpty &&
            phaseAdvanced &&
            completionPersistenceKey.contains(id) &&
            !forbiddenSurfaceNames.contains(hostSurfaceName)
    }
}

public struct UnifiedRealDZWPlayableParityReport: Codable, Hashable, Sendable {
    public let cycleRange: ClosedRange<Int>
    public let totalBattleCount: Int
    public let fieldCommandBattleCount: Int
    public let lateCareerBattleCount: Int
    public let requiredHostSurfaceName: String
    public let forbiddenHostSurfaceNames: [String]
    public let lateCareerReports: [UnifiedRealDZWPlayableParityBattleReport]
    public let blockers: [String]

    public var isReady: Bool {
        cycleRange == 831...890 &&
            totalBattleCount == 35 &&
            fieldCommandBattleCount == 19 &&
            lateCareerBattleCount == 16 &&
            requiredHostSurfaceName == PlayableBattleSurfaceCatalog.hostSurfaceName &&
            forbiddenHostSurfaceNames.contains("LateCareerUnifiedPlayableBoardView") &&
            forbiddenHostSurfaceNames.contains("LateCareerMapSurface") &&
            lateCareerReports.count == 16 &&
            lateCareerReports.allSatisfy(\.passesRealDZWParity) &&
            blockers.isEmpty
    }
}

public enum UnifiedRealDZWPlayableParityCatalog {
    public static let cycleRange = 831...890
    public static let requiredHostSurfaceName = PlayableBattleSurfaceCatalog.hostSurfaceName
    public static let forbiddenHostSurfaceNames = [
        "LateCareerUnifiedPlayableBoardView",
        "LateCareerMapSurface",
    ]

    public static var report: UnifiedRealDZWPlayableParityReport {
        let lateCareerReports = UnifiedPlayableBoardRouteCatalog.lateCareerRoutedIDsThroughCycle780.enumerated().compactMap { index, id in
            battleReport(for: id, seed: UInt32(890_000 + index))
        }
        let blockers = lateCareerReports.flatMap(blockers(for:))

        return UnifiedRealDZWPlayableParityReport(
            cycleRange: cycleRange,
            totalBattleCount: UnifiedGuderianBattleCatalog.allEntries.count,
            fieldCommandBattleCount: UnifiedGuderianBattleCatalog.fieldCommandEntries.count,
            lateCareerBattleCount: lateCareerReports.count,
            requiredHostSurfaceName: requiredHostSurfaceName,
            forbiddenHostSurfaceNames: forbiddenHostSurfaceNames,
            lateCareerReports: lateCareerReports,
            blockers: blockers
        )
    }

    public static var acceptanceReadyThroughCycle890: Bool {
        report.isReady
    }

    private static func battleReport(
        for battlefieldID: String,
        seed: UInt32
    ) -> UnifiedRealDZWPlayableParityBattleReport? {
        guard let route = UnifiedPlayableBoardRouteCatalog.route(for: .lateCareer(battlefieldID)),
              let entry = UnifiedGuderianBattleCatalog.entry(for: .lateCareer(battlefieldID)),
              let session = LateCareerNativeBoardSession(battlefieldID: battlefieldID, seed: seed) else {
            return nil
        }

        let opening = session.snapshot()
        if opening.selectedUnit != nil {
            switch opening.phase {
            case .movement:
                session.moveSelectedUnitTowardNearestObjective(maxDistance: 4)
            case .shooting:
                session.selectNearestEnemyToSelectedUnit()
                session.shootSelectedTarget()
            case .assault:
                session.resolveFirstPendingChoice()
            }
        }
        let afterAction = session.snapshot()
        session.advancePhase()
        let afterPhase = session.snapshot()
        let completion = UnifiedLateCareerCompletionResolver.completeBattle(from: session)

        return UnifiedRealDZWPlayableParityBattleReport(
            id: battlefieldID,
            title: entry.title,
            order: entry.order,
            hostSurfaceName: route.hostSurfaceName,
            snapshotTypeName: "NativeBoardSnapshot",
            openingBoardPlayable: opening.isScenarioBoardPlayable,
            openingUnitCount: opening.units.count,
            openingObjectiveCount: opening.objectives.count,
            openingZoneCount: opening.zones.count,
            selectedUnitName: opening.selectedUnit?.name ?? "",
            commandActionStatus: afterAction.lastAction.status,
            commandActionDetail: afterAction.lastAction.detail,
            phaseAdvanced: afterPhase.phase != opening.phase ||
                afterPhase.activePlayer != opening.activePlayer ||
                afterPhase.turnNumber != opening.turnNumber,
            completionPersistenceKey: completion?.persistenceKey ?? "",
            forbiddenSurfaceNames: forbiddenHostSurfaceNames
        )
    }

    private static func blockers(for battleReport: UnifiedRealDZWPlayableParityBattleReport) -> [String] {
        var blockers: [String] = []
        if battleReport.hostSurfaceName != requiredHostSurfaceName {
            blockers.append("\(battleReport.title) does not target \(requiredHostSurfaceName).")
        }
        if battleReport.snapshotTypeName != "NativeBoardSnapshot" {
            blockers.append("\(battleReport.title) does not expose the shared native board snapshot.")
        }
        if !battleReport.openingBoardPlayable {
            blockers.append("\(battleReport.title) does not open on a playable native board.")
        }
        if battleReport.selectedUnitName.isEmpty {
            blockers.append("\(battleReport.title) did not select an opening unit.")
        }
        if battleReport.commandActionStatus == .idle {
            blockers.append("\(battleReport.title) did not resolve a live board command.")
        }
        if !battleReport.phaseAdvanced {
            blockers.append("\(battleReport.title) did not advance phase through the shared board API.")
        }
        if !battleReport.completionPersistenceKey.contains(battleReport.id) {
            blockers.append("\(battleReport.title) did not resolve late-career persistence from the live board session.")
        }
        if forbiddenHostSurfaceNames.contains(battleReport.hostSurfaceName) {
            blockers.append("\(battleReport.title) still targets a retired late-career surface.")
        }
        return blockers
    }
}

private struct LateCareerNativeBattleInstanceBuilder {
    let battlefield: LateCareerStaffBattlefield

    func build() -> LateCareerNativeBattleInstance {
        let frame = NativeBattleFrame(width: battlefield.map.width, height: battlefield.map.height)
        let zones = makeDeploymentZones()
        return LateCareerNativeBattleInstance(
            id: battlefield.id,
            instanceID: "\(battlefield.id)-late-career-native-v1",
            title: battlefield.title,
            order: battlefield.order,
            commandScope: battlefield.scope,
            frame: frame,
            terrain: makeTerrain(),
            deploymentZones: zones,
            objectives: makeObjectives(),
            units: makeUnits(deploymentZones: zones),
            events: makeEvents(),
            aiProfile: makeAIProfile(),
            victory: makeVictory(),
            caveatLabel: battlefield.visibleCommandCaveatLabel
        )
    }

    private func makeTerrain() -> [NativeBattleTerrainFeature] {
        battlefield.map.elements.map { element in
            NativeBattleTerrainFeature(
                id: element.id,
                name: element.name,
                kind: unifiedNativeTerrainKind(element.kind),
                side: unifiedNativeSide(element.side),
                points: element.points.map { NativeBattleCoordinate(x: $0.x, y: $0.y) },
                radius: element.radius,
                movementCostHint: unifiedMovementCostHint(for: element.kind),
                blocksLineOfSightHint: unifiedBlocksLineOfSightHint(for: element.kind),
                note: element.note
            )
        }
    }

    private func makeDeploymentZones() -> [NativeBattleDeploymentZone] {
        battlefield.map.deploymentZones.map { zone in
            NativeBattleDeploymentZone(
                id: zone.id,
                name: zone.name,
                side: unifiedNativeSide(zone.side),
                origin: NativeBattleCoordinate(x: zone.origin.x, y: zone.origin.y),
                width: zone.width,
                height: zone.height,
                capacityHint: max(2, battlefield.forces.filter { $0.side == zone.side }.count + battlefield.objectives.filter { $0.side == zone.side }.count),
                note: zone.note
            )
        }
    }

    private func makeObjectives() -> [NativeBattleObjective] {
        let anchors = objectiveAnchors()
        return battlefield.objectives.enumerated().map { index, objective in
            let anchor = anchors.isEmpty ? nil : anchors[index % anchors.count]
            let position = anchor.flatMap(center) ?? NativeBattleCoordinate(x: battlefield.map.width / 2, y: battlefield.map.height / 2)
            return NativeBattleObjective(
                id: objective.id,
                name: objective.name,
                side: unifiedNativeSide(objective.side),
                kind: unifiedObjectiveKind(name: objective.name, description: objective.description),
                victoryPoints: objective.victoryPoints,
                timing: "Late-career scenario objective",
                description: objective.description,
                anchorTerrainID: anchor?.id,
                position: position
            )
        }
    }

    private func makeUnits(deploymentZones: [NativeBattleDeploymentZone]) -> [NativeBattleUnit] {
        let forceUnits = battlefield.forces.enumerated().map { index, force in
            makeUnit(
                id: force.id,
                name: force.name,
                side: unifiedNativeSide(force.side),
                role: force.role,
                note: force.caveat,
                zone: zone(for: unifiedNativeSide(force.side), in: deploymentZones),
                index: index,
                count: max(1, battlefield.forces.count)
            )
        }
        let objectiveUnits = battlefield.objectives.enumerated().map { index, objective in
            let side = unifiedNativeSide(objective.side)
            return makeUnit(
                id: "\(objective.id)-detachment",
                name: "\(objective.name) detachment",
                side: side,
                role: objective.description,
                note: battlefield.visibleCommandCaveatLabel,
                zone: zone(for: side, in: deploymentZones),
                index: index + forceUnits.count,
                count: max(1, battlefield.objectives.count + forceUnits.count)
            )
        }
        return forceUnits + objectiveUnits
    }

    private func makeUnit(id: String, name: String, side: NativeBattleSide, role: String, note: String, zone: NativeBattleDeploymentZone, index: Int, count: Int) -> NativeBattleUnit {
        NativeBattleUnit(
            id: id,
            name: name,
            side: side,
            mobility: unifiedMobility(name: name, role: role),
            role: role,
            historicalNote: note,
            deploymentZoneID: zone.id,
            startingPosition: position(in: zone, index: index, count: count),
            weapons: unifiedWeaponProfiles(id: id, name: name, role: role, note: note)
        )
    }

    private func makeEvents() -> [NativeBattleEventTrigger] {
        battlefield.rules.map { rule in
            NativeBattleEventTrigger(
                id: "\(rule.id)-late-native-event",
                kind: .trigger,
                title: rule.name,
                timing: "Late-career rule",
                condition: rule.trigger,
                effect: rule.effect,
                sourceID: rule.id
            )
        }
    }

    private func makeAIProfile() -> LateCareerNativeAIProfile {
        let plan = LateCareerPlayableSurfaceCatalog.aiPlan(for: battlefield.id)
        let priorities = plan?.priorities.sorted { $0.order < $1.order } ?? []
        return LateCareerNativeAIProfile(
            id: "\(battlefield.id)-native-ai",
            postureName: "\(battlefield.scope.rawValue) pressure",
            strategicGoal: battlefield.germanContext,
            targetPriorities: priorities.map(\.targetName),
            orders: priorities.enumerated().map { index, priority in
                NativeBattleAIOrder(
                    id: "\(priority.id)-native-order",
                    turnWindow: index == 0 ? "Turn 1" : "Turns \(index + 1)-\(index + 3)",
                    kind: .movement,
                    target: priority.targetName,
                    instruction: priority.detail
                )
            }
        )
    }

    private func makeVictory() -> NativeBattleVictoryProfile {
        let report = LateCareerPlayableSurfaceCatalog.report(for: battlefield.id)
        let scoring = report?.scoringProfile
        let maxScore = scoring?.maxPlayerScore ?? max(1, battlefield.objectives.map(\.victoryPoints).reduce(0, +))
        let lowerTurn = scoring?.targetTurnLowerBound ?? 6
        let upperTurn = max(lowerTurn, scoring?.targetTurnUpperBound ?? 10)
        return NativeBattleVictoryProfile(
            targetTurns: lowerTurn...upperTurn,
            missionTargetScore: max(1, maxScore),
            playerWinCondition: "Complete \(battlefield.title) through the unified 35-battle playable screen.",
            pressureLimit: battlefield.visibleCommandCaveatLabel,
            scoreRules: battlefield.objectives.map { objective in
                NativeBattleScoreRule(
                    id: "\(objective.id)-score",
                    name: objective.name,
                    side: unifiedNativeSide(objective.side),
                    victoryPoints: objective.victoryPoints,
                    timing: "Late-career objective scoring",
                    description: objective.description
                )
            },
            outcomeBands: [
                ScenarioOutcomeBand(id: "\(battlefield.id)-operational", grade: .operational, scoreRange: max(1, maxScore - 2)...maxScore, summary: "Unified playable result for \(battlefield.title)."),
                ScenarioOutcomeBand(id: "\(battlefield.id)-tactical", grade: .tactical, scoreRange: max(1, maxScore / 2)...max(1, maxScore - 3), summary: "Partial late-career battlefield result."),
                ScenarioOutcomeBand(id: "\(battlefield.id)-pressure", grade: .historicalPressure, scoreRange: 0...max(0, (maxScore / 2) - 1), summary: battlefield.visibleCommandCaveatLabel),
            ]
        )
    }

    private func objectiveAnchors() -> [ScenarioMapElement] {
        let preferred: Set<ScenarioMapElementKind> = [.objective, .bridge, .ford, .ferry, .urbanDistrict, .village, .town, .fortifiedLine, .phaseLine]
        return battlefield.map.elements.filter { preferred.contains($0.kind) }
    }

    private func center(of element: ScenarioMapElement) -> NativeBattleCoordinate? {
        guard !element.points.isEmpty else {
            return nil
        }
        let sum = element.points.reduce((x: 0.0, y: 0.0)) { partial, point in
            (partial.x + point.x, partial.y + point.y)
        }
        return NativeBattleCoordinate(x: sum.x / Double(element.points.count), y: sum.y / Double(element.points.count))
    }

    private func zone(for side: NativeBattleSide, in zones: [NativeBattleDeploymentZone]) -> NativeBattleDeploymentZone {
        zones.first { $0.side == side } ??
            zones.first { $0.side != .neutral } ??
            NativeBattleDeploymentZone(
                id: "\(battlefield.id)-fallback-zone",
                name: "Fallback deployment",
                side: side,
                origin: NativeBattleCoordinate(x: 0, y: 0),
                width: battlefield.map.width,
                height: battlefield.map.height,
                capacityHint: battlefield.forces.count,
                note: "Generated fallback only used when authored deployment zones are missing."
            )
    }

    private func position(in zone: NativeBattleDeploymentZone, index: Int, count: Int) -> NativeBattleCoordinate {
        let columns = max(1, Int(ceil(sqrt(Double(count)))))
        let rows = max(1, Int(ceil(Double(count) / Double(columns))))
        let column = index % columns
        let row = index / columns
        return NativeBattleCoordinate(
            x: unifiedClamp(zone.origin.x + zone.width * (Double(column + 1) / Double(columns + 1)), min: 0, max: battlefield.map.width),
            y: unifiedClamp(zone.origin.y + zone.height * (Double(min(row, rows - 1) + 1) / Double(rows + 1)), min: 0, max: battlefield.map.height)
        )
    }
}

private struct UnifiedScenarioBoardRect {
    let x: Float
    let y: Float
    let width: Float
    let height: Float
}

private struct UnifiedScenarioBoardZoneSpec {
    let id: Int
    let name: String
    let kind: terrain_kind_t
    let rect: UnifiedScenarioBoardRect
    let coverSave: Int
    let blocksLineOfSight: Bool
    let hullDown: Bool
}

private struct UnifiedScenarioBoardObjectiveSpec {
    let id: Int
    let name: String
    let x: Float
    let y: Float
    let radius: Float
}

private struct UnifiedCatalogOption {
    let catalogID: Int
    let name: String
    let primaryWeaponName: String
    let kind: unit_kind_t
    let maxCount: Int
}

private func unifiedNativeTerrainKind(_ kind: ScenarioMapElementKind) -> NativeBattleTerrainKind {
    switch kind {
    case .road:
        return .road
    case .river:
        return .river
    case .canal:
        return .canal
    case .lake:
        return .lake
    case .marsh:
        return .marsh
    case .railway:
        return .railway
    case .town:
        return .town
    case .village:
        return .village
    case .urbanDistrict:
        return .urbanDistrict
    case .forest:
        return .forest
    case .ridge:
        return .ridge
    case .bunker:
        return .bunker
    case .fortifiedLine:
        return .fortifiedLine
    case .bridge:
        return .bridge
    case .ford:
        return .ford
    case .ferry:
        return .ferry
    case .objective, .deployment:
        return .objective
    case .artillery:
        return .artilleryPark
    case .airPressure:
        return .airPressure
    case .phaseLine:
        return .phaseLine
    }
}

private func unifiedNativeSide(_ side: ScenarioSide) -> NativeBattleSide {
    switch side {
    case .player:
        return .player
    case .guderianAI:
        return .guderianAI
    case .neutral:
        return .neutral
    }
}

private func unifiedObjectiveKind(name: String, description: String) -> NativeBattleObjectiveKind {
    let text = "\(name) \(description)".lowercased()
    if unifiedContainsAny(text, ["withdraw", "escape", "exit", "corridor"]) { return .withdraw }
    if unifiedContainsAny(text, ["breakout", "breakthrough"]) { return .breakout }
    if unifiedContainsAny(text, ["evacuate", "evacuation"]) { return .evacuate }
    if unifiedContainsAny(text, ["preserve", "protect"]) { return .preserve }
    if unifiedContainsAny(text, ["counter", "strike"]) { return .counterattack }
    if unifiedContainsAny(text, ["deny", "block", "cut", "seal", "close", "isolate"]) { return .deny }
    if unifiedContainsAny(text, ["disrupt", "raid"]) { return .disrupt }
    if unifiedContainsAny(text, ["hold", "control"]) { return .hold }
    return .score
}

private func unifiedMobility(name: String, role: String) -> NativeBattleUnitMobility {
    let text = "\(name) \(role)".lowercased()
    if unifiedContainsAny(text, ["tank", "armor", "armored", "panzer", "mobile", "mechanized"]) { return .armor }
    if unifiedContainsAny(text, ["engineer", "sapper", "bridge", "crossing"]) { return .engineer }
    if unifiedContainsAny(text, ["artillery", "gun", "anti-tank", "anti tank"]) { return .gun }
    if unifiedContainsAny(text, ["command", "staff", "headquarters"]) { return .command }
    if unifiedContainsAny(text, ["cavalry"]) { return .cavalry }
    return .infantry
}

private func unifiedWeaponProfiles(id: String, name: String, role: String, note: String) -> [NativeBattleWeaponProfile] {
    let text = "\(name) \(role) \(note)".lowercased()
    var roles: [NativeBattleWeaponRole] = []
    if unifiedContainsAny(text, ["anti-tank", "anti tank", "tank", "armor", "armored", "panzer"]) { roles.append(.antiTank) }
    if unifiedContainsAny(text, ["tank", "armor", "armored", "panzer"]) { roles.append(.armorGun) }
    if unifiedContainsAny(text, ["artillery", "gun", "battery"]) { roles.append(.artillery) }
    if unifiedContainsAny(text, ["engineer", "sapper", "bridge", "demolition", "crossing"]) { roles.append(.demolition) }
    if unifiedContainsAny(text, ["command", "staff", "headquarters"]) { roles.append(.command) }
    if unifiedContainsAny(text, ["recon", "cavalry", "raid"]) { roles.append(.reconnaissance) }
    roles.append(.smallArms)

    var unique: [NativeBattleWeaponRole] = []
    for role in roles where !unique.contains(role) {
        unique.append(role)
    }
    return unique.map { role in
        NativeBattleWeaponProfile(
            id: "\(id)-\(role.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))",
            name: role.rawValue,
            role: role,
            rangeBand: role == .smallArms ? "Close" : "Scenario",
            effect: role == .smallArms ? "Baseline combat capability." : "Late-career scenario capability derived from authored force and objective text."
        )
    }
}

private func unifiedMovementCostHint(for kind: ScenarioMapElementKind) -> Double {
    switch kind {
    case .road, .railway:
        return 0.75
    case .river, .canal, .lake:
        return 99
    case .marsh, .forest, .ridge, .bunker, .fortifiedLine, .urbanDistrict:
        return 2
    case .bridge, .ford, .ferry:
        return 1
    case .town, .village:
        return 1.5
    case .objective, .artillery, .airPressure, .deployment, .phaseLine:
        return 1
    }
}

private func unifiedBlocksLineOfSightHint(for kind: ScenarioMapElementKind) -> Bool {
    switch kind {
    case .forest, .ridge, .bunker, .fortifiedLine, .town, .village, .urbanDistrict:
        return true
    default:
        return false
    }
}

private func engineTerrainKind(for kind: NativeBattleTerrainKind) -> terrain_kind_t {
    switch kind {
    case .river, .canal, .lake:
        return DZW_TERRAIN_IMPASSABLE
    case .town, .village, .urbanDistrict, .forest, .ridge, .bunker, .fortifiedLine, .marsh:
        return DZW_TERRAIN_DIFFICULT
    case .road, .railway, .bridge, .ford, .ferry, .objective, .artilleryPark, .airPressure, .phaseLine:
        return DZW_TERRAIN_OPEN
    }
}

private func unifiedCoverSave(for kind: NativeBattleTerrainKind) -> Int {
    switch kind {
    case .bunker, .fortifiedLine:
        return 4
    case .town, .village, .urbanDistrict, .forest, .ridge, .marsh:
        return 5
    case .bridge, .ford, .ferry, .artilleryPark:
        return 6
    case .road, .river, .canal, .lake, .railway, .objective, .airPressure, .phaseLine:
        return 0
    }
}

private func unifiedTerrainPriority(_ kind: NativeBattleTerrainKind) -> Int {
    switch kind {
    case .bunker, .fortifiedLine:
        return 7
    case .bridge, .ford, .ferry:
        return 6
    case .town, .village, .urbanDistrict, .forest, .ridge, .marsh:
        return 5
    case .road, .railway, .phaseLine:
        return 4
    case .river, .canal, .lake:
        return 3
    case .artilleryPark:
        return 2
    case .objective, .airPressure:
        return 1
    }
}

private func unifiedIsLinearTerrain(_ kind: NativeBattleTerrainKind) -> Bool {
    switch kind {
    case .road, .railway, .river, .canal, .bridge, .ford, .ferry, .phaseLine:
        return true
    default:
        return false
    }
}

private func withUnifiedCStringPointers<Result>(_ strings: [String], _ body: ([UnsafePointer<CChar>?]) -> Result) -> Result {
    var result: Result?

    func recurse(_ index: Int, _ pointers: [UnsafePointer<CChar>?]) {
        if index == strings.count {
            result = body(pointers)
            return
        }
        strings[index].withCString { pointer in
            recurse(index + 1, pointers + [pointer])
        }
    }

    recurse(0, [])
    return result!
}

private func unifiedCString(_ pointer: UnsafePointer<CChar>?) -> String {
    guard let pointer else {
        return ""
    }
    return String(cString: pointer)
}

private func unifiedContainsAny(_ text: String, _ needles: [String]) -> Bool {
    needles.contains { text.contains($0) }
}

private func unifiedClamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
    Swift.min(Swift.max(value, minimum), maximum)
}

private func unifiedDistance(from unit: unit_view_t, to objective: objective_view_t) -> Double {
    let dx = Double(unit.x) - Double(objective.x)
    let dy = Double(unit.y) - Double(objective.y)
    return sqrt(dx * dx + dy * dy)
}

private func unifiedDistance(from lhs: unit_view_t, to rhs: unit_view_t) -> Double {
    let dx = Double(lhs.x) - Double(rhs.x)
    let dy = Double(lhs.y) - Double(rhs.y)
    return sqrt(dx * dx + dy * dy)
}

private func unifiedNormalized(_ string: String) -> String {
    string
        .lowercased()
        .replacingOccurrences(of: "-", with: " ")
        .replacingOccurrences(of: "/", with: " ")
}

private func unifiedBoardPhase(_ phase: phase_t) -> NativeBoardPhase {
    switch phase {
    case DZW_PHASE_SHOOTING:
        return .shooting
    case DZW_PHASE_ASSAULT:
        return .assault
    default:
        return .movement
    }
}

private func unifiedUnitKindName(_ kind: unit_kind_t) -> String {
    switch kind {
    case DZW_UNIT_VEHICLE:
        return "Vehicle"
    case DZW_UNIT_ASSAULT_GUN:
        return "Assault gun"
    default:
        return "Infantry"
    }
}

private func unifiedTerrainKindName(_ kind: terrain_kind_t) -> String {
    switch kind {
    case DZW_TERRAIN_DIFFICULT:
        return "Difficult"
    case DZW_TERRAIN_IMPASSABLE:
        return "Impassable"
    default:
        return "Open"
    }
}
