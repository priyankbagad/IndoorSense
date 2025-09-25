// FILEPATH: IndoorSense/IndoorSenseApp.swift
import SwiftUI
import Observation

@main
struct IndoorSenseApp: App {
    @State private var store = MapStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .onAppear {
                    do {
                        try store.loadFromBundle()
                        
                        // Auto-start research logging immediately when app launches
                        let timestamp = Date().timeIntervalSince1970
                        ResearchLogger.shared.startSession(
                            participantID: "User_\(Int(timestamp))",
                            studyCondition: .control
                        )
                        
                        print("🚀 App launched - Research logging started automatically")
                        
                    } catch {
                        print("❌ Failed to load features.json:", error.localizedDescription)
                    }
                }
        }
    }
}