import Foundation
import XCTest
@testable import GuderianCore

private struct ReviewLocalHardeningItem {
    let id: Int
    let title: String
    let owner: String
    let targetCycles: ClosedRange<Int>
}

private enum ReviewLocalHardeningPlan {
    static let localRoot = "/Users/barbalet/github/guderian"
    static let siblingUpstreamRoot = "/Users/barbalet/github/derZweiteWeltkrieg"

    static let items: [ReviewLocalHardeningItem] = [
        item(1, "Board dimensions single source", "guderian/dzw core and battle UI", 966...970),
        item(2, "Acceptance gates move to tests", "GuderianTests", 991...995),
        item(3, "Scenario map feature sets", "guderian/dzw ScenarioMapLayout", 971...975),
        item(4, "Marsh category ownership", "guderian/dzw ScenarioMapLayout", 971...975),
        item(5, "Unified battle catalog caching", "GuderianCore", 976...980),
        item(6, "Scenario content catalog caching", "guderian/dzw ScenarioContentCatalog", 976...980),
        item(7, "Tutorial content protocol", "GuderianCore tutorials", 981...985),
        item(8, "First battle flow stub removal", "GuderianCore tutorials", 986...990),
        item(9, "Named battlefield colors", "GuderianApp presentation", 996...1000),
        item(10, "Late career filter titles", "GuderianApp campaign view", 996...1000),
        item(11, "GameController state reduction", "guderian/dzw app view model", 1036...1045),
        item(12, "Debug-only window snapshots", "GuderianApp battle view", 1066...1070),
        item(13, "Playable board snapshot API", "GuderianApp battle session protocol", 1001...1005),
        item(14, "Late career set lookup index", "GuderianCore late career", 1006...1010),
        item(15, "Tutorial hint event authority", "GuderianCore tutorials", 1006...1010),
        item(16, "Typed tutorial and hint IDs", "GuderianCore tutorials", 986...990),
        item(17, "Typed unified battle ID storage", "GuderianCore unified catalog", 1011...1015),
        item(18, "Guderian module boundary", "guderian package and embedded dzw", 1046...1055),
        item(19, "HEINZ_GUDERIAN_GAME documentation", "README and guarded dzw hook", 966...970),
        item(20, "German AI plan truthfulness", "guderian/dzw AI catalog and runners", 1056...1060),
        item(21, "Campaign save key consolidation", "GuderianApp campaign persistence", 1016...1020),
        item(22, "Scenario map grid constants", "GuderianApp scenario map", 996...1000),
        item(23, "GuderianCore re-export rationale", "GuderianCore module shell", 1061...1065),
        item(24, "Battlefield viewport filename", "GuderianApp file hygiene", 1061...1065),
        item(25, "Discardable result diagnostics", "GuderianCore and GuderianApp runners", 1031...1035),
        item(26, "GameController Sendable", "guderian/dzw app view model", 1036...1040),
        item(27, "Typed automation stages", "guderian/dzw automation runner", 1026...1030),
        item(28, "Scenario map renderable visibility", "GuderianApp or GuderianCore map API", 1061...1065),
        item(29, "Campaign progress persistence tests", "GuderianTests", 1021...1025),
        item(30, "Window routing cleanup", "guderian/dzw and GuderianApp shell", 1066...1075),
    ]

    private static func item(
        _ id: Int,
        _ title: String,
        _ owner: String,
        _ targetCycles: ClosedRange<Int>
    ) -> ReviewLocalHardeningItem {
        ReviewLocalHardeningItem(id: id, title: title, owner: owner, targetCycles: targetCycles)
    }
}

extension UnifiedGuderianBattleCatalog {
    static var acceptanceReadyThroughCycle740: Bool {
        cycleRange == 736...740 &&
            allEntries.count == 35 &&
            fieldCommandEntries.count == GuderianCampaignCatalog.all.count &&
            lateCareerEntries.count == LateCareerGuderianPresentationCatalog.visibleEntryCount &&
            allEntries.map(\.order) == Array(1...35) &&
            allEntries.allSatisfy(\.usesUnifiedPlayableSurface) &&
            allEntries.allSatisfy(\.hasHistoricalCaveatOnly) &&
            Set(allEntries.map(\.id)).count == 35
    }
}

extension GuderianTutorialCatalog {
    static var acceptanceReadyThroughCycle910: Bool {
        let flow = firstRunHistoryFlow
        var progress = TutorialProgress()
        let initiallyPresents = progress.shouldPresent(flow)
        progress.dismiss(flow)
        let dismissedStaysHidden = !progress.shouldPresent(flow)
        let nextVersionShows = progress.shouldPresent(
            TutorialFlow(
                id: flow.id,
                version: flow.version + 1,
                title: flow.title,
                presentationKind: flow.presentationKind,
                storageKey: TutorialStorageKey("guderian.tutorial.firstRunHistory.v2.dismissed"),
                openingTrigger: flow.openingTrigger,
                pages: flow.pages
            )
        )

        return firstRunCycleRange == 891...910 &&
            flow.pages.count == 4 &&
            flow.presentationKind == .pagedOnboarding &&
            flow.openingTrigger == .appFirstLaunch &&
            flow.usesReusableStorageContract &&
            flow.pages.allSatisfy { (80...125).contains($0.wordCount) } &&
            flow.pages.allSatisfy(\.containsRequiredTopics) &&
            initiallyPresents &&
            dismissedStaysHidden &&
            nextVersionShows
    }

