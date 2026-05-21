import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var pipeline: TranscriptionPipeline
    @Query(sort: \TranscriptRecord.createdAt, order: .reverse) private var records: [TranscriptRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var completedRecord: TranscriptRecord?
    @State private var recordingError: String?
    @State private var showingSettings = false
    @State private var showingHistory = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.paper.ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 14)
                        .padding(.top, 8)

                    Spacer(minLength: 0)

                    masthead
                        .padding(.bottom, 64)

                    recordCluster

                    Spacer(minLength: 0)

                    if pipeline.isAuthenticated, !records.isEmpty {
                        recentPreview
                            .padding(.bottom, 28)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showingHistory) {
                HistoryView()
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

    private var topBar: some View {
        HStack {
            historyButton
                .opacity(pipeline.isAuthenticated ? 1 : 0)
                .allowsHitTesting(pipeline.isAuthenticated)

            Spacer()

            settingsButton
        }
        .frame(height: 44)
    }

    private var historyButton: some View {
        Button {
            showingHistory = true
        } label: {
            Image(systemName: "clock")
                .font(.system(size: 17, weight: .light))
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
                .font(.system(size: 17, weight: .light))
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
        .font(.display400(32))
        .tracking(-0.5)
        .lineSpacing(2)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recordCluster: some View {
        VStack(spacing: 22) {
            recordButton

            Text(pipeline.isAuthenticated ? "TAP TO LISTEN" : "TAP TO CONNECT DROPBOX")
                .font(.mono400(10))
                .tracking(1.6)
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity)
    }

    private var recordButton: some View {
        Button {
            if pipeline.isAuthenticated {
                do {
                    try pipeline.startRecording()
                } catch {
                    recordingError = error.localizedDescription
                }
            } else {
                pipeline.connectDropbox()
            }
        } label: {
            Circle()
                .fill(pipeline.isAuthenticated ? Theme.ink : Theme.inkFaint)
                .frame(width: 104, height: 104)
                .overlay {
                    Image(systemName: pipeline.isAuthenticated ? "mic" : "link")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Theme.paper)
                }
        }
        .buttonStyle(.plain)
    }

    private var recentPreview: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("RECENT")
                    .font(.mono400(10))
                    .tracking(1.6)
                    .foregroundStyle(Theme.inkFaint)
                Spacer()
                if records.count > 3 {
                    Button {
                        showingHistory = true
                    } label: {
                        Text("ALL →")
                            .font(.mono400(10))
                            .tracking(1.6)
                            .foregroundStyle(Theme.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)

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
                .tracking(1.0)
                .foregroundStyle(Theme.inkFaint)
                .frame(width: 56, alignment: .leading)

            Text(record.transcript?.prefix(64).description ?? "processing.")
                .font(.body300(13))
                .foregroundStyle(Theme.inkMuted)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

