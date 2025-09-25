// FILEPATH: IndoorSenseTests/JSONParsingTests.swift
import XCTest
@testable import IndoorSense

final class JSONParsingTests: XCTestCase {
  func testDecodeFeatureCollectionFromString() throws {
    // Keep tests self-contained: decode from a string literal (no bundle files needed)
    let json = """
    {
      "features": [
        {
          "id":"a",
          "type":"room",
          "name":"A",
          "coordinates": [[0,0],[0,10],[10,10],[10,0]]
        },
        {
          "id":"b",
          "type":"elevator",
          "name":"Elevator",
          "coordinates": [[20,0],[25,0],[25,10],[20,10]]
        }
      ]
    }
    """
    let data = Data(json.utf8)
    let decoded = try JSONDecoder().decode(FeatureCollection.self, from: data)
    XCTAssertEqual(decoded.features.count, 2)
    XCTAssertTrue(decoded.features.contains { $0.type == .elevator })
  }
}
