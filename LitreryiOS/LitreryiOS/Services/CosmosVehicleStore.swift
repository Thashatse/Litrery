import Foundation

/// Talks directly to the same Azure Cosmos DB the current MAUI app uses, over
/// Cosmos's REST API (there's no official Swift SDK). Gateway-mode HTTPS only —
/// the .NET app's `ConnectionMode.Direct` has no public/portable equivalent here.
final class CosmosVehicleStore: VehicleStore, Sendable {
    private let endpoint: URL
    private let databaseName: String
    private let containerName: String
    private let apiVersion = "2018-12-31"
    private let signer: CosmosAuthSigner
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(endpoint: URL, masterKeyBase64: String, databaseName: String = "litrery-db", containerName: String = "Vehicles", session: URLSession = .shared) {
        self.endpoint = endpoint
        self.databaseName = databaseName
        self.containerName = containerName
        self.signer = CosmosAuthSigner(masterKeyBase64: masterKeyBase64)
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(CosmosDateFormat.decode)
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom(CosmosDateFormat.encode)
        self.encoder = encoder
    }

    private var collectionLink: String {
        CosmosPaths.collectionLink(db: databaseName, container: containerName)
    }

    private var docsURL: URL {
        endpoint.appendingPathComponent(collectionLink).appendingPathComponent("docs")
    }

    func fetchVehicles() async throws -> [Vehicle] {
        var results: [Vehicle] = []
        var continuation: String?

        repeat {
            let date = DateFormatter.rfc1123.string(from: Date())
            var request = URLRequest(url: docsURL)
            request.httpMethod = "POST"
            request.setValue(date, forHTTPHeaderField: "x-ms-date")
            request.setValue(apiVersion, forHTTPHeaderField: "x-ms-version")
            request.setValue(
                try signer.authorizationHeaderValue(verb: "POST", resourceType: "docs", resourceLink: collectionLink, utcDateRFC1123: date),
                forHTTPHeaderField: "Authorization"
            )
            request.setValue("application/query+json", forHTTPHeaderField: "Content-Type")
            request.setValue("true", forHTTPHeaderField: "x-ms-documentdb-isquery")
            request.setValue("true", forHTTPHeaderField: "x-ms-documentdb-query-enablecrosspartition")
            if let continuation {
                request.setValue(continuation, forHTTPHeaderField: "x-ms-continuation")
            }
            // SELECT * FROM c is intentionally not projected/trimmed — VehicleDetailView
            // receives the already-fully-loaded Vehicle straight from this fetch, with
            // zero further network calls on drill-in. Trimming Logs out here would force
            // a new per-vehicle fetch on navigation that the current app doesn't have.
            request.httpBody = try encoder.encode(CosmosQuery(query: "SELECT * FROM c", parameters: []))

            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw CosmosError.http(status: (response as? HTTPURLResponse)?.statusCode ?? -1, body: String(data: data, encoding: .utf8) ?? "")
            }
            let page = try decoder.decode(CosmosDocumentsPage<Vehicle>.self, from: data)
            results.append(contentsOf: page.documents)
            continuation = http.value(forHTTPHeaderField: "x-ms-continuation")
        } while continuation != nil

        return results
    }

    @discardableResult
    func upsertVehicle(_ vehicle: Vehicle) async throws -> Vehicle {
        let date = DateFormatter.rfc1123.string(from: Date())
        var request = URLRequest(url: docsURL)
        request.httpMethod = "POST"
        request.setValue(date, forHTTPHeaderField: "x-ms-date")
        request.setValue(apiVersion, forHTTPHeaderField: "x-ms-version")
        request.setValue(
            try signer.authorizationHeaderValue(verb: "POST", resourceType: "docs", resourceLink: collectionLink, utcDateRFC1123: date),
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-ms-documentdb-is-upsert")
        let partitionKeyHeader = try JSONEncoder().encode([vehicle.vehicleIdentificationNumber])
        request.setValue(String(data: partitionKeyHeader, encoding: .utf8), forHTTPHeaderField: "x-ms-documentdb-partitionkey")
        request.httpBody = try encoder.encode(vehicle)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw CosmosError.http(status: (response as? HTTPURLResponse)?.statusCode ?? -1, body: String(data: data, encoding: .utf8) ?? "")
        }
        return try decoder.decode(Vehicle.self, from: data)
    }
}
