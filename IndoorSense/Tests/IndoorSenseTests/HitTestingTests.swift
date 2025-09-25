// FILEPATH: IndoorSenseTests/HitTestingTests.swift
import XCTest
@testable import IndoorSense

final class HitTestingTests: XCTestCase {
  func testPointInPolygon() {
    let store = MapStore()
    let square = Feature(
      id: "sq",
      type: .room,
      name: "Square",
      coordinates: [[0,0],[0,10],[10,10],[10,0]]
    )
    store.features = [square]
    store.mapRect = MapStore.computeBounds(features: store.features)

    let inside = store.pointInPolygon(point: CGPoint(x: 5, y: 5), polygon: square.coordinates)
    let outside = store.pointInPolygon(point: CGPoint(x: 50, y: 50), polygon: square.coordinates)

    XCTAssertTrue(inside)
    XCTAssertFalse(outside)
  }

  func testFeatureAtPoint() {
    let store = MapStore()
    let room = Feature(id: "r", type: .room, name: "R", coordinates: [[0,0],[0,20],[20,20],[20,0]])
    let elev = Feature(id: "e", type: .elevator, name: "E", coordinates: [[30,0],[40,0],[40,10],[30,10]])
    store.features = [room, elev]
    store.mapRect = MapStore.computeBounds(features: store.features)

    XCTAssertEqual(store.feature(at: CGPoint(x: 10, y: 10))?.id, "r")
    XCTAssertEqual(store.feature(at: CGPoint(x: 35, y: 5))?.id, "e")
    XCTAssertNil(store.feature(at: CGPoint(x: 25, y: 25)))
  }
}
