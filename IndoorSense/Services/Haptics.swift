// FILEPATH: IndoorSense/Services/Haptics.swift
import UIKit

final class Haptics {
    static let shared = Haptics()
    
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notif = UINotificationFeedbackGenerator()
    
    // For continuous/pulsing patterns
    private var continuousTimer: Timer?
    private var pulseTimer: Timer?
    
    private init() {
        // Prime generators to reduce first-use latency
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notif.prepare()
    }
    
    func bump(for type: FeatureType) {
        // Stop any ongoing patterns first
        stopContinuousPatterns()
        
        switch type {
        case .corridor:
            startContinuousVibration()
        case .room:
            medium.impactOccurred()
        case .elevator:
            notif.notificationOccurred(.success)
        case .stairs:
            heavy.impactOccurred()
        case .bathroom:
            notif.notificationOccurred(.warning)
        case .landmark:
            smoothStrongVibration()
        }
    }
    
    // MARK: - Specific Haptic Patterns
    
    /// Continuous vibration for corridors (as specified in requirements)
    private func startContinuousVibration() {
        light.impactOccurred()
        
        continuousTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.light.impactOccurred(intensity: 0.3)
        }
        
        // Stop after 2 seconds to avoid battery drain
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.stopContinuousPatterns()
        }
    }
    
    /// Pulsing vibration for intersections/junctions
    /// Note: In your current data, you don't have explicit "intersections" but this could be used
    /// for areas where multiple corridors meet or special junction points
    private func startPulsingVibration() {
        var pulseCount = 0
        
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            self?.medium.impactOccurred(intensity: 0.7)
            pulseCount += 1
            
            if pulseCount >= 6 { // 6 pulses over ~1.8 seconds
                timer.invalidate()
            }
        }
    }
    
    /// Smooth-strong vibration for landmarks (as specified in requirements)
    private func smoothStrongVibration() {
        // Initial strong impact
        heavy.impactOccurred(intensity: 1.0)
        
        // Follow with a smooth fade-out pattern
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.medium.impactOccurred(intensity: 0.8)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.medium.impactOccurred(intensity: 0.6)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.light.impactOccurred(intensity: 0.4)
        }
    }
    
    /// Stop all continuous patterns
    private func stopContinuousPatterns() {
        continuousTimer?.invalidate()
        continuousTimer = nil
        pulseTimer?.invalidate()
        pulseTimer = nil
    }
    
    /// Call this when user lifts finger or moves to different area
    func stopAllPatterns() {
        stopContinuousPatterns()
    }
    
    // MARK: - Additional Utility Methods
    
    /// Light tap for UI feedback (like gesture acknowledgment)
    func lightTap() {
        light.impactOccurred(intensity: 0.5)
    }
    
    /// Success feedback for completed actions
    func success() {
        notif.notificationOccurred(.success)
    }
    
    /// Error feedback for failed actions
    func error() {
        notif.notificationOccurred(.error)
    }
    
    /// Custom pattern for "outside floor plan" feedback
    func outsidePlan() {
        // Double light tap to indicate "nothing here"
        light.impactOccurred(intensity: 0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.light.impactOccurred(intensity: 0.3)
        }
    }
}