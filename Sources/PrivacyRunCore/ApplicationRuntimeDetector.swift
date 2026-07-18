import Foundation

public enum ApplicationRuntime: Equatable, Sendable {
    case native
    case electron
    case unsupported
    case unknown
}

public struct ApplicationRuntimeDetector: Sendable {
    public init() {}

    public func detect(
        _ application: ResolvedApplication,
        linkedLibraries: [String]? = nil
    ) -> ApplicationRuntime {
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

        let libraries = linkedLibraries ?? readLinkedLibraries(
            from: application.executableURL
        )
        if libraries.contains(where: {
            $0.contains("/AppKit.framework/")
                || $0.contains("/Cocoa.framework/")
                || $0.contains("/SwiftUI.framework/")
        }) {
            return .native
        }

        return .unknown
    }

    private func exists(_ name: String, in directory: URL) -> Bool {
        FileManager.default.fileExists(
            atPath: directory.appending(path: name).path
        )
    }

    private func readLinkedLibraries(from executableURL: URL) -> [String] {
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/otool") else {
            return []
        }

        let output = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/otool")
        process.arguments = ["-L", executableURL.path]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }
        guard process.terminationStatus == 0 else {
            return []
        }

        let data = output.fileHandleForReading.readDataToEndOfFile()
        let value = String(data: data, encoding: .utf8) ?? ""
        return value.split(separator: "\n").dropFirst().map(String.init)
    }
}
