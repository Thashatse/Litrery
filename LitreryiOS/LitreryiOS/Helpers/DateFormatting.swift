import Foundation

/// Cosmos DB's stored `FuelLog.Date` strings turned out NOT to be one consistent
/// shape — inspecting the real litrery-db data (see the plan's verification step 0)
/// found at least two variants in practice, depending on how the original C#
/// `DateTime.Kind` was set when each entry was written:
///   - Unspecified, no fractional seconds:      "2026-04-11T00:00:00"
///   - Local/UTC, with offset and microseconds: "2026-05-02T09:19:23.884681+02:00"
/// so decoding tries several formats, most-specific first, rather than assuming a
/// single shape. New writes from this app always use the simplest form (no
/// fraction, no offset) to match the app's own "combined local date+time, no real
/// timezone semantics" model — the same as the source MAUI app's DatePicker +
/// TimePicker combination.
enum CosmosDateFormat {
    private static func makeFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = format
        return f
    }

    // Ordered most-specific first so a shorter pattern doesn't partially match a
    // longer string. XXX matches an ISO8601 colon-separated offset like "+02:00".
    private static let decodeFormatters: [DateFormatter] = [
        makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX"),
        makeFormatter("yyyy-MM-dd'T'HH:mm:ssXXX"),
        makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"),
        makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSS"),
        makeFormatter("yyyy-MM-dd'T'HH:mm:ss"),
    ]

    private static let encodeFormatter = makeFormatter("yyyy-MM-dd'T'HH:mm:ss")

    static func decode(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        for formatter in decodeFormatters {
            if let date = formatter.date(from: string) { return date }
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized Cosmos date format: \(string)")
    }

    static func encode(_ date: Date, to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(encodeFormatter.string(from: date))
    }
}

extension DateFormatter {
    /// RFC1123, required for both the Cosmos `x-ms-date` header and the string that gets signed.
    static let rfc1123: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "GMT")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        return f
    }()
}
