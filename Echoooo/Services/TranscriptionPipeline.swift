import Foundation
import SwiftUI
import Combine

@MainActor
class TranscriptionPipeline: ObservableObject {
    enum PipelineState: Equatable {
        case idle
        case recording
        case uploading
        case transcribing
        case complete(transcript: String)
        case failed(message: String)
    }

    @Published var state: PipelineState = .idle

    let recorder = RecorderService()
    let dropbox = DropboxService()
    private let riviera = RivieraAPIClient()

    private(set) var lastRecordingURL: URL?
    private(set) var lastDropboxPath: String?

    private var transcribeTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var isAuthenticated: Bool { dropbox.isAuthenticated }

    init() {
        recorder.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        dropbox.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func connectDropbox() {
        dropbox.authenticate()
    }

    func disconnectDropbox() {
        dropbox.logout()
    }

    func reset() {
        state = .idle
    }

    func startRecording() throws {
        let url = try recorder.start()
        lastRecordingURL = url
        state = .recording
    }

    func stopAndTranscribe() {
        transcribeTask?.cancel()
        transcribeTask = Task { [weak self] in
            await self?.runStopAndTranscribe()
        }
    }

    func cancelTranscribe() {
        transcribeTask?.cancel()
        transcribeTask = nil
        if let fileURL = lastRecordingURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        state = .idle
    }

    private func runStopAndTranscribe() async {
        guard let fileURL = recorder.stop() else {
            state = .failed(message: "No audio file found.")
            return
        }

        let dropboxPath = "/\(fileURL.lastPathComponent)"
        lastDropboxPath = dropboxPath

        do {
            try Task.checkCancellation()
            state = .uploading
            _ = try await dropbox.upload(localURL: fileURL, dropboxPath: dropboxPath)

            try Task.checkCancellation()
            state = .transcribing
            guard let token = await dropbox.getAccessToken() else {
                state = .failed(message: EchooooError.notAuthenticated.localizedDescription)
                return
            }

            let jobId = try await riviera.transcribe(dropboxPath: dropboxPath, token: token)
            let transcript = try await riviera.poll(jobId: jobId, token: token)

            try Task.checkCancellation()

            let keepAudio = UserDefaults.standard.object(forKey: SettingsKey.keepAudio) as? Bool
                ?? SettingsDefault.keepAudio
            if keepAudio {
                if let movedURL = Self.relocateToDocuments(fileURL) {
                    lastRecordingURL = movedURL
                }
            } else {
                try? FileManager.default.removeItem(at: fileURL)
            }

            state = .complete(transcript: transcript)
        } catch is CancellationError {
            // user-initiated cancel, state already set to .idle in cancelTranscribe
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession cancelled, also user-initiated
        } catch {
            if Task.isCancelled {
                // suppress, treat as cancellation
            } else {
                state = .failed(message: error.localizedDescription)
            }
        }
    }

    private static func relocateToDocuments(_ tempURL: URL) -> URL? {
        let fm = FileManager.default
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let recordingsDir = docs.appendingPathComponent("recordings", isDirectory: true)
        do {
            try fm.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        let dest = recordingsDir.appendingPathComponent(tempURL.lastPathComponent)
        try? fm.removeItem(at: dest)
        do {
            try fm.moveItem(at: tempURL, to: dest)
            return dest
        } catch {
            return nil
        }
    }
}
