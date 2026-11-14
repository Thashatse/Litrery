import Foundation

@MainActor
@Observable
final class VehicleDetailViewModel {
    var vehicle: Vehicle
    let store: VehicleStore

    init(vehicle: Vehicle, store: VehicleStore) {
        self.vehicle = vehicle
        self.store = store
    }

    var sortedLogs: [FuelLog] {
        vehicle.logs.sorted { $0.date > $1.date }
    }

    var averageConsumptionText: String {
        let values = vehicle.logs.compactMap(\.lPer100Km)
        guard !values.isEmpty else { return "--" }
        let avg = values.reduce(0, +) / Double(values.count)
        return avg.formatted(.number.precision(.fractionLength(1)))
    }

    var averageCostText: String {
        let values = vehicle.logs.compactMap(\.costZar)
        guard !values.isEmpty else { return "--" }
        let avg = values.reduce(0, +) / Double(values.count)
        return "R\(avg.formatted(.number.precision(.fractionLength(0))))"
    }

    var totalFillUpsText: String {
        "\(vehicle.logs.count)"
    }

    var averageDaysBetweenFillsText: String {
        guard vehicle.logs.count >= 2 else { return "--" }
        let sorted = vehicle.logs.sorted { $0.date > $1.date }
        let gaps = zip(sorted, sorted.dropFirst()).map { $0.date.timeIntervalSince($1.date) / 86_400 }
        let avg = gaps.reduce(0, +) / Double(gaps.count)
        return "\(avg.formatted(.number.precision(.fractionLength(1))))d"
    }
}
