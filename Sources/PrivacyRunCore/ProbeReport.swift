import Foundation

public struct ProbeReport: Codable, Equatable, Sendable {
    public let timeZoneIdentifier: String
    public let localeIdentifier: String
    public let preferredLanguages: [String]

    public init(
        timeZoneIdentifier: String,
        localeIdentifier: String,
        preferredLanguages: [String]
    ) {
        self.timeZoneIdentifier = timeZoneIdentifier
        self.localeIdentifier = localeIdentifier
        self.preferredLanguages = preferredLanguages
    }
}
