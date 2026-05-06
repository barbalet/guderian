import Foundation

public enum TutorialFlowID: String, Codable, CaseIterable, Hashable, Sendable {
    case firstRunHistory
    case firstBattleGuidance
}

public enum TutorialPresentationKind: String, Codable, Hashable, Sendable {
    case pagedOnboarding
    case contextualBattleHints
}

public enum TutorialTrigger: String, Codable, CaseIterable, Hashable, Sendable {
    case appFirstLaunch
    case battleOpened
    case boardVisible
    case unitSelection
    case objectiveInspection
    case movementDrag
    case phaseAdvance
    case blockedAction
    case shooting
    case assault
    case germanAITurn
    case debrief
}

public enum FirstBattleGuidanceHintID: String, Codable, CaseIterable, Hashable, Sendable {
    case orientation = "firstBattleGuidance-orientation"
    case board = "firstBattleGuidance-board"
    case selection = "firstBattleGuidance-selection"
    case objectives = "firstBattleGuidance-objectives"
    case movement = "firstBattleGuidance-movement"
    case phase = "firstBattleGuidance-phase"
    case shooting = "firstBattleGuidance-shooting"
    case assault = "firstBattleGuidance-assault"
    case blocked = "firstBattleGuidance-blocked"
    case germanAI = "firstBattleGuidance-germanAI"
    case debrief = "firstBattleGuidance-debrief"
}

public enum FirstBattleButtonCoachID: String, Codable, CaseIterable, Hashable, Sendable {
    case autoStep = "firstBattleButtonCoach-autoStep"
    case germanTurn = "firstBattleButtonCoach-germanTurn"
    case playToEnd = "firstBattleButtonCoach-playToEnd"
    case nextPhase = "firstBattleButtonCoach-nextPhase"
    case debrief = "firstBattleButtonCoach-debrief"
    case restart = "firstBattleButtonCoach-restart"
    case previousReady = "firstBattleButtonCoach-previousReady"
    case nextReady = "firstBattleButtonCoach-nextReady"
    case nearestEnemy = "firstBattleButtonCoach-nearestEnemy"
    case clearSelection = "firstBattleButtonCoach-clearSelection"
    case rotateLeft = "firstBattleButtonCoach-rotateLeft"
    case rotateRight = "firstBattleButtonCoach-rotateRight"
    case manualCover = "firstBattleButtonCoach-manualCover"
    case hullDown = "firstBattleButtonCoach-hullDown"
    case shootTarget = "firstBattleButtonCoach-shootTarget"
    case assaultFollowUp = "firstBattleButtonCoach-assaultFollowUp"
    case assaultTarget = "firstBattleButtonCoach-assaultTarget"
    case resolvePending = "firstBattleButtonCoach-resolvePending"
    case zoomOut = "firstBattleButtonCoach-zoomOut"
    case resetZoom = "firstBattleButtonCoach-resetZoom"
    case commandPanel = "firstBattleButtonCoach-commandPanel"
    case inspectorPanel = "firstBattleButtonCoach-inspectorPanel"
    case forcesPanel = "firstBattleButtonCoach-forcesPanel"
    case logPanel = "firstBattleButtonCoach-logPanel"
}

public struct TutorialStorageKey: Codable, Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public protocol TutorialContent {
    var body: String { get }
    var requiredTopics: [String] { get }
}

public extension TutorialContent {
    var wordCount: Int {
        body
            .split { $0.isWhitespace || $0.isNewline }
            .count
    }

    var containsRequiredTopics: Bool {
        requiredTopics.allSatisfy { topic in
            body.localizedCaseInsensitiveContains(topic)
        }
    }
}

public struct TutorialPage: Identifiable, Codable, Hashable, Sendable, TutorialContent {
    public let id: String
    public let title: String
    public let body: String
    public let accessibilityIdentifier: String
    public let requiredTopics: [String]

    public init(
        id: String,
        title: String,
        body: String,
        accessibilityIdentifier: String,
        requiredTopics: [String] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.accessibilityIdentifier = accessibilityIdentifier
        self.requiredTopics = requiredTopics
    }
}

