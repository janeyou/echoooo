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
    var status: String
    var title: String?

    init(
        id: UUID = UUID(),
        localFilePath: String,
        dropboxPath: String? = nil,
        transcript: String? = nil,
        duration: TimeInterval = 0,
        createdAt: Date = Date(),
        status: String = "recording",
        title: String? = nil
    ) {
        self.id = id
        self.localFilePath = localFilePath
        self.dropboxPath = dropboxPath
        self.transcript = transcript
        self.duration = duration
        self.createdAt = createdAt
        self.status = status
        self.title = title
    }

    var derivedTitle: String {
        if let title, !title.isEmpty { return title }
        if let transcript {
            let firstSentence = transcript
                .components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
                .first?
                .trimmingCharacters(in: .whitespaces) ?? ""
            if !firstSentence.isEmpty {
                return firstSentence.count > 40
                    ? String(firstSentence.prefix(40)).trimmingCharacters(in: .whitespaces) + "…"
                    : firstSentence
            }
        }
        return "voice memo · \(createdAt.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var wordCount: Int {
        guard let transcript else { return 0 }
        return transcript.split(whereSeparator: \.isWhitespace).count
    }

    var localAudioExists: Bool {
        guard !localFilePath.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: localFilePath)
    }
}
