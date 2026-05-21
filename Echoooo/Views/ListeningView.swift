import SwiftUI

struct ListeningView: View {
    @ObservedObject var pipeline: TranscriptionPipeline
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                Text("LISTENING")
                    .font(.mono400(10))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.25))

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 220, height: 220)
                    .scaleEffect(isBreathing ? 1.06 : 0.94)
                    .overlay {
                        Circle()
                            .fill(Color.white.opacity(0.55))
                            .frame(width: 10, height: 10)
                    }
                    .animation(
                        .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                        value: isBreathing
                    )

                Text(formattedElapsed)
                    .font(.mono400(13))
                    .tracking(1.0)
                    .foregroundStyle(.white.opacity(0.4))
                    .monospacedDigit()

                Spacer()

                Text("TAP TO STOP")
                    .font(.mono400(10))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, 56)
            }
        }
        .onAppear {
            isBreathing = true
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task { await pipeline.stopAndTranscribe() }
        }
    }

    private var formattedElapsed: String {
        let elapsed = pipeline.recorder.elapsedTime
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
