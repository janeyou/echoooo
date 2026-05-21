import SwiftUI
import SwiftData

struct TranscriptView: View {
    @Bindable var record: TranscriptRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.keepAudio) private var keepAudio: Bool = SettingsDefault.keepAudio

    @State private var showingDeleteConfirm = false

    private var showsScrubber: Bool {
        keepAudio && record.localAudioExists
    }

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.horizontal, 24)
                            .padding(.top, 18)

                        if showsScrubber {
                            scrubberPill
                                .padding(.horizontal, 24)
                                .padding(.top, 14)
                        } else {
                            audioClearedNote
                                .padding(.horizontal, 24)
                                .padding(.top, 14)
                        }

                        bodyText
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 32)
                    }
                }
                .scrollIndicators(.hidden)

                bottomToolbar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("TRANSCRIPT")
                    .font(.mono400(10))
                    .tracking(2.0)
                    .foregroundStyle(Theme.inkMuted)
            }
        }
        .confirmationDialog("delete this transcript?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("delete", role: .destructive) { performDelete() }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("this can't be undone.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(record.derivedTitle)
                .font(.body300(22))
                .tracking(-0.2)
                .lineSpacing(4)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Text(record.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.mono400(10))
                    .tracking(0.8)
                    .foregroundStyle(Theme.inkFaint)
                    .textCase(.uppercase)

                Text("·")
                    .font(.mono400(10))
                    .foregroundStyle(Theme.inkFaint)

                Text(formattedDuration)
                    .font(.mono400(10))
                    .foregroundStyle(Theme.inkFaint)
                    .monospacedDigit()

                if record.wordCount > 0 {
                    Text("·")
                        .font(.mono400(10))
                        .foregroundStyle(Theme.inkFaint)

                    Text("\(record.wordCount) WORDS")
                        .font(.mono400(10))
                        .tracking(0.8)
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    private var audioClearedNote: some View {
        HStack(spacing: 6) {
            Image(systemName: "trash")
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(Theme.inkFaint)

            Text("AUDIO CLEARED · TRANSCRIPT ONLY")
                .font(.mono400(10))
                .tracking(0.8)
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private var scrubberPill: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.ink)
                .frame(width: 26, height: 26)
                .overlay {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.paper)
                        .offset(x: 1)
                }

            miniWaveform
                .frame(height: 18)

            Text("0:00 / \(formattedDuration)")
                .font(.mono400(10))
                .foregroundStyle(Theme.inkMuted)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surface2)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 0.5))
    }

    private var miniWaveform: some View {
        HStack(alignment: .center, spacing: 1) {
            ForEach(0..<40, id: \.self) { i in
                let h = 6 + CGFloat(abs(sin(Double(i) * 0.5 + 0.7))) * 12
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.hairline)
                    .frame(width: 2, height: h)
            }
        }
    }

    private var bodyText: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(paragraphs, id: \.self) { paragraph in
                Text(paragraph)
                    .font(.body300(16))
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var paragraphs: [String] {
        (record.transcript ?? "no transcript available")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.hairline).frame(height: 0.5)

            HStack(spacing: 0) {
                toolbarButton(label: "copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = record.transcript
                }
                Divider().frame(height: 32)
                ShareLink(item: record.transcript ?? "") {
                    toolbarLabel(label: "share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                Divider().frame(height: 32)
                toolbarButton(label: "delete", systemImage: "trash") {
                    showingDeleteConfirm = true
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 6)
            .background(Theme.paper)
        }
    }

    private func toolbarButton(label: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            toolbarLabel(label: label, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func toolbarLabel(label: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Theme.ink)
            Text(label.uppercased())
                .font(.mono400(10))
                .tracking(0.8)
                .foregroundStyle(Theme.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func performDelete() {
        if !record.localFilePath.isEmpty {
            try? FileManager.default.removeItem(atPath: record.localFilePath)
        }
        modelContext.delete(record)
        try? modelContext.save()
        dismiss()
    }

    private var formattedDuration: String {
        let minutes = Int(record.duration) / 60
        let seconds = Int(record.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