public struct TutorialHint: Identifiable, Codable, Hashable, Sendable, TutorialContent {
    public let id: String
    public let trigger: TutorialTrigger
    public let order: Int
    public let title: String
    public let body: String
    public let accessibilityIdentifier: String
    public let requiredTopics: [String]

    public init(
        id: String,
        trigger: TutorialTrigger,
        order: Int,
        title: String,
        body: String,
        accessibilityIdentifier: String,
        requiredTopics: [String] = []
    ) {
        self.id = id
        self.trigger = trigger
        self.order = order
        self.title = title
        self.body = body
        self.accessibilityIdentifier = accessibilityIdentifier
        self.requiredTopics = requiredTopics
    }
}

public struct FirstBattleButtonCoachTip: Identifiable, Codable, Hashable, Sendable, TutorialContent {
    public let id: FirstBattleButtonCoachID
    public let title: String
    public let body: String
    public let accessibilityIdentifier: String
    public let requiredTopics: [String]

    public init(
        id: FirstBattleButtonCoachID,
        title: String,
        body: String,
        accessibilityIdentifier: String,
        requiredTopics: [String] = []
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.accessibilityIdentifier = accessibilityIdentifier
        self.requiredTopics = requiredTopics
    }
}

public struct TutorialFlow: Identifiable, Codable, Hashable, Sendable {
    public let id: TutorialFlowID
    public let version: Int
    public let title: String
    public let presentationKind: TutorialPresentationKind
    public let storageKey: TutorialStorageKey
    public let openingTrigger: TutorialTrigger
    public let pages: [TutorialPage]
    public let hints: [TutorialHint]
    public let doNotShowAgainLabel: String

    public init(
        id: TutorialFlowID,
        version: Int,
        title: String,
        presentationKind: TutorialPresentationKind,
        storageKey: TutorialStorageKey,
        openingTrigger: TutorialTrigger,
        pages: [TutorialPage],
        hints: [TutorialHint] = [],
        doNotShowAgainLabel: String = GuderianTutorialCatalog.doNotShowAgainLabel
    ) {
        self.id = id
        self.version = version
        self.title = title
        self.presentationKind = presentationKind
        self.storageKey = storageKey
        self.openingTrigger = openingTrigger
        self.pages = pages
        self.hints = hints
        self.doNotShowAgainLabel = doNotShowAgainLabel
    }

    public var usesReusableStorageContract: Bool {
        storageKey.rawValue.hasPrefix("guderian.tutorial.") &&
            storageKey.rawValue.contains(".v\(version).") &&
            doNotShowAgainLabel == GuderianTutorialCatalog.doNotShowAgainLabel
    }

    public var orderedHints: [TutorialHint] {
        hints.sorted { lhs, rhs in
            if lhs.order == rhs.order {
                return lhs.id < rhs.id
            }
            return lhs.order < rhs.order
        }
    }

    public func hasHint(for trigger: TutorialTrigger) -> Bool {
        hints.contains { $0.trigger == trigger }
    }

    public func isLastHint(_ hint: TutorialHint) -> Bool {
        orderedHints.last?.id == hint.id
    }
}

public struct TutorialProgress: Codable, Hashable, Sendable {
    public private(set) var dismissedVersions: [TutorialFlowID: Int]
    public private(set) var completedHintIDs: Set<String>

    public init(
        dismissedVersions: [TutorialFlowID: Int] = [:],
        completedHintIDs: Set<String> = []
    ) {
        self.dismissedVersions = dismissedVersions
        self.completedHintIDs = completedHintIDs
    }

    public func shouldPresent(_ flow: TutorialFlow) -> Bool {
        dismissedVersions[flow.id, default: 0] < flow.version
    }

    public mutating func dismiss(_ flow: TutorialFlow) {
        dismissedVersions[flow.id] = flow.version
    }

    public mutating func reset(_ id: TutorialFlowID? = nil) {
        if let id {
            dismissedVersions[id] = nil
            completedHintIDs = completedHintIDs.filter { !$0.hasPrefix("\(id.rawValue)-") }
        } else {
            dismissedVersions.removeAll()
            completedHintIDs.removeAll()
        }
    }

