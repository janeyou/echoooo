import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \TranscriptRecord.createdAt, order: .reverse) private var records: [TranscriptRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var query: String = ""

    private var filtered: [TranscriptRecord] {
        guard !query.isEmpty else { return records }
        let q = query.lowercased()
        return records.filter { record in
            (record.transcript?.lowercased().contains(q) ?? false)
                || record.derivedTitle.lowercased().contains(q)
        }
    }

    private var todayGroup: [TranscriptRecord] {
        filtered.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var thisWeekGroup: [TranscriptRecord] {
        let cal = Calendar.current
        return filtered.filter { record in
            !cal.isDateInToday(record.createdAt)
                && cal.isDate(record.createdAt, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }

    private var earlierGroup: [TranscriptRecord] {
        let cal = Calendar.current
        return filtered.filter { record in
            !cal.isDate(record.createdAt, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            if filtered.isEmpty {
                empty
            } else {
                content
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
            Text("conversations you capture will collect here.")
                .font(.body300(12))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                searchField
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                VStack(spacing: 18) {
                    if !todayGroup.isEmpty { group(label: "TODAY", items: todayGroup) }
                    if !thisWeekGroup.isEmpty { group(label: "THIS WEEK", items: thisWeekGroup) }
                    if !earlierGroup.isEmpty { group(label: "EARLIER", items: earlierGroup) }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.inkFaint)

            TextField("", text: $query, prompt:
                Text("search transcripts")
                    .font(.body300(14))
                    .foregroundStyle(Theme.inkFaint)
            )
            .font(.body300(14))
            .foregroundStyle(Theme.ink)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 0.5))
    }

    private func group(label: String, items: [TranscriptRecord]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.mono400(10))
                .tracking(1.8)
                .foregroundStyle(Theme.inkFaint)
                .padding(.bottom, 8)

            Rectangle().fill(Theme.hairline).frame(height: 0.5)

            VStack(spacing: 0) {
                ForEach(items) { record in
                    NavigationLink {
                        TranscriptView(record: record)
                    } label: {
                        groupRow(record: record)
                    }
                    .buttonStyle(.plain)

                    if record.id != items.last?.id {
                        Rectangle().fill(Theme.hairline).frame(height: 0.5)
                    }
                }
            }
        }
    }

    private func groupRow(record: TranscriptRecord) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.derivedTitle)
                    .font(.body300(15))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                if let preview = record.transcript?.prefix(140).description, !preview.isEmpty {
                    Text(preview)
                        .font(.body300(12))
                        .foregroundStyle(Theme.inkFaint)
                        .lineSpacing(2)
                        .lineLimit(2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(record.createdAt, format: .dateTime.hour().minute())
                    .font(.mono400(10))
                    .foregroundStyle(Theme.inkFaint)
                    .monospacedDigit()

                Text(formattedDuration(record.duration))
                    .font(.mono400(10))
                    .foregroundStyle(Theme.inkMuted)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
