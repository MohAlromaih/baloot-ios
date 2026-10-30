#if canImport(UIKit)
import SwiftUI
import BalootCore

// MARK: - Settings

struct SettingsView: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss
    @State var targetText = ""
    @State var defaultTargetText = ""

    var body: some View {
        @Bindable var state = state
        let t = state.t
        NavigationStack {
            Form {
                Section(t.language) {
                    Picker(t.language, selection: $state.language) {
                        Text("العربية").tag(AppLanguage.ar)
                        Text("English").tag(AppLanguage.en)
                    }
                    .pickerStyle(.segmented)
                }
                Section(t.appearance) {
                    Picker(t.appearance, selection: $state.theme) {
                        Text(t.themeSystem).tag(AppTheme.system)
                        Text(t.themeLight).tag(AppTheme.light)
                        Text(t.themeDark).tag(AppTheme.dark)
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Toggle(t.keypad, isOn: $state.keypadEnabled)
                } footer: { Text(t.keypadDesc) }

                Section {
                    HStack {
                        Text(t.targetScore)
                        Spacer()
                        TextField("152", text: $targetText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .disabled(!state.match.hands.isEmpty)
                            .onSubmit(applyTarget)
                            .onChange(of: targetText) { applyTarget() }
                    }
                    HStack {
                        Text(t.defaultTargetLabel).font(.subheadline)
                        Spacer()
                        TextField("152", text: $defaultTargetText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                            .onChange(of: defaultTargetText) {
                                if let v = Validation.parseTarget(defaultTargetText) { state.defaultTarget = v }
                            }
                    }
                } footer: {
                    if !state.match.hands.isEmpty { Text(t.targetLocked) }
                }

                Section(t.rulesTitle) {
                    ForEach(t.rules, id: \.self) { rule in
                        Label(rule, systemImage: "checkmark.seal").font(.subheadline)
                    }
                }
                Section(t.storageTitle) {
                    Label(t.storageDesc, systemImage: "iphone").font(.subheadline)
                }
            }
            .navigationTitle(t.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(t.done) { dismiss() } }
            }
            .onAppear {
                targetText = String(state.match.targetScore)
                defaultTargetText = String(state.defaultTarget)
            }
        }
    }

    private func applyTarget() {
        if let v = Validation.parseTarget(targetText), v != state.match.targetScore, state.match.hands.isEmpty {
            state.setTarget(v)
        }
    }
}

// MARK: - New match

struct NewMatchView: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss
    @State var nameA = ""
    @State var nameB = ""
    @State var targetText = ""

    var body: some View {
        let t = state.t
        NavigationStack {
            Form {
                if !state.match.hands.isEmpty {
                    Section {
                        Label(t.newMatchConfirm, systemImage: "archivebox").font(.subheadline)
                    }
                }
                Section {
                    TextField(t.teamAName, text: $nameA).foregroundStyle(Palette.teamA)
                    TextField(t.teamBName, text: $nameB).foregroundStyle(Palette.teamB)
                    Button(t.resetNames) {
                        nameA = t.defaultTeamA; nameB = t.defaultTeamB
                    }
                }
                Section(t.targetScore) {
                    TextField("152", text: $targetText).keyboardType(.numberPad)
                }
            }
            .navigationTitle(t.newMatch)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(t.cancel) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t.startMatch) {
                        let target = Validation.parseTarget(targetText) ?? state.defaultTarget
                        state.startNewMatch(teamA: nameA, teamB: nameB, target: target)
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                nameA = state.name(.teamA)   // keep current names by default
                nameB = state.name(.teamB)
                targetText = String(state.defaultTarget)
            }
        }
    }
}

// MARK: - Edit hand

struct EditHandView: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss
    let hand: Hand
    let number: Int
    @State var a = ""
    @State var b = ""
    @State var error: String?

    var body: some View {
        let t = state.t
        NavigationStack {
            Group {
                if let c = state.pendingConflict {
                    ConflictView(conflict: c, onFinish: { dismiss() })
                } else {
                    Form {
                        Section {
                            LabeledContent(t.pointsOf(state.name(.teamA))) {
                                TextField("0", text: $a).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            }
                            LabeledContent(t.pointsOf(state.name(.teamB))) {
                                TextField("0", text: $b).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            }
                        } footer: {
                            if let error { Label(error, systemImage: "exclamationmark.circle").foregroundStyle(.red) }
                        }
                    }
                }
            }
            .navigationTitle(t.editHandTitle(number))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if state.pendingConflict == nil {
                    ToolbarItem(placement: .cancellationAction) { Button(t.cancel) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button(t.save, action: save).bold() }
                }
            }
            .onAppear { a = String(hand.teamAPoints); b = String(hand.teamBPoints) }
        }
        .interactiveDismissDisabled(state.pendingConflict != nil)
    }

    private func save() {
        let t = state.t
        switch Validation.validateHand(teamA: a, teamB: b) {
        case .success(let (pa, pb)):
            state.editHand(id: hand.id, teamA: pa, teamB: pb)
            if state.pendingConflict == nil && state.bannerError == nil { dismiss() }
            else if state.bannerError != nil { error = state.bannerError }
        case .failure(.bothZero): error = t.bothZero
        case .failure(.fields(let ea, let eb)):
            error = (ea == .required && eb == .required) ? t.enterBoth : t.invalidNumber
        }
    }
}

