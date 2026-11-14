import Foundation

/// Where the app gets its Cosmos connection details at runtime.
///
/// - The endpoint is baked in at build time (Info.plist ← the gitignored
///   `Config/Secrets.xcconfig`). It names the account but grants no access on its own.
/// - The primary key is never compiled in. `CosmosKeyEntryView` asks for it once and
///   it lives only in this device's Keychain, so a build that leaves this machine
///   (TestFlight, App Store) carries no database credentials.
enum CosmosCredentials {
    /// Unchanged from the old seed-based flow so existing installs keep their key.
    private static let keychainKey = "cosmosMasterKey"

    static func endpoint() -> URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "CosmosEndpoint") as? String,
              !raw.isEmpty, let url = URL(string: raw), url.host() != nil else { return nil }
        return url
    }

    static func masterKey() -> String? {
        guard let key = try? KeychainService().get(keychainKey), !key.isEmpty else { return nil }
        return key
    }

    static func saveMasterKey(_ key: String) throws {
        try KeychainService().set(key, for: keychainKey)
    }

    static func forgetMasterKey() {
        try? KeychainService().delete(keychainKey)
    }
}