    public mutating func recordHintCompletion(_ hint: TutorialHint) {
        completedHintIDs.insert(hint.id)
    }

    public func hasCompleted(_ hint: TutorialHint) -> Bool {
        completedHintIDs.contains(hint.id)
    }

    public func completedHintCount(in flow: TutorialFlow) -> Int {
        flow.hints.filter { completedHintIDs.contains($0.id) }.count
    }

    public func isComplete(_ flow: TutorialFlow) -> Bool {
        flow.hints.isEmpty == false &&
            completedHintCount(in: flow) == flow.hints.count
    }

    public func nextIncompleteHint(
        in flow: TutorialFlow,
        triggeredHintIDs: Set<String>
    ) -> TutorialHint? {
        flow.orderedHints.first { hint in
            triggeredHintIDs.contains(hint.id) && !completedHintIDs.contains(hint.id)
        }
    }
}

public struct FirstBattleButtonCoachProgress: Codable, Hashable, Sendable {
    public private(set) var usedButtonIDs: Set<FirstBattleButtonCoachID>
    public private(set) var completedFirstGame: Bool

    public init(
        usedButtonIDs: Set<FirstBattleButtonCoachID> = [],
        completedFirstGame: Bool = false
    ) {
        self.usedButtonIDs = usedButtonIDs
        self.completedFirstGame = completedFirstGame
    }

    public func shouldPresent(_ id: FirstBattleButtonCoachID) -> Bool {
        !completedFirstGame && !usedButtonIDs.contains(id)
    }

    public mutating func recordUse(_ id: FirstBattleButtonCoachID) {
        usedButtonIDs.insert(id)
    }

    public mutating func completeFirstGame() {
        completedFirstGame = true
    }

    public mutating func resetSessionUse() {
        usedButtonIDs.removeAll()
    }
}

public struct TutorialTriggerEvent: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let flowID: TutorialFlowID
    public let trigger: TutorialTrigger
    public let hintIDs: [String]

    public init(
        flowID: TutorialFlowID,
        trigger: TutorialTrigger,
        hintIDs: [String]
    ) {
        self.id = "\(flowID.rawValue)-\(trigger.rawValue)-\(hintIDs.joined(separator: "-"))"
        self.flowID = flowID
        self.trigger = trigger
        self.hintIDs = hintIDs
    }
}

public struct TutorialHintCoordinator: Codable, Hashable, Sendable {
    public private(set) var progress: TutorialProgress
    public private(set) var events: [TutorialTriggerEvent]

    public var triggeredHintIDs: Set<String> {
        Set(events.flatMap(\.hintIDs))
    }

    public init(
        progress: TutorialProgress = TutorialProgress(),
        triggeredHintIDs: Set<String> = [],
        events: [TutorialTriggerEvent] = []
    ) {
        self.progress = progress
        self.events = events + Self.legacyEvents(for: triggeredHintIDs.subtracting(Set(events.flatMap(\.hintIDs))))
    }

    public mutating func record(_ trigger: TutorialTrigger, in flow: TutorialFlow) {
        let matchingHints = flow.orderedHints.filter { $0.trigger == trigger }
        guard !matchingHints.isEmpty else {
            return
        }

        let ids = matchingHints.map(\.id)
        events.append(TutorialTriggerEvent(flowID: flow.id, trigger: trigger, hintIDs: ids))
    }

    public func activeHint(in flow: TutorialFlow) -> TutorialHint? {
        guard progress.shouldPresent(flow) else {
            return nil
        }
        return progress.nextIncompleteHint(in: flow, triggeredHintIDs: triggeredHintIDs)
    }

    public mutating func completeActiveHint(in flow: TutorialFlow) {
        guard let hint = activeHint(in: flow) else {
            return
        }
        progress.recordHintCompletion(hint)
    }

    public mutating func dismiss(_ flow: TutorialFlow) {
        progress.dismiss(flow)
    }

    public mutating func reset(_ id: TutorialFlowID? = nil) {
        progress.reset(id)
        if let id {
            events = events.filter { $0.flowID != id }
        } else {
            events.removeAll()
        }
    }

