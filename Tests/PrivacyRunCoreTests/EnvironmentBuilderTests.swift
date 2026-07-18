import Foundation
import Testing
@testable import PrivacyRunCore

struct EnvironmentBuilderTests {
    @Test
    func fixedConfigurationOverridesProcessEnvironment() throws {
        let configuration = EnvironmentConfiguration(
            timeZone: .fixed(identifier: "Asia/Tokyo"),
            languageIdentifier: "en-US",
            localeIdentifier: "en_US"
        )

        let result = try EnvironmentBuilder().build(
            configuration: configuration,
            base: [
                "TZ": "UTC",
                "HOME": "/Users/test",
                "OPENAI_API_KEY": "secret",
                "KEEP": "value"
            ],
            temporaryDirectory: URL(fileURLWithPath: "/tmp/privacyrun-test")
        )

        #expect(result["TZ"] == "Asia/Tokyo")
        #expect(result["LANG"] == "en_US.UTF-8")
        #expect(result["LC_ALL"] == "en_US.UTF-8")
        #expect(result["TMPDIR"] == "/tmp/privacyrun-test")
        #expect(result["HOME"] == "/Users/test")
        #expect(result["OPENAI_API_KEY"] == nil)
        #expect(result["KEEP"] == nil)
    }

    @Test
    func inheritedConfigurationDoesNotLeakLocaleOrToolMarkers() throws {
        let result = try EnvironmentBuilder().build(
            configuration: EnvironmentConfiguration(),
            base: [
                "LANG": "zh_CN.UTF-8",
                "LC_ALL": "zh_CN.UTF-8",
                "PRIVACYRUN_LANGUAGE": "zh-Hans"
            ],
            temporaryDirectory: URL(fileURLWithPath: "/tmp/privacyrun-test")
        )

        #expect(result["LANG"] == nil)
        #expect(result["LC_ALL"] == nil)
        #expect(result["PRIVACYRUN_LANGUAGE"] == nil)
    }

    @Test
    func inheritedTimeZoneRemovesParentOverride() throws {
        let result = try EnvironmentBuilder().build(
            configuration: EnvironmentConfiguration(timeZone: .inherit),
            base: ["TZ": "UTC"],
            temporaryDirectory: URL(fileURLWithPath: "/tmp/privacyrun-test")
        )

        #expect(result["TZ"] == nil)
    }

    @Test
    func invalidTimeZoneIsRejected() {
        #expect(throws: EnvironmentConfigurationError.invalidTimeZone("Mars/Olympus")) {
            try EnvironmentBuilder().build(
                configuration: EnvironmentConfiguration(
                    timeZone: .fixed(identifier: "Mars/Olympus")
                ),
                base: [:],
                temporaryDirectory: URL(fileURLWithPath: "/tmp/privacyrun-test")
            )
        }
    }
}
