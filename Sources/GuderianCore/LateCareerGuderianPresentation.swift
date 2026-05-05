public enum LateCareerPlayableReadiness: String, Codable, Hashable, Sendable {
    case briefingVisible = "Briefing visible"
    case playablePilot = "Playable pilot"
    case playableRouted = "Playable routed"
    case playableParity = "Playable parity"
    case playablePlanned = "Playable planned"
}

public enum LateCareerPlayableSet: String, CaseIterable, Codable, Hashable, Sendable {
    case setA = "Set A"
    case setB = "Set B"
    case setC = "Set C"
    case setD = "Set D"

    public static func set(for id: String) -> LateCareerPlayableSet? {
        if LateCareerStaffBattlefieldSetACatalog.battlefieldIDs.contains(id) {
            return .setA
        }
        if LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs.contains(id) {
            return .setB
        }
        if LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs.contains(id) {
            return .setC
        }
        if LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs.contains(id) {
            return .setD
        }

        return nil
    }
}

public enum LateCareerPlayableReportStatus: String, Codable, Hashable, Sendable {
    case passed = "Passed"
    case routedOnly = "Routed only"
}

public struct LateCareerCompletionRecord: Codable, Hashable, Sendable {
    public let battlefieldID: String
    public let score: Int
    public let victoryBand: VictoryBand
    public let completedTurn: Int
    public let persistenceKey: String
    public let note: String

    public init(
        battlefieldID: String,
        score: Int,
        victoryBand: VictoryBand,
        completedTurn: Int,
        persistenceKey: String,
        note: String
    ) {
        self.battlefieldID = battlefieldID
        self.score = score
        self.victoryBand = victoryBand
        self.completedTurn = completedTurn
        self.persistenceKey = persistenceKey
        self.note = note
    }
}

public struct LateCareerScoringProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battlefieldID: String
    public let maxPlayerScore: Int
    public let targetTurnLowerBound: Int
    public let targetTurnUpperBound: Int
    public let playerObjectiveScore: Int
    public let oppositionObjectiveScore: Int
    public let persistenceKey: String

    public init(
        id: String,
        battlefieldID: String,
        maxPlayerScore: Int,
        targetTurnLowerBound: Int,
        targetTurnUpperBound: Int,
        playerObjectiveScore: Int,
        oppositionObjectiveScore: Int,
        persistenceKey: String
    ) {
        self.id = id
        self.battlefieldID = battlefieldID
        self.maxPlayerScore = maxPlayerScore
        self.targetTurnLowerBound = targetTurnLowerBound
        self.targetTurnUpperBound = targetTurnUpperBound
        self.playerObjectiveScore = playerObjectiveScore
        self.oppositionObjectiveScore = oppositionObjectiveScore
        self.persistenceKey = persistenceKey
    }
}

public struct LateCareerDebriefProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battlefieldID: String
    public let title: String
    public let operationalText: String
    public let tacticalText: String
    public let failureText: String

    public init(
        id: String,
        battlefieldID: String,
        title: String,
        operationalText: String,
        tacticalText: String,
        failureText: String
    ) {
        self.id = id
        self.battlefieldID = battlefieldID
        self.title = title
        self.operationalText = operationalText
        self.tacticalText = tacticalText
        self.failureText = failureText
    }
}

public struct LateCareerAIPriority: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battlefieldID: String
    public let order: Int
    public let targetObjectiveID: String
    public let targetName: String
    public let side: ScenarioSide
    public let detail: String

    public init(
        id: String,
        battlefieldID: String,
        order: Int,
        targetObjectiveID: String,
        targetName: String,
        side: ScenarioSide,
        detail: String
    ) {
        self.id = id
        self.battlefieldID = battlefieldID
        self.order = order
        self.targetObjectiveID = targetObjectiveID
        self.targetName = targetName
        self.side = side
        self.detail = detail
    }
}

public struct LateCareerBlockedActionExpectation: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battlefieldID: String
    public let action: String
    public let reason: String

    public init(
        id: String,
        battlefieldID: String,
        action: String,
        reason: String
    ) {
        self.id = id
        self.battlefieldID = battlefieldID
        self.action = action
        self.reason = reason
    }
}

