#if canImport(UIKit)
import SwiftUI
#if canImport(BalootCore)
import BalootCore
#endif

@main
struct BalootApp: App {
    @State var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(state)
                .environment(\.layoutDirection, state.language.layoutDirection)
                .environment(\.locale, state.language.locale)
                .preferredColorScheme(state.theme.colorScheme)
        }
    }
}

// MARK: - Palette

enum Palette {
    static let teamA = Color(red: 0.23, green: 0.51, blue: 0.96)   // blue
    static let teamB = Color(red: 0.96, green: 0.25, blue: 0.37)   // rose
    static let accent = Color(red: 0.06, green: 0.73, blue: 0.51)  // emerald
    static let darkBG = Color(red: 0.027, green: 0.043, blue: 0.078) // #070b14
}

extension TeamID {
    var color: Color { self == .teamA ? Palette.teamA : Palette.teamB }
    var other: TeamID { self == .teamA ? .teamB : .teamA }
}

struct AppBackground: View {
    @Environment(\.colorScheme) var scheme
    var body: some View {
        (scheme == .dark ? Palette.darkBG : Color(.systemGroupedBackground))
            .ignoresSafeArea()
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.primary.opacity(0.08)))
    }
}
#endif
