import Testing
@testable import PrivacyRunCore

struct LaunchArgumentsBuilderTests {
    @Test
    func appendsAppleArgumentDomainOverrides() {
        let configuration = EnvironmentConfiguration(
            languageIdentifier: "en-US",
            localeIdentifier: "en_US"
        )

        let result = LaunchArgumentsBuilder().build(
            configuration: configuration,
            base: ["--existing"]
        )

        #expect(
            result == [
                "--existing",
                "-AppleLocale", "en_US",
                "-AppleLanguages", "(en-US)"
            ]
        )
    }

    @Test
    func inheritedValuesDoNotAddArguments() {
        let result = LaunchArgumentsBuilder().build(
            configuration: EnvironmentConfiguration(),
            base: ["--existing"]
        )

        #expect(result == ["--existing"])
    }
}