    private enum CodingKeys: String, CodingKey {
        case progress
        case triggeredHintIDs
        case events
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        progress = try container.decode(TutorialProgress.self, forKey: .progress)
        let events = try container.decodeIfPresent([TutorialTriggerEvent].self, forKey: .events) ?? []
        let legacyIDs = try container.decodeIfPresent(Set<String>.self, forKey: .triggeredHintIDs) ?? []
        self.events = events + Self.legacyEvents(for: legacyIDs.subtracting(Set(events.flatMap(\.hintIDs))))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(progress, forKey: .progress)
        try container.encode(events, forKey: .events)
    }

    private static func legacyEvents(for ids: Set<String>) -> [TutorialTriggerEvent] {
        TutorialFlowID.allCases.compactMap { flowID in
            let matchingIDs = ids
                .filter { $0.hasPrefix("\(flowID.rawValue)-") }
                .sorted()
            guard !matchingIDs.isEmpty else {
                return nil
            }
            return TutorialTriggerEvent(flowID: flowID, trigger: .battleOpened, hintIDs: matchingIDs)
        }
    }
}

public enum TutorialProgressCodec {
    public static let cycleRange = 906...910

    public static func encode(_ progress: TutorialProgress) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(progress)
    }

    public static func decode(_ data: Data) throws -> TutorialProgress {
        try JSONDecoder().decode(TutorialProgress.self, from: data)
    }

    public static func decodeIfPresent(_ data: Data) -> TutorialProgress {
        guard !data.isEmpty,
              let progress = try? decode(data) else {
            return TutorialProgress()
        }
        return progress
    }
}

public enum GuderianTutorialCatalog {
    public static let cycleRange = 891...930
    public static let firstRunCycleRange = 891...910
    public static let firstBattleCycleRange = 911...930
    public static let doNotShowAgainLabel = "Do not show again"

    public static let firstRunHistoryStorageKey = TutorialStorageKey("guderian.tutorial.firstRunHistory.v1.dismissed")
    public static let firstBattleGuidanceStorageKey = TutorialStorageKey("guderian.tutorial.firstBattleGuidance.v1.dismissed")
    public static let firstBattleButtonCoachStorageKey = TutorialStorageKey("guderian.tutorial.firstBattleButtonCoach.v1.completed")

    public static var firstRunHistoryFlow: TutorialFlow {
        TutorialFlow(
            id: .firstRunHistory,
            version: 1,
            title: "Before The Campaign",
            presentationKind: .pagedOnboarding,
            storageKey: firstRunHistoryStorageKey,
            openingTrigger: .appFirstLaunch,
            pages: firstRunHistoryPages
        )
    }

    public static var firstBattleGuidanceFlow: TutorialFlow {
        TutorialFlow(
            id: .firstBattleGuidance,
            version: 1,
            title: "First Battle Guidance",
            presentationKind: .contextualBattleHints,
            storageKey: firstBattleGuidanceStorageKey,
            openingTrigger: .battleOpened,
            pages: [],
            hints: firstBattleGuidanceHints
        )
    }

