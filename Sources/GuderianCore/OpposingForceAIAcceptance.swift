import Foundation

public struct OpposingForceAIFieldCommandAudit: Identifiable, Codable, Hashable, Sendable {
    public let id: GuderianBattleID
    public let title: String
    public let armyFamily: OpposingForceAIArmyFamily
    public let behaviorProfile: OpposingForceAIBehaviorProfile
    public let movementPriorityNames: [String]
    public let shootingPriorityNames: [String]
    public let assaultPriorityNames: [String]
    public let visibleReasoning: [String]
    public let guderianCommandSelected: Bool
    public let completedToDebrief: Bool
    public let opposingStepCount: Int
    public let germanStepCount: Int
    public let opposingRunDetails: [String]

    public init(
        id: GuderianBattleID,
        title: String,
        armyFamily: OpposingForceAIArmyFamily,
        behaviorProfile: OpposingForceAIBehaviorProfile,
        movementPriorityNames: [String],
        shootingPriorityNames: [String],
        assaultPriorityNames: [String],
        visibleReasoning: [String],
        guderianCommandSelected: Bool,
        completedToDebrief: Bool,
        opposingStepCount: Int,
        germanStepCount: Int,
        opposingRunDetails: [String]
    ) {
        self.id = id
        self.title = title
        self.armyFamily = armyFamily
        self.behaviorProfile = behaviorProfile
        self.movementPriorityNames = movementPriorityNames
        self.shootingPriorityNames = shootingPriorityNames
        self.assaultPriorityNames = assaultPriorityNames
        self.visibleReasoning = visibleReasoning
        self.guderianCommandSelected = guderianCommandSelected
        self.completedToDebrief = completedToDebrief
        self.opposingStepCount = opposingStepCount
        self.germanStepCount = germanStepCount
        self.opposingRunDetails = opposingRunDetails
    }

    public var hasPhaseAwarePriorities: Bool {
        !movementPriorityNames.isEmpty &&
            !shootingPriorityNames.isEmpty &&
            !assaultPriorityNames.isEmpty
    }

    public var hasVisibleReasoning: Bool {
        visibleReasoning.count >= 3 &&
            visibleReasoning.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } &&
            opposingRunDetails.contains {
                $0.localizedCaseInsensitiveContains("priority target") &&
                    $0.localizedCaseInsensitiveContains("Reason:")
            }
    }

    public var guderianCommandAutoplayReady: Bool {
        guderianCommandSelected &&
            completedToDebrief &&
            opposingStepCount > 0 &&
            germanStepCount > 0
    }

    public var behaviorSignature: String {
        [
            armyFamily.rawValue,
            behaviorProfile.rawValue,
            movementPriorityNames.first ?? "",
            shootingPriorityNames.first ?? "",
            assaultPriorityNames.first ?? "",
        ].joined(separator: " | ")
    }

    public var isReady: Bool {
        hasPhaseAwarePriorities &&
            hasVisibleReasoning &&
            guderianCommandAutoplayReady
    }
}

public struct OpposingForceAILateCareerAudit: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let armyFamily: OpposingForceAIArmyFamily
    public let behaviorProfile: OpposingForceAIBehaviorProfile
    public let priorityNames: [String]
    public let priorityDetails: [String]
    public let blockedActionReasons: [String]
    public let commandCaveat: String

    public init(
        id: String,
        title: String,
        armyFamily: OpposingForceAIArmyFamily,
        behaviorProfile: OpposingForceAIBehaviorProfile,
        priorityNames: [String],
        priorityDetails: [String],
        blockedActionReasons: [String],
        commandCaveat: String
    ) {
        self.id = id
        self.title = title
        self.armyFamily = armyFamily
        self.behaviorProfile = behaviorProfile
        self.priorityNames = priorityNames
        self.priorityDetails = priorityDetails
        self.blockedActionReasons = blockedActionReasons
        self.commandCaveat = commandCaveat
    }

    public var behaviorSignature: String {
        [
            armyFamily.rawValue,
            behaviorProfile.rawValue,
            priorityNames.prefix(2).joined(separator: " -> "),
        ].joined(separator: " | ")
    }

    public var isReady: Bool {
        armyFamily == .lateWarSovietAllied &&
            priorityNames.count >= 2 &&
            priorityDetails.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } &&
            !blockedActionReasons.isEmpty &&
            commandCaveat.localizedCaseInsensitiveContains("not a Guderian field command")
    }
}

