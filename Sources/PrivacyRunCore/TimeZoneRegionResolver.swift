import Foundation

public enum RegionConsistency: String, Codable, Equatable, Sendable {
    case consistent
    case inconsistent
    case unavailable
}

public struct TimeZoneRegionResolver: Sendable {
    private let regionsByTimeZone: [String: Set<String>]

    public init(zoneTable: String) {
        self.regionsByTimeZone = Self.parse(zoneTable)
    }

    public init(
        zoneTableURL: URL = URL(fileURLWithPath: "/usr/share/zoneinfo/zone.tab")
    ) throws {
        let data = try Data(contentsOf: zoneTableURL)
        guard let contents = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        self.init(zoneTable: contents)
    }

    public func regions(for timeZoneIdentifier: String) -> Set<String> {
        regionsByTimeZone[timeZoneIdentifier] ?? []
    }

    public func compare(
        timeZoneIdentifier: String,
        ipCountryCode: String?
    ) -> RegionConsistency {
        guard
            let ipCountryCode,
            !ipCountryCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return .unavailable
        }

        let expectedRegions = regions(for: timeZoneIdentifier)
        guard !expectedRegions.isEmpty else {
            return .unavailable
        }

        return expectedRegions.contains(ipCountryCode.uppercased())
            ? .consistent
            : .inconsistent
    }

    private static func parse(_ contents: String) -> [String: Set<String>] {
        var result: [String: Set<String>] = [:]

        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else {
                continue
            }

            let columns = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard columns.count >= 3 else {
                continue
            }

            let countryCodes = columns[0]
                .split(separator: ",")
                .map { String($0).uppercased() }
            let timeZoneIdentifier = String(columns[2])
            result[timeZoneIdentifier, default: []].formUnion(countryCodes)
        }

        return result
    }
}
