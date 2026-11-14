import SwiftUI

/// Shown on first launch (or after "Forget Database Key"): the Cosmos primary key is
/// pasted here once, checked against the database, then kept in Keychain.
struct CosmosKeyEntryView: View {
    let endpoint: URL
    let onConnected: (VehicleStore) -> Void

    @State private var key = ""
    @State private var isConnecting = false
    @State private var errorMessage: String?

    private var trimmedKey: String {
        key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Primary key", text: $key)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .privacySensitive()
                        .onSubmit { Task { await connect() } }
                } header: {
                    Text("Cosmos DB primary key")
                } footer: {
                    Text("Paste the primary key for \(endpoint.host() ?? "your Cosmos account") from Azure Portal → Keys. It's stored in this device's Keychain and only used to sign requests.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await connect() }
                    } label: {
                        HStack {
                            Text("Connect")
                            if isConnecting {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(trimmedKey.isEmpty || isConnecting)
                }
            }
            .navigationTitle("Connect Database")
        }
    }

    private func connect() async {
        let candidate = trimmedKey
        guard !candidate.isEmpty, !isConnecting else { return }
        guard Data(base64Encoded: candidate) != nil else {
            errorMessage = "That doesn't look like a Cosmos key. Copy the Primary Key from Azure Portal → your Cosmos account → Keys."
            return
        }

        isConnecting = true
        errorMessage = nil
        defer { isConnecting = false }

        // Prove the key works before saving it, so a typo can't leave the app stuck
        // on an empty list with a generic load error.
        let store = CosmosVehicleStore(endpoint: endpoint, masterKeyBase64: candidate)
        do {
            _ = try await store.fetchVehicles()
            try CosmosCredentials.saveMasterKey(candidate)
            onConnected(store)
        } catch {
            errorMessage = "Couldn't connect with that key. Check the key and your connection, then try again."
        }
    }
}

#Preview {
    CosmosKeyEntryView(endpoint: URL(string: "https://example.documents.azure.com:443/")!) { _ in }
}
