import Foundation

class RivieraAPIClient {
    private let baseURL = "https://api.dropboxapi.com"
    private let pollInterval: TimeInterval = 15

    func transcribe(dropboxPath: String, token: String) async throws -> String {
        let url = URL(string: "\(baseURL)/2/riviera/get_transcript_async")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "file_id_or_url": [".tag": "path", "path": dropboxPath],
            "timestamp_level": "sentence"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw EchooooError.transcriptionFailed("Submit request failed")
        }

        let jobResponse = try JSONDecoder().decode(AsyncJobResponse.self, from: data)
        return jobResponse.asyncJobId
    }

    func poll(jobId: String, token: String) async throws -> String {
        let url = URL(string: "\(baseURL)/2/riviera/get_transcript_async/check")!

        while true {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["async_job_id": jobId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw EchooooError.transcriptionFailed("Poll request failed")
            }

            let transcriptResponse = try JSONDecoder().decode(TranscriptResponse.self, from: data)

            if transcriptResponse.tag == "complete",
               let segments = transcriptResponse.structuredTranscript?.segments {
                return joinSegments(segments)
            }

            try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
    }

    private func joinSegments(_ segments: [TranscriptSegment]) -> String {
        var paragraphs: [String] = []
        var currentParagraph: [String] = []

        for (index, segment) in segments.enumerated() {
            let trimmed = segment.text.trimmingCharacters(in: .whitespaces)
            currentParagraph.append(trimmed)

            let isLast = index == segments.count - 1
            let hasLongPause: Bool = {
                guard !isLast else { return false }
                let next = segments[index + 1]
                return next.startTime - segment.endTime > 2.0
            }()

            if hasLongPause || isLast {
                paragraphs.append(currentParagraph.joined(separator: " "))
                currentParagraph = []
            }
        }

        return paragraphs.joined(separator: "\n\n")
    }
}
