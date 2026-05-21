import SwiftUI
import UserNotifications

struct ProcessingView: View {
    @ObservedObject var pipeline: TranscriptionPipeline
    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt = Date()
    @State private var uploadFinishedAt: Date?
    @State private var isHaloPulsing = false
    @State private var canNotify = false

    private var audioDuration: TimeInterval {
        pipeline.recorder.elapsedTime
    }

    private var estimatedTotal: TimeInterval {
        max(15, 10 + audioDuration * 0.6)
    }

    private enum Phase { case done, active, pending }

    private var uploadPhase: Phase {
        switch pipeline.state {
        case .uploading: return .active
        case .transcribing, .complete: return .done
        default: return .pending
        }
    }

    private var transcribePhase: Phase {
        switch pipeline.state {
        case .transcribing: return .active
        case .complete: return .done
        default: return .pending
        }
    }

    private var formatPhase: Phase {
        switch pipeline.state {
        case .complete: return .done
        default: return .pending
        }
    }

    var body: some View {
        TimelineView(.periodic(from: startedAt, by: 0.5)) { context in
            let elapsed = context.date.timeIntervalSince(startedAt)
            let progress = min(elapsed / estimatedTotal, 0.95)
            let remaining = max(0, estimatedTotal - elapsed)

            ZStack {
                Theme.paper.ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 14)
                        .padding(.top, 8)

                    Text("TRANSCRIBING")
                        .font(.mono400(10))
                        .tracking(2.4)
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 16)

                    Text("hold on")
                        .font(.display400(28))
                        .tracking(-0.3)
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 24)

                    phaseRows(transcribeDetail: phaseDetail(remaining: remaining))
                        .frame(width: 260)
                        .padding(.top, 48)

                    progressBar(progress: progress)
                        .frame(width: 240, height: 2)
                        .padding(.top, 22)

                    Text("DURATION \(formattedDuration)")
                        .font(.mono400(10))
                        .tracking(1.4)
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 18)

                    Spacer()

                    leaveCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 22)
                }
            }
        }
        .onAppear {
            startedAt = Date()
            isHaloPulsing = true
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            canNotify = settings.authorizationStatus == .authorized
        }
        .onChange(of: pipeline.state) { _, newState in
            switch newState {
            case .transcribing:
                if uploadFinishedAt == nil { uploadFinishedAt = Date() }
            case .complete:
                notifyComplete()
            default: break
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                pipeline.cancelTranscribe()
            } label: {
                Text("cancel")
                    .font(.mono400(11))
                    .foregroundStyle(Theme.inkMuted)
                    .frame(width: 80, height: 40, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Color.clear.frame(width: 80, height: 40)
        }
    }

    private func phaseDetail(remaining: TimeInterval) -> String {
        if remaining > 1 { return "riviera · \(Int(remaining))s left" }
        return "riviera · finishing"
    }

    private func phaseRows(transcribeDetail: String) -> some View {
        VStack(spacing: 14) {
            phaseRow(phase: uploadPhase, label: "uploaded to dropbox", detail: uploadDetail)
            phaseRow(phase: transcribePhase, label: "transcribing", detail: transcribeDetail)
            phaseRow(phase: formatPhase, label: "formatting", detail: "")
        }
    }

    private var uploadDetail: String {
        guard let uploadFinishedAt else { return "" }
        let secs = max(1, Int(uploadFinishedAt.timeIntervalSince(startedAt)))
        return "\(secs)s"
    }

    private func phaseRow(phase: Phase, label: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: 0) {
            phaseIndicator(phase: phase)
                .frame(width: 20, alignment: .leading)

            Text(label)
                .font(.body300(14))
                .foregroundStyle(phase == .pending ? Theme.inkFaint : Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(detail)
                .font(.mono400(10))
                .tracking(0.8)
                .foregroundStyle(Theme.inkFaint)
        }
    }

    @ViewBuilder
    private func phaseIndicator(phase: Phase) -> some View {
        switch phase {
        case .done:
            ZStack {
                Circle().fill(Theme.accent).frame(width: 12, height: 12)
                Image(systemName: "checkmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
            }
        case .active:
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.18))
                    .frame(width: 20, height: 20)
                    .scaleEffect(isHaloPulsing ? 1.0 : 0.7)
                    .opacity(isHaloPulsing ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isHaloPulsing)
                Circle().fill(Theme.accent).frame(width: 12, height: 12)
            }
        case .pending:
            Circle()
                .strokeBorder(Theme.hairline, lineWidth: 1)
                .frame(width: 12, height: 12)
        }
    }

    private func progressBar(progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1).fill(Theme.hairline)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeOut(duration: 0.4), value: progress)
            }
        }
    }

    private var leaveCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: canNotify ? "bell" : "clock")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Theme.ink)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("it's OK to leave")
                    .font(.body300(14))
                    .foregroundStyle(Theme.ink)

                Text(canNotify
                     ? "we'll keep going and notify you when it's ready"
                     : "we'll keep going. open the app to see the result.")
                    .font(.body300(12))
                    .foregroundStyle(Theme.inkMuted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.hairline, lineWidth: 0.5)
        )
    }

    private var formattedDuration: String {
        let minutes = Int(audioDuration) / 60
        let seconds = Int(audioDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func notifyComplete() {
        guard scenePhase != .active, canNotify else { return }
        let content = UNMutableNotificationContent()
        content.title = "transcript ready"
        content.body = "your conversation is ready to read."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
