import Testing
@testable import PrivacyRunCore

struct TimeZoneRegionResolverTests {
    private let zoneTable = """
    # Country\tCoordinates\tTZ
    JP\t+353916+1394441\tAsia/Tokyo
    US\t+404251-0740023\tAmerica/New_York
    CA,US\t+4906-11631\tAmerica/Creston
    """

    @Test
    func matchingCountryIsConsistent() {
        let resolver = TimeZoneRegionResolver(zoneTable: zoneTable)

        #expect(
            resolver.compare(timeZoneIdentifier: "Asia/Tokyo", ipCountryCode: "jp")
                == .consistent
        )
    }

    @Test
    func differentCountryIsInconsistent() {
        let resolver = TimeZoneRegionResolver(zoneTable: zoneTable)

        #expect(
            resolver.compare(timeZoneIdentifier: "Asia/Tokyo", ipCountryCode: "US")
                == .inconsistent
        )
    }

    @Test
    func multiCountryTimeZoneAcceptsEveryMappedRegion() {
        let resolver = TimeZoneRegionResolver(zoneTable: zoneTable)

        #expect(
            resolver.compare(timeZoneIdentifier: "America/Creston", ipCountryCode: "CA")
                == .consistent
        )
        #expect(
            resolver.compare(timeZoneIdentifier: "America/Creston", ipCountryCode: "US")
                == .consistent
        )
    }

    @Test
    func missingDataCannotBeJudged() {
        let resolver = TimeZoneRegionResolver(zoneTable: zoneTable)

        #expect(
            resolver.compare(timeZoneIdentifier: "Etc/UTC", ipCountryCode: "JP")
                == .unavailable
        )
        #expect(
            resolver.compare(timeZoneIdentifier: "Asia/Tokyo", ipCountryCode: nil)
                == .unavailable
        )
    }
}
