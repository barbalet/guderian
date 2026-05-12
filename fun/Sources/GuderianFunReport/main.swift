import Foundation
import GuderianFun

let args = Set(CommandLine.arguments.dropFirst())
let shouldCompare = args.contains("--compare")
let shouldRunScenarios = shouldCompare || args.contains("--run-scenarios")
let shouldPrintSideData = args.contains("--side-data")

do {
    if shouldPrintSideData {
        let report = try FunBattleSideReportCatalog.generate(runUnifiedHarness: shouldRunScenarios)
        print(report.markdownAppendix())
    } else if shouldCompare {
        let staticReport = try FunOptimizationReport.generate(runUnifiedHarness: false)
        let liveReport = try FunOptimizationReport.generate(runUnifiedHarness: true)
        let comparison = FunOptimizationReport.compare(baseline: staticReport, candidate: liveReport)

        print(liveReport.markdownSummary())
        print("")
        print("## Static vs Live")
        print("- Static average: \(FunScoreFormatter.percent(comparison.baselineAverage))")
        print("- Live average: \(FunScoreFormatter.percent(comparison.candidateAverage))")
        print("- Delta: \(FunScoreFormatter.percent(comparison.delta))")
        print("- Increased: \(comparison.increased ? "yes" : "no")")
    } else {
        let report = try FunOptimizationReport.generate(runUnifiedHarness: shouldRunScenarios)
        print(report.markdownSummary())
    }
} catch {
    FileHandle.standardError.write(Data("GuderianFunReport failed: \(error)\n".utf8))
    exit(1)
}
