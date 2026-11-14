import Foundation

@MainActor
@Observable
final class AddVehicleViewModel {
    var make = ""
    var model = ""
    var year = ""
    var color = ""
    var registrationNumber = ""
    var vin = ""
    var odometerText = ""

    var errorMessage: String?
    private(set) var isSaving = false

    private let store: VehicleStore

    init(store: VehicleStore) {
        self.store = store
    }

    func save() async -> Bool {
        let make = make.trimmingCharacters(in: .whitespaces)
        let model = model.trimmingCharacters(in: .whitespaces)
        let vin = vin.trimmingCharacters(in: .whitespaces)

        guard !make.isEmpty, !model.isEmpty, !vin.isEmpty else {
            // Fixed wording vs. the source app, which required VIN in code but only
            // said "Make and model are required" in the alert.
            errorMessage = "Make, model, and VIN are required."
            return false
        }

        let trimmedOdometer = odometerText.trimmingCharacters(in: .whitespaces)
        let odometerKm = DecimalInput.parseInteger(trimmedOdometer)
        guard trimmedOdometer.isEmpty || odometerKm != nil else {
            errorMessage = "Odometer \"\(odometerText)\" isn't a whole number of kilometres."
            return false
        }

        let vehicle = Vehicle(
            vehicleIdentificationNumber: vin,
            make: make,
            model: model,
            year: year.trimmingCharacters(in: .whitespaces),
            color: color.trimmingCharacters(in: .whitespaces),
            registrationNumber: registrationNumber.trimmingCharacters(in: .whitespaces),
            odometer: odometerKm ?? 0
        )

        isSaving = true
        defer { isSaving = false }
        do {
            _ = try await store.upsertVehicle(vehicle)
            return true
        } catch {
            // Generic message, kept deliberately — matches the source app's
            // AddVehiclePage exactly, which shows a canned message rather than
            // ex.Message (unlike AddLogPage, which does show the real error).
            errorMessage = "Failed to create vehicle."
            return false
        }
    }
}
