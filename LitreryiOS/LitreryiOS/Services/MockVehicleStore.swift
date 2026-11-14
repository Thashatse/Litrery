import Foundation

/// In-memory store for Xcode Previews and tests — no network, no Keychain.
/// Seeded to exercise every branch VehicleDetailViewModel's stats math hits:
/// zero logs ("--" everywhere), exactly one log ("--" specifically for avg-days,
/// which needs >= 2), and many logs mixing barsRemaining nil/0/populated and
/// notes present/absent.
final class MockVehicleStore: VehicleStore, @unchecked Sendable {
    private var vehicles: [Vehicle]

    init(vehicles: [Vehicle] = MockVehicleStore.sampleVehicles) {
        self.vehicles = vehicles
    }

    func fetchVehicles() async throws -> [Vehicle] {
        vehicles
    }

    @discardableResult
    func upsertVehicle(_ vehicle: Vehicle) async throws -> Vehicle {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            vehicles[index] = vehicle
        } else {
            vehicles.append(vehicle)
        }
        return vehicle
    }

    static var sampleVehicles: [Vehicle] {
        let now = Date()
        let day: TimeInterval = 86_400

        var noLogs = Vehicle()
        noLogs.make = "Toyota"; noLogs.model = "Hilux"; noLogs.year = "2019"
        noLogs.color = "White"; noLogs.registrationNumber = "CA 111-111"
        noLogs.vehicleIdentificationNumber = "VIN-NOLOGS"; noLogs.odometer = 82_000

        var oneLog = Vehicle()
        oneLog.make = "Suzuki"; oneLog.model = "Jimny"; oneLog.year = "2023"
        oneLog.color = "Green"; oneLog.registrationNumber = "CA 222-222"
        oneLog.vehicleIdentificationNumber = "VIN-ONELOG"; oneLog.odometer = 15_400
        oneLog.logs = [
            FuelLog(date: now.addingTimeInterval(-2 * day), kilometresDriven: 380, litres: 32.5,
                    costZar: 631.75, lPer100Km: 8.55, barsRemaining: 7, notes: "Full tank")
        ]

        var manyLogs = Vehicle()
        manyLogs.make = "Volkswagen"; manyLogs.model = "Polo"; manyLogs.year = "2021"
        manyLogs.color = "Grey"; manyLogs.registrationNumber = "CA 333-333"
        manyLogs.vehicleIdentificationNumber = "VIN-MANYLOGS"; manyLogs.odometer = 44_200
        manyLogs.logs = [
            FuelLog(date: now.addingTimeInterval(-1 * day), kilometresDriven: 410, litres: 28.2,
                    costZar: 548.10, lPer100Km: 6.88, barsRemaining: 0, notes: nil),
            FuelLog(date: now.addingTimeInterval(-9 * day), kilometresDriven: 395.5, litres: 29.9,
                    costZar: 580.06, lPer100Km: 7.56, barsRemaining: nil, notes: "Filled at Engen"),
            FuelLog(date: now.addingTimeInterval(-18 * day), kilometresDriven: 402.2, litres: 27.4,
                    costZar: 531.98, lPer100Km: 6.81, barsRemaining: 3, notes: nil),
        ]

        return [noLogs, oneLog, manyLogs]
    }
}
