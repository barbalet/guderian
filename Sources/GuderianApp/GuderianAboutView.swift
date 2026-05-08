import AppKit
import DerZweiteWeltkriegHistorical
import GuderianCore
import SwiftUI

public struct GuderianAboutView: View {
    public init() {}

    public var body: some View {
        HistoricalAppAboutView(
            content: GuderianAppAboutCatalog.content,
            icon: Image(nsImage: NSApp.applicationIconImage)
        )
    }
}
