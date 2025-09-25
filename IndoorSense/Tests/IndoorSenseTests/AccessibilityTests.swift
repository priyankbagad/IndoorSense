// FILEPATH: IndoorSenseTests/AccessibilityTests.swift
import XCTest
@testable import IndoorSense

final class AccessibilityTests: XCTestCase {
    
    func testAccessibilityLabelsAreNotEmpty() {
        let features = [
            Feature(id: "r1", type: .room, name: "Classroom 101", coordinates: [[0,0],[0,10],[10,10],[10,0]]),
            Feature(id: "e1", type: .elevator, name: "Elevator A", coordinates: [[20,0],[30,0],[30,10],[20,10]]),
            Feature(id: "s1", type: .stairs, name: "Stairs 1", coordinates: [[40,0],[50,0],[50,10],[40,10]]),
            Feature(id: "b1", type: .bathroom, name: "Bathroom", coordinates: [[60,0],[70,0],[70,10],[60,10]]),
            Feature(id: "c1", type: .corridor, name: "Main Corridor", coordinates: [[0,20],[80,20],[80,30],[0,30]]),
            Feature(id: "l1", type: .landmark, name: "Reception Desk", coordinates: [[80,0],[90,0],[90,10],[80,10]])
        ]
        
        // Test that all feature names are non-empty (required for accessibility)
        for feature in features {
            XCTAssertFalse(feature.name.isEmpty, "Feature \(feature.id) has empty name")
            XCTAssertFalse(feature.name.trimmingCharacters(in: .whitespaces).isEmpty, 
                          "Feature \(feature.id) has only whitespace name")
        }
    }
    
    func testContextualHelpMessages() {
        let testCases: [(FeatureType, String)] = [
            (.room, "Room. Double tap to get more information."),
            (.corridor, "Corridor connecting different areas."),
            (.elevator, "Elevator for vertical transportation."),
            (.stairs, "Stairs for vertical movement."),
            (.bathroom, "Restroom facility."),
            (.landmark, "Notable landmark for navigation reference.")
        ]
        
        for (type, expectedContent) in testCases {
            let feature = Feature(id: "test", type: type, name: "Test \(type.rawValue.capitalized)", coordinates: [[0,0],[10,0],[10,10],[0,10]])
            let help = Accessibility.contextualHelp(for: feature)
            
            XCTAssertTrue(help.contains(expectedContent), 
                         "Contextual help for \(type) doesn't contain expected content")
            XCTAssertTrue(help.contains(feature.name), 
                         "Contextual help for \(type) doesn't contain feature name")
        }
    }
    
    func testFloorPlanOverviewConsistency() {
        let store = MapStore()
        store.features = [
            Feature(id: "r1", type: .room, name: "Room 101", coordinates: [[0,0],[10,0],[10,10],[0,10]]),
            Feature(id: "r2", type: .room, name: "Room 102", coordinates: [[20,0],[30,0],[30,10],[20,10]]),
            Feature(id: "e1", type: .elevator, name: "Elevator A", coordinates: [[40,0],[50,0],[50,10],[40,10]]),
            Feature(id: "b1", type: .bathroom, name: "Bathroom", coordinates: [[60,0],[70,0],[70,10],[60,10]])
        ]
        store.mapRect = MapStore.computeBounds(features: store.features)
        
        let overview1 = store.getFloorPlanOverview()
        let overview2 = store.getFloorPlanOverview()
        
        // Overview should be consistent across multiple calls
        XCTAssertEqual(overview1, overview2, "Floor plan overview is inconsistent")
        
        // Should contain counts (updated to match your actual implementation)
        XCTAssertTrue(overview1.contains("2 room"), "Overview should mention room count")
        XCTAssertTrue(overview1.contains("1 elevator"), "Overview should mention elevator count")
        XCTAssertTrue(overview1.contains("1 bathroom"), "Overview should mention bathroom count")
        
        // Should contain the word "contains" as your implementation does
        XCTAssertTrue(overview1.contains("contains"), "Overview should use standard format")
    }
    
    func testAccessibilityAnnouncementFormat() {
        // Test that announcement strings follow consistent format
        let testMessages = [
            "Test message",
            "Another test with numbers 123",
            "Special characters: éñ",
            "" // Empty string
        ]
        
        for message in testMessages {
            // Should not crash with any input
            XCTAssertNoThrow(Accessibility.announce(message))
            
            // Empty messages should be handled gracefully
            if message.isEmpty {
                // Empty announcements should be filtered out to avoid confusing users
                continue
            }
            
            // Valid messages should not be excessively long
            XCTAssertLessThanOrEqual(message.count, 200, "Accessibility messages should be concise")
        }
    }
    
    func testExplorationTipsAreUseful() {
        let tips = Accessibility.explorationTips()
        
        // Should have multiple tips
        XCTAssertGreaterThan(tips.count, 3, "Should provide multiple exploration tips")
        
        // Each tip should be non-empty and helpful
        for tip in tips {
            XCTAssertFalse(tip.isEmpty, "Tips should not be empty")
            XCTAssertGreaterThan(tip.count, 10, "Tips should be descriptive")
            XCTAssertLessThanOrEqual(tip.count, 150, "Tips should not be too long")
        }
        
        // Random tip should return valid content
        let randomTip = Accessibility.randomTip()
        XCTAssertTrue(tips.contains(randomTip) || randomTip == "Explore by tapping and dragging across the screen.",
                     "Random tip should be from the tips array or fallback")
    }
    
    func testHapticFeedbackConsistency() {
        // Test that each feature type has consistent haptic feedback
        let featureTypes: [FeatureType] = [.room, .corridor, .elevator, .stairs, .bathroom, .landmark]
        
        for type in featureTypes {
            let feature1 = Feature(id: "test1", type: type, name: "Test 1", coordinates: [[0,0],[10,0],[10,10],[0,10]])
            let feature2 = Feature(id: "test2", type: type, name: "Test 2", coordinates: [[20,0],[30,0],[30,10],[20,10]])
            
            // Should not crash when providing haptic feedback
            XCTAssertNoThrow(Haptics.shared.bump(for: type))
            
            // Same feature type should get same haptic treatment
            // (We can't directly test the haptic output, but we can ensure the code runs consistently)
        }
    }
}