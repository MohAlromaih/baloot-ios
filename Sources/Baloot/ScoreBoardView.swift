#if canImport(UIKit)
import SwiftUI
import BalootCore

struct ScoreBoardView: View {
    @Environment(AppState.self) var state
    var onRename: (TeamID) -> Void

    var body: some View {
        // HStack follows layout direction: team A is on the leading side
        // (right in Arabic, left in English) — scores always stay with their team.
        HStack(spacing: 12) {
            TeamScoreCard(team: .teamA, onRename: onRename)
            TeamScoreCard(team: .teamB, onRename: onRename)
        }
    }
}

struct TeamScoreCard: View {
    @Environment(AppState.self) var state
    let team: TeamID
    var onRename: (TeamID) -> Void

    var body: some View {
        let t = state.t
        let total = state.engine.total(for: team)
        let remaining = state.engine.remaining(for: team)
        let target = state.match.targetScore
        let isWinner = state.match.winner == team
        let progress = min(1, Double(total) / Double(max(1, target)))

        VStack(spacing: 8) {
            Button { onRename(team) } label: {
                HStack(spacing: 4) {
                    if isWinner { Image(systemName: "crown.fill") }
                    Text(state.name(team))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Image(systemName: "pencil")
                        .font(.caption2)
                        .opacity(0.6)
                }
                .font(.headline)
                .foregroundStyle(team.color)
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .accessibilityLabel("\(state.name(team)), \(t.rename)")

            Text("\(total)")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .accessibilityLabel("\(t.total) \(total)")

            ProgressView(value: progress)
                .tint(team.color)

            HStack {
                Text(t.remaining)
                Spacer()
                Text("\(remaining)").monospacedDigit().bold()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(team.color.opacity(isWinner ? 0.9 : 0.25), lineWidth: isWinner ? 3 : 1)
        )
    }
}
#endif
