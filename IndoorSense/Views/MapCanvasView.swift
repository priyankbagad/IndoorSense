// FILEPATH: IndoorSense/Views/MapCanvasView.swift
import SwiftUI

struct MapCanvasView: View {
    @Environment(MapStore.self) private var store
    
    @Binding var debugText: String
    @Binding var speakEnabled: Bool
    @Binding var tonesEnabled: Bool
    @Binding var hapticsEnabled: Bool
    
    // Debounce so we don't spam audio while tracing
    @State private var lastFeatureID: String?
    @State private var lastFeedbackTime: TimeInterval = 0
    private let cooldown: TimeInterval = 0.30
    
    // Research logging
    @State private var touchStartTime: TimeInterval = 0
    @State private var discoveredFeatures: Set<String> = []
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // Ensure we have a valid size
                guard size.width > 0 && size.height > 0 else { return }
                
                let (scale, offset) = computeScaleAndOffset(canvasSize: size, mapRect: store.mapRect)
                
                // Draw features (shapes)
                for f in store.features {
                    let path = makePath(for: f, scale: scale, offset: offset, canvasSize: size)
                    let color = colorFor(type: f.type)
                    
                    // Fill with transparency
                    context.fill(path, with: .color(color.opacity(0.3)))
                    // Stroke with solid color
                    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2.5))
                    
                    // Add text labels for features
                    drawLabel(for: f, context: context, scale: scale, offset: offset, size: size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .clipped()
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Record touch start time for duration calculation
                    if touchStartTime == 0 {
                        touchStartTime = Date().timeIntervalSince1970
                    }
                    handleTouch(at: value.location, canvasSize: geo.size, isDrag: true)
                }
                .onEnded { value in
                    let touchDuration = Date().timeIntervalSince1970 - touchStartTime
                    handleTouch(at: value.location, canvasSize: geo.size, isDrag: false, duration: touchDuration)
                    
                    // Stop haptic patterns when user lifts finger
                    if hapticsEnabled {
                        Haptics.shared.stopAllPatterns()
                    }
                    
                    // Reset for next touch
                    lastFeatureID = nil
                    touchStartTime = 0
                }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityHidden(true)
        }
    }
    
    // MARK: - Drawing helpers
    
    private func computeScaleAndOffset(canvasSize: CGSize, mapRect: CGRect) -> (scale: CGFloat, offset: CGPoint) {
        guard mapRect.width > 0 && mapRect.height > 0 else {
            return (1.0, CGPoint.zero)
        }
        
        let padding: CGFloat = 20
        let availableWidth = canvasSize.width - (padding * 2)
        let availableHeight = canvasSize.height - (padding * 2)
        
        let scaleX = availableWidth / mapRect.width
        let scaleY = availableHeight / mapRect.height
        let scale = min(scaleX, scaleY)
        
        let scaledWidth = mapRect.width * scale
        let scaledHeight = mapRect.height * scale
        let offsetX = (canvasSize.width - scaledWidth) / 2 - (mapRect.minX * scale)
        let offsetY = (canvasSize.height - scaledHeight) / 2 - (mapRect.minY * scale)
        
        return (scale, CGPoint(x: offsetX, y: offsetY))
    }
    
    private func toCanvas(_ point: [CGFloat], scale: CGFloat, offset: CGPoint, canvasSize: CGSize) -> CGPoint {
        let x = point[0] * scale + offset.x
        let y = point[1] * scale + offset.y
        return CGPoint(x: x, y: y)
    }
    
    private func makePath(for f: Feature, scale: CGFloat, offset: CGPoint, canvasSize: CGSize) -> Path {
        var path = Path()
        guard let firstPoint = f.coordinates.first, firstPoint.count >= 2 else { return path }
        
        let startPoint = toCanvas(firstPoint, scale: scale, offset: offset, canvasSize: canvasSize)
        path.move(to: startPoint)
        
        for coordinate in f.coordinates.dropFirst() {
            guard coordinate.count >= 2 else { continue }
            let canvasPoint = toCanvas(coordinate, scale: scale, offset: offset, canvasSize: canvasSize)
            path.addLine(to: canvasPoint)
        }
        
        path.closeSubpath()
        return path
    }
    
    private func drawLabel(for feature: Feature, context: GraphicsContext, scale: CGFloat, offset: CGPoint, size: CGSize) {
        let centerPoint = calculateCenter(for: feature)
        let canvasCenter = toCanvas([centerPoint.x, centerPoint.y], scale: scale, offset: offset, canvasSize: size)
        
        let fontSize = fontSizeForFeature(feature, scale: scale)
        let font = Font.system(size: fontSize, weight: .medium)
        
        let displayText = getDisplayText(for: feature, fontSize: fontSize)
        
        var textContext = context
        textContext.addFilter(.shadow(color: .black.opacity(0.3), radius: 1, x: 0.5, y: 0.5))
        
        let textSize = estimateTextSize(displayText, fontSize: fontSize)
        let backgroundRect = CGRect(
            x: canvasCenter.x - textSize.width / 2 - 4,
            y: canvasCenter.y - textSize.height / 2 - 2,
            width: textSize.width + 8,
            height: textSize.height + 4
        )
        
        textContext.fill(
            Path(roundedRect: backgroundRect, cornerRadius: 4),
            with: .color(.white.opacity(0.8))
        )
        
        textContext.draw(
            Text(displayText)
                .font(font)
                .foregroundColor(.black),
            at: canvasCenter,
            anchor: .center
        )
    }
    
    private func calculateCenter(for feature: Feature) -> CGPoint {
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
    
    private func fontSizeForFeature(_ feature: Feature, scale: CGFloat) -> CGFloat {
        let baseSize: CGFloat
        
        switch feature.type {
        case .room:
            baseSize = 12
        case .corridor:
            baseSize = 10
        case .elevator, .stairs, .bathroom:
            baseSize = 9
        case .landmark:
            baseSize = 11
        }
        
        let scaledSize = baseSize * sqrt(scale)
        return min(max(scaledSize, 8), 16)
    }
    
    private func getDisplayText(for feature: Feature, fontSize: CGFloat) -> String {
        let name = feature.name
        
        if fontSize < 10 {
            switch feature.type {
            case .room:
                return name.components(separatedBy: " ").first ?? name
            case .elevator:
                return "ELV"
            case .stairs:
                return "STR"
            case .bathroom:
                return "WC"
            case .corridor:
                return ""
            case .landmark:
                return String(name.prefix(6))
            }
        }
        
        return String(name.prefix(12))
    }
    
    private func estimateTextSize(_ text: String, fontSize: CGFloat) -> CGSize {
        let avgCharWidth = fontSize * 0.6
        let width = CGFloat(text.count) * avgCharWidth
        let height = fontSize * 1.2
        return CGSize(width: width, height: height)
    }
    
    private func colorFor(type: FeatureType) -> Color {
        switch type {
        case .room:     return .blue
        case .corridor: return .gray
        case .elevator: return .orange
        case .stairs:   return .purple
        case .bathroom: return .teal
        case .landmark: return .pink
        }
    }
    
    // MARK: - Touch handling + feedback with Research Logging
    
    private func handleTouch(at canvasPoint: CGPoint, canvasSize: CGSize, isDrag: Bool, duration: TimeInterval? = nil) {
        let mapPt = store.canvasToMap(canvasPoint, canvasSize: canvasSize)
        
        if let f = store.feature(at: mapPt) {
            debugText = "On: \(f.name) (\(f.type.rawValue))"
            let now = CACurrentMediaTime()
            
            // Log interaction for research
            let isNewDiscovery = !discoveredFeatures.contains(f.id)
            if isNewDiscovery {
                discoveredFeatures.insert(f.id)
            }
            
            ResearchLogger.shared.logInteraction(
                canvasPoint: canvasPoint,
                featureID: f.id,
                featureName: f.name,
                featureType: f.type,
                interactionType: isNewDiscovery ? .featureDiscovery : .featureRevisit,
                duration: duration
            )
            
            if f.id != lastFeatureID && (now - lastFeedbackTime) > cooldown {
                lastFeatureID = f.id
                lastFeedbackTime = now
                
                // Existing feedback logic
                Accessibility.announce(f.name)
                if speakEnabled { SpeechAnnouncer.shared.say(f.name) }
                if tonesEnabled { TonePlayer.shared.play(for: f.type) }
                if hapticsEnabled { Haptics.shared.bump(for: f.type) }
            }
        } else {
            // User touched outside any feature
            debugText = "Outside floor plan"
            lastFeatureID = nil
            
            // Log outside touch for research
            ResearchLogger.shared.logInteraction(
                canvasPoint: canvasPoint,
                featureID: nil,
                featureName: nil,
                featureType: nil,
                interactionType: .outsideTouch,
                duration: duration
            )
            
            let outsideMessage = generateOutsideMessage(canvasPoint: canvasPoint, canvasSize: canvasSize)
            
            Accessibility.announce(outsideMessage)
            if speakEnabled { 
                SpeechAnnouncer.shared.say(outsideMessage) 
            }
            
            if hapticsEnabled {
                Haptics.shared.outsidePlan()
            }
        }
    }
    
    private func generateOutsideMessage(canvasPoint: CGPoint, canvasSize: CGSize) -> String {
        let x = canvasPoint.x / canvasSize.width
        let y = canvasPoint.y / canvasSize.height
        
        var direction = ""
        if x < 0.33 { direction += "left " }
        else if x > 0.67 { direction += "right " }
        else { direction += "center " }
        
        if y < 0.33 { direction += "top" }
        else if y > 0.67 { direction += "bottom" }
        else { direction += "middle" }
        
        let nearestFeatures = findNearestFeatures(to: canvasPoint, canvasSize: canvasSize, limit: 2)
        
        if nearestFeatures.isEmpty {
            return "Outside floor plan in \(direction) area. Try exploring the center of the screen to find features."
        } else {
            let featureNames = nearestFeatures.map { $0.name }.joined(separator: " or ")
            return "Outside floor plan in \(direction) area. Move toward center to find \(featureNames)."
        }
    }
    
    private func findNearestFeatures(to canvasPoint: CGPoint, canvasSize: CGSize, limit: Int) -> [Feature] {
        let (scale, offset) = computeScaleAndOffset(canvasSize: canvasSize, mapRect: store.mapRect)
        
        let featuresWithDistance = store.features.compactMap { feature -> (Feature, CGFloat)? in
            let center = calculateCenter(for: feature)
            let canvasCenter = toCanvas([center.x, center.y], scale: scale, offset: offset, canvasSize: canvasSize)
            
            let distance = sqrt(pow(canvasPoint.x - canvasCenter.x, 2) + pow(canvasPoint.y - canvasCenter.y, 2))
            return (feature, distance)
        }
        
        return featuresWithDistance
            .sorted { $0.1 < $1.1 }
            .prefix(limit)
            .map { $0.0 }
    }
}