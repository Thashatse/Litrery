import SwiftUI

struct AddFuelLogView: View {
    @State private var viewModel: AddFuelLogViewModel
    let onSave: (Vehicle) -> Void
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddFuelLogViewModel, onSave: @escaping (Vehicle) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section {
                // SwiftUI supports one combined date+time picker natively — the
                // source app uses two separate pickers (Date + Time) manually
                // summed into one DateTime; this produces the identical value
                // with less code.
                DatePicker("Date & Time", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
            }

            Section {
                // Bound to the raw text and read with DecimalInput, which accepts a
                // comma or a full stop whatever the phone's locale says. See
                // LabeledNumberField.swift for the bug this replaces.
                LabeledDecimalField(title: "Kilometres driven", placeholder: "e.g. \(DecimalInput.format(424.2))", text: $viewModel.kilometresText)
                LabeledDecimalField(title: "Litres", placeholder: "e.g. \(DecimalInput.format(34.15))", text: $viewModel.litresText)

                VStack(alignment: .leading, spacing: 4) {
                    Text("L/100km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("Auto calculated", text: viewModel.lPer100KmEditingBinding)
                            .keyboardType(.decimalPad)
                        Button("Recalc") { viewModel.recalcButtonTapped() }
                            .buttonStyle(.bordered)
                    }
                    Text("Edit manually to override, or tap Recalc to recalculate from km and litres.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                LabeledDecimalField(title: "Cost (R)", placeholder: "e.g. \(DecimalInput.format(664.9))", text: $viewModel.costText)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bars remaining (out of 10)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Slider(value: $viewModel.barsRemaining, in: 0...10, step: 1)
                        Text(viewModel.barsRemaining == 0 ? "not recorded" : "\(Int(viewModel.barsRemaining))/10")
                            .font(.system(size: 14, weight: .bold))
                            .frame(minWidth: 84, alignment: .trailing)
                    }
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 80)
                }
            }
        }
        // The decimal pad has no Return key; dragging the form puts it away.
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Add Fill-up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        if let updated = await viewModel.save() {
                            onSave(updated)
                            dismiss()
                        }
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
        AddFuelLogView(
            viewModel: AddFuelLogViewModel(vehicle: MockVehicleStore.sampleVehicles[1], store: MockVehicleStore()),
            onSave: { _ in }
        )
    }
}