    static var acceptanceReadyThroughCycle930: Bool {
        let flow = firstBattleGuidanceFlow
        var coordinator = TutorialHintCoordinator()
        for trigger in requiredFirstBattleTriggers {
            coordinator.record(trigger, in: flow)
        }

        let orderedHints = flow.orderedHints
        let firstHint = coordinator.activeHint(in: flow)
        for _ in orderedHints.indices {
            coordinator.completeActiveHint(in: flow)
        }
        let allHintsCompleted = coordinator.progress.isComplete(flow)
        coordinator.dismiss(flow)

        return cycleRange == 891...930 &&
            firstBattleCycleRange == 911...930 &&
            acceptanceReadyThroughCycle910 &&
            flow.presentationKind == .contextualBattleHints &&
            flow.openingTrigger == .battleOpened &&
            flow.pages.isEmpty &&
            flow.hints.count == requiredFirstBattleTriggers.count &&
            orderedHints.map(\.order) == Array(1...orderedHints.count) &&
            Set(flow.hints.map(\.trigger)) == Set(requiredFirstBattleTriggers) &&
            flow.hints.allSatisfy { $0.accessibilityIdentifier.hasPrefix("first-battle-tutorial-hint-") } &&
            flow.hints.allSatisfy { (28...55).contains($0.wordCount) } &&
            flow.hints.allSatisfy(\.containsRequiredTopics) &&
            flow.usesReusableStorageContract &&
            firstHint?.trigger == .battleOpened &&
            allHintsCompleted &&
            coordinator.progress.shouldPresent(flow) == false
    }
}

struct GuderianTutorialAcceptanceReport: Hashable, Sendable {
    let cycleRange: ClosedRange<Int>
    let firstRunReady: Bool
    let firstBattleReady: Bool
    let reusableModelReady: Bool
    let firstBattleHintCount: Int
    let requiredTriggers: [TutorialTrigger]
    let storageKeys: [TutorialStorageKey]
    let uiAccessibilityIdentifiers: [String]
    let remainingCycles: Int
    let blockers: [String]

    var isReady: Bool {
        cycleRange == 911...930 &&
            firstRunReady &&
            firstBattleReady &&
            reusableModelReady &&
            firstBattleHintCount == requiredTriggers.count &&
            storageKeys.contains(GuderianTutorialCatalog.firstRunHistoryStorageKey) &&
            storageKeys.contains(GuderianTutorialCatalog.firstBattleGuidanceStorageKey) &&
            uiAccessibilityIdentifiers.contains("first-run-history-tutorial") &&
            uiAccessibilityIdentifiers.contains("first-battle-tutorial-hint") &&
            remainingCycles == 0 &&
            blockers.isEmpty
    }
}

enum GuderianTutorialAcceptanceCatalog {
    static let cycleRange = 911...930

    static var report: GuderianTutorialAcceptanceReport {
        let firstRunReady = GuderianTutorialCatalog.acceptanceReadyThroughCycle910
        let firstBattleReady = GuderianTutorialCatalog.acceptanceReadyThroughCycle930
        let flow = GuderianTutorialCatalog.firstBattleGuidanceFlow

        var blockers: [String] = []
        if !firstRunReady {
            blockers.append("First-run historical tutorial is not acceptance-ready.")
        }
        if !firstBattleReady {
            blockers.append("First-battle contextual tutorial is not acceptance-ready.")
        }
        if !flow.usesReusableStorageContract {
            blockers.append("First-battle tutorial does not use the reusable storage contract.")
        }

        return GuderianTutorialAcceptanceReport(
            cycleRange: cycleRange,
            firstRunReady: firstRunReady,
            firstBattleReady: firstBattleReady,
            reusableModelReady: flow.usesReusableStorageContract,
            firstBattleHintCount: flow.hints.count,
            requiredTriggers: GuderianTutorialCatalog.requiredFirstBattleTriggers,
            storageKeys: [
                GuderianTutorialCatalog.firstRunHistoryStorageKey,
                GuderianTutorialCatalog.firstBattleGuidanceStorageKey,
            ],
            uiAccessibilityIdentifiers: [
                "first-run-history-tutorial",
                "first-battle-tutorial-hint",
                "first-battle-tutorial-do-not-show-again",
                "first-battle-tutorial-next-button",
            ],
            remainingCycles: 0,
            blockers: blockers
        )
    }

    static var acceptanceReadyThroughCycle930: Bool {
        report.isReady
    }
}

final class ReviewLocalHardeningTests: XCTestCase {
    private static let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private func repositoryFile(_ path: String) throws -> String {
        try String(contentsOf: Self.packageRoot.appendingPathComponent(path), encoding: .utf8)
    }

