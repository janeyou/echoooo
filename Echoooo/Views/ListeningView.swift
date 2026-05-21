import SwiftUI

struct ListeningView: View {
    @ObservedObject var pipeline: TranscriptionPipeline
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKey.hapticOnStop) private var hapticOnStop: Bool = SettingsDefault.hapticOnStop
    @State private var isPulsing = false

    private let dotRed = Color(red: 0xE0/255.0, green: 0x50/255.0, blue: 0x7A/255.0)
    private let barCount = 28

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                topZone
                    .padding(.top, 22)

                Spacer()

                middleZone

                Spacer()

                bottomZone
                    .padding(.bottom, 14)
            }
        }
        .onAppear {
            isPulsing = true
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                pipeline.recorder.syncElapsedFromWallClock()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            stop()
        }
    }

    private var topZone: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(dotRed)
                .frame(width: 8, height: 8)
                .opacity(isPulsing ? 1.0 : 0.4)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isPulsing)

            Text("LISTENING")
                .font(.mono400(11))
                .tracking(2.6)
                .foregroundStyle(.white.opacity(0.62))
        }
    }

    private var middleZone: some View {
        VStack(spacing: 0) {
            waveform
                .frame(height: 80)
                .opacity(0.32)

            Text(formattedElapsed)
                .font(.mono400(26))
                .foregroundStyle(.white.opacity(0.42))
                .monospacedDigit()
                .padding(.top, 26)

            Text("LIVE · DROPBOX READY")
                .font(.mono400(10))
                .tracking(2.2)
                .foregroundStyle(.white.opacity(0.22))
                .padding(.top, 10)
        }
    }

    private var waveform: some View {
        let power = CGFloat(pipeline.recorder.normalizedPower)
        return HStack(alignment: .center, spacing: 4) {
            ForEach(0..<barCount, id: \.self) { i in
                let baseline = baselineHeight(i: i)
                let live = baseline * max(0.18, min(1.0, power * 2.5))
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(.white.opacity(0.78))
                    .frame(width: 3, height: max(12, live))
                    .animation(.easeOut(duration: 0.12), value: power)
            }
        }
    }

    private func baselineHeight(i: Int) -> CGFloat {
        let s = abs(sin(Double(i) * 0.72 + 1.4))
        return 12 + CGFloat(s) * 34
    }

    private var bottomZone: some View {
        VStack(spacing: 12) {
            Button {
                stop()
            } label: {
                Text("STOP")
                    .font(.mono400(11))
                    .tracking(2.4)
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 36)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.32), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Text("or tap anywhere")
                .font(.body300(11))
                .foregroundStyle(.white.opacity(0.28))
        }
    }

    private func stop() {
        if hapticOnStop {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        pipeline.stopAndTranscribe()
    }

    private var formattedElapsed: String {
        let elapsed = pipeline.recorder.elapsedTime
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
