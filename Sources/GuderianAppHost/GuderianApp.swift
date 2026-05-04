import SwiftUI
#if SWIFT_PACKAGE
import GuderianAppUI
#endif

@main
struct GuderianApp: App {
    var body: some Scene {
        WindowGroup("guderian") {
            GuderianCampaignView()
                .frame(minWidth: 1120, minHeight: 760)
        }
        .windowResizability(.contentMinSize)
    }
}
