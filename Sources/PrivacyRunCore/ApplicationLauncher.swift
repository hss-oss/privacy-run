import Foundation

public struct PreparedLaunch: Sendable {
    public let environment: [String: String]
    public let applicationArguments: [String]
    public let probeArguments: [String]
}

public struct ApplicationLauncher: Sendable {
    public init() {}

    public func prepare(
        application: ResolvedApplication,
        configuration: EnvironmentConfiguration,
        temporaryRoot: URL
    ) throws -> PreparedLaunch {
        let temporaryDirectory = temporaryRoot
            .appending(path: application.bundleIdentifier, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )

        let environment = try EnvironmentBuilder().build(
            configuration: configuration,
            temporaryDirectory: temporaryDirectory
        )
        let argumentBuilder = LaunchArgumentsBuilder()
        let applicationArguments = argumentBuilder.build(
            configuration: configuration,
            style: isElectron(application) ? .electron : .apple
        )
        let probeArguments = argumentBuilder.build(configuration: configuration)

        return PreparedLaunch(
            environment: environment,
            applicationArguments: applicationArguments,
            probeArguments: probeArguments
        )
    }

    public func launch(
        application: ResolvedApplication,
        prepared: PreparedLaunch
    ) throws -> Int32 {
        let process = Process()
        process.executableURL = application.executableURL
        process.environment = prepared.environment
        process.arguments = prepared.applicationArguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        try process.run()
        return process.processIdentifier
    }

    private func isElectron(_ application: ResolvedApplication) -> Bool {
        if Bundle(url: application.bundleURL)?
            .object(forInfoDictionaryKey: "ElectronAsarIntegrity") != nil
        {
            return true
        }
        let frameworkURL = application.bundleURL
            .appending(path: "Contents/Frameworks/Electron Framework.framework")
        return FileManager.default.fileExists(atPath: frameworkURL.path)
    }
}
