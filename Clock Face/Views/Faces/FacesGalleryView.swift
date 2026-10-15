import SwiftUI

/// The Faces tab: My Faces first, then one row per collection. Each card is a
/// live, ticking preview. New collections appear automatically as rows.
struct FacesGalleryView: View {
    let onSelect: (WatchFaceType) -> Void

    @Environment(AppSettings.self) private var settings

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 48) {
                shelf(title: "My Faces", faces: settings.myFaces)
                ForEach(FaceCollection.allCases) { collection in
                    shelf(title: collection.displayName, faces: collection.faces)
                }
            }
            .padding(.top, 150)
            .padding(.bottom, 60)
        }
        .scrollClipDisabled()
    }

    private func shelf(title: String, faces: [WatchFaceType]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionLabel(text: title)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 48) {
                    ForEach(faces) { face in
                        FaceCard(face: face, isOnClock: face == settings.faceType) {
                            onSelect(face)
                        }
                    }
                }
                .padding(.vertical, 28)
            }
            .scrollClipDisabled()
        }
        .focusSection()
    }
}

private struct FaceCard: View {
    let face: WatchFaceType
    let isOnClock: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: action) {
                LiveFaceView(face: face)
                    .frame(width: 448, height: 252)
                    // Keeps dark faces from blending into a dark background.
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.ink.opacity(0.12), lineWidth: 2))
            }
            .buttonStyle(.card)
            .accessibilityLabel(face.displayName)

            HStack(spacing: 10) {
                Text(face.displayName)
                if isOnClock {
                    Image(systemName: "checkmark.circle.fill")
                        .accessibilityLabel("On Clock")
                }
            }
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(Color.ink.opacity(0.8))
        }
    }
}