    public static var firstBattleButtonCoachTips: [FirstBattleButtonCoachTip] {
        [
            FirstBattleButtonCoachTip(
                id: .autoStep,
                title: "Auto Step",
                body: "Runs one legal action for the active side and then advances the board. Use it when you want the engine to handle a single phase step.",
                accessibilityIdentifier: "first-battle-button-coach-auto-step",
                requiredTopics: ["legal action", "phase"]
            ),
            FirstBattleButtonCoachTip(
                id: .germanTurn,
                title: "German Turn",
                body: "Lets the German AI act until control returns to you or the safety cap is reached. Watch where it applies pressure before setting your next defense.",
                accessibilityIdentifier: "first-battle-button-coach-german-turn",
                requiredTopics: ["German AI", "pressure"]
            ),
            FirstBattleButtonCoachTip(
                id: .playToEnd,
                title: "Play To End",
                body: "Autoplays the remaining battle and creates the debrief result. This is useful for checking the scenario outcome without issuing every order yourself.",
                accessibilityIdentifier: "first-battle-button-coach-play-to-end",
                requiredTopics: ["Autoplays", "debrief"]
            ),
            FirstBattleButtonCoachTip(
                id: .nextPhase,
                title: "Next Phase",
                body: "Moves the battle to the next movement, shooting, or assault phase. Check your selected unit first because some actions are only legal in one phase.",
                accessibilityIdentifier: "first-battle-button-coach-next-phase",
                requiredTopics: ["phase", "legal"]
            ),
            FirstBattleButtonCoachTip(
                id: .debrief,
                title: "Debrief",
                body: "Ends the current battle state and records score, victory band, and campaign progress. Use it when you are ready to accept the result.",
                accessibilityIdentifier: "first-battle-button-coach-debrief",
                requiredTopics: ["score", "campaign progress"]
            ),
            FirstBattleButtonCoachTip(
                id: .restart,
                title: "Restart",
                body: "Resets the battle to a fresh board while keeping the same scenario selected. Use it when you want to try a different opening plan.",
                accessibilityIdentifier: "first-battle-button-coach-restart",
                requiredTopics: ["Resets", "scenario"]
            ),
            FirstBattleButtonCoachTip(
                id: .previousReady,
                title: "Prev Ready",
                body: "Selects the previous active unit that can still participate. It helps you review the force without hunting across the map.",
                accessibilityIdentifier: "first-battle-button-coach-prev-ready",
                requiredTopics: ["active unit", "map"]
            ),
            FirstBattleButtonCoachTip(
                id: .nextReady,
                title: "Next Ready",
                body: "Selects the next active unit that can still participate. Use it to step through your available units before ending a phase.",
                accessibilityIdentifier: "first-battle-button-coach-next-ready",
                requiredTopics: ["active unit", "phase"]
            ),
            FirstBattleButtonCoachTip(
                id: .nearestEnemy,
                title: "Nearest Enemy",
                body: "Targets the closest enemy to the selected unit. This is a quick way to set up shooting or assault orders.",
                accessibilityIdentifier: "first-battle-button-coach-nearest-enemy",
                requiredTopics: ["enemy", "orders"]
            ),
            FirstBattleButtonCoachTip(
                id: .clearSelection,
                title: "Clear",
                body: "Returns selection to the first active friendly unit. It gives you a reliable reset when the current selection is confusing.",
                accessibilityIdentifier: "first-battle-button-coach-clear-selection",
                requiredTopics: ["selection", "friendly unit"]
            ),
            FirstBattleButtonCoachTip(
                id: .rotateLeft,
                title: "Rotate Left",
                body: "Turns the selected unit forty-five degrees left. Facing matters for vehicles and line-of-fire decisions.",
                accessibilityIdentifier: "first-battle-button-coach-rotate-left",
                requiredTopics: ["selected unit", "Facing"]
            ),
            FirstBattleButtonCoachTip(
                id: .rotateRight,
                title: "Rotate Right",
                body: "Turns the selected unit forty-five degrees right. Use it to orient armor or guns toward the threat you expect next.",
                accessibilityIdentifier: "first-battle-button-coach-rotate-right",
                requiredTopics: ["selected unit", "threat"]
            ),
            FirstBattleButtonCoachTip(
                id: .manualCover,
                title: "Manual Cover",
                body: "Marks whether the selected unit is using cover. Cover can change how survivable a position is under fire.",
                accessibilityIdentifier: "first-battle-button-coach-manual-cover",
                requiredTopics: ["selected unit", "Cover"]
            ),
            FirstBattleButtonCoachTip(
                id: .hullDown,
                title: "Hull Down",
                body: "Marks whether the selected vehicle is protected by a hull-down position. It is mainly for armor using terrain to reduce exposure.",
                accessibilityIdentifier: "first-battle-button-coach-hull-down",
                requiredTopics: ["vehicle", "terrain"]
            ),
            FirstBattleButtonCoachTip(
                id: .shootTarget,
                title: "Shoot Target",
                body: "Fires with the selected unit at the current target during the shooting phase. If the button is disabled, check phase, target, and whether the unit can still fire.",
                accessibilityIdentifier: "first-battle-button-coach-shoot-target",
                requiredTopics: ["shooting phase", "target"]
            ),
            FirstBattleButtonCoachTip(
                id: .assaultFollowUp,
                title: "Assault Follow-Up",
                body: "Chooses whether a victorious assaulting unit advances after combat. Leave it off when holding position matters more than taking ground.",
                accessibilityIdentifier: "first-battle-button-coach-assault-follow-up",
                requiredTopics: ["assault", "position"]
            ),
            FirstBattleButtonCoachTip(
                id: .assaultTarget,
                title: "Assault Target",
                body: "Orders close combat against the selected target during the assault phase. Use it only when the board position is worth the risk.",
                accessibilityIdentifier: "first-battle-button-coach-assault-target",
                requiredTopics: ["assault phase", "target"]
            ),
            FirstBattleButtonCoachTip(
                id: .resolvePending,
                title: "Resolve Pending",
                body: "Accepts the first pending rules choice so play can continue. Use it when combat or weapon handling is waiting for a resolution.",
                accessibilityIdentifier: "first-battle-button-coach-resolve-pending",
                requiredTopics: ["rules choice", "continue"]
            ),
            FirstBattleButtonCoachTip(
                id: .zoomOut,
                title: "Zoom Out",
                body: "Reduces the battlefield zoom level. Use it when you need more of the map in view before giving orders.",
                accessibilityIdentifier: "first-battle-button-coach-zoom-out",
                requiredTopics: ["zoom", "map"]
            ),
            FirstBattleButtonCoachTip(
                id: .resetZoom,
                title: "Reset Zoom",
                body: "Returns the battlefield to the normal zoom level. Use it when panning or scaling has made the board hard to read.",
                accessibilityIdentifier: "first-battle-button-coach-reset-zoom",
                requiredTopics: ["zoom", "board"]
            ),
            FirstBattleButtonCoachTip(
                id: .commandPanel,
                title: "Command Panel",
                body: "Shows or hides the command panel with phase and action controls. Keep it open when you are issuing orders frequently.",
                accessibilityIdentifier: "first-battle-button-coach-command-panel",
                requiredTopics: ["command panel", "orders"]
            ),
            FirstBattleButtonCoachTip(
                id: .inspectorPanel,
                title: "Inspector Panel",
                body: "Shows or hides unit details and objectives. Use it to understand the selected unit and the scenario goals.",
                accessibilityIdentifier: "first-battle-button-coach-inspector-panel",
                requiredTopics: ["unit details", "objectives"]
            ),
            FirstBattleButtonCoachTip(
                id: .forcesPanel,
                title: "Forces Panel",
                body: "Shows or hides the force matchup and recent German AI events. It helps you compare remaining units and pressure.",
                accessibilityIdentifier: "first-battle-button-coach-forces-panel",
                requiredTopics: ["force matchup", "pressure"]
            ),
            FirstBattleButtonCoachTip(
                id: .logPanel,
                title: "Log Panel",
                body: "Shows or hides the recent battle log. Open it when you need to review what the engine just resolved.",
                accessibilityIdentifier: "first-battle-button-coach-log-panel",
                requiredTopics: ["battle log", "engine"]
            ),
        ]
    }

