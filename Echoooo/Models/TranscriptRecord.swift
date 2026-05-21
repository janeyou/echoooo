import Foundation
import SwiftData

@Model
class TranscriptRecord {
    @Attribute(.unique) var id: UUID
    var localFilePath: String
    var dropboxPath: String?
    var transcript: String?
    var duration: TimeInterval
    var createdAt: Date
    var status: String // "recording", "uploading", "transcribing", "complete", "failed"

    init(
        id: UUID = UUID(),
        localFilePath: String,
        dropboxPath: String? = nil,
        transcript: String? = nil,
        duration: TimeInterval = 0,
        createdAt: Date = Date(),
        status: String = "recording"
    ) {
        self.id = id
        self.localFilePath = localFilePath
        self.dropboxPath = dropboxPath
        self.transcript = transcript
        self.duration = duration
        self.createdAt = createdAt
        self.status = status
    }
}
