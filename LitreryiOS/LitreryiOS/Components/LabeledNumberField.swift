import SwiftUI

/// Reads numbers the way people actually type them, with either "," or "." as the
/// decimal separator, independent of the device's locale or number-format settings.
///
/// Why this exists instead of `TextField(value:format:)`: fill-ups typed on a
/// South African phone ("463,9", "35,7", "929,98") were saved with km, litres and
/// cost all missing, while a plain "8" survived. Locale-driven parsing has two ways
/// to lose a value silently: the parse rules can disagree with the decimal key the
/// keyboard shows (the keyboard follows the user's number-format override, the parse
/// style may not), and on some iOS versions a value-bound field only commits on
/// Return, which a decimal pad doesn't have. Binding the field to its raw text and
/// parsing it here removes both.
enum DecimalInput {
    private static let separators: Set<Character> = [",", "."]

    /// Returns nil for empty or unreadable text. The LAST "," or "." is the decimal
    /// separator; the other kind before it is treated as digit grouping
    /// ("1,056.25" and "1.056,25" both read as 1056.25). Spaces and apostrophes,
    /// used for grouping in some locales, are ignored. Text that repeats the
    /// decimal separator ("35,7929,98") is rejected rather than guessed at.
    static func parse(_ text: String) -> Double? {
        let cleaned = text.filter { !$0.isWhitespace && $0 != "'" && $0 != "’" }
        guard !cleaned.isEmpty else { return nil }

        guard let decimalIndex = cleaned.lastIndex(where: separators.contains) else {
            return isDigits(cleaned) ? Double(cleaned) : nil
        }
        let decimalSeparator = cleaned[decimalIndex]
        let wholePart = cleaned[..<decimalIndex]
        let fraction = cleaned[cleaned.index(after: decimalIndex)...]

        guard !wholePart.contains(decimalSeparator) else { return nil }
        let whole = wholePart.filter { !separators.contains($0) }
        guard isDigits(whole), isDigits(fraction), !(whole.isEmpty && fraction.isEmpty) else { return nil }
        return Double("\(whole.isEmpty ? "0" : whole).\(fraction.isEmpty ? "0" : String(fraction))")
    }

    /// Whole numbers such as an odometer reading. Any spaces, apostrophes, commas or
    /// full stops are treated as grouping ("26 688", "26,688" and "26.688" all read
    /// as 26688).
    static func parseInteger(_ text: String) -> Int? {
        let digits = text.filter { !$0.isWhitespace && $0 != "'" && $0 != "’" && !separators.contains($0) }
        guard !digits.isEmpty, isDigits(digits) else { return nil }
        return Int(digits)
    }

    /// Display text for a value the app fills in itself, in the device's own style.
    /// Never grouped, so it always reads back through `parse` unchanged.
    static func format(_ value: Double, maxFractionDigits: Int = 2) -> String {
        value.formatted(.number.precision(.fractionLength(0...maxFractionDigits)).grouping(.never))
    }

    /// True when the user typed something that can't be read as a number. Empty text
    /// is not an error, because every numeric fill-up field is optional.
    static func isUnreadable(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parse(text) == nil
    }

    private static func isDigits<S: StringProtocol>(_ text: S) -> Bool {
        text.allSatisfy { $0.isASCII && $0.isNumber }
    }
}

/// A captioned decimal field bound to the raw text the user typed. The view model
/// reads the number with `DecimalInput.parse`, so every keystroke is captured, even
/// if Save is tapped while the field still has focus.
struct LabeledDecimalField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
        }
    }
}

/// A captioned whole-number field bound to raw text; see `DecimalInput.parseInteger`.
struct LabeledIntegerField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
        }
    }
}
