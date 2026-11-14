import SwiftUI

struct VehicleDetailView: View {
    @State private var viewModel: VehicleDetailViewModel
    @State private var isPresentingAddLog = false

    init(viewModel: VehicleDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                headerCard
                statsStrip
                ForEach(viewModel.sortedLogs) { log in
                    FuelLogRow(log: log)
                }
            }
            .padding(16)
        }
        // Kept as a prominent full-width button (unlike the vehicle-list screen's
        // button, which moved to the nav bar): logging a fill-up is this screen's
        // primary purpose and deserves the most discoverable affordance.
        .safeAreaInset(edge: .bottom) {
            Button {
                isPresentingAddLog = true
            } label: {
                Label("Add Fill-up", systemImage: "fuelpump.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(16)
            .background(.bar)
        }
        .navigationTitle(viewModel.vehicle.model)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddLog) {
            NavigationStack {
                AddFuelLogView(
                    viewModel: AddFuelLogViewModel(vehicle: viewModel.vehicle, store: viewModel.store),
                    onSave: { updated in viewModel.vehicle = updated }
                )
            }
        }
    }

    private var headerCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.vehicle.make.uppercased())
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Text(viewModel.vehicle.model)
                    .font(.title2).fontWeight(.bold)
                Text("\(viewModel.vehicle.year) · \(viewModel.vehicle.registrationNumber)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(viewModel.vehicle.odometer.formatted()) km")
                    .font(.system(size: 14, weight: .bold))
                Text("odometer")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background.secondary))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))
    }

    private var statsStrip: some View {
        HStack {
            StatTile(value: viewModel.averageConsumptionText, caption: "avg L/100km")
            StatTile(value: viewModel.averageCostText, caption: "avg cost")
            StatTile(value: viewModel.totalFillUpsText, caption: "fill-ups")
            StatTile(value: viewModel.averageDaysBetweenFillsText, caption: "avg days")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background.secondary))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))
    }
}

#Preview("Many logs") {
    NavigationStack {
        VehicleDetailView(viewModel: VehicleDetailViewModel(vehicle: MockVehicleStore.sampleVehicles[2], store: MockVehicleStore()))
    }
}

#Preview("One log") {
    NavigationStack {
        VehicleDetailView(viewModel: VehicleDetailViewModel(vehicle: MockVehicleStore.sampleVehicles[1], store: MockVehicleStore()))
    }
}

#Preview("No logs") {
    NavigationStack {
        VehicleDetailView(viewModel: VehicleDetailViewModel(vehicle: MockVehicleStore.sampleVehicles[0], store: MockVehicleStore()))
    }
}
