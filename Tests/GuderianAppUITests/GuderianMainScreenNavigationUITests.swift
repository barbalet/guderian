import XCTest

final class GuderianMainScreenNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMainScreenBattleSelectionOpensPlayableBattle() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--guderian-ui-test-disable-tutorials"]
        app.launch()

        openTucholaBattle(from: app)
    }

    @MainActor
    func testMainScreenSideSelectionStillOpensPlayableBattle() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--guderian-ui-test-disable-tutorials"]
        app.launch()

        let opposingForce = app.radioButtons["guderian-battle-selection-side-option-tucholaForest-opposing-force"].firstMatch
        XCTAssertTrue(opposingForce.waitForExistence(timeout: 10), app.debugDescription)
        opposingForce.click()

        openTucholaBattle(from: app)
    }

    @MainActor
    func testBattleCanBeReopenedAsOppositeSideAfterReturningToCampaign() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--guderian-ui-test-disable-tutorials"]
        app.launch()

        let guderianCommand = app.radioButtons["guderian-battle-selection-side-option-tucholaForest-guderian-command"].firstMatch
        XCTAssertTrue(guderianCommand.waitForExistence(timeout: 10), app.debugDescription)
        guderianCommand.click()

        openTucholaBattle(from: app)
        returnToCampaign(from: app)

        let opposingForce = app.radioButtons["guderian-battle-selection-side-option-tucholaForest-opposing-force"].firstMatch
        XCTAssertTrue(opposingForce.waitForExistence(timeout: 10), app.debugDescription)
        opposingForce.click()

        openTucholaBattle(from: app)
    }

    @MainActor
    func testFirstBattleHoverCoachAssistsMovementAndTargeting() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--guderian-ui-test-disable-tutorials",
            "--guderian-ui-test-disable-first-battle-hints",
            "--guderian-ui-test-enable-button-coach",
            "--guderian-ui-test-reset-button-coach",
        ]
        app.launchEnvironment["GUDERIAN_UI_TESTING"] = "1"
        app.launch()

        openTucholaBattle(from: app)

        let selectedUnitSummary = app.descendants(matching: .any)["battle-selected-unit-summary"].firstMatch
        XCTAssertTrue(selectedUnitSummary.waitForExistence(timeout: 10), app.debugDescription)
        selectedUnitSummary.hover()

        let movementCoach = app.descendants(matching: .any)["first-battle-button-coach-board-unit-movement"].firstMatch
        XCTAssertTrue(movementCoach.waitForExistence(timeout: 5), app.debugDescription)
        let movementGhost = app.descendants(matching: .any)["first-battle-movement-ghost"].firstMatch
        XCTAssertTrue(movementGhost.waitForExistence(timeout: 5), app.debugDescription)

        let enemyUnit = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "battle-board-enemy-unit-"))
            .firstMatch
        XCTAssertTrue(waitUntilHittable(enemyUnit, timeout: 10), app.debugDescription)
        enemyUnit.hover()

        let targetingCoach = app.descendants(matching: .any)["first-battle-button-coach-board-enemy-targeting"].firstMatch
        XCTAssertTrue(targetingCoach.waitForExistence(timeout: 5), app.debugDescription)
        let targetingGhost = app.descendants(matching: .any)["first-battle-targeting-ghost"].firstMatch
        XCTAssertTrue(targetingGhost.waitForExistence(timeout: 5), app.debugDescription)
    }

    @MainActor
    private func openTucholaBattle(from app: XCUIApplication) {
        let campaignScreen = app.descendants(matching: .any)["campaign-screen"].firstMatch
        XCTAssertTrue(campaignScreen.waitForExistence(timeout: 10), app.debugDescription)

        let tucholaLaunch = app.buttons["unified-battle-link-tucholaForest"].firstMatch
        XCTAssertTrue(tucholaLaunch.waitForExistence(timeout: 10), app.debugDescription)
        tucholaLaunch.click()

        let battleScreen = app.descendants(matching: .any)["battle-screen"].firstMatch
        XCTAssertTrue(battleScreen.waitForExistence(timeout: 15), app.debugDescription)

        let battleBoard = app.descendants(matching: .any)["battle-board"].firstMatch
        XCTAssertTrue(battleBoard.waitForExistence(timeout: 10), app.debugDescription)
    }

    @MainActor
    private func returnToCampaign(from app: XCUIApplication) {
        let backToCampaign = app.buttons["battle-back-to-campaign-button"].firstMatch
        XCTAssertTrue(backToCampaign.waitForExistence(timeout: 10), app.debugDescription)
        backToCampaign.click()

        let tucholaLaunch = app.buttons["unified-battle-link-tucholaForest"].firstMatch
        XCTAssertTrue(waitUntilHittable(tucholaLaunch, timeout: 10), app.debugDescription)
    }

    @MainActor
    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists && element.isHittable {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return element.exists && element.isHittable
    }
}