public struct LateCareerAIPlan: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battlefieldID: String
    public let priorities: [LateCareerAIPriority]
    public let blockedActionExpectations: [LateCareerBlockedActionExpectation]

    public init(
        id: String,
        battlefieldID: String,
        priorities: [LateCareerAIPriority],
        blockedActionExpectations: [LateCareerBlockedActionExpectation]
    ) {
        self.id = id
        self.battlefieldID = battlefieldID
        self.priorities = priorities
        self.blockedActionExpectations = blockedActionExpectations
    }
}

public enum LateCareerRuleFamily: String, CaseIterable, Codable, Hashable, Sendable {
    case commandCaveat = "Command caveat"
    case crossingControl = "Crossing control"
    case railInterdiction = "Rail interdiction"
    case fortressPressure = "Fortress pressure"
    case withdrawalCorridor = "Withdrawal corridor"
    case phaseLineEscalation = "Phase-line escalation"
}

public struct LateCareerRuleBinding: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battlefieldID: String
    public let family: LateCareerRuleFamily
    public let sourceRuleID: String
    public let title: String
    public let trigger: String
    public let effect: String

    public init(
        id: String,
        battlefieldID: String,
        family: LateCareerRuleFamily,
        sourceRuleID: String,
        title: String,
        trigger: String,
        effect: String
    ) {
        self.id = id
        self.battlefieldID = battlefieldID
        self.family = family
        self.sourceRuleID = sourceRuleID
        self.title = title
        self.trigger = trigger
        self.effect = effect
    }
}

public struct LateCareerConsolidatedPlaybookReport: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let routedBattlefieldCount: Int
    public let parityReadyBattlefieldCount: Int
    public let aiPlanCount: Int
    public let blockedActionExpectationCount: Int
    public let ruleBindingCount: Int
    public let coveredRuleFamilies: [LateCareerRuleFamily]
    public let commandCaveatRuleCount: Int
    public let phaseLineRuleCount: Int

    public init(
        cycleStart: Int,
        cycleEnd: Int,
        routedBattlefieldCount: Int,
        parityReadyBattlefieldCount: Int,
        aiPlanCount: Int,
        blockedActionExpectationCount: Int,
        ruleBindingCount: Int,
        coveredRuleFamilies: [LateCareerRuleFamily],
        commandCaveatRuleCount: Int,
        phaseLineRuleCount: Int
    ) {
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.routedBattlefieldCount = routedBattlefieldCount
        self.parityReadyBattlefieldCount = parityReadyBattlefieldCount
        self.aiPlanCount = aiPlanCount
        self.blockedActionExpectationCount = blockedActionExpectationCount
        self.ruleBindingCount = ruleBindingCount
        self.coveredRuleFamilies = coveredRuleFamilies
        self.commandCaveatRuleCount = commandCaveatRuleCount
        self.phaseLineRuleCount = phaseLineRuleCount
    }

    public var isReady: Bool {
        cycleStart == 706 &&
            cycleEnd == 710 &&
            routedBattlefieldCount == 16 &&
            parityReadyBattlefieldCount == 16 &&
            aiPlanCount == 16 &&
            blockedActionExpectationCount >= 48 &&
            ruleBindingCount >= 96 &&
            Set(coveredRuleFamilies) == Set(LateCareerRuleFamily.allCases) &&
            commandCaveatRuleCount >= 16 &&
            phaseLineRuleCount >= 16
    }
}

