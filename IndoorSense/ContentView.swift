import SwiftUI
import Observation

struct ContentView: View {
    @Environment(MapStore.self) private var store
    
    @State private var speakEnabled = true
    @State private var tonesEnabled = false
    @State private var hapticsEnabled = true
    @State private var debug = "Ready"
    @State private var hasAnnouncedOverview = false
    
    // Simple export management
    @StateObject private var exportManager = QuickExportManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with export button
                    HUDView(
                        title: "IndoorSense",
                        speakEnabled: $speakEnabled,
                        tonesEnabled: $tonesEnabled,
                        hapticsEnabled: $hapticsEnabled,
                        onOverview: announceOverview,
                        onQuickExport: handleQuickExport
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    // Map takes most space
                    MapCanvasView(
                        debugText: $debug,
                        speakEnabled: $speakEnabled,
                        tonesEnabled: $tonesEnabled,
                        hapticsEnabled: $hapticsEnabled
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Gesture control area
                    GestureControlView(
                        onQuickScan: quickScan,
                        onRandomTip: announceRandomTip,
                        debugText: debug
                    )
                }
                
                // Loading overlay during export
                if exportManager.isExporting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Preparing data export...")
                                .foregroundColor(.white)
                                .padding(.top, 16)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
            }
        }
        .onAppear {
            SpeechAnnouncer.shared.alwaysSpeak = speakEnabled
            
            if !hasAnnouncedOverview {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    announceInitialOverview()
                }
            }
        }
        .onChange(of: speakEnabled) { _, v in 
            SpeechAnnouncer.shared.alwaysSpeak = v 
        }
        .sheet(isPresented: $exportManager.showShareSheet) {
            ShareSheet(items: exportManager.shareItems) {
                exportManager.showShareSheet = false
                exportManager.shareItems = []
            }
        }
    }
    
    private func handleQuickExport() {
        // Provide audio feedback
        Accessibility.announce("Exporting research data")
        if speakEnabled {
            SpeechAnnouncer.shared.say("Preparing data for sharing")
        }
        
        // Trigger the quick export
        exportManager.quickExportAndShare()
    }
    
    private func quickScan() {
        let sortedFeatures = store.features.sorted { $0.minX < $1.minX }
        
        if sortedFeatures.isEmpty {
            let message = "No features loaded"
            Accessibility.announce(message)
            if speakEnabled { SpeechAnnouncer.shared.say(message) }
            return
        }
        
        let leftFeatures = sortedFeatures.filter { $0.minX < 100 }
        let centerFeatures = sortedFeatures.filter { $0.minX >= 100 && $0.minX < 180 }
        let rightFeatures = sortedFeatures.filter { $0.minX >= 180 }
        
        var scanParts: [String] = []
        
        if !leftFeatures.isEmpty {
            let names = leftFeatures.map { $0.name }.joined(separator: ", ")
            scanParts.append("Left side: \(names)")
        }
        
        if !centerFeatures.isEmpty {
            let names = centerFeatures.map { $0.name }.joined(separator: ", ")
            scanParts.append("Center: \(names)")
        }
        
        if !rightFeatures.isEmpty {
            let names = rightFeatures.map { $0.name }.joined(separator: ", ")
            scanParts.append("Right side: \(names)")
        }
        
        let message = scanParts.joined(separator: ". ")
        Accessibility.announce(message)
        if speakEnabled { SpeechAnnouncer.shared.say(message) }
    }
    
    private func announceOverview() {
        let overview = generateDetailedOverview()
        Accessibility.announce(overview)
        if speakEnabled { SpeechAnnouncer.shared.say(overview) }
    }
    
    private func announceRandomTip() {
        let tip = Accessibility.randomTip()
        Accessibility.announce(tip)
        if speakEnabled { SpeechAnnouncer.shared.say(tip) }
    }
    
    private func announceInitialOverview() {
        hasAnnouncedOverview = true
        let gestureInstructions = "Double tap the bottom edge to scan all features, or triple tap for exploration tips."
        let message = "IndoorSense loaded. \(generateDetailedOverview()) Tap and drag on the main area to explore features. \(gestureInstructions)"
        
        Accessibility.announce(message)
        if speakEnabled { 
            SpeechAnnouncer.shared.say(message)
        }
    }
    
    private func generateDetailedOverview() -> String {
        let features = store.features
        guard !features.isEmpty else { return "No floor plan loaded." }
        
        let rooms = features.filter { $0.type == .room }
        let elevators = features.filter { $0.type == .elevator }
        let stairs = features.filter { $0.type == .stairs }
        let bathrooms = features.filter { $0.type == .bathroom }
        let landmarks = features.filter { $0.type == .landmark }
        let corridors = features.filter { $0.type == .corridor }
        
        var parts: [String] = []
        
        if !rooms.isEmpty {
            if rooms.count == 1 {
                parts.append("1 room: \(rooms.first!.name)")
            } else {
                parts.append("\(rooms.count) rooms including \(rooms.map { $0.name }.joined(separator: ", "))")
            }
        }
        
        var navFeatures: [String] = []
        if !elevators.isEmpty {
            navFeatures.append(elevators.count == 1 ? "1 elevator" : "\(elevators.count) elevators")
        }
        if !stairs.isEmpty {
            navFeatures.append(stairs.count == 1 ? "1 stairway" : "\(stairs.count) stairways")
        }
        if !navFeatures.isEmpty {
            parts.append(navFeatures.joined(separator: " and "))
        }
        
        if !bathrooms.isEmpty {
            parts.append(bathrooms.count == 1 ? "1 bathroom" : "\(bathrooms.count) bathrooms")
        }
        
        if !landmarks.isEmpty {
            if landmarks.count == 1 {
                parts.append("landmark: \(landmarks.first!.name)")
            } else {
                parts.append("landmarks: \(landmarks.map { $0.name }.joined(separator: ", "))")
            }
        }
        
        if !corridors.isEmpty && corridors.count == 1 {
            parts.append("connected by \(corridors.first!.name)")
        } else if corridors.count > 1 {
            parts.append("connected by \(corridors.count) corridors")
        }
        
        let overview = "Floor plan contains: " + parts.joined(separator: ", ") + "."
        return overview
    }
}