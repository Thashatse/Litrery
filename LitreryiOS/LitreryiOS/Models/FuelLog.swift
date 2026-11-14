import Foundation

struct FuelLog: Codable, Identifiable, Hashable, Sendable {
    var id: String = UUID().uuidString
    var date: Date
    var kilometresDriven: Double?
    var litres: Double?
    var costZar: Double?
    var lPer100Km: Double?
    var barsRemaining: Int?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case date = "Date"
        case kilometresDriven = "KilometresDriven"
        case litres = "Litres"
        case costZar = "CostZar"
        case lPer100Km = "LPer100Km"
        case barsRemaining = "BarsRemaining"
        case notes = "Notes"
    }
}
