import SwiftUI

struct SettingsView: View {
    @ObservedObject var pipeline: TranscriptionPipeline
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("DROPBOX")
                                .font(.mono400(10))
                                .tracking(1.6)
                                .foregroundStyle(Theme.inkFaint)

                            Text(pipeline.isAuthenticated ? "connected." : "not connected.")
                                .font(.body300(15))
                                .foregroundStyle(Theme.inkMuted)
                        }
                        .padding(.top, 8)

                        if pipeline.isAuthenticated {
                            Button(role: .destructive) {
                                pipeline.disconnectDropbox()
                            } label: {
                                Text("disconnect")
                                    .font(.body300(14))
                                    .foregroundStyle(Theme.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Theme.surface2)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.hairline, lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button {
                                pipeline.connectDropbox()
                            } label: {
                                Text("connect dropbox")
                                    .font(.body300(14))
                                    .foregroundStyle(Theme.paper)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Theme.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }

                        Text("recordings upload to your dropbox app folder. transcription happens via riviera, using the same account.")
                            .font(.body300(12))
                            .foregroundStyle(Theme.inkFaint)
                            .lineSpacing(3)

                        Divider()
                            .background(Theme.hairline)
                            .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("ABOUT")
                                .font(.mono400(10))
                                .tracking(1.6)
                                .foregroundStyle(Theme.inkFaint)

                            Text("echoooo captures conversations and turns them into readable text. a quiet alternative to voice memos.")
                                .font(.body300(13))
                                .foregroundStyle(Theme.inkMuted)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") { dismiss() }
                        .font(.mono400(12))
                        .foregroundStyle(Theme.inkMuted)
                }
            }
        }
    }
}
