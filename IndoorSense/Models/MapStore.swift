// FILEPATH: IndoorSense/Models/MapStore.swift
import Foundation
import SwiftUI
import CoreGraphics
import Observation

/// Central model for the app.
/// Holds all decoded features and provides helpers for drawing + hit-testing.
@Observable
final class MapStore {
    // All features decoded from JSON
    var features: [Feature] = []
    
    // Bounding rectangle of all polygons in map coordinate space
    var mapRect: CGRect = .zero
    
    // MARK: - Loading JSON
    
    func loadFromBundle() throws {
        guard let url = Bundle.main.url(forResource: "features", withExtension: "json") else {
            throw NSError(domain: "IndoorSense",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "features.json not found in bundle"])
        }
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(FeatureCollection.self, from: data)
        self.features = decoded.features
        self.mapRect = Self.computeBounds(features: features)
        
        // Debug print to verify the bounds
        print("Loaded \(features.count) features")
        print("Map bounds: \(mapRect)")
        for feature in features.prefix(3) {
            print("Feature \(feature.name): \(feature.coordinates)")
        }
    }
    
    /// Compute overall bounding box of all features.
    static func computeBounds(features: [Feature]) -> CGRect {
        guard !features.isEmpty else { 
            return CGRect(x: 0, y: 0, width: 100, height: 100) 
        }
        
        var allX: [CGFloat] = []
        var allY: [CGFloat] = []
        
        for feature in features {
            for coordinate in feature.coordinates {
                guard coordinate.count >= 2 else { continue }
                allX.append(coordinate[0])
                allY.append(coordinate[1])
            }
        }
        
        guard let minX = allX.min(),
              let maxX = allX.max(),
              let minY = allY.min(),
              let maxY = allY.max()
        else {
            return CGRect(x: 0, y: 0, width: 100, height: 100)
        }
        
        // Add a small buffer to ensure features aren't right at the edge
        let bufferX = (maxX - minX) * 0.05
        let bufferY = (maxY - minY) * 0.05
        
        return CGRect(
            x: minX - bufferX, 
            y: minY - bufferY, 
            width: (maxX - minX) + (bufferX * 2), 
            height: (maxY - minY) + (bufferY * 2)
        )
    }
    
    // MARK: - Coordinate transforms
    
    /// Convert a touch point in the Canvas (screen space) to map coordinate space.
    /// This MUST match the scaling logic used in MapCanvasView for consistent hit-testing.
    func canvasToMap(_ point: CGPoint, canvasSize: CGSize) -> CGPoint {
        guard canvasSize.width > 0 && canvasSize.height > 0 && 
              mapRect.width > 0 && mapRect.height > 0 else {
            return point
        }
        
        // Use the same scaling logic as in MapCanvasView
        let padding: CGFloat = 20
        let availableWidth = canvasSize.width - (padding * 2)
        let availableHeight = canvasSize.height - (padding * 2)
        
        let scaleX = availableWidth / mapRect.width
        let scaleY = availableHeight / mapRect.height
        let scale = min(scaleX, scaleY)
        
        // Calculate the same offset used in drawing
        let scaledWidth = mapRect.width * scale
        let scaledHeight = mapRect.height * scale
        let offsetX = (canvasSize.width - scaledWidth) / 2 - (mapRect.minX * scale)
        let offsetY = (canvasSize.height - scaledHeight) / 2 - (mapRect.minY * scale)
        
        // Convert canvas point back to map coordinates
        let mapX = (point.x - offsetX) / scale
        let mapY = (point.y - offsetY) / scale
        
        return CGPoint(x: mapX, y: mapY)
    }
    
    // MARK: - Hit testing
    
    /// Find the first feature containing a given map-space point.
    func feature(at mapPoint: CGPoint) -> Feature? {
        for f in features {
            if pointInPolygon(point: mapPoint, polygon: f.coordinates) {
                return f
            }
        }
        return nil
    }
    
    /// Check if a point is within the overall floor plan area
    func isPointInFloorPlan(_ canvasPoint: CGPoint, canvasSize: CGSize) -> Bool {
        let mapPoint = canvasToMap(canvasPoint, canvasSize: canvasSize)
        
        // Use minimal tolerance to be more precise for testing
        let tolerance: CGFloat = 2.0
        let expandedRect = CGRect(
            x: mapRect.minX - tolerance,
            y: mapRect.minY - tolerance,
            width: mapRect.width + (tolerance * 2),
            height: mapRect.height + (tolerance * 2)
        )
        
        return expandedRect.contains(mapPoint)
    }
    
    /// Get features sorted by distance from a canvas point
    func featuresByDistance(from canvasPoint: CGPoint, canvasSize: CGSize) -> [(Feature, CGFloat)] {
        let mapPoint = canvasToMap(canvasPoint, canvasSize: canvasSize)
        
        return features.compactMap { feature in
            let center = calculateFeatureCenter(feature)
            let distance = sqrt(pow(mapPoint.x - center.x, 2) + pow(mapPoint.y - center.y, 2))
            return (feature, distance)
        }.sorted { $0.1 < $1.1 }
    }
    
    /// Calculate the center point of a feature
    private func calculateFeatureCenter(_ feature: Feature) -> CGPoint {
        guard !feature.coordinates.isEmpty else { return CGPoint.zero }
        
        var totalX: CGFloat = 0
        var totalY: CGFloat = 0
        var validPoints = 0
        
        for coordinate in feature.coordinates {
            guard coordinate.count >= 2 else { continue }
            totalX += coordinate[0]
            totalY += coordinate[1]
            validPoints += 1
        }
        
        guard validPoints > 0 else { return CGPoint.zero }
        
        return CGPoint(x: totalX / CGFloat(validPoints), y: totalY / CGFloat(validPoints))
    }
    
    /// Ray-casting algorithm for point-in-polygon.
    func pointInPolygon(point: CGPoint, polygon: [[CGFloat]]) -> Bool {
        guard polygon.count >= 3 else { return false }
        
        var inside = false
        var j = polygon.count - 1
        
        for i in 0..<polygon.count {
            guard polygon[i].count >= 2 && polygon[j].count >= 2 else {
                j = i
                continue
            }
            
            let xi = polygon[i][0], yi = polygon[i][1]
            let xj = polygon[j][0], yj = polygon[j][1]
            
            let intersectsY = (yi > point.y) != (yj > point.y)
            
            if intersectsY {
                let denom = (yj - yi)
                if abs(denom) > 1e-9 { // Avoid division by zero
                    let slopeX = (xj - xi) * (point.y - yi) / denom + xi
                    if point.x < slopeX {
                        inside.toggle()
                    }
                }
            }
            j = i
        }
        return inside
    }
}

// MARK: - Convenience Extensions

extension MapStore {
    /// Get a feature by ID for testing
    func feature(withID id: String) -> Feature? {
        return features.first { $0.id == id }
    }
    
    /// Get all features of a specific type
    func features(ofType type: FeatureType) -> [Feature] {
        return features.filter { $0.type == type }
    }
    
    /// Get a quick overview of the floor plan for accessibility
    func getFloorPlanOverview() -> String {
        let roomCount = features.count { $0.type == .room }
        let elevatorCount = features.count { $0.type == .elevator }
        let stairCount = features.count { $0.type == .stairs }
        let bathroomCount = features.count { $0.type == .bathroom }
        
        var overview = "Floor plan contains"
        
        if roomCount > 0 { overview += " \(roomCount) room\(roomCount == 1 ? "" : "s")" }
        if elevatorCount > 0 { overview += ", \(elevatorCount) elevator\(elevatorCount == 1 ? "" : "s")" }
        if stairCount > 0 { overview += ", \(stairCount) stair\(stairCount == 1 ? "" : "s")" }
        if bathroomCount > 0 { overview += ", \(bathroomCount) bathroom\(bathroomCount == 1 ? "" : "s")" }
        
        return overview + ". Explore by tapping and dragging across the screen."
    }
}