import Foundation

public struct ReportBuilder: Sendable {
    public init() {}

    public func build(
        configuration: EnvironmentConfiguration,
        probe: ProbeReport?,
        ipCountryCode: String?,
        consistency: RegionConsistency,
        processIdentifier: Int32?,
        launchError: String? = nil
    ) -> RunReport {
        let expectedTimeZone: String
        switch configuration.timeZone {
        case .inherit:
            expectedTimeZone = TimeZone.current.identifier
        case .fixed(let identifier):
            expectedTimeZone = identifier
        }

        let actualTimeZone = probe?.timeZoneIdentifier ?? "无法获取"
        let timeZoneOutcome = outcome(
            probe.map {
                timeZonesMatch(expected: expectedTimeZone, actual: $0.timeZoneIdentifier)
            }
        )

        let expectedLanguage = configuration.languageIdentifier ?? "跟随系统"
        let actualLanguage = probe?.preferredLanguages.first ?? "无法获取"
        let languageOutcome = outcome(
            probe.map {
                configuration.languageIdentifier == nil
                || normalizedLanguage($0.preferredLanguages.first ?? "")
                    == normalizedLanguage(expectedLanguage)
            }
        )

        let expectedLocale = configuration.localeIdentifier
            .flatMap(regionIdentifier) ?? "跟随系统"
        let actualLocale = probe
            .flatMap { regionIdentifier($0.localeIdentifier) } ?? "无法获取"
        let localeOutcome = outcome(
            probe.map {
                configuration.localeIdentifier == nil
                || regionIdentifier($0.localeIdentifier) == expectedLocale
            }
        )

        let ipDisplay = ipCountryCode ?? "无法获取"
        let consistencyValues: (String, CheckResult) = switch consistency {
        case .consistent:
            ("一致", .passed)
        case .inconsistent:
            ("不一致", .warning)
        case .unavailable:
            ("无法判断", .unavailable)
        }

        let checks = [
            ReportCheck(
                name: "时区",
                expected: expectedTimeZone,
                actual: actualTimeZone,
                result: timeZoneOutcome.0,
                resultLabel: timeZoneOutcome.1
            ),
            ReportCheck(
                name: "语言",
                expected: expectedLanguage,
                actual: actualLanguage,
                result: languageOutcome.0,
                resultLabel: languageOutcome.1
            ),
            ReportCheck(
                name: "地区格式",
                expected: expectedLocale,
                actual: actualLocale,
                result: localeOutcome.0,
                resultLabel: localeOutcome.1
            ),
            ReportCheck(
                name: "系统默认字体",
                expected: "仅供参考",
                actual: probe?.systemFontName ?? "无法获取",
                result: probe == nil ? .unavailable : .information,
                resultLabel: probe == nil ? "无法获取" : "系统值"
            ),
            ReportCheck(
                name: "公网 IP 属地",
                expected: "仅供参考",
                actual: ipDisplay,
                result: ipCountryCode == nil ? .unavailable : .information,
                resultLabel: ipCountryCode == nil ? "无法获取" : "已获取"
            ),
            ReportCheck(
                name: "时区与 IP 是否一致",
                expected: expectedTimeZone,
                actual: ipDisplay,
                result: consistencyValues.1,
                resultLabel: consistencyValues.0
            )
        ]

        return RunReport(
            processIdentifier: processIdentifier,
            checks: checks,
            launchError: launchError
        )
    }

    private func normalizedLanguage(_ value: String) -> String {
        value.replacingOccurrences(of: "_", with: "-").lowercased()
    }

    private func timeZonesMatch(expected: String, actual: String) -> Bool {
        if expected == actual {
            return true
        }
        let utcAliases: Set<String> = ["UTC", "GMT", "Etc/UTC"]
        return utcAliases.contains(expected) && utcAliases.contains(actual)
    }

    private func outcome(_ matches: Bool?) -> (CheckResult, String) {
        guard let matches else {
            return (.unavailable, "无法获取")
        }
        return matches ? (.passed, "通过") : (.warning, "不一致")
    }

    private func regionIdentifier(_ value: String) -> String? {
        let identifier = value
            .replacingOccurrences(of: "-", with: "_")
            .components(separatedBy: ".")
            .first
            ?? value
        return Locale(identifier: identifier).region?.identifier
    }
}
