#if canImport(UIKit)
import SwiftUI
import BalootCore

struct HandInputView: View {
    @Environment(AppState.self) var state
    @FocusState var focused: TeamID?

    var body: some View {
        @Bindable var state = state
        let t = state.t

        Card {
            VStack(spacing: 12) {
                // Header + keypad toggle
                HStack {
                    Text(t.addHand).font(.subheadline.bold()).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        focused = nil
                        state.keypadEnabled.toggle()
                    } label: {
                        Label(t.keypad, systemImage: state.keypadEnabled ? "circle.grid.3x3.fill" : "keyboard")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .frame(minHeight: 36)
                            .background(state.keypadEnabled ? Palette.accent.opacity(0.18) : Color.secondary.opacity(0.12),
                                        in: Capsule())
                    }
                    .foregroundStyle(state.keypadEnabled ? Palette.accent : .secondary)
                    .accessibilityValue(state.keypadEnabled ? "ON" : "OFF")
                }

                // Two labelled score boxes
                HStack(alignment: .top, spacing: 12) {
                    scoreBox(.teamA, text: $state.inputA, error: state.fieldErrorA)
                    scoreBox(.teamB, text: $state.inputB, error: state.fieldErrorB)
                }

                if let err = state.formError {
                    Label(err, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Add hand + Undo
                HStack(spacing: 10) {
                    Button {
                        focused = nil
                        state.submitHand()
                    } label: {
                        Label(t.addHand, systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.accent)
                    .disabled(state.isSubmitting)

                    Button { state.undo() } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.headline)
                            .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.bordered)
                    .disabled(state.match.hands.isEmpty)
                    .accessibilityLabel(t.undo)
                }

                if state.keypadEnabled {
                    KeypadView()
                }
            }
        }
        .sensoryFeedback(.success, trigger: state.match.hands.count)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(t.addHand) {
                    focused = nil
                    state.submitHand()
                }
                .bold()
                Button(t.done) { focused = nil }
            }
        }
    }

    @ViewBuilder
    private func scoreBox(_ team: TeamID, text: Binding<String>, error: PointsFieldError?) -> some View {
        let t = state.t
        let isActive = state.keypadEnabled && state.activeTeam == team
        VStack(alignment: .leading, spacing: 6) {
            Text(t.pointsOf(state.name(team)))
                .font(.caption.bold())
                .foregroundStyle(team.color)
                .lineLimit(1)

            Group {
                if state.keypadEnabled {
                    // Display-only box driven by the built-in keypad.
                    Button { state.activeTeam = team } label: {
                        Text(text.wrappedValue.isEmpty ? "0" : text.wrappedValue)
                            .foregroundStyle(text.wrappedValue.isEmpty ? Color.secondary.opacity(0.5) : team.color)
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                } else {
                    TextField("0", text: text)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(team.color)
                        .focused($focused, equals: team)
                        .frame(minHeight: 56)
                        .onChange(of: text.wrappedValue) { state.clearErrors() }
                }
            }
            .font(.system(size: 30, weight: .black, design: .rounded))
            .monospacedDigit()
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(error != nil ? Color.red : (isActive ? team.color : Color.clear), lineWidth: 2)
            )
            .accessibilityLabel(t.pointsOf(state.name(team)))

            if let error {
                Label(error == .required ? t.enterBoth : t.invalidNumber, systemImage: "exclamationmark.circle")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Built-in keypad with direct team allocation

struct KeypadView: View {
    @Environment(AppState.self) var state

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        let t = state.t
        VStack(spacing: 10) {
            Text(t.keypadHint)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            // Team buttons: typed points go straight to the pressed team.
            HStack(spacing: 10) {
                teamButton(.teamA)
                teamButton(.teamB)
            }

            // Quick presets
            HStack(spacing: 8) {
                ForEach([8, 16, 26], id: \.self) { v in
                    key { state.keypadPreset(v) } label: { Text("+\(v)").font(.headline) }
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9"], id: \.self) { d in
                    key { state.keypadDigit(Character(d)) } label: { Text(d).font(.title2.bold()) }
                }
                key(secondary: true) { state.keypadClear() } label: { Text("C").font(.title3.bold()) }
                key { state.keypadDigit("0") } label: { Text("0").font(.title2.bold()) }
                key(secondary: true) { state.keypadBackspace() } label: {
                    Image(systemName: "delete.backward").font(.title3)
                }
            }
            .environment(\.layoutDirection, .leftToRight) // keep phone-keypad digit order
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        .sensoryFeedback(.selection, trigger: state.inputA + state.inputB)
    }

    private func teamButton(_ team: TeamID) -> some View {
        let typed = team == .teamA
            ? (state.inputA.isEmpty ? state.inputB : state.inputA)
            : (state.inputB.isEmpty ? state.inputA : state.inputB)
        return Button { state.pressTeam(team) } label: {
            HStack {
                Image(systemName: "plus")
                Text(state.name(team)).lineLimit(1).minimumScaleFactor(0.6)
                Spacer(minLength: 4)
                Text(typed.isEmpty ? "0" : "+\(typed)")
                    .monospacedDigit()
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(team.color.gradient, in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(state.isSubmitting)
    }

    private func key<L: View>(secondary: Bool = false, _ action: @escaping () -> Void,
                              @ViewBuilder label: () -> L) -> some View {
        Button(action: action) {
            label()
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(secondary ? Color.secondary.opacity(0.18) : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
#endif
