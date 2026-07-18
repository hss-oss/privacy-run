import AppKit
import Foundation

public struct PreparedLaunch: Sendable {
    public let environment: [String: String]
    public let applicationArguments: [String]
    public let probeArguments: [String]
}

public enum ApplicationLaunchError: LocalizedError {
    case alreadyRunning(String)
    case unsupportedLanguageOverride
    case exitedEarly(Int32, String)

    public var errorDescription: String? {
        switch self {
        case .alreadyRunning(let name):
            "请先彻底退出 \(name)，再通过 PrivacyRun 启动。"
        case .unsupportedLanguageOverride:
            "该 App 的 Runtime 暂不支持安全的语言覆盖。"
        case .exitedEarly(let status, let message):
            message.isEmpty
                ? "App 启动后立即退出（状态码 \(status)）。"
                : "App 启动后立即退出（状态码 \(status)）：\(message)"
        }
    }
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
        let runtime = ApplicationRuntimeDetector().detect(application)
        if runtime == .unsupported, configuration.languageIdentifier != nil {
            throw ApplicationLaunchError.unsupportedLanguageOverride
        }
        let argumentBuilder = LaunchArgumentsBuilder()
        let applicationArguments = argumentBuilder.build(
            configuration: configuration,
            style: runtime == .electron ? .electron : .apple
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
        guard NSRunningApplication.runningApplications(
            withBundleIdentifier: application.bundleIdentifier
        ).isEmpty else {
            throw ApplicationLaunchError.alreadyRunning(application.name)
        }

        let errorLogURL = URL(
            fileURLWithPath: prepared.environment["TMPDIR"] ?? NSTemporaryDirectory()
        ).appending(path: "launch-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: errorLogURL.path, contents: nil)
        let errorLog = try FileHandle(forWritingTo: errorLogURL)
        defer {
            try? errorLog.close()
            try? FileManager.default.removeItem(at: errorLogURL)
        }

        let process = Process()
        process.executableURL = application.executableURL
        process.environment = prepared.environment
        process.arguments = prepared.applicationArguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = errorLog

        try process.run()
        Thread.sleep(forTimeInterval: 0.75)
        guard process.isRunning else {
            try? errorLog.synchronize()
            let data = (try? Data(contentsOf: errorLogURL)) ?? Data()
            let message = String(data: data.prefix(4_096), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw ApplicationLaunchError.exitedEarly(
                process.terminationStatus,
                message
            )
        }
        return process.processIdentifier
    }
}
