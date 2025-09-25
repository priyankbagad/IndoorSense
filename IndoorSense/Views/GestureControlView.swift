// FILEPATH: IndoorSense/Views/GestureControlView.swift
import SwiftUI

struct GestureControlView: View {
    let onQuickScan: () -> Void
    let onRandomTip: () -> Void
    let debugText: String
    
    @State private var lastTapTime: TimeInterval = 0
    @State private var tapCount = 0
    
    var body: some View {
        HStack {
            // Debug text (left side)
            Text(debugText)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Gesture hint (right side)
            Text("Double tap: scan • Triple tap: tips")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .top)
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            handleGestureTap()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gesture control area")
        .accessibilityHint("Double tap to scan all features from left to right. Triple tap for exploration tips.")
        .accessibilityAction(named: "Scan Features") {
            onQuickScan()
        }
        .accessibilityAction(named: "Get Tip") {
            onRandomTip()
        }
    }
    
    private func handleGestureTap() {
        let now = CACurrentMediaTime()
        let gestureStartTime = now
        
        // Reset tap count if too much time has passed
        if now - lastTapTime > 0.5 {
            tapCount = 0
        }
        
        tapCount += 1
        lastTapTime = now
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Handle gestures with a small delay to allow for multiple taps
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let gestureDuration = CACurrentMediaTime() - gestureStartTime
            
            if now == lastTapTime { // Only execute if this was the last tap
                switch tapCount {
                case 2:
                    // Double tap: Quick scan
                    ResearchLogger.shared.logGesture(
                        gestureType: .doubleTap,
                        success: true,
                        duration: gestureDuration
                    )
                    onQuickScan()
                case 3:
                    // Triple tap: Random tip
                    ResearchLogger.shared.logGesture(
                        gestureType: .tripleTap,
                        success: true,
                        duration: gestureDuration
                    )
                    onRandomTip()
                default:
                    // Single tap: Just acknowledge
                    ResearchLogger.shared.logGesture(
                        gestureType: .singleTap,
                        success: true,
                        duration: gestureDuration
                    )
                    Accessibility.announce("Gesture area. Double tap to scan, triple tap for tips.")
                }
                tapCount = 0
            }
        }
    }
}
