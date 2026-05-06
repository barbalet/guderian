import DerZweiteWeltkriegCore
import Foundation
@testable import GuderianCore
import XCTest

final class GuderianCampaignTests: XCTestCase {
    func testCampaignCatalogLocksNineteenCommandScopeScenarios() {
        XCTAssertEqual(GuderianCampaignCatalog.all.count, 19)
        XCTAssertEqual(GuderianCampaignCatalog.all.map(\.order), Array(1...19))
        XCTAssertEqual(Set(GuderianCampaignCatalog.all.map(\.id)).count, 19)
    }

    func testCareerScopeLedgerSeparatesDirectBattlesFromLateCareerContext() {
        XCTAssertEqual(GuderianCareerScopeCatalog.allCurrentScenarioIDs, Set(GuderianBattleID.allCases))
        XCTAssertEqual(GuderianCareerScopeCatalog.record(for: .dunkirk)?.scope, .adjacentCampaignPressure)
        XCTAssertTrue(GuderianCareerScopeCatalog.record(for: .dunkirk)?.requiresCommandCaveat == true)
        XCTAssertEqual(GuderianCareerScopeCatalog.record(for: .tucholaForest)?.scope, .directFieldCommand)
        XCTAssertEqual(GuderianCareerScopeCatalog.record(for: .sedan)?.scope, .directFieldCommand)

        let lateCareer = GuderianCareerScopeCatalog.lateCareerExpansionCandidates
        XCTAssertGreaterThanOrEqual(lateCareer.count, 15)
        XCTAssertTrue(lateCareer.allSatisfy(\.requiresCommandCaveat))
        XCTAssertTrue(lateCareer.contains { $0.title.contains("Vistula-Oder") })
        XCTAssertTrue(lateCareer.contains { $0.scope == .postDismissalContext })
    }

    func testCycle600MapDetailAuditSetsPerBattleFourXTargets() {
        let report = ScenarioMapDetailAuditCatalog.report()

        XCTAssertEqual(report.scenarioCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.battleIDsNeedingEnrichment, GuderianCampaignCatalog.all.map(\.id))
        XCTAssertEqual(report.minimumFeatureCount, report.currentFeatureCount * 4)
        XCTAssertEqual(report.requiredAdditionalFeatureCount, report.currentFeatureCount * 3)
        XCTAssertTrue(report.categoryGaps.contains(.totalMapFeatures))
        XCTAssertTrue(report.categoryGaps.contains(.railways))

        guard let tuchola = ScenarioMapDetailAuditCatalog.audit(for: .tucholaForest) else {
            XCTFail("Tuchola Forest needs a map-detail audit")
            return
        }

        XCTAssertEqual(tuchola.target.minimumFeatureCount, tuchola.metrics.mapFeatureCount * 4)
        XCTAssertGreaterThan(tuchola.metrics.count(for: .water), 0)
        XCTAssertGreaterThan(tuchola.metrics.count(for: .crossings), 0)
    }

    func testCycle605MapSchemaSupportsDetailedGeographyAndSourceNotes() {
        let expectedKinds: Set<ScenarioMapElementKind> = [
            .canal,
            .lake,
            .marsh,
            .railway,
            .ford,
            .ferry,
            .village,
            .urbanDistrict,
            .phaseLine,
        ]

        XCTAssertTrue(expectedKinds.isSubset(of: Set(ScenarioMapElementKind.allCases)))

        let source = ScenarioMapSourceNote(
            title: "Schema source",
            url: URL(string: "https://example.com/schema"),
            note: "Verifies source-note metadata without relying on real map data."
        )
        let layout = ScenarioMapLayout(
            id: .sedan,
            title: "Schema probe",
            elements: [
                ScenarioMapElement(id: "canal", name: "Canal", kind: .canal, points: [ScenarioMapPoint(1, 1), ScenarioMapPoint(4, 1)], sourceNotes: [source]),
                ScenarioMapElement(id: "rail", name: "Railway", kind: .railway, points: [ScenarioMapPoint(1, 3), ScenarioMapPoint(4, 3)]),
                ScenarioMapElement(id: "village", name: "Village", kind: .village, points: [ScenarioMapPoint(2, 5)], radius: 2),
                ScenarioMapElement(id: "phase", name: "Phase line", kind: .phaseLine, points: [ScenarioMapPoint(0, 7), ScenarioMapPoint(8, 7)]),
            ],
            deploymentZones: [
                ScenarioDeploymentZone(id: "player", name: "Player", side: .player, origin: ScenarioMapPoint(0, 0), width: 4, height: 4, note: "Start"),
                ScenarioDeploymentZone(id: "ai", name: "AI", side: .guderianAI, origin: ScenarioMapPoint(4, 0), width: 4, height: 4, note: "Start"),
            ],
            sourceNotes: [source]
        )
        let metrics = ScenarioMapDetailMetrics(layout: layout)

        XCTAssertEqual(metrics.count(for: .water), 1)
        XCTAssertEqual(metrics.count(for: .railways), 1)
        XCTAssertEqual(metrics.count(for: .settlements), 1)
        XCTAssertEqual(metrics.count(for: .sourceNotes), 2)
        XCTAssertFalse(ScenarioMapElementKind.phaseLine.isPlayableTerrainFeature)
    }

    func testCycle610GeographyPipelineCreatesCrossCheckRecordsAndMapSourceNotes() throws {
        let report = ScenarioMapGeographyPipelineCatalog.report()

        XCTAssertEqual(report.scenarioCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.readyScenarioIDs, GuderianCampaignCatalog.all.map(\.id))
        XCTAssertEqual(report.modernVisualReferenceCount, GuderianCampaignCatalog.all.count)
        XCTAssertGreaterThan(report.featureVisualReferenceCount, report.scenarioCount)

        let tuchola = try XCTUnwrap(ScenarioMapGeographyPipelineCatalog.record(for: .tucholaForest))

        XCTAssertTrue(tuchola.workflowSteps.contains(.traceWaterAndTerrain))
        XCTAssertTrue(tuchola.workflowSteps.contains(.traceTransportAndCrossings))
        XCTAssertTrue(tuchola.workflowSteps.contains(.handAuthorAbstractCoordinates))
        XCTAssertTrue(tuchola.visualGuideReferences.contains { $0.url.absoluteString.contains("google.com/maps/search") })
        XCTAssertTrue(tuchola.anchors.contains { $0.expectedKind == .bridge || $0.targetCategories.contains(.crossings) })
        XCTAssertTrue(tuchola.requiredDetailCategories.contains(.settlements))

        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let layout = ScenarioMapCatalog.layout(for: scenario)

        XCTAssertGreaterThanOrEqual(layout.sourceNotes.count, scenario.sourceLinks.count + 1)
        XCTAssertTrue(layout.sourceNotes.allSatisfy { !$0.note.isEmpty })
    }

