// FILEPATH: IndoorSense/Services/QuickExportManager.swift
import Foundation
import UIKit
import SwiftUI

class QuickExportManager: ObservableObject {
    static let shared = QuickExportManager()
    
    @Published var isExporting = false
    @Published var showShareSheet = false
    @Published var shareItems: [Any] = []
    
    private init() {}
    
    /// Quick export that captures current data and shares immediately
    func quickExportAndShare() {
        isExporting = true
        
        // Give a brief moment for any pending interactions to be logged
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performExport()
        }
    }
    
    private func performExport() {
        // Create a combined CSV with all interaction data
        let csvContent = generateCombinedCSV()
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "IndoorSense_Data_\(timestamp).csv"
        
        // Save to temporary directory for sharing
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Prepare for sharing
            DispatchQueue.main.async {
                self.shareItems = [tempURL]
                self.showShareSheet = true
                self.isExporting = false
            }
            
            print("Quick export ready for sharing: \(filename)")
            
        } catch {
            print("Failed to create export file: \(error)")
            isExporting = false
        }
    }
    
    private func generateCombinedCSV() -> String {
        let logger = ResearchLogger.shared
        var csvContent = ""
        
        // Header with session info
        csvContent += "# IndoorSense Research Data Export\n"
        csvContent += "# Generated: \(Date())\n"
        csvContent += "# App Version: 1.0\n"
        csvContent += "\n"
        
        // Session summary
        csvContent += "# Session Summary\n"
        let sessionSummary = logger.getSessionSummary()
        for line in sessionSummary.components(separatedBy: .newlines) {
            csvContent += "# \(line)\n"
        }
        csvContent += "\n"
        
        // Interactions section
        csvContent += "# INTERACTIONS DATA\n"
        csvContent += "timestamp,session_id,participant_id,x_coordinate,y_coordinate,feature_id,feature_name,feature_type,interaction_type,duration\n"
        
        csvContent += getInteractionsCSVData()
        csvContent += "\n"
        
        // Gestures section  
        csvContent += "# GESTURES DATA\n"
        csvContent += "timestamp,session_id,participant_id,gesture_type,success,duration,attempts\n"
        
        csvContent += getGesturesCSVData()
        csvContent += "\n"
        
        // Quick stats
        csvContent += "# QUICK STATISTICS\n"
        csvContent += generateQuickStats()
        
        return csvContent
    }
    
    private func getInteractionsCSVData() -> String {
        let interactions = ResearchLogger.shared.getCurrentInteractions()
        
        if interactions.isEmpty {
            return "# No interaction data recorded\n"
        }
        
        return interactions.map { record in
            let featureID = record.featureID ?? ""
            let featureName = record.featureName ?? ""
            let featureType = record.featureType ?? ""
            let duration = record.duration.map { String($0) } ?? ""
            
            return "\(record.timestamp),\(record.sessionID),\(record.participantID),\(record.x),\(record.y),\(featureID),\(featureName),\(featureType),\(record.interactionType.rawValue),\(duration)"
        }.joined(separator: "\n")
    }
    
    private func getGesturesCSVData() -> String {
        let gestures = ResearchLogger.shared.getCurrentGestures()
        
        if gestures.isEmpty {
            return "# No gesture data recorded\n"
        }
        
        return gestures.map { record in
            "\(record.timestamp),\(record.sessionID),\(record.participantID),\(record.gestureType.rawValue),\(record.success),\(record.duration),\(record.attempts)"
        }.joined(separator: "\n")
    }
    
    private func generateQuickStats() -> String {
        let logger = ResearchLogger.shared
        let interactions = logger.getCurrentInteractions()
        let gestures = logger.getCurrentGestures()
        
        var stats = ""
        stats += "# Total Interactions: \(interactions.count)\n"
        stats += "# Total Gestures: \(gestures.count)\n"
        
        let featureInteractions = interactions.filter { $0.featureID != nil }
        let outsideInteractions = interactions.filter { $0.interactionType == .outsideTouch }
        
        stats += "# Feature Interactions: \(featureInteractions.count)\n"
        stats += "# Outside-Plan Touches: \(outsideInteractions.count)\n"
        
        let uniqueFeatures = Set(interactions.compactMap { $0.featureID })
        stats += "# Unique Features Discovered: \(uniqueFeatures.count)\n"
        
        stats += "# Logging Status: \(logger.isLoggingEnabled ? "Active" : "Inactive")\n"
        stats += "# Export Time: \(Date())\n"
        stats += "# Data Format: CSV\n"
        stats += "# Research Purpose: Indoor Navigation & Spatial Cognition Study\n"
        
        return stats
    }
}

// MARK: - Share Sheet Wrapper for SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}