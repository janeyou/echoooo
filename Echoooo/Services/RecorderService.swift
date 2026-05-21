import AVFoundation
import Combine

class RecorderService: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var normalizedPower: Float = 0

    private(set) var startedAt: Date?
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var meterTimer: Timer?
    private var currentFileURL: URL?
    private var smoothedPower: Float = 0

    func start() throws -> URL {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default, options: [.allowBluetooth])
        try session.setActive(true)

        let filename = "recording_\(Self.timestampString()).m4a"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128000
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.record()
        self.recorder = recorder

        currentFileURL = url
        isRecording = true
        startedAt = Date()
        elapsedTime = 0
        smoothedPower = 0
        normalizedPower = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let startedAt = self.startedAt else { return }
            self.elapsedTime = Date().timeIntervalSince(startedAt)
        }

        meterTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.sampleMeter()
        }

        return url
    }

    func stop() -> URL? {
        if let startedAt {
            elapsedTime = Date().timeIntervalSince(startedAt)
        }
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        meterTimer?.invalidate()
        meterTimer = nil
        isRecording = false
        normalizedPower = 0
        smoothedPower = 0
        startedAt = nil

        let url = currentFileURL
        currentFileURL = nil
        return url
    }

    func syncElapsedFromWallClock() {
        guard let startedAt else { return }
        elapsedTime = Date().timeIntervalSince(startedAt)
    }

    func simulateListening(elapsed: TimeInterval, level: Float) {
        isRecording = true
        elapsedTime = elapsed
        normalizedPower = level
    }

    private func sampleMeter() {
        guard let recorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let raw = recorder.averagePower(forChannel: 0)
        let normalized = Self.normalize(power: raw)
        let alpha: Float = 0.3
        smoothedPower = alpha * normalized + (1 - alpha) * smoothedPower
        normalizedPower = smoothedPower
    }

    private static func normalize(power: Float) -> Float {
        let minDb: Float = -50
        if power < minDb { return 0 }
        if power >= 0 { return 1 }
        return (power - minDb) / -minDb
    }

    private static func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}