    public static func firstBattleButtonCoachTip(for id: FirstBattleButtonCoachID) -> FirstBattleButtonCoachTip? {
        firstBattleButtonCoachTips.first { $0.id == id }
    }

    public static var firstRunHistoryPages: [TutorialPage] {
        [
            TutorialPage(
                id: "firstRunHistory-guderian",
                title: "Guderian In History",
                body: "Heinz Guderian was a German officer in World War II whose name became closely associated with armored warfare, radio coordination, and rapid combined-arms operations. He served Nazi Germany, held senior commands under Adolf Hitler, and both benefited from and argued with Hitler's direction of the war; those disputes do not separate him from the Nazi regime he helped wage war for. This game does not present him as a hero. It studies battles connected to his career because military systems, command choices, and battlefield pressure shaped real lives. Understanding that history requires looking at operational skill beside the destructive Nazi cause it served.",
                accessibilityIdentifier: "first-run-history-page-guderian",
                requiredTopics: ["Heinz Guderian", "World War II", "Nazi Germany", "Adolf Hitler", "armored warfare", "not present him as a hero"]
            ),
            TutorialPage(
                id: "firstRunHistory-opposition",
                title: "Why You Oppose Him",
                body: "The player commands the opposing forces resisting Guderian's formations, not the formations themselves. That choice matters. It keeps attention on soldiers, staffs, cities, bridges, roads, and civilians caught under the pressure of mechanized attack. The battles are built as problems of defense, delay, withdrawal, counterattack, and survival. You are asked to read terrain, protect objectives, accept hard tradeoffs, and limit the damage of an offensive machine. This perspective lets the game examine Guderian's operational influence without asking the player to celebrate conquest.",
                accessibilityIdentifier: "first-run-history-page-opposition",
                requiredTopics: ["opposing", "defense", "without asking the player to celebrate"]
            ),
            TutorialPage(
                id: "firstRunHistory-battles",
                title: "Why These Battles Matter",
                body: "These battles are memorialized because they show how doctrine becomes consequences. A river crossing, a forest screen, a fortified town, or a retreat corridor can decide whether units escape, whether civilians have time, and whether commanders understand the cost of speed. The campaign follows engagements from Poland, France, the Soviet Union, and later staff contexts to show patterns rather than isolated anecdotes. Each scenario is a small historical question: what was at stake, who had agency, what could be preserved, and what could not be undone?",
                accessibilityIdentifier: "first-run-history-page-battles",
                requiredTopics: ["memorialized", "civilians", "historical question"]
            ),
            TutorialPage(
                id: "firstRunHistory-memorial",
                title: "Memorial, Not Celebration",
                body: "A wargame can accidentally make war feel tidy. This project tries to resist that. Rules, maps, counters, and victory bands are tools for study, not trophies. They help preserve the memory of places where people faced fear, exhaustion, bad information, and impossible orders. The aim is sober memorialization: to make the battles legible while remembering that every clever maneuver had human costs. When you play, treat the board as a historical model and a memorial space. Winning should mean understanding more, not turning suffering into spectacle.",
                accessibilityIdentifier: "first-run-history-page-memorial",
                requiredTopics: ["sober memorialization", "human costs", "not turning suffering into spectacle"]
            ),
        ]
    }

