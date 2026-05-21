import SwiftUI

struct TranscriptView: View {
    let record: TranscriptRecord

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header

                    Text(record.transcript ?? "no transcript available")
                        .font(.body300(17))
                        .lineSpacing(7)
                        .tracking(0.1)
                        .textSelection(.enabled)
                        .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 48)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 18) {
                    Button {
                        UIPasteboard.general.string = record.transcript
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 15, weight: .light))
                    }
                    ShareLink(item: record.transcript ?? "") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .light))
                    }
                }
                .foregroundStyle(Theme.inkMuted)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(record.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.mono400(10))
                .tracking(1.4)
                .foregroundStyle(Theme.inkFaint)
            Text("·")
                .font(.mono400(10))
                .foregroundStyle(Theme.inkFaint)
            Text(formattedDuration)
                .font(.mono400(10))
                .tracking(1.4)
                .foregroundStyle(Theme.inkFaint)
                .monospacedDigit()
        }
    }

    private var formattedDuration: String {
        let minutes = Int(record.duration) / 60
        let seconds = Int(record.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