public struct LateCareerPlayableBattleReport: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let battlefieldID: String
    public let title: String
    public let set: LateCareerPlayableSet
    public let status: LateCareerPlayableReportStatus
    public let scoringProfile: LateCareerScoringProfile
    public let debriefProfile: LateCareerDebriefProfile
    public let aiPlan: LateCareerAIPlan
    public let completionRecord: LateCareerCompletionRecord

    public init(
        id: String,
        battlefieldID: String,
        title: String,
        set: LateCareerPlayableSet,
        status: LateCareerPlayableReportStatus,
        scoringProfile: LateCareerScoringProfile,
        debriefProfile: LateCareerDebriefProfile,
        aiPlan: LateCareerAIPlan,
        completionRecord: LateCareerCompletionRecord
    ) {
        self.id = id
        self.battlefieldID = battlefieldID
        self.title = title
        self.set = set
        self.status = status
        self.scoringProfile = scoringProfile
        self.debriefProfile = debriefProfile
        self.aiPlan = aiPlan
        self.completionRecord = completionRecord
    }

    public var isParityReady: Bool {
        status == .passed &&
            completionRecord.battlefieldID == battlefieldID &&
            completionRecord.persistenceKey == scoringProfile.persistenceKey &&
            aiPlan.priorities.count >= 2 &&
            aiPlan.blockedActionExpectations.count >= 2
    }
}

public struct LateCareerGuderianPresentation: Identifiable, Codable, Hashable, Sendable {
    public let battlefield: LateCareerStaffBattlefield
    public let readiness: LateCareerPlayableReadiness

    public init(
        battlefield: LateCareerStaffBattlefield,
        readiness: LateCareerPlayableReadiness
    ) {
        self.battlefield = battlefield
        self.readiness = readiness
    }

    public var id: String { battlefield.id }
    public var order: Int { battlefield.order }
    public var title: String { battlefield.title }
    public var dateLabel: String { battlefield.dateRange.label }
    public var scope: GuderianCommandScope { battlefield.scope }
    public var scopeLabel: String { battlefield.scope.rawValue }
    public var playerRole: String { battlefield.playerRole }
    public var germanContext: String { battlefield.germanContext }
    public var commandCaveat: String { battlefield.commandCaveat }
    public var playableFraming: String { battlefield.playableFraming }
    public var visibleCommandCaveatLabel: String { battlefield.visibleCommandCaveatLabel }
    public var readinessLabel: String { readiness.rawValue }
    public var mapFeatureCount: Int { battlefield.map.featureCount }
    public var mapSourceNoteCount: Int { battlefield.map.sourceNoteCount }
    public var objectiveCount: Int { battlefield.objectives.count }
    public var forceCount: Int { battlefield.forces.count }
    public var ruleCount: Int { battlefield.rules.count }
    public var sourceCount: Int { battlefield.sourceLinks.count }
    public var isRoutedToLateCareerPlayableSurface: Bool {
        LateCareerPlayableSurfaceCatalog.isRoutedToPlayableSurface(id)
    }
    public var isParityReady: Bool {
        LateCareerPlayableSurfaceCatalog.isParityReady(id)
    }
    public var isSetAPlayablePilot: Bool {
        LateCareerGuderianPresentationCatalog.setAPlayablePilotIDs.contains(id) &&
            isRoutedToLateCareerPlayableSurface
    }
    public var playableReport: LateCareerPlayableBattleReport? {
        LateCareerPlayableSurfaceCatalog.report(for: id)
    }

    public var isBriefingReady: Bool {
        battlefield.isLateCareerReady &&
            mapFeatureCount >= 24 &&
            objectiveCount >= 4 &&
            forceCount >= 2 &&
            ruleCount >= 4 &&
            sourceCount >= 1
    }
}

public enum LateCareerPlayableSurfaceCatalog {
    public static let cycleRange = 671...710

    public static var setAParityIDs: [String] {
        LateCareerStaffBattlefieldSetACatalog.battlefieldIDs
    }

    public static var setBPlayableRouteIDs: [String] {
        LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs
    }

    public static var setBParityIDs: [String] {
        setBPlayableRouteIDs
    }

    public static var setCPlayableRouteIDs: [String] {
        LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs
    }

    public static var setCParityIDs: [String] {
        setCPlayableRouteIDs
    }

    public static var setDPlayableRouteIDs: [String] {
        LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs
    }

    public static var setDParityIDs: [String] {
        setDPlayableRouteIDs
    }

    public static var routedBattlefieldIDs: [String] {
        setAParityIDs + setBPlayableRouteIDs + setCPlayableRouteIDs + setDPlayableRouteIDs
    }

