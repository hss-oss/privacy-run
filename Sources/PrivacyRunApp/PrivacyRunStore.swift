import AppKit
import Foundation
import PrivacyRunCore

@MainActor
final class PrivacyRunStore: ObservableObject {
    enum Screen: String {
        case configuration
        case report
    }

    enum LaunchState: Equatable {
        case idle
        case launching
        case running(Int32)
        case failed(String)
    }

    @Published private(set) var applications: [AppRecord] = []
    @Published var selectedApplicationID: UUID?
    @Published var screen: Screen = .configuration
    @Published private(set) var launchState: LaunchState = .idle

    private let persistenceKey = "privacyrun.app-records.v1"

    init() {
        load()
    }

    var selectedApplication: AppRecord? {
        guard let selectedApplicationID else {
            return nil
        }
        return applications.first { $0.id == selectedApplicationID }
    }

    func addApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "选择要通过 PrivacyRun 启动的 App"
        panel.prompt = "添加"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let resolved = try AppBundleResolver().resolve(url)
            if let existing = applications.first(where: {
                $0.bundleIdentifier == resolved.bundleIdentifier
            }) {
                selectedApplicationID = existing.id
                return
            }

            let record = AppRecord(
                name: resolved.name,
                bundleIdentifier: resolved.bundleIdentifier,
                version: resolved.version,
                bundlePath: resolved.bundleURL.path(percentEncoded: false)
            )
            applications.append(record)
            selectedApplicationID = record.id
            save()
        } catch {
            launchState = .failed(error.localizedDescription)
        }
    }

    func removeSelectedApplication() {
        guard let selectedApplicationID else {
            return
        }
        applications.removeAll { $0.id == selectedApplicationID }
        self.selectedApplicationID = applications.first?.id
        screen = .configuration
        launchState = .idle
        save()
    }

    func updateConfiguration(_ configuration: EnvironmentConfiguration) {
        guard
            let selectedApplicationID,
            let index = applications.firstIndex(where: { $0.id == selectedApplicationID })
        else {
            return
        }
        applications[index].configuration = configuration
        save()
    }

    func launchSelectedApplication() {
        guard let record = selectedApplication, launchState != .launching else {
            return
        }

        launchState = .launching
        let configuration = record.configuration
        let bundleURL = URL(fileURLWithPath: record.bundlePath)
        let probeURL = Self.probeExecutableURL()
        let temporaryRoot = Self.temporaryRootURL()

        Task {
            let ipTask = Task {
                try? await CountryISProvider().countryCode()
            }

            do {
                let resolved = try AppBundleResolver().resolve(bundleURL)
                let prepared = try await Task.detached {
                    try ApplicationLauncher().prepare(
                        bundleIdentifier: resolved.bundleIdentifier,
                        configuration: configuration,
                        temporaryRoot: temporaryRoot
                    )
                }.value

                let probe = try? await Task.detached {
                    guard FileManager.default.isExecutableFile(atPath: probeURL.path) else {
                        throw ProbeRunnerError.failedToStart("找不到 privacyrun-probe")
                    }
                    return try ProbeRunner().run(
                        executableURL: probeURL,
                        environment: prepared.environment,
                        arguments: prepared.arguments
                    )
                }.value

                let processIdentifier = try await Task.detached {
                    try ApplicationLauncher().launch(
                        application: resolved,
                        prepared: prepared
                    )
                }.value

                let countryCode = await ipTask.value
                let expectedTimeZone = Self.expectedTimeZone(configuration)
                let consistency = (
                    try? TimeZoneRegionResolver()
                        .compare(
                            timeZoneIdentifier: expectedTimeZone,
                            ipCountryCode: countryCode
                        )
                ) ?? .unavailable

                let report = ReportBuilder().build(
                    configuration: configuration,
                    probe: probe,
                    ipCountryCode: countryCode,
                    consistency: consistency,
                    processIdentifier: processIdentifier
                )
                store(
                    report: report,
                    for: record.id,
                    launchState: .running(processIdentifier)
                )
            } catch {
                let countryCode = await ipTask.value
                let report = ReportBuilder().build(
                    configuration: configuration,
                    probe: nil,
                    ipCountryCode: countryCode,
                    consistency: .unavailable,
                    processIdentifier: nil,
                    launchError: error.localizedDescription
                )
                store(
                    report: report,
                    for: record.id,
                    launchState: .failed(error.localizedDescription)
                )
            }
        }
    }

    func dismissError() {
        if case .failed = launchState {
            launchState = .idle
        }
    }

    private func store(
        report: RunReport,
        for applicationID: UUID,
        launchState: LaunchState
    ) {
        guard let index = applications.firstIndex(where: { $0.id == applicationID }) else {
            return
        }
        applications[index].latestReport = report
        self.launchState = launchState
        screen = .report
        save()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: persistenceKey),
            let decoded = try? JSONDecoder().decode([AppRecord].self, from: data)
        else {
            return
        }
        applications = decoded
        selectedApplicationID = decoded.first?.id
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(applications) else {
            return
        }
        UserDefaults.standard.set(data, forKey: persistenceKey)
    }

    private static func probeExecutableURL() -> URL {
        URL(fileURLWithPath: CommandLine.arguments[0])
            .deletingLastPathComponent()
            .appending(path: "privacyrun-probe")
    }

    private static func temporaryRootURL() -> URL {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return support
            .appending(path: "PrivacyRun", directoryHint: .isDirectory)
            .appending(path: "Temp", directoryHint: .isDirectory)
    }

    private static func expectedTimeZone(
        _ configuration: EnvironmentConfiguration
    ) -> String {
        switch configuration.timeZone {
        case .inherit:
            TimeZone.current.identifier
        case .fixed(let identifier):
            identifier
        }
    }
}
