import Foundation

public protocol IPCountryProviding: Sendable {
    func countryCode() async throws -> String
}

public enum IPCountryProviderError: LocalizedError {
    case invalidResponse
    case missingCountry

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "IP 属地服务返回异常"
        case .missingCountry:
            "IP 属地服务未返回国家或地区"
        }
    }
}

public struct CountryISProvider: IPCountryProviding {
    private let endpoint: URL
    private let session: URLSession

    public init(
        endpoint: URL = URL(string: "https://api.country.is/")!,
        timeout: TimeInterval = 2
    ) {
        self.endpoint = endpoint
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        self.session = URLSession(configuration: configuration)
    }

    public func countryCode() async throws -> String {
        let (data, response) = try await session.data(from: endpoint)
        guard
            let response = response as? HTTPURLResponse,
            200..<300 ~= response.statusCode
        else {
            throw IPCountryProviderError.invalidResponse
        }

        let payload = try JSONDecoder().decode(Payload.self, from: data)
        let country = payload.country.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !country.isEmpty else {
            throw IPCountryProviderError.missingCountry
        }
        return country.uppercased()
    }

    private struct Payload: Decodable {
        let country: String
    }
}
