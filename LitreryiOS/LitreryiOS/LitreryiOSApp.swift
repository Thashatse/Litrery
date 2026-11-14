import SwiftUI

@main
struct LitreryiOSApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// Picks the data source: a Cosmos store once a key is in Keychain, the key-entry
/// screen until then, or an empty in-memory store if this build has no endpoint.
private struct RootView: View {
    @State private var store: VehicleStore? = RootView.initialStore()

    var body: some View {
        if let store {
            MainListView(store: store, onForgetKey: forgetKeyAction)
        } else if let endpoint = CosmosCredentials.endpoint() {
            CosmosKeyEntryView(endpoint: endpoint) { connected in
                store = connected
            }
        } else {
            // No Config/Secrets.xcconfig set up — degrade to an empty in-memory store
            // rather than crashing, so the app is still explorable.
            MainListView(store: MockVehicleStore(vehicles: []))
        }
    }

    /// Only a Keychain-backed Cosmos store has a key to forget.
    private var forgetKeyAction: (() -> Void)? {
        guard store is CosmosVehicleStore else { return nil }
        return {
            CosmosCredentials.forgetMasterKey()
            store = nil
        }
    }

    private static func initialStore() -> VehicleStore? {
        #if DEBUG
        // Launch with `-useMockStore` to exercise the UI against sample data
        // without reading from or writing to the real Cosmos database.
        if ProcessInfo.processInfo.arguments.contains("-useMockStore") {
            return MockVehicleStore()
        }
        #endif
        guard let endpoint = CosmosCredentials.endpoint(),
              let key = CosmosCredentials.masterKey() else { return nil }
        return CosmosVehicleStore(endpoint: endpoint, masterKeyBase64: key)
    }
}
