import AppKit
import Foundation
import PrivacyRunCore

let report = ProbeReport(
    timeZoneIdentifier: TimeZone.current.identifier,
    localeIdentifier: Locale.current.identifier,
    preferredLanguages: Locale.preferredLanguages,
    systemFontName: NSFont.systemFont(ofSize: NSFont.systemFontSize).fontName
)

do {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(report)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data([0x0A]))
} catch {
    FileHandle.standardError.write(Data("Probe 编码失败：\(error)\n".utf8))
    Foundation.exit(EXIT_FAILURE)
}
