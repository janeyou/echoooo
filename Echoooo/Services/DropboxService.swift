import Foundation
import SwiftyDropbox
import UIKit

@MainActor
class DropboxService: ObservableObject {
    @Published var isAuthenticated: Bool

    init() {
        self.isAuthenticated = DropboxClientsManager.authorizedClient != nil
    }

    func authenticate() {
        let scopeRequest = ScopeRequest(
            scopeType: .user,
            scopes: ["files.content.read", "files.content.write"],
            includeGrantedScopes: false
        )
        DropboxClientsManager.authorizeFromControllerV2(
            UIApplication.shared,
            controller: nil,
            loadingStatusDelegate: nil,
            openURL: { url in UIApplication.shared.open(url) },
            scopeRequest: scopeRequest
        )
    }

    func handleRedirect(url: URL) -> Bool {
        let completion: DropboxOAuthCompletion = { [weak self] result in
            guard let self else { return }
            if case .success = result {
                Task { @MainActor in
                    self.isAuthenticated = true
                }
            }
        }
        return DropboxClientsManager.handleRedirectURL(
            url,
            includeBackgroundClient: false,
            completion: completion
        )
    }

    func logout() {
        DropboxClientsManager.unlinkClients()
        isAuthenticated = false
    }

    func getAccessToken() async -> String? {
        guard let client = DropboxClientsManager.authorizedClient else { return nil }
        return await withCheckedContinuation { continuation in
            client.accessTokenProvider.refreshAccessTokenIfNecessary { _ in
                continuation.resume(returning: client.accessTokenProvider.accessToken)
            }
        }
    }

    func upload(localURL: URL, dropboxPath: String) async throws -> String {
        guard let client = DropboxClientsManager.authorizedClient else {
            throw EchooooError.notAuthenticated
        }

        let data = try Data(contentsOf: localURL)

        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Files.FileMetadata, Error>) in
            client.files.upload(path: dropboxPath, mode: .add, autorename: true, input: data)
                .response { metadata, _ in
                    if let metadata {
                        continuation.resume(returning: metadata)
                    } else {
                        continuation.resume(throwing: EchooooError.uploadFailed)
                    }
                }
        }

        return dropboxPath
    }
}

enum EchooooError: Error, LocalizedError {
    case notAuthenticated
    case uploadFailed
    case transcriptionFailed(String)
    case networkError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Connect Dropbox before listening."
        case .uploadFailed: return "Failed to upload audio."
        case .transcriptionFailed(let msg): return "Transcription failed: \(msg)"
        case .networkError: return "Network error."
        }
    }
}