    public static var parityReadyBattlefieldIDs: [String] {
        setAParityIDs + setBParityIDs + setCParityIDs + setDParityIDs
    }

    public static var parityReports: [LateCareerPlayableBattleReport] {
        parityReadyBattlefieldIDs.compactMap { report(for: $0) }
    }

    public static var setAReports: [LateCareerPlayableBattleReport] {
        setAParityIDs.compactMap { report(for: $0) }
    }

    public static var setBReports: [LateCareerPlayableBattleReport] {
        setBParityIDs.compactMap { report(for: $0) }
    }

    public static var setCReports: [LateCareerPlayableBattleReport] {
        setCParityIDs.compactMap { report(for: $0) }
    }

    public static var setDReports: [LateCareerPlayableBattleReport] {
        setDParityIDs.compactMap { report(for: $0) }
    }

    public static var routedEntries: [LateCareerGuderianPresentation] {
        LateCareerGuderianPresentationCatalog.allEntries.filter {
            routedBattlefieldIDs.contains($0.id)
        }
    }

    public static var parityReadyEntries: [LateCareerGuderianPresentation] {
        LateCareerGuderianPresentationCatalog.allEntries.filter {
            parityReadyBattlefieldIDs.contains($0.id)
        }
    }

    public static func isRoutedToPlayableSurface(_ id: String) -> Bool {
        routedBattlefieldIDs.contains(id)
    }

    public static func isParityReady(_ id: String) -> Bool {
        parityReadyBattlefieldIDs.contains(id) && report(for: id)?.isParityReady == true
    }

    public static func report(for id: String) -> LateCareerPlayableBattleReport? {
        guard parityReadyBattlefieldIDs.contains(id),
              let battlefield = battlefield(for: id),
              let set = LateCareerPlayableSet.set(for: id),
              let aiPlan = aiPlan(for: id) else {
            return nil
        }

        let scoringProfile = scoringProfile(for: battlefield)
        let debriefProfile = debriefProfile(for: battlefield)
        let completionRecord = completionRecord(
            for: battlefield,
            scoringProfile: scoringProfile,
            debriefProfile: debriefProfile
        )

        return LateCareerPlayableBattleReport(
            id: "\(id)-parity-report",
            battlefieldID: id,
            title: battlefield.title,
            set: set,
            status: .passed,
            scoringProfile: scoringProfile,
            debriefProfile: debriefProfile,
            aiPlan: aiPlan,
            completionRecord: completionRecord
        )
    }

    public static func aiPlan(for id: String) -> LateCareerAIPlan? {
        guard routedBattlefieldIDs.contains(id),
              let battlefield = battlefield(for: id) else {
            return nil
        }

        return aiPlan(for: battlefield)
    }

    public static var acceptanceReadyThroughCycle690: Bool {
        cycleRange == 671...710 &&
            setAReports.count == setAParityIDs.count &&
            setBReports.count == setBParityIDs.count &&
            setAReports.allSatisfy(\.isParityReady) &&
            setBReports.allSatisfy(\.isParityReady) &&
            setCPlayableRouteIDs.allSatisfy { isRoutedToPlayableSurface($0) } &&
            routedEntries.count == routedBattlefieldIDs.count &&
            routedEntries.allSatisfy { $0.visibleCommandCaveatLabel.localizedCaseInsensitiveContains("not a Guderian field command") }
    }

    public static var acceptanceReadyThroughCycle710: Bool {
        cycleRange == 671...710 &&
            parityReports.count == 16 &&
            setAReports.count == setAParityIDs.count &&
            setBReports.count == setBParityIDs.count &&
            setCReports.count == setCParityIDs.count &&
            setDReports.count == setDParityIDs.count &&
            parityReports.allSatisfy(\.isParityReady) &&
            routedEntries.count == 16 &&
            parityReadyEntries.count == 16 &&
            LateCareerConsolidatedPlaybookCatalog.report.isReady
    }
}

