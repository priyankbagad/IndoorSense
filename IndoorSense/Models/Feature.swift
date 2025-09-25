// FILEPATH: IndoorSense/Models/Feature.swift
import Foundation
import CoreGraphics

/// The finite set of feature types in our indoor map.
/// Matches the `type` strings in features.json.
enum FeatureType: String, Codable, CaseIterable {
  case room, corridor, elevator, stairs, bathroom, landmark
}

/// Represents one indoor feature (a polygon with an id, name, and type).
struct Feature: Codable, Identifiable, Equatable {
  let id: String
  let type: FeatureType
  let name: String
  let coordinates: [[CGFloat]] // array of [x, y] points forming a polygon

  // Convenience: leftmost X for ordering
  var minX: CGFloat {
    coordinates.map { $0[0] }.min() ?? 0
  }
}

/// Wraps the top-level JSON object.
struct FeatureCollection: Codable, Equatable {
  let features: [Feature]
}
