// FILEPATH: IndoorSense/Services/ResearchLogger.swift
import Foundation
import UIKit
import CoreGraphics

class ResearchLogger: ObservableObject {
    static let shared = ResearchLogger()
    
    // MARK: - Configuration
    @Published var isLoggingEnabled = false
    @Published var studyConfiguration: StudyConfiguration?
    
    // MARK: - Data Storage
    private var interactions: [InteractionRecord] = []
    private var gestures: [GestureRecord] = []
    private var sessions: [SessionRecord] = []
    private var currentSession: SessionTracker?
    
    // MARK: - Session Management
    private class SessionTracker {
        let sessionID: String
        let participantID: String
        let startTime: TimeInterval
        var discoveredFeatures: Set<String> = []
        var interactionCount: Int = 0
        var errorCount: Int = 0
        var exploredPoints: Set<String> = [] // Store as "x,y" strings
        
        init(participantID: String) {
            self.sessionID = UUID().uuidString
            self.participantID = participantID
            self.startTime = Date().timeIntervalSince1970
        }
        
        func addExploredPoint(_ point: CGPoint) {
            let pointKey = "\(Int(point.x)),\(Int(point.y))"
            exploredPoints.insert(pointKey)
        }
    }
    
    private init() {}
    
    // MARK: - Public Data Access Methods
    
    func getCurrentInteractions() -> [InteractionRecord] {
        return interactions
    }
    
    func getCurrentGestures() -> [GestureRecord] {
        return gestures
    }
    
    func getCurrentSessions() -> [SessionRecord] {
        return sessions
    }
    
    // MARK: - Session Control
    
    func startSession(participantID: String, studyCondition: StudyConfiguration.StudyCondition) {
        isLoggingEnabled = true
        currentSession = SessionTracker(participantID: participantID)
        
        studyConfiguration = StudyConfiguration(
            studyID: "IndoorSense_Study_2025",
            participantID: participantID,
            condition: studyCondition,
            enabledFeatures: [.interactionLogging, .performanceMetrics],
            taskList: [.freeExploration]
        )
        
        print("Research session started: \(currentSession?.sessionID ?? "unknown")")
    }
    
    func endSession() {
        guard let session = currentSession else { return }
        
        let sessionRecord = SessionRecord(
            sessionID: session.sessionID,
            participantID: session.participantID,
            startTime: session.startTime,
            endTime: Date().timeIntervalSince1970,
            totalInteractions: session.interactionCount,
            uniqueFeaturesDiscovered: session.discoveredFeatures.count,
            totalFeaturesAvailable: 6, // Based on your features.json
            explorationCoverage: Double(session.exploredPoints.count) / 100.0, // Rough coverage estimate
            studyCondition: studyConfiguration?.condition.rawValue ?? "unknown",
            completedTasks: ["free_exploration"],
            errorCount: session.errorCount
        )
        
        sessions.append(sessionRecord)
        print("Research session ended: \(sessionRecord.sessionID)")
        
        // Don't disable logging or clear session - keep it active for continuous data collection
        // currentSession = nil
        // isLoggingEnabled = false
    }
    
    // MARK: - Data Logging
    
    func logInteraction(
        canvasPoint: CGPoint,
        featureID: String?,
        featureName: String?,
        featureType: FeatureType?,
        interactionType: InteractionRecord.InteractionType,
        duration: TimeInterval? = nil
    ) {
        guard isLoggingEnabled, let session = currentSession else { 
            print("Warning: Interaction not logged - logging disabled or no session")
            return 
        }
        
        let record = InteractionRecord(
            timestamp: Date().timeIntervalSince1970,
            sessionID: session.sessionID,
            participantID: session.participantID,
            x: canvasPoint.x,
            y: canvasPoint.y,
            featureID: featureID,
            featureName: featureName,
            featureType: featureType?.rawValue,
            interactionType: interactionType,
            duration: duration
        )
        
        interactions.append(record)
        session.interactionCount += 1
        session.addExploredPoint(canvasPoint)
        
        // Track feature discoveries
        if let featureID = featureID, !session.discoveredFeatures.contains(featureID) {
            session.discoveredFeatures.insert(featureID)
            print("New feature discovered: \(featureName ?? featureID)")
        }
        
        // Track errors
        if interactionType == .outsideTouch {
            session.errorCount += 1
        }
        
        print("Logged interaction: \(interactionType.rawValue) at (\(canvasPoint.x), \(canvasPoint.y))")
    }
    
