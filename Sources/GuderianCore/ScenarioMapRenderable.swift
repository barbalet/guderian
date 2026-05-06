import DerZweiteWeltkriegGuderian
import Foundation

public protocol ScenarioMapRenderable {
    var title: String { get }
    var width: Double { get }
    var height: Double { get }
    var elements: [ScenarioMapElement] { get }
    var deploymentZones: [ScenarioDeploymentZone] { get }
}

extension ScenarioMapLayout: ScenarioMapRenderable {}
extension LateCareerStaffBattlefieldMap: ScenarioMapRenderable {}
