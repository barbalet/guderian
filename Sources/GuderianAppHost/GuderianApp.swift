import SwiftUI
#if SWIFT_PACKAGE
import GuderianAppUI
#endif

@main
struct GuderianApp: App {
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("guderian") {
            GuderianCampaignView()
                .frame(minWidth: 1120, minHeight: 760)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Guderian") {
                    openWindow(id: "guderian-about")
                }
            }
        }

        Window("About Guderian", id: "guderian-about") {
            GuderianAboutView()
        }
        .defaultSize(width: 620, height: 560)
        .windowResizability(.contentSize)
    }
}
