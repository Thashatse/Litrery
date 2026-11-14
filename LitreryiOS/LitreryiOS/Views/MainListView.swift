import SwiftUI

struct MainListView: View {
    let store: VehicleStore
    /// Set when the store is backed by a Keychain key the user can clear (e.g. to
    /// paste a rotated one). Nil hides the menu.
    var onForgetKey: (() -> Void)?
    @State private var viewModel: MainListViewModel
    @State private var isPresentingAddVehicle = false

    init(store: VehicleStore, onForgetKey: (() -> Void)? = nil) {
        self.store = store
        self.onForgetKey = onForgetKey
        _viewModel = State(initialValue: MainListViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.vehicles.isEmpty {
                    ProgressView()
                } else if viewModel.vehicles.isEmpty {
                    ContentUnavailableView(
                        "No Vehicles Yet",
                        systemImage: "car.fill",
                        description: Text("Add your first vehicle to start tracking fill-ups.")
                    )
                } else {
                    List(viewModel.vehicles) { vehicle in
                        NavigationLink(value: vehicle) {
                            VehicleRow(vehicle: vehicle)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Vehicles")
            .navigationDestination(for: Vehicle.self) { vehicle in
                VehicleDetailView(viewModel: VehicleDetailViewModel(vehicle: vehicle, store: store))
            }
            .toolbar {
                if let onForgetKey {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button(role: .destructive, action: onForgetKey) {
                                Label("Forget Database Key", systemImage: "key")
                            }
                        } label: {
                            Label("Settings", systemImage: "ellipsis.circle")
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingAddVehicle = true
                    } label: {
                        Label("Add Vehicle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddVehicle, onDismiss: {
                Task { await viewModel.loadVehicles() }
            }) {
                NavigationStack {
                    AddVehicleView(viewModel: AddVehicleViewModel(store: store))
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            // MAUI's OnAppearing fires on every appearance, including "back from
            // detail" — .task would NOT re-run in that case since it's tied to view
            // identity, not the appear/disappear cycle. .onAppear is the correct match.
            .onAppear {
                Task { await viewModel.loadVehicles() }
            }
            .refreshable {
                await viewModel.loadVehicles()
            }
        }
    }
}

private struct VehicleRow: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vehicle.make)
                .font(.system(size: 14))
            Text(vehicle.model)
                .font(.system(size: 18, weight: .bold))
            Text(vehicle.year)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MainListView(store: MockVehicleStore())
}

#Preview("Empty") {
    MainListView(store: MockVehicleStore(vehicles: []))
}
