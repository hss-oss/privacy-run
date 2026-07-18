import Foundation

public struct AppRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var bundleIdentifier: String
    public var version: String?
    public var bundlePath: String
    public var configuration: EnvironmentConfiguration
    public var latestReport: RunReport?

    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        version: String?,
        bundlePath: String,
        configuration: EnvironmentConfiguration = EnvironmentConfiguration(),
        latestReport: RunReport? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.bundlePath = bundlePath
        self.configuration = configuration
        self.latestReport = latestReport
    }
}
