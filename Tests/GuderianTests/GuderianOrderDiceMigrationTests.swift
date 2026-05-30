import Foundation
import GuderianCore
import Testing

@Suite("Guderian order-dice migration cycles 1-200")
struct GuderianOrderDiceMigrationTests {
    @Test("Cycles 1-5 audit covers every known phase-flow dependency category")
    func orderDiceAuditCoversLegacyPhaseDependencies() throws {
        let findings = GuderianOrderDiceAuditCatalog.findings
        let plan = try String(contentsOfFile: "PLAN.md", encoding: .utf8)
        let docs = try String(contentsOfFile: "docs/guderian_order_dice_cycle_001_020.md", encoding: .utf8)

        #expect(GuderianOrderDiceAuditCatalog.acceptanceReadyThroughCycle5)
        #expect(GuderianOrderDiceAuditCatalog.cycleRange == 1...5)
        #expect(findings.count >= 10)
        #expect(GuderianOrderDiceAuditCatalog.categoriesCovered == Set(GuderianOrderDiceAuditCategory.allCases))
        #expect(GuderianOrderDiceAuditCatalog.impactedTypeNames.contains("DZWPlayableBattleViewModel"))
        #expect(GuderianOrderDiceAuditCatalog.impactedTypeNames.contains("GuderianTestFirstBattleRunController"))
        #expect(GuderianOrderDiceAuditCatalog.impactedTypeNames.contains("LateCareerNativeBoardSession"))
        #expect(findings.allSatisfy { !$0.sourcePath.isEmpty && !$0.legacyAssumption.isEmpty })
        #expect(plan.contains("Cycles 1-20 complete"))
        #expect(docs.contains("Rules reference: Warlord Games Bolt Action reference sheet"))
    }

    @Test("Cycles 6-10 scenario impact map covers all 35 battles and both sides")
    func scenarioImpactMapCoversAllUnifiedBattles() throws {
        let rows = GuderianOrderDiceScenarioImpactCatalog.allRows
        let tuchola = try #require(GuderianOrderDiceScenarioImpactCatalog.row(for: .fieldCommand(.tucholaForest)))
        let moscow = try #require(GuderianOrderDiceScenarioImpactCatalog.row(for: .fieldCommand(.moscowTulaKashira)))
        let lateCareer = try #require(rows.first { $0.id.kind == .lateCareer })

        #expect(GuderianOrderDiceScenarioImpactCatalog.acceptanceReadyThroughCycle10)
        #expect(rows.count == 35)
        #expect(rows.map(\.order) == Array(1...35))
        #expect(Set(rows.map(\.id)).count == 35)
        #expect(rows.allSatisfy { $0.hasOrderDiceForBothSides })
        #expect(rows.allSatisfy { !$0.vehicleClasses.isEmpty })
        #expect(rows.allSatisfy { !$0.terrainCategories.isEmpty })
        #expect(tuchola.retainedOrderUse == .ambushLikely || tuchola.retainedOrderUse == .ambushAndDown)
        #expect(tuchola.terrainCategories.contains(.road))
        #expect(moscow.expectedPinPressure == .heavy || moscow.expectedPinPressure == .severe)
        #expect(moscow.vehicleClasses.contains(.heavyArmor))
        #expect(lateCareer.commandScope.requiresCommandCaveat)
        #expect(lateCareer.officerPresence == .commandCritical)
    }

