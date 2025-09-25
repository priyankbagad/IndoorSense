// FILEPATH: IndoorSense/Views/HUDView.swift
import SwiftUI

struct HUDView: View {
    var title: String = "IndoorSense"
    @Binding var speakEnabled: Bool
    @Binding var tonesEnabled: Bool
    @Binding var hapticsEnabled: Bool
    var onOverview: () -> Void = {}
    var onQuickExport: () -> Void = {}
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer()
            
            // Quick Export button
            Button {
                onQuickExport()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 13))
                    .accessibilityLabel("Export Research Data")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            // Overview button
            Button {
                onOverview()
            } label: {
                Label("Overview", systemImage: "info.circle")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 13))
                    .accessibilityLabel("Floor Plan Overview")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            
            // Settings menu
            Menu {
                Toggle("Speak (AV)", isOn: $speakEnabled)
                Toggle("Tones", isOn: $tonesEnabled)
                Toggle("Haptics", isOn: $hapticsEnabled)
            } label: {
                Label("Options", systemImage: "ellipsis.circle")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 13))
                    .accessibilityLabel("Options")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.06), radius: 4, y: 1)
    }
}