import Foundation

public enum TimeZoneMode: Codable, Equatable, Sendable {
    case inherit
    case fixed(identifier: String)
}

public struct EnvironmentConfiguration: Codable, Equatable, Sendable {
    public var timeZone: TimeZoneMode
    public var languageIdentifier: String?
    public var localeIdentifier: String?

    public init(
        timeZone: TimeZoneMode = .inherit,
        languageIdentifier: String? = nil,
        localeIdentifier: String? = nil
    ) {
        self.timeZone = timeZone
        self.languageIdentifier = languageIdentifier
        self.localeIdentifier = localeIdentifier
    }
}

public enum EnvironmentConfigurationError: LocalizedError, Equatable {
    case invalidTimeZone(String)
    case invalidLocale(String)

    public var errorDescription: String? {
        switch self {
        case .invalidTimeZone(let identifier):
            "无法识别时区：\(identifier)"
        case .invalidLocale(let identifier):
            "无法识别地区格式：\(identifier)"
        }
    }
}
