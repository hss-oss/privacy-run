import Foundation

public struct ResolvedApplication: Equatable, Sendable {
    public let name: String
    public let bundleIdentifier: String
    public let version: String?
    public let bundleURL: URL
    public let executableURL: URL

    public init(
        name: String,
        bundleIdentifier: String,
        version: String?,
        bundleURL: URL,
        executableURL: URL
    ) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.bundleURL = bundleURL
        self.executableURL = executableURL
    }
}

public enum AppBundleResolutionError: LocalizedError {
    case notApplicationBundle
    case unreadableBundle
    case missingBundleIdentifier
    case missingExecutable

    public var errorDescription: String? {
        switch self {
        case .notApplicationBundle:
            "所选路径不是 .app"
        case .unreadableBundle:
            "无法读取 App Bundle"
        case .missingBundleIdentifier:
            "App 缺少 Bundle Identifier"
        case .missingExecutable:
            "App 缺少可执行文件"
        }
    }
}

public struct AppBundleResolver: Sendable {
    public init() {}

    public func resolve(_ url: URL) throws -> ResolvedApplication {
        guard url.pathExtension.lowercased() == "app" else {
            throw AppBundleResolutionError.notApplicationBundle
        }
        guard let bundle = Bundle(url: url) else {
            throw AppBundleResolutionError.unreadableBundle
        }
        guard let bundleIdentifier = bundle.bundleIdentifier, !bundleIdentifier.isEmpty else {
            throw AppBundleResolutionError.missingBundleIdentifier
        }
        guard
            let executableURL = bundle.executableURL,
            FileManager.default.isExecutableFile(atPath: executableURL.path)
        else {
            throw AppBundleResolutionError.missingExecutable
        }

        let name =
            bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent
        let version =
            bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        return ResolvedApplication(
            name: name,
            bundleIdentifier: bundleIdentifier,
            version: version,
            bundleURL: url,
            executableURL: executableURL
        )
    }
}
