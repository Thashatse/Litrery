import SwiftUI

struct AddVehicleView: View {
    @State private var viewModel: AddVehicleViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddVehicleViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            LabeledTextField(title: "Make", placeholder: "e.g. Suzuki", text: $viewModel.make)
            LabeledTextField(title: "Model", placeholder: "e.g. Jimny", text: $viewModel.model)
            LabeledTextField(title: "Year", placeholder: "e.g. 2025", text: $viewModel.year, keyboardType: .numberPad)
            LabeledTextField(title: "Color", placeholder: "e.g. White", text: $viewModel.color)
            LabeledTextField(title: "Registration number", placeholder: "e.g. CA 123-456", text: $viewModel.registrationNumber, autocapitalization: .characters)
            LabeledTextField(title: "VIN", placeholder: "Vehicle identification number", text: $viewModel.vin, autocapitalization: .characters)
            LabeledIntegerField(title: "Odometer (km)", placeholder: "e.g. 15000", text: $viewModel.odometerText)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Add Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        if await viewModel.save() { dismiss() }
                    }
                }
                .disabled(viewModel.isSaving)
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
    }
}

#Preview {
    NavigationStack {
        AddVehicleView(viewModel: AddVehicleViewModel(store: MockVehicleStore()))
    }
}
