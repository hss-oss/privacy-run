import Foundation

public enum CheckResult: String, Codable, Equatable, Sendable {
    case passed
    case information
    case warning
    case unavailable
}

public struct ReportCheck: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let expected: String
    public let actual: String
    public let result: CheckResult
    public let resultLabel: String

    public init(
        id: UUID = UUID(),
        name: String,
        expected: String,
        actual: String,
        result: CheckResult,
        resultLabel: String
    ) {
        self.id = id
        self.name = name
        self.expected = expected
        self.actual = actual
        self.result = result
        self.resultLabel = resultLabel
    }
}

public struct RunReport: Codable, Equatable, Sendable {
    public let createdAt: Date
    public let processIdentifier: Int32?
    public let checks: [ReportCheck]
    public let launchError: String?

    public init(
        createdAt: Date = Date(),
        processIdentifier: Int32?,
        checks: [ReportCheck],
        launchError: String? = nil
    ) {
        self.createdAt = createdAt
        self.processIdentifier = processIdentifier
        self.checks = checks
        self.launchError = launchError
    }
}