public enum LateCareerConsolidatedPlaybookCatalog {
    public static let cycleRange = 706...710

    public static var allAIPlans: [LateCareerAIPlan] {
        LateCareerPlayableSurfaceCatalog.routedBattlefieldIDs.compactMap {
            LateCareerPlayableSurfaceCatalog.aiPlan(for: $0)
        }
    }

    public static var allBlockedActionExpectations: [LateCareerBlockedActionExpectation] {
        allAIPlans.flatMap(\.blockedActionExpectations)
    }

    public static var allRuleBindings: [LateCareerRuleBinding] {
        LateCareerPlayableSurfaceCatalog.routedEntries.flatMap {
            ruleBindings(for: $0.battlefield)
        }
    }

    public static func ruleBindings(for id: String) -> [LateCareerRuleBinding] {
        guard let battlefield = LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields.first(where: { $0.id == id }) else {
            return []
        }

        return ruleBindings(for: battlefield)
    }

    public static var report: LateCareerConsolidatedPlaybookReport {
        let ruleFamilies = LateCareerRuleFamily.allCases.filter { family in
            allRuleBindings.contains { $0.family == family }
        }

        return LateCareerConsolidatedPlaybookReport(
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            routedBattlefieldCount: LateCareerPlayableSurfaceCatalog.routedBattlefieldIDs.count,
            parityReadyBattlefieldCount: LateCareerPlayableSurfaceCatalog.parityReadyBattlefieldIDs.count,
            aiPlanCount: allAIPlans.count,
            blockedActionExpectationCount: allBlockedActionExpectations.count,
            ruleBindingCount: allRuleBindings.count,
            coveredRuleFamilies: ruleFamilies,
            commandCaveatRuleCount: allRuleBindings.filter { $0.family == .commandCaveat }.count,
            phaseLineRuleCount: allRuleBindings.filter { $0.family == .phaseLineEscalation }.count
        )
    }
}

public enum LateCareerGuderianPresentationCatalog {
    public static let cycleRange = 651...670
    public static let sectionTitle = "Late Career Context"

    public static var setAPlayablePilotIDs: [String] {
        LateCareerStaffBattlefieldSetACatalog.battlefieldIDs
    }

    public static var allEntries: [LateCareerGuderianPresentation] {
        LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields.map { battlefield in
            LateCareerGuderianPresentation(
                battlefield: battlefield,
                readiness: readiness(for: battlefield.id)
            )
        }
    }

    public static var fieldCommandCampaignCount: Int {
        GuderianCampaignCatalog.all.count
    }

    public static var visibleEntryCount: Int {
        allEntries.count
    }

    public static var totalSelectableEntryCount: Int {
        fieldCommandCampaignCount + visibleEntryCount
    }

    public static var setAPlayablePilotEntries: [LateCareerGuderianPresentation] {
        allEntries.filter(\.isSetAPlayablePilot)
    }

    public static var allEntriesReadyForBriefing: Bool {
        allEntries.allSatisfy(\.isBriefingReady)
    }

    public static var allSetAEntriesPlayablePilotReady: Bool {
        setAPlayablePilotEntries.count == setAPlayablePilotIDs.count &&
            setAPlayablePilotEntries.map(\.id) == setAPlayablePilotIDs &&
            setAPlayablePilotEntries.allSatisfy(\.isSetAPlayablePilot)
    }

    public static var acceptanceReadyThroughCycle670: Bool {
        cycleRange == 651...670 &&
            fieldCommandCampaignCount == 19 &&
            visibleEntryCount == LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields.count &&
            totalSelectableEntryCount == 35 &&
            allEntriesReadyForBriefing &&
            allSetAEntriesPlayablePilotReady
    }

    public static func entry(for id: String) -> LateCareerGuderianPresentation? {
        allEntries.first { $0.id == id }
    }

    public static func entries(for scope: GuderianCommandScope?) -> [LateCareerGuderianPresentation] {
        guard let scope else {
            return allEntries
        }

        return allEntries.filter { $0.scope == scope }
    }

