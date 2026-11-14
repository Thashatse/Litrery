import Foundation
import SwiftUI

@MainActor
@Observable
final class AddFuelLogViewModel {
    var date: Date = .now

    // The fields hold exactly what the user typed; the numbers are read from that
    // text by DecimalInput (see LabeledNumberField.swift for why).
    var kilometresText = "" {
        didSet { recalculateLPer100Km() }
    }
    var litresText = "" {
        didSet { recalculateLPer100Km() }
    }
    var costText = ""
    var notes = ""

    /// Written directly by recalculateLPer100Km(), never through
    /// lPer100KmEditingBinding, so a programmatic recalculation can never mark
    /// itself as a manual edit.
    private(set) var lPer100KmText = ""
    private(set) var hasManualLPer100KmOverride = false

    var barsRemaining: Double = 0
    var errorMessage: String?
    private(set) var isSaving = false

    private let vehicle: Vehicle
    private let store: VehicleStore

    init(vehicle: Vehicle, store: VehicleStore) {
        self.vehicle = vehicle
        self.store = store
    }

    var kilometresDriven: Double? { DecimalInput.parse(kilometresText) }
    var litres: Double? { DecimalInput.parse(litresText) }
    var costZar: Double? { DecimalInput.parse(costText) }
    var lPer100Km: Double? { DecimalInput.parse(lPer100KmText) }

    /// The ONLY path a user's own keystrokes into the L/100km field can take.
    var lPer100KmEditingBinding: Binding<String> {
        Binding(
            get: { self.lPer100KmText },
            set: { newValue in
                self.lPer100KmText = newValue
                self.hasManualLPer100KmOverride = true
            }
        )
    }

    /// Runs on every change to the km or litres text.
    func recalculateLPer100Km(force: Bool = false) {
        guard force || !hasManualLPer100KmOverride else { return }
        guard let km = kilometresDriven, km > 0, let litres else {
            lPer100KmText = ""
            return
        }
        lPer100KmText = DecimalInput.format((litres / km * 100 * 100).rounded() / 100)
    }

    func recalcButtonTapped() {
        hasManualLPer100KmOverride = false
        recalculateLPer100Km(force: true)
    }

    func save() async -> Vehicle? {
        // Never save a fill-up with a number silently dropped: if anything typed
        // can't be read, say which field and keep the form open.
        let fields = [
            ("Kilometres driven", kilometresText),
            ("Litres", litresText),
            ("L/100km", lPer100KmText),
            ("Cost", costText),
        ]
        if let (name, text) = fields.first(where: { DecimalInput.isUnreadable($0.1) }) {
            errorMessage = "\(name) \"\(text)\" isn't a number. Use digits with one comma or full stop, e.g. 463,9."
            return nil
        }

        let bars = Int(barsRemaining.rounded())
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        let log = FuelLog(
            date: date,
            kilometresDriven: kilometresDriven,
            litres: litres,
            costZar: costZar,
            lPer100Km: lPer100Km,
            barsRemaining: bars == 0 ? nil : bars,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )

        // A copy, not a shared-reference mutation: if the upsert below throws,
        // nothing has touched `vehicle` or the parent screen's state.
        var updated = vehicle
        updated.logs.append(log)

        isSaving = true
        defer { isSaving = false }
        do {
            return try await store.upsertVehicle(updated)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
