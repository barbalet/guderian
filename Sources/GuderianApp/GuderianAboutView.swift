import AppKit
import GuderianCore
import SwiftUI

public struct GuderianAboutView: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(GuderianAppAboutCatalog.appName)
                        .font(.largeTitle.weight(.semibold))
                    Text("Version \(GuderianAppAboutCatalog.displayVersion())")
                        .font(.headline.monospacedDigit())
                    Text(GuderianAppAboutCatalog.buildLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(GuderianAppAboutCatalog.developmentParagraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.callout)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                ForEach(GuderianAppAboutCatalog.credits, id: \.self) { credit in
                    Label(credit, systemImage: "checkmark.circle")
                        .labelStyle(.titleAndIcon)
                }
                Text(GuderianAppAboutCatalog.contactLine)
                    .padding(.top, 4)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 620)
    }
}