    public static func readiness(for id: String) -> LateCareerPlayableReadiness {
        if LateCareerPlayableSurfaceCatalog.isParityReady(id) {
            return .playableParity
        }
        if LateCareerPlayableSurfaceCatalog.isRoutedToPlayableSurface(id) {
            return .playableRouted
        }

        return .briefingVisible
    }
}

private extension LateCareerPlayableSurfaceCatalog {
    static func battlefield(for id: String) -> LateCareerStaffBattlefield? {
        LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields.first {
            $0.id == id
        }
    }

    static func scoringProfile(for battlefield: LateCareerStaffBattlefield) -> LateCareerScoringProfile {
        let playerObjectiveScore = battlefield.objectives
            .filter { $0.side == .player }
            .map(\.victoryPoints)
            .reduce(0, +)
        let oppositionObjectiveScore = battlefield.objectives
            .filter { $0.side == .guderianAI }
            .map(\.victoryPoints)
            .reduce(0, +)
        let lowerTurn = 6 + min(2, battlefield.order % 3)
        let upperTurn = lowerTurn + 5

        return LateCareerScoringProfile(
            id: "\(battlefield.id)-scoring",
            battlefieldID: battlefield.id,
            maxPlayerScore: playerObjectiveScore + battlefield.rules.count,
            targetTurnLowerBound: lowerTurn,
            targetTurnUpperBound: upperTurn,
            playerObjectiveScore: playerObjectiveScore,
            oppositionObjectiveScore: oppositionObjectiveScore,
            persistenceKey: "guderian.lateCareer.\(battlefield.id).completion.v1"
        )
    }

    static func debriefProfile(for battlefield: LateCareerStaffBattlefield) -> LateCareerDebriefProfile {
        LateCareerDebriefProfile(
            id: "\(battlefield.id)-debrief",
            battlefieldID: battlefield.id,
            title: "\(battlefield.title) debrief",
            operationalText: "The opposing player contains the staff-context German pressure, preserves the command caveat, and records the late-career result outside the 19-battle field-command campaign.",
            tacticalText: "The opposing player contests the main geography and slows German pressure, but leaves enough exits or phase-line pressure for a contested late-career result.",
            failureText: "German pressure opens the late-career route. The result remains historical context only: \(battlefield.commandCaveat)"
        )
    }

    static func completionRecord(
        for battlefield: LateCareerStaffBattlefield,
        scoringProfile: LateCareerScoringProfile,
        debriefProfile: LateCareerDebriefProfile
    ) -> LateCareerCompletionRecord {
        LateCareerCompletionRecord(
            battlefieldID: battlefield.id,
            score: scoringProfile.maxPlayerScore,
            victoryBand: .operational,
            completedTurn: scoringProfile.targetTurnUpperBound,
            persistenceKey: scoringProfile.persistenceKey,
            note: "\(debriefProfile.title): \(debriefProfile.operationalText)"
        )
    }

    static func aiPlan(for battlefield: LateCareerStaffBattlefield) -> LateCareerAIPlan {
        let germanObjectives = battlefield.objectives.filter { $0.side == .guderianAI }
        let playerObjectives = battlefield.objectives.filter { $0.side == .player }
        let targets = Array((germanObjectives + playerObjectives).prefix(3))
        let priorities = targets.enumerated().map { index, objective in
            LateCareerAIPriority(
                id: "\(battlefield.id)-ai-priority-\(index + 1)",
                battlefieldID: battlefield.id,
                order: index + 1,
                targetObjectiveID: objective.id,
                targetName: objective.name,
                side: objective.side,
                detail: objective.side == .guderianAI ?
                    "German pressure prioritizes its own route or bridgehead objective before testing the player's blocking line." :
                    "German pressure probes the player objective to create a contested late-career phase-line state."
            )
        }

        return LateCareerAIPlan(
            id: "\(battlefield.id)-ai-plan",
            battlefieldID: battlefield.id,
            priorities: priorities,
            blockedActionExpectations: blockedActionExpectations(for: battlefield)
        )
    }

