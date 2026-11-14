import Foundation

struct Vehicle: Codable, Identifiable, Hashable, Sendable {
    var id: String = UUID().uuidString
    var vehicleIdentificationNumber: String = ""
    var engineNumber: String = ""
    var make: String = ""
    var model: String = ""
    var year: String = ""
    var color: String = ""
    var registrationNumber: String = ""
    var odometer: Int = 0
    var logs: [FuelLog] = []

    enum CodingKeys: String, CodingKey {
        case id
        case vehicleIdentificationNumber = "VehicleIdentificationNumber"
        case engineNumber = "EngineNumber"
        case make = "Make"
        case model = "Model"
        case year = "Year"
        case color = "Color"
        case registrationNumber = "RegistrationNumber"
        case odometer = "Odometer"
        case logs = "Logs"
    }
}
