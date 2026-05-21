import SwiftUI
import SwiftData
import UserNotifications

struct HomeView: View {
    @EnvironmentObject private var pipeline: TranscriptionPipeline
    @Query(sort: \TranscriptRecord.createdAt, order: .reverse) private var records: [TranscriptRecord]
    @Environment(\.modelContext) private var modelContext

    @AppStorage(SettingsKey.consentPrompt) private var consentPrompt: Bool = SettingsDefault.consentPrompt

    @State private var completedRecord: TranscriptRecord?
    @State private var recordingError: String?
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingConsent = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()

                if pipeline.isAuthenticated {
                    connectedLayout
                } else {
                    emptyLayout
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showingHistory) { HistoryView() }
            .fullScreenCover(isPresented: $showingConsent) {
                ConsentView(onStart: {
                    showingConsent = false
                    startRecording()
                })
            }
            .fullScreenCover(isPresented: isListening) {
                ListeningView(pipeline: pipeline)
            }
            .fullScreenCover(isPresented: isProcessing) {
                ProcessingView(pipeline: pipeline)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(pipeline: pipeline)
            }
            .sheet(item: $completedRecord) { record in
                NavigationStack {
                    TranscriptView(record: record)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("done") { completedRecord = nil }
                                    .font(.mono400(12))
                                    .foregroundStyle(Theme.inkMuted)
                            }
                        }
                }
                .onDisappear { pipeline.reset() }
            }
            .alert("something went wrong", isPresented: Binding(
                get: { recordingError != nil },
                set: { if !$0 { recordingError = nil; pipeline.reset() } }
            )) {
                Button("OK") {}
            } message: {
                Text(recordingError ?? "")
            }
            .task {
                await requestNotificationPermissionIfNeeded()
            }
            .onChange(of: pipeline.state) { _, newState in
                switch newState {
                case .complete(let transcript):
                    let record = TranscriptRecord(
                        localFilePath: pipeline.lastRecordingURL?.path ?? "",
                        dropboxPath: pipeline.lastDropboxPath,
                        transcript: transcript,
                        duration: pipeline.recorder.elapsedTime,
                        status: "complete"
                    )
                    modelContext.insert(record)
                    completedRecord = record
                case .failed(let message):
                    recordingError = message
                default:
                    break
                }
            }
        }
    }

    private var emptyLayout: some View {
        VStack(spacing: 0) {
            topBar(leftSlot: AnyView(Color.clear.frame(width: 32, height: 32)))
                .padding(.horizontal, 14)
                .padding(.top, 8)

            masthead
                .padding(.top, 36)

            Spacer(minLength: 0)

            recordCluster(eyebrow: "TAP TO CONNECT DROPBOX", subCaption: nil)

            stepsBlock
                .padding(.top, 28)

            Spacer(minLength: 0)

            privacyFooter
                .padding(.bottom, 16)
        }
    }

    private var connectedLayout: some View {
        VStack(spacing: 0) {
            topBar(leftSlot: AnyView(historyButton))
                .padding(.horizontal, 14)
                .padding(.top, 8)

            masthead
                .padding(.top, 32)

            Spacer(minLength: 0)

            recordCluster(eyebrow: "TAP TO LISTEN", subCaption: "screen goes dark, tap again to stop")

            Spacer(minLength: 0)

            if !records.isEmpty {
                recentBlock
                    .padding(.bottom, 18)
            }
        }
    }

    private func topBar(leftSlot: AnyView) -> some View {
        HStack {
            leftSlot
                .frame(width: 80, alignment: .leading)

            Spacer()

            Text("echoooo")
                .font(.body300(15))
                .tracking(0.2)
                .foregroundStyle(Theme.ink)

            Spacer()

            settingsButton
                .frame(width: 80, alignment: .trailing)
        }
        .frame(height: 44)
    }

    private var historyButton: some View {
        Button {
            showingHistory = true
        } label: {
            Image(systemName: "clock")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var settingsButton: some View {
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var masthead: some View {
        (
            Text("a quiet way to capture\n")
                .foregroundStyle(Theme.ink)
            +
            Text("conversations")
                .italic()
                .foregroundStyle(Theme.accent)
            +
            Text(".")
                .foregroundStyle(Theme.ink)
        )
        .font(.display400(28))
        .tracking(-0.4)
        .lineSpacing(2)
        .padding(.leading, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func recordCluster(eyebrow: String, subCaption: String?) -> some View {
        VStack(spacing: 14) {
            recordButton

            Text(eyebrow)
                .font(.mono400(10))
                .tracking(1.8)
                .foregroundStyle(Theme.inkFaint)

            if let subCaption {
                Text(subCaption)
                    .font(.body300(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var recordButton: some View {
        Button {
            if pipeline.isAuthenticated {
                if consentPrompt {
                    showingConsent = true
                } else {
                    startRecording()
                }
            } else {
                pipeline.connectDropbox()
            }
        } label: {
            Circle()
                .fill(pipeline.isAuthenticated ? Theme.ink : Theme.inkFaint)
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: pipeline.isAuthenticated ? "mic" : "link")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(Theme.paper)
                }
        }
        .buttonStyle(.plain)
    }

    private var stepsBlock: some View {
        VStack(spacing: 10) {
            stepRow(number: "01", verb: "listen", explainer: "tap, the screen dims, we listen")
            stepRow(number: "02", verb: "transcribe", explainer: "we send it to your dropbox quietly")
            stepRow(number: "03", verb: "read", explainer: "a transcript appears, ready to copy")
        }
        .padding(.horizontal, 32)
    }

    private func stepRow(number: String, verb: String, explainer: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(number)
                .font(.mono400(10))
                .tracking(1.0)
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 22, alignment: .leading)

            Text(verb)
                .font(.body300(14))
                .foregroundStyle(Theme.ink)
                .frame(width: 70, alignment: .leading)

            Text(explainer)
                .font(.body300(12))
                .foregroundStyle(Theme.inkFaint)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var privacyFooter: some View {
        VStack(spacing: 4) {
            Text("audio stays in your dropbox app folder.")
            Text("nothing leaves your account.")
        }
        .font(.body300(11))
        .foregroundStyle(Theme.inkFaint)
        .multilineTextAlignment(.center)
        .lineSpacing(3)
        .padding(.horizontal, 36)
    }

    private var recentBlock: some View {
        VStack(spacing: 0) {
            HStack {
                Text("RECENT")
                    .font(.mono400(10))
                    .tracking(1.8)
                    .foregroundStyle(Theme.inkFaint)

                Spacer()

                if records.count > 3 {
                    Button {
                        showingHistory = true
                    } label: {
                        Text("ALL →")
                            .font(.mono400(10))
                            .tracking(1.8)
                            .foregroundStyle(Theme.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 10)

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 0.5)

            VStack(spacing: 0) {
                ForEach(Array(records.prefix(3))) { record in
                    NavigationLink {
                        TranscriptView(record: record)
                    } label: {
                        RecentRow(record: record)
                    }
                    .buttonStyle(.plain)
                }
            }

            Rectangle()
                .fill(Theme.hairline)
                .frame(height: 0.5)
        }
        .padding(.horizontal, 24)
    }

    private func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    private func startRecording() {
        do {
            try pipeline.startRecording()
        } catch {
            recordingError = error.localizedDescription
        }
    }

    private var isListening: Binding<Bool> {
        Binding(get: { pipeline.state == .recording }, set: { _ in })
    }

    private var isProcessing: Binding<Bool> {
        Binding(
            get: { pipeline.state == .uploading || pipeline.state == .transcribing },
            set: { _ in }
        )
    }
}

struct RecentRow: View {
    let record: TranscriptRecord

    var body: some View {
        HStack(spacing: 12) {
            Text(record.createdAt, format: .dateTime.month(.abbreviated).day())
                .font(.mono400(10))
                .tracking(0.8)
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.derivedTitle)
                    .font(.body300(14))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Text(record.transcript?.prefix(64).description ?? "processing.")
                    .font(.body300(12))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(1)
            }

            Spacer()

            Text(formattedDuration)
                .font(.mono400(10))
                .foregroundStyle(Theme.inkFaint)
                .monospacedDigit()
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var formattedDuration: String {
        let minutes = Int(record.duration) / 60
        let seconds = Int(record.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
