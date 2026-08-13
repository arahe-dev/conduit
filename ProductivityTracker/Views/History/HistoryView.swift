import SwiftUI

struct HistoryView: View {
    @Bindable var controller: SessionController
    @State private var sessions: [Session] = []

    var body: some View {
        List(sessions, id: \.id) { session in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(session.space?.name ?? "Space")
                        .font(.headline)
                    Spacer()
                    Text(ElapsedFormatter.compact(session.elapsed(at: session.endedAt ?? controller.timeSource.now())))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(grouped(session), id: \.name) { row in
                    HStack {
                        Text(row.name)
                        Spacer()
                        Text(ElapsedFormatter.compact(row.duration))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationTitle("History")
        .accessibilityIdentifier("history-screen")
        .onAppear {
            sessions = (try? controller.historicalSessions()) ?? []
        }
    }

    private func grouped(_ session: Session) -> [(name: String, duration: TimeInterval)] {
        let now = session.endedAt ?? controller.timeSource.now()
        var totals: [String: TimeInterval] = [:]
        var order: [String] = []
        for interval in session.intervals {
            let name = interval.task?.name ?? "Task"
            if totals[name] == nil {
                order.append(name)
            }
            totals[name, default: 0] += interval.duration(at: now)
        }
        return order.map { (name: $0, duration: totals[$0] ?? 0) }
    }
}
