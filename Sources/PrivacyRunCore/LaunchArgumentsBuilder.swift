import Foundation

public struct LaunchArgumentsBuilder: Sendable {
    public init() {}

    public func build(
        configuration: EnvironmentConfiguration,
        base: [String] = []
    ) -> [String] {
        var arguments = base

        if let localeIdentifier = normalized(configuration.localeIdentifier) {
            arguments.append(contentsOf: ["-AppleLocale", localeIdentifier])
        }

        if let languageIdentifier = normalized(configuration.languageIdentifier) {
            arguments.append(
                contentsOf: ["-AppleLanguages", "(\(languageIdentifier))"]
            )
        }

        return arguments
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
