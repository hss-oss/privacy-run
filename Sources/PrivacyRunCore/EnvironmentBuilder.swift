import Foundation

public struct EnvironmentBuilder: Sendable {
    private static let inheritedKeys: Set<String> = [
        "HOME",
        "LOGNAME",
        "PATH",
        "SHELL",
        "USER",
        "__CF_USER_TEXT_ENCODING"
    ]

    public init() {}

    public func build(
        configuration: EnvironmentConfiguration,
        base: [String: String] = ProcessInfo.processInfo.environment,
        temporaryDirectory: URL
    ) throws -> [String: String] {
        var environment = base.filter { Self.inheritedKeys.contains($0.key) }

        switch configuration.timeZone {
        case .inherit:
            environment.removeValue(forKey: "TZ")
        case .fixed(let identifier):
            guard TimeZone(identifier: identifier) != nil else {
                throw EnvironmentConfigurationError.invalidTimeZone(identifier)
            }
            environment["TZ"] = identifier
        }

        if let localeIdentifier = normalized(configuration.localeIdentifier) {
            guard Locale.availableIdentifiers.contains(localeIdentifier) else {
                throw EnvironmentConfigurationError.invalidLocale(localeIdentifier)
            }
            let posixLocale = localeIdentifier.replacingOccurrences(of: "-", with: "_")
            environment["LANG"] = "\(posixLocale).UTF-8"
            environment["LC_ALL"] = "\(posixLocale).UTF-8"
        }

        environment["TMPDIR"] = temporaryDirectory.path(percentEncoded: false)
        return environment
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
