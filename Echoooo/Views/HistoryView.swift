import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \TranscriptRecord.createdAt, order: .reverse) private var records: [TranscriptRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            if records.isEmpty {
                empty
            } else {
                list
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("TRANSCRIPTS")
                    .font(.mono400(10))
                    .tracking(2.0)
                    .foregroundStyle(Theme.inkMuted)
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 12) {
            Text("nothing yet.")
                .font(.body300(15))
                .foregroundStyle(Theme.inkMuted)
            Text("recordings you make will collect here.")
                .font(.body300(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(records) { record in
                    NavigationLink {
                        TranscriptView(record: record)
                    } label: {
                        HistoryRow(record: record)
                    }
                    .buttonStyle(.plain)

                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(height: 0.5)
                        .padding(.leading, 24)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 60)
        }
        .scrollIndicators(.hidden)
    }
}

struct HistoryRow: View {
    let record: TranscriptRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(record.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.mono400(10))
                    .tracking(1.0)
                    .foregroundStyle(Theme.inkFaint)
                Text("·")
                    .font(.mono400(10))
                    .foregroundStyle(Theme.inkFaint)
                Text(formattedDuration)
                    .font(.mono400(10))
                    .tracking(1.0)
                    .foregroundStyle(Theme.inkFaint)
                    .monospacedDigit()
            }

            Text(record.transcript?.prefix(160).description ?? "processing.")
                .font(.body300(15))
                .foregroundStyle(Theme.inkMuted)
                .lineLimit(2)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }

    private var formattedDuration: String {
        let minutes = Int(record.duration) / 60
        let seconds = Int(record.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