    private func repositoryFiles(under path: String, extensions allowedExtensions: Set<String>) throws -> [URL] {
        let root = Self.packageRoot.appendingPathComponent(path)
        let urls = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey])?
            .compactMap { $0 as? URL } ?? []
        return try urls.filter { url in
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            return values.isRegularFile == true && allowedExtensions.contains(url.pathExtension)
        }
    }

    func testCycle961ReviewChecklistCoversEveryReviewItemLocally() {
        let items = ReviewLocalHardeningPlan.items

        XCTAssertEqual(items.map(\.id), Array(1...30))
        XCTAssertEqual(Set(items.map(\.id)).count, 30)
        XCTAssertTrue(items.allSatisfy { !$0.title.isEmpty })
        XCTAssertTrue(items.allSatisfy { !$0.owner.isEmpty })
        XCTAssertTrue(items.allSatisfy { (961...1080).contains($0.targetCycles.lowerBound) })
        XCTAssertTrue(items.allSatisfy { (961...1080).contains($0.targetCycles.upperBound) })
        XCTAssertEqual(ReviewLocalHardeningPlan.localRoot, "/Users/barbalet/github/guderian")
        XCTAssertEqual(ReviewLocalHardeningPlan.siblingUpstreamRoot, "/Users/barbalet/github/derZweiteWeltkrieg")
    }

    func testCycle966BoardDimensionsComeFromEngineBoundary() {
        XCTAssertEqual(game_board_width(), Float(72), accuracy: 0.001)
        XCTAssertEqual(game_board_height(), Float(48), accuracy: 0.001)
    }

    func testCycle971ScenarioMapFeatureCategoriesAreCanonical() {
        XCTAssertEqual(ScenarioMapElementKind.allCases.filter(\.isWaterFeature), [.river, .canal, .lake])
        XCTAssertEqual(ScenarioMapElementKind.allCases.filter(\.isCrossingFeature), [.bridge, .ford, .ferry])
        XCTAssertEqual(ScenarioMapElementKind.allCases.filter(\.isSettlementFeature), [.town, .village, .urbanDistrict])
        XCTAssertEqual(ScenarioMapElementKind.allCases.filter(\.isFortificationFeature), [.bunker, .fortifiedLine])
        XCTAssertEqual(ScenarioMapElementKind.allCases.filter(\.isPressureMarker), [.artillery, .airPressure])
        XCTAssertFalse(ScenarioMapElementKind.marsh.isWaterFeature)
        XCTAssertTrue(ScenarioMapElementKind.marsh.isGroundTerrainFeature)

        let waterFeatures = Set(ScenarioMapElementKind.allCases.filter(\.isWaterFeature))
        let groundFeatures = Set(ScenarioMapElementKind.allCases.filter(\.isGroundTerrainFeature))
        XCTAssertTrue(waterFeatures.isDisjoint(with: groundFeatures))
    }

    func testCycle976UnifiedBattleCatalogCachePreservesOrdering() {
        XCTAssertEqual(UnifiedGuderianBattleCatalog.fieldCommandEntries.count, 19)
        XCTAssertEqual(UnifiedGuderianBattleCatalog.lateCareerEntries.count, 16)
        XCTAssertEqual(UnifiedGuderianBattleCatalog.allEntries.count, 35)
        XCTAssertEqual(
            UnifiedGuderianBattleCatalog.allEntries,
            UnifiedGuderianBattleCatalog.fieldCommandEntries + UnifiedGuderianBattleCatalog.lateCareerEntries
        )
        XCTAssertEqual(UnifiedGuderianBattleCatalog.allEntries.map(\.order), Array(1...35))
        XCTAssertEqual(Set(UnifiedGuderianBattleCatalog.allEntries.map(\.id)).count, 35)
    }

    func testCycle980ScenarioContentBundlesAreCachedByID() throws {
        XCTAssertEqual(ScenarioContentCatalog.allBundles.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(ScenarioContentCatalog.allBundles.map(\.id), GuderianCampaignCatalog.all.map(\.id))

        let tucholaBundle = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .tucholaForest))
        XCTAssertEqual(tucholaBundle, ScenarioContentCatalog.allBundles[0])
        XCTAssertEqual(tucholaBundle.id, .tucholaForest)
    }

    func testCycle981TutorialPagesAndHintsShareContentBehavior() throws {
        let page = try XCTUnwrap(GuderianTutorialCatalog.firstRunHistoryFlow.pages.first)
        let hint = try XCTUnwrap(GuderianTutorialCatalog.firstBattleGuidanceFlow.hints.first)
        let content: [any TutorialContent] = [page, hint]

        XCTAssertTrue(content.allSatisfy { $0.wordCount > 0 })
        XCTAssertTrue(content.allSatisfy(\.containsRequiredTopics))
    }

    func testCycle986FirstBattleHintIDsAreTypedAndStable() {
        let flow = GuderianTutorialCatalog.firstBattleGuidanceFlow
        let typedIDs = FirstBattleGuidanceHintID.allCases.map(\.rawValue)

        XCTAssertEqual(flow.hints.map(\.id), typedIDs)
        XCTAssertEqual(typedIDs.count, GuderianTutorialCatalog.requiredFirstBattleTriggers.count)
        XCTAssertTrue(typedIDs.allSatisfy { $0.hasPrefix("firstBattleGuidance-") })
        XCTAssertEqual(FirstBattleGuidanceHintID.germanAI.rawValue, "firstBattleGuidance-germanAI")
    }

    func testCycle991TargetedAcceptanceGatesLiveInTestTarget() {
        XCTAssertTrue(UnifiedGuderianBattleCatalog.acceptanceReadyThroughCycle740)
        XCTAssertTrue(GuderianTutorialCatalog.acceptanceReadyThroughCycle910)
        XCTAssertTrue(GuderianTutorialCatalog.acceptanceReadyThroughCycle930)
        XCTAssertTrue(GuderianTutorialAcceptanceCatalog.acceptanceReadyThroughCycle930)
    }

    func testCycle1001LateCareerSessionSnapshotAPIUsesSharedBoardName() throws {
        let session = try XCTUnwrap(LateCareerNativeBoardSession(battlefieldID: "kursk-armored-force-pressure", seed: 1_001))

        let playableSnapshot = session.snapshot()
        XCTAssertEqual(playableSnapshot.scenarioTitle, "Kursk Armored Force Pressure")
        XCTAssertTrue(playableSnapshot.isScenarioBoardPlayable)
        XCTAssertGreaterThan(playableSnapshot.units.count, 0)

        let summarySnapshot = session.lateCareerSnapshot()
        XCTAssertEqual(summarySnapshot.battlefieldID, "kursk-armored-force-pressure")
        XCTAssertEqual(summarySnapshot.unitCount, playableSnapshot.units.count)
        XCTAssertEqual(summarySnapshot.objectiveCount, playableSnapshot.objectives.count)
    }

    func testCycle1006LateCareerSetLookupAndTutorialTriggersAreDerived() throws {
        let expectedSetPairs: [(String, LateCareerPlayableSet)] =
            LateCareerStaffBattlefieldSetACatalog.battlefieldIDs.map { ($0, .setA) } +
            LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs.map { ($0, .setB) } +
            LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs.map { ($0, .setC) } +
            LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs.map { ($0, .setD) }

        XCTAssertEqual(expectedSetPairs.count, 16)
        XCTAssertTrue(expectedSetPairs.allSatisfy { LateCareerPlayableSet.set(for: $0.0) == $0.1 })
        XCTAssertNil(LateCareerPlayableSet.set(for: "not-a-battlefield"))

        let flow = GuderianTutorialCatalog.firstBattleGuidanceFlow
        var coordinator = TutorialHintCoordinator()
        coordinator.record(.battleOpened, in: flow)
        let triggeredIDs = coordinator.triggeredHintIDs
        XCTAssertEqual(triggeredIDs, Set([FirstBattleGuidanceHintID.orientation.rawValue]))

        let encoded = try JSONEncoder().encode(coordinator)
        let decoded = try JSONDecoder().decode(TutorialHintCoordinator.self, from: encoded)
        XCTAssertEqual(decoded.triggeredHintIDs, triggeredIDs)
        XCTAssertEqual(decoded.events, coordinator.events)
    }

    func testCycle1011UnifiedBattleIDStoresFieldCommandIDsAsTypedValues() throws {
        let fieldID = UnifiedGuderianBattleID.fieldCommand(.tucholaForest)
        XCTAssertEqual(fieldID.kind, .fieldCommand)
        XCTAssertEqual(fieldID.rawValue, GuderianBattleID.tucholaForest.rawValue)
        XCTAssertEqual(fieldID.fieldCommandID, .tucholaForest)
        XCTAssertNil(fieldID.lateCareerID)

        let lateID = UnifiedGuderianBattleID.lateCareer("kursk-armored-force-pressure")
        XCTAssertEqual(lateID.kind, .lateCareer)
        XCTAssertEqual(lateID.rawValue, "kursk-armored-force-pressure")
        XCTAssertNil(lateID.fieldCommandID)
        XCTAssertEqual(lateID.lateCareerID, "kursk-armored-force-pressure")

        let encoded = try JSONEncoder().encode(fieldID)
        let decoded = try JSONDecoder().decode(UnifiedGuderianBattleID.self, from: encoded)
        XCTAssertEqual(decoded, fieldID)
        XCTAssertEqual(decoded.fieldCommandID, .tucholaForest)
    }

    func testCycle1016UnifiedCampaignSaveMigrationPreservesLegacyCampaignData() throws {
        var campaignProgress = CampaignProgress()
        campaignProgress.recordCompletion(
            CampaignCompletionRecord(
                scenarioID: .tucholaForest,
                score: 9,
                victoryBand: .operational,
                completedTurn: 4,
                note: "Legacy campaign save migration probe."
            )
        )
        let legacyState = CampaignSaveState(
            selectedScenarioID: .tucholaForest,
            playMode: .standalone,
            progress: campaignProgress
        )
        let legacyData = try CampaignSaveCodec.encode(legacyState)

        let envelope = UnifiedCampaignSaveCodec.decodeOrMigrate(
            unifiedData: Data(),
            legacyCampaignData: legacyData,
            legacyLateCareerData: Data()
        )

        XCTAssertEqual(envelope.selectedBattleID.fieldCommandID, .tucholaForest)
        XCTAssertEqual(envelope.playMode, .standalone)
        XCTAssertNotNil(envelope.progress.fieldCommandProgress.completionRecord(for: .tucholaForest))
        XCTAssertEqual(envelope.migratedFromCampaignSaveVersion, CampaignSaveState.currentSchemaVersion)
        XCTAssertTrue(envelope.migrationNote.localizedCaseInsensitiveContains("migrated"))
    }

    func testCycle1021CampaignProgressPersistenceRoundTripsSummariesAndOrdering() throws {
        let ordered = GuderianCampaignCatalog.all.sorted { $0.order < $1.order }
        let first = try XCTUnwrap(ordered.first)
        let second = try XCTUnwrap(ordered.dropFirst().first)
        let third = try XCTUnwrap(ordered.dropFirst(2).first)
        let futureOutsideSubset = try XCTUnwrap(ordered.dropFirst(3).first)

        var progress = CampaignProgress()
        progress.recordCompletion(
            CampaignCompletionRecord(
                scenarioID: first.id,
                score: 10,
                victoryBand: .operational,
                completedTurn: 4,
                note: "Persistence round-trip probe."
            )
        )
        progress.markCompleted(second.id)

        let decoded = try JSONDecoder().decode(CampaignProgress.self, from: JSONEncoder().encode(progress))
        XCTAssertTrue(decoded.isCompleted(first.id))
        XCTAssertTrue(decoded.isCompleted(second.id))
        XCTAssertEqual(decoded.completionRecord(for: first.id)?.score, 10)
        XCTAssertNil(decoded.completionRecord(for: second.id))

        let subset = [first, second, third]
        let snapshot = decoded.snapshot(mode: .chronological, catalog: subset)
        XCTAssertEqual(snapshot.completedRecords.map(\.scenarioID), [first.id])
        XCTAssertEqual(snapshot.nextScenarioID, third.id)

        let summary = decoded.completionSummary(catalog: subset)
        XCTAssertEqual(summary.totalScenarios, 3)
        XCTAssertEqual(summary.completedScenarios, 2)
        XCTAssertEqual(summary.remainingScenarioIDs, [third.id])
        XCTAssertEqual(summary.totalScore, 10)
        XCTAssertEqual(summary.victoryBands[.operational], 1)

        var progressWithFutureRecord = decoded
        progressWithFutureRecord.recordCompletion(
            CampaignCompletionRecord(
                scenarioID: futureOutsideSubset.id,
                score: 99,
                victoryBand: .decisive,
                completedTurn: 8,
                note: "Future relative to this focused catalog."
            )
        )
        XCTAssertEqual(progressWithFutureRecord.completionSummary(catalog: subset).totalScore, 10)
    }

    func testCycle1022LateCareerProgressPersistenceIgnoresUnknownBattlefieldIDs() throws {
        let knownRecord = try XCTUnwrap(UnifiedLateCareerScoringDebriefCatalog.completionSummaries.first?.completionRecord)
        let unknownRecord = LateCareerCompletionRecord(
            battlefieldID: "future-local-battlefield",
            score: 42,
            victoryBand: .operational,
            completedTurn: 6,
            persistenceKey: "guderian.future-local-battlefield.completion.v1",
            note: "Unknown late-career progress should not enter summaries."
        )

        var progress = LateCareerProgress()
        progress.recordCompletion(knownRecord)
        progress.recordCompletion(unknownRecord)

        let decoded = try JSONDecoder().decode(LateCareerProgress.self, from: JSONEncoder().encode(progress))
        XCTAssertEqual(decoded.completionRecord(for: knownRecord.battlefieldID), knownRecord)
        XCTAssertNil(decoded.completionRecord(for: unknownRecord.battlefieldID))
        XCTAssertEqual(decoded.completionSummary().completedBattlefields, 1)
        XCTAssertEqual(decoded.completionSummary().totalScore, knownRecord.score)

        let injectedFuture = LateCareerProgress(completionRecords: [unknownRecord.battlefieldID: unknownRecord])
        XCTAssertEqual(injectedFuture.completionSummary().completedBattlefields, 0)
        XCTAssertEqual(injectedFuture.completionSummary().totalScore, 0)
    }

    func testCycle1023UnifiedProgressWrappingRoundTripsAndRejectsFutureIDs() throws {
        let fieldRecord = CampaignCompletionRecord(
            scenarioID: .tucholaForest,
            score: 11,
            victoryBand: .operational,
            completedTurn: 4,
            note: "Unified wrapper field-command probe."
        )
        let lateRecord = try XCTUnwrap(UnifiedLateCareerScoringDebriefCatalog.completionSummaries.first?.completionRecord)

        var fieldProgress = CampaignProgress()
        fieldProgress.recordCompletion(fieldRecord)
        var lateProgress = LateCareerProgress()
        lateProgress.recordCompletion(lateRecord)

        let unified = UnifiedCampaignProgressCatalog.progress(
            fieldCommandProgress: fieldProgress,
            lateCareerProgress: lateProgress
        )
        let decoded = try JSONDecoder().decode(UnifiedCampaignProgress.self, from: JSONEncoder().encode(unified))

        XCTAssertEqual(decoded.completedCount, 2)
        XCTAssertEqual(decoded.fieldCommandProgress.completionRecord(for: .tucholaForest), fieldRecord)
        XCTAssertEqual(decoded.lateCareerProgress.completionRecord(for: lateRecord.battlefieldID), lateRecord)
        XCTAssertEqual(decoded.summary().completedBattleCount, 2)

        var rejectsFuture = decoded
        rejectsFuture.recordCompletion(
            UnifiedCampaignProgressRecord(
                id: .lateCareer("future-local-battlefield"),
                source: .lateCareer,
                title: "Future Local Battlefield",
                commandScope: try XCTUnwrap(UnifiedGuderianBattleCatalog.allEntries.first?.commandScope),
                score: 50,
                victoryBand: .operational,
                completedTurn: 7,
                persistenceKey: "guderian.future-local-battlefield.completion.v1",
                note: "Future unified progress should be ignored until cataloged."
            )
        )

        XCTAssertFalse(rejectsFuture.isCompleted(.lateCareer("future-local-battlefield")))
        XCTAssertEqual(rejectsFuture.completedCount, decoded.completedCount)
    }

    func testCycle1024EmptyUnifiedSaveLaunchesWithDefaultProgress() {
        let envelope = UnifiedCampaignSaveCodec.decodeOrMigrate(
            unifiedData: Data(),
            legacyCampaignData: Data(),
            legacyLateCareerData: Data()
        )

        XCTAssertTrue(envelope.isCurrentSchema)
        XCTAssertEqual(envelope.selectedBattleID, .fieldCommand(.tucholaForest))
        XCTAssertEqual(envelope.playMode, .chronological)
        XCTAssertEqual(envelope.progress.completedCount, 0)
        XCTAssertNil(envelope.migratedFromCampaignSaveVersion)
        XCTAssertNil(envelope.migratedLateCareerProgressVersion)
        XCTAssertTrue(envelope.migrationNote.localizedCaseInsensitiveContains("unified"))
    }

    func testCycle1026CampaignAutomationStagesAreTypedAndDecodeLegacyStrings() throws {
        XCTAssertTrue(CampaignAutomationStage.knownCases.contains(.nativeLoader))
        XCTAssertTrue(CampaignAutomationStage.knownCases.contains(.turnPlayback))
        XCTAssertEqual(CampaignAutomationStage(rawValue: "Native Loader"), .nativeLoader)
        XCTAssertEqual(CampaignAutomationStage(rawValue: "Turn 3 German Shooting").rawValue, "Turn 3 German Shooting")
        XCTAssertEqual(CampaignAutomationStage(rawValue: "Legacy Probe").rawValue, "Legacy Probe")

        let legacyStepJSON = Data(
            #"{"id":"legacy-step","stage":"Native Loader","status":"Passed","title":"Loaded","detail":"Compatibility payload."}"#.utf8
        )
        let legacyIssueJSON = Data(
            #"{"id":"legacy-issue","kind":"Warning","stage":"Native Playability","title":"Warned","detail":"Compatibility payload."}"#.utf8
        )

        let step = try JSONDecoder().decode(CampaignAutomationStep.self, from: legacyStepJSON)
        let issue = try JSONDecoder().decode(CampaignAutomationIssue.self, from: legacyIssueJSON)

        XCTAssertEqual(step.stage, .nativeLoader)
        XCTAssertEqual(issue.stage, .nativePlayability)
        XCTAssertEqual(try JSONDecoder().decode(CampaignAutomationStep.self, from: JSONEncoder().encode(step)), step)
    }

    func testCycle1031PlayableTestGameDoesNotMarkIgnoredActionsAsSucceeded() throws {
        let result = try PlayableTestGameRunner.runBattle(for: .tucholaForest, seed: 1_031)
        let noLegalActionSteps = result.steps.filter { $0.detail.hasPrefix("No legal") }

        XCTAssertTrue(result.completedToEnd, result.blockers.joined(separator: "\n"))
        XCTAssertFalse(result.steps.isEmpty)
        XCTAssertTrue(noLegalActionSteps.allSatisfy { $0.status == .blocked })
        XCTAssertFalse(result.steps.contains { $0.detail.hasPrefix("No legal") && $0.status == .succeeded })
    }

    func testCycle1041GameControllerStateUsesSetupAndSelectionSnapshots() throws {
        let controllerSource = try repositoryFile("dzw/Sources/DerZweiteWeltkriegApp/ViewModel/GameController.swift")

        XCTAssertTrue(controllerSource.contains("struct GameControllerSetupSelectionState: Equatable, Sendable"))
        XCTAssertTrue(controllerSource.contains("struct GameControllerBoardSelectionState: Equatable, Sendable"))
        XCTAssertTrue(controllerSource.contains("@Published private(set) var setupSelection"))
        XCTAssertTrue(controllerSource.contains("@Published private(set) var boardSelection"))
        XCTAssertTrue(controllerSource.contains("var selectedUnitID: Int?"))
        XCTAssertTrue(controllerSource.contains("var playerOneArmyID: String"))
        XCTAssertFalse(controllerSource.contains("@Published var selectedUnitID"))
        XCTAssertFalse(controllerSource.contains("@Published var selectedTargetID"))
        XCTAssertFalse(controllerSource.contains("@Published var playerOneArmyID"))
        XCTAssertFalse(controllerSource.contains("@Published var playerTwoArmyID"))
    }

    func testCycle1046GuderianModuleBoundaryIsFormalizedLocally() throws {
        let packageManifest = try repositoryFile("dzw/Package.swift")
        let boundarySource = try repositoryFile("dzw/Sources/DerZweiteWeltkriegGuderian/GuderianModuleBoundary.swift")

        XCTAssertTrue(boundarySource.contains("public enum GuderianModuleBoundaryContract"))
        XCTAssertTrue(boundarySource.contains("local embedded dzw content module"))
        XCTAssertTrue(boundarySource.contains("DerZweiteWeltkriegGuderian -> DerZweiteWeltkriegCore"))
        XCTAssertTrue(boundarySource.contains("DerZweiteWeltkriegCore -> DerZweiteWeltkriegGuderian"))
        XCTAssertTrue(packageManifest.contains("Local Guderian integration boundary"))
        XCTAssertTrue(packageManifest.contains("name: \"DerZweiteWeltkriegGuderian\""))
        XCTAssertTrue(packageManifest.contains("dependencies: [\"DerZweiteWeltkriegCore\"]"))
    }

    func testCycle1051ReusableDZWCoreDoesNotImportGuderianContent() throws {
        let coreFiles = try repositoryFiles(
            under: "dzw/Sources/DerZweiteWeltkriegCore",
            extensions: ["c", "h", "swift"]
        )
        let forbiddenNeedles = ["DerZweiteWeltkriegGuderian", "GuderianCore", "GuderianAppUI"]
        let violations = try coreFiles.flatMap { url -> [String] in
            let source = try String(contentsOf: url, encoding: .utf8)
            return forbiddenNeedles
                .filter(source.contains)
                .map { "\(url.lastPathComponent): \($0)" }
        }

        XCTAssertFalse(coreFiles.isEmpty)
        XCTAssertTrue(try repositoryFile("dzw/Sources/DerZweiteWeltkriegGuderian/GuderianModuleBoundary.swift").contains("DerZweiteWeltkriegCore -> DerZweiteWeltkriegGuderian"))
        XCTAssertTrue(violations.isEmpty, violations.joined(separator: "\n"))
    }

    func testCycle1056GermanAIPlanIsExecutableAutoplayInput() throws {
        let plan = GermanAIPlanCatalog.plan(for: try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest)))

        XCTAssertEqual(plan.executionMode, .nativeAutoplayTargetPriorities)
        XCTAssertTrue(plan.isExecutableByNativeAutoplay)
        XCTAssertEqual(plan.targetPriorities(for: .movement).first, "Chojnice and Brda approaches")
        XCTAssertTrue(plan.targetPriorities(for: .movement).contains("Pruszcz bridge"))
        XCTAssertEqual(plan.targetPriorities(for: .shooting).first, "Chojnice-Tuchola road net")
        XCTAssertTrue(plan.targetPriorities(for: .assault).contains("Bydgoszcz withdrawal"))

        let legacyPayload = Data("""
        {
          "id": "\(GuderianBattleID.tucholaForest.rawValue)",
          "postureName": "Legacy AI plan",
          "strategicGoal": "Decode without an executionMode key.",
          "targetPriorities": ["Bridge"],
          "orders": [
            {
              "id": "legacy-order",
              "turnWindow": "Turn 1",
              "kind": "Movement",
              "target": "Bridge",
              "instruction": "Move toward the bridge."
            }
          ]
        }
        """.utf8)
        let decoded = try JSONDecoder().decode(GermanAIPlan.self, from: legacyPayload)

        XCTAssertEqual(decoded.executionMode, .nativeAutoplayTargetPriorities)
        XCTAssertTrue(decoded.isExecutableByNativeAutoplay)
        XCTAssertEqual(decoded.targetPriorities(for: .movement), ["Bridge"])
    }

    func testCycle1061ScenarioMapRenderableAndFileHygieneAreClosed() throws {
        let coreRenderable = try repositoryFile("Sources/GuderianCore/ScenarioMapRenderable.swift")
        let scenarioMapView = try repositoryFile("Sources/GuderianApp/ScenarioMapView.swift")
        let coreReexports = try repositoryFile("Sources/GuderianCore/GuderianCore.swift")
        let xcodeProject = try repositoryFile("Guderian.xcodeproj/project.pbxproj")

        XCTAssertTrue(coreRenderable.contains("public protocol ScenarioMapRenderable"))
        XCTAssertTrue(coreRenderable.contains("extension ScenarioMapLayout: ScenarioMapRenderable"))
        XCTAssertTrue(coreRenderable.contains("extension LateCareerStaffBattlefieldMap: ScenarioMapRenderable"))
        XCTAssertFalse(scenarioMapView.contains("protocol ScenarioMapRenderable {"))
        XCTAssertTrue(coreReexports.contains("Re-export the embedded dzw engine and Guderian content module"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: Self.packageRoot.appendingPathComponent("Sources/GuderianApp/BattlefieldViewport.swift").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: Self.packageRoot.appendingPathComponent("Sources/GuderianApp/BattlefieldWorkspace.swift").path))
        XCTAssertTrue(xcodeProject.contains("BattlefieldViewport.swift"))
        XCTAssertFalse(xcodeProject.contains("BattlefieldWorkspace.swift"))
    }

    func testCycle1066WindowDiagnosticsAndPanelRoutingAreHardened() throws {
        let playableView = try repositoryFile("Sources/GuderianApp/DZWPlayableBattleView.swift")
        let battleShell = try repositoryFile("dzw/Sources/DerZweiteWeltkriegApp/Shell/BattleShellView.swift")

        XCTAssertTrue(playableView.contains("#if DEBUG\n@MainActor\nprivate func logDZWWindowSnapshot"))
        XCTAssertTrue(playableView.contains("#else\n@MainActor\nprivate func logDZWWindowSnapshot"))
        XCTAssertFalse(playableView.contains("panelsByWindowID"))
        XCTAssertFalse(battleShell.contains("panelsByWindowID"))
        XCTAssertFalse(playableView.contains("ObjectIdentifier(window)"))
        XCTAssertFalse(battleShell.contains("ObjectIdentifier(window)"))
        XCTAssertTrue(playableView.contains("window.identifier = panel.windowIdentifier"))
        XCTAssertTrue(battleShell.contains("window.identifier = panel.windowIdentifier"))
        XCTAssertTrue(playableView.contains("private func panel(for window: NSWindow) -> DZWPlayableBattlePanel?"))
        XCTAssertTrue(battleShell.contains("private func panel(for window: NSWindow) -> BattleShellPanel?"))
    }

    func testCycle1076ReviewChecklistClosesEveryItemThrough1080() throws {
        let plan = try repositoryFile("PLAN.md")
        let readme = try repositoryFile("README.md")
        let items = ReviewLocalHardeningPlan.items

        XCTAssertEqual(items.map(\.id), Array(1...30))
        XCTAssertEqual(items.map(\.targetCycles.lowerBound).min(), 966)
        XCTAssertEqual(items.map(\.targetCycles.upperBound).max(), 1075)
        XCTAssertTrue(items.allSatisfy { $0.targetCycles.upperBound <= 1080 })
        XCTAssertTrue(plan.contains("Status through cycle 1080: completed"))
        XCTAssertTrue(plan.contains("Acceptance for cycle 1080"))
        XCTAssertTrue(plan.contains("Cycle 1080 closes") || plan.contains("Cycle 1080 update"))
        XCTAssertTrue(plan.contains("`REVIEW.md` local hardening block is complete"))
        XCTAssertTrue(readme.contains("current ship status"))
        XCTAssertTrue(readme.contains("[PLAN.md](PLAN.md)"))
    }

    func testDZWPrefixMigrationRemovesLegacyTEPrefixes() throws {
        var urls = [
            Self.packageRoot.appendingPathComponent("README.md"),
            Self.packageRoot.appendingPathComponent("PLAN.md"),
            Self.packageRoot.appendingPathComponent("RELEASE.md"),
        ]

        for root in ["Sources", "Tests", "dzw/Sources", "dzw/Tests", "dzw/docs"] {
            urls.append(contentsOf: try repositoryFiles(
                under: root,
                extensions: ["swift", "c", "h", "md"]
            ))
        }

        let legacyPrefixPattern = "\\b(?:" + "T" + "E_|" + "t" + "e_)"

        for url in urls {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            let text = try String(contentsOf: url, encoding: .utf8)
            XCTAssertNil(
                text.range(of: legacyPrefixPattern, options: .regularExpression),
                url.path
            )
        }

        let header = try repositoryFile("dzw/Sources/DerZweiteWeltkriegCore/include/der_Zweite_Weltkrieg.h")
        XCTAssertTrue(header.contains("DZW_PLAYER_ONE"))
        XCTAssertTrue(header.contains("typedef struct dzw_game game_t;"))
    }
}