// MARK: - Conflict (earlier win after correction)

struct ConflictView: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss
    let conflict: PendingConflict
    var onFinish: (() -> Void)?

    var body: some View {
        let t = state.t
        let hands = state.match.hands
        let flaggedNumbers = conflict.subsequentHandIDs.compactMap { id in
            hands.firstIndex(where: { $0.id == id }).map { $0 + 1 }
        }
        VStack(alignment: .leading, spacing: 16) {
            Label(t.conflictTitle, systemImage: "exclamationmark.triangle.fill")
                .font(.title3.bold())
                .foregroundStyle(.orange)
            Text(t.conflictMsg(team: state.conflictWinnerName(conflict),
                               hand: conflict.winningHandIndex + 1,
                               count: conflict.subsequentHandIDs.count))
            // Flag the hands that would be removed
            HStack {
                Text(t.flagged + ":").bold()
                Text(flaggedNumbers.map { "#\($0)" }.joined(separator: "  "))
                    .monospacedDigit()
            }
            .font(.subheadline)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

            Spacer()
            Button(role: .destructive) {
                state.resolveConflictRemovingSubsequent()
                finish()
            } label: {
                Text(t.conflictRemove).frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Button {
                state.cancelConflict()
                finish()
            } label: {
                Text(t.conflictCancel).frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
    }

    private func finish() {
        if let onFinish { onFinish() } else { dismiss() }
    }
}

// MARK: - Saved matches

struct SavedMatchesView: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    var body: some View {
        let t = state.t
        NavigationStack {
            List {
                if state.archived.isEmpty {
                    ContentUnavailableView(t.noSaved, systemImage: "clock")
                }
                ForEach(state.archived) { m in
                    NavigationLink {
                        ArchivedMatchDetail(match: m)
                    } label: {
                        ArchivedRow(match: m)
                    }
                }
                .onDelete { idx in
                    for i in idx { state.deleteArchived(id: state.archived[i].id) }
                }
            }
            .navigationTitle(t.previousMatches)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(t.close) { dismiss() } }
            }
        }
    }
}

struct ArchivedRow: View {
    @Environment(AppState.self) var state
    let match: Match
    var body: some View {
        let t = state.t
        let totals = Scoring.totals(match.hands)
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(match.teamAName).foregroundStyle(Palette.teamA).bold()
                Text("\(totals.teamA) – \(totals.teamB)").monospacedDigit().bold()
                    .environment(\.layoutDirection, .leftToRight)
                Text(match.teamBName).foregroundStyle(Palette.teamB).bold()
            }
            HStack(spacing: 6) {
                if let w = match.winner {
                    Label(t.teamWins(match.name(for: w)), systemImage: "trophy.fill")
                } else {
                    Text(t.noWinner)
                }
                Text("·")
                Text("\(match.hands.count) \(t.hands)")
                Text("·")
                Text(match.createdAt, format: .dateTime.day().month().year().hour().minute())
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

struct ArchivedMatchDetail: View {
    @Environment(AppState.self) var state
    let match: Match
    var body: some View {
        let t = state.t
        let running = Scoring.runningTotals(match.hands)
        List {
            Section {
                ArchivedRow(match: match)
                LabeledContent(t.targetScore, value: "\(match.targetScore)")
            }
            Section(t.handHistory) {
                ForEach(Array(match.hands.enumerated()), id: \.element.id) { i, h in
                    HStack {
                        Text("\(i + 1)").foregroundStyle(.secondary).frame(width: 30)
                        VStack { Text("+\(h.teamAPoints)").foregroundStyle(Palette.teamA); Text("\(running[i].teamATotal)").font(.caption) }
                            .frame(maxWidth: .infinity)
                        VStack { Text("+\(h.teamBPoints)").foregroundStyle(Palette.teamB); Text("\(running[i].teamBTotal)").font(.caption) }
                            .frame(maxWidth: .infinity)
                    }
                    .monospacedDigit()
                }
            }
        }
        .navigationTitle(t.previousMatches)
    }
}
#endif
