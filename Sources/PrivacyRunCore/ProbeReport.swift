import Foundation

public struct ProbeReport: Codable, Equatable, Sendable {
    public let timeZoneIdentifier: String
    public let localeIdentifier: String
    public let preferredLanguages: [String]
    public let systemFontName: String

    public init(
        timeZoneIdentifier: String,
        localeIdentifier: String,
        preferredLanguages: [String],
        systemFontName: String
    ) {
        self.timeZoneIdentifier = timeZoneIdentifier
        self.localeIdentifier = localeIdentifier
        self.preferredLanguages = preferredLanguages
        self.systemFontName = systemFontName
    }
}
