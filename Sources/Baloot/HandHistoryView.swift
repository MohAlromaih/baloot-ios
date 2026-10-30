#if canImport(UIKit)
import SwiftUI
import BalootCore

struct HandHistoryView: View {
    @Environment(AppState.self) var state
    var onEdit: (Hand, Int) -> Void
    var onDelete: (Hand, Int) -> Void

    var body: some View {
        let t = state.t
        let hands = state.match.hands
        let running = state.engine.runningTotals

        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(t.handHistory, systemImage: "list.number")
                        .font(.headline)
                    Spacer()
                    Text("\(t.targetScore): \(state.match.targetScore)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                if hands.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "tray").font(.title)
                        Text(t.noHands).font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 90)
                } else {
                    // Column header
                    HStack {
                        Text("#").frame(width: 34)
                        Text(state.name(.teamA)).foregroundStyle(Palette.teamA).frame(maxWidth: .infinity)
                        Text(state.name(.teamB)).foregroundStyle(Palette.teamB).frame(maxWidth: .infinity)
                        Color.clear.frame(width: 44)
                    }
                    .font(.caption.bold())
                    .lineLimit(1)

                    // Newest first
                    ForEach(Array(hands.enumerated()).reversed(), id: \.element.id) { i, hand in
                        HandRow(number: i + 1, hand: hand, running: running[i],
                                isWinningHand: state.isCompleted && i == hands.count - 1,
                                onEdit: { onEdit(hand, i + 1) },
                                onDelete: { onDelete(hand, i + 1) })
                        if i > 0 { Divider() }
                    }
                }
            }
        }
    }
}

struct HandRow: View {
    @Environment(AppState.self) var state
    let number: Int
    let hand: Hand
    let running: RunningTotal
    let isWinningHand: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void

    var body: some View {
        let t = state.t
        HStack {
            HStack(spacing: 2) {
                if isWinningHand { Image(systemName: "trophy.fill").font(.caption2).foregroundStyle(.orange) }
                Text("\(number)")
            }
            .font(.subheadline.bold())
            .foregroundStyle(.secondary)
            .frame(width: 34)

            cell(points: hand.teamAPoints, total: running.teamATotal, color: Palette.teamA)
            cell(points: hand.teamBPoints, total: running.teamBTotal, color: Palette.teamB)

            Menu {
                Button { onEdit() } label: { Label(t.edit, systemImage: "pencil") }
                Button(role: .destructive) { onDelete() } label: { Label(t.delete, systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("\(t.hand) \(number)")
        }
    }

    private func cell(points: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 0) {
            Text("+\(points)").font(.headline).foregroundStyle(color)
            Text("\(total)").font(.caption).foregroundStyle(.secondary)
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity)
    }
}
#endif
