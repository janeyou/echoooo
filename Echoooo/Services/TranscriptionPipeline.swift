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

    func stopAndTranscribe() async {
        guard let fileURL = recorder.stop() else {
            state = .failed(message: "No recording file found.")
            return
        }

        let dropboxPath = "/\(fileURL.lastPathComponent)"
        lastDropboxPath = dropboxPath

        do {
            state = .uploading
            _ = try await dropbox.upload(localURL: fileURL, dropboxPath: dropboxPath)

            state = .transcribing
            guard let token = await dropbox.getAccessToken() else {
                state = .failed(message: EchooooError.notAuthenticated.localizedDescription)
                return
            }

            let jobId = try await riviera.transcribe(dropboxPath: dropboxPath, token: token)
            let transcript = try await riviera.poll(jobId: jobId, token: token)

            state = .complete(transcript: transcript)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
