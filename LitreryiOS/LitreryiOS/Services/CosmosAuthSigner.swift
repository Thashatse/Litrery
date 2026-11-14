import CryptoKit
import Foundation

/// Signs requests for Azure Cosmos DB's REST API using a master key. There is no
/// official Cosmos DB SDK for Swift, so this reimplements the signing scheme the
/// .NET SDK (`Microsoft.Azure.Cosmos`) handles internally.
///
/// Reference worked example (verified against Microsoft's published Cosmos DB REST
/// API authorization documentation): see LitreryiOSTests/CosmosAuthSignerTests.swift.
struct CosmosAuthSigner: Sendable {
    let masterKeyBase64: String

    enum SigningError: Error {
        case invalidKey
    }

    /// - Parameters:
    ///   - verb: HTTP method, e.g. "GET" or "POST".
    ///   - resourceType: Cosmos resource type, e.g. "docs" or "dbs".
    ///   - resourceLink: the collection link (`dbs/<db>/colls/<container>`) for feed
    ///     operations, or the document link (`.../docs/<id>`) for point operations.
    ///     Case-sensitive — must NOT be lowercased.
    ///   - utcDateRFC1123: the exact string also sent as the `x-ms-date` header.
    func authorizationHeaderValue(verb: String, resourceType: String, resourceLink: String, utcDateRFC1123: String) throws -> String {
        guard let keyData = Data(base64Encoded: masterKeyBase64) else {
            throw SigningError.invalidKey
        }

        // Five newline-joined fields; the 5th is always empty (reserved).
        let stringToSign = [
            verb.lowercased(),
            resourceType.lowercased(),
            resourceLink,
            utcDateRFC1123.lowercased(),
            "",
        ].joined(separator: "\n") + "\n"

        let mac = HMAC<SHA256>.authenticationCode(for: Data(stringToSign.utf8), using: SymmetricKey(data: keyData))
        let signatureBase64 = Data(mac).base64EncodedString()

        let raw = "type=master&ver=1.0&sig=\(signatureBase64)"
        // The ENTIRE string (including the type=/ver=/sig= delimiters) is percent-encoded
        // using encodeURIComponent's unreserved set. `.urlQueryAllowed` is more permissive
        // than that and would leave characters unescaped that Cosmos expects encoded.
        let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")
        return raw.addingPercentEncoding(withAllowedCharacters: unreserved) ?? raw
    }
}

enum CosmosPaths {
    static func collectionLink(db: String, container: String) -> String {
        "dbs/\(db)/colls/\(container)"
    }

    static func documentLink(db: String, container: String, docId: String) -> String {
        "dbs/\(db)/colls/\(container)/docs/\(docId)"
    }
}
