#if canImport(UIKit)
import SwiftUI
#if canImport(BalootCore)
import BalootCore
#endif

enum ActiveSheet: Identifiable {
    case settings, newMatch, saved, edit(Hand, Int)
    var id: String {
        switch self {
        case .settings: "settings"
        case .newMatch: "new"
        case .saved: "saved"
        case .edit(let h, _): "edit-\(h.id)"
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) var state
    @State var sheet: ActiveSheet?
    @State var renaming: TeamID?
    @State var renameText = ""
    @State var deleting: (Hand, Int)?

    var body: some View {
        let t = state.t
        NavigationStack {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 14) {
                    HeaderView(sheet: $sheet)
                    if let err = state.bannerError {
                        ErrorBanner(text: err)
                    }
                    ScoreBoardView(onRename: { team in
                        renameText = state.name(team)
                        renaming = team
                    })
                    StatusBanner()
                    if state.isCompleted {
                        Card {
                            Label(t.matchLocked, systemImage: "lock.fill")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        HandInputView()
                    }
                    HandHistoryView(
                        onEdit: { hand, n in sheet = .edit(hand, n) },
                        onDelete: { hand, n in deleting = (hand, n) }
                    )
                    BottomActions(sheet: $sheet)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $sheet) { s in
            Group {
                switch s {
                case .settings: SettingsView()
                case .newMatch: NewMatchView()
                case .saved: SavedMatchesView()
                case .edit(let h, let n): EditHandView(hand: h, number: n)
                }
            }
            .environment(state)
            .environment(\.layoutDirection, state.language.layoutDirection)
            .environment(\.locale, state.language.locale)
            .preferredColorScheme(state.theme.colorScheme)
        }
        .alert(t.rename, isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } }),
               presenting: renaming) { team in
            TextField(t.rename, text: $renameText)
            Button(t.save) { state.rename(team, to: renameText) }
            Button(t.cancel, role: .cancel) {}
        }
        .alert(t.deleteHandTitle, isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
               presenting: deleting) { d in
            Button(t.delete, role: .destructive) { state.deleteHand(id: d.0.id) }
            Button(t.cancel, role: .cancel) {}
        } message: { d in
            Text(t.deleteHandMsg(d.1))
        }
        // Conflicts from deletes (edits show their conflict inside the edit sheet).
        .sheet(item: Binding(get: { sheet == nil ? state.pendingConflict : nil },
                             set: { if $0 == nil { state.cancelConflict() } })) { c in
            ConflictView(conflict: c)
                .environment(state)
                .environment(\.layoutDirection, state.language.layoutDirection)
                .presentationDetents([.medium, .large])
                .interactiveDismissDisabled()
        }
    }
}

// MARK: - Header

struct HeaderView: View {
    @Environment(AppState.self) var state
    @Binding var sheet: ActiveSheet?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "suit.spade.fill")
                .font(.title2)
                .foregroundStyle(Palette.accent)
            Text(state.t.appTitle)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Button {
                state.language = state.language == .ar ? .en : .ar
            } label: {
                Text(state.language == .ar ? "EN" : "ع")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel(state.t.language)
            Button { sheet = .settings } label: {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial, in: Circle())
            }
            .accessibilityLabel(state.t.settings)
        }
        .foregroundStyle(.primary)
        .padding(.top, 6)
    }
}

struct ErrorBanner: View {
    let text: String
    var body: some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.red)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Status (winner / tie)

struct StatusBanner: View {
    @Environment(AppState.self) var state
    var body: some View {
        let t = state.t
        switch state.engine.outcome {
        case .won(let team):
            Label(t.teamWins(state.name(team)), systemImage: "trophy.fill")
                .font(.title3.bold())
                .foregroundStyle(.white)
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(team.color.gradient, in: RoundedRectangle(cornerRadius: 18))
        case .tieContinue:
            Label(t.tieContinue, systemImage: "equal.circle.fill")
                .font(.headline)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 16))
        case .inProgress:
            EmptyView()
        }
    }
}

// MARK: - Bottom actions

struct BottomActions: View {
    @Environment(AppState.self) var state
    @Binding var sheet: ActiveSheet?
    var body: some View {
        let t = state.t
        HStack(spacing: 10) {
            Button { sheet = .newMatch } label: {
                Label(t.newMatch, systemImage: "plus.circle")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            Button { sheet = .saved } label: {
                Label(t.previousMatches, systemImage: "clock.arrow.circlepath")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
        }
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}
#endif
