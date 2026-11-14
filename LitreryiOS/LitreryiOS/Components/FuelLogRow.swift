import SwiftUI

/// Matches the source app's per-log card precision exactly: cost 2 decimals, km
/// driven 1 decimal, litres 3 decimals (intentionally more precise than the other
/// fields — matches C#'s "{0:N3}"), L/100km 1 decimal.
struct FuelLogRow: View {
    let log: FuelLog

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Self.dateFormatter.string(from: log.date))
                    .font(.system(size: 13, weight: .bold))
                Spacer()
                Text(costText)
                    .font(.system(size: 13, weight: .bold))
            }
            HStack {
                Text(kilometresText)
                Spacer()
                Text(litresText)
            }
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            HStack {
                Text(consumptionText)
                Spacer()
                Text(barsText)
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary.opacity(0.8))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(.background.secondary))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary))
    }

    private var costText: String {
        guard let cost = log.costZar else { return "--" }
        return "R\(cost.formatted(.number.precision(.fractionLength(2))))"
    }
    private var kilometresText: String {
        guard let km = log.kilometresDriven else { return "-- km" }
        return "\(km.formatted(.number.precision(.fractionLength(1)))) km"
    }
    private var litresText: String {
        guard let litres = log.litres else { return "-- L" }
        return "\(litres.formatted(.number.precision(.fractionLength(3)))) L"
    }
    private var consumptionText: String {
        guard let value = log.lPer100Km else { return "-- L/100km" }
        return "\(value.formatted(.number.precision(.fractionLength(1)))) L/100km"
    }
    private var barsText: String {
        guard let bars = log.barsRemaining else { return "not recorded" }
        return "\(bars)/10 bars"
    }
}