public struct OpposingForceAIAcceptanceReport: Codable, Hashable, Sendable {
    public let cycleStart: Int
    public let cycleEnd: Int
    public let fieldCommandAudits: [OpposingForceAIFieldCommandAudit]
    public let lateCareerAudits: [OpposingForceAILateCareerAudit]
    public let blockers: [String]

    public init(
        cycleStart: Int,
        cycleEnd: Int,
        fieldCommandAudits: [OpposingForceAIFieldCommandAudit],
        lateCareerAudits: [OpposingForceAILateCareerAudit],
        blockers: [String]
    ) {
        self.cycleStart = cycleStart
        self.cycleEnd = cycleEnd
        self.fieldCommandAudits = fieldCommandAudits
        self.lateCareerAudits = lateCareerAudits
        self.blockers = blockers
    }

    public var fieldCommandBattleCount: Int {
        fieldCommandAudits.count
    }

    public var lateCareerBattleCount: Int {
        lateCareerAudits.count
    }

    public var coveredArmyFamilies: [OpposingForceAIArmyFamily] {
        OpposingForceAIArmyFamily.allCasesInAcceptanceOrder.filter { family in
            fieldCommandAudits.contains { $0.armyFamily == family } ||
                lateCareerAudits.contains { $0.armyFamily == family }
        }
    }

    public var requiredArmyFamiliesCovered: Bool {
        OpposingForceAIArmyFamily.requiredForCycle1120.allSatisfy { coveredArmyFamilies.contains($0) }
    }

    public var uniqueFieldCommandBehaviorSignatureCount: Int {
        Set(fieldCommandAudits.map(\.behaviorSignature)).count
    }

    public var uniqueLateCareerBehaviorSignatureCount: Int {
        Set(lateCareerAudits.map(\.behaviorSignature)).count
    }

    public var allFieldCommandGuderianSideRunsReachDebrief: Bool {
        fieldCommandAudits.allSatisfy(\.guderianCommandAutoplayReady)
    }

    public var visibleReasoningReady: Bool {
        fieldCommandAudits.allSatisfy(\.hasVisibleReasoning) &&
            lateCareerAudits.allSatisfy(\.isReady)
    }

    public var isReady: Bool {
        cycleStart == 1101 &&
            cycleEnd == 1120 &&
            blockers.isEmpty &&
            fieldCommandBattleCount == 19 &&
            lateCareerBattleCount == 16 &&
            requiredArmyFamiliesCovered &&
            allFieldCommandGuderianSideRunsReachDebrief &&
            visibleReasoningReady
    }
}

public enum OpposingForceAIAcceptanceCatalog {
    public static let cycleRange = 1101...1120

    public static var report: OpposingForceAIAcceptanceReport {
        let campaignResult: PlayableTestGameCampaignResult?
        let campaignFailure: String?
        do {
            campaignResult = try PlayableTestGameRunner.runGuderianCommandCampaign()
            campaignFailure = nil
        } catch {
            campaignResult = nil
            campaignFailure = "Guderian-command field campaign harness failed: \(error)"
        }

        let resultsByID = Dictionary(
            uniqueKeysWithValues: (campaignResult?.results ?? []).map { ($0.id, $0) }
        )
        let fieldAudits = GuderianCampaignCatalog.all.map { scenario in
            fieldCommandAudit(for: scenario, result: resultsByID[scenario.id])
        }
        let lateAudits = LateCareerPlayableSurfaceCatalog.parityReports.compactMap(lateCareerAudit(for:))
        let blockers = blockers(
            fieldAudits: fieldAudits,
            lateAudits: lateAudits,
            campaignFailure: campaignFailure
        )

        return OpposingForceAIAcceptanceReport(
            cycleStart: cycleRange.lowerBound,
            cycleEnd: cycleRange.upperBound,
            fieldCommandAudits: fieldAudits,
            lateCareerAudits: lateAudits,
            blockers: blockers
        )
    }

