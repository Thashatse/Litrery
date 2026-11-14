import Foundation

@MainActor
@Observable
final class MainListViewModel {
    private(set) var vehicles: [Vehicle] = []
    private(set) var isLoading = false
    var errorMessage: String?

    private let store: VehicleStore

    init(store: VehicleStore) {
        self.store = store
    }

    func loadVehicles() async {
        isLoading = true
        defer { isLoading = false }
        do {
            vehicles = try await store.fetchVehicles()
        } catch {
            errorMessage = "An error occurred loading vehicles, please try again later."
        }
    }
}
