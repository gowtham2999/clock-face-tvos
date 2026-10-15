import SwiftUI

/// Large live preview of one face with its options. Opened from the gallery,
/// or by pressing and holding on the Clock tab to customise the current face.
struct FaceDetailView: View {
    let face: WatchFaceType
    let onSetAsClock: () -> Void

    @Environment(AppSettings.self) private var settings
    /// When set, the preview sweeps through a whole day starting from midnight.
    @State private var dayPreviewStart: Date?

    private static let dayPreviewDuration: TimeInterval = 15

    @ViewBuilder
    private var preview: some View {
        if let dayPreviewStart {
            TimelineView(.animation) { context in
                let progress = min(1, context.date.timeIntervalSince(dayPreviewStart) / Self.dayPreviewDuration)
                FaceView(face: face, date: Calendar.current.startOfDay(for: .now).addingTimeInterval(progress * 86_400))
            }
            .task(id: dayPreviewStart) {
                try? await Task.sleep(for: .seconds(Self.dayPreviewDuration))
                if !Task.isCancelled { self.dayPreviewStart = nil }
            }
        } else {
            LiveFaceView(face: face)
        }
    }

    var body: some View {
        let isInMyFaces = settings.isInMyFaces(face)

        HStack(alignment: .center, spacing: 64) {
            preview
                .frame(width: 1040, height: 585)
                .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
                .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 22) {
                SettingsSectionLabel(text: face.collection.displayName)
                Text(face.displayName)
                    .font(.system(size: 64, weight: .bold))
                Text(face.summary)
                    .font(.system(size: 26))
                    .foregroundStyle(Color.ink.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)

                if face.palette.isEmpty {
                    if let note = face.customizationNote {
                        Text(note)
                            .font(.system(size: 22))
                            .foregroundStyle(Color.ink.opacity(0.45))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 12)
                    }
                } else {
                    SettingsSectionLabel(text: "Colour")
                        .padding(.top, 12)
                    FaceColorSwatchRow(palette: face.palette, selectedID: settings.color(for: face)?.id) { color in
                        settings.setColor(color, for: face)
                    }
                }

                VStack(alignment: .leading, spacing: 18) {
                    if face.followsTheSun {
                        Button {
                            dayPreviewStart = dayPreviewStart == nil ? .now : nil
                        } label: {
                            Label(dayPreviewStart == nil ? "Play a Day" : "Stop", systemImage: dayPreviewStart == nil ? "play.fill" : "stop.fill")
                                .frame(width: 440)
                        }
                    }

                    Button(action: onSetAsClock) {
                        Label("Set as Clock", systemImage: "checkmark")
                            .frame(width: 440)
                    }

                    Button {
                        if isInMyFaces {
                            settings.removeFromMyFaces(face)
                        } else {
                            settings.addToMyFaces(face)
                        }
                    } label: {
                        Label(isInMyFaces ? "Remove from My Faces" : "Add to My Faces",
                              systemImage: isInMyFaces ? "minus.circle" : "plus.circle")
                            .frame(width: 440)
                    }
                    .disabled(isInMyFaces && settings.myFaces.count == 1)
                }
                .padding(.top, 28)
                .focusSection()
            }
            .frame(width: 560, alignment: .leading)
            .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(settings.theme.background.ignoresSafeArea())
    }
}
