import SwiftUI

struct SettingsView: View {
    @ObservedObject var pipeline: TranscriptionPipeline
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKey.keepAudio) private var keepAudio: Bool = SettingsDefault.keepAudio
    @AppStorage(SettingsKey.consentPrompt) private var consentPrompt: Bool = SettingsDefault.consentPrompt
    @AppStorage(SettingsKey.hapticOnStop) private var hapticOnStop: Bool = SettingsDefault.hapticOnStop

    private let greenDot = Color(red: 0x3F/255.0, green: 0xAB/255.0, blue: 0x6D/255.0)

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        dropboxSection
                            .padding(.horizontal, 24)
                            .padding(.top, 28)

                        preferencesSection
                            .padding(.horizontal, 24)
                            .padding(.top, 28)

                        aboutSection
                            .padding(.horizontal, 24)
                            .padding(.top, 28)
                            .padding(.bottom, 48)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(.mono400(10))
                        .tracking(2.0)
                        .foregroundStyle(Theme.inkMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("done") { dismiss() }
                        .font(.mono400(11))
                        .tracking(0.4)
                        .foregroundStyle(Theme.inkMuted)
                }
            }
        }
    }

    private var dropboxSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DROPBOX")
                .font(.mono400(10))
                .tracking(1.8)
                .foregroundStyle(Theme.inkFaint)

            if pipeline.isAuthenticated {
                connectedCard
            } else {
                disconnectedCard
            }

            Text("audio uploads to your dropbox app folder. transcription happens via riviera, using the same account.")
                .font(.body300(12))
                .foregroundStyle(Theme.inkFaint)
                .lineSpacing(3)
                .padding(.top, 4)
        }
    }

    private var connectedCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle().fill(greenDot).frame(width: 7, height: 7)
                    Text("connected")
                        .font(.body300(14))
                        .foregroundStyle(Theme.ink)
                }

                Text("/Apps/Echoooo")
                    .font(.body300(12))
                    .foregroundStyle(Theme.inkFaint)
            }

            Spacer()

            Button {
                pipeline.disconnectDropbox()
            } label: {
                Text("DISCONNECT")
                    .font(.mono400(10))
                    .tracking(1.4)
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 0.5))
    }

    private var disconnectedCard: some View {
        HStack {
            Text("not connected")
                .font(.body300(14))
                .foregroundStyle(Theme.inkMuted)

            Spacer()

            Button {
                pipeline.connectDropbox()
            } label: {
                Text("CONNECT")
                    .font(.mono400(10))
                    .tracking(1.4)
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 0.5))
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PREFERENCES")
                .font(.mono400(10))
                .tracking(1.8)
                .foregroundStyle(Theme.inkFaint)
                .padding(.bottom, 8)

            Rectangle().fill(Theme.hairline).frame(height: 0.5)

            toggleRow(label: "keep audio after", isOn: $keepAudio)
            Rectangle().fill(Theme.hairline).frame(height: 0.5)
            toggleRow(label: "consent prompt", isOn: $consentPrompt)
            Rectangle().fill(Theme.hairline).frame(height: 0.5)
            toggleRow(label: "haptic on stop", isOn: $hapticOnStop)
            Rectangle().fill(Theme.hairline).frame(height: 0.5)

            Text("by default we delete the audio once the transcript is in. turn keep audio after on if you want playback.")
                .font(.body300(11))
                .foregroundStyle(Theme.inkFaint)
                .lineSpacing(3)
                .padding(.top, 10)
        }
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.body300(14))
                .foregroundStyle(Theme.ink)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.vertical, 8)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ABOUT")
                .font(.mono400(10))
                .tracking(1.8)
                .foregroundStyle(Theme.inkFaint)
                .padding(.bottom, 12)

            Text("echoooo captures conversations and turns them into readable text. a quiet alternative to voice memos.")
                .font(.body300(13))
                .foregroundStyle(Theme.inkMuted)
                .lineSpacing(3)

            Text(versionLabel)
                .font(.mono400(10))
                .tracking(1.2)
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 22)
        }
    }

    private var versionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "VERSION \(version) · BUILD \(build)"
    }
}
