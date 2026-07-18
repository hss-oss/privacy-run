import Foundation

public enum ApplicationRuntime: Equatable, Sendable {
    case native
    case electron
    case unsupported
}

public struct ApplicationRuntimeDetector: Sendable {
    public init() {}

    public func detect(_ application: ResolvedApplication) -> ApplicationRuntime {
        let contentsURL = application.bundleURL.appending(path: "Contents")
        let frameworksURL = contentsURL.appending(path: "Frameworks")
        let info = NSDictionary(contentsOf: contentsURL.appending(path: "Info.plist"))

        if info?["ElectronAsarIntegrity"] != nil
            || exists("Electron Framework.framework", in: frameworksURL)
        {
            return .electron
        }

        let unsupportedFrameworks = [
            "Chromium Embedded Framework.framework",
            "QtCore.framework",
            "QtWebEngineCore.framework"
        ]
        if info?["JVMMainClassName"] != nil
            || FileManager.default.fileExists(
                atPath: contentsURL.appending(path: "Java").path
            )
            || unsupportedFrameworks.contains(where: { exists($0, in: frameworksURL) })
        {
            return .unsupported
        }

        return .native
    }

    private func exists(_ name: String, in directory: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: directory.appending(path: name).path
        )
    }
}
