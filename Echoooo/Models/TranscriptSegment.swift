import Foundation

struct TranscriptSegment: Codable {
    let text: String
    let startTime: Double
    let endTime: Double

    enum CodingKeys: String, CodingKey {
        case text
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct TranscriptResponse: Codable {
    let tag: String
    let structuredTranscript: StructuredTranscript?

    enum CodingKeys: String, CodingKey {
        case tag = ".tag"
        case structuredTranscript = "structured_transcript"
    }
}

struct StructuredTranscript: Codable {
    let segments: [TranscriptSegment]
}

struct AsyncJobResponse: Codable {
    let asyncJobId: String

    enum CodingKeys: String, CodingKey {
        case asyncJobId = "async_job_id"
    }
}
