import Foundation

/// Deliberately just two operations, matching what the current MAUI app actually
/// uses. `ReadVehicle(id, vin)` (a point-read) is dead code in the source app —
/// nothing calls it — so it isn't ported. There is no delete anywhere in the
/// current app either.
protocol VehicleStore: Sendable {
    func fetchVehicles() async throws -> [Vehicle]

    @discardableResult
    func upsertVehicle(_ vehicle: Vehicle) async throws -> Vehicle
}
