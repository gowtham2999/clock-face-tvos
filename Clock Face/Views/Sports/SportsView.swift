import SwiftUI

/// The Sports tab: a glass sidebar of sports, and the selected sport's page.
struct SportsView: View {
    @State private var selectedSport: Sport = .formula1

    var body: some View {
        HStack(alignment: .top, spacing: 48) {
            sidebar
                .frame(width: 380)

            Group {
                if selectedSport == .formula1 {
                    F1View()
                } else {
                    PlaceholderTabView(title: selectedSport.displayName, subtitle: "Schedule coming soon")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.top, 150)
    }

    private var sidebar: some View {
        VStack(spacing: 8) {
            ForEach(Sport.allCases) { sport in
                Button {
                    selectedSport = sport
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: sport.symbolName)
                            .frame(width: 44)
                        Text(sport.displayName)
                        Spacer(minLength: 0)
                        if !sport.isAvailable {
                            Text("Soon")
                                .font(.system(size: 18, weight: .semibold))
                                .opacity(0.5)
                        }
                    }
                }
                .buttonStyle(SidebarRowButtonStyle(isSelected: sport == selectedSport))
                .accessibilityLabel(sport.displayName)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
        .focusSection()
    }
}
