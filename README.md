# IndoorSense: Accessible Indoor Navigation

An iOS app designed for blind and visually impaired users to explore indoor floor plans through multi-modal feedback including speech, haptics, and spatial audio cues.

## Summary

IndoorSense transforms indoor navigation accessibility by providing a gesture-based interface that allows users to explore spatial layouts through touch, audio announcements, and haptic feedback. The app renders floor plans from JSON data and enables users to discover rooms, elevators, corridors, and landmarks through intuitive exploration patterns.

### Key Features
- **Gesture-Based Navigation**: Double-tap to scan all features, triple-tap for exploration tips
- **Multi-Modal Feedback**: Speech announcements, haptic patterns, and audio tones
- **Real-Time Guidance**: Outside-plan detection with directional assistance
- **Research Integration**: Comprehensive interaction logging and CSV data export
- **Full Accessibility**: VoiceOver compatibility with proper semantic labels

### Demo
The app displays a color-coded floor plan where users can:
- Tap and drag to discover features (blue rooms, orange elevators, teal bathrooms)
- Receive instant audio feedback identifying each space
- Feel distinct haptic patterns for different feature types
- Access overview information and spatial scanning functions

## Object-Oriented Design

The app follows a clean separation of concerns with distinct layers for data management, user interface, and services.

### Core Models
- **Feature**: Represents individual map elements (rooms, elevators, etc.) with coordinates, type, and metadata
- **MapStore**: Observable data store managing feature collection, coordinate transformations, and hit testing
- **FeatureCollection**: JSON parsing wrapper for loading floor plan data

### View Architecture
- **ContentView**: Main application coordinator managing state and user interactions
- **MapCanvasView**: Custom SwiftUI Canvas for rendering and touch handling
- **HUDView**: Compact header interface with accessibility controls
- **GestureControlView**: Bottom gesture area for double-tap and triple-tap recognition

### Service Layer
- **SpeechAnnouncer**: AVFoundation-based text-to-speech with VoiceOver integration
- **Haptics**: UIKit feedback generators with feature-specific vibration patterns
- **TonePlayer**: Audio cue system for spatial orientation
- **ResearchLogger**: Comprehensive interaction tracking and CSV export functionality

### Data Flow
1. JSON floor plan loaded into MapStore on app launch
2. User touches trigger coordinate transformation from canvas to map space
3. Hit testing determines which feature (if any) contains the touch point
4. Multi-modal feedback systems provide immediate sensory response
5. All interactions logged for research analysis

## Gesture & Feedback Design

The interface prioritizes non-visual interaction patterns that blind users can discover and master quickly.

### Primary Gestures
- **Single Tap**: Announces current location or gesture area function
- **Touch and Drag**: Continuous exploration with real-time feature identification
- **Double-Tap (Bottom Area)**: Quick spatial scan from left to right
- **Triple-Tap (Bottom Area)**: Random exploration tip

### Feedback Mapping
Each feature type provides distinct sensory signatures:

- **Rooms**: Medium haptic pulse + speech announcement + blue visual
- **Corridors**: Continuous light vibration + directional audio cues + gray visual
- **Elevators**: Success notification haptic + higher-pitched tone + orange visual
- **Stairs**: Heavy haptic impact + distinct audio cue + purple visual
- **Bathrooms**: Warning-style notification + specific announcement + teal visual
- **Landmarks**: Smooth-strong vibration sequence + emphasis tone + pink visual

### Accessibility Integration
- VoiceOver compatibility with proper accessibility labels and hints
- Custom accessibility actions for power users
- Gesture recognition that works with assistive touch
- Audio announcements that complement rather than conflict with VoiceOver

## Tradeoffs

### Design Decisions
**Gesture vs Button Interface**: Chose gesture-based controls over traditional buttons to reduce cognitive load for blind users. While this requires a learning curve, it ultimately provides faster navigation once mastered.

**Custom Canvas vs MapKit**: Implemented custom SwiftUI Canvas instead of Apple MapKit to have precise control over accessibility features and coordinate systems. MapKit would have provided zooming and panning but at the cost of accessibility customization.

**Continuous vs Discrete Feedback**: Selected continuous haptic feedback for corridors and real-time audio for exploration. This provides richer spatial information but may drain battery faster than discrete notifications.

