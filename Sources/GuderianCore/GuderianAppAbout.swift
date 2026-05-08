import Foundation

public enum GuderianAppAboutCatalog {
    public static let appName = "Guderian"
    public static let releaseVersion = "1.02"
    public static let buildLabel = "Native macOS wargame"
    public static let contactLine = "Contact: barbalet at gmail dot com"

    public static let developmentParagraphs = [
        "Guderian is a macOS World War II wargame built around the battles connected to Heinz Guderian's field commands and later staff context. The default player lens is the opposing force: delaying, escaping, defending, counterattacking, or holding evacuation corridors against German pressure.",
        "Development combines SwiftUI presentation, Metal-ready rendering surfaces, and the local dzw rules engine. The project keeps Guderian-specific scenario data, maps, tutorials, save migration, and opponent AI in this checkout while preserving a clear boundary around reusable dzw engine code.",
        "The campaign now supports a unified 35-battle playable chronology, side selection for the field-command battles, first-run historical onboarding, contextual first-battle guidance, and phase-aware automated opposition for both the default opposing-force lens and Guderian-command study mode.",
        "The historical framing is deliberately sober. Guderian was a senior Nazi German commander; selecting his command is presented as command-study comparison rather than admiration or role-play.",
    ]

    public static let credits = [
        "Engine foundation: derZweiteWeltkrieg / dzw",
        "Interface: SwiftUI macOS app shell",
        "Research shelf: public historical sources linked from the campaign chronology",
        "Icon source: public-domain Wikimedia Commons portrait documented in Resources/AppIconSource",
    ]

    public static func displayVersion(
        bundleInfo: [String: Any] = Bundle.main.infoDictionary ?? [:]
    ) -> String {
        guard let bundleVersion = bundleInfo["CFBundleShortVersionString"] as? String else {
            return releaseVersion
        }

        let trimmed = bundleVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || trimmed == "1.0" || trimmed.contains("$(") ? releaseVersion : trimmed
    }
}
