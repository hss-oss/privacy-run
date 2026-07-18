import Foundation
import Testing
@testable import PrivacyRunCore

struct ApplicationLauncherTests {
    @Test
    func reportsProcessThatExitsDuringStartup() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appending(path: "LauncherTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let application = ResolvedApplication(
            name: "Failing App",
            bundleIdentifier: "test.launcher.\(UUID().uuidString)",
            version: nil,
            bundleURL: temporaryDirectory.appending(path: "Failing.app"),
            executableURL: URL(fileURLWithPath: "/bin/sh")
        )
        let prepared = PreparedLaunch(
            environment: ["TMPDIR": temporaryDirectory.path],
            applicationArguments: ["-c", "echo startup-failed >&2; exit 7"],
            probeArguments: []
        )

        do {
            _ = try ApplicationLauncher().launch(
                application: application,
                prepared: prepared
            )
            Issue.record("立即退出的目标进程不应被标记为启动成功")
        } catch ApplicationLaunchError.exitedEarly(let status) {
            #expect(status == 7)
        }
    }
}
