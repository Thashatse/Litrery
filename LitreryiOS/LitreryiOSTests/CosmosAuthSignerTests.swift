import Testing
@testable import LitreryiOS

/// Reference values are Microsoft's own published worked example, verbatim from
/// "Access Control on Azure Cosmos DB Resources" (learn.microsoft.com), fetched at
/// implementation time rather than trusted from memory:
///
///   Verb: GET · ResourceType: "dbs" · ResourceLink: "dbs/ToDoList"
///   Date: "Thu, 27 Apr 2017 00:51:12 GMT"
///   Key:  `sampleKey` below (the docs' published sample key)
///   Output (percent-decoded): "type=master&ver=1.0&sig=c09PEVJrgp2uQRkr934kFbTqhByc7TVr3OHyqlu+c+c="
///
/// The test percent-decodes our function's output before comparing, rather than
/// asserting exact string equality against the docs' own encoded form — the docs
/// render percent-encoded hex digits lowercase (e.g. "%3d"), while Swift's
/// `addingPercentEncoding` renders them uppercase ("%3D"); both decode identically
/// per RFC 3986, so comparing the decoded form validates the actual cryptographic
/// correctness without depending on that cosmetic difference.
struct CosmosAuthSignerTests {
    private let sampleKey = "dsZQi3KtZmCv1ljt3VNWNm7sQUF1y5rJfC6kv5JiwvW0EndXdDku/dkKBp8/ufDToSxLzR4y+O/0H/t4bQtVNw==" // ggignore: Microsoft's public docs sample key, not a real account

    @Test func matchesMicrosoftPublishedWorkedExample() throws {
        let signer = CosmosAuthSigner(masterKeyBase64: sampleKey)
        let header = try signer.authorizationHeaderValue(
            verb: "GET",
            resourceType: "dbs",
            resourceLink: "dbs/ToDoList",
            utcDateRFC1123: "Thu, 27 Apr 2017 00:51:12 GMT"
        )

        let decoded = header.removingPercentEncoding
        #expect(decoded == "type=master&ver=1.0&sig=c09PEVJrgp2uQRkr934kFbTqhByc7TVr3OHyqlu+c+c=")
    }

    @Test func lowercasesVerbAndResourceTypeButNotResourceLink() throws {
        let signer = CosmosAuthSigner(masterKeyBase64: sampleKey)
        // Mixed-case verb/resourceType must sign identically to the canonical
        // lowercase form; resourceLink casing must NOT be touched (it's part of
        // the actual, case-sensitive Cosmos resource path).
        let mixedCase = try signer.authorizationHeaderValue(
            verb: "GeT",
            resourceType: "DBS",
            resourceLink: "dbs/ToDoList",
            utcDateRFC1123: "Thu, 27 Apr 2017 00:51:12 GMT"
        )
        let canonical = try signer.authorizationHeaderValue(
            verb: "GET",
            resourceType: "dbs",
            resourceLink: "dbs/ToDoList",
            utcDateRFC1123: "Thu, 27 Apr 2017 00:51:12 GMT"
        )
        #expect(mixedCase == canonical)
    }

    @Test func invalidBase64KeyThrows() {
        let signer = CosmosAuthSigner(masterKeyBase64: "not valid base64!!!")
        #expect(throws: CosmosAuthSigner.SigningError.self) {
            try signer.authorizationHeaderValue(verb: "GET", resourceType: "dbs", resourceLink: "dbs/ToDoList", utcDateRFC1123: "Thu, 27 Apr 2017 00:51:12 GMT")
        }
    }
}
