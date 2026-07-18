import Testing
@testable import PrivacyRunCore

struct ReportBuilderTests {
    private let configuration = EnvironmentConfiguration(
        timeZone: .fixed(identifier: "Asia/Tokyo"),
        languageIdentifier: "en-US",
        localeIdentifier: "en_US"
    )

    private let probe = ProbeReport(
        timeZoneIdentifier: "Asia/Tokyo",
        localeIdentifier: "en_US",
        preferredLanguages: ["en-US"]
    )

    @Test
    func consistentNetworkProducesPassingRiskCheck() {
        let report = ReportBuilder().build(
            configuration: configuration,
            probe: probe,
            ipCountryCode: "JP",
            consistency: .consistent,
            processIdentifier: 42
        )

        #expect(report.processIdentifier == 42)
        #expect(report.checks.count == 5)
        #expect(
            report.checks.first { $0.name == "时区与 IP 是否一致" }?.result
                == .passed
        )
    }

    @Test
    func missingProbeNeverReportsEnvironmentChecksAsPassed() {
        let report = ReportBuilder().build(
            configuration: EnvironmentConfiguration(),
            probe: nil,
            ipCountryCode: nil,
            consistency: .unavailable,
            processIdentifier: nil
        )

        #expect(
            report.checks.first { $0.name == "时区" }?.result == .unavailable
        )
        #expect(
            report.checks.first { $0.name == "语言" }?.result == .unavailable
        )
        #expect(
            report.checks.first { $0.name == "地区格式" }?.result == .unavailable
        )
    }

    @Test
    func equalOffsetsFromDifferentZonesAreNotTreatedAsSameTimeZone() {
        let seoulProbe = ProbeReport(
            timeZoneIdentifier: "Asia/Seoul",
            localeIdentifier: "en_US",
            preferredLanguages: ["en-US"]
        )

        let report = ReportBuilder().build(
            configuration: configuration,
            probe: seoulProbe,
            ipCountryCode: "JP",
            consistency: .consistent,
            processIdentifier: 42
        )

        #expect(
            report.checks.first { $0.name == "时区" }?.result == .warning
        )
    }

    @Test
    func inconsistentNetworkIsWarningWithoutFailingProbeFields() {
        let report = ReportBuilder().build(
            configuration: configuration,
            probe: probe,
            ipCountryCode: "US",
            consistency: .inconsistent,
            processIdentifier: 42
        )

        #expect(
            report.checks.first { $0.name == "时区" }?.result == .passed
        )
        #expect(
            report.checks.first { $0.name == "时区与 IP 是否一致" }?.result
                == .warning
        )
    }

    @Test
    func unavailableNetworkDoesNotBlockLocalChecks() {
        let report = ReportBuilder().build(
            configuration: configuration,
            probe: probe,
            ipCountryCode: nil,
            consistency: .unavailable,
            processIdentifier: 42
        )

        #expect(
            report.checks.first { $0.name == "公网 IP 属地" }?.result
                == .unavailable
        )
        #expect(
            report.checks.first { $0.name == "语言" }?.result == .passed
        )
    }

    @Test
    func localeCheckComparesRegionIndependentlyFromHostLanguage() {
        let japaneseConfiguration = EnvironmentConfiguration(
            languageIdentifier: "ja-JP",
            localeIdentifier: "ja_JP"
        )
        let bundledProbe = ProbeReport(
            timeZoneIdentifier: "Asia/Tokyo",
            localeIdentifier: "zh-Hans_JP",
            preferredLanguages: ["ja-JP"]
        )

        let report = ReportBuilder().build(
            configuration: japaneseConfiguration,
            probe: bundledProbe,
            ipCountryCode: nil,
            consistency: .unavailable,
            processIdentifier: 42
        )
        let localeCheck = report.checks.first { $0.name == "地区格式" }

        #expect(localeCheck?.expected == "JP")
        #expect(localeCheck?.actual == "JP")
        #expect(localeCheck?.result == .passed)
    }
}