    private static func fieldCommandAudit(
        for scenario: GuderianScenario,
        result: PlayableTestGameBattleResult?
    ) -> OpposingForceAIFieldCommandAudit {
        let plan = OpposingForceAIPlanCatalog.plan(for: scenario)
        let opposingDetails = result?.steps
            .filter { $0.controller == .antiGuderian }
            .map(\.detail) ?? []

        return OpposingForceAIFieldCommandAudit(
            id: scenario.id,
            title: scenario.title,
            armyFamily: plan.armyFamily,
            behaviorProfile: plan.behaviorProfile,
            movementPriorityNames: plan.targetPriorities(for: .movement),
            shootingPriorityNames: plan.targetPriorities(for: .shooting),
            assaultPriorityNames: plan.targetPriorities(for: .assault),
            visibleReasoning: plan.orders.map { "\($0.target): \($0.instruction)" },
            guderianCommandSelected: result != nil,
            completedToDebrief: result?.completedToEnd ?? false,
            opposingStepCount: result?.antiGuderianStepCount ?? 0,
            germanStepCount: result?.germanStepCount ?? 0,
            opposingRunDetails: Array(opposingDetails.prefix(8))
        )
    }

    private static func lateCareerAudit(
        for report: LateCareerPlayableBattleReport
    ) -> OpposingForceAILateCareerAudit? {
        guard let entry = LateCareerGuderianPresentationCatalog.entry(for: report.battlefieldID) else {
            return nil
        }

        return OpposingForceAILateCareerAudit(
            id: report.battlefieldID,
            title: report.title,
            armyFamily: .lateWarSovietAllied,
            behaviorProfile: lateCareerBehaviorProfile(for: report),
            priorityNames: report.aiPlan.priorityNames(for: .movement),
            priorityDetails: report.aiPlan.priorities.map(\.detail),
            blockedActionReasons: report.aiPlan.blockedActionExpectations.map(\.reason),
            commandCaveat: entry.visibleCommandCaveatLabel
        )
    }

    private static func lateCareerBehaviorProfile(
        for report: LateCareerPlayableBattleReport
    ) -> OpposingForceAIBehaviorProfile {
        let text = (
            [report.battlefieldID, report.title] +
                report.aiPlan.priorities.map(\.targetName)
        ).joined(separator: " ").lowercased()

        if text.contains("counterstroke") || text.contains("counterattack") {
            return .counterattack
        }
        if text.contains("pocket") || text.contains("escape") || text.contains("withdrawal") {
            return .breakout
        }
        if text.contains("fortress") || text.contains("urban") || text.contains("heights") {
            return .urbanDefense
        }
        if text.contains("bridgehead") || text.contains("crossing") || text.contains("lodgment") {
            return .fortifiedDelay
        }
        return .mobileDelay
    }

    private static func blockers(
        fieldAudits: [OpposingForceAIFieldCommandAudit],
        lateAudits: [OpposingForceAILateCareerAudit],
        campaignFailure: String?
    ) -> [String] {
        var blockers: [String] = []
        if let campaignFailure {
            blockers.append(campaignFailure)
        }
        if fieldAudits.count != 19 {
            blockers.append("Field-command opposing AI coverage is \(fieldAudits.count), expected 19.")
        }
        if lateAudits.count != 16 {
            blockers.append("Late-career opposing AI coverage is \(lateAudits.count), expected 16.")
        }
        if fieldAudits.contains(where: { !$0.isReady }) {
            blockers.append("At least one field-command opposing AI audit is not ready.")
        }
        if lateAudits.contains(where: { !$0.isReady }) {
            blockers.append("At least one late-career AI audit is not ready.")
        }

        let coveredFamilies = OpposingForceAIArmyFamily.allCasesInAcceptanceOrder.filter { family in
            fieldAudits.contains { $0.armyFamily == family } ||
                lateAudits.contains { $0.armyFamily == family }
        }
        for family in OpposingForceAIArmyFamily.requiredForCycle1120 where !coveredFamilies.contains(family) {
            blockers.append("Missing opposing-force AI family coverage for \(family.rawValue).")
        }

        if Set(fieldAudits.map(\.behaviorSignature)).count < fieldAudits.count {
            blockers.append("Field-command opposing AI behavior signatures are not battle-distinct.")
        }
        if Set(lateAudits.map(\.behaviorSignature)).count < 8 {
            blockers.append("Late-career AI behavior signatures are too uniform.")
        }

        return blockers
    }
}

private extension OpposingForceAIArmyFamily {
    static let requiredForCycle1120: [OpposingForceAIArmyFamily] = [
        .polish,
        .french,
        .alliedPortDefense,
        .soviet1941,
        .sovietWinter,
        .lateWarSovietAllied,
    ]

    static let allCasesInAcceptanceOrder: [OpposingForceAIArmyFamily] = [
        .polish,
        .french,
        .alliedPortDefense,
        .soviet1941,
        .sovietWinter,
        .lateWarSovietAllied,
        .generic,
    ]
}
