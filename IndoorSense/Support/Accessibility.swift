// FILEPATH: IndoorSense/Support/Accessibility.swift
import UIKit
import SwiftUI

/// Helper for accessibility announcements and VoiceOver integration
struct Accessibility {
    
    /// Post an accessibility announcement that VoiceOver will speak
    static func announce(_ text: String) {
        guard !text.isEmpty else { return }
        
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }
    
    /// Announce with interruption (stops current announcement)
    static func announceWithInterruption(_ text: String) {
        guard !text.isEmpty else { return }
        
        DispatchQueue.main.async {
            // First stop any current announcement
            UIAccessibility.post(notification: .announcement, argument: "")
            // Then post the new one
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }
    
    /// Check if VoiceOver is currently running
    static var isVoiceOverRunning: Bool {
        return UIAccessibility.isVoiceOverRunning
    }
    
    /// Check if any assistive technology is running
    static var isAssistiveTechRunning: Bool {
        return UIAccessibility.isVoiceOverRunning || 
               UIAccessibility.isSwitchControlRunning ||
               UIAccessibility.isAssistiveTouchRunning
    }
    
    /// Generate contextual help text for the current feature
    static func contextualHelp(for feature: Feature) -> String {
        switch feature.type {
        case .room:
            return "\(feature.name). Room. Double tap to get more information."
        case .corridor:
            return "\(feature.name). Corridor connecting different areas."
        case .elevator:
            return "\(feature.name). Elevator for vertical transportation."
        case .stairs:
            return "\(feature.name). Stairs for vertical movement."
        case .bathroom:
            return "\(feature.name). Restroom facility."
        case .landmark:
            return "\(feature.name). Notable landmark for navigation reference."
        }
    }
    
    /// Generate directional guidance
    static func directionalGuidance(from currentPoint: CGPoint, to targetPoint: CGPoint) -> String {
        let deltaX = targetPoint.x - currentPoint.x
        let deltaY = targetPoint.y - currentPoint.y
        
        let angle = atan2(deltaY, deltaX) * 180 / .pi
        let normalizedAngle = angle < 0 ? angle + 360 : angle
        
        let direction: String
        switch normalizedAngle {
        case 0..<22.5, 337.5...360:
            direction = "right"
        case 22.5..<67.5:
            direction = "down and right"
        case 67.5..<112.5:
            direction = "down"
        case 112.5..<157.5:
            direction = "down and left"
        case 157.5..<202.5:
            direction = "left"
        case 202.5..<247.5:
            direction = "up and left"
        case 247.5..<292.5:
            direction = "up"
        case 292.5..<337.5:
            direction = "up and right"
        default:
            direction = "nearby"
        }
        
        return direction
    }
    
    /// Generate exploration tips for blind users
    static func explorationTips() -> [String] {
        return [
            "Tap and hold to hear the name of features under your finger.",
            "Drag your finger across the screen to explore different areas.",
            "Use the scan button to get an overview of all features from left to right.",
            "Use the overview button to hear a summary of the entire floor plan.",
            "Enable haptics in settings to feel different vibrations for different feature types.",
            "Enable tones to hear different sounds for rooms, elevators, and other features."
        ]
    }
    
    /// Get a random exploration tip
    static func randomTip() -> String {
        let tips = explorationTips()
        return tips.randomElement() ?? "Explore by tapping and dragging across the screen."
    }
}