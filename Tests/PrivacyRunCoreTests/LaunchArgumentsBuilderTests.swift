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

    @Test
    func usesChromiumLanguageArgumentForElectron() {
        let configuration = EnvironmentConfiguration(
            languageIdentifier: "ja-JP",
            localeIdentifier: "ja_JP"
        )

        let result = LaunchArgumentsBuilder().build(
            configuration: configuration,
            style: .electron,
            base: ["--existing"]
        )

        #expect(result == ["--existing", "--lang=ja-JP"])
    }

    @Test
    func unknownRuntimeUsesEnvironmentOnly() {
        let configuration = EnvironmentConfiguration(
            languageIdentifier: "ja-JP",
            localeIdentifier: "ja_JP"
        )

        let result = LaunchArgumentsBuilder().build(
            configuration: configuration,
            style: .environmentOnly,
            base: ["--existing"]
        )

        #expect(result == ["--existing"])
    }
}