    func testCycle615PolandMapsMeetFourXEnrichmentBaseline() throws {
        let cycle600BaselineFeatureCounts: [GuderianBattleID: Int] = [
            .tucholaForest: 14,
            .wizna: 9,
            .brzescLitewski: 11,
            .kobryn: 10,
        ]
        let polandIDs: [GuderianBattleID] = [.tucholaForest, .wizna, .brzescLitewski, .kobryn]

        for id in polandIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let layout = ScenarioMapCatalog.layout(for: scenario)
            let metrics = ScenarioMapDetailMetrics(layout: layout)
            let baseline = try XCTUnwrap(cycle600BaselineFeatureCounts[id])

            XCTAssertGreaterThanOrEqual(metrics.mapFeatureCount, baseline * 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .water), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .roads), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .railways), 1, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .crossings), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .settlements), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .groundTerrain), 4, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .phaseLine }, scenario.title)
        }
    }

    func testCycle620FranceMapsMeetFourXEnrichmentBaseline() throws {
        let cycle600BaselineFeatureCounts: [GuderianBattleID: Int] = [
            .sedan: 10,
            .stonne: 9,
            .montcornet: 9,
            .amiensAbbeville: 10,
            .boulogne: 10,
            .calais: 10,
            .dunkirk: 11,
            .fallRot: 10,
        ]
        let franceIDs: [GuderianBattleID] = [
            .sedan,
            .stonne,
            .montcornet,
            .amiensAbbeville,
            .boulogne,
            .calais,
            .dunkirk,
            .fallRot,
        ]

        for id in franceIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let layout = ScenarioMapCatalog.layout(for: scenario)
            let metrics = ScenarioMapDetailMetrics(layout: layout)
            let baseline = try XCTUnwrap(cycle600BaselineFeatureCounts[id])

            XCTAssertGreaterThanOrEqual(metrics.mapFeatureCount, baseline * 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .water), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .roads), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .railways), 1, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .crossings), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .settlements), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .groundTerrain), 4, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .urbanDistrict }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .phaseLine }, scenario.title)
        }
    }

    func testCycle625EasternFrontMapsMeetFourXEnrichmentBaseline() throws {
        let cycle600BaselineFeatureCounts: [GuderianBattleID: Int] = [
            .bialystokMinsk: 11,
            .smolensk: 13,
            .roslavlNovozybkov: 12,
            .kiev: 12,
            .bryansk: 13,
            .mtsensk: 13,
            .moscowTulaKashira: 16,
        ]
        let easternFrontIDs: [GuderianBattleID] = [
            .bialystokMinsk,
            .smolensk,
            .roslavlNovozybkov,
            .kiev,
            .bryansk,
            .mtsensk,
            .moscowTulaKashira,
        ]

        for id in easternFrontIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let layout = ScenarioMapCatalog.layout(for: scenario)
            let metrics = ScenarioMapDetailMetrics(layout: layout)
            let baseline = try XCTUnwrap(cycle600BaselineFeatureCounts[id])

            XCTAssertGreaterThanOrEqual(metrics.mapFeatureCount, baseline * 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .water), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .roads), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .railways), 1, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .crossings), 3, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .settlements), 4, scenario.title)
            XCTAssertGreaterThanOrEqual(metrics.count(for: .groundTerrain), 4, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .railway }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .forest }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .urbanDistrict }, scenario.title)
            XCTAssertTrue(layout.elements.contains { $0.kind == .phaseLine }, scenario.title)
        }
    }

    func testCycle630LateCareerSetAStaffContextBattlefieldsAreReady() throws {
        let catalog = LateCareerStaffBattlefieldSetACatalog.self
        let currentBattleRawIDs = Set(GuderianBattleID.allCases.map(\.rawValue))

        XCTAssertEqual(catalog.cycleRange, 626...630)
        XCTAssertEqual(catalog.allBattlefields.map(\.id), GuderianCareerScopeCatalog.lateCareerSetACandidateIDs)
        XCTAssertTrue(catalog.allBattlefieldsReady)
        XCTAssertEqual(GuderianCampaignCatalog.all.count, 19)

        for battlefield in catalog.allBattlefields {
            let candidate = try XCTUnwrap(GuderianCareerScopeCatalog.expansionCandidate(for: battlefield.id))

            XCTAssertFalse(currentBattleRawIDs.contains(battlefield.id), battlefield.title)
            XCTAssertEqual(battlefield.title, candidate.title)
            XCTAssertEqual(battlefield.scope, .inspectorGeneralInfluence, battlefield.title)
            XCTAssertTrue(battlefield.requiresCommandCaveat, battlefield.title)
            XCTAssertTrue(battlefield.commandCaveat.localizedCaseInsensitiveContains("not a Guderian field command"), battlefield.title)
            XCTAssertTrue(battlefield.map.hasRequiredStaffContextDetail, battlefield.title)
            XCTAssertGreaterThanOrEqual(battlefield.objectives.count, 4, battlefield.title)
            XCTAssertGreaterThanOrEqual(battlefield.rules.count, 4, battlefield.title)
            XCTAssertTrue(battlefield.forces.contains { $0.side == .player }, battlefield.title)
            XCTAssertTrue(battlefield.forces.contains { $0.side == .guderianAI }, battlefield.title)
            XCTAssertTrue(battlefield.map.elements.contains { $0.kind == .railway }, battlefield.title)
            XCTAssertTrue(battlefield.map.elements.contains { $0.kind == .phaseLine }, battlefield.title)
        }
    }

    func testCycle635Through645RemainingLateCareerSetsAreReady() throws {
        XCTAssertEqual(LateCareerStaffBattlefieldSetBCatalog.cycleRange, 631...635)
        XCTAssertEqual(LateCareerStaffBattlefieldSetCCatalog.cycleRange, 636...640)
        XCTAssertEqual(LateCareerStaffBattlefieldSetDCatalog.cycleRange, 641...645)
        XCTAssertTrue(LateCareerStaffBattlefieldSetBCatalog.allBattlefieldsReady)
        XCTAssertTrue(LateCareerStaffBattlefieldSetCCatalog.allBattlefieldsReady)
        XCTAssertTrue(LateCareerStaffBattlefieldSetDCatalog.allBattlefieldsReady)

        let battlefields = LateCareerStaffBattlefieldSetBCatalog.allBattlefields +
            LateCareerStaffBattlefieldSetCCatalog.allBattlefields +
            LateCareerStaffBattlefieldSetDCatalog.allBattlefields

        XCTAssertEqual(battlefields.count, 12)
        XCTAssertEqual(Set(battlefields.map(\.id)).count, 12)
        XCTAssertTrue(battlefields.contains { $0.id == "warsaw-defensive-arcs" })
        XCTAssertTrue(battlefields.contains { $0.id == "kustrin-oder-bridgeheads" })

        for battlefield in battlefields {
            let candidate = try XCTUnwrap(GuderianCareerScopeCatalog.expansionCandidate(for: battlefield.id))

            XCTAssertEqual(battlefield.title, candidate.title)
            XCTAssertEqual(battlefield.scope, candidate.scope, battlefield.title)
            XCTAssertTrue(battlefield.isLateCareerReady, battlefield.title)
            XCTAssertTrue(battlefield.map.hasRequiredStaffContextDetail, battlefield.title)
            XCTAssertTrue(battlefield.visibleCommandCaveatLabel.contains(battlefield.scope.rawValue), battlefield.title)
            XCTAssertTrue(battlefield.visibleCommandCaveatLabel.localizedCaseInsensitiveContains("not a Guderian field command"), battlefield.title)
            XCTAssertTrue(battlefield.objectives.contains { $0.side == .player }, battlefield.title)
            XCTAssertTrue(battlefield.objectives.contains { $0.side == .guderianAI }, battlefield.title)
            XCTAssertTrue(battlefield.forces.contains { $0.side == .player }, battlefield.title)
            XCTAssertTrue(battlefield.forces.contains { $0.side == .guderianAI }, battlefield.title)
        }

        let epilogues = LateCareerStaffBattlefieldSetDCatalog.allBattlefields.filter { $0.scope == .postDismissalContext }
        XCTAssertEqual(epilogues.map(\.id), ["seelow-heights-epilogue", "berlin-halbe-epilogue"])
    }

    func testCycle650LateCareerAcceptanceReportIsReady() {
        let report = LateCareerStaffBattlefieldAcceptanceCatalog.report

        XCTAssertEqual(LateCareerStaffBattlefieldAcceptanceCatalog.cycleRange, 646...650)
        XCTAssertTrue(report.isReadyForAcceptance)
        XCTAssertEqual(report.currentPlayableBattleCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.routedPlayableBattleCount, PlayableBattleSurfaceCatalog.routedBattleIDs.count)
        XCTAssertEqual(report.currentPlayableBattleCount, 19)
        XCTAssertEqual(report.lateCareerBattlefieldCount, 16)
        XCTAssertEqual(report.commandCaveatCount, 16)
        XCTAssertEqual(report.postDismissalBattlefieldCount, 2)
        XCTAssertTrue(report.currentCampaignMapDetailReady)
        XCTAssertTrue(report.allLateCareerBattlefieldsReady)
        XCTAssertTrue(report.allBattlefieldIDsMatchLedger)
        XCTAssertEqual(
            LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefieldIDs,
            GuderianCareerScopeCatalog.lateCareerBattlefieldCandidateIDs
        )
        XCTAssertEqual(
            LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefields.map(\.order),
            Array(1...16)
        )
    }

    func testCycle655LateCareerPresentationCatalogKeepsCampaignSeparate() {
        let catalog = LateCareerGuderianPresentationCatalog.self
        let currentBattleRawIDs = Set(GuderianBattleID.allCases.map(\.rawValue))

        XCTAssertEqual(catalog.cycleRange, 651...670)
        XCTAssertEqual(catalog.fieldCommandCampaignCount, 19)
        XCTAssertEqual(GuderianCampaignCatalog.all.count, 19)
        XCTAssertEqual(catalog.visibleEntryCount, 16)
        XCTAssertEqual(catalog.totalSelectableEntryCount, 35)
        XCTAssertEqual(
            catalog.allEntries.map(\.id),
            LateCareerStaffBattlefieldAcceptanceCatalog.allLateCareerBattlefieldIDs
        )
        XCTAssertTrue(catalog.allEntriesReadyForBriefing)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle670)

        for entry in catalog.allEntries {
            XCTAssertFalse(currentBattleRawIDs.contains(entry.id), entry.title)
            XCTAssertTrue(entry.visibleCommandCaveatLabel.localizedCaseInsensitiveContains("not a Guderian field command"), entry.title)
            XCTAssertFalse(entry.scope.allowsDirectBattlefieldScenario, entry.title)
        }
    }

    func testCycle660LateCareerPresentationSupportsScopeFiltersAndVisibleRows() {
        let catalog = LateCareerGuderianPresentationCatalog.self

        XCTAssertEqual(catalog.sectionTitle, "Late Career Context")
        XCTAssertEqual(catalog.entries(for: nil).count, 16)
        XCTAssertEqual(catalog.entries(for: .inspectorGeneralInfluence).count, 4)
        XCTAssertEqual(catalog.entries(for: .armyGeneralStaffInfluence).count, 10)
        XCTAssertEqual(catalog.entries(for: .postDismissalContext).count, 2)
        XCTAssertEqual(catalog.entries(for: .directFieldCommand).count, 0)
        XCTAssertEqual(catalog.entries(for: .adjacentCampaignPressure).count, 0)
        XCTAssertEqual(catalog.allEntries.map(\.order), Array(1...16))
        XCTAssertEqual(catalog.entry(for: "kursk-armored-force-pressure")?.title, "Kursk Armored Force Pressure")
        XCTAssertEqual(catalog.entry(for: "berlin-halbe-epilogue")?.scope, .postDismissalContext)
    }

    func testCycle665LateCareerBriefingSurfaceUsesSharedDZWData() {
        for entry in LateCareerGuderianPresentationCatalog.allEntries {
            let battlefield = entry.battlefield

            XCTAssertEqual(entry.mapFeatureCount, battlefield.map.featureCount, entry.title)
            XCTAssertEqual(entry.mapSourceNoteCount, battlefield.map.sourceNoteCount, entry.title)
            XCTAssertEqual(entry.objectiveCount, battlefield.objectives.count, entry.title)
            XCTAssertEqual(entry.forceCount, battlefield.forces.count, entry.title)
            XCTAssertEqual(entry.ruleCount, battlefield.rules.count, entry.title)
            XCTAssertEqual(entry.sourceCount, battlefield.sourceLinks.count, entry.title)
            XCTAssertTrue(battlefield.map.hasRequiredStaffContextDetail, entry.title)
            XCTAssertTrue(battlefield.map.elements.contains { $0.kind == .phaseLine }, entry.title)
            XCTAssertGreaterThanOrEqual(battlefield.map.sourceNoteCount, 1, entry.title)
            XCTAssertTrue(battlefield.objectives.contains { $0.side == .player }, entry.title)
            XCTAssertTrue(battlefield.objectives.contains { $0.side == .guderianAI }, entry.title)
        }
    }

    func testCycle670LateCareerSetAPlayablePilotIsRouted() {
        let catalog = LateCareerGuderianPresentationCatalog.self
        let setAIDs = LateCareerStaffBattlefieldSetACatalog.battlefieldIDs

        XCTAssertEqual(catalog.setAPlayablePilotIDs, setAIDs)
        XCTAssertEqual(catalog.setAPlayablePilotEntries.map(\.id), setAIDs)
        XCTAssertEqual(catalog.setAPlayablePilotEntries.count, 4)
        XCTAssertTrue(catalog.allSetAEntriesPlayablePilotReady)

        for entry in catalog.allEntries {
            if setAIDs.contains(entry.id) {
                XCTAssertTrue(entry.isRoutedToLateCareerPlayableSurface, entry.title)
                XCTAssertTrue(entry.isSetAPlayablePilot, entry.title)
            } else {
                XCTAssertFalse(entry.isSetAPlayablePilot, entry.title)
            }
        }
    }

    func testCycle675LateCareerSetAParityAddsScoringDebriefAndPersistence() {
        let catalog = LateCareerPlayableSurfaceCatalog.self

        XCTAssertEqual(catalog.cycleRange, 671...710)
        XCTAssertEqual(catalog.setAParityIDs, LateCareerStaffBattlefieldSetACatalog.battlefieldIDs)
        XCTAssertEqual(catalog.setAReports.map(\.battlefieldID), catalog.setAParityIDs)
        XCTAssertEqual(catalog.setAReports.count, 4)

        for report in catalog.setAReports {
            XCTAssertEqual(report.set, .setA, report.title)
            XCTAssertTrue(report.isParityReady, report.title)
            XCTAssertEqual(report.status, .passed, report.title)
            XCTAssertGreaterThanOrEqual(report.scoringProfile.maxPlayerScore, 12, report.title)
            XCTAssertEqual(report.completionRecord.score, report.scoringProfile.maxPlayerScore, report.title)
            XCTAssertEqual(report.completionRecord.victoryBand, .operational, report.title)
            XCTAssertEqual(report.completionRecord.persistenceKey, report.scoringProfile.persistenceKey, report.title)
            XCTAssertTrue(report.completionRecord.persistenceKey.contains(report.battlefieldID), report.title)
            XCTAssertFalse(report.debriefProfile.operationalText.isEmpty, report.title)
        }
    }

    func testCycle680LateCareerSetBRoutesIntoPlayableSurface() {
        let catalog = LateCareerPlayableSurfaceCatalog.self
        let setBIDs = LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs

        XCTAssertEqual(catalog.setBPlayableRouteIDs, setBIDs)
        XCTAssertTrue(setBIDs.allSatisfy { catalog.isRoutedToPlayableSurface($0) })
        XCTAssertEqual(
            LateCareerGuderianPresentationCatalog.allEntries
                .filter { setBIDs.contains($0.id) }
                .map(\.readiness),
            Array(repeating: LateCareerPlayableReadiness.playableParity, count: setBIDs.count)
        )
        XCTAssertEqual(Array(catalog.routedBattlefieldIDs.prefix(8).suffix(4)), setBIDs)
    }

    func testCycle685LateCareerSetBParityAddsAIAndBlockedActionCoverage() {
        let catalog = LateCareerPlayableSurfaceCatalog.self

        XCTAssertEqual(catalog.setBReports.map(\.battlefieldID), LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs)
        XCTAssertEqual(catalog.setBReports.count, 4)

        for report in catalog.setBReports {
            XCTAssertEqual(report.set, .setB, report.title)
            XCTAssertTrue(report.isParityReady, report.title)
            XCTAssertGreaterThanOrEqual(report.aiPlan.priorities.count, 2, report.title)
            XCTAssertGreaterThanOrEqual(report.aiPlan.blockedActionExpectations.count, 2, report.title)
            XCTAssertTrue(
                report.aiPlan.blockedActionExpectations.contains {
                    $0.reason.localizedCaseInsensitiveContains("not a Guderian field command")
                },
                report.title
            )
            XCTAssertTrue(report.debriefProfile.failureText.localizedCaseInsensitiveContains("not a Guderian field command"), report.title)
        }
    }

    func testCycle690LateCareerSetCRoutesWithGeneralStaffCaveats() throws {
        let catalog = LateCareerPlayableSurfaceCatalog.self
        let setCIDs = LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs

        XCTAssertEqual(catalog.setCPlayableRouteIDs, setCIDs)
        XCTAssertTrue(setCIDs.allSatisfy { catalog.isRoutedToPlayableSurface($0) })
        XCTAssertTrue(setCIDs.allSatisfy { catalog.aiPlan(for: $0) != nil })
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle690)

        for id in setCIDs {
            let entry = try XCTUnwrap(LateCareerGuderianPresentationCatalog.entry(for: id))
            XCTAssertEqual(entry.scope, .armyGeneralStaffInfluence, id)
            XCTAssertTrue(entry.visibleCommandCaveatLabel.localizedCaseInsensitiveContains("not a Guderian field command"), id)
        }
    }

    func testCycle695LateCareerSetCParityAddsScoringDebriefAndPersistence() {
        let catalog = LateCareerPlayableSurfaceCatalog.self

        XCTAssertEqual(catalog.setCParityIDs, LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs)
        XCTAssertEqual(catalog.setCReports.map(\.battlefieldID), catalog.setCParityIDs)
        XCTAssertEqual(catalog.setCReports.count, 4)

        for report in catalog.setCReports {
            XCTAssertEqual(report.set, .setC, report.title)
            XCTAssertTrue(report.isParityReady, report.title)
            XCTAssertEqual(report.completionRecord.score, report.scoringProfile.maxPlayerScore, report.title)
            XCTAssertEqual(report.completionRecord.victoryBand, .operational, report.title)
            XCTAssertTrue(report.debriefProfile.operationalText.localizedCaseInsensitiveContains("outside the 19-battle field-command campaign"), report.title)
            XCTAssertTrue(report.completionRecord.persistenceKey.contains(report.battlefieldID), report.title)
        }
    }

    func testCycle700LateCareerSetDRoutesWithPostDismissalCaveatsVisible() throws {
        let catalog = LateCareerPlayableSurfaceCatalog.self
        let setDIDs = LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs

        XCTAssertEqual(catalog.setDPlayableRouteIDs, setDIDs)
        XCTAssertTrue(setDIDs.allSatisfy { catalog.isRoutedToPlayableSurface($0) })
        XCTAssertEqual(Array(catalog.routedBattlefieldIDs.suffix(4)), setDIDs)

        let setDEntries = try setDIDs.map { id in
            try XCTUnwrap(LateCareerGuderianPresentationCatalog.entry(for: id))
        }
        XCTAssertEqual(setDEntries.filter { $0.scope == .postDismissalContext }.count, 2)
        XCTAssertTrue(setDEntries.allSatisfy { $0.visibleCommandCaveatLabel.localizedCaseInsensitiveContains("not a Guderian field command") })
    }

    func testCycle705LateCareerSetDParityAddsFinalWarDebriefHandling() {
        let catalog = LateCareerPlayableSurfaceCatalog.self

        XCTAssertEqual(catalog.setDParityIDs, LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs)
        XCTAssertEqual(catalog.setDReports.map(\.battlefieldID), catalog.setDParityIDs)
        XCTAssertEqual(catalog.setDReports.count, 4)

        for report in catalog.setDReports {
            XCTAssertEqual(report.set, .setD, report.title)
            XCTAssertTrue(report.isParityReady, report.title)
            XCTAssertTrue(report.debriefProfile.failureText.localizedCaseInsensitiveContains("historical context only"), report.title)
            XCTAssertGreaterThanOrEqual(report.aiPlan.blockedActionExpectations.count, 3, report.title)
        }

        XCTAssertEqual(catalog.parityReports.count, 16)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle710)
    }

    func testCycle710LateCareerAIAndRulesPlaybookConsolidatesAllSixteenBattlefields() {
        let catalog = LateCareerConsolidatedPlaybookCatalog.self
        let report = catalog.report

        XCTAssertEqual(catalog.cycleRange, 706...710)
        XCTAssertTrue(report.isReady)
        XCTAssertEqual(report.routedBattlefieldCount, 16)
        XCTAssertEqual(report.parityReadyBattlefieldCount, 16)
        XCTAssertEqual(report.aiPlanCount, 16)
        XCTAssertEqual(Set(report.coveredRuleFamilies), Set(LateCareerRuleFamily.allCases))
        XCTAssertEqual(report.commandCaveatRuleCount, 16)
        XCTAssertEqual(report.phaseLineRuleCount, 16)
        XCTAssertGreaterThanOrEqual(report.ruleBindingCount, 96)
        XCTAssertGreaterThanOrEqual(report.blockedActionExpectationCount, 48)

        for entry in LateCareerGuderianPresentationCatalog.allEntries {
            XCTAssertEqual(entry.readiness, .playableParity, entry.title)
            XCTAssertTrue(entry.isParityReady, entry.title)
            XCTAssertEqual(catalog.ruleBindings(for: entry.id).count, LateCareerRuleFamily.allCases.count, entry.title)
        }
    }

    func testCycle715LateCareerProgressTracksSeparatelyFromFieldCampaign() throws {
        var lateProgress = LateCareerProgress()
        let firstReport = try XCTUnwrap(LateCareerPlayableSurfaceCatalog.parityReports.first)

        lateProgress.recordCompletion(firstReport.completionRecord)
        let partialSummary = lateProgress.completionSummary()
        let fieldCampaignSummary = CampaignProgress().completionSummary(catalog: GuderianCampaignCatalog.all)

        XCTAssertEqual(partialSummary.totalBattlefields, 16)
        XCTAssertEqual(partialSummary.completedBattlefields, 1)
        XCTAssertEqual(partialSummary.remainingBattlefieldIDs.count, 15)
        XCTAssertEqual(partialSummary.totalScore, firstReport.completionRecord.score)
        XCTAssertEqual(fieldCampaignSummary.totalScenarios, 19)
        XCTAssertEqual(fieldCampaignSummary.completedScenarios, 0)
        XCTAssertEqual(GuderianCampaignCatalog.all.count, 19)
        XCTAssertEqual(LateCareerGuderianPresentationCatalog.totalSelectableEntryCount, 35)

        let encoded = try LateCareerProgressCodec.encode(lateProgress)
        let restored = try XCTUnwrap(LateCareerProgressCodec.decodeIfCurrent(encoded))
        XCTAssertEqual(restored, lateProgress)

        lateProgress.recordAllParityCompletions()
        let completeSummary = lateProgress.completionSummary()
        XCTAssertTrue(completeSummary.isComplete)
        XCTAssertEqual(completeSummary.completedBattlefields, 16)
        XCTAssertEqual(lateProgress.completionRecords.count, 16)
    }

    func testCycle720LateCareerAutomationRunsEveryContextBattleToDebrief() {
        let report = LateCareerAutomationCatalog.runAll

        XCTAssertEqual(report.cycleRange, 716...720)
        XCTAssertEqual(report.reports.count, 16)
        XCTAssertTrue(report.allPassed, report.reports.flatMap(\.issues).joined(separator: "\n"))
        XCTAssertEqual(report.passedCount, 16)
        XCTAssertEqual(report.issueCount, 0)
        XCTAssertTrue(report.completionSummary.isComplete)

        for battle in report.reports {
            XCTAssertEqual(battle.status, .passed, battle.title)
            XCTAssertTrue(battle.caveatVisible, battle.title)
            XCTAssertTrue(battle.mapDetailReady, battle.title)
            XCTAssertTrue(battle.aiPressureReady, battle.title)
            XCTAssertTrue(battle.scoringReady, battle.title)
            XCTAssertTrue(battle.persistenceReady, battle.title)
            XCTAssertTrue(battle.ruleBindingReady, battle.title)
            XCTAssertFalse(battle.accessibilityIdentifiers.isEmpty, battle.title)
            XCTAssertTrue(battle.issues.isEmpty, battle.title)
        }
    }

    func testCycle725LateCareerUXAuditCoversFiltersAccessibilitySourcesAndFinalWarCaveats() {
        let report = LateCareerUXAuditCatalog.report

        XCTAssertEqual(report.cycleRange, 721...725)
        XCTAssertTrue(report.isReady)
        XCTAssertTrue(report.items.allSatisfy(\.passed))
        XCTAssertEqual(Set(LateCareerScopeFilterSpec.allCases.map(\.rawValue)), ["All", "Inspector", "General Staff", "Epilogue"])
        XCTAssertGreaterThanOrEqual(report.accessibilityIdentifierCount, 64)
        XCTAssertGreaterThanOrEqual(report.sourceLinkCount, 16)
        XCTAssertEqual(report.finalWarCaveatCount, 2)
    }

    func testCycle730LateCareerFinalAcceptanceReportIsReady() {
        let report = LateCareerFinalAcceptanceCatalog.report

        XCTAssertEqual(report.cycleRange, 726...730)
        XCTAssertTrue(report.isReadyForAcceptance, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.fieldCommandCampaignCount, 19)
        XCTAssertEqual(report.lateCareerBattlefieldCount, 16)
        XCTAssertEqual(report.totalSelectableEntryCount, 35)
        XCTAssertEqual(report.playableCampaignRouteCount, 19)
        XCTAssertEqual(report.lateCareerParityCount, 16)
        XCTAssertTrue(report.lateCareerAutomationPassed)
        XCTAssertTrue(report.lateCareerProgressReady)
        XCTAssertTrue(report.lateCareerUXReady)
        XCTAssertTrue(report.playbookReady)
        XCTAssertTrue(report.buildCommands.contains("swift test"))
        XCTAssertTrue(report.buildCommands.contains("swift build"))
        XCTAssertTrue(report.buildCommands.contains { $0.contains("GuderianTest") })
        XCTAssertTrue(report.blockers.isEmpty)
    }

    func testCycle735UnifiedPlayableAcceptanceBarRetiresSeparateLateCareerTier() {
        let report = UnifiedPlayableAcceptanceCatalog.report

        XCTAssertEqual(report.cycleRange, 731...735)
        XCTAssertTrue(report.isReadyForUnifiedRollout, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.totalBattleCount, 35)
        XCTAssertEqual(report.fieldCommandBattleCount, 19)
        XCTAssertEqual(report.lateCareerBattleCount, 16)
        XCTAssertEqual(report.hostSurfaceName, PlayableBattleSurfaceCatalog.hostSurfaceName)
        XCTAssertEqual(report.requiredGates, PlayableBattleAcceptanceGate.allCases)
        XCTAssertTrue(report.retiredAcceptanceSurfaceNames.contains("LateCareerPlayablePilotView"))
        XCTAssertTrue(report.caveatPolicy.localizedCaseInsensitiveContains("historical labels"))
        XCTAssertTrue(report.blockers.isEmpty)
    }

    func testCycle740UnifiedBattleIdentityCoversAllThirtyFiveEntries() throws {
        let catalog = UnifiedGuderianBattleCatalog.self

        XCTAssertEqual(catalog.cycleRange, 736...740)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle740)
        XCTAssertEqual(catalog.allEntries.count, 35)
        XCTAssertEqual(catalog.fieldCommandEntries.count, 19)
        XCTAssertEqual(catalog.lateCareerEntries.count, 16)
        XCTAssertEqual(catalog.allEntries.map(\.order), Array(1...35))
        XCTAssertEqual(catalog.allEntries.map(\.hostSurfaceName), Array(repeating: PlayableBattleSurfaceCatalog.hostSurfaceName, count: 35))

        let tuchola = try XCTUnwrap(catalog.entry(for: .fieldCommand(.tucholaForest)))
        XCTAssertEqual(tuchola.title, "Battle of Tuchola Forest")
        XCTAssertNil(tuchola.caveatLabel)

        let kursk = try XCTUnwrap(catalog.entry(for: .lateCareer("kursk-armored-force-pressure")))
        XCTAssertEqual(kursk.order, 20)
        XCTAssertEqual(kursk.commandScope, .inspectorGeneralInfluence)
        XCTAssertTrue(kursk.caveatLabel?.localizedCaseInsensitiveContains("not a Guderian field command") == true)
    }

    func testCycle745LateCareerBoardAdapterCreatesNativeBattleShape() throws {
        let catalog = LateCareerNativeBattleInstanceCatalog.self

        XCTAssertEqual(catalog.cycleRange, 741...745)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle745)
        XCTAssertEqual(catalog.allInstances.count, 16)

        let kursk = try XCTUnwrap(catalog.instance(for: "kursk-armored-force-pressure"))
        XCTAssertTrue(kursk.isModeledForUnifiedNativeGameplay)
        XCTAssertEqual(kursk.commandScope, .inspectorGeneralInfluence)
        XCTAssertGreaterThanOrEqual(kursk.units.filter { $0.side == .player }.count, 2)
        XCTAssertGreaterThanOrEqual(kursk.units.filter { $0.side == .guderianAI }.count, 1)
        XCTAssertGreaterThanOrEqual(kursk.terrain.count, 20)
        XCTAssertGreaterThanOrEqual(kursk.objectives.count, 4)
        XCTAssertFalse(kursk.aiProfile.targetPriorities.isEmpty)
        XCTAssertTrue(kursk.caveatLabel.localizedCaseInsensitiveContains("not a Guderian field command"))

        let blueprint = kursk.engineBlueprint(seed: 745_001)
        XCTAssertTrue(blueprint.isCompleteForScenarioLoader)
        XCTAssertEqual(blueprint.id, kursk.id)
        XCTAssertEqual(blueprint.missionTargetScore, kursk.victory.missionTargetScore)
    }

    func testCycle750LateCareerSessionLoaderCreatesScenarioSpecificBoard() throws {
        let loader = LateCareerNativeScenarioLoader.self

        XCTAssertEqual(loader.cycleRange, 746...750)
        XCTAssertTrue(loader.acceptanceReadyThroughCycle750)
        XCTAssertEqual(loader.allLoadouts.count, 16)
        XCTAssertTrue(loader.allLoadouts.allSatisfy(\.canCreateSkirmishBridge))
        XCTAssertTrue(loader.allLoadouts.allSatisfy(\.canApplyScenarioBoardHook))
        XCTAssertTrue(loader.allLoadouts.allSatisfy { $0.playerArmyName == "Soviet" })
        XCTAssertTrue(loader.allLoadouts.allSatisfy { $0.opponentArmyName == "German" })

        let loadout = try XCTUnwrap(loader.load("kursk-armored-force-pressure", seed: 750_001))
        XCTAssertTrue(loadout.warnings.isEmpty, loadout.warnings.map(\.detail).joined(separator: "\n"))

        let game = try XCTUnwrap(loadout.makeGame())
        XCTAssertTrue(game.boardReport.isScenarioSpecific, game.boardReport.notes.joined(separator: "\n"))
        XCTAssertTrue(game.deploymentReport.placedAnyScenarioUnit, game.deploymentReport.notes.joined(separator: "\n"))
        XCTAssertGreaterThan(Int(game_unit_count(game.handle)), 0)
        XCTAssertGreaterThan(Int(game_objective_count(game.handle)), 0)
        XCTAssertGreaterThan(Int(game_zone_count(game.handle)), 0)

        let session = try XCTUnwrap(LateCareerNativeBoardSession(battlefieldID: "kursk-armored-force-pressure", seed: 750_002))
        let snapshot = session.lateCareerSnapshot()
        XCTAssertTrue(snapshot.isScenarioBoardPlayable)
        XCTAssertEqual(snapshot.battlefieldID, "kursk-armored-force-pressure")
        XCTAssertEqual(snapshot.mission.targetScore, loadout.blueprint.missionTargetScore)
    }

    func testCycle755UnifiedCampaignListRemovesVisibleSplit() throws {
        let catalog = UnifiedCampaignListCatalog.self

        XCTAssertEqual(catalog.cycleRange, 751...755)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle755)
        XCTAssertEqual(catalog.sectionTitle, "Battles")
        XCTAssertTrue(catalog.legacySectionTitlesRemoved.contains("Scenarios"))
        XCTAssertTrue(catalog.legacySectionTitlesRemoved.contains("Late Career Context"))

        var campaignProgress = CampaignProgress()
        let tuchola = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        campaignProgress.recordCompletion(
            CampaignCompletionRecord(
                scenarioID: tuchola.id,
                score: 12,
                victoryBand: .operational,
                completedTurn: 3,
                note: "Unified row state smoke completion."
            )
        )
        var lateCareerProgress = LateCareerProgress()
        lateCareerProgress.recordAllParityCompletions()

        let rows = catalog.rows(
            progress: campaignProgress,
            lateCareerProgress: lateCareerProgress,
            playMode: .standalone
        )

        XCTAssertEqual(rows.count, 35)
        XCTAssertEqual(rows.map(\.order), Array(1...35))
        XCTAssertTrue(rows.allSatisfy(\.usesUnifiedCampaignListTreatment))
        XCTAssertTrue(rows.allSatisfy { $0.playAffordanceTitle == "Play" })
        XCTAssertTrue(rows.allSatisfy { $0.hostSurfaceName == PlayableBattleSurfaceCatalog.hostSurfaceName })
        XCTAssertEqual(Set(rows.map(\.rowStyleIdentifier)), Set([UnifiedCampaignListCatalog.rowStyleIdentifier]))

        let tucholaRow = try XCTUnwrap(catalog.row(for: .fieldCommand(.tucholaForest), progress: campaignProgress))
        XCTAssertEqual(tucholaRow.completionState, .complete)
        XCTAssertEqual(tucholaRow.availability, .available)
        XCTAssertEqual(tucholaRow.navigationTreatment, .playableBattle)

        let kurskRow = try XCTUnwrap(catalog.row(for: .lateCareer("kursk-armored-force-pressure"), lateCareerProgress: lateCareerProgress))
        XCTAssertEqual(kurskRow.order, 20)
        XCTAssertEqual(kurskRow.completionState, .complete)
        XCTAssertEqual(kurskRow.availability, .available)
        XCTAssertTrue(kurskRow.caveatLabel?.localizedCaseInsensitiveContains("not a Guderian field command") == true)
    }

    func testCycle760UnifiedBriefingShellRemovesPilotContextCopy() throws {
        let catalog = UnifiedBattleBriefingCatalog.self

        XCTAssertEqual(catalog.cycleRange, 756...760)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle760)
        XCTAssertEqual(catalog.allShells.count, 35)
        XCTAssertTrue(catalog.allShells.allSatisfy(\.usesSharedBriefingShell))
        XCTAssertTrue(catalog.allShells.allSatisfy { $0.hostSurfaceName == PlayableBattleSurfaceCatalog.hostSurfaceName })
        XCTAssertTrue(catalog.allShells.allSatisfy { $0.retiredSurfaceNames.contains("LateCareerPlayablePilotView") })
        XCTAssertFalse(catalog.allShells.contains { $0.displayText.localizedCaseInsensitiveContains("pilot") })
        XCTAssertFalse(catalog.allShells.contains { $0.displayText.localizedCaseInsensitiveContains("context-only") })

        let smolensk = try XCTUnwrap(catalog.shell(for: .fieldCommand(.smolensk)))
        XCTAssertTrue(smolensk.sectionKinds.contains(.playerForce))
        XCTAssertTrue(smolensk.sectionKinds.contains(.germanContext))
        XCTAssertTrue(smolensk.sectionKinds.contains(.objectives))

        let kursk = try XCTUnwrap(catalog.shell(for: .lateCareer("kursk-armored-force-pressure")))
        XCTAssertEqual(kursk.briefingAccessibilityIdentifier, "unified-battle-briefing-kursk-armored-force-pressure")
        XCTAssertTrue(kursk.caveatLabels.joined(separator: " ").localizedCaseInsensitiveContains("not a Guderian field command"))
        XCTAssertTrue(kursk.sectionKinds.contains(.rules))
        XCTAssertFalse(kursk.sourceLinks.isEmpty)
    }

    func testCycle765SetABoardParityRoutesInspectorGeneralBattles() throws {
        let catalog = UnifiedPlayableBoardRouteCatalog.self

        XCTAssertEqual(catalog.cycleRange, 761...780)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle765)
        XCTAssertEqual(catalog.lateCareerRoutedIDsThroughCycle765, LateCareerStaffBattlefieldSetACatalog.battlefieldIDs)
        XCTAssertEqual(catalog.lateCareerRoutesThroughCycle765.count, 4)
        XCTAssertTrue(catalog.lateCareerRoutesThroughCycle765.allSatisfy(\.isFullPlayableBoardRoute))
        XCTAssertTrue(catalog.lateCareerRoutesThroughCycle765.allSatisfy { $0.commandScope == .inspectorGeneralInfluence })

        let kurskRoute = try XCTUnwrap(catalog.route(for: .lateCareer("kursk-armored-force-pressure")))
        XCTAssertEqual(kurskRoute.cycleRange, 761...765)
        XCTAssertEqual(kurskRoute.hostSurfaceName, PlayableBattleSurfaceCatalog.hostSurfaceName)
        XCTAssertEqual(kurskRoute.acceptanceGates, PlayableBattleAcceptanceGate.allCases)
        XCTAssertTrue(kurskRoute.supportsSelectableUnits)
        XCTAssertTrue(kurskRoute.supportsDraggedMovement)
        XCTAssertTrue(kurskRoute.supportsPhaseControls)
        XCTAssertTrue(kurskRoute.supportsCombatActions)
        XCTAssertTrue(kurskRoute.supportsBlockedActionFeedback)
        XCTAssertTrue(kurskRoute.supportsGermanAIRunner)
        XCTAssertTrue(kurskRoute.supportsDebriefPersistence)

        let session = try XCTUnwrap(LateCareerNativeBoardSession(battlefieldID: "kursk-armored-force-pressure", seed: 765_001))
        let snapshot = session.lateCareerSnapshot()
        XCTAssertTrue(snapshot.isScenarioBoardPlayable)
        XCTAssertGreaterThan(snapshot.unitCount, 0)
        XCTAssertGreaterThan(snapshot.objectiveCount, 0)
    }

    func testCycle770SetBBoardParityRoutesGeneralStaffBattles() throws {
        let catalog = UnifiedPlayableBoardRouteCatalog.self

        XCTAssertEqual(catalog.cycleRange, 761...780)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle770)
        XCTAssertEqual(catalog.lateCareerRoutedIDsThroughCycle770, LateCareerStaffBattlefieldSetACatalog.battlefieldIDs + LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs)
        XCTAssertEqual(catalog.lateCareerRoutesThroughCycle770.count, 8)
        XCTAssertEqual(catalog.allRoutesThroughCycle770.count, 27)
        XCTAssertTrue(catalog.lateCareerRoutesThroughCycle770.allSatisfy(\.isFullPlayableBoardRoute))

        let setBRoutes = Array(catalog.lateCareerRoutesThroughCycle770.suffix(4))
        XCTAssertEqual(setBRoutes.map { $0.id.rawValue }, LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs)
        XCTAssertTrue(setBRoutes.allSatisfy { $0.commandScope == .armyGeneralStaffInfluence })
        XCTAssertTrue(setBRoutes.allSatisfy { $0.caveatLabel?.localizedCaseInsensitiveContains("not a Guderian field command") == true })

        let bagrationRoute = try XCTUnwrap(catalog.route(for: .lateCareer("operation-bagration-withdrawal")))
        XCTAssertEqual(bagrationRoute.cycleRange, 766...770)
        XCTAssertTrue(bagrationRoute.completionPersistenceKey.contains("operation-bagration-withdrawal"))

        let loadout = try XCTUnwrap(LateCareerNativeScenarioLoader.load("operation-bagration-withdrawal", seed: 770_001))
        let game = try XCTUnwrap(loadout.makeGame())
        XCTAssertGreaterThan(Int(game_unit_count(game.handle)), 0)
        XCTAssertGreaterThan(Int(game_objective_count(game.handle)), 0)
        XCTAssertGreaterThan(Int(game_zone_count(game.handle)), 0)
    }

    func testCycle775SetCBoardParityRoutesGeneralStaffCollapseBattles() throws {
        let catalog = UnifiedPlayableBoardRouteCatalog.self

        XCTAssertTrue(catalog.acceptanceReadyThroughCycle775)
        XCTAssertEqual(catalog.lateCareerRoutedIDsThroughCycle775, LateCareerStaffBattlefieldSetACatalog.battlefieldIDs + LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs + LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs)
        XCTAssertEqual(catalog.lateCareerRoutesThroughCycle775.count, 12)
        XCTAssertTrue(catalog.lateCareerRoutesThroughCycle775.allSatisfy(\.isFullPlayableBoardRoute))

        let setCRoutes = Array(catalog.lateCareerRoutesThroughCycle775.suffix(4))
        XCTAssertEqual(setCRoutes.map { $0.id.rawValue }, LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs)
        XCTAssertTrue(setCRoutes.allSatisfy { $0.commandScope == .armyGeneralStaffInfluence })

        let vistulaOderRoute = try XCTUnwrap(catalog.route(for: .lateCareer("vistula-oder-breakthrough")))
        XCTAssertEqual(vistulaOderRoute.cycleRange, 771...775)
        XCTAssertTrue(vistulaOderRoute.supportsGermanAIRunner)

        let session = try XCTUnwrap(LateCareerNativeBoardSession(battlefieldID: "vistula-oder-breakthrough", seed: 775_001))
        let snapshot = session.lateCareerSnapshot()
        XCTAssertTrue(snapshot.isScenarioBoardPlayable)
        XCTAssertGreaterThan(snapshot.unitCount, 0)
        XCTAssertGreaterThan(snapshot.objectiveCount, 0)
    }

    func testCycle780SetDBoardParityRoutesFinalWarAndEpilogueBattles() throws {
        let catalog = UnifiedPlayableBoardRouteCatalog.self

        XCTAssertTrue(catalog.acceptanceReadyThroughCycle780)
        XCTAssertEqual(catalog.lateCareerRoutedIDsThroughCycle780, LateCareerStaffBattlefieldSetACatalog.battlefieldIDs + LateCareerStaffBattlefieldSetBCatalog.battlefieldIDs + LateCareerStaffBattlefieldSetCCatalog.battlefieldIDs + LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs)
        XCTAssertEqual(catalog.lateCareerRoutesThroughCycle780.count, 16)
        XCTAssertEqual(catalog.allRoutesThroughCycle780.count, 35)
        XCTAssertTrue(catalog.lateCareerRoutesThroughCycle780.allSatisfy(\.isFullPlayableBoardRoute))

        let setDRoutes = Array(catalog.lateCareerRoutesThroughCycle780.suffix(4))
        XCTAssertEqual(setDRoutes.map { $0.id.rawValue }, LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs)
        XCTAssertEqual(setDRoutes.filter { $0.commandScope == .postDismissalContext }.count, 2)
        XCTAssertTrue(setDRoutes.allSatisfy { $0.caveatLabel?.localizedCaseInsensitiveContains("not a Guderian field command") == true })

        let berlinRoute = try XCTUnwrap(catalog.route(for: .lateCareer("berlin-halbe-epilogue")))
        XCTAssertEqual(berlinRoute.cycleRange, 776...780)
        XCTAssertEqual(berlinRoute.commandScope, .postDismissalContext)
        XCTAssertTrue(berlinRoute.supportsDebriefPersistence)

        let loadout = try XCTUnwrap(LateCareerNativeScenarioLoader.load("berlin-halbe-epilogue", seed: 780_001))
        let game = try XCTUnwrap(loadout.makeGame())
        XCTAssertGreaterThan(Int(game_unit_count(game.handle)), 0)
        XCTAssertGreaterThan(Int(game_objective_count(game.handle)), 0)
    }

    func testCycle785UnifiedLateCareerAIExecutesLiveBoardRunner() throws {
        let catalog = UnifiedLateCareerAIExecutionCatalog.self

        XCTAssertEqual(catalog.cycleRange, 781...785)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle785)
        XCTAssertEqual(catalog.allReports.count, 16)
        XCTAssertEqual(catalog.allReports.map(\.battlefieldID), UnifiedPlayableBoardRouteCatalog.lateCareerRoutedIDsThroughCycle780)
        XCTAssertTrue(catalog.allReports.allSatisfy(\.completedGermanTurnRunner))
        XCTAssertTrue(catalog.allReports.allSatisfy { $0.germanTurnRunnerName == UnifiedLateCareerAIExecutionCatalog.germanTurnRunnerName })

        let report = try XCTUnwrap(catalog.report(for: "kustrin-oder-bridgeheads", seed: 785_001))
        XCTAssertTrue(report.completedGermanTurnRunner, report.blockers.joined(separator: "\n"))
        XCTAssertTrue(report.steps.contains { $0.activePlayer == .guderianAI })
        XCTAssertTrue(report.steps.contains { $0.usedLegalBoardAction || $0.reportedBlockedMove })
        XCTAssertFalse(report.targetPriorityNames.isEmpty)
        XCTAssertTrue(report.boardSnapshot.isScenarioBoardPlayable)
    }

    func testCycle790UnifiedScoringAndDebriefUsesCompletionResolverPattern() throws {
        let catalog = UnifiedLateCareerScoringDebriefCatalog.self

        XCTAssertEqual(catalog.cycleRange, 786...790)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle790)
        XCTAssertEqual(catalog.completionSummaries.count, 16)
        XCTAssertEqual(catalog.failureSummaries.count, 16)
        XCTAssertTrue(catalog.completionSummaries.allSatisfy(\.isResolvedThroughUnifiedPattern))
        XCTAssertTrue(catalog.failureSummaries.allSatisfy(\.isResolvedThroughUnifiedPattern))
        XCTAssertEqual(Set(catalog.completionSummaries.map(\.persistenceKey)).count, 16)
        XCTAssertTrue(catalog.failureSummaries.allSatisfy { $0.completionRecord.victoryBand == .historicalPressure })

        let session = try XCTUnwrap(LateCareerNativeBoardSession(battlefieldID: "berlin-halbe-epilogue", seed: 790_001))
        let summary = try XCTUnwrap(UnifiedLateCareerCompletionResolver.completeBattle(from: session))
        XCTAssertEqual(summary.sourceName, UnifiedLateCareerCompletionResolver.sourceName)
        XCTAssertTrue(summary.isResolvedThroughUnifiedPattern)
        XCTAssertTrue(summary.persistenceKey.contains("berlin-halbe-epilogue"))
        XCTAssertTrue(summary.scoreBands.contains { $0.victoryBand == .operational })
        XCTAssertTrue(summary.scoreBands.contains { $0.victoryBand == .historicalPressure })
        XCTAssertTrue(summary.failureHandling.localizedCaseInsensitiveContains("failure"))
        XCTAssertEqual(summary.completionRecord.note, summary.debriefSummary)
    }

    func testCycle795UnifiedProgressPresentsOneThirtyFiveBattleSummary() throws {
        let catalog = UnifiedCampaignProgressCatalog.self

        XCTAssertEqual(catalog.cycleRange, 791...795)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle795)

        let progress = catalog.completedProgress
        let summary = progress.summary()
        XCTAssertTrue(summary.isComplete)
        XCTAssertEqual(summary.totalBattleCount, 35)
        XCTAssertEqual(summary.completedBattleCount, 35)
        XCTAssertEqual(summary.progressLabel, "35 of 35 complete")
        XCTAssertEqual(summary.completionTitle, "Unified Campaign Complete")
        XCTAssertTrue(summary.remainingBattleIDs.isEmpty)
        XCTAssertTrue(summary.filtersAreOptionalViews)
        XCTAssertEqual(progress.fieldCommandProgress.completedCount, 19)
        XCTAssertEqual(progress.lateCareerProgress.completionSummary().completedBattlefields, 16)

        let berlin = UnifiedGuderianBattleID.lateCareer("berlin-halbe-epilogue")
        XCTAssertTrue(progress.isCompleted(berlin))
        XCTAssertEqual(progress.completionRecord(for: berlin)?.source, .lateCareer)
    }

    func testCycle800UnifiedSaveEnvelopeMigratesLegacyCampaignAndLateCareerSaves() throws {
        let codec = UnifiedCampaignSaveCodec.self

        XCTAssertEqual(codec.cycleRange, 796...800)
        XCTAssertTrue(codec.acceptanceReadyThroughCycle800)

        var campaignProgress = CampaignProgress()
        campaignProgress.recordCompletion(
            CampaignCompletionRecord(
                scenarioID: .tucholaForest,
                score: 12,
                victoryBand: .operational,
                completedTurn: 4,
                note: "Legacy campaign completion."
            )
        )
        let campaignState = CampaignSaveState(
            selectedScenarioID: .tucholaForest,
            playMode: .standalone,
            progress: campaignProgress
        )
        var lateCareerProgress = LateCareerProgress()
        let lateSummary = try XCTUnwrap(UnifiedLateCareerScoringDebriefCatalog.completionSummaries.first)
        lateCareerProgress.recordCompletion(lateSummary.completionRecord)

        let migrated = codec.migrate(campaignState: campaignState, lateCareerProgress: lateCareerProgress)
        XCTAssertTrue(migrated.isCurrentSchema)
        XCTAssertTrue(migrated.preservesLegacyProgress)
        XCTAssertEqual(migrated.selectedBattleID, .fieldCommand(.tucholaForest))
        XCTAssertEqual(migrated.playMode, .standalone)
        XCTAssertEqual(migrated.progress.completedCount, 2)
        XCTAssertEqual(migrated.migratedFromCampaignSaveVersion, CampaignSaveState.currentSchemaVersion)
        XCTAssertEqual(migrated.migratedLateCareerProgressVersion, 1)
        XCTAssertTrue(migrated.migrationNote.localizedCaseInsensitiveContains("migrated"))

        let encoded = try codec.encode(migrated)
        let decoded = try XCTUnwrap(codec.decodeIfCurrent(encoded))
        XCTAssertEqual(decoded.schemaVersion, migrated.schemaVersion)
        XCTAssertEqual(decoded.selectedBattleID, migrated.selectedBattleID)
        XCTAssertEqual(decoded.playMode, migrated.playMode)
        XCTAssertEqual(decoded.progress, migrated.progress)
        XCTAssertEqual(decoded.migratedFromCampaignSaveVersion, migrated.migratedFromCampaignSaveVersion)
        XCTAssertEqual(decoded.migratedLateCareerProgressVersion, migrated.migratedLateCareerProgressVersion)
    }

    func testCycle805UnifiedPlayableHarnessRunsAllThirtyFiveBattles() throws {
        let harness = UnifiedPlayableScreenHarness.self

        XCTAssertEqual(harness.cycleRange, 801...805)
        XCTAssertTrue(harness.acceptanceReadyThroughCycle805)

        let results = try harness.runAll35FlowsThroughCycle805()
        XCTAssertEqual(results.count, 35)
        XCTAssertEqual(results.map(\.id), UnifiedGuderianBattleCatalog.allEntries.map(\.id))
        XCTAssertTrue(results.allSatisfy(\.completedAllStages))
        XCTAssertTrue(results.allSatisfy(\.usesUnifiedHarnessSurface))
        XCTAssertTrue(results.allSatisfy { $0.completedStages == DZWPlayableScreenHarnessStage.allCases })
        XCTAssertTrue(results.allSatisfy { $0.displayedAccessibilityIdentifiers.contains("battle-action-feedback") })
        XCTAssertTrue(results.allSatisfy { $0.displayedAccessibilityIdentifiers.contains("battle-debrief-panel") })
        XCTAssertEqual(results.filter { $0.id.kind == .fieldCommand }.count, 19)
        XCTAssertEqual(results.filter { $0.id.kind == .lateCareer }.count, 16)

        let berlin = try XCTUnwrap(results.first { $0.id == .lateCareer("berlin-halbe-epilogue") })
        XCTAssertTrue(berlin.completionPersistenceKey.contains("berlin-halbe-epilogue"))
        XCTAssertTrue(berlin.displayedAccessibilityIdentifiers.contains("german-turn-button"))
    }

    func testCycle810UnifiedUIParityAuditFindsNoSeparateLateCareerTier() {
        let catalog = UnifiedUIParityAuditCatalog.self
        let report = catalog.report

        XCTAssertEqual(report.cycleRange, 806...810)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle810)
        XCTAssertTrue(report.isReady)
        XCTAssertEqual(report.totalBattleCount, 35)
        XCTAssertEqual(Set(report.rowStyleIdentifiers), Set([UnifiedCampaignListCatalog.rowStyleIdentifier]))
        XCTAssertEqual(Set(report.playAffordanceTitles), Set([UnifiedCampaignListCatalog.playAffordanceTitle]))
        XCTAssertEqual(Set(report.hostSurfaceNames), Set([UnifiedGuderianBattleCatalog.hostSurfaceName]))
        XCTAssertTrue(report.retiredSurfaceNames.contains("LateCareerPlayablePilotView"))
        XCTAssertTrue(report.retiredSurfaceNames.contains("LateCareerContextBriefingView"))
        XCTAssertTrue(report.items.allSatisfy(\.passed))
        XCTAssertEqual(report.caveatLabelOnlyCount, UnifiedGuderianBattleCatalog.allEntries.filter { $0.caveatLabel != nil }.count)
    }

    func testCycle815UnifiedBalancePacingAuditCoversLateCareerBattles() {
        let report = UnifiedBalancePacingAuditCatalog.report

        XCTAssertEqual(report.cycleRange, 811...815)
        XCTAssertTrue(UnifiedBalancePacingAuditCatalog.acceptanceReadyThroughCycle815, report.blockers.joined(separator: "\n"))
        XCTAssertTrue(report.isReady, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.firstNineteenReferenceBattleCount, 19)
        XCTAssertEqual(report.lateCareerAuditCount, 16)
        XCTAssertEqual(report.passedLateCareerIDs, UnifiedPlayableBoardRouteCatalog.lateCareerRoutedIDsThroughCycle780)
        XCTAssertTrue(report.audits.allSatisfy(\.isPlayableLikeFirstNineteen))
        XCTAssertTrue(report.audits.allSatisfy { $0.terrainFeatureCount >= report.minimumTerrainFeatureCount })
        XCTAssertTrue(report.audits.allSatisfy { $0.mobilityProfileCount >= report.minimumMobilityProfileCount })
        XCTAssertTrue(report.audits.allSatisfy { $0.minimumObjectiveSpacing >= report.minimumObjectiveSpacing })
        XCTAssertTrue(report.blockers.isEmpty)
    }

    func testCycle820ReadmeBattleChronologyListsAllThirtyFiveWithLinks() throws {
        let report = UnifiedDocumentationCleanupCatalog.report
        let readme = try readmeText()
        let plan = try planText()
        let chronologyRows = battleChronologyRows(in: readme)

        XCTAssertEqual(report.cycleRange, 816...820)
        XCTAssertTrue(report.isReady, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(chronologyRows.count, 35)
        XCTAssertEqual(report.expectedBattleChronologyRowCount, 35)
        XCTAssertEqual(report.lateCareerChronologyRowCount, 16)

        for expected in report.expectedRows.filter({ $0.id.kind == .lateCareer }) {
            let row = try XCTUnwrap(
                chronologyRows.first { $0.contains("| \(expected.order) |") },
                "README needs chronology row \(expected.order) for \(expected.title)"
            )
            XCTAssertTrue(row.contains(expected.title), expected.title)
            XCTAssertTrue(row.contains(expected.primarySourceURL.absoluteString), expected.title)
            XCTAssertTrue(row.contains(expected.commandScopeLabel), expected.title)
            XCTAssertTrue(row.localizedCaseInsensitiveContains("not a Guderian field command"), expected.title)
        }

        for phrase in report.requiredReadmePhrases {
            XCTAssertTrue(
                readme.localizedCaseInsensitiveContains(phrase) ||
                    plan.localizedCaseInsensitiveContains(phrase),
                phrase
            )
        }
        XCTAssertTrue(plan.contains("Cycle 830 update"))
        XCTAssertTrue(plan.localizedCaseInsensitiveContains("no cycles remaining"))
    }

    func testCycle825UnifiedBuildRegressionHardeningReportIsReady() {
        let report = UnifiedBuildRegressionHardeningCatalog.report

        XCTAssertEqual(report.cycleRange, 821...825)
        XCTAssertTrue(UnifiedBuildRegressionHardeningCatalog.acceptanceReadyThroughCycle825, report.blockers.joined(separator: "\n"))
        XCTAssertTrue(report.isReady, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.fullHarnessBattleCount, 35)
        XCTAssertTrue(report.saveMigrationReady)
        XCTAssertTrue(report.uiParityReady)
        XCTAssertTrue(report.balancePacingReady)
        XCTAssertTrue(report.documentationReady)
        XCTAssertTrue(report.gates.allSatisfy(\.passed))
        XCTAssertTrue(report.buildCommands.contains("swift build"))
        XCTAssertTrue(report.buildCommands.contains("swift test"))
        XCTAssertTrue(report.buildCommands.contains { $0.contains("xcodebuild") && $0.contains("GuderianTest") })
    }

    func testCycle830UnifiedCampaignAcceptanceShipsSingleThirtyFiveBattleCampaign() throws {
        let readme = try readmeText()
        let chronologyRows = battleChronologyRows(in: readme)
        let report = UnifiedCampaignAcceptanceCatalog.report(readmeBattleChronologyRows: chronologyRows.count)

        XCTAssertEqual(report.cycleRange, 826...830)
        XCTAssertTrue(UnifiedCampaignAcceptanceCatalog.acceptanceReadyThroughCycle830, report.blockers.joined(separator: "\n"))
        XCTAssertTrue(report.isReadyForUnifiedCampaignShip, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.totalBattleCount, 35)
        XCTAssertEqual(report.fieldCommandBattleCount, 19)
        XCTAssertEqual(report.lateCareerBattleCount, 16)
        XCTAssertEqual(report.readmeBattleChronologyRows, 35)
        XCTAssertEqual(report.hostSurfaceName, PlayableBattleSurfaceCatalog.hostSurfaceName)
        XCTAssertTrue(report.allBattlesUseSameUI)
        XCTAssertTrue(report.allBattlesCompleteFromLaunchToPersistence)
        XCTAssertTrue(report.caveatsRemainHistoricalOnly)
        XCTAssertTrue(report.noSeparateLateCareerGameplayTier)
        XCTAssertEqual(report.remainingCycles, 0)
        XCTAssertTrue(report.blockers.isEmpty)
    }

    func testCycle890LateCareerBattlesUseRealDZWPlayableBoardParity() throws {
        let catalog = UnifiedRealDZWPlayableParityCatalog.self
        let report = catalog.report

        XCTAssertEqual(report.cycleRange, 831...890)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle890, report.blockers.joined(separator: "\n"))
        XCTAssertTrue(report.isReady, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.totalBattleCount, 35)
        XCTAssertEqual(report.fieldCommandBattleCount, 19)
        XCTAssertEqual(report.lateCareerBattleCount, 16)
        XCTAssertEqual(report.requiredHostSurfaceName, PlayableBattleSurfaceCatalog.hostSurfaceName)
        XCTAssertTrue(report.forbiddenHostSurfaceNames.contains("LateCareerUnifiedPlayableBoardView"))
        XCTAssertTrue(report.forbiddenHostSurfaceNames.contains("LateCareerMapSurface"))
        XCTAssertEqual(report.lateCareerReports.map(\.id), UnifiedPlayableBoardRouteCatalog.lateCareerRoutedIDsThroughCycle780)
        XCTAssertTrue(report.lateCareerReports.allSatisfy(\.passesRealDZWParity), report.blockers.joined(separator: "\n"))
        XCTAssertTrue(report.lateCareerReports.allSatisfy { $0.snapshotTypeName == "NativeBoardSnapshot" })
        XCTAssertTrue(report.lateCareerReports.allSatisfy { $0.hostSurfaceName == PlayableBattleSurfaceCatalog.hostSurfaceName })
        XCTAssertTrue(report.lateCareerReports.allSatisfy { !$0.forbiddenSurfaceNames.contains($0.hostSurfaceName) })
        XCTAssertTrue(report.lateCareerReports.allSatisfy { $0.commandActionStatus != .idle })
        XCTAssertTrue(report.lateCareerReports.allSatisfy(\.phaseAdvanced))

        let kursk = try XCTUnwrap(report.lateCareerReports.first { $0.id == "kursk-armored-force-pressure" })
        XCTAssertGreaterThan(kursk.openingUnitCount, 0)
        XCTAssertGreaterThan(kursk.openingObjectiveCount, 0)
        XCTAssertGreaterThan(kursk.openingZoneCount, 0)
        XCTAssertFalse(kursk.selectedUnitName.isEmpty)
        XCTAssertTrue(kursk.completionPersistenceKey.contains("kursk-armored-force-pressure"))
    }

    func testCycle910FirstRunTutorialModelContentAndPersistenceAreReady() throws {
        let catalog = GuderianTutorialCatalog.self
        let flow = catalog.firstRunHistoryFlow

        XCTAssertEqual(catalog.cycleRange, 891...930)
        XCTAssertEqual(catalog.firstRunCycleRange, 891...910)
        XCTAssertEqual(catalog.firstBattleCycleRange, 911...930)
        XCTAssertTrue(catalog.acceptanceReadyThroughCycle910)
        XCTAssertEqual(flow.id, .firstRunHistory)
        XCTAssertEqual(flow.version, 1)
        XCTAssertEqual(flow.presentationKind, .pagedOnboarding)
        XCTAssertEqual(flow.openingTrigger, .appFirstLaunch)
        XCTAssertEqual(flow.pages.count, 4)
        XCTAssertEqual(flow.doNotShowAgainLabel, "Do not show again")
        XCTAssertEqual(flow.storageKey, catalog.firstRunHistoryStorageKey)
        XCTAssertEqual(catalog.firstBattleGuidanceFlow.storageKey, catalog.firstBattleGuidanceStorageKey)
        XCTAssertTrue(flow.usesReusableStorageContract)
        XCTAssertTrue(catalog.firstBattleGuidanceFlow.usesReusableStorageContract)
        XCTAssertTrue(flow.pages.allSatisfy { (80...125).contains($0.wordCount) })
        XCTAssertTrue(flow.pages.allSatisfy(\.containsRequiredTopics))
        XCTAssertTrue(flow.pages.allSatisfy { $0.accessibilityIdentifier.hasPrefix("first-run-history-page-") })
        let openingPage = try XCTUnwrap(flow.pages.first)
        XCTAssertTrue(openingPage.body.contains("World War II"))
        XCTAssertTrue(openingPage.body.contains("Nazi Germany"))
        XCTAssertTrue(openingPage.body.contains("Adolf Hitler"))
        XCTAssertTrue(openingPage.body.localizedCaseInsensitiveContains("Nazi regime"))

        var progress = TutorialProgress()
        XCTAssertTrue(progress.shouldPresent(flow))
        progress.dismiss(flow)
        XCTAssertFalse(progress.shouldPresent(flow))

        let encoded = try TutorialProgressCodec.encode(progress)
        let decoded = try TutorialProgressCodec.decode(encoded)
        XCTAssertEqual(decoded, progress)
        XCTAssertFalse(TutorialProgressCodec.decodeIfPresent(encoded).shouldPresent(flow))

        let revisedFlow = TutorialFlow(
            id: flow.id,
            version: flow.version + 1,
            title: flow.title,
            presentationKind: flow.presentationKind,
            storageKey: TutorialStorageKey("guderian.tutorial.firstRunHistory.v2.dismissed"),
            openingTrigger: flow.openingTrigger,
            pages: flow.pages
        )
        XCTAssertTrue(progress.shouldPresent(revisedFlow))

        progress.reset(.firstRunHistory)
        XCTAssertTrue(progress.shouldPresent(flow))
    }

    func testCycle930FirstBattleTutorialHintsPersistenceAndAcceptanceAreReady() throws {
        let flow = GuderianTutorialCatalog.firstBattleGuidanceFlow
        let report = GuderianTutorialAcceptanceCatalog.report

        XCTAssertEqual(GuderianTutorialAcceptanceCatalog.cycleRange, 911...930)
        XCTAssertTrue(GuderianTutorialCatalog.acceptanceReadyThroughCycle930)
        XCTAssertTrue(GuderianTutorialAcceptanceCatalog.acceptanceReadyThroughCycle930, report.blockers.joined(separator: "\n"))
        XCTAssertTrue(report.isReady, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.remainingCycles, 0)
        XCTAssertEqual(report.firstBattleHintCount, GuderianTutorialCatalog.requiredFirstBattleTriggers.count)

        XCTAssertEqual(flow.id, .firstBattleGuidance)
        XCTAssertEqual(flow.version, 1)
        XCTAssertEqual(flow.presentationKind, .contextualBattleHints)
        XCTAssertEqual(flow.openingTrigger, .battleOpened)
        XCTAssertEqual(flow.doNotShowAgainLabel, "Do not show again")
        XCTAssertEqual(flow.storageKey, GuderianTutorialCatalog.firstBattleGuidanceStorageKey)
        XCTAssertTrue(flow.usesReusableStorageContract)
        XCTAssertTrue(flow.pages.isEmpty)
        XCTAssertEqual(flow.hints.count, 11)
        XCTAssertEqual(flow.orderedHints.map(\.order), Array(1...11))
        XCTAssertEqual(Set(flow.hints.map(\.trigger)), Set(GuderianTutorialCatalog.requiredFirstBattleTriggers))
        XCTAssertTrue(flow.hints.allSatisfy { $0.accessibilityIdentifier.hasPrefix("first-battle-tutorial-hint-") })
        XCTAssertTrue(flow.hints.allSatisfy { (28...55).contains($0.wordCount) })
        XCTAssertTrue(flow.hints.allSatisfy(\.containsRequiredTopics))
        XCTAssertTrue(flow.hasHint(for: .movementDrag))
        XCTAssertTrue(flow.hasHint(for: .blockedAction))
        XCTAssertTrue(flow.hasHint(for: .germanAITurn))
        XCTAssertTrue(flow.hasHint(for: .debrief))

        var coordinator = TutorialHintCoordinator()
        XCTAssertNil(coordinator.activeHint(in: flow))
        coordinator.record(.battleOpened, in: flow)
        XCTAssertEqual(coordinator.activeHint(in: flow)?.trigger, .battleOpened)
        coordinator.completeActiveHint(in: flow)

        for trigger in GuderianTutorialCatalog.requiredFirstBattleTriggers.dropFirst() {
            coordinator.record(trigger, in: flow)
        }
        XCTAssertEqual(coordinator.events.map(\.trigger), GuderianTutorialCatalog.requiredFirstBattleTriggers)
        XCTAssertEqual(coordinator.triggeredHintIDs.count, flow.hints.count)
        XCTAssertEqual(coordinator.activeHint(in: flow)?.trigger, .boardVisible)

        var completed = 1
        while coordinator.activeHint(in: flow) != nil {
            coordinator.completeActiveHint(in: flow)
            completed += 1
        }
        XCTAssertEqual(completed, flow.hints.count)
        XCTAssertTrue(coordinator.progress.isComplete(flow))
        XCTAssertEqual(coordinator.progress.completedHintCount(in: flow), flow.hints.count)

        coordinator.dismiss(flow)
        XCTAssertFalse(coordinator.progress.shouldPresent(flow))
        XCTAssertNil(coordinator.activeHint(in: flow))

        coordinator.reset(.firstBattleGuidance)
        XCTAssertTrue(coordinator.progress.shouldPresent(flow))
        XCTAssertTrue(coordinator.triggeredHintIDs.isEmpty)
        XCTAssertTrue(coordinator.events.isEmpty)

        let harness = try DZWPlayableScreenHarness.runTucholaFlow(seed: 930_001)
        XCTAssertTrue(harness.completedAllStages, harness.blockers.joined(separator: "\n"))
        XCTAssertEqual(harness.completion.completionRecord.scenarioID, .tucholaForest)
        XCTAssertNotNil(harness.persistedProgress.completionRecord(for: .tucholaForest))
    }

    private func readmeText() throws -> String {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("README.md")
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func planText() throws -> String {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("PLAN.md")
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func battleChronologyRows(in readme: String) -> [String] {
        var rows: [String] = []
        var isInChronology = false

        for line in readme.components(separatedBy: .newlines) {
            if line == "## Battle Chronology" {
                isInChronology = true
                continue
            }
            if isInChronology && line.hasPrefix("## ") {
                break
            }
            guard isInChronology, line.hasPrefix("| ") else {
                continue
            }

            let cells = line
                .split(separator: "|", omittingEmptySubsequences: false)
                .map { String($0).trimmingCharacters(in: .whitespaces) }
            if cells.count > 2, Int(cells[1]) != nil {
                rows.append(line)
            }
        }

        return rows
    }

    func testCampaignCatalogIsChronologicalWithinStableOrder() {
        let scenarios = GuderianCampaignCatalog.all

        for pair in zip(scenarios, scenarios.dropFirst()) {
            XCTAssertLessThan(pair.0.order, pair.1.order)
            XCTAssertLessThanOrEqual(pair.0.startDate, pair.1.startDate)
        }
    }

    func testEveryScenarioHasSourcesTerrainObjectivesAndOpposingForceRole() {
        for scenario in GuderianCampaignCatalog.all {
            XCTAssertFalse(scenario.sourceLinks.isEmpty, "\(scenario.title) needs at least one source")
            XCTAssertFalse(scenario.mapFeatures.isEmpty, "\(scenario.title) needs terrain features")
            XCTAssertFalse(scenario.objectives.isEmpty, "\(scenario.title) needs objectives")
            XCTAssertTrue(
                scenario.forces.contains { $0.side == "Player" },
                "\(scenario.title) needs a player force slot"
            )
            XCTAssertTrue(
                scenario.forces.contains { $0.side == "Guderian AI" },
                "\(scenario.title) needs a Guderian AI force slot"
            )
        }
    }

    func testDemoScenarioIDsMatchFirstThirtyCycleScope() throws {
        XCTAssertEqual(GuderianCampaignCatalog.demoIDs, [.wizna, .sedan, .moscowTulaKashira])

        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            XCTAssertTrue(scenario.isDemoScenario)
            XCTAssertEqual(scenario.status, .dzwProxyLoadable)
        }
    }

    func testScenarioLoaderCreatesDZWGameWithoutChangingSubmodule() throws {
        let loadout = DZWScenarioLoader.loadFirstDemoScenario(seed: 19390907)
        XCTAssertEqual(loadout.scenario.id, .wizna)
        XCTAssertEqual(loadout.playerArmyName, "British")
        XCTAssertEqual(loadout.opponentArmyName, "German")
        XCTAssertFalse(loadout.adapterNotes.isEmpty)

        let game = try XCTUnwrap(loadout.makeGame())
        defer { game_destroy(game) }

        XCTAssertEqual(game_player_army(game, DZW_PLAYER_ONE), loadout.playerArmy)
        XCTAssertEqual(game_player_army(game, DZW_PLAYER_TWO), loadout.opponentArmy)
        XCTAssertGreaterThan(Int(game_unit_count(game)), 0)
        XCTAssertGreaterThan(Int(game_objective_count(game)), 0)
    }

    func testEasternFrontScenarioLoaderUsesSovietOpposition() throws {
        let loadout = try XCTUnwrap(DZWScenarioLoader.load(.moscowTulaKashira, seed: 19411002))
        XCTAssertEqual(loadout.playerArmyName, "Soviet")
        XCTAssertEqual(loadout.opponentArmyName, "German")

        let game = try XCTUnwrap(loadout.makeGame())
        defer { game_destroy(game) }

        XCTAssertEqual(game_player_army(game, DZW_PLAYER_ONE), DZW_ARMY_SOVIET)
        XCTAssertEqual(game_player_army(game, DZW_PLAYER_TWO), DZW_ARMY_GERMAN)
    }

    func testEveryScenarioHasRenderableMapAndAIPlan() {
        for scenario in GuderianCampaignCatalog.all {
            let layout = ScenarioMapCatalog.layout(for: scenario)
            let aiPlan = GermanAIPlanCatalog.plan(for: scenario)

            XCTAssertEqual(layout.id, scenario.id)
            XCTAssertGreaterThan(layout.width, 0)
            XCTAssertGreaterThan(layout.height, 0)
            XCTAssertFalse(layout.elements.isEmpty, "\(scenario.title) needs map elements")
            XCTAssertEqual(layout.deploymentZones.count, 2, "\(scenario.title) needs both deployment zones")
            XCTAssertFalse(aiPlan.orders.isEmpty, "\(scenario.title) needs German AI orders")
            XCTAssertFalse(aiPlan.targetPriorities.isEmpty, "\(scenario.title) needs AI target priorities")
        }
    }

    func testWiznaTutorialLocksFortificationDelayFlow() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .wizna))
        let layout = ScenarioMapCatalog.layout(for: scenario)
        let setup = ScenarioSetupCatalog.setup(for: scenario)
        let aiPlan = GermanAIPlanCatalog.plan(for: scenario)

        XCTAssertTrue(layout.elements.contains { $0.kind == .bunker })
        XCTAssertTrue(layout.elements.contains { $0.kind == .fortifiedLine })
        XCTAssertGreaterThanOrEqual(setup.tutorialSteps.count, 4)
        XCTAssertTrue(setup.tutorialSteps.contains { $0.title.contains("bunkers") })
        XCTAssertTrue(setup.triggers.contains { $0.name.contains("Bombardment") })
        XCTAssertTrue(aiPlan.orders.contains { $0.kind == .artillery })
        XCTAssertTrue(setup.playerUnits.contains { $0.name.contains("anti-tank") })
    }

    func testSedanMapForcesAndTriggersCoverCrossingScenario() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .sedan))
        let layout = ScenarioMapCatalog.layout(for: scenario)
        let setup = ScenarioSetupCatalog.setup(for: scenario)
        let aiPlan = GermanAIPlanCatalog.plan(for: scenario)

        XCTAssertTrue(layout.elements.contains { $0.kind == .river && $0.name.contains("Meuse") })
        XCTAssertGreaterThanOrEqual(layout.elements.filter { $0.kind == .bridge }.count, 2)
        XCTAssertTrue(setup.playerUnits.contains { $0.name.contains("French artillery") })
        XCTAssertTrue(setup.guderianUnits.contains { $0.name.contains("engineers") })
        XCTAssertTrue(setup.guderianUnits.contains { $0.name.contains("panzer") })
        XCTAssertTrue(setup.triggers.contains { $0.name.contains("counterattack") })
        XCTAssertTrue(aiPlan.orders.contains { $0.kind == .reinforcement && $0.target.contains("Bridgehead") })
    }

    func testDemoBalanceProfilesExposeScoringPacingAndDebriefBands() throws {
        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let balance = ScenarioBalanceCatalog.profile(for: scenario)

            XCTAssertEqual(balance.id, id)
            XCTAssertGreaterThan(balance.maxPlayerScore, 0, "\(scenario.title) should expose player scoring")
            XCTAssertFalse(balance.scoreChannels.isEmpty, "\(scenario.title) needs score channels")
            XCTAssertFalse(balance.pacingRules.isEmpty, "\(scenario.title) needs pacing rules")
            XCTAssertFalse(balance.outcomeBands.isEmpty, "\(scenario.title) needs debrief bands")
            XCTAssertLessThanOrEqual(balance.targetTurns.lowerBound, balance.targetTurns.upperBound)
        }
    }

    func testSedanBalanceProtectsCounterattackAgency() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .sedan))
        let balance = ScenarioBalanceCatalog.profile(for: scenario)

        XCTAssertTrue(balance.scoreChannels.contains { $0.name.contains("Bridgehead delay") && $0.side == .player })
        XCTAssertTrue(balance.scoreChannels.contains { $0.name.contains("Counterattack damage") })
        XCTAssertTrue(balance.pacingRules.contains { $0.name.contains("Air-pressure cap") })
        XCTAssertTrue(balance.pacingRules.contains { $0.name.contains("Counterattack agency") })
        XCTAssertTrue(balance.reinforcements.contains { $0.unitName.contains("French reserve") && $0.side == .player })
        XCTAssertTrue(balance.reinforcements.contains { $0.unitName.contains("panzer") && $0.side == .guderianAI })
    }

    func testMoscowTulaScenarioHasWinterForcesExhaustionAndCounterattack() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .moscowTulaKashira))
        let layout = ScenarioMapCatalog.layout(for: scenario)
        let setup = ScenarioSetupCatalog.setup(for: scenario)
        let balance = ScenarioBalanceCatalog.profile(for: scenario)
        let aiPlan = GermanAIPlanCatalog.plan(for: scenario)

        XCTAssertTrue(layout.elements.contains { $0.name.contains("Winter road choke") })
        XCTAssertTrue(layout.elements.contains { $0.name.contains("Tula defensive belt") })
        XCTAssertTrue(setup.playerUnits.contains { $0.name.contains("reserve armor") })
        XCTAssertTrue(setup.playerUnits.contains { $0.name.contains("anti-tank") })
        XCTAssertTrue(setup.guderianUnits.contains { $0.name.contains("supply") })
        XCTAssertTrue(setup.triggers.contains { $0.name.contains("exhaustion") })
        XCTAssertTrue(balance.scoreChannels.contains { $0.name.contains("German exhaustion") })
        XCTAssertTrue(balance.reinforcements.contains { $0.unitName.contains("Soviet reserve armor") })
        XCTAssertTrue(aiPlan.orders.contains { $0.id == "moscow-exhaustion" })
    }

    func testEventLogsCanBeFilteredByEveryCategoryForDemoScenarios() throws {
        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let entries = ScenarioEventLogCatalog.entries(for: scenario)
            let categories = Set(entries.map(\.category))

            XCTAssertFalse(entries.isEmpty)
            XCTAssertTrue(categories.contains(.briefing))
            XCTAssertTrue(categories.contains(.objectives))
            XCTAssertTrue(categories.contains(.forces))
            XCTAssertTrue(categories.contains(.aiPlan))
            XCTAssertTrue(categories.contains(.balance))
            XCTAssertTrue(categories.contains(.reinforcements), "\(scenario.title) should expose reinforcement timing")
        }
    }

    func testAllDemoScenariosCreateProxyGamesWithObjectives() throws {
        for id in GuderianCampaignCatalog.demoIDs {
            let loadout = try XCTUnwrap(DZWScenarioLoader.load(id, seed: UInt32(9_000 + id.rawValue.count)))
            let game = try XCTUnwrap(loadout.makeGame(), "\(loadout.scenario.title) should load through dzw proxy")
            defer { game_destroy(game) }

            XCTAssertEqual(game_player_army(game, DZW_PLAYER_ONE), loadout.playerArmy)
            XCTAssertEqual(game_player_army(game, DZW_PLAYER_TWO), loadout.opponentArmy)
            XCTAssertGreaterThan(Int(game_unit_count(game)), 0)
            XCTAssertGreaterThan(Int(game_objective_count(game)), 0)
        }
    }

    func testCampaignProgressMakesDemoScenariosAvailable() throws {
        var progress = CampaignProgress()

        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            XCTAssertTrue(progress.isAvailable(scenario), "\(scenario.title) should be playable in the demo shell")
        }

        let first = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        XCTAssertTrue(progress.isAvailable(first))
        progress.markCompleted(.tucholaForest)

        let second = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .wizna))
        XCTAssertTrue(progress.isCompleted(.tucholaForest))
        XCTAssertTrue(progress.isAvailable(second))

        progress.reset()
        XCTAssertEqual(progress.completedCount, 0)
    }

    func testCampaignProgressSupportsChronologicalAndStandaloneModes() throws {
        var progress = CampaignProgress()
        let tuchola = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let brzesc = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .brzescLitewski))

        XCTAssertTrue(progress.isAvailable(tuchola, in: .chronological))
        XCTAssertFalse(progress.isAvailable(brzesc, in: .chronological))
        XCTAssertEqual(progress.availableScenarios(in: .standalone).count, GuderianCampaignCatalog.all.count)

        let record = CampaignCompletionRecord(
            scenarioID: .tucholaForest,
            score: 10,
            victoryBand: .operational,
            completedTurn: 7,
            note: "Bridges blocked and withdrawal opened."
        )
        progress.recordCompletion(record)
        progress.markCompleted(.wizna)

        XCTAssertEqual(progress.completionRecord(for: .tucholaForest), record)
        XCTAssertTrue(progress.isAvailable(brzesc, in: .chronological))

        let snapshot = progress.snapshot(mode: .chronological)
        XCTAssertEqual(snapshot.nextScenarioID, .brzescLitewski)
        XCTAssertTrue(snapshot.availableScenarioIDs.contains(.brzescLitewski))
        XCTAssertEqual(snapshot.completedRecords, [record])
    }

    func testScenarioContentBundlesCollectHandAuthoredData() throws {
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.tucholaForest))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.brzescLitewski))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.amiensAbbeville))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.fallRot))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.bialystokMinsk))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.smolensk))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.bryansk))
        XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(.mtsensk))

        for id in ScenarioContentCatalog.handAuthoredScenarioIDs {
            let bundle = try XCTUnwrap(ScenarioContentCatalog.bundle(for: id))

            XCTAssertEqual(bundle.id, id)
            XCTAssertEqual(bundle.scenario.id, id)
            XCTAssertEqual(bundle.mapLayout.id, id)
            XCTAssertEqual(bundle.setup.id, id)
            XCTAssertEqual(bundle.aiPlan.id, id)
            XCTAssertEqual(bundle.balance.id, id)
            XCTAssertFalse(bundle.logEntries.isEmpty)
        }
    }

    func testPolishCampaignSystemsExposeReusableEarlyWarAssets() throws {
        XCTAssertEqual(
            PolishCampaignSystemCatalog.polishScenarioIDs,
            [.tucholaForest, .wizna, .brzescLitewski, .kobryn]
        )

        for id in PolishCampaignSystemCatalog.polishScenarioIDs {
            let profile = try XCTUnwrap(PolishCampaignSystemCatalog.profile(for: id))

            XCTAssertEqual(profile.id, id)
            XCTAssertFalse(profile.assets.isEmpty)
            XCTAssertFalse(profile.specialRules.isEmpty)
            XCTAssertFalse(profile.operationalProblem.isEmpty)
            XCTAssertFalse(profile.playerDoctrine.isEmpty)
        }

        let tuchola = try XCTUnwrap(PolishCampaignSystemCatalog.profile(for: .tucholaForest))
        XCTAssertTrue(tuchola.assets.contains { $0.kind == .cavalryBrigade && $0.name.contains("Pomeranian") })
        XCTAssertTrue(tuchola.assets.contains { $0.kind == .demolitionTeam && $0.name.contains("Brda") })
        XCTAssertTrue(tuchola.assets.contains { $0.kind == .withdrawalRoute && $0.name.contains("Bydgoszcz") })
        XCTAssertTrue(tuchola.assets.contains { $0.kind == .commandFriction })
        XCTAssertTrue(tuchola.specialRules.contains { $0.name.contains("Krojanty") })
    }

    func testPolandExpansionScenariosAreHandAuthoredAndProxyLoadable() throws {
        let brzesc = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .brzescLitewski))
        let kobryn = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .kobryn))
        let brzescBundle = ScenarioContentCatalog.bundle(for: brzesc)
        let kobrynBundle = ScenarioContentCatalog.bundle(for: kobryn)

        XCTAssertEqual(brzesc.status, .dzwProxyLoadable)
        XCTAssertEqual(kobryn.status, .dzwProxyLoadable)
        XCTAssertNotNil(PolishCampaignSystemCatalog.profile(for: brzesc))
        XCTAssertNotNil(PolishCampaignSystemCatalog.profile(for: kobryn))

        XCTAssertTrue(brzescBundle.mapLayout.elements.contains { $0.name.contains("Citadel") })
        XCTAssertTrue(brzescBundle.mapLayout.elements.contains { $0.name.contains("Armored train") })
        XCTAssertTrue(brzescBundle.setup.playerUnits.contains { $0.name.contains("Armored trains") })
        XCTAssertTrue(brzescBundle.setup.playerUnits.contains { $0.name.contains("FT-17") })
        XCTAssertTrue(brzescBundle.balance.scoreChannels.contains { $0.name.contains("Citadel") })
        XCTAssertTrue(brzescBundle.aiPlan.orders.contains { $0.id == "brzesc-citadel-ring" })

        XCTAssertTrue(kobrynBundle.mapLayout.elements.contains { $0.name.contains("Eastern exit") })
        XCTAssertTrue(kobrynBundle.setup.playerUnits.contains { $0.name.contains("60th Reserve") })
        XCTAssertTrue(kobrynBundle.setup.guderianUnits.contains { $0.name.contains("2nd Motorized") })
        XCTAssertTrue(kobrynBundle.balance.scoreChannels.contains { $0.name.contains("Cohesion") })
        XCTAssertTrue(kobrynBundle.aiPlan.orders.contains { $0.id == "kobryn-exit-threat" })
    }

    func testFranceCampaignSystemsExposeArmorAirAndChannelRules() throws {
        XCTAssertEqual(
            FranceCampaignSystemCatalog.franceScenarioIDs,
            [.sedan, .stonne, .montcornet, .amiensAbbeville, .boulogne, .calais, .dunkirk, .fallRot]
        )

        for id in FranceCampaignSystemCatalog.franceScenarioIDs {
            let profile = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: id))

            XCTAssertEqual(profile.id, id)
            XCTAssertFalse(profile.assets.isEmpty)
            XCTAssertFalse(profile.specialRules.isEmpty)
            XCTAssertFalse(profile.operationalProblem.isEmpty)
            XCTAssertFalse(profile.playerDoctrine.isEmpty)
        }

        let stonne = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .stonne))
        let montcornet = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .montcornet))
        let amiens = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .amiensAbbeville))
        let boulogne = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .boulogne))
        let calais = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .calais))
        let dunkirk = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .dunkirk))
        let fallRot = try XCTUnwrap(FranceCampaignSystemCatalog.profile(for: .fallRot))

        XCTAssertTrue(stonne.assets.contains { $0.kind == .heavyTank && $0.name.contains("Char B1") })
        XCTAssertTrue(montcornet.assets.contains { $0.kind == .airPressure && $0.name.contains("Luftwaffe") })
        XCTAssertTrue(amiens.assets.contains { $0.kind == .riverCrossing && $0.name.contains("Somme") })
        XCTAssertTrue(amiens.specialRules.contains { $0.name.contains("Channel cut") })
        XCTAssertTrue(boulogne.assets.contains { $0.kind == .navalSupport && $0.name.contains("destroyer") })
        XCTAssertTrue(calais.assets.contains { $0.name.contains("Dunkirk time") })
        XCTAssertTrue(dunkirk.specialRules.contains { $0.name.contains("Command-scope caveat") })
        XCTAssertTrue(fallRot.assets.contains { $0.kind == .withdrawalRoute && $0.name.contains("Retreat") })
    }

    func testFranceExpansionScenariosAreHandAuthoredAndProxyLoadable() throws {
        for id in [GuderianBattleID.stonne, .montcornet, .amiensAbbeville, .boulogne, .calais, .dunkirk, .fallRot] {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let bundle = ScenarioContentCatalog.bundle(for: scenario)
            let loadout = try XCTUnwrap(DZWScenarioLoader.load(id, seed: UInt32(19400500 + scenario.order)))

            XCTAssertEqual(scenario.status, .dzwProxyLoadable)
            XCTAssertEqual(loadout.playerArmyName, "British")
            XCTAssertTrue(loadout.adapterNotes.contains { $0.contains("France 1940 campaign systems") })
            XCTAssertGreaterThanOrEqual(bundle.balance.maxPlayerScore, 8)
            XCTAssertFalse(bundle.setup.playerUnits.isEmpty)
            XCTAssertFalse(bundle.setup.guderianUnits.isEmpty)
            XCTAssertFalse(bundle.aiPlan.orders.isEmpty)
        }

        let stonne = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .stonne))
        XCTAssertTrue(stonne.mapLayout.elements.contains { $0.name.contains("Stonne") })
        XCTAssertTrue(stonne.setup.playerUnits.contains { $0.name.contains("Char B1") })
        XCTAssertTrue(stonne.balance.scoreChannels.contains { $0.name.contains("Heavy-tank") })

        let montcornet = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .montcornet))
        XCTAssertTrue(montcornet.mapLayout.elements.contains { $0.name.contains("German column") })
        XCTAssertTrue(montcornet.balance.reinforcements.contains { $0.unitName.contains("Luftwaffe") })

        let amiens = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .amiensAbbeville))
        XCTAssertTrue(amiens.mapLayout.elements.contains { $0.name.contains("Abbeville") })
        XCTAssertTrue(amiens.balance.scoreChannels.contains { $0.name.contains("Evacuation") })

        let boulogne = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .boulogne))
        XCTAssertTrue(boulogne.mapLayout.elements.contains { $0.name.contains("Harbor") })
        XCTAssertTrue(boulogne.setup.playerUnits.contains { $0.name.contains("destroyer") })
        XCTAssertTrue(boulogne.balance.scoreChannels.contains { $0.name.contains("Port denial") })

        let calais = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .calais))
        XCTAssertTrue(calais.setup.playerUnits.contains { $0.name.contains("supply") })
        XCTAssertTrue(calais.balance.scoreChannels.contains { $0.name.contains("Dunkirk time") })

        let dunkirk = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .dunkirk))
        XCTAssertTrue(dunkirk.setup.triggers.contains { $0.name.contains("Command-scope caveat") })
        XCTAssertTrue(dunkirk.balance.scoreChannels.contains { $0.name.contains("Evacuated") })

        let fallRot = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .fallRot))
        XCTAssertTrue(fallRot.mapLayout.elements.contains { $0.name.contains("Belfort") })
        XCTAssertTrue(fallRot.balance.reinforcements.contains { $0.unitName.contains("Army Group C") })
    }

    func testEasternFrontSystemsExposePocketBreakoutAndLogisticsRules() throws {
        XCTAssertEqual(
            EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs,
            [.bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .mtsensk, .moscowTulaKashira]
        )

        for id in EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs {
            let profile = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: id))

            XCTAssertEqual(profile.id, id)
            XCTAssertFalse(profile.assets.isEmpty)
            XCTAssertFalse(profile.specialRules.isEmpty)
            XCTAssertFalse(profile.operationalProblem.isEmpty)
            XCTAssertFalse(profile.playerDoctrine.isEmpty)
        }

        let bialystok = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .bialystokMinsk))
        XCTAssertTrue(bialystok.assets.contains { $0.kind == .pocket && $0.name.contains("pockets") })
        XCTAssertTrue(bialystok.assets.contains { $0.kind == .mechanizedCorps })
        XCTAssertTrue(bialystok.specialRules.contains { $0.name.contains("Double envelopment") })
        XCTAssertTrue(bialystok.specialRules.contains { $0.name.contains("Command preservation") })

        let smolensk = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .smolensk))
        XCTAssertTrue(smolensk.assets.contains { $0.kind == .riverCrossing && $0.name.contains("Dnieper") })
        XCTAssertTrue(smolensk.specialRules.contains { $0.name.contains("Logistics crisis") })

        let roslavl = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .roslavlNovozybkov))
        XCTAssertTrue(roslavl.assets.contains { $0.name.contains("southward-turn") || $0.name.contains("southward") })
        XCTAssertTrue(roslavl.specialRules.contains { $0.name.contains("Intelligence") })

        let kiev = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .kiev))
        XCTAssertTrue(kiev.assets.contains { $0.kind == .commandPost })
        XCTAssertTrue(kiev.specialRules.contains { $0.name.contains("Pincer link-up") })

        let bryansk = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .bryansk))
        XCTAssertTrue(bryansk.assets.contains { $0.name.contains("Tula") })
        XCTAssertTrue(bryansk.specialRules.contains { $0.name.contains("Unexpected axis") })

        let mtsensk = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .mtsensk))
        XCTAssertTrue(mtsensk.assets.contains { $0.kind == .armorAmbush && $0.name.contains("Katukov") })
        XCTAssertTrue(mtsensk.specialRules.contains { $0.name.contains("T-34") })

        let moscow = try XCTUnwrap(EasternFrontCampaignSystemCatalog.profile(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.assets.contains { $0.name.contains("Venev") })
        XCTAssertTrue(moscow.specialRules.contains { $0.name.contains("Kashira") })
    }

    func testBialystokMinskIsHandAuthoredAndProxyLoadable() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .bialystokMinsk))
        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        let loadout = try XCTUnwrap(DZWScenarioLoader.load(.bialystokMinsk, seed: 19410622))

        XCTAssertEqual(scenario.status, .dzwProxyLoadable)
        XCTAssertEqual(loadout.playerArmyName, "Soviet")
        XCTAssertEqual(loadout.opponentArmyName, "German")
        XCTAssertTrue(loadout.adapterNotes.contains { $0.contains("Eastern Front campaign systems") })

        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("Minsk") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("2nd Panzer") })
        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("10th Army") })
        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("mechanized") })
        XCTAssertTrue(bundle.setup.guderianUnits.contains { $0.name.contains("2nd Panzer Group") })
        XCTAssertTrue(bundle.aiPlan.orders.contains { $0.id == "bialystok-pocket-close" })
        XCTAssertTrue(bundle.balance.scoreChannels.contains { $0.name.contains("Breakout") })
        XCTAssertTrue(bundle.balance.reinforcements.contains { $0.unitName.contains("Mechanized") && $0.side == .player })
    }

    func testCycle210EasternFrontScenariosAreHandAuthoredAndProxyLoadable() throws {
        for id in [GuderianBattleID.smolensk, .roslavlNovozybkov, .kiev, .bryansk] {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let bundle = ScenarioContentCatalog.bundle(for: scenario)
            let loadout = try XCTUnwrap(DZWScenarioLoader.load(id, seed: UInt32(19410000 + scenario.order)))

            XCTAssertEqual(scenario.status, .dzwProxyLoadable)
            XCTAssertEqual(loadout.playerArmyName, "Soviet")
            XCTAssertEqual(loadout.opponentArmyName, "German")
            XCTAssertTrue(loadout.adapterNotes.contains { $0.contains("Eastern Front campaign systems") })
            XCTAssertTrue(ScenarioContentCatalog.handAuthoredScenarioIDs.contains(id))
            XCTAssertNotNil(EasternFrontCampaignSystemCatalog.profile(for: id))
            XCTAssertGreaterThanOrEqual(bundle.balance.maxPlayerScore, 9)
            XCTAssertFalse(bundle.setup.playerUnits.isEmpty)
            XCTAssertFalse(bundle.setup.guderianUnits.isEmpty)
            XCTAssertFalse(bundle.aiPlan.orders.isEmpty)
            XCTAssertFalse(bundle.logEntries.isEmpty)
        }

        let smolensk = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .smolensk))
        XCTAssertTrue(smolensk.mapLayout.elements.contains { $0.name.contains("Yartsevo") })
        XCTAssertTrue(smolensk.setup.playerUnits.contains { $0.name.contains("reserve") })
        XCTAssertTrue(smolensk.aiPlan.orders.contains { $0.id == "smolensk-pocket-close" })
        XCTAssertTrue(smolensk.balance.scoreChannels.contains { $0.name.contains("supply strain") })

        let roslavl = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .roslavlNovozybkov))
        XCTAssertTrue(roslavl.mapLayout.elements.contains { $0.name.contains("Southward") || $0.name.contains("southward") })
        XCTAssertTrue(roslavl.setup.playerUnits.contains { $0.name.contains("reconnaissance") })
        XCTAssertTrue(roslavl.aiPlan.orders.contains { $0.id == "roslavl-counterpressure" })
        XCTAssertTrue(roslavl.balance.scoreChannels.contains { $0.name.contains("Column") })

        let kiev = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .kiev))
        XCTAssertTrue(kiev.mapLayout.elements.contains { $0.name.contains("command") || $0.name.contains("Command") })
        XCTAssertTrue(kiev.setup.playerUnits.contains { $0.name.contains("command") || $0.name.contains("Command") })
        XCTAssertTrue(kiev.aiPlan.orders.contains { $0.id == "kiev-linkup" })
        XCTAssertTrue(kiev.balance.scoreChannels.contains { $0.name.contains("Command evacuation") })

        let bryansk = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .bryansk))
        XCTAssertTrue(bryansk.mapLayout.elements.contains { $0.name.contains("Orel") })
        XCTAssertTrue(bryansk.setup.playerUnits.contains { $0.name.contains("50th Army") })
        XCTAssertTrue(bryansk.aiPlan.orders.contains { $0.id == "bryansk-pocket-close" })
        XCTAssertTrue(bryansk.balance.scoreChannels.contains { $0.name.contains("Tula road") })
    }

    func testCycle240MtsenskAndMoscowExpansionArePlayableDataSlices() throws {
        let mtsenskScenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .mtsensk))
        let mtsensk = ScenarioContentCatalog.bundle(for: mtsenskScenario)
        let mtsenskLoadout = try XCTUnwrap(DZWScenarioLoader.load(.mtsensk, seed: 19411004))

        XCTAssertEqual(mtsenskScenario.status, .dzwProxyLoadable)
        XCTAssertEqual(mtsenskLoadout.playerArmyName, "Soviet")
        XCTAssertTrue(mtsensk.mapLayout.elements.contains { $0.name.contains("Katukov") })
        XCTAssertTrue(mtsensk.mapLayout.elements.contains { $0.name.contains("Tula road") })
        XCTAssertTrue(mtsensk.setup.playerUnits.contains { $0.name.contains("4th Tank Brigade") })
        XCTAssertTrue(mtsensk.setup.guderianUnits.contains { $0.name.contains("4th Panzer") })
        XCTAssertTrue(mtsensk.setup.triggers.contains { $0.name.contains("T-34") })
        XCTAssertTrue(mtsensk.aiPlan.orders.contains { $0.id == "mtsensk-ambush-contact" })
        XCTAssertTrue(mtsensk.balance.scoreChannels.contains { $0.name.contains("German tank losses") })
        XCTAssertTrue(mtsensk.historicalOverlay.caveats.contains { $0.contains("Tank-loss claims") })

        let moscow = try XCTUnwrap(ScenarioContentCatalog.bundle(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.mapLayout.elements.contains { $0.name.contains("Venev") })
        XCTAssertTrue(moscow.mapLayout.elements.contains { $0.name.contains("Belov") })
        XCTAssertTrue(moscow.setup.playerUnits.contains { $0.name.contains("Belov") })
        XCTAssertTrue(moscow.setup.guderianUnits.contains { $0.name.contains("Venev") })
        XCTAssertTrue(moscow.aiPlan.orders.contains { $0.id == "moscow-venev-bypass" })
        XCTAssertTrue(moscow.balance.scoreChannels.contains { $0.name.contains("Mordves") })
        XCTAssertTrue(moscow.historicalOverlay.caveats.contains { $0.contains("southern pincer") })
    }

    func testHistoricalOverlaysCoverEveryScenario() throws {
        XCTAssertEqual(ScenarioHistoricalOverlayCatalog.allOverlays.count, GuderianCampaignCatalog.all.count)

        for scenario in GuderianCampaignCatalog.all {
            let overlay = ScenarioHistoricalOverlayCatalog.overlay(for: scenario)

            XCTAssertEqual(overlay.id, scenario.id)
            XCTAssertFalse(overlay.commanderContext.isEmpty)
            XCTAssertFalse(overlay.mapNote.isEmpty)
            XCTAssertFalse(overlay.outcomeSummary.isEmpty)
            XCTAssertFalse(overlay.caveats.isEmpty)
            XCTAssertEqual(overlay.sourceNotes.count, scenario.sourceLinks.count)
        }

        let dunkirk = try XCTUnwrap(ScenarioHistoricalOverlayCatalog.overlay(for: .dunkirk))
        XCTAssertTrue(dunkirk.caveats.contains { $0.contains("indirect") })
    }

    func testAIRefinementSnapshotsCoverEveryScenario() throws {
        XCTAssertEqual(GermanAIRefinementCatalog.allSnapshots.count, GuderianCampaignCatalog.all.count)

        for scenario in GuderianCampaignCatalog.all {
            let snapshot = GermanAIRefinementCatalog.snapshot(for: scenario)
            let plan = GermanAIPlanCatalog.plan(for: scenario)

            XCTAssertEqual(snapshot.id, scenario.id)
            XCTAssertEqual(Optional(snapshot.primaryOrderID), plan.orders.first?.id)
            XCTAssertEqual(snapshot.difficultyTiers, GermanAIDifficultyTier.allCases)
            XCTAssertGreaterThanOrEqual(snapshot.fallbackBehaviors.count, 3)
            XCTAssertGreaterThan(snapshot.deterministicSeedHint, 0)
        }

        let mtsensk = try XCTUnwrap(GermanAIRefinementCatalog.snapshot(for: .mtsensk))
        XCTAssertTrue(mtsensk.fallbackBehaviors.contains { $0.response.contains("mobile reserve") || $0.response.contains("security group") })
    }

    func testBalanceAuditAndFullCampaignSmokeCoverage() throws {
        XCTAssertEqual(ScenarioBalanceAuditCatalog.allAudits.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(ScenarioContentCatalog.handAuthoredScenarioIDs, Set(GuderianBattleID.allCases))

        for scenario in GuderianCampaignCatalog.all {
            let audit = ScenarioBalanceAuditCatalog.audit(for: scenario)
            let bundle = ScenarioContentCatalog.bundle(for: scenario)
            let loadout = try XCTUnwrap(DZWScenarioLoader.load(scenario.id, seed: UInt32(24_000 + scenario.order)))
            let game = try XCTUnwrap(loadout.makeGame(), "\(scenario.title) should create a proxy dzw game")
            defer { game_destroy(game) }

            XCTAssertEqual(scenario.status, .dzwProxyLoadable)
            XCTAssertEqual(audit.id, scenario.id)
            XCTAssertGreaterThanOrEqual(audit.victoryGradeCount, 3)
            XCTAssertGreaterThan(audit.maximumPlayerScore, 0)
            XCTAssertFalse(bundle.mapLayout.elements.isEmpty)
            XCTAssertFalse(bundle.setup.units.isEmpty)
            XCTAssertFalse(bundle.aiPlan.orders.isEmpty)
            XCTAssertFalse(bundle.balance.outcomeBands.isEmpty)
            XCTAssertFalse(bundle.logEntries.isEmpty)
            XCTAssertGreaterThan(Int(game_unit_count(game)), 0)
            XCTAssertGreaterThan(Int(game_objective_count(game)), 0)
        }
    }

    func testCycle250CampaignSaveStateRoundTripsProgressAndSelection() throws {
        var progress = CampaignProgress()
        let record = CampaignCompletionRecord(
            scenarioID: .tucholaForest,
            score: 12,
            victoryBand: .decisive,
            completedTurn: 6,
            note: "Release save/load regression."
        )
        progress.recordCompletion(record)

        let state = CampaignSaveState(
            selectedScenarioID: .sedan,
            playMode: .standalone,
            progress: progress,
            savedAt: Date(timeIntervalSince1970: 1_941)
        )
        let data = try CampaignSaveCodec.encode(state)
        let decoded = try CampaignSaveCodec.decode(data)

        XCTAssertEqual(decoded, state)
        XCTAssertEqual(CampaignSaveCodec.decodeIfCurrent(data), state)
        XCTAssertEqual(decoded.progress.completionRecord(for: .tucholaForest), record)
        XCTAssertEqual(decoded.selectedScenarioID, .sedan)
        XCTAssertEqual(decoded.playMode, .standalone)

        let stale = CampaignSaveState(
            selectedScenarioID: .wizna,
            playMode: .chronological,
            progress: progress,
            savedAt: Date(timeIntervalSince1970: 1_942),
            schemaVersion: 0
        )
        XCTAssertNil(CampaignSaveCodec.decodeIfCurrent(try CampaignSaveCodec.encode(stale)))
    }

    func testCycle250CampaignCompletionSummaryUnlocksFinalScreen() throws {
        var progress = CampaignProgress()
        var expectedScore = 0

        XCTAssertFalse(progress.completionSummary().isComplete)
        XCTAssertEqual(progress.completionSummary().nextScenarioID, .tucholaForest)

        for scenario in GuderianCampaignCatalog.all {
            let balance = ScenarioBalanceCatalog.profile(for: scenario)
            expectedScore += balance.maxPlayerScore
            progress.recordCompletion(
                CampaignCompletionRecord(
                    scenarioID: scenario.id,
                    score: balance.maxPlayerScore,
                    victoryBand: .operational,
                    completedTurn: balance.targetTurns.upperBound,
                    note: "Cycle 250 full-campaign completion regression."
                )
            )
        }

        let summary = progress.completionSummary()
        XCTAssertTrue(summary.isComplete)
        XCTAssertTrue(progress.isComplete())
        XCTAssertEqual(summary.completedScenarios, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(summary.remainingScenarioIDs, [])
        XCTAssertNil(summary.nextScenarioID)
        XCTAssertEqual(summary.totalScore, expectedScore)
        XCTAssertEqual(summary.victoryBands[.operational], GuderianCampaignCatalog.all.count)
        XCTAssertEqual(summary.completionTitle, "Full Campaign Complete")
    }

    func testCycle250FullCampaignShipReportIsReadyCreditedAndBudgeted() throws {
        let report = FullCampaignShipReportCatalog.report()

        XCTAssertTrue(report.isShipReady, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.cycleRange, 241...250)
        XCTAssertEqual(report.scenarioCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.proxyLoadableCount, report.scenarioCount)
        XCTAssertEqual(report.handAuthoredCount, report.scenarioCount)
        XCTAssertEqual(report.historicalOverlayCount, report.scenarioCount)
        XCTAssertEqual(report.aiSnapshotCount, report.scenarioCount)
        XCTAssertEqual(report.balanceAuditCount, report.scenarioCount)
        XCTAssertTrue(report.blockers.isEmpty)
        XCTAssertTrue(report.releaseChecklist.allSatisfy { $0.status == .passed })
        XCTAssertTrue(report.releaseChecklist.contains { $0.id == "save-load" })
        XCTAssertTrue(report.releaseChecklist.contains { $0.id == "completion" })
        XCTAssertTrue(report.credits.contains { $0.id == "engine" && $0.sourcePathOrURL == "dzw/" })
        XCTAssertTrue(report.credits.contains { $0.id == "icon" && $0.sourcePathOrURL.contains("AppIconSource") })
        XCTAssertGreaterThanOrEqual(report.accessibilityItems.count, 4)
        XCTAssertGreaterThanOrEqual(report.performanceBudgets.count, 4)
        XCTAssertTrue(report.performanceBudgets.allSatisfy(\.isPassing))
        XCTAssertTrue(report.buildCommands.contains("swift test"))
        XCTAssertTrue(report.buildCommands.contains { $0.contains("xcodebuild") })
    }

    func testCycle260NativePlayabilityArchitectureDefinesGuardedDZWBoundary() throws {
        let architecture = NativePlayabilityArchitectureCatalog.architecture

        XCTAssertEqual(architecture.cycleRange, 251...260)
        XCTAssertEqual(architecture.guardMacro, "HEINZ_GUDERIAN_GAME")
        XCTAssertEqual(architecture.guardMacro, NativePlayabilityArchitectureCatalog.guardMacro)
        XCTAssertEqual(architecture.demoPlayableTargetCycle, 300)
        XCTAssertEqual(architecture.fullCampaignPlayableTargetCycle, 400)
        XCTAssertFalse(architecture.dzwEditsRequiredDuringArchitectureCycle)

        let reusedIDs = Set(architecture.reusedEngineSystems.map(\.id))
        XCTAssertTrue(reusedIDs.isSuperset(of: ["turn-phases", "movement-rules", "combat-rules", "objective-scoring", "snapshots"]))
        XCTAssertTrue(architecture.reusedEngineSystems.allSatisfy { $0.owner == .dzwEngine })

        let guderianOwnedIDs = Set(architecture.guderianOwnedSystems.map(\.id))
        XCTAssertTrue(guderianOwnedIDs.isSuperset(of: ["scenario-instance-data", "historical-campaign-flow", "battle-board-ui", "campaign-automation"]))
        XCTAssertTrue(architecture.guderianOwnedSystems.contains { $0.owner == .guderianCore })
        XCTAssertTrue(architecture.guderianOwnedSystems.contains { $0.owner == .guderianApp })
        XCTAssertTrue(architecture.guderianOwnedSystems.contains { $0.owner == .guderianTest })

        let hooks = Dictionary(uniqueKeysWithValues: architecture.requiredEngineHooks.map { ($0.id, $0) })
        XCTAssertEqual(Set(hooks.keys), ["scenario-instance-loader", "scenario-mission-state", "scenario-event-triggers", "scenario-ai-controls"])
        XCTAssertEqual(hooks["scenario-instance-loader"]?.firstNeededCycles, 271...280)
        XCTAssertEqual(hooks["scenario-mission-state"]?.firstNeededCycles, 271...300)
        XCTAssertTrue(architecture.requiredEngineHooks.allSatisfy { $0.guardMacro == "HEINZ_GUDERIAN_GAME" })
        XCTAssertTrue(architecture.requiredEngineHooks.allSatisfy { $0.owner == .dzwEngine })
    }

    func testCycle400AllBattlesAreNativePlayableWithShipReadinessNotes() throws {
        let reports = NativePlayabilityArchitectureCatalog.allReadinessReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)
        let nativePlayableIDs = Set(GuderianCampaignCatalog.demoIDs + PolishCampaignSystemCatalog.polishScenarioIDs + FranceCampaignSystemCatalog.franceScenarioIDs + EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs)
        let polishIDs = Set(PolishCampaignSystemCatalog.polishScenarioIDs)
        let franceIDs = Set(FranceCampaignSystemCatalog.franceScenarioIDs)
        let easternFrontIDs = Set(EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(nativePlayableIDs.count, GuderianCampaignCatalog.all.count)

        for report in reports {
            XCTAssertTrue(report.hasMinimumAuthoredInputs, "\(report.title): \(report.summary)")
            XCTAssertFalse(report.requiredHookIDs.contains("scenario-instance-loader"))
            XCTAssertTrue(report.notes.contains { $0.contains("scenario-specific terrain/objectives/mission target") })
            XCTAssertTrue(report.notes.contains { $0.contains("Cycle 375 native AI/event pass") })
            XCTAssertTrue(report.notes.contains { $0.contains("Cycle 380 native AI/event execution") })
            XCTAssertTrue(report.notes.contains { $0.contains("Cycle 390 balance/UX audit") })

            if nativePlayableIDs.contains(report.id) {
                XCTAssertEqual(report.status, .nativePlayable)
                XCTAssertFalse(report.requiredHookIDs.contains("scenario-mission-state"))
                XCTAssertFalse(report.requiredHookIDs.contains("scenario-event-triggers"))
                XCTAssertFalse(report.requiredHookIDs.contains("scenario-ai-controls"))
                XCTAssertTrue(report.requiredHookIDs.isEmpty, report.title)
                if easternFrontIDs.contains(report.id) {
                    XCTAssertTrue(report.notes.contains { $0.contains("Cycle 370 native Eastern Front pack") })
                } else if franceIDs.contains(report.id) {
                    XCTAssertTrue(report.notes.contains { $0.contains("Cycle 345 native France pack") })
                } else if polishIDs.contains(report.id) {
                    XCTAssertTrue(report.notes.contains { $0.contains("Cycle 325 native Poland pack") })
                } else {
                    XCTAssertTrue(report.notes.contains { $0.contains("Cycle 300 demo parity") })
                }
            }
        }

        let demoReports = reports.filter { GuderianCampaignCatalog.demoIDs.contains($0.id) }
        XCTAssertEqual(demoReports.count, GuderianCampaignCatalog.demoIDs.count)
        XCTAssertTrue(demoReports.allSatisfy { $0.notes.contains { $0.contains("cycles 291-300") } })

        let polishReports = reports.filter { polishIDs.contains($0.id) }
        XCTAssertEqual(polishReports.count, PolishCampaignSystemCatalog.polishScenarioIDs.count)
        XCTAssertTrue(polishReports.allSatisfy { $0.notes.contains { $0.contains("Cycle 325 native Poland pack") } })

        let franceReports = reports.filter { franceIDs.contains($0.id) }
        XCTAssertEqual(franceReports.count, FranceCampaignSystemCatalog.franceScenarioIDs.count)
        XCTAssertTrue(franceReports.allSatisfy { $0.notes.contains { $0.contains("Cycle 345 native France pack") } })

        let easternFrontReports = reports.filter { easternFrontIDs.contains($0.id) }
        XCTAssertEqual(easternFrontReports.count, EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs.count)
        XCTAssertTrue(easternFrontReports.allSatisfy { $0.notes.contains { $0.contains("Cycle 370 native Eastern Front pack") } })
    }

    func testCycle270NativeBattleInstancesConvertEveryScenarioIntoEngineBlueprints() throws {
        XCTAssertEqual(NativeBattleInstanceCatalog.modelCycleRange, 261...270)

        let instances = NativeBattleInstanceCatalog.allInstances
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(instances.map(\.id), orderedIDs)
        XCTAssertEqual(instances.count, GuderianCampaignCatalog.all.count)

        for instance in instances {
            let bundle = try XCTUnwrap(ScenarioContentCatalog.bundle(for: instance.id))
            let deploymentZoneIDs = Set(instance.deploymentZones.map(\.id))
            let blueprint = instance.engineBlueprint(seed: UInt32(90_000 + instance.order))

            XCTAssertTrue(instance.isModeledForNativeGameplay, instance.title)
            XCTAssertTrue(instance.requiresNativeScenarioLoader)
            XCTAssertEqual(instance.units.count, bundle.setup.units.count)
            XCTAssertEqual(instance.terrain.count, bundle.mapLayout.elements.count)
            XCTAssertEqual(instance.objectives.count, bundle.scenario.objectives.count)
            XCTAssertEqual(instance.reinforcements.count, bundle.balance.reinforcements.count)
            XCTAssertGreaterThanOrEqual(instance.events.count, bundle.setup.triggers.count + bundle.balance.reinforcements.count + bundle.balance.pacingRules.count)
            XCTAssertTrue(instance.units.allSatisfy { deploymentZoneIDs.contains($0.deploymentZoneID) })
            XCTAssertTrue(instance.units.allSatisfy { !$0.weapons.isEmpty })
            XCTAssertTrue(instance.objectives.allSatisfy { $0.position.x >= 0 && $0.position.x <= instance.frame.width })
            XCTAssertTrue(instance.objectives.allSatisfy { $0.position.y >= 0 && $0.position.y <= instance.frame.height })

            XCTAssertTrue(blueprint.isCompleteForScenarioLoader, instance.title)
            XCTAssertEqual(blueprint.units.count, instance.units.count)
            XCTAssertEqual(blueprint.objectives.count, instance.objectives.count)
            XCTAssertEqual(blueprint.terrain.count, instance.terrain.count)
            XCTAssertEqual(blueprint.missionTargetScore, instance.victory.missionTargetScore)
            XCTAssertTrue(blueprint.units.allSatisfy { $0.x >= 0 && $0.x <= blueprint.engineBoardFrame.width })
            XCTAssertTrue(blueprint.units.allSatisfy { $0.y >= 0 && $0.y <= blueprint.engineBoardFrame.height })
            XCTAssertTrue(blueprint.objectives.allSatisfy { $0.victoryPoints > 0 })
        }
    }

    func testCycle270DemoInstancesExposePlayableClassesAndScenarioEvents() throws {
        let wizna = try XCTUnwrap(NativeBattleInstanceCatalog.instance(for: .wizna))
        XCTAssertTrue(wizna.terrain.contains { $0.kind == .bunker })
        XCTAssertTrue(wizna.units.contains { unit in unit.weapons.contains { $0.role == .antiTank } })
        XCTAssertTrue(wizna.events.contains { $0.kind == .tutorial })

        let sedan = try XCTUnwrap(NativeBattleInstanceCatalog.instance(for: .sedan))
        XCTAssertTrue(sedan.terrain.contains { $0.kind == .river })
        XCTAssertTrue(sedan.terrain.contains { $0.kind == .bridge })
        XCTAssertTrue(sedan.units.contains { $0.mobility == .engineer })
        XCTAssertTrue(sedan.units.contains { unit in unit.weapons.contains { $0.role == .airSupport } })
        XCTAssertTrue(sedan.events.contains { $0.kind == .reinforcement })

        let moscow = try XCTUnwrap(NativeBattleInstanceCatalog.instance(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.terrain.contains { $0.name.contains("Tula") })
        XCTAssertTrue(moscow.units.contains { $0.side == .player && $0.mobility == .armor })
        XCTAssertTrue(moscow.events.contains { $0.kind == .reinforcement })
        XCTAssertTrue(moscow.victory.targetTurns.upperBound >= 7)
    }

    func testCycle280NativeScenarioLoaderCreatesSkirmishBridgeForEveryBattle() throws {
        XCTAssertEqual(NativeScenarioLoader.cycleRange, 271...280)
        XCTAssertEqual(NativeScenarioLoader.boardHookCycleRange, 281...290)

        for scenario in GuderianCampaignCatalog.all {
            let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(100_000 + scenario.order))
            let loadedGame = try XCTUnwrap(loadout.makeGame(), "\(scenario.title) should create a native-loader skirmish bridge")

            XCTAssertEqual(loadout.scenario.id, scenario.id)
            XCTAssertFalse(loadout.usesForcePresetProxy)
            XCTAssertEqual(loadout.gameCreationMode, .nativeBlueprintSkirmishBridge)
            XCTAssertTrue(loadout.canCreateSkirmishBridge, scenario.title)
            XCTAssertTrue(loadout.canApplyScenarioBoardHook, scenario.title)
            XCTAssertFalse(loadout.playerEntries.isEmpty, "\(scenario.title) needs player army-list entries")
            XCTAssertFalse(loadout.opponentEntries.isEmpty, "\(scenario.title) needs opponent army-list entries")
            XCTAssertTrue(loadout.playerEntries.allSatisfy { $0.count > 0 })
            XCTAssertTrue(loadout.opponentEntries.allSatisfy { $0.count > 0 })
            XCTAssertTrue(loadout.warnings.contains { $0.id.contains("event-hook") })

            XCTAssertGreaterThan(Int(game_unit_count(loadedGame.handle)), 0)
            XCTAssertGreaterThan(Int(game_objective_count(loadedGame.handle)), 0)
            XCTAssertTrue(loadedGame.boardReport.isScenarioSpecific, "\(scenario.title) should apply a scenario board")
            XCTAssertEqual(game_mission_view(loadedGame.handle).target_score, Int32(loadout.blueprint.missionTargetScore))
            XCTAssertEqual(Int(game_objective_count(loadedGame.handle)), min(loadout.blueprint.objectives.count, NativeScenarioLoader.boardObjectiveCapacity))
            XCTAssertEqual(Int(game_zone_count(loadedGame.handle)), min(loadout.blueprint.terrain.filter { $0.kind != .objective && $0.kind != .airPressure }.isEmpty ? loadout.blueprint.terrain.count : loadout.blueprint.terrain.filter { $0.kind != .objective && $0.kind != .airPressure }.count, NativeScenarioLoader.boardTerrainZoneCapacity))
            XCTAssertGreaterThan(loadedGame.deploymentReport.attempted, 0, "\(scenario.title) should attempt scenario deployments")
            XCTAssertTrue(loadedGame.deploymentReport.placedAnyScenarioUnit, "\(scenario.title) should place at least one native blueprint unit")
        }
    }

    func testCycle290DemoNativeLoaderUsesScenarioBoardAndBlueprintPositions() throws {
        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let loadout = NativeScenarioLoader.load(scenario, seed: UInt32(110_000 + scenario.order))
            let loadedGame = try XCTUnwrap(loadout.makeGame())
            let firstPlayerSpawn = try XCTUnwrap(loadout.blueprint.units.first { $0.side == .player })
            let playerUnit = try XCTUnwrap((0..<Int(game_unit_count(loadedGame.handle))).lazy
                .map { game_unit_view(loadedGame.handle, Int32($0)) }
                .first { $0.owner == DZW_PLAYER_ONE && !$0.embarked })

            XCTAssertLessThanOrEqual(abs(Double(playerUnit.x) - firstPlayerSpawn.x), 8.5, scenario.title)
            XCTAssertLessThanOrEqual(abs(Double(playerUnit.y) - firstPlayerSpawn.y), 8.5, scenario.title)
            XCTAssertEqual(game_mission_view(loadedGame.handle).target_score, Int32(loadout.blueprint.missionTargetScore))
            XCTAssertEqual(String(cString: game_mission_view(loadedGame.handle).name), scenario.title)
            XCTAssertEqual(String(cString: game_objective_view(loadedGame.handle, 0).name), loadout.blueprint.objectives[0].name)
            XCTAssertGreaterThan(Int(game_zone_count(loadedGame.handle)), 0, "The guarded board/mission C hook should apply scenario terrain.")
        }
    }

    func testCycle290NativeBoardSessionExposesPlayableBoardControls() throws {
        XCTAssertEqual(NativeBoardSession.cycleRange, 281...290)

        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .sedan))
        let session = try XCTUnwrap(NativeBoardSession(scenario: scenario, seed: 19400513))
        let opening = session.snapshot()

        XCTAssertTrue(opening.isScenarioBoardPlayable)
        XCTAssertEqual(opening.scenarioID, .sedan)
        XCTAssertEqual(opening.mission.name, scenario.title)
        XCTAssertEqual(opening.mission.targetScore, NativeBattleInstanceCatalog.instance(for: scenario).victory.missionTargetScore)
        XCTAssertFalse(opening.zones.isEmpty)
        XCTAssertFalse(opening.objectives.isEmpty)
        XCTAssertFalse(opening.units.isEmpty)
        XCTAssertNotNil(opening.selectedUnit)
        XCTAssertNotNil(opening.selectedTarget)
        XCTAssertEqual(opening.phase, .movement)

        _ = session.moveSelectedUnitTowardNearestObjective(maxDistance: 2)
        let afterMove = session.snapshot()
        XCTAssertNotEqual(afterMove.lastAction.status, .idle)

        session.advancePhase()
        let shooting = session.snapshot()
        XCTAssertEqual(shooting.phase, .shooting)
        XCTAssertNotNil(shooting.selectedUnit)

        _ = session.shootSelectedTarget()
        let afterFire = session.snapshot()
        XCTAssertNotEqual(afterFire.lastAction.status, .idle)
        XCTAssertFalse(afterFire.logLines.isEmpty)
    }

    func testCycle300DemoParityCompletesDemoBattlesFromNativeBoardToDebrief() throws {
        XCTAssertEqual(NativeDemoParityRunner.cycleRange, 291...300)
        XCTAssertEqual(NativeDemoParityRunner.playableBattleIDs, GuderianCampaignCatalog.demoIDs)

        for id in GuderianCampaignCatalog.demoIDs {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: id))
            let balance = ScenarioBalanceCatalog.profile(for: scenario)
            let completion = try NativeDemoParityRunner.runBattle(
                scenario,
                seed: UInt32(150_000 + scenario.order)
            )

            XCTAssertEqual(completion.id, id)
            XCTAssertEqual(completion.cycleStart, 291)
            XCTAssertEqual(completion.cycleEnd, 300)
            XCTAssertTrue(completion.completedFromNativeBoardToDebrief, scenario.title)
            XCTAssertTrue(completion.completedWithoutGenericProxies, scenario.title)
            XCTAssertEqual(completion.openingSnapshot.scenarioID, id)
            XCTAssertEqual(completion.openingSnapshot.mission.name, scenario.title)
            XCTAssertTrue(completion.openingSnapshot.isScenarioBoardPlayable)
            XCTAssertTrue(completion.finalSnapshot.isScenarioBoardPlayable)
            XCTAssertTrue(completion.openingSnapshot.deploymentReport.placedAnyScenarioUnit)
            XCTAssertEqual(completion.score, balance.maxPlayerScore)
            XCTAssertEqual(completion.score, completion.scoreAwards.filter(\.awarded).reduce(0) { $0 + $1.victoryPoints })
            XCTAssertTrue(balance.outcomeBands.contains { $0.grade == completion.victoryBand && $0.scoreRange.contains(completion.score) })
            XCTAssertEqual(completion.completionRecord.scenarioID, id)
            XCTAssertEqual(completion.completionRecord.score, completion.score)
            XCTAssertEqual(completion.completionRecord.victoryBand, completion.victoryBand)
            XCTAssertGreaterThan(completion.phaseAdvances, 0)
            XCTAssertFalse(completion.steps.isEmpty)
            XCTAssertTrue(completion.steps.contains { $0.phase == .movement })
            XCTAssertTrue(completion.steps.contains { $0.phase == .shooting })
            XCTAssertTrue(completion.steps.contains { $0.phase == .assault })
            XCTAssertTrue(completion.debriefSummary.contains("\(completion.score)/\(balance.maxPlayerScore) VP"))
        }
    }

    func testCycle300DemoParityCampaignProgressRecordsAllDemoCompletions() throws {
        let suite = try NativeDemoParityRunner.runDemoCampaign()

        XCTAssertEqual(suite.battleIDs, GuderianCampaignCatalog.demoIDs)
        XCTAssertEqual(suite.completions.map(\.id), GuderianCampaignCatalog.demoIDs)
        XCTAssertTrue(suite.completedAllDemoBattles)
        XCTAssertTrue(suite.summary.isComplete)
        XCTAssertEqual(suite.summary.completedScenarios, GuderianCampaignCatalog.demoIDs.count)
        XCTAssertEqual(suite.summary.remainingScenarioIDs, [])
        XCTAssertNil(suite.summary.nextScenarioID)
        XCTAssertEqual(suite.progress.completedCount, GuderianCampaignCatalog.demoIDs.count)
        XCTAssertTrue(suite.completions.allSatisfy { suite.progress.completionRecord(for: $0.id) == $0.completionRecord })
    }

    func testCycle310NativeBoardDiagnosticsRunEveryBattleThroughRealBoardActions() throws {
        XCTAssertEqual(NativeBoardDiagnosticsRunner.cycleRange, 301...310)

        let suite = NativeBoardDiagnosticsRunner.runCampaign()
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(suite.cycleStart, 301)
        XCTAssertEqual(suite.cycleEnd, 310)
        XCTAssertEqual(suite.reports.map(\.id), orderedIDs)
        XCTAssertEqual(suite.passedCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(suite.blockingFindingCount, 0)

        for diagnostic in suite.reports {
            XCTAssertTrue(diagnostic.openedNativeSession, diagnostic.title)
            XCTAssertTrue(diagnostic.passedRealBoardDiagnostics, "\(diagnostic.title): \(diagnostic.findings.map(\.detail).joined(separator: "\n"))")
            XCTAssertTrue(diagnostic.openingSnapshot?.isScenarioBoardPlayable == true, diagnostic.title)
            XCTAssertTrue(diagnostic.finalSnapshot?.isScenarioBoardPlayable == true, diagnostic.title)
            XCTAssertGreaterThan(diagnostic.legalActionsAttempted, 0, diagnostic.title)
            XCTAssertGreaterThan(diagnostic.legalActionsSucceeded, 0, diagnostic.title)
            XCTAssertGreaterThanOrEqual(diagnostic.phaseAdvances, 2, diagnostic.title)
            XCTAssertFalse(diagnostic.steps.isEmpty, diagnostic.title)
            XCTAssertTrue(diagnostic.steps.contains { $0.phase == .movement }, diagnostic.title)
            XCTAssertTrue(diagnostic.steps.contains { $0.phase == .shooting }, diagnostic.title)
            XCTAssertTrue(diagnostic.steps.contains { $0.phase == .assault }, diagnostic.title)
            XCTAssertFalse(diagnostic.findings.contains { $0.kind == .blockedPhase })
            XCTAssertFalse(diagnostic.findings.contains { $0.kind == .impossibleReinforcement })
            XCTAssertFalse(diagnostic.findings.contains { $0.kind == .unwinnableGate })
        }
    }

    func testCycle325NativePolandPackCoversFour1939BattlesAndCompletesThem() throws {
        XCTAssertEqual(NativePolandBattlefieldPackCatalog.cycleRange, 311...325)
        XCTAssertEqual(
            NativePolandBattlefieldPackCatalog.playableBattleIDs,
            [.tucholaForest, .wizna, .brzescLitewski, .kobryn]
        )

        let packs = NativePolandBattlefieldPackCatalog.allPacks
        XCTAssertEqual(packs.map(\.id), NativePolandBattlefieldPackCatalog.playableBattleIDs)
        XCTAssertTrue(packs.allSatisfy(\.isNativePolandPackReady))

        let tuchola = try XCTUnwrap(NativePolandBattlefieldPackCatalog.pack(for: .tucholaForest))
        XCTAssertTrue(tuchola.hasRule(.withdrawal))
        XCTAssertTrue(tuchola.hasRule(.demolition))
        XCTAssertTrue(tuchola.hasRule(.cavalryScreen))
        XCTAssertTrue(tuchola.hasRule(.antiTankLane))
        XCTAssertTrue(tuchola.objectiveKinds.contains(.withdraw))
        XCTAssertTrue(tuchola.playerMobilities.contains(.cavalry))

        let wizna = try XCTUnwrap(NativePolandBattlefieldPackCatalog.pack(for: .wizna))
        XCTAssertTrue(wizna.hasRule(.bunker))
        XCTAssertTrue(wizna.terrainKinds.contains(.bunker))
        XCTAssertTrue(wizna.terrainKinds.contains(.fortifiedLine))

        let brzesc = try XCTUnwrap(NativePolandBattlefieldPackCatalog.pack(for: .brzescLitewski))
        XCTAssertTrue(brzesc.hasRule(.railSupport))
        XCTAssertTrue(brzesc.hasRule(.fortressUrban))
        XCTAssertTrue(brzesc.hasRule(.obsoleteArmor))
        XCTAssertTrue(brzesc.playerMobilities.contains(.armoredTrain))
        XCTAssertTrue(brzesc.playerMobilities.contains(.armor))

        let kobryn = try XCTUnwrap(NativePolandBattlefieldPackCatalog.pack(for: .kobryn))
        XCTAssertTrue(kobryn.hasRule(.withdrawal))
        XCTAssertTrue(kobryn.hasRule(.roadblock))
        XCTAssertTrue(kobryn.objectiveKinds.contains(.withdraw))

        let campaign = try NativePolandPackRunner.runCampaign()
        XCTAssertTrue(campaign.completedAllPolishBattles)
        XCTAssertEqual(campaign.summary.completedScenarios, NativePolandBattlefieldPackCatalog.playableBattleIDs.count)
        XCTAssertTrue(campaign.completions.allSatisfy(\.completedFromNativePolandBattlefield))
        XCTAssertTrue(campaign.completions.allSatisfy { $0.completionRecord.score > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { $0.phaseAdvances > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { !$0.steps.isEmpty })
    }

    func testCycle345NativeFrancePackCoversFrance1940BattlesAndCompletesThem() throws {
        XCTAssertEqual(NativeFranceBattlefieldPackCatalog.cycleRange, 326...345)
        XCTAssertEqual(
            NativeFranceBattlefieldPackCatalog.playableBattleIDs,
            [.sedan, .stonne, .montcornet, .amiensAbbeville, .boulogne, .calais, .dunkirk, .fallRot]
        )

        let packs = NativeFranceBattlefieldPackCatalog.allPacks
        XCTAssertEqual(packs.map(\.id), NativeFranceBattlefieldPackCatalog.playableBattleIDs)
        XCTAssertTrue(packs.allSatisfy(\.isNativeFrancePackReady))

        let sedan = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .sedan))
        XCTAssertTrue(sedan.hasRule(.riverCrossing))
        XCTAssertTrue(sedan.hasRule(.bridgehead))
        XCTAssertTrue(sedan.hasRule(.airPressure))
        XCTAssertTrue(sedan.terrainKinds.contains(.river))
        XCTAssertTrue(sedan.terrainKinds.contains(.bridge))

        let stonne = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .stonne))
        XCTAssertTrue(stonne.hasRule(.heavyTankShock))
        XCTAssertTrue(stonne.terrainKinds.contains(.town))
        XCTAssertTrue(stonne.playerMobilities.contains(.armor))

        let montcornet = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .montcornet))
        XCTAssertTrue(montcornet.hasRule(.armoredRaid))
        XCTAssertTrue(montcornet.hasRule(.airPressure))
        XCTAssertTrue(montcornet.hasRule(.withdrawal))

        let amiens = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .amiensAbbeville))
        XCTAssertTrue(amiens.hasRule(.riverCrossing))
        XCTAssertTrue(amiens.hasRule(.channelDelay))

        let boulogne = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .boulogne))
        XCTAssertTrue(boulogne.hasRule(.evacuation))
        XCTAssertTrue(boulogne.hasRule(.navalSupport))
        XCTAssertTrue(boulogne.hasRule(.portDenial))

        let calais = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .calais))
        XCTAssertTrue(calais.hasRule(.siegeSupply))
        XCTAssertTrue(calais.hasRule(.channelDelay))

        let dunkirk = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .dunkirk))
        XCTAssertTrue(dunkirk.hasRule(.evacuation))
        XCTAssertTrue(dunkirk.hasRule(.channelDelay))

        let fallRot = try XCTUnwrap(NativeFranceBattlefieldPackCatalog.pack(for: .fallRot))
        XCTAssertTrue(fallRot.hasRule(.fortressFallback))
        XCTAssertTrue(fallRot.hasRule(.withdrawal))

        let campaign = try NativeFrancePackRunner.runCampaign()
        XCTAssertTrue(campaign.completedAllFranceBattles)
        XCTAssertEqual(campaign.summary.completedScenarios, NativeFranceBattlefieldPackCatalog.playableBattleIDs.count)
        XCTAssertTrue(campaign.completions.allSatisfy(\.completedFromNativeFranceBattlefield))
        XCTAssertTrue(campaign.completions.allSatisfy { $0.completionRecord.score > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { $0.phaseAdvances > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { !$0.steps.isEmpty })
    }

    func testCycle350EasternFrontNativeFoundationCoversAll1941Battles() throws {
        XCTAssertEqual(NativeEasternFrontBattlefieldFoundationCatalog.cycleRange, 346...350)
        XCTAssertEqual(
            NativeEasternFrontBattlefieldFoundationCatalog.foundationBattleIDs,
            [.bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .mtsensk, .moscowTulaKashira]
        )

        let foundations = NativeEasternFrontBattlefieldFoundationCatalog.allFoundations
        XCTAssertEqual(foundations.map(\.id), NativeEasternFrontBattlefieldFoundationCatalog.foundationBattleIDs)
        XCTAssertTrue(foundations.allSatisfy(\.isNativeEasternFrontFoundationReady))

        for foundation in foundations {
            let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: foundation.id))
            XCTAssertTrue(NativeEasternFrontBattlefieldFoundationCatalog.isFoundationReady(scenario), foundation.title)
            XCTAssertFalse(foundation.summary.isEmpty)
        }

        let bialystok = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .bialystokMinsk))
        XCTAssertTrue(bialystok.hasRule(.pocket))
        XCTAssertTrue(bialystok.hasRule(.breakout))
        XCTAssertTrue(bialystok.hasRule(.mechanizedCounterattack))

        let smolensk = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .smolensk))
        XCTAssertTrue(smolensk.hasRule(.riverCrossing))
        XCTAssertTrue(smolensk.hasRule(.logistics))
        XCTAssertTrue(smolensk.hasRule(.breakout))

        let roslavl = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .roslavlNovozybkov))
        XCTAssertTrue(roslavl.hasRule(.southwardTurn))

        let kiev = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .kiev))
        XCTAssertTrue(kiev.hasRule(.pincer))
        XCTAssertTrue(kiev.hasRule(.commandPost))
        XCTAssertTrue(kiev.hasRule(.pocket))

        let bryansk = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .bryansk))
        XCTAssertTrue(bryansk.hasRule(.logistics))
        XCTAssertTrue(bryansk.hasRule(.tulaDefense))

        let mtsensk = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .mtsensk))
        XCTAssertTrue(mtsensk.hasRule(.armorAmbush))
        XCTAssertTrue(mtsensk.hasRule(.t34KVShock))

        let moscow = try XCTUnwrap(NativeEasternFrontBattlefieldFoundationCatalog.foundation(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.hasRule(.winterFriction))
        XCTAssertTrue(moscow.hasRule(.tulaDefense))
    }

    func testCycle370NativeEasternFrontPackCovers1941BattlesAndCompletesThem() throws {
        XCTAssertEqual(NativeEasternFrontBattlefieldPackCatalog.cycleRange, 346...370)
        XCTAssertEqual(
            NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs,
            [.bialystokMinsk, .smolensk, .roslavlNovozybkov, .kiev, .bryansk, .mtsensk, .moscowTulaKashira]
        )

        let packs = NativeEasternFrontBattlefieldPackCatalog.allPacks
        XCTAssertEqual(packs.map(\.id), NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs)
        XCTAssertTrue(packs.allSatisfy(\.isNativeEasternFrontPackReady))
        XCTAssertTrue(packs.allSatisfy { $0.foundationCycleStart == 346 && $0.foundationCycleEnd == 350 })

        let bialystok = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .bialystokMinsk))
        XCTAssertTrue(bialystok.hasRule(.pocket))
        XCTAssertTrue(bialystok.hasRule(.breakout))
        XCTAssertTrue(bialystok.hasRule(.mechanizedCounterattack))

        let smolensk = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .smolensk))
        XCTAssertTrue(smolensk.hasRule(.riverCrossing))
        XCTAssertTrue(smolensk.hasRule(.logistics))
        XCTAssertTrue(smolensk.hasRule(.breakout))

        let kiev = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .kiev))
        XCTAssertTrue(kiev.hasRule(.pincer))
        XCTAssertTrue(kiev.hasRule(.commandPost))
        XCTAssertTrue(kiev.hasRule(.pocket))

        let mtsensk = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .mtsensk))
        XCTAssertTrue(mtsensk.hasRule(.armorAmbush))
        XCTAssertTrue(mtsensk.hasRule(.t34KVShock))

        let moscow = try XCTUnwrap(NativeEasternFrontBattlefieldPackCatalog.pack(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.hasRule(.winterFriction))
        XCTAssertTrue(moscow.hasRule(.tulaDefense))
        XCTAssertTrue(moscow.hasRule(.counteroffensive))

        let campaign = try NativeEasternFrontPackRunner.runCampaign()
        XCTAssertTrue(campaign.completedAllEasternFrontBattles)
        XCTAssertEqual(campaign.summary.completedScenarios, NativeEasternFrontBattlefieldPackCatalog.playableBattleIDs.count)
        XCTAssertTrue(campaign.completions.allSatisfy(\.completedFromNativeEasternFrontBattlefield))
        XCTAssertTrue(campaign.completions.allSatisfy { $0.completionRecord.score > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { $0.phaseAdvances > 0 })
        XCTAssertTrue(campaign.completions.allSatisfy { !$0.steps.isEmpty })
    }

    func testCycle375NativeAIEventPassCoversEveryBattle() throws {
        XCTAssertEqual(NativeAIEventPassCatalog.cycleRange, 371...375)

        let reports = NativeAIEventPassCatalog.allReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(reports.allSatisfy(\.isNativeAIEventPassReady))

        for report in reports {
            XCTAssertGreaterThan(report.aiOrderCount, 0, report.title)
            XCTAssertGreaterThan(report.targetPriorityCount, 0, report.title)
            XCTAssertGreaterThan(report.fallbackBehaviorCount, 0, report.title)
            XCTAssertGreaterThan(report.eventTriggerCount, 0, report.title)
            XCTAssertGreaterThan(report.deterministicSeedHint, 0, report.title)
            XCTAssertTrue(report.hasBinding(.germanPriority), report.title)
            XCTAssertTrue(report.hasBinding(.fallbackBehavior), report.title)
            XCTAssertTrue(report.hasBinding(.victoryGate), report.title)
            XCTAssertFalse(report.summary.isEmpty)
        }

        let sedan = try XCTUnwrap(NativeAIEventPassCatalog.report(for: .sedan))
        XCTAssertTrue(sedan.hasBinding(.reinforcementTiming))
        XCTAssertTrue(sedan.hasBinding(.scenarioRule))

        let moscow = try XCTUnwrap(NativeAIEventPassCatalog.report(for: .moscowTulaKashira))
        XCTAssertTrue(moscow.hasBinding(.reinforcementTiming))
        XCTAssertTrue(moscow.hasBinding(.scenarioRule))
        XCTAssertGreaterThan(moscow.scenarioRuleEventCount, 0)
    }

    func testCycle380NativeAIEventExecutionOperatesOnBoardState() throws {
        XCTAssertEqual(NativeAIEventExecutionCatalog.cycleRange, 376...380)

        let reports = NativeAIEventExecutionCatalog.allReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(reports.allSatisfy(\.isNativeAIEventExecutionReady))

        for report in reports {
            XCTAssertEqual(report.passCycleStart, NativeAIEventPassCatalog.cycleRange.lowerBound, report.title)
            XCTAssertEqual(report.passCycleEnd, NativeAIEventPassCatalog.cycleRange.upperBound, report.title)
            XCTAssertTrue(report.openedBoardSession, report.title)
            XCTAssertTrue(report.scenarioBoardPlayable, report.title)
            XCTAssertGreaterThan(report.aiControlResolutionCount, 0, report.title)
            XCTAssertGreaterThan(report.fallbackResolutionCount, 0, report.title)
            XCTAssertGreaterThan(report.eventResolutionCount, 0, report.title)
            XCTAssertGreaterThan(report.victoryGateResolutionCount, 0, report.title)
            XCTAssertEqual(report.boardStateResolutionCount, report.resolutions.count, report.title)
            XCTAssertFalse(report.preferredObjectiveNames.isEmpty, report.title)
            XCTAssertFalse(report.summary.isEmpty)
            XCTAssertTrue(report.resolutions.allSatisfy(\.resolvedAgainstBoardState), report.title)
            XCTAssertTrue(report.resolutions.contains { $0.boardTargetKind == .objective || $0.boardTargetKind == .mission })
        }

        let sedan = try XCTUnwrap(NativeAIEventExecutionCatalog.report(for: .sedan))
        XCTAssertGreaterThan(sedan.reinforcementResolutionCount, 0)
        XCTAssertGreaterThan(sedan.scenarioRuleResolutionCount, 0)

        let moscow = try XCTUnwrap(NativeAIEventExecutionCatalog.report(for: .moscowTulaKashira))
        XCTAssertGreaterThan(moscow.reinforcementResolutionCount, 0)
        XCTAssertGreaterThan(moscow.scenarioRuleResolutionCount, 0)
    }

    func testCycle390NativeBalanceUXAuditCoversEveryBattle() throws {
        XCTAssertEqual(NativeBalanceUXAuditCatalog.cycleRange, 381...390)

        let reports = NativeBalanceUXAuditCatalog.allReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(reports.allSatisfy(\.isNativeBalanceUXReady))

        for report in reports {
            XCTAssertTrue(report.readableUnitDensity, report.title)
            XCTAssertTrue(report.playablePacingReady, report.title)
            XCTAssertTrue(report.playerAgencyReady, report.title)
            XCTAssertTrue(report.debriefReady, report.title)
            XCTAssertTrue(report.accessibilityReady, report.title)
            XCTAssertTrue(report.saveLoadReady, report.title)
            XCTAssertTrue(report.failureReportingReady, report.title)
            XCTAssertTrue(report.blockers.isEmpty, report.title)
            XCTAssertGreaterThan(report.nativeUnitCount, 0, report.title)
            XCTAssertGreaterThan(report.nativeObjectiveCount, 0, report.title)
            XCTAssertGreaterThan(report.nativeTerrainCount, 0, report.title)
            XCTAssertGreaterThanOrEqual(report.victoryBandCount, 3, report.title)
            XCTAssertGreaterThanOrEqual(report.maxPlayerScore, report.missionTargetScore, report.title)
            XCTAssertEqual(Set(report.signals.map(\.kind)).count, 7, report.title)
            XCTAssertTrue(report.signals.allSatisfy(\.ready), report.title)
            XCTAssertFalse(report.summary.isEmpty)
        }
    }

    func testCycle400NativeCampaignShipReportIsReady() throws {
        XCTAssertEqual(NativeCampaignShipReportCatalog.cycleRange, 391...400)

        let report = NativeCampaignShipReportCatalog.report()

        XCTAssertTrue(report.isNativeCampaignShipReady, report.blockers.joined(separator: "\n"))
        XCTAssertEqual(report.scenarioCount, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.nativePlayableCount, report.scenarioCount)
        XCTAssertEqual(report.automationNonTerminalCount, report.scenarioCount)
        XCTAssertEqual(report.completedScenarioCount, report.scenarioCount)
        XCTAssertEqual(report.aiEventExecutionReadyCount, report.scenarioCount)
        XCTAssertEqual(report.balanceUXReadyCount, report.scenarioCount)
        XCTAssertTrue(report.metadataShipReady)
        XCTAssertTrue(report.blockers.isEmpty)
        XCTAssertTrue(report.gates.allSatisfy { $0.status == .passed })
        XCTAssertTrue(report.gates.contains { $0.id == "native-playable" })
        XCTAssertTrue(report.gates.contains { $0.id == "ai-events" })
        XCTAssertTrue(report.gates.contains { $0.id == "balance-ux" })
        XCTAssertTrue(report.buildCommands.contains("swift test"))
        XCTAssertTrue(report.buildCommands.contains { $0.contains("GuderianTest") })
        XCTAssertFalse(report.summary.isEmpty)
    }

    func testCycle425PostShipAnalysisCoversEveryBattle() throws {
        XCTAssertEqual(NativePostShipAnalysisCatalog.cycleRange, 401...425)

        let reports = NativePostShipAnalysisCatalog.allReports
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(reports.map(\.id), orderedIDs)
        XCTAssertEqual(reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(reports.allSatisfy(\.isPostShipAnalysisReady))

        for report in reports {
            XCTAssertEqual(report.readinessStatus, .nativePlayable, report.title)
            XCTAssertTrue(report.aiEventExecutionReady, report.title)
            XCTAssertTrue(report.balanceUXReady, report.title)
            XCTAssertGreaterThanOrEqual(report.notes.count, 5, report.title)
            XCTAssertEqual(Set(report.notes.map(\.theme)).count, 5, report.title)
            XCTAssertFalse(report.tuningBacklog.isEmpty, report.title)
            XCTAssertFalse(report.summary.isEmpty)
        }
    }

    func testCycle450NativeCampaignSoakRunsDeterministicProbes() throws {
        XCTAssertEqual(NativeCampaignSoakRunner.cycleRange, 426...450)
        XCTAssertEqual(NativeCampaignSoakRunner.seedsPerBattle, 3)

        let suite = NativeCampaignSoakRunner.runCampaign()
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)

        XCTAssertEqual(suite.reports.map(\.id), orderedIDs)
        XCTAssertEqual(suite.reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(suite.stableBattleCount, GuderianCampaignCatalog.all.count)
        XCTAssertTrue(suite.isCampaignSoakReady)

        for report in suite.reports {
            XCTAssertTrue(report.isSoakStable, report.title)
            XCTAssertEqual(report.probes.count, NativeCampaignSoakRunner.seedsPerBattle, report.title)
            XCTAssertEqual(Set(report.probes.map(\.seed)).count, NativeCampaignSoakRunner.seedsPerBattle, report.title)
            XCTAssertEqual(Set(report.probes.map(\.replaySignature)).count, NativeCampaignSoakRunner.seedsPerBattle, report.title)
            XCTAssertTrue(report.probes.allSatisfy(\.isStable), report.title)
            XCTAssertFalse(report.summary.isEmpty)
        }
    }

    func testCycle460TucholaForestSupportsDZWStylePlayableCommands() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let session = try XCTUnwrap(NativeBoardSession(scenario: scenario, seed: 19390901))
        let opening = session.snapshot()

        XCTAssertEqual(opening.scenarioID, .tucholaForest)
        XCTAssertEqual(opening.mission.name, scenario.title)
        XCTAssertTrue(opening.isScenarioBoardPlayable)
        XCTAssertGreaterThan(opening.zones.count, 0)
        XCTAssertGreaterThan(opening.objectives.count, 0)
        XCTAssertTrue(opening.units.contains { $0.owner == .player })
        XCTAssertTrue(opening.units.contains { $0.owner == .guderianAI })
        XCTAssertEqual(opening.phase, .movement)

        let selected = try XCTUnwrap(opening.selectedUnit)
        XCTAssertEqual(selected.owner, opening.activePlayer)
        XCTAssertTrue(selected.canMoveNow)

        let destination = NativeBattleCoordinate(
            x: min(selected.x + 1.25, 70),
            y: min(selected.y + 1.0, 46)
        )
        XCTAssertTrue(session.moveUnit(selected.id, to: destination), session.snapshot().lastAction.detail)

        let movedSnapshot = session.snapshot()
        let moved = try XCTUnwrap(movedSnapshot.units.first { $0.id == selected.id })
        XCTAssertNotEqual(moved.x, selected.x)
        XCTAssertNotEqual(moved.y, selected.y)

        XCTAssertTrue(session.rotateUnit(selected.id, to: selected.facingDegrees + 45), session.snapshot().lastAction.detail)
        _ = session.toggleCover(for: selected.id, enabled: true)
        _ = session.toggleHullDown(for: selected.id, enabled: true)

        session.selectNearestEnemyToSelectedUnit()
        XCTAssertNotNil(session.snapshot().selectedTarget)
        session.advancePhase()
        XCTAssertEqual(session.snapshot().phase, .shooting)
    }

    func testCycle480TucholaForestHasFidelityAndGermanAITurnTargets() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let instance = NativeBattleInstanceCatalog.instance(for: scenario)

        XCTAssertEqual(instance.objectives.count, scenario.objectives.count)
        XCTAssertTrue(instance.objectives.contains { $0.name == "Pruszcz bridge / Pila-Mlyn bridge" && $0.kind == .deny })
        XCTAssertTrue(instance.objectives.contains { $0.name == "Bydgoszcz withdrawal" && $0.kind == .withdraw })
        XCTAssertTrue(instance.terrain.contains { $0.name == "East Prussia pincer" && $0.side == .guderianAI })
        XCTAssertTrue(instance.terrain.contains { $0.name == "XIX Corps spearhead" && $0.side == .guderianAI })
        XCTAssertTrue(instance.units.contains { $0.id == "tuchola-cavalry" && $0.mobility == .cavalry })
        XCTAssertTrue(instance.units.contains { $0.id == "tuchola-demolition-parties" && $0.mobility == .engineer })
        XCTAssertTrue(instance.units.contains { $0.id == "tuchola-3rd-panzer" && $0.mobility == .armor })

        let session = try XCTUnwrap(NativeBoardSession(scenario: scenario, seed: 19390901))
        let opening = session.snapshot()
        XCTAssertTrue(opening.units.contains { $0.name == "Polish 9th Infantry Division bridge guards" && $0.role.contains("Brda") })
        XCTAssertTrue(opening.units.contains { $0.name == "Pomeranian Cavalry Brigade screen" && $0.mobility == "Cavalry" })
        XCTAssertTrue(opening.units.contains { $0.name == "German 3rd Panzer Division spearhead" && $0.mobility == "Armor" })
        XCTAssertTrue(opening.objectives.contains { $0.name == "Pruszcz bridge / Pila-Mlyn bridge" })
        XCTAssertTrue(opening.objectives.contains { $0.name == "Bydgoszcz withdrawal" })

        var safety = 0
        while session.snapshot().activePlayer != .guderianAI && safety < 4 {
            session.advancePhase()
            safety += 1
        }

        let germanTurn = session.snapshot()
        XCTAssertEqual(germanTurn.activePlayer, .guderianAI)
        XCTAssertEqual(germanTurn.phase, .movement)
        let selectedAIUnit = try XCTUnwrap(germanTurn.selectedUnit)
        XCTAssertEqual(selectedAIUnit.owner, .guderianAI)

        XCTAssertTrue(
            session.moveSelectedUnitTowardPriorityObjective(
                named: ["Pruszcz bridge", "Pila-Mlyn bridge", "Chojnice road hub", "Bydgoszcz withdrawal"],
                maxDistance: 6
            ),
            session.snapshot().lastAction.detail
        )
        let afterAIMove = session.snapshot()
        let movedAIUnit = try XCTUnwrap(afterAIMove.units.first { $0.id == selectedAIUnit.id })
        XCTAssertTrue(movedAIUnit.x != selectedAIUnit.x || movedAIUnit.y != selectedAIUnit.y)
        XCTAssertTrue(
            ["Pruszcz bridge", "Pila-Mlyn bridge", "Chojnice road hub", "Bydgoszcz withdrawal"].contains { afterAIMove.lastAction.detail.contains($0) },
            afterAIMove.lastAction.detail
        )
    }

    func testCycle590DZWPlayableScreenHarnessAndRolloutPlanAreReadyForFullCampaign() throws {
        XCTAssertEqual(DZWPlayableScreenHarness.cycleRange, 486...590)
        XCTAssertEqual(PlayableBattleSurfaceCatalog.cycleRange, 491...590)
        XCTAssertEqual(PlayableBattleSurfaceCatalog.completedThroughCycle, 590)

        let harness = try DZWPlayableScreenHarness.runTucholaFlow(seed: 19390901)
        XCTAssertEqual(harness.id, .tucholaForest)
        XCTAssertTrue(harness.completedAllStages, harness.blockers.joined(separator: "\n"))
        XCTAssertTrue(harness.blockers.isEmpty)
        XCTAssertEqual(harness.completedStages, DZWPlayableScreenHarnessStage.allCases)
        XCTAssertTrue(harness.openingSnapshot.isScenarioBoardPlayable)
        XCTAssertEqual(harness.completion.completionRecord.scenarioID, .tucholaForest)
        XCTAssertGreaterThan(harness.completion.completionRecord.score, 0)
        XCTAssertNotNil(harness.persistedProgress.completionRecord(for: .tucholaForest))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-screen"))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-board"))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-action-feedback"))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-debrief-panel"))
        XCTAssertTrue(harness.displayedAccessibilityIdentifiers.contains("battle-persisted-result"))

        let plans = PlayableBattleSurfaceCatalog.allPlans
        let routedThroughCalais: [GuderianBattleID] = [
            .tucholaForest,
            .wizna,
            .brzescLitewski,
            .kobryn,
            .sedan,
            .stonne,
            .montcornet,
            .amiensAbbeville,
            .boulogne,
            .calais,
        ]
        let fullCampaignIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)
        XCTAssertEqual(plans.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(plans.map(\.id), fullCampaignIDs)
        XCTAssertEqual(PlayableBattleSurfaceCatalog.routedBattleIDs, fullCampaignIDs)
        XCTAssertEqual(PlayableBattleSurfaceCatalog.completedBattleIDsThroughCycle545, routedThroughCalais)
        XCTAssertEqual(PlayableBattleSurfaceCatalog.completedBattleIDsThroughCycle590, fullCampaignIDs)
        XCTAssertTrue(PlayableBattleSurfaceCatalog.nextRolloutIDs.isEmpty)

        let tucholaPlan = try XCTUnwrap(PlayableBattleSurfaceCatalog.plan(for: .tucholaForest))
        XCTAssertEqual(tucholaPlan.readiness, .pilotComplete)
        XCTAssertEqual(tucholaPlan.cycleWindow, 451...500)
        XCTAssertEqual(tucholaPlan.acceptanceGates, PlayableBattleAcceptanceGate.allCases)

        let wiznaPlan = try XCTUnwrap(PlayableBattleSurfaceCatalog.plan(for: .wizna))
        XCTAssertEqual(wiznaPlan.readiness, .playableParityComplete)
        XCTAssertEqual(wiznaPlan.cycleWindow, 501...505)

        let calaisPlan = try XCTUnwrap(PlayableBattleSurfaceCatalog.plan(for: .calais))
        XCTAssertEqual(calaisPlan.readiness, .playableParityComplete)
        XCTAssertEqual(calaisPlan.cycleWindow, 541...545)

        let dunkirkPlan = try XCTUnwrap(PlayableBattleSurfaceCatalog.plan(for: .dunkirk))
        XCTAssertEqual(dunkirkPlan.readiness, .playableParityComplete)
        XCTAssertEqual(dunkirkPlan.cycleWindow, 546...550)

        let finalPlan = try XCTUnwrap(PlayableBattleSurfaceCatalog.plan(for: .moscowTulaKashira))
        XCTAssertEqual(finalPlan.readiness, .playableParityComplete)
        XCTAssertEqual(finalPlan.cycleWindow, 586...590)
        XCTAssertTrue(plans.allSatisfy { !$0.notes.isEmpty })
        XCTAssertTrue(plans.allSatisfy { $0.hostSurfaceName == PlayableBattleSurfaceCatalog.hostSurfaceName })
        XCTAssertTrue(plans.allSatisfy { $0.readiness.isPlayableComplete })

        let routedHarnesses = try DZWPlayableScreenHarness.runCompletedParityFlowsThroughCycle590()
        XCTAssertEqual(routedHarnesses.map(\.id), fullCampaignIDs)
        XCTAssertTrue(routedHarnesses.allSatisfy(\.completedAllStages), routedHarnesses.flatMap(\.blockers).joined(separator: "\n"))
        XCTAssertTrue(routedHarnesses.allSatisfy { $0.completedStages == DZWPlayableScreenHarnessStage.allCases })
        XCTAssertTrue(routedHarnesses.allSatisfy { $0.openingSnapshot.isScenarioBoardPlayable })
        XCTAssertTrue(routedHarnesses.allSatisfy { $0.persistedProgress.completionRecord(for: $0.id) != nil })
    }

    func testGuderianTestAutomationRunsEveryBattleAndSurfacesDiagnostics() throws {
        let report = CampaignAutomationRunner.runCampaign()
        let orderedIDs = GuderianCampaignCatalog.all
            .sorted { $0.order < $1.order }
            .map(\.id)
        let demoIDs = Set(GuderianCampaignCatalog.demoIDs)
        let polishIDs = Set(PolishCampaignSystemCatalog.polishScenarioIDs)
        let franceIDs = Set(FranceCampaignSystemCatalog.franceScenarioIDs)
        let easternFrontIDs = Set(EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs)
        let nativePlayableIDs = Set(GuderianCampaignCatalog.demoIDs + PolishCampaignSystemCatalog.polishScenarioIDs + FranceCampaignSystemCatalog.franceScenarioIDs + EasternFrontCampaignSystemCatalog.easternFrontScenarioIDs)
        let routedPlayableScreenIDs = Set(PlayableBattleSurfaceCatalog.routedBattleIDs)

        XCTAssertEqual(report.reports.map(\.id), orderedIDs)
        XCTAssertEqual(report.reports.count, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(report.completionSummary.completedScenarios, GuderianCampaignCatalog.all.count)
        XCTAssertEqual(nativePlayableIDs.count, GuderianCampaignCatalog.all.count)
        XCTAssertGreaterThan(report.reports.reduce(0) { $0 + $1.actionsAttempted }, 0)
        XCTAssertGreaterThan(report.reports.reduce(0) { $0 + $1.phaseAdvances }, 0)

        for battle in report.reports {
            XCTAssertFalse(battle.status.isTerminalProblem, "\(battle.title): \(battle.issues.map(\.detail).joined(separator: "\n"))")
            XCTAssertGreaterThan(battle.engineUnitCount, 0, "\(battle.title) should load engine units")
            XCTAssertGreaterThan(battle.engineObjectiveCount, 0, "\(battle.title) should load engine objectives")
            XCTAssertFalse(battle.steps.isEmpty, "\(battle.title) should expose an automation timeline")
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Loader" })
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Board" })
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Board Diagnostics" })
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Playability" })
            XCTAssertTrue(battle.issues.contains { $0.stage == "Native Loader" && $0.kind == .warning })
            XCTAssertFalse(battle.playerArmy.isEmpty)
            XCTAssertFalse(battle.opponentArmy.isEmpty)
            XCTAssertTrue(battle.nativeBoardDiagnosticsPassed, battle.title)
            XCTAssertNotNil(battle.boardDiagnostic, battle.title)
            XCTAssertTrue(battle.boardDiagnostic?.passedRealBoardDiagnostics == true, battle.title)
            XCTAssertTrue(battle.nativeAIEventPassReady, battle.title)
            XCTAssertFalse(battle.nativeAIEventPassSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native AI/Event Pass" && $0.status == .passed })
            XCTAssertTrue(battle.nativeAIEventExecutionReady, battle.title)
            XCTAssertFalse(battle.nativeAIEventExecutionSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native AI/Event Execution" && $0.status == .passed })
            XCTAssertTrue(battle.nativeBalanceUXReady, battle.title)
            XCTAssertFalse(battle.nativeBalanceUXSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Balance/UX" && $0.status == .passed })
            XCTAssertTrue(battle.nativePostShipAnalysisReady, battle.title)
            XCTAssertFalse(battle.nativePostShipAnalysisSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Post-Ship Analysis" && $0.status == .passed })
            XCTAssertTrue(battle.nativeSoakReady, battle.title)
            XCTAssertFalse(battle.nativeSoakSummary.isEmpty)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Native Campaign Soak" && $0.status == .passed })
            XCTAssertTrue(battle.playableTestGameCompleted, battle.title)
            XCTAssertFalse(battle.playableTestGameSummary.isEmpty, battle.title)
            XCTAssertTrue(battle.playableTestGameBlockers.isEmpty, battle.title)
            XCTAssertTrue(battle.steps.contains { $0.stage == "Playable Test Game" && $0.status == .passed })

            if routedPlayableScreenIDs.contains(battle.id) {
                XCTAssertTrue(battle.playableScreenParityCompleted, battle.title)
                XCTAssertFalse(battle.playableScreenParitySummary.isEmpty)
                XCTAssertTrue(battle.playableScreenParityBlockers.isEmpty, battle.title)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Playable Screen Parity" && $0.status == .passed })
            } else {
                XCTAssertFalse(battle.playableScreenParityCompleted, battle.title)
                XCTAssertTrue(battle.playableScreenParitySummary.isEmpty, battle.title)
                XCTAssertTrue(battle.playableScreenParityBlockers.isEmpty, battle.title)
            }

            if demoIDs.contains(battle.id) {
                XCTAssertTrue(battle.nativeDemoBoardCompleted, battle.title)
                XCTAssertNotNil(battle.completionRecord, battle.title)
                XCTAssertFalse(battle.debriefSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native Demo" && $0.status == .passed })
            }

            if polishIDs.contains(battle.id) {
                XCTAssertTrue(battle.nativePolandPackCompleted, battle.title)
                XCTAssertNotNil(battle.completionRecord, battle.title)
                XCTAssertFalse(battle.nativePolandPackSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native Poland Pack" && $0.status == .passed })
            }

            if franceIDs.contains(battle.id) {
                XCTAssertTrue(battle.nativeFrancePackCompleted, battle.title)
                XCTAssertNotNil(battle.completionRecord, battle.title)
                XCTAssertFalse(battle.nativeFrancePackSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native France Pack" && $0.status == .passed })
            }

            if easternFrontIDs.contains(battle.id) {
                XCTAssertTrue(battle.easternFrontFoundationReady, battle.title)
                XCTAssertFalse(battle.easternFrontFoundationSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native Eastern Front Foundation" && $0.status == .passed })
                XCTAssertTrue(battle.nativeEasternFrontPackCompleted, battle.title)
                XCTAssertNotNil(battle.completionRecord, battle.title)
                XCTAssertFalse(battle.nativeEasternFrontPackSummary.isEmpty)
                XCTAssertTrue(battle.steps.contains { $0.stage == "Native Eastern Front Pack" && $0.status == .passed })
            }

            if nativePlayableIDs.contains(battle.id) {
                XCTAssertFalse(battle.issues.contains { $0.stage == "Native Playability" && $0.kind == .warning }, battle.title)
            } else {
                XCTAssertFalse(battle.nativeDemoBoardCompleted, battle.title)
                XCTAssertFalse(battle.nativePolandPackCompleted, battle.title)
                XCTAssertFalse(battle.nativeFrancePackCompleted, battle.title)
                XCTAssertFalse(battle.nativeEasternFrontPackCompleted, battle.title)
                XCTAssertNil(battle.completionRecord, battle.title)
                XCTAssertTrue(battle.issues.contains { $0.stage == "Native Playability" && $0.kind == .warning })
            }
        }
    }

    func testTucholaForestIsFirstFullCampaignPlayableDataSlice() throws {
        let scenario = try XCTUnwrap(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let bundle = ScenarioContentCatalog.bundle(for: scenario)
        let loadout = try XCTUnwrap(DZWScenarioLoader.load(.tucholaForest, seed: 19390901))

        XCTAssertEqual(scenario.status, .dzwProxyLoadable)
        XCTAssertGreaterThanOrEqual(scenario.sourceLinks.count, 3)
        XCTAssertEqual(loadout.playerArmyName, "British")
        XCTAssertEqual(loadout.opponentArmyName, "German")
        XCTAssertTrue(loadout.adapterNotes.contains { $0.contains("Polish campaign systems") })

        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.kind == .river && $0.name.contains("Brda") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.kind == .forest && $0.name.contains("Tuchola") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("Chojnice") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("Krojanty") })
        XCTAssertTrue(bundle.mapLayout.elements.contains { $0.name.contains("Bydgoszcz") })

        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("9th Infantry") })
        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("Cavalry") })
        XCTAssertTrue(bundle.setup.playerUnits.contains { $0.name.contains("demolition") })
        XCTAssertTrue(bundle.setup.guderianUnits.contains { $0.name.contains("engineers") })
        XCTAssertTrue(bundle.setup.triggers.contains { $0.name.contains("Pincer") })

        XCTAssertTrue(bundle.aiPlan.orders.contains { $0.id == "tuchola-pincer" })
        XCTAssertTrue(bundle.balance.scoreChannels.contains { $0.name.contains("Brda") })
        XCTAssertTrue(bundle.balance.scoreChannels.contains { $0.name.contains("Withdraw") })
        XCTAssertTrue(bundle.balance.reinforcements.contains { $0.unitName.contains("27th Infantry") && $0.side == .player })
        XCTAssertTrue(bundle.balance.reinforcements.contains { $0.unitName.contains("pincer") && $0.side == .guderianAI })
    }
}
