import Foundation

struct CosmosQuery: Encodable {
    let query: String
    let parameters: [String]
}

struct CosmosDocumentsPage<T: Decodable>: Decodable {
    let documents: [T]

    enum CodingKeys: String, CodingKey {
        case documents = "Documents"
    }
}

enum CosmosError: Error, LocalizedError {
    case http(status: Int, body: String)
    case missingCredentials

    var errorDescription: String? {
        switch self {
        case .http(let status, let body):
            return "Cosmos request failed (\(status)): \(body)"
        case .missingCredentials:
            return "No Cosmos key found in Keychain."
        }
    }
}
