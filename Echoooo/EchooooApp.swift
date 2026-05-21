import SwiftUI
import SwiftData
import SwiftyDropbox

@main
struct EchooooApp: App {
    @StateObject private var pipeline = TranscriptionPipeline()

    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "DropboxAppKey") as? String ?? ""
        DropboxClientsManager.setupWithAppKey(key)
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(pipeline)
                .onOpenURL { url in
                    _ = pipeline.dropbox.handleRedirect(url: url)
                }
        }
        .modelContainer(for: TranscriptRecord.self)
    }

    @ViewBuilder
    private var rootView: some View {
        if DemoMode.isOn {
            DemoRoot(pipeline: pipeline)
        } else {
            HomeView()
        }
    }
}

struct DemoRoot: View {
    @ObservedObject var pipeline: TranscriptionPipeline
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TranscriptRecord.createdAt, order: .reverse) private var records: [TranscriptRecord]
    @State private var didSeed = false

    var body: some View {
        Group {
            switch DemoMode.screen {
            case "home-empty":
                HomeView()
            case "home-connected":
                HomeView()
            case "consent":
                ConsentView(onStart: {})
            case "listening":
                ListeningView(pipeline: pipeline)
            case "processing":
                ProcessingView(pipeline: pipeline)
            case "transcript":
                NavigationStack {
                    if let record = records.first {
                        TranscriptView(record: record)
                    } else {
                        Color.clear
                    }
                }
            case "history":
                NavigationStack {
                    HistoryView()
                }
            case "settings":
                SettingsView(pipeline: pipeline)
            default:
                HomeView()
            }
        }
        .task {
            await seedIfNeeded()
            primePipelineState()
        }
    }

    @MainActor
    private func seedIfNeeded() async {
        guard !didSeed else { return }
        didSeed = true

        let needsRecords: Set<String> = ["home-connected", "transcript", "history"]
        guard needsRecords.contains(DemoMode.screen) else { return }
        guard records.isEmpty else { return }

        for sample in DemoMode.sampleRecords() {
            modelContext.insert(sample)
        }
        try? modelContext.save()
    }

    private func primePipelineState() {
        switch DemoMode.screen {
        case "listening":
            pipeline.recorder.simulateListening(elapsed: 122, level: 0.55)
            pipeline.state = .recording
        case "processing":
            pipeline.recorder.simulateListening(elapsed: 184, level: 0)
            pipeline.state = .transcribing
        default:
            break
        }
    }
}
