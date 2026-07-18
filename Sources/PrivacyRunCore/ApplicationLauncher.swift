import Foundation

public struct PreparedLaunch: Sendable {
    public let environment: [String: String]
    public let arguments: [String]
}

public struct ApplicationLauncher: Sendable {
    public init() {}

    public func prepare(
        bundleIdentifier: String,
        configuration: EnvironmentConfiguration,
        temporaryRoot: URL
    ) throws -> PreparedLaunch {
        let temporaryDirectory = temporaryRoot
            .appending(path: bundleIdentifier, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        let environment = try EnvironmentBuilder().build(
            configuration: configuration,
            temporaryDirectory: temporaryDirectory
        )
        let arguments = LaunchArgumentsBuilder().build(configuration: configuration)

        return PreparedLaunch(
            environment: environment,
            arguments: arguments
        )
    }

    public func launch(
        application: ResolvedApplication,
        prepared: PreparedLaunch
    ) throws -> Int32 {
        let process = Process()
        process.executableURL = application.executableURL
        process.environment = prepared.environment
        process.arguments = prepared.arguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        return process.processIdentifier
    }
}
