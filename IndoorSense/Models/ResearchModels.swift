// FILEPATH: IndoorSense/Models/ResearchModels.swift
import Foundation
import CoreGraphics

// MARK: - Data Records for CSV Export

struct InteractionRecord {
    let timestamp: TimeInterval
    let sessionID: String
    let participantID: String
    let x: CGFloat
    let y: CGFloat
    let featureID: String?
    let featureName: String?
    let featureType: String?
    let interactionType: InteractionType
    let duration: TimeInterval?
    
    enum InteractionType: String, CaseIterable {
        case touch = "touch"
        case drag = "drag"
        case outsideTouch = "outside_touch"
        case featureDiscovery = "feature_discovery"
        case featureRevisit = "feature_revisit"
    }
}

struct GestureRecord {
    let timestamp: TimeInterval
    let sessionID: String
    let participantID: String
    let gestureType: GestureType
    let success: Bool
    let duration: TimeInterval
    let attempts: Int
    
    enum GestureType: String, CaseIterable {
        case doubleTap = "double_tap"
        case tripleTap = "triple_tap"
        case singleTap = "single_tap"
        case overview = "overview_button"
    }
}

struct SessionRecord {
    let sessionID: String
    let participantID: String
    let startTime: TimeInterval
    let endTime: TimeInterval?
    let totalInteractions: Int
    let uniqueFeaturesDiscovered: Int
    let totalFeaturesAvailable: Int
    let explorationCoverage: Double // percentage of map explored
    let studyCondition: String
    let completedTasks: [String]
    let errorCount: Int // outside-plan touches
}

struct PerformanceMetrics {
    let sessionID: String
    let participantID: String
    let firstFeatureDiscoveryTime: TimeInterval?
    let averageFeatureDiscoveryTime: TimeInterval
    let spatialAccuracy: Double // ratio of successful to total touches
    let explorationEfficiency: Double // coverage per unit time
    let gestureUsageFrequency: [GestureRecord.GestureType: Int]
    let learningProgression: Double // improvement over time
}

// MARK: - Study Configuration

struct StudyConfiguration {
    let studyID: String
    let participantID: String
    let condition: StudyCondition
    let enabledFeatures: Set<ResearchFeature>
    let taskList: [ResearchTask]
    
    enum StudyCondition: String, CaseIterable {
        case control = "control"
        case gestureOnly = "gesture_only"
        case buttonOnly = "button_only"
        case multiModal = "multi_modal"
        case hapticOnly = "haptic_only"
        case audioOnly = "audio_only"
    }
    
    enum ResearchFeature: String, CaseIterable {
        case interactionLogging = "interaction_logging"
        case performanceMetrics = "performance_metrics"
        case spatialAnalysis = "spatial_analysis"
        case learningAssessment = "learning_assessment"
    }
    
    enum ResearchTask: String, CaseIterable {
        case freeExploration = "free_exploration"
        case findBathroom = "find_bathroom"
        case findElevator = "find_elevator"
        case routePlanning = "route_planning"
        case spatialMemoryTest = "spatial_memory_test"
    }
}