    public static var firstBattleGuidanceHints: [TutorialHint] {
        [
            TutorialHint(
                id: FirstBattleGuidanceHintID.orientation.rawValue,
                trigger: .battleOpened,
                order: 1,
                title: "You Are The Blocking Force",
                body: "This first battle is Tuchola Forest. You command the Polish units trying to slow Guderian's XIX Corps, protect crossings, and preserve withdrawal routes. Think like a delaying commander: force the attack to spend time, keep defenders mutually supporting, and do not chase every German unit.",
                accessibilityIdentifier: "first-battle-tutorial-hint-orientation",
                requiredTopics: ["Tuchola Forest", "Polish", "delaying"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.board.rawValue,
                trigger: .boardVisible,
                order: 2,
                title: "Read The Board Before Acting",
                body: "The map is the main strategy tool. Blue counters are your force, red counters are Guderian's pressure, and numbered markers are objectives. Roads and crossings matter because speed is the German advantage. Use terrain and distance to make each German phase less efficient.",
                accessibilityIdentifier: "first-battle-tutorial-hint-board",
                requiredTopics: ["strategy", "objectives", "terrain"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.selection.rawValue,
                trigger: .unitSelection,
                order: 3,
                title: "Select A Ready Unit",
                body: "Click a blue unit to inspect it. The inspector shows role, remaining wounds, cover state, hull-down state, and historical notes. The selected unit is outlined on the board. Use Next Ready when you want to cycle through units that can still matter this phase.",
                accessibilityIdentifier: "first-battle-tutorial-hint-selection",
                requiredTopics: ["Click", "inspector", "Next Ready"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.objectives.rawValue,
                trigger: .objectiveInspection,
                order: 4,
                title: "Objectives Explain The Plan",
                body: "Open objectives before moving. In Tuchola Forest, the bridges, road hubs, and withdrawal routes are not just labels; they tell you where German tempo must be delayed. A good move often protects an objective indirectly by blocking a road or covering an approach.",
                accessibilityIdentifier: "first-battle-tutorial-hint-objectives",
                requiredTopics: ["objectives", "bridges", "withdrawal"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.movement.rawValue,
                trigger: .movementDrag,
                order: 5,
                title: "Drag To Move, Then Anchor",
                body: "During movement, drag a selected blue unit to a useful position. Short moves are often better than dramatic lunges: keep fields of fire, stay near cover, and leave routes open for later withdrawal. If a move is refused, read the feedback line before trying again.",
                accessibilityIdentifier: "first-battle-tutorial-hint-movement",
                requiredTopics: ["movement", "drag", "feedback"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.phase.rawValue,
                trigger: .phaseAdvance,
                order: 6,
                title: "Phases Set What Is Legal",
                body: "The battle advances through movement, shooting, and assault phases. A command that made sense one moment may be blocked in the next because the phase changed. Use Next Phase deliberately, after checking whether your selected unit still has a useful action.",
                accessibilityIdentifier: "first-battle-tutorial-hint-phase",
                requiredTopics: ["movement", "shooting", "assault"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.shooting.rawValue,
                trigger: .shooting,
                order: 7,
                title: "Shoot To Disrupt, Not To Duel",
                body: "In the shooting phase, pick a target that affects German tempo. Fire at units threatening bridges, roads, or exposed defenders. Damage helps, but pinning and forcing caution also matter. When a weapon or hit allocation choice appears, Resolve Pending keeps play moving.",
                accessibilityIdentifier: "first-battle-tutorial-hint-shooting",
                requiredTopics: ["shooting", "German tempo", "Resolve Pending"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.assault.rawValue,
                trigger: .assault,
                order: 8,
                title: "Assault Is A Commitment",
                body: "Assaults can finish a close fight, but they also expose units. Use them when the board position is worth the risk, such as clearing an approach or buying a turn near an objective. The follow-up toggle decides whether winners advance or consolidate.",
                accessibilityIdentifier: "first-battle-tutorial-hint-assault",
                requiredTopics: ["Assaults", "objective", "follow-up"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.blocked.rawValue,
                trigger: .blockedAction,
                order: 9,
                title: "Blocked Actions Are Useful",
                body: "A blocked action is not just an error. It tells you why the rules rejected an order: wrong phase, no target, movement limit, line of sight, or unavailable unit. Treat that feedback as a rules tutor, then adjust the plan rather than forcing the same command.",
                accessibilityIdentifier: "first-battle-tutorial-hint-blocked",
                requiredTopics: ["blocked action", "rules", "feedback"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.germanAI.rawValue,
                trigger: .germanAITurn,
                order: 10,
                title: "Let The German AI Reveal Pressure",
                body: "German Turn advances Guderian's side through its rules-backed actions. Watch which objective the AI pressures, then plan your next defense around delay and preservation. The aim is not to stop every attack; it is to make speed costly and keep the campaign goals alive.",
                accessibilityIdentifier: "first-battle-tutorial-hint-german-ai",
                requiredTopics: ["German Turn", "AI", "delay"]
            ),
            TutorialHint(
                id: FirstBattleGuidanceHintID.debrief.rawValue,
                trigger: .debrief,
                order: 11,
                title: "Debrief Saves The Lesson",
                body: "The debrief converts the battle into score, victory band, notes, and campaign persistence. Read it as after-action analysis, not just a win screen. If these hints have done their job, use the checkbox here to keep this first-battle tutorial from appearing again.",
                accessibilityIdentifier: "first-battle-tutorial-hint-debrief",
                requiredTopics: ["debrief", "campaign persistence", "checkbox"]
            ),
        ]
    }

    public static let requiredFirstBattleTriggers: [TutorialTrigger] = [
        .battleOpened,
        .boardVisible,
        .unitSelection,
        .objectiveInspection,
        .movementDrag,
        .phaseAdvance,
        .shooting,
        .assault,
        .blockedAction,
        .germanAITurn,
        .debrief,
    ]
}
