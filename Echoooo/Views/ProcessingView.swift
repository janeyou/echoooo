import SwiftUI

struct ProcessingView: View {
    @ObservedObject var pipeline: TranscriptionPipeline
    @State private var startedAt = Date()

    private var audioDuration: TimeInterval {
        pipeline.recorder.elapsedTime
    }

    private var estimatedTotal: TimeInterval {
        max(15, 10 + audioDuration * 0.6)
    }

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 0.5)) { context in
            let elapsed = context.date.timeIntervalSince(startedAt)
            let progress = min(elapsed / estimatedTotal, 0.95)
            let remaining = max(0, estimatedTotal - elapsed)

            ZStack {
                Theme.paper.ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    Text("TRANSCRIBING")
                        .font(.mono400(10))
                        .tracking(2.4)
                        .foregroundStyle(Theme.inkFaint)

                    Text("hold on")
                        .font(.display400(28))
                        .foregroundStyle(Theme.ink)

                    VStack(spacing: 10) {
                        progressBar(progress: progress)
                            .frame(width: 240, height: 3)

                        Text(remaining > 1 ? "about \(formattedSeconds(remaining)) left" : "wrapping up.")
                            .font(.body300(13))
                            .foregroundStyle(Theme.inkMuted)
                            .monospacedDigit()
                    }
                    .padding(.top, 8)

                    Text("recorded \(formattedDuration)")
                        .font(.mono400(10))
                        .tracking(1.4)
                        .foregroundStyle(Theme.inkFaint)

                    Spacer()

                    Text("you can switch apps. we'll keep going.")
                        .font(.body300(12))
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.bottom, 44)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { startedAt = Date() }
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.hairline)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeOut(duration: 0.4), value: progress)
            }
        }
    }

    private func formattedSeconds(_ s: TimeInterval) -> String {
        let i = Int(s.rounded())
        if i < 60 { return "\(i)s" }
        let m = i / 60
        let r = i % 60
        return r == 0 ? "\(m)m" : "\(m)m \(r)s"
    }

    private var formattedDuration: String {
        let minutes = Int(audioDuration) / 60
        let seconds = Int(audioDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