    func logGesture(
        gestureType: GestureRecord.GestureType,
        success: Bool,
        duration: TimeInterval,
        attempts: Int = 1
    ) {
        guard isLoggingEnabled, let session = currentSession else { 
            print("Warning: Gesture not logged - logging disabled or no session")
            return 
        }
        
        let record = GestureRecord(
            timestamp: Date().timeIntervalSince1970,
            sessionID: session.sessionID,
            participantID: session.participantID,
            gestureType: gestureType,
            success: success,
            duration: duration,
            attempts: attempts
        )
        
        gestures.append(record)
        print("Logged gesture: \(gestureType.rawValue) - success: \(success)")
    }
    
    // MARK: - CSV Export
    
    func exportAllDataToCSV() -> [URL] {
        var exportedFiles: [URL] = []
        
        if let interactionsURL = exportInteractionsCSV() {
            exportedFiles.append(interactionsURL)
        }
        
        if let gesturesURL = exportGesturesCSV() {
            exportedFiles.append(gesturesURL)
        }
        
        if let sessionsURL = exportSessionsCSV() {
            exportedFiles.append(sessionsURL)
        }
        
        return exportedFiles
    }
    
    private func exportInteractionsCSV() -> URL? {
        let headers = "timestamp,session_id,participant_id,x_coordinate,y_coordinate,feature_id,feature_name,feature_type,interaction_type,duration\n"
        
        let csvData = interactions.map { record in
            let featureID = record.featureID ?? ""
            let featureName = record.featureName ?? ""
            let featureType = record.featureType ?? ""
            let duration = record.duration.map { String($0) } ?? ""
            
            return "\(record.timestamp),\(record.sessionID),\(record.participantID),\(record.x),\(record.y),\(featureID),\(featureName),\(featureType),\(record.interactionType.rawValue),\(duration)"
        }.joined(separator: "\n")
        
        return saveCSVFile(content: headers + csvData, filename: "interactions.csv")
    }
    
    private func exportGesturesCSV() -> URL? {
        let headers = "timestamp,session_id,participant_id,gesture_type,success,duration,attempts\n"
        
        let csvData = gestures.map { record in
            "\(record.timestamp),\(record.sessionID),\(record.participantID),\(record.gestureType.rawValue),\(record.success),\(record.duration),\(record.attempts)"
        }.joined(separator: "\n")
        
        return saveCSVFile(content: headers + csvData, filename: "gestures.csv")
    }
    
    private func exportSessionsCSV() -> URL? {
        let headers = "session_id,participant_id,start_time,end_time,duration,total_interactions,features_discovered,total_features,coverage_percentage,study_condition,error_count\n"
        
        let csvData = sessions.map { record in
            let endTime = record.endTime ?? Date().timeIntervalSince1970
            let duration = endTime - record.startTime
            let coveragePercentage = record.explorationCoverage * 100
            
            return "\(record.sessionID),\(record.participantID),\(record.startTime),\(endTime),\(duration),\(record.totalInteractions),\(record.uniqueFeaturesDiscovered),\(record.totalFeaturesAvailable),\(coveragePercentage),\(record.studyCondition),\(record.errorCount)"
        }.joined(separator: "\n")
        
        return saveCSVFile(content: headers + csvData, filename: "sessions.csv")
    }
    
    private func saveCSVFile(content: String, filename: String) -> URL? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Exported: \(filename)")
            return fileURL
        } catch {
            print("Failed to export \(filename): \(error)")
            return nil
        }
    }
    
    // MARK: - Data Access
    
    func getSessionSummary() -> String {
        guard let session = currentSession else { return "No active session" }
        
        let currentInteractionCount = interactions.filter { $0.sessionID == session.sessionID }.count
        let currentGestureCount = gestures.filter { $0.sessionID == session.sessionID }.count
        
        return """
        Session ID: \(session.sessionID)
        Participant: \(session.participantID)
        Interactions: \(currentInteractionCount)
        Gestures: \(currentGestureCount)
        Features Found: \(session.discoveredFeatures.count)/6
        Errors: \(session.errorCount)
        Duration: \(Int(Date().timeIntervalSince1970 - session.startTime))s
        """
    }
    
    func clearAllData() {
        interactions.removeAll()
        gestures.removeAll()
        sessions.removeAll()
        currentSession = nil
        isLoggingEnabled = false
        print("All research data cleared")
    }
}