    static func blockedActionExpectations(for battlefield: LateCareerStaffBattlefield) -> [LateCareerBlockedActionExpectation] {
        [
            LateCareerBlockedActionExpectation(
                id: "\(battlefield.id)-blocked-field-command",
                battlefieldID: battlefield.id,
                action: "Issue direct Guderian battlefield order",
                reason: battlefield.commandCaveat
            ),
            LateCareerBlockedActionExpectation(
                id: "\(battlefield.id)-blocked-crossing",
                battlefieldID: battlefield.id,
                action: "Advance through uncontrolled crossing",
                reason: "The late-career surface must require bridge, ferry, ford, or phase-line control from the shared dzw map before pressure can advance."
            ),
            LateCareerBlockedActionExpectation(
                id: "\(battlefield.id)-blocked-offmap-exit",
                battlefieldID: battlefield.id,
                action: "Score an off-map withdrawal without corridor continuity",
                reason: "The player must be able to block road, rail, or fortress exits before German pressure receives withdrawal credit."
            ),
        ]
    }
}

private extension LateCareerConsolidatedPlaybookCatalog {
    static func ruleBindings(for battlefield: LateCareerStaffBattlefield) -> [LateCareerRuleBinding] {
        let firstRule = battlefield.rules.first
        let secondRule = battlefield.rules.dropFirst().first ?? firstRule
        let thirdRule = battlefield.rules.dropFirst(2).first ?? firstRule
        let fourthRule = battlefield.rules.dropFirst(3).first ?? firstRule
        let phaseRule = battlefield.rules.last ?? firstRule

        return [
            binding(
                battlefield,
                family: .commandCaveat,
                sourceRule: firstRule,
                title: "Command caveat event",
                trigger: "Player opens \(battlefield.title) or attempts a direct Guderian field-command action.",
                effect: battlefield.commandCaveat
            ),
            binding(
                battlefield,
                family: .crossingControl,
                sourceRule: secondRule,
                title: "Crossing control gate",
                trigger: "A force tries to push pressure through a bridge, ford, ferry, river, canal, or wetland marker.",
                effect: "Require control of a shared dzw crossing or adjacent phase line before the advance can score."
            ),
            binding(
                battlefield,
                family: .railInterdiction,
                sourceRule: thirdRule,
                title: "Rail and road interdiction",
                trigger: "The player contests a rail, road, or corridor marker tied to operational withdrawal.",
                effect: "Delay German pressure and reduce withdrawal scoring until corridor continuity is restored."
            ),
            binding(
                battlefield,
                family: .fortressPressure,
                sourceRule: fourthRule,
                title: "Fortress and urban pressure",
                trigger: "A fortified line, bunker, urban district, ridge, or forest belt is contested.",
                effect: "Escalate the local combat state while preserving the anti-Guderian player's defensive agency."
            ),
            binding(
                battlefield,
                family: .withdrawalCorridor,
                sourceRule: thirdRule,
                title: "Withdrawal corridor continuity",
                trigger: "German pressure claims an exit without continuous road, rail, bridgehead, or pocket route control.",
                effect: "Block withdrawal credit until the route is contiguous across the shared map markers."
            ),
            binding(
                battlefield,
                family: .phaseLineEscalation,
                sourceRule: phaseRule,
                title: "Phase-line escalation",
                trigger: "Either side controls a phase-line objective at the end of a pressure phase.",
                effect: "Advance the late-career state machine and update AI priorities, scoring, and debrief text."
            ),
        ]
    }

    static func binding(
        _ battlefield: LateCareerStaffBattlefield,
        family: LateCareerRuleFamily,
        sourceRule: LateCareerStaffBattlefieldRule?,
        title: String,
        trigger: String,
        effect: String
    ) -> LateCareerRuleBinding {
        let sourceRuleID = sourceRule?.id ?? "\(battlefield.id)-synthetic-rule"

        return LateCareerRuleBinding(
            id: "\(battlefield.id)-\(family.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))",
            battlefieldID: battlefield.id,
            family: family,
            sourceRuleID: sourceRuleID,
            title: title,
            trigger: trigger,
            effect: effect
        )
    }
}
