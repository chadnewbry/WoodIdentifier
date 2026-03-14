import Foundation

/// Single source of truth for app configuration.
/// Reads from `app-config.json` bundled in `.asc/` at the project root.
public struct AppConfig: Codable {
    public let bundleId: String
    public let appName: String?
    public let copyright: String
    public let urls: URLs
    public let revenueCat: RevenueCat?
    public let review: Review?

    public struct URLs: Codable {
        public let website: String
        public let privacyPolicy: String
        public let termsOfService: String
        public let support: String
    }

    public struct RevenueCat: Codable {
        public let apiKey: String

        public var isProduction: Bool {
            apiKey.hasPrefix("appl_")
        }

        public var isTest: Bool {
            apiKey.hasPrefix("test_")
        }
    }

    public struct Review: Codable {
        public let demoAccountRequired: Bool?
        public let contactFirstName: String?
        public let contactLastName: String?
        public let contactEmail: String?
        public let contactPhone: String?
    }

    public static let shared: AppConfig = {
        let configName: String
        if Bundle.main.url(forResource: "app-config", withExtension: "json") != nil {
            configName = "app-config"
        } else if Bundle.main.url(forResource: "app-store", withExtension: "json") != nil {
            configName = "app-store"
        } else {
            fatalError("Missing app-config.json in bundle. Add .asc/app-config.json to 'Copy Bundle Resources'.")
        }

        guard let url = Bundle.main.url(forResource: configName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("Failed to load \(configName).json from bundle.")
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AppConfig.self, from: data)
        } catch {
            fatalError("Failed to decode \(configName).json: \(error)")
        }
    }()
}
