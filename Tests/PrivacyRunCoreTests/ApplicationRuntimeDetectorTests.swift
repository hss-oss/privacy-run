import Foundation
import Testing
@testable import PrivacyRunCore

struct ApplicationRuntimeDetectorTests {
    @Test
    func detectsCustomizedElectronFromBundleMetadata() throws {
        let application = try makeApplication(
            info: ["ElectronAsarIntegrity": ["resources/default_app.asar": "hash"]]
        )
        defer { try? FileManager.default.removeItem(at: application.bundleURL) }

        #expect(ApplicationRuntimeDetector().detect(application) == .electron)
    }

    @Test
    func treatsUnsupportedFrameworksConservatively() throws {
        let application = try makeApplication(
            frameworks: ["QtWebEngineCore.framework"]
        )
        defer { try? FileManager.default.removeItem(at: application.bundleURL) }

        #expect(ApplicationRuntimeDetector().detect(application) == .unsupported)
    }

    @Test
    func defaultsOrdinaryMacApplicationToNative() throws {
        let application = try makeApplication()
        defer { try? FileManager.default.removeItem(at: application.bundleURL) }

        #expect(ApplicationRuntimeDetector().detect(application) == .native)
    }

    private func makeApplication(
        info: [String: Any] = [:],
        frameworks: [String] = []
    ) throws -> ResolvedApplication {
        let bundleURL = FileManager.default.temporaryDirectory
            .appending(path: "RuntimeDetector-\(UUID().uuidString).app")
        let contentsURL = bundleURL.appending(path: "Contents")
        let frameworksURL = contentsURL.appending(path: "Frameworks")
        try FileManager.default.createDirectory(
            at: frameworksURL,
            withIntermediateDirectories: true
        )

        let plistData = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try plistData.write(to: contentsURL.appending(path: "Info.plist"))
        for framework in frameworks {
            try FileManager.default.createDirectory(
                at: frameworksURL.appending(path: framework),
                withIntermediateDirectories: true
            )
        }

        return ResolvedApplication(
            name: "Test App",
            bundleIdentifier: "test.runtime.\(UUID().uuidString)",
            version: nil,
            bundleURL: bundleURL,
            executableURL: URL(fileURLWithPath: "/bin/sh")
        )
    }
}