### Challenges Encountered
**Coordinate System Mapping**: The most complex aspect was ensuring consistent coordinate transformation between the JSON data, canvas rendering, and touch detection. Required extensive testing to achieve pixel-perfect accuracy.

**VoiceOver Integration**: Balancing custom speech announcements with VoiceOver functionality required careful consideration of when to use UIAccessibility.post vs direct AVSpeechSynthesizer calls.

**Haptic Pattern Design**: Creating distinct, memorable haptic signatures for each feature type while avoiding user fatigue from excessive vibration.

### Future Improvements
With additional time, I would implement:
- **Multi-floor Support**: Extend the JSON schema to support building levels with floor switching
- **Route Planning**: Add pathfinding between features with turn-by-turn haptic guidance
- **Customizable Feedback**: Allow users to adjust haptic intensity, speech rate, and audio cue preferences
- **Spatial Audio**: Implement 3D audio positioning for true directional awareness
- **Collaborative Features**: Enable shared exploration sessions for training purposes

## Research Impact

This IndoorSense app provides a unique platform for studying non-visual spatial cognition and accessibility technology effectiveness in controlled research environments. Researchers could deploy the app to investigate how blind and visually impaired individuals construct mental maps from multi-modal feedback, comparing traditional button-based interfaces against the app's innovative gesture-driven approach to determine which interaction paradigms most effectively support spatial learning. The app's comprehensive logging capabilities would enable longitudinal studies tracking how users develop navigation strategies over time, while its configurable feedback systems (haptic patterns, audio announcements, spatial tones) allow for controlled experiments testing optimal sensory substitution techniques. By presenting standardized floor plan layouts across participants, researchers could isolate variables like architectural complexity, landmark density, and route planning challenges to understand individual differences in spatial processing abilities. The app's real-world applicability - functioning as an actual navigation aid rather than merely a research prototype - ensures findings would directly inform the development of assistive technologies, indoor wayfinding systems, and architectural design guidelines that support universal accessibility in complex built environments.

## Installation & Usage

### Requirements
- iOS 16.0 or later
- Xcode 15.0 or later
- Device with haptic feedback support recommended

### Setup
1. Clone this repository
2. Open `IndoorSense.xcodeproj` in Xcode
3. Build and run on simulator or device
4. Grant microphone permissions for speech features

### Usage Instructions
1. Launch the app to automatically load the sample floor plan
2. Tap and drag across the screen to explore different areas
3. Double-tap the bottom area for a quick left-to-right scan
4. Triple-tap the bottom area for exploration tips
5. Use the overview button (info icon) for complete floor plan summary
6. Export interaction data using the share button for research analysis

### File Structure
```
IndoorSense/
├── Models/
│   ├── Feature.swift              # Core data model
│   ├── MapStore.swift             # Data management
│   └── ResearchModels.swift       # Research data structures
├── Views/
│   ├── ContentView.swift          # Main interface
│   ├── MapCanvasView.swift        # Map rendering & interaction
│   ├── HUDView.swift              # Header interface
│   └── GestureControlView.swift   # Bottom gesture area
├── Services/
│   ├── SpeechAnnouncer.swift      # Text-to-speech
│   ├── Haptics.swift              # Haptic feedback
│   ├── TonePlayer.swift           # Audio cues
│   ├── ResearchLogger.swift       # Data collection
│   └── QuickExportManager.swift   # CSV export
├── Support/
│   └── Accessibility.swift        # Accessibility utilities
├── Resources/
│   └── features.json              # Sample floor plan data
└── Tests/
    ├── AccessibilityTests.swift   # Accessibility verification
    ├── HitTestingTests.swift      # Touch accuracy testing
    └── JSONParsingTests.swift     # Data parsing validation
```

## Testing

Run the test suite using Command+U in Xcode. Tests cover:
- JSON parsing and feature instantiation accuracy
- Touch detection precision and coordinate mapping
- Accessibility label consistency and VoiceOver compatibility
- Research data collection and export functionality

## Contributing

This project was developed as a research tool for accessibility and spatial cognition studies. Future enhancements should prioritize user experience for blind and visually impaired individuals while maintaining research data collection capabilities.

## License

Educational and research use permitted. Please cite this work in academic publications.
