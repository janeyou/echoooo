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
            HomeView()
                .environmentObject(pipeline)
                .onOpenURL { url in
                    _ = pipeline.dropbox.handleRedirect(url: url)
                }
        }
        .modelContainer(for: TranscriptRecord.self)
    }
}