    @Test("Cycles 11-15 compatibility shim maps legacy intent to DZW order contracts")
    func compatibilityShimIssuesOrderBeforeLegacyAction() throws {
        let session = try #require(NativeBoardSession(battleID: .tucholaForest, seed: 20_015))
        let opening = session.snapshot()
        let activeUnit = try #require(opening.units.first { $0.owner == opening.activePlayer && !$0.destroyed })

        #expect(GuderianOrderDiceCompatibilityShim.acceptanceReadyThroughCycle15)
        #expect(GuderianOrderDiceCompatibilityShim.dzwOrderContractReady)
        #expect(GuderianOrderDiceCompatibilityShim.requiredOrders == HistoricalBoardOrder.allCases)
        #expect(GuderianOrderDiceCompatibilityShim.preferredOrder(for: NativeBoardPhase.movement) == .advance)
        #expect(GuderianOrderDiceCompatibilityShim.preferredOrder(for: NativeBoardPhase.shooting) == .fire)
        #expect(GuderianOrderDiceCompatibilityShim.preferredOrder(for: NativeBoardPhase.assault) == .run)
        #expect(GuderianOrderDiceCompatibilityShim.requiredSnapshotFields.contains("pinCount"))
        #expect(GuderianOrderDiceCompatibilityShim.requiredSnapshotFields.contains("retainedOrder"))

        #expect(GuderianOrderDiceCompatibilityShim.issuePreferredOrderBeforeLegacyAction(
            in: session,
            unitID: activeUnit.id,
            phase: opening.phase
        ))
        let orderedUnit = try #require(session.snapshot().units.first { $0.id == activeUnit.id })
        #expect(orderedUnit.currentOrder == GuderianOrderDiceCompatibilityShim.preferredOrder(for: opening.phase))
    }

    @Test("Cycles 16-20 acceptance gates are installed and become blocking after the UI window")
    func acceptanceGatesCatchFuturePhaseSurfaceDebt() throws {
        let playableView = try String(
            contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift",
            encoding: .utf8
        )
        let catalystApp = try String(
            contentsOfFile: "Sources/GuderianMacCatalyst/GuderianMacCatalystApp.swift",
            encoding: .utf8
        )
        let autoplay = try String(
            contentsOfFile: "Sources/GuderianCore/GuderianTestFirstBattleAutoplay.swift",
            encoding: .utf8
        )
        let sources = [
            "Sources/GuderianApp/DZWPlayableBattleView.swift": playableView,
            "Sources/GuderianMacCatalyst/GuderianMacCatalystApp.swift": catalystApp,
            "Sources/GuderianCore/GuderianTestFirstBattleAutoplay.swift": autoplay,
        ]
        let cycle20Report = GuderianOrderDiceAcceptanceCatalog.report(
            sourceTextByPath: sources,
            evaluatedCycle: 20
        )
        let cycle75Report = GuderianOrderDiceAcceptanceCatalog.report(
            sourceTextByPath: sources,
            evaluatedCycle: 75
        )
        let macOSGate = try #require(cycle75Report.gateReports.first { $0.gate.id == "macos-playable-phase-buttons" })

        #expect(GuderianOrderDiceAcceptanceCatalog.acceptanceReadyThroughCycle20)
        #expect(cycle20Report.isReadyThroughCycle20)
        #expect(cycle20Report.blockers.isEmpty)
        #expect(cycle20Report.phaseSurfaceGateCount >= 3)
        #expect(cycle20Report.gateReports.allSatisfy { !$0.isBlocking })
        #expect(macOSGate.observedLegacyIdentifiers.isEmpty ? macOSGate.isSatisfied : macOSGate.isBlocking)
        #expect(GuderianOrderDiceAcceptanceCatalog.phaseSurfaceGates.allSatisfy { !$0.replacementContract.isEmpty })
    }

    @Test("Cycles 21-25 assign quality across every Guderian force family")
    func unitQualityAssignmentsCoverEveryForceFamily() throws {
        let assignments = GuderianOrderDiceUnitQualityCatalog.allAssignments
        let tuchola = GuderianOrderDiceUnitQualityCatalog.assignments(for: .fieldCommand(.tucholaForest))
        let sedan = GuderianOrderDiceUnitQualityCatalog.assignments(for: .fieldCommand(.sedan))
        let moscow = GuderianOrderDiceUnitQualityCatalog.assignments(for: .fieldCommand(.moscowTulaKashira))
        let lateCareer = assignments.filter { $0.battleID.kind == .lateCareer }

        #expect(GuderianOrderDiceUnitQualityCatalog.acceptanceReadyThroughCycle25)
        #expect(assignments.count > 100)
        #expect(GuderianOrderDiceUnitQualityCatalog.forceFamiliesCovered.isSuperset(of: Set(GuderianOrderDiceForceFamily.allCases)))
        #expect(GuderianOrderDiceUnitQualityCatalog.moraleQualitiesCovered == Set(GuderianOrderDiceMoraleQuality.allCases))
        #expect(tuchola.contains { $0.forceFamily == .polish })
        #expect(tuchola.contains { $0.forceFamily == .germanEarlyWar })
        #expect(sedan.contains { $0.forceFamily == .french && $0.moraleQuality == .veteran })
        #expect(moscow.contains { $0.forceFamily == .sovietWinter && $0.moraleQuality == .veteran })
        #expect(lateCareer.contains { $0.forceFamily == .lateWarGerman })
        #expect(lateCareer.contains { $0.forceFamily == .lateCareerGenerated })
    }

    @Test("Cycles 26-30 bootstrap field-command and late-career sessions into order-dice cups")
    func sideOrderDiceBootstrapCreatesDiceForBothSides() throws {
        let scenario = try #require(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let fieldSession = try #require(NativeBoardSession(scenario: scenario, seed: 30_001))
        let lateID = try #require(UnifiedGuderianBattleCatalog.lateCareerEntries.first?.id.lateCareerID)
        let lateSession = try #require(LateCareerNativeBoardSession(battlefieldID: lateID, seed: 30_002))
        let fieldReport = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: fieldSession)
        let lateReport = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: lateSession)

        #expect(GuderianOrderDiceSessionBootstrap.acceptanceReadyThroughCycle30)
        #expect(fieldReport.isReady)
        #expect(lateReport.isReady)
        #expect(fieldReport.playerDice > 0)
        #expect(fieldReport.guderianDice > 0)
        #expect(fieldReport.totalRemainingDice == fieldReport.playerDice + fieldReport.guderianDice)
        #expect(lateReport.totalRemainingDice == lateReport.playerDice + lateReport.guderianDice)
    }

    @Test("Cycles 31-35 map DZW and Guderian-specific order eligibility reasons")
    func eligibilityMapperSurfacesOrderDiceReasons() throws {
        let scenario = try #require(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let session = try #require(NativeBoardSession(scenario: scenario, seed: 35_001))
        let opening = session.snapshot()
        let unit = try #require(opening.units.first { $0.owner == .player && !$0.destroyed })
        let report = try #require(GuderianOrderDiceEligibilityMapper.report(in: session, unitID: unit.id))

        #expect(GuderianOrderDiceEligibilityMapper.acceptanceReadyThroughCycle35)
        #expect(GuderianOrderDiceEligibilityMapper.category(for: "Destroyed units cannot receive orders.") == .destroyed)
        #expect(GuderianOrderDiceEligibilityMapper.category(for: "Embarked units cannot receive orders directly.") == .embarked)
        #expect(GuderianOrderDiceEligibilityMapper.category(for: "Unit is retaining an order.") == .retainedOrder)
        #expect(GuderianOrderDiceEligibilityMapper.category(for: "Pin markers require an order test.") == .pinnedOrderTest)
        #expect(GuderianOrderDiceEligibilityMapper.category(for: "Immobilized vehicles cannot receive movement orders.") == .immobilizedVehicle)
        #expect(report.battleID == .fieldCommand(.tucholaForest))
        #expect(report.unitID == unit.id)
        #expect(report.reasons.count >= HistoricalBoardOrder.allCases.count)
        #expect(report.categories.contains(.noDrawnDie) || report.categories.contains(.eligible))
    }

    @Test("Cycles 36-40 migrate scenario setup to order/movement classifications")
    func setupMigrationClassifiesEveryBattleForOrderMovement() throws {
        let rows = GuderianOrderDiceSetupMigrationCatalog.allRows
        let tuchola = try #require(rows.first { $0.id == .fieldCommand(.tucholaForest) })
        let berlin = try #require(rows.last)
        let acceptance = GuderianOrderDiceMigrationCycle40AcceptanceCatalog.report()

        #expect(GuderianOrderDiceSetupMigrationCatalog.acceptanceReadyThroughCycle40)
        #expect(rows.count == 35)
        #expect(rows.allSatisfy { $0.isReady })
        #expect(tuchola.movementClasses.contains(.roadRunBonus))
        #expect(tuchola.deploymentOpeningOrders.contains(.advance))
        #expect(tuchola.objectiveOrders.contains(.run) || tuchola.objectiveOrders.contains(.ambush))
        #expect(berlin.id.kind == .lateCareer)
        #expect(berlin.eventOrders.contains(.advance))
        #expect(acceptance.isReadyThroughCycle40)
        #expect(acceptance.blockers.isEmpty)
        #expect(acceptance.qualityAssignments == GuderianOrderDiceUnitQualityCatalog.allAssignments.count)
        #expect(acceptance.setupRows == 35)
    }

    @Test("Cycles 41-45 bind historical side selection to order-dice ownership")
    func sideSelectionBindsOrderDiceOwnership() throws {
        let bindings = GuderianOrderDiceSideOwnershipCatalog.allBindings
        let opposing = try #require(GuderianOrderDiceSideOwnershipCatalog.binding(
            for: .fieldCommand(.tucholaForest),
            chosenHumanSideID: GuderianHistoricalSideID.opposingForce
        ))
        let guderian = try #require(GuderianOrderDiceSideOwnershipCatalog.binding(
            for: .fieldCommand(.tucholaForest),
            chosenHumanSideID: GuderianHistoricalSideID.guderianCommand
        ))
        let lateCareer = try #require(bindings.first { $0.battleID.kind == .lateCareer && $0.chosenHumanSideID == GuderianHistoricalSideID.guderianCommand })

        #expect(GuderianOrderDiceSideOwnershipCatalog.acceptanceReadyThroughCycle45)
        #expect(bindings.count == 70)
        #expect(bindings.allSatisfy { $0.isReady })
        #expect(opposing.humanPlayer == .player)
        #expect(opposing.aiPlayer == .guderianAI)
        #expect(guderian.humanPlayer == .guderianAI)
        #expect(guderian.aiPlayer == .player)
        #expect(opposing.humanDice > 0)
        #expect(guderian.humanDice > 0)
        #expect(lateCareer.canHumanControlDrawnDice)
    }

    @Test("Cycles 46-60 expose order panel, inspector, and movement-preview contracts")
    func orderPanelInspectorAndMovementContractsAreReady() throws {
        let sourceText = try String(contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift", encoding: .utf8)
        let scenario = try #require(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let session = try #require(NativeBoardSession(scenario: scenario, seed: 60_060))
        _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        let snapshot = session.snapshot()
        let selected = try #require(snapshot.selectedUnit)
        let commandState = GuderianOrderDiceCommandPanelPresenter.state(
            snapshot: snapshot,
            humanPlayer: .player,
            humanSideTitle: GuderianHistoricalSideSelectionResolver.sideTitle(for: .player, in: scenario),
            activeSideTitle: GuderianHistoricalSideSelectionResolver.sideTitle(for: snapshot.activePlayer, in: scenario)
        )
        let inspectorState = GuderianOrderDiceInspectorPresenter.state(for: selected)
        let movementState = try #require(GuderianOrderDiceMovementPreviewPresenter.state(snapshot: snapshot, battleID: .fieldCommand(.tucholaForest)))
        let acceptance = GuderianOrderDiceMigrationCycle60AcceptanceCatalog.report(sourceText: sourceText)

        #expect(GuderianOrderDiceCommandPanelPresenter.acceptanceReadyThroughCycle50)
        #expect(GuderianOrderDiceInspectorPresenter.acceptanceReadyThroughCycle55)
        #expect(GuderianOrderDiceMovementPreviewPresenter.acceptanceReadyThroughCycle60)
        #expect(commandState.isReady)
        #expect(commandState.canHumanControlDrawnDie)
        #expect(commandState.orderPickerOptions == HistoricalBoardOrder.allCases)
        #expect(commandState.turnEndStatus.contains("await"))
        #expect(inspectorState.isReady)
        #expect(inspectorState.orderDiceSummary.contains("Pins"))
        #expect(movementState.isReady)
        #expect(movementState.advanceMoveAllowance > 0)
        #expect(movementState.runMoveAllowance >= movementState.advanceMoveAllowance)
        #expect(movementState.terrainClasses.contains(.roadRunBonus))
        #expect(acceptance.isReadyThroughCycle60)
        #expect(acceptance.missingUISourceIdentifiers.isEmpty)
        #expect(acceptance.blockers.isEmpty)
    }

    @Test("Cycles 61-80 expose shooting, vehicle, close-quarters, and Guderian AI contracts")
    func shootingVehicleAssaultAndGuderianAIContractsAreReady() throws {
        let sourceText = try String(contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift", encoding: .utf8)
        let scenario = try #require(GuderianCampaignCatalog.scenario(id: .tucholaForest))
        let session = try #require(NativeBoardSession(scenario: scenario, seed: 80_080))
        _ = GuderianOrderDiceSessionBootstrap.enableOrderDice(in: session)
        let snapshot = session.snapshot()
        let shooting = try #require(GuderianOrderDiceShootingPresenter.state(snapshot: snapshot))
        let vehicle = try #require(GuderianOrderDiceVehiclePresenter.state(snapshot: snapshot))
        let closeQuarters = try #require(GuderianOrderDiceCloseQuartersPresenter.state(snapshot: snapshot))
        let aiDecision = try #require(GuderianOrderDiceGuderianAIActivationPlanner.decision(
            snapshot: snapshot,
            battleID: .fieldCommand(.tucholaForest),
            priorityNames: ScenarioContentCatalog.bundle(for: scenario).aiPlan.targetPriorities(for: .movement)
        ))
        let acceptance = GuderianOrderDiceMigrationCycle80AcceptanceCatalog.report(
            cycle60SourceText: sourceText,
            cycle80SourceText: sourceText
        )

        #expect(GuderianOrderDiceShootingPresenter.acceptanceReadyThroughCycle65)
        #expect(GuderianOrderDiceVehiclePresenter.acceptanceReadyThroughCycle70)
        #expect(GuderianOrderDiceCloseQuartersPresenter.acceptanceReadyThroughCycle75)
        #expect(GuderianOrderDiceGuderianAIActivationPlanner.acceptanceReadyThroughCycle80)
        #expect(shooting.isReady)
        #expect(shooting.fireChoiceSummary.contains("Fire"))
        #expect(shooting.advanceChoiceSummary.contains("Advance"))
        #expect(shooting.hitModifierBreakdown.contains("Base"))
        #expect(vehicle.isReady)
        #expect(vehicle.armourFacingSummary.contains("F/S/R"))
        #expect(vehicle.penetrationModifierSummary.localizedCaseInsensitiveContains("penetration"))
        #expect(closeQuarters.isReady)
        #expect(closeQuarters.runOrderAssaultSummary.contains("Run"))
        #expect(aiDecision.isReady)
        #expect(aiDecision.drawnSide == .guderianAI)
        #expect(HistoricalBoardOrder.allCases.contains(aiDecision.chosenOrder))
        #expect(acceptance.isReadyThroughCycle80)
        #expect(acceptance.missingUISourceIdentifiers.isEmpty)
        #expect(acceptance.blockers.isEmpty)
    }

    @Test("Cycles 81-100 expose opposing AI, standing-order, morale, and reaction contracts")
    func opposingAIStandingOrderMoraleAndReactionContractsAreReady() throws {
        let sourceText = try String(contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift", encoding: .utf8)
        let decisions = GuderianOrderDiceOpposingAIActivationPlanner.allDecisionStates
        let tuchola = try #require(decisions.first { $0.battleID == .fieldCommand(.tucholaForest) })
        let lateCareer = try #require(decisions.first { $0.battleID.kind == .lateCareer })
        let standing = GuderianOrderDiceStandingOrderPlanner.deterministicRecommendations
        let morale = GuderianOrderDicePinsMoraleAIPlanner.deterministicStates
        let reactions = GuderianOrderDiceTargetReactionAIPlanner.deterministicDecisions
        let acceptance = GuderianOrderDiceMigrationCycle100AcceptanceCatalog.report(cycle80SourceText: sourceText)
        let allOpposingDecisionsReady = decisions.allSatisfy(\.isReady)

        #expect(GuderianOrderDiceOpposingAIActivationPlanner.acceptanceReadyThroughCycle85)
        #expect(GuderianOrderDiceStandingOrderPlanner.acceptanceReadyThroughCycle90)
        #expect(GuderianOrderDicePinsMoraleAIPlanner.acceptanceReadyThroughCycle95)
        #expect(GuderianOrderDiceTargetReactionAIPlanner.acceptanceReadyThroughCycle100)
        #expect(decisions.count == 35)
        #expect(allOpposingDecisionsReady)
        #expect(tuchola.armyFamily == .polish)
        #expect(tuchola.orderPrioritySummary.contains("Polish"))
        #expect(lateCareer.armyFamily == .lateWarSovietAllied)
        #expect(Set(standing.map(\.intent)) == Set(GuderianOrderDiceStandingOrderIntent.allCases))
        #expect(morale.contains { $0.rallyPriority && $0.recommendedOrder == .rally })
        #expect(morale.contains { $0.officerModifier > 0 && $0.failedOrderTestPlan.localizedCaseInsensitiveContains("officer") })
        #expect(reactions.contains { $0.recommendedReaction == .down && $0.attackerSide == .guderianAI })
        #expect(reactions.contains { $0.recommendedReaction == .ambushOpportunity && $0.attackerSide == .player })
        #expect(acceptance.isReadyThroughCycle100)
        #expect(acceptance.missingUISourceIdentifiers.isEmpty)
        #expect(acceptance.blockers.isEmpty)
    }

    @Test("Cycles 101-120 expose activation-step autoplay and field-command tuning")
    func activationHarnessAndScenarioTuningAreReady() throws {
        let battleSource = try String(contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift", encoding: .utf8)
        let guderianTestSource = try String(contentsOfFile: "Sources/GuderianTest/GuderianTestApp.swift", encoding: .utf8)
        let harness = GuderianOrderDiceAutoplayHarnessCatalog.report
        let rows = GuderianOrderDiceFieldScenarioTuningCatalog.allRows
        let tuchola = try #require(GuderianOrderDiceFieldScenarioTuningCatalog.row(for: .fieldCommand(.tucholaForest)))
        let sedan = try #require(GuderianOrderDiceFieldScenarioTuningCatalog.row(for: .fieldCommand(.sedan)))
        let moscow = try #require(GuderianOrderDiceFieldScenarioTuningCatalog.row(for: .fieldCommand(.moscowTulaKashira)))
        let acceptance = GuderianOrderDiceMigrationCycle120AcceptanceCatalog.report(
            cycle80And100SourceText: battleSource,
            guderianTestSourceText: guderianTestSource
        )
        let allRowsReady = rows.allSatisfy(\.isReady)

        #expect(GuderianOrderDiceAutoplayHarnessCatalog.acceptanceReadyThroughCycle105)
        #expect(harness.isReadyThroughCycle105)
        #expect(harness.firstBattleActivationSteps == harness.firstBattlePhaseCompatibilitySteps)
        #expect(harness.speedModes == GuderianTestFirstBattleAutoplaySpeed.allCases)
        #expect(GuderianOrderDiceFieldScenarioTuningCatalog.acceptanceReadyThroughCycle110)
        #expect(GuderianOrderDiceFieldScenarioTuningCatalog.acceptanceReadyThroughCycle115)
        #expect(GuderianOrderDiceFieldScenarioTuningCatalog.acceptanceReadyThroughCycle120)
        #expect(rows.count == 19)
        #expect(allRowsReady)
        #expect(tuchola.theater == .poland)
        #expect(tuchola.emphases.contains(.earlyWarArmorInfantry))
        #expect(sedan.emphases.contains(.riverCrossings))
        #expect(sedan.emphases.contains(.airArtilleryPinning))
        #expect(moscow.emphases.contains(.winterMovement))
        #expect(moscow.emphases.contains(.t34KVArmour))
        #expect(acceptance.isReadyThroughCycle120)
        #expect(acceptance.missingSourceIdentifiers.isEmpty)
        #expect(acceptance.blockers.isEmpty)
    }

    @Test("Cycles 121-140 expose late-career tuning and activation-aware scoring")
    func lateCareerTuningAndActivationAwareScoringAreReady() throws {
        let battleSource = try String(contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift", encoding: .utf8)
        let guderianTestSource = try String(contentsOfFile: "Sources/GuderianTest/GuderianTestApp.swift", encoding: .utf8)
        let lateRows = GuderianOrderDiceLateCareerTuningCatalog.allRows
        let scoreRows = GuderianOrderDiceActivationScoringCatalog.allRows
        let setARow = try #require(GuderianOrderDiceLateCareerTuningCatalog.row(for: .lateCareer(LateCareerStaffBattlefieldSetACatalog.battlefieldIDs[0])))
        let setDRow = try #require(GuderianOrderDiceLateCareerTuningCatalog.row(for: .lateCareer(LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs[0])))
        let fieldScore = try #require(GuderianOrderDiceActivationScoringCatalog.row(for: .fieldCommand(.tucholaForest)))
        let lateScore = try #require(GuderianOrderDiceActivationScoringCatalog.row(for: .lateCareer(LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs[0])))
        let acceptance = GuderianOrderDiceMigrationCycle140AcceptanceCatalog.report(
            cycle80And100SourceText: battleSource,
            guderianTestSourceText: guderianTestSource,
            battleSourceText: battleSource
        )

        #expect(GuderianOrderDiceLateCareerTuningCatalog.acceptanceReadyThroughCycle125)
        #expect(lateRows.count == 16)
        #expect(lateRows.allSatisfy { $0.isReady })
        #expect(setARow.emphases.contains(.staffInfluence))
        #expect(setARow.emphases.contains(.armoredForcePressure))
        #expect(setDRow.emphases.contains(.finalWarCompression))
        #expect(setDRow.emphases.contains(.epilogueContext))
        #expect(GuderianOrderDiceActivationScoringCatalog.acceptanceReadyThroughCycle130)
        #expect(GuderianOrderDiceActivationScoringCatalog.acceptanceReadyThroughCycle135)
        #expect(GuderianOrderDiceActivationScoringCatalog.acceptanceReadyThroughCycle140)
        #expect(scoreRows.count == 35)
        #expect(fieldScore.source == .fieldCommand)
        #expect(lateScore.source == .lateCareer)
        #expect(fieldScore.activationAdjustedScore(baseScore: fieldScore.parScore, activationSteps: fieldScore.fastActivationThreshold) >
            fieldScore.activationAdjustedScore(baseScore: fieldScore.parScore, activationSteps: fieldScore.overBudgetActivationThreshold + 1))
        #expect(lateScore.scoringSummary.localizedCaseInsensitiveContains("activation"))
        #expect(acceptance.isReadyThroughCycle140)
        #expect(acceptance.missingSourceIdentifiers.isEmpty)
        #expect(acceptance.blockers.isEmpty)
    }

    @Test("Cycles 141-160 expose save migration, debrief copy, and activation-first tutorial language")
    func saveMigrationDebriefCopyAndTutorialLanguageAreReady() throws {
        let battleSource = try String(contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift", encoding: .utf8)
        let guderianTestSource = try String(contentsOfFile: "Sources/GuderianTest/GuderianTestApp.swift", encoding: .utf8)
        let tutorialSource = try String(contentsOfFile: "Sources/GuderianCore/TutorialOnboarding.swift", encoding: .utf8)
        let saveRows = GuderianOrderDiceSaveStateMigrationCatalog.allRows
        let debriefRows = GuderianOrderDiceDebriefCopyCatalog.allRows
        let tutorialRows = GuderianOrderDiceActivationFirstTutorialCatalog.allRows
        let tucholaSave = try #require(GuderianOrderDiceSaveStateMigrationCatalog.row(for: .fieldCommand(.tucholaForest)))
        let lateDebrief = try #require(GuderianOrderDiceDebriefCopyCatalog.row(for: .lateCareer(LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs[0])))
        let autoStepLanguage = try #require(tutorialRows.first { $0.id == FirstBattleButtonCoachID.autoStep.rawValue })
        let acceptance = GuderianOrderDiceMigrationCycle160AcceptanceCatalog.report(
            cycle80And100SourceText: battleSource,
            guderianTestSourceText: guderianTestSource,
            battleSourceText: battleSource,
            tutorialSourceText: tutorialSource
        )

        #expect(GuderianOrderDiceSaveStateMigrationCatalog.acceptanceReadyThroughCycle145)
        #expect(saveRows.count == 35)
        #expect(saveRows.filter { $0.source == .fieldCommand }.count == 19)
        #expect(saveRows.filter { $0.source == .lateCareer }.count == 16)
        #expect(saveRows.allSatisfy { $0.isReady })
        #expect(Set(saveRows.flatMap(\.orderDiceStateKeys)).count == 105)
        #expect(tucholaSave.completionPersistenceKey == "guderian.campaign.tucholaForest.completion.v1")
        #expect(tucholaSave.orderDiceBagKey.contains("orderDice"))
        #expect(GuderianOrderDiceDebriefCopyCatalog.acceptanceReadyThroughCycle150)
        #expect(debriefRows.count == 35)
        #expect(debriefRows.allSatisfy { $0.isReady })
        #expect(lateDebrief.ethicalFrame.localizedCaseInsensitiveContains("not a direct field command"))
        #expect(lateDebrief.activationSummary.localizedCaseInsensitiveContains("activations"))
        #expect(GuderianOrderDiceActivationFirstTutorialCatalog.acceptanceReadyThroughCycle155)
        #expect(tutorialRows.count == 9)
        #expect(tutorialRows.allSatisfy { $0.isReady })
        #expect(autoStepLanguage.body.localizedCaseInsensitiveContains("order-dice activation"))
        #expect(acceptance.isReadyThroughCycle160)
        #expect(acceptance.missingSourceIdentifiers.isEmpty)
        #expect(acceptance.blockers.isEmpty)
    }

    @Test("Cycles 161-180 expose turn-end persistence, replay signatures, balance audit, and phase retirement")
    func turnEndHarnessBalanceAndPhaseRetirementAreReady() throws {
        let battleSource = try String(contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift", encoding: .utf8)
        let guderianTestSource = try String(contentsOfFile: "Sources/GuderianTest/GuderianTestApp.swift", encoding: .utf8)
        let tutorialSource = try String(contentsOfFile: "Sources/GuderianCore/TutorialOnboarding.swift", encoding: .utf8)
        let readme = try String(contentsOfFile: "README.md", encoding: .utf8)
        let plan = try String(contentsOfFile: "PLAN.md", encoding: .utf8)
        let turnEndRows = GuderianOrderDiceTurnEndPersistenceCatalog.allRows
        let harnessRows = GuderianOrderDiceFullBattleHarnessCatalog.allRows
        let balanceRows = GuderianOrderDiceBalanceAuditCatalog.allRows
        let tucholaTurnEnd = try #require(GuderianOrderDiceTurnEndPersistenceCatalog.row(for: .fieldCommand(.tucholaForest)))
        let tucholaHarness = try #require(GuderianOrderDiceFullBattleHarnessCatalog.row(for: .fieldCommand(.tucholaForest)))
        let lateBalance = try #require(GuderianOrderDiceBalanceAuditCatalog.row(for: .lateCareer(LateCareerStaffBattlefieldSetDCatalog.battlefieldIDs[0])))
        let phaseReport = GuderianOrderDicePhaseSurfaceRetirementCatalog.report(
            battleSourceText: battleSource,
            tutorialSourceText: tutorialSource,
            readmeText: readme,
            planText: plan
        )
        let acceptance = GuderianOrderDiceMigrationCycle180AcceptanceCatalog.report(
            cycle80And100SourceText: battleSource,
            guderianTestSourceText: guderianTestSource,
            battleSourceText: battleSource,
            tutorialSourceText: tutorialSource,
            readmeText: readme,
            planText: plan
        )

        #expect(GuderianOrderDiceTurnEndPersistenceCatalog.acceptanceReadyThroughCycle165)
        #expect(turnEndRows.count == 35)
        #expect(turnEndRows.allSatisfy { $0.isReady })
        #expect(tucholaTurnEnd.turnEndWriteSet.count == 4)
        #expect(tucholaTurnEnd.turnEndWriteSet.contains(tucholaTurnEnd.retainedOrdersKey))
        #expect(GuderianOrderDiceFullBattleHarnessCatalog.acceptanceReadyThroughCycle170)
        #expect(harnessRows.count == 35)
        #expect(harnessRows.allSatisfy { $0.isReady })
        #expect(Set(harnessRows.map(\.replaySignature)).count == 35)
        #expect(tucholaHarness.replaySignature.localizedCaseInsensitiveContains("tucholaForest"))
        #expect(GuderianOrderDiceBalanceAuditCatalog.acceptanceReadyThroughCycle175)
        #expect(balanceRows.count == 35)
        #expect(balanceRows.allSatisfy { $0.isReady })
        #expect(lateBalance.pacingSummary.localizedCaseInsensitiveContains("command caveat"))
        #expect(phaseReport.isReady)
        #expect(phaseReport.retiredVisibleLabelsStillPresent.isEmpty)
        #expect(phaseReport.tutorialPhaseFirstCopyStillPresent.isEmpty)
        #expect(phaseReport.compatibilityIdentifiersRetained.contains("next-phase-button"))
        #expect(acceptance.isReadyThroughCycle180)
        #expect(acceptance.blockers.isEmpty)
        #expect(acceptance.replaySignatureCount == 35)
    }

    @Test("Cycles 181-200 close with Monty handoff, build matrix, cleanup, and final acceptance")
    func finalAcceptanceAndMontyHandoffAreReady() throws {
        let battleSource = try String(contentsOfFile: "Sources/GuderianApp/DZWPlayableBattleView.swift", encoding: .utf8)
        let autoplaySource = try String(contentsOfFile: "Sources/GuderianCore/GuderianTestFirstBattleAutoplay.swift", encoding: .utf8)
        let tutorialSource = try String(contentsOfFile: "Sources/GuderianCore/TutorialOnboarding.swift", encoding: .utf8)
        let readme = try String(contentsOfFile: "README.md", encoding: .utf8)
        let plan = try String(contentsOfFile: "PLAN.md", encoding: .utf8)
        let montyDocs = try String(contentsOfFile: "docs/montyBackwardcompatibility.md", encoding: .utf8)
        let finalDocs = try String(contentsOfFile: "docs/guderian_order_dice_cycle_181_200.md", encoding: .utf8)
        let phaseReport = GuderianOrderDicePhaseSurfaceRetirementCatalog.report(
            battleSourceText: battleSource,
            tutorialSourceText: tutorialSource,
            readmeText: readme,
            planText: plan
        )
        let cycle180EvidenceReady = GuderianOrderDiceTurnEndPersistenceCatalog.acceptanceReadyThroughCycle165 &&
            GuderianOrderDiceFullBattleHarnessCatalog.acceptanceReadyThroughCycle170 &&
            GuderianOrderDiceBalanceAuditCatalog.acceptanceReadyThroughCycle175 &&
            phaseReport.isReady
        let cleanup = GuderianOrderDiceMigrationCleanupCatalog.report(
            battleSourceText: battleSource,
            testSourceText: autoplaySource
        )
        let acceptance = GuderianOrderDiceMigrationCycle200AcceptanceCatalog.report(
            battleSourceText: battleSource,
            testSourceText: autoplaySource,
            readmeText: readme,
            planText: plan,
            montyDocsText: montyDocs,
            finalDocsText: finalDocs,
            cycle180EvidenceReady: cycle180EvidenceReady
        )

        #expect(GuderianOrderDiceMontyAPIHandoffCatalog.acceptanceReadyThroughCycle185)
        #expect(GuderianOrderDiceMontyAPIHandoffCatalog.allRows.count == GuderianOrderDiceMontyAPIHandoffSurface.allCases.count)
        #expect(GuderianOrderDiceMontyAPIHandoffCatalog.allRows.allSatisfy { $0.isReady })
        #expect(GuderianOrderDiceMontyAPIHandoffCatalog.summary.localizedCaseInsensitiveContains("Monty"))
        #expect(GuderianOrderDiceBuildMatrixCatalog.acceptanceReadyThroughCycle190)
        #expect(GuderianOrderDiceBuildMatrixCatalog.allRows.contains { $0.command == "swift build" && $0.status == .passed })
        #expect(GuderianOrderDiceBuildMatrixCatalog.allRows.contains { $0.command.contains("MontyBackwardCompatibilityTests") })
        #expect(cleanup.isReady)
        #expect(cleanup.retiredVisibleLabelsStillPresent.isEmpty)
        #expect(cleanup.compatibilitySymbolsRetained.contains("next-phase-button"))
        #expect(battleSource.contains("monty-order-dice-api-handoff"))
        #expect(battleSource.contains("order-dice-build-matrix"))
        #expect(battleSource.contains("legacy-phase-compatibility-quarantine"))
        #expect(battleSource.contains("order-dice-final-acceptance"))
        #expect(acceptance.isReadyThroughCycle200)
        #expect(acceptance.zeroRemainingCycles)
        #expect(acceptance.blockers.isEmpty)
    }
}
